--[[
	Cappuccino Assassino (Rare)
	Canonical look: a white ceramic cappuccino cup as the HEAD (side handle, brown crema with
	a white latte-art heart on top, faint steam), a black ninja cloth tied around the top of
	the cup, angry eyes + brows on the cup, a slim black ninja body (sash, wrapped wrists and
	shins, split-toe ninja boots) and TWO katanas, one in each hand, in a crouched stance.

	Rare flair (never changes the design): gleaming Neon katana edges + glints, steam
	particles, one soft warm light over the cup.

	Coordinates: feet on y = 0, faces -Z, right hand at +X. Animated joints use a group whose
	origin is the joint plus an un-animated "frame" group that shifts back, so every part
	inside is still written in world coordinates.
]]

-- Palette ------------------------------------------------------------------------------
local CUP = "#f5efe4" -- dominant head: warm white ceramic
local CUP_SHADE = "#e3d8c6" -- foot ring, handle pads
local CUP_HI = "#fffdf8" -- glaze highlights
local CREMA = "#b0703f" -- coffee crema
local CREMA_DARK = "#7a4524"
local FOAM = "#fff7ea" -- latte-art heart
local FOAM_CREAM = "#ecd8b8" -- foam bubbles

local NINJA = "#25252f" -- dominant body: tinted black
local NINJA_DARK = "#191920"
local NINJA_LIGHT = "#363645" -- lapels, knee pads, folds
local SCARF = "#2c2c38"
local WRAP = "#4b4b5a" -- bandage wraps
local WRAP_LIGHT = "#62627a"
local SASH = "#7a4a2b" -- coffee-brown sash (secondary)
local SASH_DARK = "#5a341d"
local LEATHER = "#4e3220"
local SOLE = "#121218"

local STEEL = "#cdd6e0"
local STEEL_DARK = "#8d97a5"
local GLEAM = "#e6f4ff" -- Neon edge (accent)
local GOLD = "#c9a046"
local ITO = "#1d1d27" -- katana handle wrap
local SAME = "#efe4cc" -- handle diamonds
local IRON = "#3a3a46"

local LINE = "#1b1b24" -- eye rims, brows, mouth
local EYE_WHITE = "#fffaf0"
local IRIS = "#7a2a1c"
local PUPIL = "#121217"
local SHINE = "#ffffff"
local STEAM = "#ffffff"

-- Layout (world studs) -------------------------------------------------------------------
local HIPC = { 0, 3.35, 0 } -- upper-body bob origin
local NECK = { 0, 5.62, -0.06 } -- head pivot
local CZ = -0.08 -- cup axis z
local CUP_R = 1.35 -- cup radius (straight upper wall)
local BOWL_Y = 7.15 -- centre of the round bowl / start of the straight wall
local BOWL_SY = 1.25 -- bowl depth (bottom at 5.9)
local CUP_TOP = 8.4
local BAND_Y = 8.08 -- ninja cloth tied around the cup

-- Torso volumes {cx, cy, cz, ax, ay, az}
local CHEST = { 0, 4.72, -0.04, 0.7, 0.675, 0.45 }
local WAIST = { 0, 3.95, 0, 0.5, 0.375, 0.36 }
local PELVIS = { 0, 3.4, 0.02, 0.575, 0.31, 0.41 }

-- Limb joints (right side; legs are mirrored)
local R_SHOULDER = { 0.72, 5.12, -0.05 }
local R_ELBOW = { 1.38, 4.55, -0.42 }
local R_HAND = { 1.78, 5.15, -0.92 }
local R_BLADE = { 0.41, 0.9, 0.14 } -- raised katana direction

local L_SHOULDER = { -0.72, 5.12, -0.05 }
local L_ELBOW = { -1.36, 4.42, 0.0 }
local L_HAND = { -1.55, 4.32, -0.76 }
local L_BLADE = { -0.45, -0.82, -0.35 } -- low-guard katana direction

local HIP = { 0.42, 3.3, 0.02 }
local KNEE = { 1.0, 1.95, -0.5 }
local ANKLE = { 1.14, 0.62, -0.06 }

-- Helpers --------------------------------------------------------------------------------
local function deg(r)
	return r * 180 / math.pi
end

local function sub(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

local function vlen(v)
	return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

local function lerp(a, b, t)
	return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

-- Rotation (degrees) that points a part's local +Y along direction d
local function aimY(d)
	local l = vlen(d)
	local x, y, z = d[1] / l, d[2] / l, d[3] / l
	return { deg(math.atan2(z, y)), 0, deg(math.asin(-x)) }
end

-- Animated joint: rotates/bobs around p, children keep world coordinates
local function joint(k, name, p, anim, fn)
	k:Group({ Name = name, Pos = p, Anim = anim }, function()
		k:Group({ Name = name .. "Frame", Pos = { -p[1], -p[2], -p[3] } }, fn)
	end)
end

-- Group whose local +Y runs from a to b; fn(L) builds along it
local function seg(k, name, a, b, fn)
	local d = sub(b, a)
	k:Group({ Name = name, Pos = a, Rot = aimY(d) }, function()
		fn(vlen(d))
	end)
end

-- Rounded limb part between two points
local function bone(k, name, a, b, w, d, color, material, shape, extra)
	local v = sub(b, a)
	k:Part({
		Name = name,
		Shape = shape or "Ellipsoid",
		Size = { w, vlen(v) + (extra or 0), d or w },
		Pos = lerp(a, b, 0.5),
		Rot = aimY(v),
		Color = color,
		Material = material or "Fabric",
	})
end

-- Flat cloth strip from a to b, twisted about its length so it reads from several sides
local function ribbon(k, name, a, b, w, color, twist, extra)
	local v = sub(b, a)
	k:Group({ Name = name, Pos = lerp(a, b, 0.5), Rot = aimY(v) }, function()
		k:Part({ Name = name, Size = { w, vlen(v) + (extra or 0.08), 0.05 }, Rot = { 0, twist, 0 }, Color = color, Material = "Fabric" })
	end)
end

-- Front (side = -1) or back (side = 1) surface z of the torso at (x, y)
local function torsoZ(x, y, side)
	local best = nil
	for _, e in ipairs({ CHEST, WAIST, PELVIS }) do
		local f = ((x - e[1]) / e[4]) ^ 2 + ((y - e[2]) / e[5]) ^ 2
		if f < 1 then
			local z = e[3] + side * e[6] * math.sqrt(1 - f)
			if best == nil or z * side > best * side then
				best = z
			end
		end
	end
	return best or 0
end

-- Strap that hugs the torso through a list of {x, y} points
local function strap(k, name, pts, side, out, w, color)
	for i = 1, #pts - 1 do
		local a = { pts[i][1], pts[i][2], torsoZ(pts[i][1], pts[i][2], side) + side * out }
		local b = { pts[i + 1][1], pts[i + 1][2], torsoZ(pts[i + 1][1], pts[i + 1][2], side) + side * out }
		bone(k, name, a, b, w, 0.06, color, "Leather", "Block", 0.06)
	end
end

-- Cup surface radius at height y (round bowl below BOWL_Y, straight wall above)
local function cupRadius(y)
	if y >= BOWL_Y then
		return CUP_R
	end
	local f = (BOWL_Y - y) / BOWL_SY
	return CUP_R * math.sqrt(math.max(0, 1 - f * f))
end

-- Point on the cup surface at height y and angle a (0 = front, + toward +X), pushed `out`
-- along the normal. Returns position and a rotation whose local -Z faces outward.
local function cupFrame(y, a, out)
	local r = cupRadius(y)
	local ar = math.rad(a)
	local tilt = 0
	if y < BOWL_Y then
		tilt = deg(math.atan2((BOWL_Y - y) / (BOWL_SY * BOWL_SY), r / (CUP_R * CUP_R)))
	end
	local tr = math.rad(tilt)
	local nx, ny, nz = math.sin(ar) * math.cos(tr), -math.sin(tr), -math.cos(ar) * math.cos(tr)
	return { r * math.sin(ar) + nx * out, y + ny * out, CZ - r * math.cos(ar) + nz * out }, { -tilt, -a, 0 }
end

--------------------------------------------------------------------------------------------
-- Katana, built along local +Y from the grip centre (spine at +X, edge at -X, flats face Z)
--------------------------------------------------------------------------------------------
local function katana(k, glintPhase, sparkle)
	-- handle (tsuka)
	k:Part({ Name = "Kashira", Shape = "Cylinder", Size = { 0.08, 0.21, 0.21 }, Pos = { 0, -0.52, 0 }, Rot = { 0, 0, 90 }, Color = GOLD, Material = "Foil" })
	k:Part({ Name = "Tsuka", Shape = "Cylinder", Size = { 0.84, 0.17, 0.17 }, Pos = { 0, -0.08, 0 }, Rot = { 0, 0, 90 }, Color = ITO, Material = "Fabric" })
	for _, y in ipairs({ -0.4, -0.22 }) do
		for _, z in ipairs({ -0.08, 0.08 }) do
			k:Part({ Name = "TsukaDiamond", Size = { 0.09, 0.09, 0.05 }, Pos = { 0, y, z }, Rot = { 0, 0, 45 }, Color = SAME })
		end
	end
	k:Part({ Name = "Fuchi", Shape = "Cylinder", Size = { 0.06, 0.2, 0.2 }, Pos = { 0, 0.34, 0 }, Rot = { 0, 0, 90 }, Color = GOLD, Material = "Foil" })
	-- guard (tsuba): gold rim around a dark iron centre
	k:Part({ Name = "Tsuba", Shape = "Cylinder", Size = { 0.05, 0.52, 0.52 }, Pos = { 0, 0.39, 0 }, Rot = { 0, 0, 90 }, Color = GOLD, Material = "Foil" })
	k:Part({ Name = "TsubaIron", Shape = "Cylinder", Size = { 0.08, 0.4, 0.4 }, Pos = { 0, 0.39, 0 }, Rot = { 0, 0, 90 }, Color = IRON, Material = "Metal" })
	k:Part({ Name = "Habaki", Size = { 0.22, 0.12, 0.09 }, Pos = { 0, 0.48, 0 }, Color = GOLD, Material = "Foil" })
	-- blade
	k:Part({ Name = "Blade", Size = { 0.2, 2.3, 0.06 }, Pos = { 0, 1.6, 0 }, Color = STEEL, Material = "Metal", Reflectance = 0.3 })
	k:Part({ Name = "BladeTip", Shape = "Wedge", Size = { 0.06, 0.38, 0.2 }, Pos = { 0, 2.94, 0 }, Rot = { 0, 90, 0 }, Color = STEEL, Material = "Metal", Reflectance = 0.3 })
	k:Part({ Name = "EdgeGleam", Size = { 0.05, 2.3, 0.07 }, Pos = { -0.085, 1.6, 0 }, Color = GLEAM, Material = "Neon" })
	k:Part({ Name = "Bohi", Size = { 0.05, 1.8, 0.07 }, Pos = { 0.045, 1.35, 0 }, Color = STEEL_DARK, Material = "Metal" })
	-- pulsing glint near the tip + a sparkle emitter on the raised blade (Rare flair)
	local glint = { Type = "Pulse", Amount = 0.35, Speed = 0.7, Phase = glintPhase }
	if sparkle then
		k:Particles({ Pos = { 0, 1.9, 0 }, Color = GLEAM, Color2 = "#ffffff", Rate = 2, Size = 0.14, Speed = 0.25, Lifetime = 0.7, Spread = 180 })
	end
	k:Part({ Name = "Glint", Shape = "Ball", Size = { 0.11, 0.11, 0.11 }, Pos = { -0.06, 2.62, 0 }, Color = SHINE, Material = "Neon", Anim = glint })
	-- gloved fist around the handle
	k:Part({ Name = "Fist", Shape = "Ellipsoid", Size = { 0.38, 0.44, 0.36 }, Pos = { 0, 0.11, 0 }, Color = NINJA, Material = "Fabric" })
	k:Part({ Name = "Thumb", Shape = "Ball", Size = { 0.15, 0.15, 0.15 }, Pos = { 0.08, 0.3, -0.12 }, Color = NINJA, Material = "Fabric" })
end

--------------------------------------------------------------------------------------------
-- Arm: shoulder -> elbow -> hand, with wrist wraps and a katana in the fist
--------------------------------------------------------------------------------------------
local function arm(k, name, S, E, H, bladeDir, shoulderAnim, elbowAnim, wristAnim, glintPhase)
	joint(k, name, S, shoulderAnim, function()
		k:Part({ Name = "Shoulder", Shape = "Ball", Size = { 0.5, 0.5, 0.5 }, Pos = S, Color = NINJA, Material = "Fabric" })
		bone(k, "UpperArm", S, E, 0.42, 0.42, NINJA, "Fabric", "Ellipsoid", 0.2)
		joint(k, name .. "Forearm", E, elbowAnim, function()
			k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.34, 0.34, 0.34 }, Pos = E, Color = NINJA, Material = "Fabric" })
			seg(k, "Forearm", E, H, function(L)
				k:Part({ Name = "ForearmCore", Shape = "Ellipsoid", Size = { 0.38, L + 0.1, 0.38 }, Pos = { 0, L * 0.45, 0 }, Color = NINJA, Material = "Fabric" })
				for i, f in ipairs({ 0.58, 0.76 }) do
					local tilt = if i % 2 == 0 then -10 else 10
					k:Part({ Name = "WristWrap", Shape = "Cylinder", Size = { 0.12, 0.38, 0.38 }, Pos = { 0, L * f, 0 }, Rot = { tilt, 0, 90 }, Color = if i == 2 then WRAP_LIGHT else WRAP, Material = "Fabric" })
				end
			end)
			joint(k, name .. "Katana", H, wristAnim, function()
				k:Group({ Name = name .. "Blade", Pos = H, Rot = aimY(bladeDir) }, function()
					katana(k, glintPhase, glintPhase == 0)
				end)
			end)
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Cup head (world coordinates, built inside the head joint)
--------------------------------------------------------------------------------------------
local function cupHead(k)
	-- big forms: round bowl + straight wall + rim + foot ring
	k:Part({ Name = "CupBowl", Shape = "Ellipsoid", Size = { CUP_R * 2, BOWL_SY * 2, CUP_R * 2 }, Pos = { 0, BOWL_Y, CZ }, Color = CUP, Reflectance = 0.06 })
	k:Part({ Name = "CupWall", Shape = "Cylinder", Size = { CUP_TOP - BOWL_Y, CUP_R * 2, CUP_R * 2 }, Pos = { 0, (CUP_TOP + BOWL_Y) / 2, CZ }, Rot = { 0, 0, 90 }, Color = CUP, Reflectance = 0.06 })
	k:Part({ Name = "CupLip", Shape = "Cylinder", Size = { 0.1, CUP_R * 2 + 0.1, CUP_R * 2 + 0.1 }, Pos = { 0, CUP_TOP + 0.03, CZ }, Rot = { 0, 0, 90 }, Color = CUP_HI, Reflectance = 0.06 })
	k:Part({ Name = "CupFoot", Shape = "Cylinder", Size = { 0.14, 1.25, 1.25 }, Pos = { 0, 5.88, CZ }, Rot = { 0, 0, 90 }, Color = CUP_SHADE })

	-- coffee: domed crema with a white latte-art heart (point toward the front)
	k:Part({ Name = "Crema", Shape = "Ellipsoid", Size = { 2.6, 0.28, 2.6 }, Pos = { 0, 8.41, CZ }, Color = CREMA })
	k:Part({ Name = "CremaRing", Shape = "Ellipsoid", Size = { 2.0, 0.26, 2.0 }, Pos = { 0, 8.425, CZ }, Color = "#c58552" })
	k:Mirror(function()
		k:Part({ Name = "HeartLobe", Shape = "Ellipsoid", Size = { 0.7, 0.08, 0.7 }, Pos = { 0.26, 8.54, CZ + 0.2 }, Color = FOAM })
	end)
	k:Part({ Name = "HeartPoint", Size = { 0.68, 0.07, 0.68 }, Pos = { 0, 8.535, CZ - 0.06 }, Rot = { 0, 45, 0 }, Color = FOAM })
	-- foam bubbles around the crema edge
	for i = 0, 3 do
		local a = math.rad(50 + i * 85)
		local r = 0.98 + (i % 3) * 0.05
		local s = 0.1 + (i % 2) * 0.05
		k:Part({ Name = "FoamBubble", Shape = "Ball", Size = { s, s, s }, Pos = { math.sin(a) * r, 8.48, CZ - math.cos(a) * r }, Color = FOAM_CREAM })
	end

	-- handle on the left side (-X): a C-loop of short cylinders
	local HCX, HCY, HR = -1.42, 7.62, 0.42
	for i = 0, 3 do
		local m = math.rad(90 + 22.5 + i * 45)
		k:Part({ Name = "Handle", Shape = "Cylinder", Size = { 0.36, 0.21, 0.21 }, Pos = { HCX + math.cos(m) * HR, HCY + math.sin(m) * HR, CZ }, Rot = { 0, 0, deg(m) + 90 }, Color = CUP, Reflectance = 0.06 })
	end
	for i = 1, 3 do
		local m = math.rad(90 + i * 45)
		k:Part({ Name = "HandleJoint", Shape = "Ball", Size = { 0.21, 0.21, 0.21 }, Pos = { HCX + math.cos(m) * HR, HCY + math.sin(m) * HR, CZ }, Color = CUP })
	end
	k:Part({ Name = "HandlePadTop", Shape = "Ellipsoid", Size = { 0.24, 0.26, 0.3 }, Pos = { -cupRadius(HCY + HR) - 0.04, HCY + HR, CZ }, Color = CUP_SHADE })
	k:Part({ Name = "HandlePadLow", Shape = "Ellipsoid", Size = { 0.24, 0.26, 0.3 }, Pos = { -cupRadius(HCY - HR) - 0.04, HCY - HR, CZ }, Color = CUP_SHADE })

	-- ninja cloth tied around the cup, with a steel plate and a coffee-bean emblem
	k:Part({ Name = "NinjaBand", Shape = "Cylinder", Size = { 0.38, CUP_R * 2 + 0.08, CUP_R * 2 + 0.08 }, Pos = { 0, BAND_Y, CZ }, Rot = { 0, 0, 90 }, Color = NINJA_DARK, Material = "Fabric" })
	k:Part({ Name = "BandFold", Shape = "Cylinder", Size = { 0.14, CUP_R * 2 + 0.12, CUP_R * 2 + 0.12 }, Pos = { 0, BAND_Y - 0.05, CZ }, Rot = { 6, 0, 90 }, Color = NINJA, Material = "Fabric" })
	for _, a in ipairs({ -15, 0, 15 }) do
		local p, r = cupFrame(BAND_Y, a, 0.08)
		k:Part({ Name = "BandPlate", Size = { if a == 0 then 0.38 else 0.34, 0.3, 0.05 }, Pos = p, Rot = r, Color = STEEL, Material = "Metal", Reflectance = 0.25 })
	end
	k:Mirror(function()
		for _, y in ipairs({ BAND_Y + 0.09, BAND_Y - 0.09 }) do
			local p, r = cupFrame(y, 20, 0.11)
			k:Part({ Name = "PlateRivet", Shape = "Ball", Size = { 0.06, 0.06, 0.06 }, Pos = p, Rot = r, Color = STEEL_DARK, Material = "Metal" })
		end
	end)
	do
		local p, r = cupFrame(BAND_Y, 0, 0.12)
		k:Part({ Name = "BeanEmblem", Shape = "Ellipsoid", Size = { 0.24, 0.16, 0.05 }, Pos = p, Rot = { r[1], r[2], 20 }, Color = CREMA_DARK })
		local p2, r2 = cupFrame(BAND_Y, 0, 0.14)
		k:Part({ Name = "BeanCrease", Size = { 0.05, 0.14, 0.05 }, Pos = p2, Rot = { r2[1], r2[2], 20 + 90 - 15 }, Color = LINE })
	end
	-- knot at the back
	local knot, kr = cupFrame(BAND_Y, 180, 0.1)
	k:Part({ Name = "BandKnot", Shape = "Ellipsoid", Size = { 0.34, 0.3, 0.24 }, Pos = knot, Rot = kr, Color = NINJA_DARK, Material = "Fabric" })
	k:Mirror(function()
		k:Part({ Name = "KnotLoop", Shape = "Ellipsoid", Size = { 0.32, 0.18, 0.14 }, Pos = { 0.24, knot[2] + 0.06, knot[3] - 0.02 }, Rot = { 0, 0, 25 }, Color = NINJA, Material = "Fabric" })
	end)
	-- fluttering tails
	joint(k, "BandTails", knot, { Type = "Wiggle", Axis = "Y", Amount = 14, Speed = 0.55, Phase = 0.1 }, function()
		joint(k, "TailA", knot, { Type = "Wiggle", Axis = "X", Amount = 10, Speed = 0.8, Phase = 0 }, function()
			local a1 = { knot[1] + 0.25, knot[2] - 0.4, knot[3] + 0.6 }
			local a2 = { knot[1] + 0.5, knot[2] - 0.85, knot[3] + 1.05 }
			ribbon(k, "BandTail", knot, a1, 0.24, NINJA_DARK, 40, 0.1)
			ribbon(k, "BandTailEnd", a1, a2, 0.22, NINJA_DARK, 60, 0.06)
		end)
		joint(k, "TailB", knot, { Type = "Wiggle", Axis = "X", Amount = 12, Speed = 0.8, Phase = 0.35 }, function()
			local b1 = { knot[1] - 0.15, knot[2] - 0.55, knot[3] + 0.5 }
			local b2 = { knot[1] - 0.35, knot[2] - 1.05, knot[3] + 0.82 }
			ribbon(k, "BandTail", knot, b1, 0.24, NINJA_DARK, -40, 0.1)
			ribbon(k, "BandTailEnd", b1, b2, 0.22, NINJA_DARK, -60, 0.06)
		end)
	end)

	-- angry face
	local BLINK = { Type = "Blink", Speed = 0.28, Phase = 0.15 }
	k:Mirror(function()
		local p, r = cupFrame(7.3, 21, 0)
		k:Group({ Name = "Eye", Pos = p, Rot = r }, function()
			k:Part({ Name = "EyeRim", Shape = "Ellipsoid", Size = { 0.78, 0.66, 0.1 }, Color = LINE })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.66, 0.55, 0.12 }, Pos = { 0, -0.01, -0.03 }, Color = EYE_WHITE, Anim = BLINK })
			k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.3, 0.34, 0.08 }, Pos = { -0.04, -0.06, -0.08 }, Color = IRIS, Anim = BLINK })
			k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.16, 0.2, 0.06 }, Pos = { -0.04, -0.06, -0.11 }, Color = PUPIL, Anim = BLINK })
			k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { 0.03, 0.0, -0.13 }, Color = SHINE, Material = "Neon", Anim = BLINK })
			k:Part({ Name = "AngryLid", Size = { 0.84, 0.2, 0.06 }, Pos = { -0.02, 0.25, -0.07 }, Rot = { 0, 0, 22 }, Color = LINE })
		end)
		local bp, br = cupFrame(7.76, 19, 0)
		k:Part({ Name = "Brow", Size = { 0.74, 0.17, 0.1 }, Pos = bp, Rot = { br[1], br[2], 24 }, Color = LINE })
	end)
	do
		local p, r = cupFrame(6.62, 0, 0)
		k:Group({ Name = "Mouth", Pos = p, Rot = r }, function()
			k:Part({ Name = "MouthMid", Size = { 0.22, 0.07, 0.07 }, Pos = { 0, 0.02, 0 }, Color = LINE })
			k:Mirror(function()
				k:Part({ Name = "MouthSide", Size = { 0.2, 0.07, 0.07 }, Pos = { 0.18, -0.01, 0.005 }, Rot = { 0, 0, -22 }, Color = LINE })
			end)
		end)
	end

	-- steam wisps + steam particles + warm light (Rare flair)
	local function wisp(x, z, y0, n, phase)
		for i = 1, n do
			local sway = if i % 2 == 0 then 0.07 else -0.07
			local sz = 0.2 - i * 0.025
			k:Part({
				Name = "SteamWisp",
				Shape = "Ellipsoid",
				Size = { sz, 0.3, sz },
				Pos = { x + sway, y0 + (i - 1) * 0.22, z },
				Rot = { 0, 0, if i % 2 == 0 then -32 else 32 },
				Color = STEAM,
				Transparency = 0.5 + i * 0.07,
				Anim = { Type = "Bob", Axis = "Y", Amount = 0.06, Speed = 0.5, Phase = phase + i * 0.12 },
			})
		end
	end
	wisp(-0.45, CZ + 0.4, 8.82, 3, 0)
	wisp(0.5, CZ + 0.3, 8.8, 2, 0.5)
	k:Particles({ Pos = { 0, 8.7, CZ }, Color = "#ffffff", Color2 = "#f1e4cf", Rate = 3, Size = 0.35, Speed = 0.8, Lifetime = 1.8, Spread = 18, Direction = "Top" })
	k:Light({ Pos = { 0, 9.0, CZ - 0.4 }, Color = "#ffe2b8", Range = 9, Brightness = 0.8 })
end

--------------------------------------------------------------------------------------------
-- Torso, sash, straps and the crossed scabbards on the back (world coordinates)
--------------------------------------------------------------------------------------------
local function torso(k)
	local function vol(name, e, color)
		k:Part({ Name = name, Shape = "Ellipsoid", Size = { e[4] * 2, e[5] * 2, e[6] * 2 }, Pos = { e[1], e[2], e[3] }, Color = color, Material = "Fabric" })
	end
	vol("Chest", CHEST, NINJA)
	k:Part({ Name = "UpperChest", Shape = "Ellipsoid", Size = { 1.62, 0.78, 0.84 }, Pos = { 0, 5.02, -0.04 }, Color = NINJA, Material = "Fabric" })
	vol("Waist", WAIST, NINJA)
	vol("Pelvis", PELVIS, NINJA)
	k:Part({ Name = "Collar", Shape = "Ellipsoid", Size = { 0.9, 0.3, 0.74 }, Pos = { 0, 5.38, -0.05 }, Color = NINJA_LIGHT, Material = "Fabric" })
	k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.55, 0.44, 0.44 }, Pos = { 0, 5.6, -0.06 }, Rot = { 0, 0, 90 }, Color = NINJA_DARK, Material = "Fabric" })
	-- neck scarf the cup rests on, with a short fluttering tail
	k:Part({ Name = "Scarf", Shape = "Ellipsoid", Size = { 0.92, 0.42, 0.8 }, Pos = { 0, 5.6, -0.06 }, Color = SCARF, Material = "Fabric" })
	k:Part({ Name = "ScarfFold", Shape = "Ellipsoid", Size = { 0.96, 0.12, 0.84 }, Pos = { 0, 5.52, -0.06 }, Rot = { 6, 0, 0 }, Color = NINJA_LIGHT, Material = "Fabric" })
	local SCK = { 0.12, 5.6, 0.32 }
	joint(k, "ScarfTail", SCK, { Type = "Wiggle", Axis = "X", Amount = 14, Speed = 0.6, Phase = 0.45 }, function()
		ribbon(k, "ScarfTail", SCK, { 0.3, 5.1, 0.78 }, 0.26, SCARF, 35, 0.08)
	end)

	-- crossed gi lapels (V neckline) and a mesh undershirt peeking out
	k:Mirror(function()
		strap(k, "Lapel", { { 0.34, 5.28 }, { 0.16, 4.98 }, { -0.04, 4.6 } }, -1, 0.015, 0.16, NINJA_LIGHT)
	end)

	-- diagonal shoulder strap with a shuriken
	strap(k, "ChestStrap", { { 0.52, 5.12 }, { 0.22, 4.68 }, { -0.12, 4.2 }, { -0.42, 3.82 } }, -1, 0.03, 0.17, LEATHER)
	do
		local x, y = 0.07, 4.45
		local z = torsoZ(x, y, -1) - 0.08
		k:Part({ Name = "Shuriken", Size = { 0.4, 0.09, 0.05 }, Pos = { x, y, z }, Rot = { 0, 0, 45 }, Color = STEEL, Material = "Metal", Reflectance = 0.2 })
		k:Part({ Name = "Shuriken", Size = { 0.4, 0.09, 0.05 }, Pos = { x, y, z }, Rot = { 0, 0, -45 }, Color = STEEL, Material = "Metal", Reflectance = 0.2 })
		k:Part({ Name = "ShurikenHub", Shape = "Cylinder", Size = { 0.06, 0.12, 0.12 }, Pos = { x, y, z - 0.01 }, Rot = { 0, 90, 0 }, Color = IRON, Material = "Metal" })
	end
	strap(k, "BackStrap", { { 0.52, 5.12 }, { 0.15, 4.6 }, { -0.2, 4.1 }, { -0.45, 3.8 } }, 1, 0.03, 0.17, LEATHER)

	-- coffee-brown sash with a front knot and fluttering ends
	k:Part({ Name = "Sash", Shape = "Ellipsoid", Size = { 1.12, 0.34, 0.84 }, Pos = { 0, 3.74, 0.0 }, Color = SASH, Material = "Fabric" })
	local SK = { -0.3, 3.72, -0.42 }
	k:Part({ Name = "SashKnot", Shape = "Ellipsoid", Size = { 0.26, 0.24, 0.16 }, Pos = SK, Color = SASH, Material = "Fabric" })
	joint(k, "SashTails", SK, { Type = "Wiggle", Axis = "X", Amount = 12, Speed = 0.7, Phase = 0.25 }, function()
		bone(k, "SashTail", SK, { -0.4, 3.12, -0.52 }, 0.16, 0.05, SASH, "Fabric", "Block", 0.06)
		bone(k, "SashTail", SK, { -0.18, 3.2, -0.5 }, 0.15, 0.05, SASH_DARK, "Fabric", "Block", 0.06)
	end)

	-- leather pouch on the back of the sash
	k:Part({ Name = "Pouch", Size = { 0.34, 0.3, 0.16 }, Pos = { 0.36, 3.6, 0.43 }, Rot = { 0, 22, 0 }, Color = LEATHER, Material = "Leather" })
	k:Part({ Name = "PouchFlap", Size = { 0.36, 0.12, 0.19 }, Pos = { 0.36, 3.72, 0.44 }, Rot = { 0, 22, 0 }, Color = SASH_DARK, Material = "Leather" })

	-- two empty scabbards crossed on the back
	local function saya(name, top, bot)
		local d = sub(bot, top)
		k:Group({ Name = name, Pos = top, Rot = aimY(d) }, function()
			local L = vlen(d)
			k:Part({ Name = "Saya", Size = { 0.2, L, 0.13 }, Pos = { 0, L / 2, 0 }, Color = NINJA_DARK, Material = "SmoothPlastic", Reflectance = 0.12 })
			k:Part({ Name = "Koiguchi", Size = { 0.24, 0.12, 0.17 }, Pos = { 0, 0.06, 0 }, Color = GOLD, Material = "Foil" })
			k:Part({ Name = "Kojiri", Size = { 0.24, 0.14, 0.17 }, Pos = { 0, L - 0.05, 0 }, Color = GOLD, Material = "Foil" })
			for _, f in ipairs({ 0.24 }) do
				k:Part({ Name = "Sageo", Size = { 0.23, 0.06, 0.16 }, Pos = { 0, L * f, 0 }, Color = SASH, Material = "Fabric" })
			end
		end)
	end
	saya("SayaA", { 0.66, 5.72, 0.44 }, { -0.5, 3.66, 0.52 })
	saya("SayaB", { -0.66, 5.72, 0.56 }, { 0.5, 3.66, 0.64 })
end

--------------------------------------------------------------------------------------------
-- Leg (right side, mirrored): baggy pants, knee pad, wrapped shin, split-toe boot
--------------------------------------------------------------------------------------------
local function leg(k)
	bone(k, "Thigh", HIP, KNEE, 0.62, 0.62, NINJA, "Fabric", "Ellipsoid", 0.3)
	k:Part({ Name = "Knee", Shape = "Ball", Size = { 0.52, 0.52, 0.52 }, Pos = KNEE, Color = NINJA, Material = "Fabric" })
	k:Part({ Name = "KneePad", Shape = "Ellipsoid", Size = { 0.42, 0.46, 0.18 }, Pos = { KNEE[1] + 0.03, KNEE[2] + 0.03, KNEE[3] - 0.22 }, Rot = { -12, -18, 0 }, Color = NINJA_LIGHT, Material = "Fabric" })
	seg(k, "Shin", KNEE, ANKLE, function(L)
		k:Part({ Name = "ShinCore", Shape = "Cylinder", Size = { L, 0.4, 0.4 }, Pos = { 0, L / 2, 0 }, Rot = { 0, 0, 90 }, Color = NINJA, Material = "Fabric" })
		for i = 1, 4 do
			local f = 0.12 + i * 0.17
			local tilt = if i % 2 == 0 then -9 else 9
			k:Part({ Name = "ShinWrap", Shape = "Cylinder", Size = { 0.12, 0.46, 0.46 }, Pos = { 0, L * f, 0 }, Rot = { tilt, 0, 90 }, Color = if i % 2 == 0 then WRAP_LIGHT else WRAP, Material = "Fabric" })
		end
	end)
	k:Part({ Name = "BootCuff", Shape = "Ellipsoid", Size = { 0.52, 0.46, 0.54 }, Pos = { ANKLE[1] + 0.02, 0.54, ANKLE[3] - 0.02 }, Color = NINJA_DARK, Material = "Fabric" })
	k:Group({ Name = "Boot", Pos = { 1.18, 0.22, -0.3 }, Rot = { 0, -14, 0 } }, function()
		k:Part({ Name = "Tabi", Shape = "Ellipsoid", Size = { 0.54, 0.44, 1.0 }, Pos = { 0.02, 0, 0.02 }, Color = NINJA_DARK, Material = "Fabric" })
		k:Part({ Name = "BigToe", Shape = "Ellipsoid", Size = { 0.2, 0.26, 0.36 }, Pos = { -0.16, -0.06, -0.38 }, Color = NINJA_DARK, Material = "Fabric" })
		k:Part({ Name = "ToeSplit", Size = { 0.05, 0.18, 0.22 }, Pos = { -0.06, -0.06, -0.42 }, Color = LINE })
		k:Part({ Name = "Sole", Shape = "Ellipsoid", Size = { 0.58, 0.1, 1.06 }, Pos = { 0.0, -0.17, 0.0 }, Color = SOLE, Material = "Rubber" })
	end)
end

return {
	Id = "CappuccinoAssassino",
	Name = "Cappuccino Assassino",
	Rarity = "Rare",
	Emoji = "☕",
	Color = "#b0703f",
	Tagline = "Two katanas, one espresso shot, zero mercy.",
	Lore = "Cappuccino Assassino strikes before your coffee gets cold. He trained for years in a hidden cafe and only fights for the last biscotto. If you hear a faint hiss of steam behind you, it is already too late.",

	Build = function(k)
		-- legs stay planted
		k:Mirror(function()
			leg(k)
		end)

		-- everything above the hips bobs in a ready stance
		joint(k, "UpperBody", HIPC, { Type = "Bob", Axis = "Y", Amount = 0.045, Speed = 0.55, Phase = 0 }, function()
			torso(k)

			arm(k, "RightArm", R_SHOULDER, R_ELBOW, R_HAND, R_BLADE,
				{ Type = "Wiggle", Axis = "X", Amount = 6, Speed = 0.5, Phase = 0 },
				{ Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 0.5, Phase = 0.2 },
				{ Type = "Wiggle", Axis = "Z", Amount = 14, Speed = 0.6, Phase = 0.1 },
				0)
			arm(k, "LeftArm", L_SHOULDER, L_ELBOW, L_HAND, L_BLADE,
				{ Type = "Wiggle", Axis = "X", Amount = 5, Speed = 0.5, Phase = 0.5 },
				{ Type = "Wiggle", Axis = "Y", Amount = 6, Speed = 0.5, Phase = 0.7 },
				{ Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.6, Phase = 0.6 },
				0.5)

			joint(k, "Head", NECK, { Type = "Wiggle", Axis = "Z", Amount = 3.5, Speed = 0.45, Phase = 0.2 }, function()
				cupHead(k)
			end)
		end)
	end,

	BuildMini = function(k)
		-- cappuccino cup head with the ninja cloth and angry eyes
		k:Part({ Name = "CupBowl", Shape = "Ellipsoid", Size = { 1.44, 1.1, 1.44 }, Pos = { 0, 0.55, 0 }, Color = CUP })
		k:Part({ Name = "CupWall", Shape = "Cylinder", Size = { 0.55, 1.44, 1.44 }, Pos = { 0, 0.825, 0 }, Rot = { 0, 0, 90 }, Color = CUP })
		k:Part({ Name = "Crema", Shape = "Ellipsoid", Size = { 1.34, 0.18, 1.34 }, Pos = { 0, 1.1, 0 }, Color = CREMA })
		k:Part({ Name = "NinjaBand", Shape = "Cylinder", Size = { 0.2, 1.5, 1.5 }, Pos = { 0, 0.96, 0 }, Rot = { 0, 0, 90 }, Color = NINJA_DARK, Material = "Fabric" })
		k:Part({ Name = "Handle", Shape = "Cylinder", Size = { 0.14, 0.52, 0.52 }, Pos = { -0.76, 0.66, 0 }, Rot = { 0, 90, 0 }, Color = CUP })
		k:Mirror(function()
			k:Part({ Name = "AngryEye", Shape = "Ellipsoid", Size = { 0.34, 0.17, 0.1 }, Pos = { 0.25, 0.66, -0.68 }, Rot = { 0, -20, 22 }, Color = LINE })
		end)
		-- slim ninja body on crouched legs
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 0.78, 0.92, 0.62 }, Pos = { 0, -0.38, 0 }, Color = NINJA, Material = "Fabric" })
		k:Mirror(function()
			k:Part({ Name = "Leg", Shape = "Ellipsoid", Size = { 0.28, 0.66, 0.32 }, Pos = { 0.3, -0.97, -0.02 }, Rot = { 0, 0, 16 }, Color = NINJA_DARK, Material = "Fabric" })
		end)
		-- two katanas: one raised, one held low
		k:Part({ Name = "KatanaR", Size = { 0.11, 1.57, 0.06 }, Pos = { 0.75, 0.28, -0.22 }, Rot = { 0, 0, -30.6 }, Color = "#e2e9f1", Material = "Metal", Reflectance = 0.35 })
		k:Part({ Name = "KatanaL", Size = { 0.11, 1.24, 0.06 }, Pos = { -0.78, -0.85, -0.26 }, Rot = { 0, 0, -50 }, Color = "#e2e9f1", Material = "Metal", Reflectance = 0.35 })
	end,
}
