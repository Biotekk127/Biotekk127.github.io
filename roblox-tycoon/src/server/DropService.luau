--[[
	Drops: spawning brainrots from droppers, rolling mutations, upgraders and the
	collector that turns them into cash.
]]

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Builders = require(script.Parent.Builders)

local DropService = {}

type DropInfo = { Plot: any, Value: number, Upgraded: { [string]: boolean } }

local drops: { [BasePart]: DropInfo } = {}
local lastGlobalAnnounce: { [Player]: number } = {}
local Services

local MAX_TOTAL_MUTATION_CHANCE = 0.6

local function removeDrop(part: BasePart)
	local info = drops[part]
	if info then
		drops[part] = nil
		info.Plot.DropCount = math.max(0, info.Plot.DropCount - 1)
	end
end

local function rollMutation(owner: Player): any?
	local luck = Services.EventService.LuckMultiplier()
	if owner:GetAttribute("Pass_LuckyMutations") then
		luck *= 3
	end
	local total = 0
	for _, mutation in Config.Mutations do
		total += mutation.Chance
	end
	-- Keep at least some normal drops even with every boost stacked.
	luck = math.min(luck, MAX_TOTAL_MUTATION_CHANCE / total)

	local roll = math.random()
	local cumulative = 0
	for _, mutation in Config.Mutations do
		cumulative += mutation.Chance * luck
		if roll < cumulative then
			return mutation
		end
	end
	return nil
end

local function announce(owner: Player, item: any, mutation: any)
	local text = `{mutation.Name:upper()} {item.Creature.Name} spawned! (x{mutation.Multiplier})`
	Services.Remotes.NotifyPlayer(owner, `✨ {text}`, "rare")
	if mutation.Name == "Rainbow" then
		local now = os.clock()
		if now - (lastGlobalAnnounce[owner] or 0) > 60 then
			lastGlobalAnnounce[owner] = now
			for _, other in game:GetService("Players"):GetPlayers() do
				if other ~= owner then
					Services.Remotes.NotifyPlayer(other, `🌈 {owner.DisplayName} got a {text}`, "rare")
				end
			end
		end
	end
end

local function spawnDrop(plot: any, dropper: any)
	local owner: Player = plot.Owner
	local item = dropper.Item
	local mutation = rollMutation(owner)
	local value = item.Value * (if mutation then mutation.Multiplier else 1)

	local part = Builders.Drop(item.Creature, mutation, dropper.SpawnCF, plot.Parts.DropsFolder)
	-- Server owns the physics so the collector can't be spoofed by clients.
	pcall(function()
		part:SetNetworkOwner(nil)
	end)
	drops[part] = { Plot = plot, Value = value, Upgraded = {} }
	plot.DropCount += 1
	part.Destroying:Connect(function()
		removeDrop(part)
	end)
	task.delay(Config.DropLifetime, function()
		if part.Parent then
			part:Destroy()
		end
	end)

	if mutation and mutation.Announce then
		announce(owner, item, mutation)
	end
end

function DropService.HookUpgrader(plot: any, item: any, laser: BasePart)
	laser.Touched:Connect(function(hit)
		local info = drops[hit]
		if info and info.Plot == plot and not info.Upgraded[item.Id] then
			info.Upgraded[item.Id] = true
			info.Value *= item.Multiplier
		end
	end)
end

function DropService.HookCollector(plot: any)
	plot.Parts.Collector.Touched:Connect(function(hit)
		local info = drops[hit]
		if not info or info.Plot ~= plot then
			return
		end
		removeDrop(hit)
		hit:Destroy()
		local owner = plot.Owner
		if owner then
			local amount = info.Value
				* plot.CollectorMultiplier
				* Services.PlayerService.GetMultiplier(owner)
				* Services.EventService.CashMultiplier()
			Services.PlotService.AddToBank(plot, amount)
		end
	end)
end

-- Forget every drop belonging to a plot (called when a plot is cleared).
function DropService.ClearPlot(plot: any)
	for part, info in drops do
		if info.Plot == plot then
			drops[part] = nil
		end
	end
	plot.DropCount = 0
end

function DropService.Init(services)
	Services = services
	PhysicsService:RegisterCollisionGroup("Drops")
	PhysicsService:RegisterCollisionGroup("Players")
	-- Drops pass through each other and through players, so nobody can block a conveyor.
	PhysicsService:CollisionGroupSetCollidable("Drops", "Drops", false)
	PhysicsService:CollisionGroupSetCollidable("Drops", "Players", false)
end

function DropService.Start()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.1 then
			return
		end
		accumulator = 0
		local now = os.clock()
		for _, plot in Services.PlotService.Plots do
			local owner = plot.Owner
			if owner then
				local interval = Config.DropInterval
				if owner:GetAttribute("Pass_FastDroppers") then
					interval *= Config.FastDropperMultiplier
				end
				for _, dropper in plot.Droppers do
					if now >= dropper.Next then
						dropper.Next = now + interval
						if plot.DropCount < Config.MaxDropsPerPlot then
							spawnDrop(plot, dropper)
						end
					end
				end
			end
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastGlobalAnnounce[player] = nil
	end)
end

return DropService
