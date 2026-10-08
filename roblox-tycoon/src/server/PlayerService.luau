--[[
	Player lifecycle, cash, multipliers, rebirths and free rewards
	(daily login streak, playtime gifts, promo codes, offline earnings).

	State the client needs is mirrored onto player attributes:
	  Cash, Multiplier, IncomePerSec, Rebirths, RebirthCost, DailyReadyAt, DailyStreak,
	  NextGiftAt, PlotId, FriendBonus, Pass_<Key>, VIP, Loaded
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerService = {}

local Services
local requestHandlers: { [string]: (Player, any) -> (boolean, string?) } = {}
local lastRequest: { [Player]: number } = {}
local joinTime: { [Player]: number } = {}
local friendCache: { [Player]: { [number]: boolean } } = {}

----------------------------------------------------------------------------------------
-- Cash
----------------------------------------------------------------------------------------

local function syncCash(player: Player, data: any)
	player:SetAttribute("Cash", data.Cash)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	if cashValue then
		(cashValue :: StringValue).Value = Format.Cash(data.Cash)
	end
end

function PlayerService.GetCash(player: Player): number
	local data = Services.DataService.Get(player)
	return if data then data.Cash else 0
end

function PlayerService.AddCash(player: Player, amount: number)
	local data = Services.DataService.Get(player)
	if not data or amount <= 0 or amount ~= amount then
		return
	end
	data.Cash += amount
	data.TotalEarned += amount
	syncCash(player, data)
end

function PlayerService.SpendCash(player: Player, amount: number): boolean
	local data = Services.DataService.Get(player)
	if not data or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	syncCash(player, data)
	return true
end

----------------------------------------------------------------------------------------
-- Multipliers & stats
----------------------------------------------------------------------------------------

function PlayerService.GetMultiplier(player: Player): number
	return (player:GetAttribute("Multiplier") or 1) :: number
end

function PlayerService.RefreshStats(player: Player)
	local data = Services.DataService.Get(player)
	if not data then
		return
	end

	local multiplier = Economy.RebirthMultiplier(data.Rebirths)
	if player:GetAttribute("Pass_DoubleCash") then
		multiplier *= 2
	end
	if player:GetAttribute("Pass_VIP") then
		multiplier *= 1.5
	end
	local bonus = (player:GetAttribute("FriendBonus") or 0) + (if player:GetAttribute("InGroup") then Config.GroupBonus else 0)
	multiplier *= 1 + bonus
	multiplier *= 1 + Economy.IndexBonus((player:GetAttribute("IndexCount") or 0) :: number)

	local plot = Services.PlotService.GetPlot(player)
	local owned = if plot then plot.Owned else data.Items
	local income = Economy.PlotIncome(owned, player:GetAttribute("Pass_FastDroppers") == true) * multiplier

	player:SetAttribute("Multiplier", multiplier)
	player:SetAttribute("IncomePerSec", income)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthCost", Economy.RebirthCost(data.Rebirths))

	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirths")
	if rebirthValue then
		(rebirthValue :: IntValue).Value = data.Rebirths
	end
end

local function incomeOf(player: Player): number
	return (player:GetAttribute("IncomePerSec") or 0) :: number
end

-- Friends in the same server boost each other's cash.
local function refreshFriendBonuses()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			local cache = friendCache[player]
			if not cache then
				return
			end
			local friends = 0
			for _, other in Players:GetPlayers() do
				if other ~= player then
					if cache[other.UserId] == nil then
						local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
						cache[other.UserId] = ok and isFriend
					end
					if cache[other.UserId] then
						friends += 1
					end
				end
			end
			local bonus = math.min(friends * Config.FriendBonusPer, Config.FriendBonusMax)
			if player.Parent and player:GetAttribute("FriendBonus") ~= bonus then
				player:SetAttribute("FriendBonus", bonus)
				PlayerService.RefreshStats(player)
				if bonus > 0 then
					Services.Remotes.NotifyPlayer(player, `👯 Friend boost active: +{math.floor(bonus * 100)}% cash!`, "success")
				end
			end
		end)
	end
end

----------------------------------------------------------------------------------------
-- Brainrot Index
----------------------------------------------------------------------------------------

local VALID_VARIANTS = {}
for _, variant in Economy.IndexVariants() do
	VALID_VARIANTS[variant] = true
end

local function countIndex(index: { [string]: { [string]: boolean } }): number
	local count = 0
	for _, variants in index do
		for _ in variants do
			count += 1
		end
	end
	return count
end

-- Mirrors the saved Index onto attributes ("Idx_<CharacterId>_<Variant>") for the client.
local function syncIndex(player: Player, data: any)
	for characterId, variants in data.Index do
		for variant in variants do
			player:SetAttribute(`Idx_{characterId}_{variant}`, true)
		end
	end
	player:SetAttribute("IndexCount", countIndex(data.Index))
end

-- Called whenever a brainrot spawns on a player's plot.
function PlayerService.Discover(player: Player, def: any, variant: string)
	local data = Services.DataService.Get(player)
	if not data or not VALID_VARIANTS[variant] then
		return
	end
	local entry = data.Index[def.Id]
	if entry and entry[variant] then
		return
	end
	if not entry then
		entry = {}
		data.Index[def.Id] = entry
	end
	entry[variant] = true
	player:SetAttribute(`Idx_{def.Id}_{variant}`, true)
	player:SetAttribute("IndexCount", countIndex(data.Index))
	PlayerService.RefreshStats(player)

	local label = if variant == "Normal" then def.Name else `{variant} {def.Name}`
	local percent = Config.IndexBonusPerDiscovery * 100
	Services.Remotes.NotifyPlayer(player, `📖 NEW in your Index: {label}! (+{percent}% cash forever)`, "rare")
end

----------------------------------------------------------------------------------------
-- Rebirth & rewards
----------------------------------------------------------------------------------------

function PlayerService.Rebirth(player: Player): (boolean, string?)
	local data = Services.DataService.Get(player)
	if not data then
		return false, "Still loading"
	end
	local cost = Economy.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		return false, `You need {Format.Cash(cost - data.Cash)} more to rebirth!`
	end

	data.Rebirths += 1
	data.Cash = 0
	data.Items = {}
	Services.PlotService.ResetForRebirth(player)
	syncCash(player, data)
	PlayerService.RefreshStats(player)

	local multiplier = Economy.RebirthMultiplier(data.Rebirths)
	Services.Remotes.Celebrate:FireClient(player, `REBIRTH {data.Rebirths}!`, `Permanent x{multiplier} cash multiplier`)
	Services.Remotes.NotifyAll(`🔁 {player.DisplayName} just reached Rebirth {data.Rebirths}!`, "event")
	task.spawn(Services.DataService.Save, player)
	return true, "Rebirthed!"
end

local function claimDaily(player: Player): (boolean, string?)
	local data = Services.DataService.Get(player)
	if not data then
		return false, "Still loading"
	end
	local now = os.time()
	local elapsed = now - data.Daily.Last
	if elapsed < Config.DailyCooldown then
		return false, `Next daily reward in {Format.Time(Config.DailyCooldown - elapsed)}`
	end
	local streak = if elapsed <= Config.DailyStreakWindow then data.Daily.Streak + 1 else 1
	local day = (streak - 1) % #Config.DailyRewards + 1
	local reward = Config.DailyRewards[day]
	local amount = Economy.ScaledReward(incomeOf(player), reward.IncomeSeconds, reward.Minimum)

	data.Daily.Streak = streak
	data.Daily.Last = now
	PlayerService.AddCash(player, amount)
	player:SetAttribute("DailyStreak", streak)
	player:SetAttribute("DailyReadyAt", now + Config.DailyCooldown)
	Services.Remotes.CashPopup:FireClient(player, amount)
	return true, `Day {day} reward: {Format.Cash(amount)}! Come back tomorrow for more.`
end

local function claimGift(player: Player): (boolean, string?)
	local now = os.time()
	local readyAt = player:GetAttribute("NextGiftAt") or math.huge
	if now < readyAt then
		return false, `Gift ready in {Format.Time(readyAt - now)}`
	end
	local gift = Config.PlaytimeGift
	local amount = Economy.ScaledReward(incomeOf(player), gift.IncomeSeconds, gift.Minimum)
	PlayerService.AddCash(player, amount)
	player:SetAttribute("NextGiftAt", now + gift.Interval)
	Services.Remotes.CashPopup:FireClient(player, amount)
	return true, `🎁 Free gift: {Format.Cash(amount)}!`
end

local function redeemCode(player: Player, code: any): (boolean, string?)
	local data = Services.DataService.Get(player)
	if not data or type(code) ~= "string" or #code > 40 then
		return false, "Invalid code"
	end
	code = string.upper((code:gsub("%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		return false, "That code doesn't exist (yet 👀)"
	end
	if data.Codes[code] then
		return false, "You already redeemed that code!"
	end
	local amount = (reward.Cash or 0)
	if reward.IncomeSeconds then
		amount += Economy.ScaledReward(incomeOf(player), reward.IncomeSeconds, reward.Minimum or 0)
	end
	data.Codes[code] = true
	PlayerService.AddCash(player, amount)
	Services.Remotes.CashPopup:FireClient(player, amount)
	return true, `Code redeemed: {Format.Cash(amount)}!`
end

local function giveOfflineEarnings(player: Player, data: any)
	if data.LastOnline <= 0 then
		return
	end
	local offline = os.time() - data.LastOnline
	local cfg = Config.OfflineEarnings
	if offline < cfg.MinSeconds then
		return
	end
	local amount = math.floor(incomeOf(player) * math.min(offline, cfg.MaxSeconds) * cfg.Rate)
	if amount > 0 then
		PlayerService.AddCash(player, amount)
		Services.Remotes.Celebrate:FireClient(
			player,
			"WELCOME BACK!",
			`Your factory made {Format.Cash(amount)} while you were away`
		)
	end
end

----------------------------------------------------------------------------------------
-- Requests from the client
----------------------------------------------------------------------------------------

function PlayerService.RegisterRequest(action: string, handler: (Player, any) -> (boolean, string?))
	requestHandlers[action] = handler
end

local function onRequest(player: Player, action: any, payload: any)
	if type(action) ~= "string" then
		return { Ok = false }
	end
	local now = os.clock()
	if (lastRequest[player] or 0) + 0.3 > now then
		return { Ok = false, Message = "Slow down!" }
	end
	lastRequest[player] = now
	local handler = requestHandlers[action]
	if not handler then
		return { Ok = false }
	end
	if not Services.DataService.Get(player) then
		return { Ok = false, Message = "Still loading your factory..." }
	end
	local ok, ok2, message = pcall(handler, player, payload)
	if not ok then
		warn(`[Request] {action} failed: {ok2}`)
		return { Ok = false, Message = "Something went wrong" }
	end
	return { Ok = ok2, Message = message }
end

----------------------------------------------------------------------------------------
-- Characters
----------------------------------------------------------------------------------------

local function setCollisionGroup(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = "Players"
	end
end

local function onCharacterAdded(player: Player, character: Model)
	for _, descendant in character:GetDescendants() do
		setCollisionGroup(descendant)
	end
	character.DescendantAdded:Connect(setCollisionGroup)

	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not root then
		return
	end
	if player:GetAttribute("VIP") then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 200, 40)
		sparkles.Parent = root
	end
	task.wait() -- let the default spawn finish first
	PlayerService.TeleportToPlot(player)
end

function PlayerService.TeleportToPlot(player: Player)
	local plot = Services.PlotService.GetPlot(player)
	local character = player.Character
	if plot and character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(Services.PlotService.SpawnCFrame(plot))
	end
end

----------------------------------------------------------------------------------------
-- Join / leave
----------------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	joinTime[player] = os.time()
	friendCache[player] = {}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cashValue = Instance.new("StringValue")
	cashValue.Name = "Cash"
	cashValue.Value = "$0"
	cashValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Parent = leaderstats
	leaderstats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	local data = Services.DataService.Load(player)
	if not player.Parent then
		Services.DataService.Release(player)
		return
	end

	Services.MonetizationService.LoadPasses(player, data)
	if Config.GroupId > 0 then
		local ok, inGroup = pcall(player.IsInGroupAsync, player, Config.GroupId)
		player:SetAttribute("InGroup", ok and inGroup)
	end

	local plot = Services.PlotService.Claim(player, data.Items)
	if not plot then
		player:Kick("This server is full - please join another one!")
		return
	end

	syncCash(player, data)
	syncIndex(player, data)
	PlayerService.RefreshStats(player)
	giveOfflineEarnings(player, data)

	player:SetAttribute("DailyStreak", data.Daily.Streak)
	player:SetAttribute("DailyReadyAt", data.Daily.Last + Config.DailyCooldown)
	player:SetAttribute("NextGiftAt", os.time() + Config.PlaytimeGift.Interval)
	player:SetAttribute("Loaded", true)

	PlayerService.TeleportToPlot(player)
	refreshFriendBonuses()

	if not data.Items.D1 then
		Services.Remotes.NotifyPlayer(player, "Welcome! Step on the green FREE button to build your first dropper 👇", "info")
	end
	if not Services.DataService.CanSave(player) then
		Services.Remotes.NotifyPlayer(player, "⚠️ Saving is unavailable right now - progress may not save.", "error")
	end
end

local function beforeRelease(player: Player)
	local data = Services.DataService.Get(player)
	if data then
		Services.PlotService.Collect(player, true)
		if joinTime[player] then
			data.Playtime += os.time() - joinTime[player]
			joinTime[player] = nil
		end
	end
end

local function onPlayerRemoving(player: Player)
	beforeRelease(player)
	Services.PlotService.Release(player)
	Services.DataService.Release(player)
	lastRequest[player] = nil
	friendCache[player] = nil
	joinTime[player] = nil
	refreshFriendBonuses()
end

function PlayerService.Init(services)
	Services = services
	Services.DataService.BeforeRelease = beforeRelease

	PlayerService.RegisterRequest("Rebirth", PlayerService.Rebirth)
	PlayerService.RegisterRequest("ClaimDaily", claimDaily)
	PlayerService.RegisterRequest("ClaimGift", claimGift)
	PlayerService.RegisterRequest("RedeemCode", redeemCode)
	Services.Remotes.Request.OnServerInvoke = onRequest
end

function PlayerService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Auto Collect game pass, plus collecting while standing still on the pad
	-- (Touched only fires when you move onto it).
	task.spawn(function()
		while true do
			task.wait(Config.AutoCollectInterval)
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Pass_AutoCollect") then
					Services.PlotService.Collect(player, true)
				elseif Services.PlotService.IsOnCollectPad(player) then
					Services.PlotService.Collect(player)
				end
			end
		end
	end)
end

return PlayerService
