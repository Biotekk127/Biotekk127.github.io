--[[
	Lirilì Larilà (Common)
	The desert elephant-cactus: a big blue-grey elephant head with floppy pink-lined ears,
	a long wrinkled trunk with a pink tip and two little tusks, sitting on a ribbed green
	saguaro body bristling with pale spines. Two stubby grey elephant legs stand in
	oversized brown leather sandals. A golden pocket watch dangles from its right cactus
	arm - it can stop time - and a pink saguaro blossom sits on the left arm.

	Faces -Z. Feet on y = 0. Built only through the CharacterKit builder `k`.
]]

-- Palette ------------------------------------------------------------------------------
local GREY = "#8e97a3" -- elephant skin (slightly blue-grey, like the meme)
local GREY_D = "#6a7380" -- wrinkles, lids, brows
local PINK = "#eda2ad" -- inner ears, trunk tip
local IVORY = "#f3e9d3" -- tusks, toenails
local CACTUS = "#55a141" -- cactus ribs and arms (dominant green)
local CACTUS_D = "#3a7b2e" -- cactus grooves / core
local SPINE = "#fff1c2" -- warm white-yellow spines
local LEATHER = "#9a6331" -- sandal straps
local LEATHER_M = "#7a4a22" -- ankle straps
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
-- theta = degrees around the Y axis measured from the front (-Z) towards +X,
-- tilt = how far the spine points upward.
local function spine(k, cx, y, cz, r, theta, tilt)
	local a = math.rad(theta)
	k:Part({
		Name = "Spine",
		Shape = "Cylinder",
		Size = { 0.42, 0.09, 0.09 },
		Pos = { cx + math.sin(a) * r, y, cz - math.cos(a) * r },
		Rot = { 0, 90 - theta, tilt or 18 },
		Color = SPINE,
	})
end

-- Saguaro body dimensions: 8 vertical ribs around a dark core.
local RIB_R, RIB_W, RIB_H, RIB_Y = 0.88, 0.6, 4.75, 3.8
local function ribAngle(i)
	return i * 45 + 22.5
end
-- radius of the rib ridge at height y (the rib is an ellipsoid, so it tapers top and bottom)
local function ribSurface(y)
	local dy = (y - RIB_Y) / (RIB_H * 0.5)
	return RIB_R + RIB_W * 0.5 * math.sqrt(math.max(0, 1 - dy * dy))
end
-- Where the spines grow: { rib index, height }. Dense on the front and sides (the beauty
-- side), lighter on the back, and kept clear of the trunk and the arm joints.
local BODY_SPINES = {
	{ 0, 2.2 }, { 7, 2.2 }, -- front, under the trunk tip
	{ 0, 5.2 }, { 7, 5.2 }, -- front, beside the trunk root
	{ 1, 2.05 }, { 1, 4.2 }, { 1, 5.25 }, -- right front
	{ 6, 2.3 }, { 6, 4.55 }, { 6, 5.5 }, -- left front
	{ 2, 2.3 }, { 2, 4.4 }, -- right back
	{ 5, 2.1 }, { 5, 4.75 }, -- left back
}

-- One saguaro arm. side = 1 (+X, right) or -1 (-X, left). `extra` builds props in arm space.
local ARM_REACH = 1.4
local ARM_D = 0.8
local function cactusArm(k, side, name, y, up, phase, extra)
	k:Group({
		Name = name,
		Pos = { 0.8 * side, y, 0.05 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.35, Phase = phase },
	}, function()
		k:Part({ Name = "ArmBranch", Shape = "Cylinder", Size = { ARM_REACH, ARM_D, ARM_D }, Pos = { ARM_REACH * 0.5 * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmElbow", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, 0, 0 }, Color = CACTUS })
		k:Part({ Name = "ArmUpright", Shape = "Cylinder", Size = { up, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up * 0.5, 0 }, Rot = UP, Color = CACTUS })
		k:Part({ Name = "ArmTip", Shape = "Ball", Size = { ARM_D, ARM_D, ARM_D }, Pos = { ARM_REACH * side, up, 0 }, Color = CACTUS })
		-- a spine on the outer side of the arm
		spine(k, ARM_REACH * side, up * 0.5, 0, ARM_D * 0.5 + 0.05, 70 * side, 20)
		if extra then
			extra(up)
		end
	end)
end

-- Golden pocket watch hanging on a chain (built in the right arm's space, under the elbow).
local function pocketWatch(k)
	k:Group({
		Name = "PocketWatch",
		Pos = { ARM_REACH, -ARM_D * 0.5 + 0.04, -0.02 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 10, Speed = 0.5 },
	}, function()
		local cy = -0.92 -- watch centre
		local R = 0.72 -- case radius
		k:Part({ Name = "WatchBow", Shape = "Cylinder", Size = { 0.1, 0.4, 0.4 }, Pos = { 0, cy + R + 0.12, 0 }, Rot = FWD, Color = GOLD, Material = "Metal" })
		k:Part({ Name = "WatchCase", Shape = "Cylinder", Size = { 0.28, R * 2, R * 2 }, Pos = { 0, cy, 0 }, Rot = FWD, Color = GOLD, Material = "Foil" })
		k:Part({ Name = "WatchFace", Shape = "Cylinder", Size = { 0.05, R * 1.64, R * 1.64 }, Pos = { 0, cy, -0.14 }, Rot = FWD, Color = CLOCKFACE })
		-- 12 tick marks (the hours); 12/3/6/9 are bigger, 12 is red
		for i = 0, 11 do
			local a = math.rad(i * 30)
			local major = i % 3 == 0
			k:Part({
				Name = "Tick",
				Size = { 0.07, if major then 0.19 else 0.11, 0.05 },
				Pos = { -math.sin(a) * 0.47, cy + math.cos(a) * 0.47, -0.17 },
				Rot = { 0, 0, i * 30 },
				Color = if i == 0 then RED else INK,
			})
		end
		-- the hands spin: time is bending
		k:Group({ Name = "MinuteHand", Pos = { 0, cy, -0.2 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.45 } }, function()
			k:Part({ Name = "MinuteHand", Size = { 0.06, 0.5, 0.05 }, Pos = { 0, 0.19, 0 }, Color = INK })
		end)
		k:Group({ Name = "HourHand", Pos = { 0, cy, -0.225 }, Anim = { Type = "Spin", Axis = "Z", Speed = 0.07, Phase = 0.3 } }, function()
			k:Part({ Name = "HourHand", Size = { 0.1, 0.34, 0.05 }, Pos = { 0, 0.11, 0 }, Color = INK })
		end)
	end)
end

-- A small pink saguaro blossom (on the left arm tip): two crossed petal discs + a heart.
local function blossom(k, x, y, z)
	for i = 0, 1 do
		k:Part({ Name = "Petals", Shape = "Ellipsoid", Size = { 0.6, 0.15, 0.26 }, Pos = { x, y, z }, Rot = { 0, 45 + i * 90, 0 }, Color = FLOWER })
	end
	k:Part({ Name = "FlowerHeart", Shape = "Ball", Size = { 0.2, 0.2, 0.2 }, Pos = { x, y + 0.06, z }, Color = FLOWER_C, Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.6 } })
end

-- Trunk: a chain of nested segments. Each group rotates about X to curl the trunk forward.
-- It hangs long and straight, then curls forward and up at the end (a J).
local TRUNK = {
	{ len = 0.62, d = 0.84, rot = 8, ring = true },
	{ len = 0.62, d = 0.74, rot = 3 },
	{ len = 0.56, d = 0.65, rot = 5, ring = true },
	{ len = 0.48, d = 0.57, rot = 22 },
	{ len = 0.4, d = 0.49, rot = 55 },
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
		if s.ring then
			k:Part({ Name = "TrunkWrinkle", Shape = "Cylinder", Size = { 0.06, s.d + 0.03, s.d + 0.03 }, Pos = { 0, -s.len * 0.5, 0 }, Rot = UP, Color = GREY_D })
		end
		if i < #TRUNK then
			trunkSegment(k, i + 1, s.len)
		else
			-- pink tip with a nostril
			k:Part({ Name = "TrunkTip", Shape = "Ellipsoid", Size = { s.d + 0.05, 0.26, s.d + 0.05 }, Pos = { 0, -s.len - 0.02, 0 }, Color = PINK })
			k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.22, 0.06, 0.15 }, Pos = { 0, -s.len - 0.13, 0 }, Color = INK })
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
			local x, z = 0.68, -0.08
			-- oversized leather sole with a rounded toe
			k:Part({ Name = "SandalSole", Size = { 1.46, 0.3, 1.2 }, Pos = { x, 0.15, z + 0.25 }, Color = LEATHER_D, Material = "Leather" })
			k:Part({ Name = "SandalToe", Shape = "Cylinder", Size = { 0.3, 1.46, 1.46 }, Pos = { x, 0.15, z - 0.35 }, Rot = UP, Color = LEATHER_D, Material = "Leather" })
			-- round elephant foot pad and a stumpy leg column
			k:Part({ Name = "Foot", Shape = "Cylinder", Size = { 0.6, 1.28, 1.28 }, Pos = { x, 0.58, z }, Rot = UP, Color = GREY })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 1.5, 1.06, 1.06 }, Pos = { x, 1.5, z + 0.02 }, Rot = UP, Color = GREY })
			-- three ivory toenails resting on the sole
			for _, th in { -42, 0, 42 } do
				local a = math.rad(th)
				k:Part({ Name = "Toenail", Shape = "Ellipsoid", Size = { 0.32, 0.28, 0.16 }, Pos = { x + math.sin(a) * 0.62, 0.44, z - math.cos(a) * 0.62 }, Rot = { 0, -th, 0 }, Color = IVORY })
			end
			-- straps: wide band over the foot, thin darker ankle band
			k:Part({ Name = "ToeStrap", Shape = "Cylinder", Size = { 0.3, 1.36, 1.36 }, Pos = { x, 0.76, z }, Rot = UP, Color = LEATHER, Material = "Leather" })
			k:Part({ Name = "AnkleStrap", Shape = "Cylinder", Size = { 0.18, 1.14, 1.14 }, Pos = { x, 1.16, z + 0.02 }, Rot = UP, Color = LEATHER_M, Material = "Leather" })
		end)

		-------------------------------------------------------------------- cactus body
		k:Group({ Name = "Body", Anim = { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 0.45 } }, function()
			k:Part({ Name = "CactusBase", Shape = "Ellipsoid", Size = { 2.0, 1.0, 2.0 }, Pos = { 0, 1.9, 0 }, Color = CACTUS_D })
			k:Part({ Name = "CactusCore", Shape = "Cylinder", Size = { 3.8, 1.95, 1.95 }, Pos = { 0, 3.8, 0 }, Rot = UP, Color = CACTUS_D })
			k:Part({ Name = "CactusNeck", Shape = "Ball", Size = { 1.95, 1.95, 1.95 }, Pos = { 0, 5.7, 0 }, Color = CACTUS_D })
			for i = 0, 7 do
				local a = math.rad(ribAngle(i))
				k:Part({ Name = "Rib", Shape = "Ellipsoid", Size = { RIB_W, RIB_H, RIB_W }, Pos = { math.sin(a) * RIB_R, RIB_Y, -math.cos(a) * RIB_R }, Color = CACTUS })
			end
			for _, s in BODY_SPINES do
				spine(k, 0, s[2], 0, ribSurface(s[2]) + 0.06, ribAngle(s[1]), 15)
			end

			-------------------------------------------------------------- arms
			cactusArm(k, -1, "LeftArm", 3.55, 1.2, 0.5, function(up)
				blossom(k, -ARM_REACH, up + ARM_D * 0.5, 0)
			end)
			cactusArm(k, 1, "RightArm", 3.15, 1.2, 0, function()
				pocketWatch(k)
			end)

			-------------------------------------------------------------- elephant head
			k:Group({ Name = "Head", Pos = { 0, 5.8, -0.05 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.3 } }, function()
				k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.75, 2.6, 2.5 }, Pos = { 0, 1.28, 0 }, Color = GREY })
				k:Part({ Name = "Snout", Shape = "Ellipsoid", Size = { 1.3, 1.75, 1.1 }, Pos = { 0, 0.8, -1.0 }, Color = GREY })

				k:Mirror(function()
					-- droopy, deadpan eyes (white + pupil + highlight blink; heavy lid stays)
					local ex, ey, ez, yaw = 0.72, 1.35, -1.0, -29
					local blink = { Type = "Blink", Speed = 0.22 }
					k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.54, 0.5, 0.28 }, Pos = { ex, ey, ez }, Rot = { 0, yaw, 0 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = { ex - 0.03, ey - 0.05, ez - 0.08 }, Color = INK, Anim = blink })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { ex - 0.06, ey - 0.0, ez - 0.2 }, Color = EYE_W, Anim = blink })
					k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.6, 0.32, 0.34 }, Pos = { ex, ey + 0.15, ez - 0.01 }, Rot = { 0, yaw, -10 }, Color = GREY_D })
					k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.6, 0.1, 0.15 }, Pos = { ex - 0.02, ey + 0.43, ez + 0.02 }, Rot = { 0, yaw, -6 }, Color = GREY_D })

					-- small ivory tusks beside the trunk
					k:Part({ Name = "Tusk", Shape = "Ellipsoid", Size = { 0.17, 0.6, 0.17 }, Pos = { 0.45, 0.1, -1.18 }, Rot = { 40, 0, 12 }, Color = IVORY })

					-- big floppy ears with pink insides (flap at the root)
					k:Group({ Name = "Ear", Pos = { 1.08, 1.4, 0.18 }, Rot = { 0, -22, -10 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.5 } }, function()
						k:Part({ Name = "EarOuter", Shape = "Ellipsoid", Size = { 2.1, 2.55, 0.22 }, Pos = { 0.92, -0.3, 0 }, Color = GREY })
						k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 1.62, 2.0, 0.1 }, Pos = { 0.95, -0.32, -0.08 }, Color = PINK })
					end)
				end)

				-- the long curling trunk
				k:Group({ Name = "TrunkRoot", Pos = { 0, 0.4, -1.32 } }, function()
					trunkSegment(k, 1, 0)
				end)
			end)
		end)
	end,

	BuildMini = function(k)
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.0, 1.35, 1.0 }, Pos = { 0, -0.4, 0 }, Color = CACTUS })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.15, 1.0, 1.0 }, Pos = { 0, 0.62, 0 }, Color = GREY })
		k:Part({ Name = "Sandals", Size = { 1.0, 0.18, 0.72 }, Pos = { 0, -1.17, -0.1 }, Color = LEATHER_D })
		k:Part({ Name = "Trunk", Shape = "Ellipsoid", Size = { 0.3, 0.85, 0.3 }, Pos = { 0, 0.15, -0.55 }, Rot = { 15, 0, 0 }, Color = GREY })
		k:Mirror(function()
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.75, 0.9, 0.12 }, Pos = { 0.8, 0.62, 0.08 }, Rot = { 0, -15, -10 }, Color = GREY })
			k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 0.55, 0.68, 0.06 }, Pos = { 0.8, 0.6, 0.0 }, Rot = { 0, -15, -10 }, Color = PINK })
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.16, 0.16, 0.16 }, Pos = { 0.27, 0.76, -0.45 }, Color = INK })
			k:Part({ Name = "CactusArm", Shape = "Cylinder", Size = { 0.7, 0.3, 0.3 }, Pos = { 0.6, -0.3, 0 }, Rot = { 0, 0, 62 }, Color = CACTUS })
		end)
	end,
}
