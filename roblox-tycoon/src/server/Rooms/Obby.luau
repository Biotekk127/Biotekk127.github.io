--[[
	PLACEHOLDER Brainrot Obby room (Phase 2 will replace this). Contract: docs/PHASE2_CONTRACTS.md
]]

local Room = {}

Room.Id = "Obby"
Room.Name = "Brainrot Obby"
Room.Emoji = "🏙️"
Room.DoorColor = Color3.fromRGB(255, 200, 60)
Room.Scene = require(script.Parent.Parent.Scenes.ObbyScene)

function Room.Build(origin: CFrame, _scene: Model?): { Spawn: CFrame }
	return { Spawn = origin * CFrame.new(0, 4, 0) }
end

function Room.Init(_services, _roomService) end

function Room.OnEnter(_player: Player) end

function Room.OnLeave(_player: Player) end

return Room
