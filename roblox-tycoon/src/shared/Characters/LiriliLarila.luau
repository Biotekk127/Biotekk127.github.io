--[[
	Lirilì Larilà (Common)
	The desert elephant-cactus: a big blue-grey elephant head with floppy pink-lined ears,
	a long wrinkled trunk with a pink tip and two little tusks, sitting on a fluted green
	saguaro body bristling with pale spines. Two stubby grey elephant legs stand in
	oversized brown leather sandals. A golden pocket watch dangles from its right cactus
	arm - it can stop time - and a pink saguaro blossom sits on the left arm.

	Faces -Z. Feet on y = 0. Built only through the CharacterKit builder `k`.
]]

-- Palette ------------------------------------------------------------------------------
local GREY = "#8a96a8" -- elephant skin (blue-grey, like the meme)
local GREY_D = "#646f82" -- lids, brows
local GREY_W = "#77839a" -- soft skin wrinkles
local PINK = "#f0a3b1" -- inner ears, trunk tip
local LIP = "#b98892" -- lower lip under the trunk
local IVORY = "#f4ead4" -- tusks, toenails
local CACTUS = "#58a844" -- cactus ribs and arms (dominant green)
local CACTUS_D = "#3d8433" -- cactus grooves / core
local SPINE = "#fff3c8" -- warm white-yellow spines
local LEATHER = "#a5692f" -- sandal straps
local LEATHER_M = "#7f4c22" -- ankle straps
local LEATHER_D = "#5a3517" -- sandal soles
local GOLD = "#e3b94c" -- pocket watch
local CLOCKFACE = "#fff8ec"
local INK = "#1e1a24"
local EYE_W = "#fff8ec"
local FLOWER = "#ff7fb2"
local FLOWER_C = "#ffd34d"

local UP = { 0, 0, 90 } -- rotation that stands a Cylinder upright (axis along Y)
local FWD = { 0, 90, 0 } -- rotation that points a Cylinder along Z (faces front)

-- A spine rod pushed straight through a round body: ONE part gives TWO spines, poking out
-- at angle theta and at theta + 180 (theta in degrees around Y, from the front (-Z) towards
-- +X). r = surface radius at that height, tilt = how far the theta end points upward.
local function spineRod(k, cx, y, cz, r, theta, tilt, stick)
	k:Part({
		Name = "Spines",
		Shape = "Cylinder",
		Size = { 2 * r + 2 * (stick or 0.26), 0.07, 0.07 },
		Pos = { cx, y, cz },
		Rot = { 0, 90 - theta, tilt or 0 },
		Color = SPINE,
	})
end

-- Saguaro body: 10 fluted ribs around a darker core.
local RIBS = 10
local RIB_R, RIB_W, RIB_H, RIB_Y = 0.9, 0.62, 4.9, 4.15
local function ribAngle(i)
	return i * (360 / RIBS) + 18
end
-- radius of the rib ridge at height y (ribs are ellipsoids, so they taper top and bottom)
local function ribSurface(y)
	local dy = (y - RIB_Y) / (RIB_H * 0.5)
	return RIB_R + RIB_W * 0.5 * math.sqrt(math.max(0, 1 - dy * dy))
end
-- Spine rods: { rib index 0..4 (the rod also exits on rib +5), height, tilt }.
-- Front ribs (0 and 9) stay below the trunk; side ribs (2 and 7) stay clear of the arms.
local BODY_SPINES = {
	{ 0, 2.45, 14 }, -- front-right  / back-left
	{ 0, 3.35, -12 },
	{ 4, 2.95, -14 }, -- back-right  / front-left
	{ 1, 2.3, 10 }, -- right-front  / left-back
	{ 1, 4.55, -10 },
	{ 3, 3.95, 12 }, -- right-back   / left-front
	{ 3, 5.35, -12 },
	{ 2, 2.35, 8 }, -- right side   / left side
	{ 2, 5.15, -8 },
}

-- One saguaro arm. side = 1 (+X, right) or -1 (-X, left). `extra` builds props in arm space.
local ARM_ROOT = 0.85
local ARM_REACH = 1.35
local ARM_D = 0.82
local function cactusArm(k, side, name, y, up, phase, extra)
	k:Group({
		Name = name,
		Pos = { ARM_ROOT * side, y, 0.05 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.35, Phase = phase },
	}, function()
		k:Part({ Name = "ArmBranch", Shape = "Cylinder", Size = { ARM_REACH, ARM_D, ARM_D }, Pos = { ARM_REACH * 0.5 * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmElbow", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmUpright", Shape = "Cylinder", Size = { up, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up * 0.5, 0 }, Rot = UP, Color = CACTUS })
		k:Part({ Name = "ArmTip", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up, 0 }, Color = CACTUS })
		-- spine rods: front/back + outer/inner of the upright, top/bottom of the branch
		spineRod(k, ARM_REACH * side, up * 0.55, 0, ARM_D * 0.5, 25 * side, 14, 0.22)
		k:Part({ Name = "Spines", Shape = "Cylinder", Size = { ARM_D + 0.44, 0.07, 0.07 }, Pos = { ARM_REACH * 0.5 * side, 0, -0.08 }, Rot = { 0, 0, 90 - 18 * side }, Color = SPINE })
		if extra then
			extra(up)
		end
	end)
end

-- Golden pocket watch hanging on a chain (built in the right arm's space, under the elbow).
local function pocketWatch(k)
	k:Group({
		Name = "PocketWatch",
		Pos = { ARM_REACH, -ARM_D * 0.5 + 0.02, -0.02 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 9, Speed = 0.5 },
	}, function()
		local R = 0.72 -- case radius
		local cy = -0.46 - R -- watch centre
		k:Part({ Name = "WatchBow", Shape = "Cylinder", Size = { 0.09, 0.4, 0.4 }, Pos = { 0, -0.16, 0 }, Rot = FWD, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchCrown", Shape = "Cylinder", Size = { 0.18, 0.22, 0.22 }, Pos = { 0, cy + R + 0.06, 0 }, Rot = UP, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchCase", Shape = "Cylinder", Size = { 0.3, R * 2, R * 2 }, Pos = { 0, cy, 0 }, Rot = FWD, Color = GOLD, Material = "Foil" })
		k:Part({ Name = "WatchFace", Shape = "Cylinder", Size = { 0.05, R * 1.7, R * 1.7 }, Pos = { 0, cy, -0.15 }, Rot = FWD, Color = CLOCKFACE })
		-- 12 hour ticks from 6 bars through the centre; an inner disc hides their middles.
		-- 12/3/6/9 are longer and bolder.
		for i = 0, 5 do
			local major = i % 3 == 0
			k:Part({
				Name = "Ticks",
				Size = { if major then 0.09 else 0.06, if major then 1.1 else 0.98, 0.05 },
				Pos = { 0, cy, -0.18 },
				Rot = { 0, 0, i * 30 },
				Color = INK,
			})
		end
		k:Part({ Name = "WatchDial", Shape = "Cylinder", Size = { 0.05, 0.8, 0.8 }, Pos = { 0, cy, -0.2 }, Rot = FWD, Color = CLOCKFACE })
		-- the hands spin: time is bending
		k:Group({ Name = "MinuteHand", Pos = { 0, cy, -0.24 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.45 } }, function()
			k:Part({ Name = "MinuteHand", Size = { 0.06, 0.48, 0.05 }, Pos = { 0, 0.2, 0 }, Color = INK })
		end)
		k:Group({ Name = "HourHand", Pos = { 0, cy, -0.265 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.07, Phase = 0.3 } }, function()
			k:Part({ Name = "HourHand", Size = { 0.1, 0.32, 0.05 }, Pos = { 0, 0.11, 0 }, Color = INK })
		end)
		k:Part({ Name = "HandCap", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = { 0, cy, -0.29 }, Color = GOLD, Material = "Metal" })
	end)
end

-- A small pink saguaro blossom (on the left arm tip): two crossed petal discs + a heart.
local function blossom(k, x, y, z)
	for i = 0, 1 do
		k:Part({ Name = "Petals", Shape = "Ellipsoid", Size = { 0.62, 0.16, 0.28 }, Pos = { x, y, z }, Rot = { 0, 45 + i * 90, 0 }, Color = FLOWER })
	end
	k:Part({ Name = "FlowerHeart", Shape = "Ball", Size = { 0.2, 0.2, 0.2 }, Pos = { x, y + 0.07, z }, Color = FLOWER_C, Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.6 } })
end

-- Trunk: a chain of nested segments. Each group rotates about X to curl the trunk forward.
-- It hangs long and straight, then curls forward and up at the end (a J).
local TRUNK = {
	{ len = 0.62, d = 0.86, rot = 8, ring = true },
	{ len = 0.62, d = 0.76, rot = 3 },
	{ len = 0.56, d = 0.67, rot = 5, ring = true },
	{ len = 0.48, d = 0.58, rot = 22 },
	{ len = 0.4, d = 0.5, rot = 55 },
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
		k:Part({ Name = "TrunkSeg", Shape = "Ellipsoid", Size = { s.d, s.len * 1.9, s.d }, Pos = { 0, -s.len * 0.5, 0 }, Color = GREY })
		if s.ring then
			k:Part({ Name = "TrunkWrinkle", Shape = "Cylinder", Size = { 0.06, s.d + 0.02, s.d + 0.02 }, Pos = { 0, -s.len * 0.5, 0 }, Rot = UP, Color = GREY_W })
		end
		if i < #TRUNK then
			trunkSegment(k, i + 1, s.len)
		else
			-- pink tip with a nostril
			k:Part({ Name = "TrunkTip", Shape = "Ellipsoid", Size = { s.d + 0.06, 0.26, s.d + 0.06 }, Pos = { 0, -s.len - 0.02, 0 }, Color = PINK })
			k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.22, 0.06, 0.15 }, Pos = { 0, -s.len - 0.13, 0 }, Color = INK })
		end
	end)
end

return {
	Id = "LiriliLarila",
	Name = "Lirilì Larilà",
	Rarity = "Common",
	Emoji = "🌵",
	Color = "#58a844",
	Tagline = "Tick tock. Lirilì Larilà stopped your time.",
	Lore = "Half elephant, half cactus, fully in sandals. It wanders the desert with a golden pocket watch and can freeze time whenever it feels like a nap. Do not hug it.",

	Build = function(k)
		-------------------------------------------------------------------- legs + sandals
		k:Mirror(function()
			local x, z = 0.74, -0.05
			-- oversized leather sole: a rounded toe in front of a long heel slab
			k:Part({ Name = "SandalSole", Size = { 1.42, 0.28, 1.25 }, Pos = { x, 0.14, z + 0.27 }, Color = LEATHER_D, Material = "Leather" })
			k:Part({ Name = "SandalToe", Shape = "Cylinder", Size = { 0.28, 1.42, 1.42 }, Pos = { x, 0.14, z - 0.35 }, Rot = UP, Color = LEATHER_D, Material = "Leather" })
			-- round elephant foot pad and a stumpy leg column
			k:Part({ Name = "Foot", Shape = "Cylinder", Size = { 0.52, 1.3, 1.3 }, Pos = { x, 0.53, z }, Rot = UP, Color = GREY })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 1.75, 1.12, 1.12 }, Pos = { x, 1.6, z + 0.02 }, Rot = UP, Color = GREY })
			-- three ivory toenails resting on the sole
			for _, th in { -40, 0, 40 } do
				local a = math.rad(th)
				k:Part({ Name = "Toenail", Shape = "Ellipsoid", Size = { 0.32, 0.27, 0.16 }, Pos = { x + math.sin(a) * 0.63, 0.42, z - math.cos(a) * 0.63 }, Rot = { 0, -th, 0 }, Color = IVORY })
			end
			-- straps: a slanted band over the foot (low over the toes, high at the heel),
			-- a thin ankle band and a heel strap joining it to the sole
			k:Part({ Name = "ToeStrap", Shape = "Cylinder", Size = { 0.24, 1.4, 1.4 }, Pos = { x, 0.8, z - 0.02 }, Rot = { -22, 0, 90 }, Color = LEATHER, Material = "Leather" })
			k:Part({ Name = "AnkleStrap", Shape = "Cylinder", Size = { 0.16, 1.18, 1.18 }, Pos = { x, 1.22, z + 0.02 }, Rot = UP, Color = LEATHER_M, Material = "Leather" })
			k:Part({ Name = "HeelStrap", Size = { 0.34, 1.0, 0.14 }, Pos = { x, 0.75, z + 0.62 }, Color = LEATHER_M, Material = "Leather" })
		end)

		-------------------------------------------------------------------- cactus body
		k:Group({ Name = "Body", Anim = { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 0.45 } }, function()
			k:Part({ Name = "CactusBase", Shape = "Ellipsoid", Size = { 2.3, 1.1, 2.3 }, Pos = { 0, 2.2, 0 }, Color = CACTUS })
			k:Part({ Name = "CactusCore", Shape = "Cylinder", Size = { 4.3, 2.0, 2.0 }, Pos = { 0, 4.25, 0 }, Rot = UP, Color = CACTUS_D })
			for i = 0, RIBS - 1 do
				local a = math.rad(ribAngle(i))
				k:Part({ Name = "Rib", Shape = "Ellipsoid", Size = { RIB_W, RIB_H, RIB_W }, Pos = { math.sin(a) * RIB_R, RIB_Y, -math.cos(a) * RIB_R }, Color = CACTUS })
			end
			for _, s in BODY_SPINES do
				spineRod(k, 0, s[2], 0, ribSurface(s[2]), ribAngle(s[1]), s[3])
			end

			-------------------------------------------------------------- arms
			cactusArm(k, -1, "LeftArm", 3.7, 1.2, 0.5, function(up)
				blossom(k, -ARM_REACH, up + ARM_D * 0.5, 0)
			end)
			cactusArm(k, 1, "RightArm", 3.25, 1.2, 0, function()
				pocketWatch(k)
			end)

			-------------------------------------------------------------- elephant head
			k:Group({ Name = "Head", Pos = { 0, 5.85, -0.05 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.3 } }, function()
				k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.8, 2.6, 2.5 }, Pos = { 0, 1.28, 0 }, Color = GREY })
				k:Part({ Name = "Snout", Shape = "Ellipsoid", Size = { 1.35, 1.75, 1.1 }, Pos = { 0, 0.78, -1.0 }, Color = GREY })
				-- deadpan little mouth: a soft lower lip peeking out under the trunk
				k:Part({ Name = "LowerLip", Shape = "Ellipsoid", Size = { 1.08, 0.3, 0.6 }, Pos = { 0, 0.04, -0.95 }, Color = LIP })

				k:Mirror(function()
					-- droopy, deadpan eyes (white + pupil + highlight blink; heavy lid stays)
					local ex, ey, ez, yaw = 0.74, 1.36, -1.0, -29
					local blink = { Type = "Blink", Speed = 0.22 }
					k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.6, 0.55, 0.3 }, Pos = { ex, ey, ez }, Rot = { 0, yaw, 0 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.28, 0.28, 0.28 }, Pos = { ex - 0.04, ey - 0.06, ez - 0.09 }, Color = INK, Anim = blink })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.09, 0.09, 0.09 }, Pos = { ex - 0.08, ey - 0.0, ez - 0.22 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.68, 0.34, 0.36 }, Pos = { ex, ey + 0.16, ez - 0.01 }, Rot = { 0, yaw, -10 }, Color = GREY_D })
					k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.64, 0.13, 0.16 }, Pos = { ex - 0.02, ey + 0.4, ez + 0.03 }, Rot = { 0, yaw, -7 }, Color = GREY_D })

					-- small ivory tusks beside the mouth
					k:Part({ Name = "Tusk", Shape = "Ellipsoid", Size = { 0.18, 0.62, 0.18 }, Pos = { 0.47, 0.06, -1.16 }, Rot = { 40, 0, 12 }, Color = IVORY })

					-- big floppy ears with pink insides and a droopy lower lobe (flap at the root)
					k:Group({ Name = "Ear", Pos = { 1.08, 1.4, 0.2 }, Rot = { 0, -22, -8 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.5 } }, function()
						k:Part({ Name = "EarOuter", Shape = "Ellipsoid", Size = { 2.1, 2.3, 0.22 }, Pos = { 0.94, -0.12, 0 }, Color = GREY })
						k:Part({ Name = "EarLobe", Shape = "Ellipsoid", Size = { 1.5, 1.7, 0.2 }, Pos = { 0.74, -0.98, 0.01 }, Rot = { 0, 0, 24 }, Color = GREY })
						k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 1.6, 2.35, 0.1 }, Pos = { 0.9, -0.44, -0.08 }, Rot = { 0, 0, 8 }, Color = PINK })
					end)
				end)

				-- the long curling trunk
				k:Group({ Name = "TrunkRoot", Pos = { 0, 0.42, -1.32 } }, function()
					trunkSegment(k, 1, 0)
				end)
			end)
		end)
	end,

	BuildMini = function(k)
		-- saguaro column standing in big sandals, elephant head on top
		k:Part({ Name = "Sandals", Size = { 1.12, 0.18, 0.9 }, Pos = { 0, -1.17, -0.14 }, Color = LEATHER_D })
		k:Part({ Name = "Body", Shape = "Cylinder", Size = { 1.5, 0.92, 0.92 }, Pos = { 0, -0.36, 0 }, Rot = UP, Color = CACTUS })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.15, 1.02, 1.0 }, Pos = { 0, 0.64, 0 }, Color = GREY })
		k:Part({ Name = "Trunk", Shape = "Ellipsoid", Size = { 0.3, 0.86, 0.3 }, Pos = { 0, 0.18, -0.58 }, Rot = { 22, 0, 0 }, Color = GREY })
		k:Mirror(function()
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.75, 0.95, 0.12 }, Pos = { 0.8, 0.6, 0.08 }, Rot = { 0, -15, -8 }, Color = GREY })
			k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 0.55, 0.72, 0.06 }, Pos = { 0.8, 0.58, 0.0 }, Rot = { 0, -15, -8 }, Color = PINK })
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.16, 0.16, 0.16 }, Pos = { 0.27, 0.78, -0.45 }, Color = INK })
			-- saguaro arms: rounded columns rising beside the body
			k:Part({ Name = "CactusArm", Shape = "Ellipsoid", Size = { 0.34, 0.8, 0.34 }, Pos = { 0.66, -0.3, 0 }, Rot = { 0, 0, 0 }, Color = CACTUS })
		end)
	end,
}
