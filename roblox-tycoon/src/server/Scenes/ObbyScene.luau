--[[
	PLACEHOLDER scene for the NYC rooftop obby room (Phase 2 will replace this).
	Built with the CharacterKit builder API, so it renders in tools/charlab with --scene.
	Local origin = the room origin; Role = "Exit" parts return players to the hub.
]]

return {
	Name = "ObbyScene",
	Build = function(k)
		k:Part({ Name = "Floor", Size = { 40, 1, 40 }, Pos = { 0, -0.5, 0 }, Color = "#3a3f55", CanCollide = true })
		k:Part({ Name = "ExitPad", Size = { 6, 0.4, 6 }, Pos = { 0, 0.2, 15 }, Color = "#50e080", Material = "Neon", Role = "Exit", CanTouch = true })
	end,
}
