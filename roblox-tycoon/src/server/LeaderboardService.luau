--[[
	Global "Top Earners" leaderboard shown on the lobby board.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local LeaderboardService = {}

local UPDATE_INTERVAL = 120
local MAX_ENTRIES = 10
local MAX_STORED_VALUE = 2 ^ 53

local Services
local store: OrderedDataStore? = nil
local nameCache: { [number]: string } = {}
local rows: { TextLabel } = {}

local function nameFor(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local result = if ok then name else "Player"
	nameCache[userId] = result
	return result
end

local function update()
	if not store then
		return
	end
	for _, player in Players:GetPlayers() do
		local data = Services.DataService.Get(player)
		if data and Services.DataService.CanSave(player) then
			pcall(function()
				(store :: OrderedDataStore):SetAsync(tostring(player.UserId), math.floor(math.min(data.TotalEarned, MAX_STORED_VALUE)))
			end)
		end
	end

	local ok, page = pcall(function()
		return (store :: OrderedDataStore):GetSortedAsync(false, MAX_ENTRIES):GetCurrentPage()
	end)
	if not ok then
		return
	end
	for i = 1, MAX_ENTRIES do
		local entry = page[i]
		local row = rows[i]
		if entry then
			local medal = if i == 1 then "🥇" elseif i == 2 then "🥈" elseif i == 3 then "🥉" else `{i}.`
			row.Text = `{medal} {nameFor(tonumber(entry.key) or 0)}  {Format.Cash(entry.value)}`
		else
			row.Text = ""
		end
	end
end

function LeaderboardService.Init(services)
	Services = services
	local frame = services.WorldBuilder.LeaderboardFrame
	for i = 1, MAX_ENTRIES do
		rows[i] = services.WorldBuilder.BoardLine(frame, if i == 1 then "Loading..." else "", 52, nil, i)
	end
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.LeaderboardStoreName)
	if ok then
		store = result
	end
end

function LeaderboardService.Start()
	task.spawn(function()
		task.wait(15)
		while true do
			local ok, err = pcall(update)
			if not ok then
				warn("[Leaderboard]", err)
			end
			task.wait(UPDATE_INTERVAL)
		end
	end)
end

return LeaderboardService
