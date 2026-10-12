--[[
	PLACEHOLDER client side of the Brainrot Obby room (Phase 2 will replace this).
	Contract: docs/PHASE2_CONTRACTS.md
]]

local Room = {}

Room.Id = "Obby"
Room.Lighting = nil -- optional table of Lighting properties applied while inside

function Room.Enter(_ctx) end

function Room.Leave() end

function Room.OnEvent(_eventName: string, _payload: any) end

return Room
