--[[
	Player data persistence.

	* Session locking stops item/cash duplication when a player hops servers quickly.
	* UpdateAsync + retries so a DataStore hiccup never wipes progress.
	* If DataStores are unavailable (e.g. Studio without API access) the player still
	  plays, but saving is disabled for that session so nothing gets overwritten.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local LOCK_TIMEOUT = 5 * 60 -- a lock older than this is considered abandoned
local LOAD_ATTEMPTS = 5
local AUTOSAVE_INTERVAL = 90

export type PlayerData = {
	Cash: number,
	TotalEarned: number,
	Rebirths: number,
	Items: { [string]: boolean },
	Daily: { Streak: number, Last: number },
	Codes: { [string]: boolean },
	Receipts: { string },
	LastOnline: number,
	Playtime: number,
}

type Profile = {
	Data: PlayerData,
	CanSave: boolean,
	Saving: boolean,
}

local profiles: { [Player]: Profile } = {}
local store: DataStore? = nil

local function defaultData(): PlayerData
	return {
		Cash = 0,
		TotalEarned = 0,
		Rebirths = 0,
		Items = {},
		Daily = { Streak = 0, Last = 0 },
		Codes = {},
		Receipts = {},
		LastOnline = 0,
		Playtime = 0,
	}
end

-- Fill in any fields added after the player's data was first created.
local function reconcile(data: any, template: any)
	for key, value in template do
		if data[key] == nil then
			data[key] = value
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
		end
	end
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable, progress will not save:", result)
	end
end

-- Loads (yields). Always returns data; check DataService.CanSave to know if it persists.
function DataService.Load(player: Player): PlayerData
	local data: any = nil
	local canSave = false

	if store then
		-- Studio without API access fails instantly; don't make the developer wait on retries.
		local attempts = if RunService:IsStudio() then 1 else LOAD_ATTEMPTS
		for attempt = 1, attempts do
			local lockedByOther = false
			local ok, err = pcall(function()
				(store :: DataStore):UpdateAsync(keyFor(player), function(saved)
					saved = saved or {}
					local lock = saved.Lock
					local now = os.time()
					if
						lock
						and lock.JobId ~= game.JobId
						and now - lock.Time < LOCK_TIMEOUT
						and attempt < attempts
					then
						lockedByOther = true
						return nil -- abort; another server still owns this session
					end
					saved.Lock = { JobId = game.JobId, Time = now }
					data = saved.Data
					return saved
				end)
			end)
			if ok and not lockedByOther then
				canSave = true
				break
			end
			if not ok then
				warn(`[DataService] Load attempt {attempt} failed for {player.Name}: {err}`)
			end
			if not player.Parent then
				break
			end
			task.wait(if lockedByOther then 4 else 2)
		end
	end

	if type(data) ~= "table" then
		data = defaultData()
	else
		reconcile(data, defaultData())
	end

	if not canSave and not RunService:IsStudio() then
		warn(`[DataService] Saving disabled for {player.Name} this session`)
	end

	profiles[player] = { Data = data, CanSave = canSave, Saving = false }
	return data
end

function DataService.Get(player: Player): PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

function DataService.CanSave(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.CanSave
end

function DataService.Save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile or not profile.CanSave or not store then
		return false
	end
	-- Wait for an in-flight save so the final release save always runs last.
	while profile.Saving do
		task.wait(0.1)
	end
	profile.Saving = true
	profile.Data.LastOnline = os.time()

	local success = false
	for _ = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function(saved)
				saved = saved or {}
				if saved.Lock and saved.Lock.JobId ~= game.JobId then
					return nil -- another server took over; don't clobber its data
				end
				saved.Data = profile.Data
				saved.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
				return saved
			end)
		end)
		if ok then
			success = true
			break
		end
		warn(`[DataService] Save failed for {player.Name}: {err}`)
		task.wait(1)
	end
	profile.Saving = false
	return success
end

-- Final save when a player leaves.
function DataService.Release(player: Player)
	if profiles[player] then
		DataService.Save(player, true)
		profiles[player] = nil
	end
end

function DataService.Start()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for _, player in Players:GetPlayers() do
			if profiles[player] then
				pending += 1
				task.spawn(function()
					-- PlayerService hooks this to bank uncollected cash first.
					if DataService.BeforeRelease then
						DataService.BeforeRelease(player)
					end
					DataService.Release(player)
					pending -= 1
				end)
			end
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

DataService.BeforeRelease = nil :: ((Player) -> ())?

return DataService
