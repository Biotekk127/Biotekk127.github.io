--[[
	Lirilì Larilà (Common)
	The desert elephant-cactus: a big grey elephant head with floppy pink-lined ears,
	a long curling trunk and little tusks, sitting on a ribbed green saguaro body covered
	in pale spines. Short grey elephant legs in oversized brown leather sandals. A golden
	pocket watch dangles from its right cactus arm - it can stop time.

	Faces -Z. Feet on y = 0. Built only through the CharacterKit builder `k`.
]]

-- Palette ------------------------------------------------------------------------------
local GREY = "#8e97a3" -- elephant skin (slightly blue-grey, like the meme)
local GREY_D = "#6c7581" -- wrinkles, lids, shading lines
local PINK = "#eda2ad" -- inner ears, trunk tip
local IVORY = "#f3e9d3" -- tusks, toenails
local CACTUS = "#55a141" -- cactus ribs (dominant green)
local CACTUS_D = "#3a7b2e" -- cactus grooves / core
local SPINE = "#fff1c2" -- warm white-yellow spines
local LEATHER = "#94602e" -- sandal straps
local LEATHER_D = "#5e3818" -- sandal soles
local GOLD = "#e2b74b" -- pocket watch
local CLOCKFACE = "#fff8ec"
local INK = "#1e1a24"
local RED = "#d8453a"
local EYE_W = "#fff8ec"
local FLOWER = "#ff7fb2"
local FLOWER_C = "#ffd34d"

local UP = { 0, 0, 90 } -- rotation that stands a Cylinder upright (axis along Y)
local FWD = { 0, 90, 0 } -- rotation that points a Cylinder along Z (faces front)

-- A thin spine sticking out of a round surface.
-- (cx, cz) = centre of the round thing, r = radius where the spine sits,
-- theta = degrees around the Y axis measured from the front (-Z) towards +X.
local function spine(k, cx, y, cz, r, theta, tilt)
	local a = math.rad(theta)
	k:Part({
		Name = "Spine",
		Shape = "Cylinder",
		Size = { 0.4, 0.08, 0.08 },
		Pos = { cx + math.sin(a) * r, y, cz - math.cos(a) * r },
		Rot = { 0, 90 - theta, tilt or 18 },
		Color = SPINE,
	})
end

-- One saguaro arm. side = 1 (+X, right) or -1 (-X, left). `extra` builds props in arm space.
local ARM_REACH = 1.3
local ARM_D = 0.62
local function cactusArm(k, side, name, y, up, phase, extra)
	k:Group({
		Name = name,
		Pos = { 0.75 * side, y, 0.05 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.35, Phase = phase },
	}, function()
		k:Part({ Name = "ArmBranch", Shape = "Cylinder", Size = { ARM_REACH, ARM_D, ARM_D }, Pos = { ARM_REACH * 0.5 * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmElbow", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmUpright", Shape = "Cylinder", Size = { up, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up * 0.5, 0 }, Rot = UP, Color = CACTUS })
		k:Part({ Name = "ArmTip", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up, 0 }, Color = CACTUS })
		-- a spine on the outer side of the arm
		spine(k, ARM_REACH * side, up * 0.45, 0, 0.36, 60 * side, 20)
		if extra then
			extra(up)
		end
	end)
end

-- Golden pocket watch hanging on a chain (built in the right arm's space, under the elbow).
local function pocketWatch(k)
	k:Group({
		Name = "PocketWatch",
		Pos = { ARM_REACH, -0.27, -0.02 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.5 },
	}, function()
		local cy = -0.98 -- watch centre
		k:Part({ Name = "ChainLink", Shape = "Ellipsoid", Size = { 0.12, 0.3, 0.07 }, Pos = { 0, -0.12, 0 }, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchBow", Shape = "Cylinder", Size = { 0.08, 0.3, 0.3 }, Pos = { 0, -0.3, 0 }, Rot = FWD, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchCrown", Shape = "Cylinder", Size = { 0.16, 0.22, 0.22 }, Pos = { 0, cy + 0.65, 0 }, Rot = UP, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchCase", Shape = "Cylinder", Size = { 0.26, 1.25, 1.25 }, Pos = { 0, cy, 0 }, Rot = FWD, Color = GOLD, Material = "Foil" })
		k:Part({ Name = "WatchFace", Shape = "Cylinder", Size = { 0.05, 1.02, 1.02 }, Pos = { 0, cy, -0.13 }, Rot = FWD, Color = CLOCKFACE })
		-- 12 tick marks (the hours); 12/3/6/9 are bigger, 12 is red
		for i = 0, 11 do
			local a = math.rad(i * 30)
			local major = i % 3 == 0
			k:Part({
				Name = "Tick",
				Size = { 0.06, if major then 0.17 else 0.1, 0.05 },
				Pos = { -math.sin(a) * 0.4, cy + math.cos(a) * 0.4, -0.16 },
				Rot = { 0, 0, i * 30 },
				Color = if i == 0 then RED else INK,
			})
		end
		-- hands spin (time is bending)
		k:Group({ Name = "MinuteHand", Pos = { 0, cy, -0.19 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.45 } }, function()
			k:Part({ Name = "MinuteHand", Size = { 0.05, 0.42, 0.05 }, Pos = { 0, 0.15, 0 }, Color = INK })
		end)
		k:Group({ Name = "HourHand", Pos = { 0, cy, -0.215 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.07, Phase = 0.3 } }, function()
			k:Part({ Name = "HourHand", Size = { 0.09, 0.3, 0.05 }, Pos = { 0, 0.09, 0 }, Color = INK })
		end)
	end)
end

-- A small pink saguaro blossom (built on the left arm tip): two crossed petal discs.
local function blossom(k, x, y, z)
	for i = 0, 1 do
		k:Part({ Name = "Petals", Shape = "Ellipsoid", Size = { 0.5, 0.13, 0.22 }, Pos = { x, y, z }, Rot = { 0, 45 + i * 90, 0 }, Color = FLOWER })
	end
	k:Part({ Name = "FlowerHeart", Shape = "Ball", Size = { 0.17, 0.17, 0.17 }, Pos = { x, y + 0.05, z }, Color = FLOWER_C })
end

-- Trunk: a chain of nested segments. Each group rotates about X to curl the trunk forward.
-- It hangs long and straight, then curls forward and up at the end (a J).
local TRUNK = {
	{ len = 0.55, d = 0.8, rot = 8 },
	{ len = 0.55, d = 0.72, rot = 3 },
	{ len = 0.5, d = 0.64, rot = 3 },
	{ len = 0.46, d = 0.57, rot = 12 },
	{ len = 0.4, d = 0.5, rot = 32 },
	{ len = 0.34, d = 0.44, rot = 45 },
}
local function trunkSegment(k, i, offset)
	local s = TRUNK[i]
	local anim = nil
	if i == 1 then
		anim = { Type = "Wiggle", Axis = "Z", Amount = 7, Speed = 0.4 }
	elseif i == 4 then
		anim = { Type = "Wiggle", Axis = "X", Amount = 10, Speed = 0.5, Phase = 0.25 }
	end
	k:Group({ Name = "Trunk" .. i, Pos = { 0, -offset, 0 }, Rot = { s.rot, 0, 0 }, Anim = anim }, function()
		k:Part({ Name = "TrunkSeg", Shape = "Ellipsoid", Size = { s.d, s.len * 1.75, s.d }, Pos = { 0, -s.len * 0.5, 0 }, Color = GREY })
		if i == 3 then
			k:Part({ Name = "TrunkWrinkle", Shape = "Cylinder", Size = { 0.05, s.d + 0.02, s.d + 0.02 }, Pos = { 0, -s.len * 0.5, 0 }, Rot = UP, Color = GREY_D })
		end
		if i < #TRUNK then
			trunkSegment(k, i + 1, s.len)
		else
			-- pink tip with a nostril
			k:Part({ Name = "TrunkTip", Shape = "Ellipsoid", Size = { s.d + 0.04, 0.24, s.d + 0.04 }, Pos = { 0, -s.len - 0.02, 0 }, Color = PINK })
			k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.2, 0.06, 0.14 }, Pos = { 0, -s.len - 0.12, 0 }, Color = INK })
		end
	end)
end

return {
	Id = "LiriliLarila",
	Name = "Lirilì Larilà",
	Rarity = "Common",
	Emoji = "🌵",
	Color = "#55a141",
	Tagline = "Tick tock. Lirilì Larilà stopped your time.",
	Lore = "Half elephant, half cactus, fully in sandals. It wanders the desert with a golden pocket watch and can freeze time whenever it feels like a nap. Do not hug it.",

	Build = function(k)
		-------------------------------------------------------------------- legs + sandals
		k:Mirror(function()
			local x = 0.64
			-- big leather sole: rounded toe + long flat block
			k:Part({ Name = "SandalSole", Size = { 1.3, 0.24, 1.6 }, Pos = { x, 0.12, 0.15 }, Color = LEATHER_D, Material = "Leather" })
			k:Part({ Name = "SandalToe", Shape = "Cylinder", Size = { 0.24, 1.3, 1.3 }, Pos = { x, 0.12, -0.65 }, Rot = UP, Color = LEATHER_D, Material = "Leather" })
			-- round elephant foot with three toenails
			k:Part({ Name = "Foot", Shape = "Cylinder", Size = { 0.48, 1.14, 1.14 }, Pos = { x, 0.47, -0.12 }, Rot = UP, Color = GREY })
			for _, th in { -38, 0, 38 } do
				local a = math.rad(th)
				k:Part({ Name = "Toenail", Shape = "Ellipsoid", Size = { 0.27, 0.24, 0.13 }, Pos = { x + math.sin(a) * 0.56, 0.38, -0.12 - math.cos(a) * 0.56 }, Rot = { 0, -th, 0 }, Color = IVORY })
			end
			-- straps: wide toe band, ankle band, buckle
			k:Part({ Name = "ToeStrap", Size = { 1.22, 0.52, 0.3 }, Pos = { x, 0.5, -0.3 }, Color = LEATHER, Material = "Leather" })
			k:Part({ Name = "AnkleStrap", Shape = "Cylinder", Size = { 0.18, 1.08, 1.08 }, Pos = { x, 0.86, 0 }, Rot = UP, Color = LEATHER, Material = "Leather" })
			k:Part({ Name = "Buckle", Size = { 0.08, 0.18, 0.24 }, Pos = { x + 0.54, 0.86, 0 }, Color = GOLD, Material = "Metal" })
			-- short, thick grey elephant leg
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 1.7, 1.0, 1.0 }, Pos = { x, 1.4, 0 }, Rot = UP, Color = GREY })
		end)

		-------------------------------------------------------------------- cactus body
		k:Group({ Name = "Body", Pos = { 0, -0.15, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 0.45 } }, function()
			k:Part({ Name = "CactusCore", Shape = "Cylinder", Size = { 3.1, 1.8, 1.8 }, Pos = { 0, 3.75, 0 }, Rot = UP, Color = CACTUS_D })
			k:Part({ Name = "CactusBase", Shape = "Ellipsoid", Size = { 1.9, 1.1, 1.9 }, Pos = { 0, 2.2, 0 }, Color = CACTUS_D })
			k:Part({ Name = "CactusDome", Shape = "Ball", Size = { 1.8, 1.8, 1.8 }, Pos = { 0, 5.3, 0 }, Color = CACTUS_D })
			-- 8 vertical ribs, with spines along the ridges
			local RIB_R, RIB_W, RIB_H, RIB_Y = 0.82, 0.5, 3.9, 3.75
			for i = 0, 7 do
				local th = i * 45 + 22.5
				local a = math.rad(th)
				k:Part({ Name = "Rib", Shape = "Ellipsoid", Size = { RIB_W, RIB_H, RIB_W }, Pos = { math.sin(a) * RIB_R, RIB_Y, -math.cos(a) * RIB_R }, Color = CACTUS })
				for j, y in { 2.75, 4.35 } do
					local yy = y + (i % 2) * 0.5 - (j - 1) * 0.1
					local dy = (yy - RIB_Y) / (RIB_H * 0.5)
					local r = RIB_R + RIB_W * 0.5 * math.sqrt(math.max(0, 1 - dy * dy)) + 0.06
					if i ~= 0 and i ~= 7 or j == 1 then -- keep the front spines clear of the trunk
						if not (j == 2 and (i == 3 or i == 4)) then
							spine(k, 0, yy, 0, r, th, 15)
						end
					end
				end
			end

			-------------------------------------------------------------- arms
			cactusArm(k, -1, "LeftArm", 3.4, 1.15, 0.5, function(up)
				blossom(k, -ARM_REACH, up + 0.3, 0)
			end)
			cactusArm(k, 1, "RightArm", 3.15, 1.15, 0, function()
				pocketWatch(k)
			end)

			-------------------------------------------------------------- elephant head
			k:Group({ Name = "Head", Pos = { 0, 5.5, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.3 } }, function()
				k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.5, 2.3, 2.3 }, Pos = { 0, 1.15, 0 }, Color = GREY })
				k:Part({ Name = "Forehead", Shape = "Ellipsoid", Size = { 1.9, 1.2, 1.6 }, Pos = { 0, 1.75, -0.35 }, Color = GREY })
				k:Part({ Name = "Snout", Shape = "Ellipsoid", Size = { 1.15, 1.6, 1.0 }, Pos = { 0, 0.75, -0.95 }, Color = GREY })
				k:Part({ Name = "SnoutWrinkle", Shape = "Ellipsoid", Size = { 0.52, 0.06, 0.1 }, Pos = { 0, 1.05, -1.42 }, Color = GREY_D })

				k:Mirror(function()
					-- droopy, deadpan eyes (white + pupil + highlight blink; heavy lid stays)
					local ex, ey, ez, yaw = 0.66, 1.3, -0.95, -28
					local blink = { Type = "Blink", Speed = 0.22 }
					k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.5, 0.46, 0.26 }, Pos = { ex, ey, ez }, Rot = { 0, yaw, 0 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.24, 0.24, 0.24 }, Pos = { ex - 0.02, ey - 0.04, ez - 0.07 }, Color = INK, Anim = blink })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { ex - 0.05, ey + 0.0, ez - 0.19 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.56, 0.3, 0.32 }, Pos = { ex, ey + 0.14, ez - 0.01 }, Rot = { 0, yaw, -10 }, Color = GREY_D })
					k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.56, 0.1, 0.14 }, Pos = { ex - 0.02, ey + 0.4, ez + 0.0 }, Rot = { 0, yaw, -6 }, Color = GREY_D })

					-- small ivory tusks beside the trunk
					k:Part({ Name = "Tusk", Shape = "Ellipsoid", Size = { 0.16, 0.55, 0.16 }, Pos = { 0.42, 0.1, -1.12 }, Rot = { 40, 0, 12 }, Color = IVORY })

					-- big floppy ears with pink insides (flap at the root)
					k:Group({ Name = "Ear", Pos = { 1.0, 1.35, 0.2 }, Rot = { 0, -22, -12 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.5 } }, function()
						k:Part({ Name = "EarOuter", Shape = "Ellipsoid", Size = { 1.95, 2.35, 0.22 }, Pos = { 0.85, -0.3, 0 }, Color = GREY })
						k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 1.5, 1.85, 0.1 }, Pos = { 0.88, -0.3, -0.07 }, Color = PINK })
					end)
				end)

				-- the long curling trunk
				k:Group({ Name = "TrunkRoot", Pos = { 0, 0.35, -1.25 } }, function()
					trunkSegment(k, 1, 0)
				end)
			end)
		end)
	end,

	BuildMini = function(k)
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.0, 1.4, 1.0 }, Pos = { 0, -0.38, 0 }, Color = CACTUS })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.15, 1.0, 1.0 }, Pos = { 0, 0.62, 0 }, Color = GREY })
		k:Part({ Name = "Trunk", Shape = "Ellipsoid", Size = { 0.3, 0.85, 0.3 }, Pos = { 0, 0.15, -0.55 }, Rot = { 15, 0, 0 }, Color = GREY })
		k:Mirror(function()
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.75, 0.9, 0.12 }, Pos = { 0.82, 0.6, 0.05 }, Rot = { 0, -15, -10 }, Color = PINK })
			k:Part({ Name = "Sandal", Size = { 0.45, 0.16, 0.75 }, Pos = { 0.27, -1.18, -0.08 }, Color = LEATHER })
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.16, 0.16, 0.16 }, Pos = { 0.28, 0.75, -0.46 }, Color = INK })
		end)
		k:Part({ Name = "CactusArmBranch", Shape = "Cylinder", Size = { 0.45, 0.28, 0.28 }, Pos = { -0.55, -0.45, 0 }, Color = CACTUS })
		k:Part({ Name = "CactusArm", Shape = "Cylinder", Size = { 0.6, 0.28, 0.28 }, Pos = { -0.7, -0.2, 0 }, Rot = UP, Color = CACTUS })
		k:Part({ Name = "Watch", Shape = "Cylinder", Size = { 0.12, 0.5, 0.5 }, Pos = { 0.72, -0.55, -0.1 }, Rot = FWD, Color = GOLD, Material = "Foil" })
	end,
}
