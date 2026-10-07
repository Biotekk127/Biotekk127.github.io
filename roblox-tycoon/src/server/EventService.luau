--[[
	Server-wide boost events (Gold Rush, Cash Frenzy, Rainbow Rain).

	Active events are replicated as attributes on ReplicatedStorage named
	"Event_<Key>" holding the server time the event ends, so the client can show
	banners with live countdowns.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local EventService = {}

local active: { [string]: number } = {} -- key -> server time the event ends
local Remotes

function EventService.Init(services)
	Remotes = services.Remotes
end

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

function EventService.IsActive(key: string): boolean
	local endsAt = active[key]
	return endsAt ~= nil and endsAt > serverNow()
end

function EventService.LuckMultiplier(): number
	local multiplier = 1
	for key in active do
		if EventService.IsActive(key) then
			multiplier *= Config.Events[key].LuckMultiplier
		end
	end
	return multiplier
end

function EventService.CashMultiplier(): number
	local multiplier = 1
	for key in active do
		if EventService.IsActive(key) then
			multiplier *= Config.Events[key].CashMultiplier
		end
	end
	return multiplier
end

-- Starts (or extends) an event. `byPlayer` is credited in the announcement.
function EventService.StartEvent(key: string, byPlayer: Player?)
	local event = Config.Events[key]
	assert(event, "Unknown event " .. key)
	local now = serverNow()
	local endsAt = if EventService.IsActive(key) then active[key] + event.Duration else now + event.Duration
	active[key] = endsAt
	ReplicatedStorage:SetAttribute("Event_" .. key, endsAt)

	local who = if byPlayer then `{byPlayer.DisplayName} started ` else ""
	Remotes.NotifyAll(`{event.Emoji} {who}{event.Name}! {event.Emoji}`, "event")
end

function EventService.Start()
	-- Expire finished events.
	task.spawn(function()
		while true do
			task.wait(1)
			for key, endsAt in active do
				if endsAt <= serverNow() then
					active[key] = nil
					ReplicatedStorage:SetAttribute("Event_" .. key, nil)
					Remotes.NotifyAll(`{Config.Events[key].Name} has ended.`, "info")
				end
			end
		end
	end)

	-- Random free events keep the server feeling alive.
	task.spawn(function()
		local randomKeys = {}
		for key, event in Config.Events do
			if event.Random then
				table.insert(randomKeys, key)
			end
		end
		if #randomKeys == 0 then
			return
		end
		while true do
			task.wait(math.random(Config.RandomEventDelay.Min, Config.RandomEventDelay.Max))
			local key = randomKeys[math.random(1, #randomKeys)]
			if not EventService.IsActive(key) then
				EventService.StartEvent(key)
			end
		end
	end)
end

return EventService
