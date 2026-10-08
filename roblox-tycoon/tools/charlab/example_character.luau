--[[
	EXAMPLE character showing every CharacterKit feature. Not used in the game.
	Read tools/charlab/CHARACTER_GUIDE.md for the full contract.
]]

local SKIN = "#7fd36b"
local DARK = "#1b1b24"

return {
	Id = "ExampleBlob",
	Name = "Example Blob",
	Rarity = "Common",
	Emoji = "🟢",
	Color = SKIN,
	Tagline = "The reference blob.",
	Lore = "Exists only to show how characters are built.",

	Build = function(k)
		-- Feet (mirrored: written once for the left side, the kit creates the right side too)
		k:Mirror(function()
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 1.4, 0.7, 1.9 }, Pos = { 0.9, 0.35, -0.2 }, Color = DARK })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 1.6, 0.7, 0.7 }, Pos = { 0.9, 1.3, 0 }, Rot = { 0, 0, 90 }, Color = SKIN })
		end)

		-- Body
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 3.6, 3.4, 3 }, Pos = { 0, 3.4, 0 }, Color = SKIN })
		k:Part({ Name = "Belly", Shape = "Ellipsoid", Size = { 2.4, 2.4, 0.6 }, Pos = { 0, 3.1, -1.25 }, Color = "#c8f5b8" })

		-- Waving arm: the Group origin is the shoulder, so the Wiggle rotates around it.
		k:Group({ Name = "LeftArm", Pos = { -1.75, 4, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 25, Speed = 0.8 } }, function()
			k:Part({ Name = "UpperArm", Shape = "Cylinder", Size = { 1.6, 0.6, 0.6 }, Pos = { -0.7, 0, 0 }, Color = SKIN })
			k:Part({ Name = "Hand", Shape = "Ball", Size = { 0.8, 0.8, 0.8 }, Pos = { -1.6, 0, 0 }, Color = SKIN })
		end)
		k:Part({ Name = "RightArm", Shape = "Cylinder", Size = { 1.6, 0.6, 0.6 }, Pos = { 2.3, 3.6, 0 }, Rot = { 0, 0, -30 }, Color = SKIN })

		-- Head with a face. Eyes blink.
		k:Group({ Name = "Head", Pos = { 0, 6.3, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 4, Speed = 0.5 } }, function()
			k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 3, 2.6, 2.6 }, Color = SKIN })
			k:Mirror(function()
				k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.8, 1, 0.3 }, Pos = { 0.6, 0.2, -1.2 }, Color = "#ffffff", Anim = { Type = "Blink", Speed = 0.25 } })
				k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.4, 0.4, 0.4 }, Pos = { 0.6, 0.15, -1.35 }, Color = DARK, Anim = { Type = "Blink", Speed = 0.25 } })
				k:Part({ Name = "Cheek", Shape = "Ellipsoid", Size = { 0.6, 0.35, 0.1 }, Pos = { 1, -0.4, -1.12 }, Rot = { 0, -25, 0 }, Color = "#ff8fa3" })
			end)
			k:Part({ Name = "Mouth", Size = { 0.9, 0.18, 0.1 }, Pos = { 0, -0.55, -1.27 }, Color = DARK })
			-- A wedge "party hat": slope faces -Z (front) by default.
			k:Part({ Name = "Hat", Shape = "Wedge", Size = { 1.2, 1.4, 1.2 }, Pos = { 0, 1.8, 0 }, Color = "#ff4fa0", Material = "Neon" })
			k:Part({ Name = "Propeller", Size = { 1.6, 0.08, 0.3 }, Pos = { 0, 2.6, 0 }, Color = "#ffd23a", Anim = { Type = "Spin", Axis = "Y", Speed = 1.5 } })
		end)

		k:Light({ Pos = { 0, 8.5, 0 }, Color = "#ffd23a", Range = 10, Brightness = 1 })
		k:Particles({ Pos = { 0, 7, 0 }, Color = "#9dff7a", Rate = 3, Size = 0.3 })
	end,

	BuildMini = function(k)
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.6, 1.8, 1.4 }, Color = SKIN })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.35, 0.35, 0.35 }, Pos = { 0.3, 0.35, -0.6 }, Color = "#ffffff" })
		end)
		k:Part({ Name = "Hat", Shape = "Wedge", Size = { 0.6, 0.6, 0.6 }, Pos = { 0, 1.1, 0 }, Color = "#ff4fa0", Material = "Neon" })
	end,
}
