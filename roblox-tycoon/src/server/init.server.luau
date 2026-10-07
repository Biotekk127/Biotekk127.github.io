--[[
	Brainrot Factory Tycoon - server entry point.

	Every service is a ModuleScript under this Script. Init() runs for all services in
	order (wiring, no yielding), then Start() runs for each in its own thread.
]]

local ORDER = {
	"Remotes",
	"WorldBuilder",
	"DataService",
	"EventService",
	"DropService",
	"PlotService",
	"PlayerService",
	"MonetizationService",
	"LeaderboardService",
}

local Services = {}
for _, name in ORDER do
	Services[name] = require(script:WaitForChild(name)) :: any
end
for _, name in ORDER do
	local service = Services[name]
	if service.Init then
		service.Init(Services)
	end
end
for _, name in ORDER do
	local service = Services[name]
	if service.Start then
		task.spawn(service.Start)
	end
end

print("[BrainrotTycoon] Server started")
