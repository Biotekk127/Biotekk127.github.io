--[[
	Tralalero Tralala (Mythic)
	The original Italian brainrot: a blue-grey great white shark with a white belly, gill
	slits, big dorsal + pectoral fins and a crescent tail, grinning with rows of sharp teeth,
	standing on THREE shark-skinned legs (two front, one rear) in blue sneakers with white
	soles, white laces and a plain side stripe (no brand logo).
	Mythic flair: glowing water splash ring at its feet, orbiting bubbles, two lights and
	three particle emitters - none of it changes the canonical shark-in-sneakers design.

	Faces -Z (snout points to -Z), feet on y = 0.
]]

-- Palette ------------------------------------------------------------------------------
local SHARK = "#5a83aa" -- blue-grey top
local SHARK_DARK = "#3e6085" -- fin tips, brows
local SHARK_DEEP = "#24364a" -- gill slits, nostrils
local SHARK_MID = "#83a3c2" -- highlights, gill lips
local BELLY = "#eef3f3" -- white underside
local BELLY_SHADE = "#d3dee5"
local LEG = "#6889ab"
local LEG_LIGHT = "#8aa7c2"
local MOUTH = "#6e1a2a"
local GUM = "#e07a8a"
local TONGUE = "#c24a5e"
local TOOTH = "#fffaf0"
local EYE = "#14151c"
local SHINE = "#fdfdf7"
local SHOE = "#2f6fe8"
local SHOE_DARK = "#1c4bb0"
local SHOE_LIGHT = "#5d95ff"
local SOLE = "#f7f6f1"
local OUTSOLE = "#283a5e"
local LACE = "#fbfbf6"
local SOCK = "#f4f3ee"
local WATER = "#8fe6ff"
local WATER_DEEP = "#3aa8e0"
local WATER_GLOW = "#46d8ff"

local sin, cos, sqrt, rad, deg = math.sin, math.cos, math.sqrt, math.rad, math.deg

local RUN = 0.9 -- running-in-place cycles per second

local function norm(x, y, z)
	local l = sqrt(x * x + y * y + z * z)
	return x / l, y / l, z / l
end

-- Rotation that turns a part's -Z (front) face toward normal n, then spins it about n.
local function faceRot(nx, ny, nz, spin)
	nx, ny, nz = norm(nx, ny, nz)
	return { deg(math.atan2(ny, -nz)), deg(math.asin(-nx)), spin or 0 }
end

-- Point + outward normal on an ellipsoid (centre c, full size s) along direction d.
local function onEllipsoid(c, s, dx, dy, dz)
	local ax, ay, az = s[1] / 2, s[2] / 2, s[3] / 2
	local ux, uy, uz = norm(dx, dy, dz)
	local px, py, pz = ux * ax, uy * ay, uz * az
	local nx, ny, nz = norm(px / (ax * ax), py / (ay * ay), pz / (az * az))
	return { c[1] + px, c[2] + py, c[3] + pz }, { nx, ny, nz }
end

local function offset(p, n, d)
	return { p[1] + n[1] * d, p[2] + n[2] * d, p[3] + n[3] * d }
end

-- Main shark forms (shark-local coordinates; Shark group origin is world y = 4.05)
local TORSO_C, TORSO_S = { 0, 0, -0.35 }, { 2.4, 2.65, 3.8 }
local CRANIUM_C, CRANIUM_S = { 0, 0.36, -1.6 }, { 2.15, 1.65, 2.75 } -- long cranium = smooth conical snout

-- Mouth layout
local MOUTH_Z = -1.85 -- centre of the mouth arcs
local UGUM_Y, LGUM_Y = -0.17, -0.5 -- gum centres (lower one is relative to shark, built in jaw frame)
local GUM_SX, GUM_SZ, GUM_SY = 1.56, 1.66, 0.28

return {
	Id = "TralaleroTralala",
	Name = "Tralalero Tralala",
	Rarity = "Mythic",
	Emoji = "🦈",
	Color = "#3f8fe8",
	Tagline = "Three legs, one shark, zero chill. Tralalero tralala!",
	Lore = "The original brainrot: a great white shark that traded its fins for three legs and a set of fresh blue sneakers. It sprints across the seabed faster than a jet ski and leaves a splash ring wherever it stands. Nobody has ever seen it tie its laces.",

	Build = function(k)
		----------------------------------------------------------------------------------
		-- helpers that need k
		----------------------------------------------------------------------------------
		-- A row of triangular teeth along the mouth arc (diamond blocks half-hidden in the gum)
		local function teethRow(name, count, y, cz, sx, sz, size, phiMax, inset)
			for i = 0, count - 1 do
				local t = if count == 1 then 0.5 else i / (count - 1)
				local phi = rad(-phiMax + 2 * phiMax * t)
				local ax, az = sx / 2 - inset, sz / 2 - inset
				local px, pz = ax * sin(phi), cz - az * cos(phi)
				local nx, nz = sin(phi) / ax, -cos(phi) / az
				local s = size * (1 - 0.35 * math.abs(sin(phi)))
				k:Part({
					Name = name,
					Size = { s, s, 0.05 },
					Pos = { px, y, pz },
					Rot = faceRot(nx, 0, nz, 45),
					Color = TOOTH,
				})
			end
		end

		-- A sneaker part in "shoe space" (y = 0 is the ground, toe points -Z), scaled by SHOE_S.
		local SHOE_S = 1.25
		local function shoePart(spec)
			local sz, ps = spec.Size, spec.Pos
			spec.Size = { sz[1] * SHOE_S, sz[2] * SHOE_S, sz[3] * SHOE_S }
			spec.Pos = { ps[1] * SHOE_S, ps[2] * SHOE_S, ps[3] * SHOE_S }
			k:Part(spec)
		end

		local function sneaker(name)
			-- rubber outsole + white midsole, rounded at toe and heel
			shoePart({ Name = name .. "Outsole", Size = { 0.62, 0.07, 0.92 }, Pos = { 0, 0.035, -0.12 }, Color = OUTSOLE, Material = "Rubber" })
			shoePart({ Name = name .. "OutsoleToe", Shape = "Cylinder", Size = { 0.07, 0.62, 0.62 }, Pos = { 0, 0.035, -0.58 }, Rot = { 0, 0, 90 }, Color = OUTSOLE, Material = "Rubber" })
			shoePart({ Name = name .. "OutsoleHeel", Shape = "Cylinder", Size = { 0.07, 0.62, 0.62 }, Pos = { 0, 0.035, 0.34 }, Rot = { 0, 0, 90 }, Color = OUTSOLE, Material = "Rubber" })
			shoePart({ Name = name .. "Midsole", Size = { 0.64, 0.17, 0.92 }, Pos = { 0, 0.15, -0.12 }, Color = SOLE })
			shoePart({ Name = name .. "MidsoleToe", Shape = "Cylinder", Size = { 0.17, 0.64, 0.64 }, Pos = { 0, 0.15, -0.58 }, Rot = { 0, 0, 90 }, Color = SOLE })
			shoePart({ Name = name .. "MidsoleHeel", Shape = "Cylinder", Size = { 0.17, 0.64, 0.64 }, Pos = { 0, 0.15, 0.34 }, Rot = { 0, 0, 90 }, Color = SOLE })
			-- blue upper
			shoePart({ Name = name .. "Upper", Shape = "Ellipsoid", Size = { 0.6, 0.56, 1.12 }, Pos = { 0, 0.32, -0.1 }, Color = SHOE, Material = "Fabric" })
			shoePart({ Name = name .. "ToeBox", Shape = "Ellipsoid", Size = { 0.6, 0.38, 0.62 }, Pos = { 0, 0.25, -0.55 }, Color = SHOE, Material = "Fabric" })
			shoePart({ Name = name .. "ToeBumper", Shape = "Ellipsoid", Size = { 0.62, 0.17, 0.32 }, Pos = { 0, 0.2, -0.79 }, Color = SOLE })
			shoePart({ Name = name .. "HeelCounter", Shape = "Ellipsoid", Size = { 0.6, 0.44, 0.38 }, Pos = { 0, 0.39, 0.3 }, Color = SHOE_DARK, Material = "Leather" })
			shoePart({ Name = name .. "Collar", Shape = "Cylinder", Size = { 0.12, 0.5, 0.5 }, Pos = { 0, 0.57, 0.06 }, Rot = { 0, 0, 90 }, Color = SHOE_DARK })
			shoePart({ Name = name .. "Tongue", Size = { 0.28, 0.36, 0.08 }, Pos = { 0, 0.55, -0.2 }, Rot = { -18, 0, 0 }, Color = SHOE_LIGHT, Material = "Fabric" })
			for i = 0, 2 do
				local ly, lz = 0.49 - i * 0.07, -0.3 - i * 0.12
				shoePart({ Name = name .. "Lace", Size = { 0.36, 0.05, 0.07 }, Pos = { 0, ly, lz }, Rot = { -28, 0, 0 }, Color = LACE })
				for _, ex in { -1, 1 } do
					shoePart({ Name = name .. "Eyelet", Shape = "Ball", Size = { 0.06, 0.06, 0.06 }, Pos = { ex * 0.19, ly - 0.015, lz }, Color = SHOE_DARK })
				end
			end
			shoePart({ Name = name .. "LaceBow", Shape = "Ellipsoid", Size = { 0.24, 0.06, 0.1 }, Pos = { 0, 0.54, -0.26 }, Rot = { -28, 0, 0 }, Color = LACE })
			for _, sx in { -1, 1 } do
				shoePart({ Name = name .. "SideStripe", Size = { 0.05, 0.09, 0.56 }, Pos = { sx * 0.29, 0.3, -0.1 }, Rot = { -16, 0, 0 }, Color = SOLE })
			end
			shoePart({ Name = name .. "HeelTab", Size = { 0.14, 0.15, 0.05 }, Pos = { 0, 0.5, 0.47 }, Rot = { 10, 0, 0 }, Color = SOLE })
		end

		-- One running leg. hip = joint position (Runner frame), phase = gait phase.
		-- Base pose is an athletic crouch (hip +15, knee -30, ankle +15 = foot flat).
		local L1, L2 = 1.4, 1.4
		local HIP_Y = 3.19
		local ANKLE_H = HIP_Y - (L1 + L2) * cos(rad(15)) -- ankle height above the ground in the base pose
		local function leg(name, hip, phase)
			k:Group({ Name = name .. "Hip", Pos = hip, Rot = { 15, 0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 22, Speed = RUN, Phase = phase } }, function()
				k:Part({ Name = name .. "Haunch", Shape = "Ellipsoid", Size = { 0.95, 1.05, 0.98 }, Pos = { 0, 0.12, 0 }, Color = LEG })
				k:Part({ Name = name .. "Thigh", Shape = "Ellipsoid", Size = { 0.8, 2.15, 0.82 }, Pos = { 0, -0.76, 0 }, Color = LEG })
				k:Part({ Name = name .. "Quad", Shape = "Ellipsoid", Size = { 0.58, 1.15, 0.44 }, Pos = { 0, -0.62, -0.2 }, Color = LEG_LIGHT })
				k:Part({ Name = name .. "Hamstring", Shape = "Ellipsoid", Size = { 0.58, 1.05, 0.42 }, Pos = { 0, -0.7, 0.19 }, Color = LEG })
				k:Group({ Name = name .. "Knee", Pos = { 0, -L1, 0 }, Rot = { -30, 0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 18, Speed = RUN, Phase = phase + 0.75 } }, function()
					k:Part({ Name = name .. "KneeJoint", Shape = "Ball", Size = { 0.58, 0.58, 0.58 }, Color = LEG })
					k:Part({ Name = name .. "Kneecap", Shape = "Ellipsoid", Size = { 0.36, 0.34, 0.18 }, Pos = { 0, 0.02, -0.25 }, Color = LEG_LIGHT })
					k:Part({ Name = name .. "Shin", Shape = "Ellipsoid", Size = { 0.56, 2.0, 0.6 }, Pos = { 0, -0.66, 0 }, Color = LEG })
					k:Part({ Name = name .. "Calf", Shape = "Ellipsoid", Size = { 0.54, 0.95, 0.48 }, Pos = { 0, -0.46, 0.15 }, Color = LEG })
					k:Group({ Name = name .. "Ankle", Pos = { 0, -L2, 0 }, Rot = { 15, 0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 8, Speed = RUN, Phase = phase + 0.5 } }, function()
						k:Part({ Name = name .. "AnkleJoint", Shape = "Ball", Size = { 0.4, 0.4, 0.4 }, Pos = { 0, 0.08, 0 }, Color = LEG })
						k:Part({ Name = name .. "Sock", Shape = "Cylinder", Size = { 0.36, 0.44, 0.44 }, Pos = { 0, 0.26, 0.04 }, Rot = { 0, 0, 90 }, Color = SOCK, Material = "Fabric" })
						k:Part({ Name = name .. "SockStripe", Shape = "Cylinder", Size = { 0.05, 0.455, 0.455 }, Pos = { 0, 0.335, 0.04 }, Rot = { 0, 0, 90 }, Color = SHOE })
						k:Part({ Name = name .. "SockStripe2", Shape = "Cylinder", Size = { 0.05, 0.455, 0.455 }, Pos = { 0, 0.405, 0.04 }, Rot = { 0, 0, 90 }, Color = SHOE })
						k:Group({ Name = name .. "Shoe", Pos = { 0, -ANKLE_H, -0.06 } }, function()
							sneaker(name)
						end)
					end)
				end)
			end)
		end

		----------------------------------------------------------------------------------
		-- Mythic flair: glowing splash ring + puddle at the feet (slowly turning)
		----------------------------------------------------------------------------------
		k:Part({ Name = "Puddle", Shape = "Cylinder", Size = { 0.05, 4.9, 4.9 }, Pos = { 0, 0.03, 0 }, Rot = { 0, 0, 90 }, Color = WATER_DEEP, Material = "Glass", Transparency = 0.45 })
		k:Group({ Name = "SplashRing", Pos = { 0, 0, 0 }, Anim = { Type = "Spin", Axis = "Y", Speed = 0.1 } }, function()
			local R, N = 2.25, 12
			for i = 0, N - 1 do
				local a = 2 * math.pi * i / N
				local ad = deg(a)
				k:Part({ Name = "RingWater", Shape = "Ellipsoid", Size = { 1.3, 0.22, 0.4 }, Pos = { R * cos(a), 0.11, R * sin(a) }, Rot = { 0, 90 - ad, 0 }, Color = WATER, Material = "Glass", Transparency = 0.3 })
				k:Part({ Name = "RingGlow", Size = { 1.1, 0.06, 0.08 }, Pos = { R * cos(a), 0.22, R * sin(a) }, Rot = { 0, 90 - ad, 0 }, Color = WATER_GLOW, Material = "Neon" })
			end
			-- splash crowns: little sheets of water flicking outward, with droplets above
			for i = 0, 5 do
				local a = 2 * math.pi * (i + 0.5) / 6
				local ad = deg(a)
				local h = if i % 2 == 0 then 0.6 else 0.42
				local r = 2.3
				k:Part({ Name = "SplashSheet", Shape = "Ellipsoid", Size = { 0.12, h, 0.42 }, Pos = { r * cos(a), h * 0.5 + 0.03, r * sin(a) }, Rot = { 0, -ad, -28 }, Color = WATER, Material = "Glass", Transparency = 0.35 })
				k:Part({ Name = "SplashDrop", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = { (r + 0.28) * cos(a), h + 0.12, (r + 0.28) * sin(a) }, Color = WATER, Material = "Glass", Transparency = 0.2, Anim = { Type = "Bob", Axis = "Y", Amount = 0.12, Speed = 1.2, Phase = i / 6 } })
			end
		end)

		----------------------------------------------------------------------------------
		-- Orbiting bubbles
		----------------------------------------------------------------------------------
		k:Group({ Name = "BubbleOrbit", Pos = { 0, 4.5, 0 }, Anim = { Type = "Spin", Axis = "Y", Speed = 0.15 } }, function()
			local bubbles = {
				{ 0.4, -1.6, 0.34 }, { 1.45, 0.4, 0.22 }, { 2.4, 1.8, 0.3 },
				{ 3.3, -0.6, 0.2 }, { 4.3, 1.0, 0.26 }, { 5.3, -1.2, 0.18 },
			}
			for i, b in bubbles do
				k:Part({ Name = "Bubble", Shape = "Ball", Size = { b[3], b[3], b[3] }, Pos = { 2.75 * cos(b[1]), b[2], 2.75 * sin(b[1]) }, Color = WATER, Material = "Glass", Transparency = 0.35, Anim = { Type = "Bob", Axis = "Y", Amount = 0.18, Speed = 0.6, Phase = i / 6 } })
			end
		end)

		----------------------------------------------------------------------------------
		-- The runner: shark body + three legs, bobbing with the stride
		----------------------------------------------------------------------------------
		k:Group({ Name = "Runner", Pos = { 0, 0, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.06, Speed = RUN * 2 } }, function()
			-- Three legs: two front (where the pectoral fins sit), one rear (anal fin position)
			leg("FrontRight", { 0.64, HIP_Y, -1.03 }, 0)
			leg("FrontLeft", { -0.64, HIP_Y, -1.03 }, 0.5)
			leg("Rear", { 0, HIP_Y, 0.87 }, 0.25)

			k:Group({ Name = "Shark", Pos = { 0, 4.36, -0.08 }, Rot = { 6, 0, 0 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 3, Speed = RUN / 2 } }, function()
				-- Big forms --------------------------------------------------------------
				k:Part({ Name = "Torso", Shape = "Ellipsoid", Size = TORSO_S, Pos = TORSO_C, Color = SHARK })
				k:Part({ Name = "Cranium", Shape = "Ellipsoid", Size = CRANIUM_S, Pos = CRANIUM_C, Color = SHARK })
				k:Part({ Name = "MidBody", Shape = "Ellipsoid", Size = { 2.1, 2.35, 2.4 }, Pos = { 0, 0.06, 0.5 }, Color = SHARK })
				k:Part({ Name = "RearBody", Shape = "Ellipsoid", Size = { 1.65, 1.85, 2.1 }, Pos = { 0, 0.14, 1.0 }, Color = SHARK })
				k:Part({ Name = "Belly", Shape = "Ellipsoid", Size = { 2.15, 2.15, 3.6 }, Pos = { 0, -0.5, -0.45 }, Color = BELLY })
				k:Part({ Name = "RearBelly", Shape = "Ellipsoid", Size = { 1.4, 1.35, 2.0 }, Pos = { 0, -0.34, 1.05 }, Color = BELLY })

				-- Dorsal fin ---------------------------------------------------------------
				k:Group({ Name = "Dorsal", Pos = { 0, 1.18, -0.3 }, Rot = { 10, 0, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = RUN / 2, Phase = 0.3 } }, function()
					-- wedge = leading edge sloping up and back, vertical trailing edge
					k:Part({ Name = "DorsalFin", Shape = "Wedge", Size = { 0.2, 1.8, 1.55 }, Pos = { 0, 0.9, 0 }, Color = SHARK })
					k:Part({ Name = "DorsalCore", Shape = "Wedge", Size = { 0.3, 1.08, 0.93 }, Pos = { 0, 0.54, -0.31 }, Color = SHARK })
					k:Part({ Name = "DorsalTip", Shape = "Wedge", Size = { 0.22, 0.47, 0.41 }, Pos = { 0, 1.565, 0.57 }, Color = SHARK_DARK })
					k:Part({ Name = "DorsalTrail", Size = { 0.22, 1.35, 0.06 }, Pos = { 0, 0.68, 0.755 }, Color = SHARK_DARK })
					k:Part({ Name = "DorsalBase", Shape = "Ellipsoid", Size = { 0.66, 0.6, 1.85 }, Pos = { 0, 0.05, 0.05 }, Color = SHARK })
					-- battle notches on the trailing edge
					k:Part({ Name = "DorsalNotch", Size = { 0.24, 0.07, 0.15 }, Pos = { 0, 1.1, 0.74 }, Rot = { 20, 0, 0 }, Color = SHARK_DEEP })
					k:Part({ Name = "DorsalNotch", Size = { 0.24, 0.06, 0.11 }, Pos = { 0, 0.8, 0.75 }, Rot = { 20, 0, 0 }, Color = SHARK_DEEP })
				end)
				k:Part({ Name = "SecondDorsal", Shape = "Wedge", Size = { 0.12, 0.34, 0.36 }, Pos = { 0, 1.1, 1.45 }, Rot = { 12, 0, 0 }, Color = SHARK })
				k:Part({ Name = "AnalFin", Shape = "Wedge", Size = { 0.12, 0.32, 0.36 }, Pos = { 0, -1.0, 1.6 }, Rot = { 0, 0, 180 }, Color = SHARK })

				-- Pectoral + pelvic fins (mirrored) ---------------------------------------
				k:Mirror(function()
					k:Group({ Name = "Pectoral", Pos = { 0.97, -0.64, -1.05 }, Rot = { 0, -15, -30 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 10, Speed = RUN, Phase = 0.1 } }, function()
						k:Part({ Name = "PectoralFin", Shape = "Wedge", Size = { 0.16, 1.75, 1.3 }, Pos = { 0.82, 0, 0.32 }, Rot = { 0, 0, -90 }, Color = SHARK })
						k:Part({ Name = "PectoralUnder", Shape = "Wedge", Size = { 0.06, 1.55, 1.15 }, Pos = { 0.77, -0.08, 0.38 }, Rot = { 0, 0, -90 }, Color = BELLY_SHADE })
						k:Part({ Name = "PectoralTip", Shape = "Wedge", Size = { 0.18, 0.455, 0.338 }, Pos = { 1.4675, 0, 0.801 }, Rot = { 0, 0, -90 }, Color = SHARK_DARK })
						-- thicker inner half along the leading edge so the fin tapers like a real one
						k:Part({ Name = "PectoralCore", Shape = "Wedge", Size = { 0.26, 0.96, 0.72 }, Pos = { 0.426, 0, 0.027 }, Rot = { 0, 0, -90 }, Color = SHARK })
						k:Part({ Name = "PectoralRoot", Shape = "Ellipsoid", Size = { 0.32, 0.3, 1.2 }, Pos = { 0.02, 0, 0.3 }, Color = SHARK })
					end)
					k:Part({ Name = "PelvicFin", Shape = "Wedge", Size = { 0.1, 0.3, 0.4 }, Pos = { 0.44, -1.02, 1.35 }, Rot = { 0, 0, 160 }, Color = SHARK })
				end)

				-- Gill slits (5 per side, breathing) ---------------------------------------
				k:Mirror(function()
					for i = 0, 4 do
						local z = -1.25 + i * 0.17
						local h = 0.78 - i * 0.05
						local p, n = onEllipsoid(TORSO_C, TORSO_S, 1, 0.02 - i * 0.01, (z - TORSO_C[3]) / 1.6)
						k:Part({ Name = "GillSlit", Shape = "Ellipsoid", Size = { 0.07, h, 0.1 }, Pos = offset(p, n, -0.02), Rot = faceRot(n[1], n[2], n[3], 0), Color = SHARK_DEEP, Anim = { Type = "Pulse", Amount = 0.06, Speed = 0.6, Phase = i * 0.1 } })
						k:Part({ Name = "GillLip", Shape = "Ellipsoid", Size = { 0.06, h * 0.92, 0.07 }, Pos = offset({ p[1], p[2], p[3] + 0.06 }, n, -0.02), Rot = faceRot(n[1], n[2], n[3], 0), Color = SHARK_MID })
					end
				end)

				-- Old battle scars (asymmetric, light scratches on the upper flanks)
				for _, sc in { { 1, 0.42, 0.12, 22, 0.62 }, { 1, 0.3, 0.2, 18, 0.45 }, { -1, 0.5, -0.05, -25, 0.5 } } do
					local p, n = onEllipsoid(TORSO_C, TORSO_S, sc[1], sc[2], sc[3])
					k:Part({ Name = "Scar", Shape = "Ellipsoid", Size = { sc[5], 0.06, 0.06 }, Pos = offset(p, n, -0.012), Rot = faceRot(n[1], n[2], n[3], sc[4]), Color = SHARK_MID })
				end

				-- Eyes, brows, nostrils, snout pores --------------------------------------
				k:Mirror(function()
					local p, n = onEllipsoid(CRANIUM_C, CRANIUM_S, 0.81, 0.1, -0.62)
					local r = faceRot(n[1], n[2], n[3], 0)
					k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.6, 0.52, 0.2 }, Pos = offset(p, n, -0.03), Rot = r, Color = SHARK_DARK })
					k:Part({ Name = "Eye", Shape = "Ellipsoid", Size = { 0.46, 0.46, 0.24 }, Pos = offset(p, n, 0.02), Rot = r, Color = EYE, Reflectance = 0.15, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = offset({ p[1] - 0.04, p[2] + 0.09, p[3] - 0.04 }, n, 0.12), Color = SHINE, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "EyeShineSmall", Shape = "Ball", Size = { 0.06, 0.06, 0.06 }, Pos = offset({ p[1] + 0.05, p[2] - 0.08, p[3] + 0.04 }, n, 0.11), Color = SHINE, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.6, 0.14, 0.24 }, Pos = offset({ p[1] - 0.03, p[2] + 0.3, p[3] }, n, 0.0), Rot = faceRot(n[1], n[2], n[3], -14), Color = SHARK_DARK })

					local np, nn = onEllipsoid(CRANIUM_C, CRANIUM_S, 0.25, -0.2, -1)
					k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.18, 0.06, 0.1 }, Pos = offset(np, nn, -0.01), Rot = faceRot(nn[1], nn[2], nn[3], 20), Color = SHARK_DEEP })
					local pores = { { 0.14, 0.22, -1 }, { 0.32, 0.08, -0.92 }, { 0.3, 0.36, -0.88 } }
					for _, d in pores do
						local pp, pn = onEllipsoid(CRANIUM_C, CRANIUM_S, d[1], d[2], d[3])
						k:Part({ Name = "Pore", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = offset(pp, pn, -0.012), Color = SHARK_DARK })
					end
				end)

				-- Mouth: dark cavity, pink gums, rows of teeth -----------------------------
				k:Part({ Name = "MouthCavity", Shape = "Ellipsoid", Size = { 1.5, 0.62, 1.6 }, Pos = { 0, -0.3, -1.8 }, Color = MOUTH })
				k:Part({ Name = "UpperGum", Shape = "Ellipsoid", Size = { GUM_SX, GUM_SY, GUM_SZ }, Pos = { 0, UGUM_Y, MOUTH_Z }, Color = GUM })
				do
					local f = sqrt(1 - (0.05 / (GUM_SY / 2)) ^ 2)
					teethRow("UpperTooth", 11, UGUM_Y - 0.05, MOUTH_Z, GUM_SX * f, GUM_SZ * f, 0.16, 74, -0.005)
					teethRow("UpperTooth2", 8, UGUM_Y - 0.03, MOUTH_Z, GUM_SX * f, GUM_SZ * f, 0.12, 62, 0.06)
				end
				k:Mirror(function()
					k:Part({ Name = "MouthCorner", Shape = "Ellipsoid", Size = { 0.1, 0.12, 0.4 }, Pos = { 0.74, -0.33, -1.55 }, Rot = { 0, -30, 0 }, Color = SHARK_DEEP })
				end)

				-- Lower jaw chomps around its hinge
				k:Group({ Name = "Jaw", Pos = { 0, -0.3, -1.2 }, Rot = { -6, 0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 6, Speed = 0.7 } }, function()
					local jy = LGUM_Y + 0.3 -- lower gum centre in jaw frame
					local jz = MOUTH_Z + 1.2
					k:Part({ Name = "LowerJaw", Shape = "Ellipsoid", Size = { 1.72, 0.6, 1.62 }, Pos = { 0, -0.42, -0.5 }, Color = BELLY })
					k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.9, 0.24, 1.1 }, Pos = { 0, -0.17, -0.55 }, Color = TONGUE })
					k:Part({ Name = "LowerGum", Shape = "Ellipsoid", Size = { GUM_SX * 0.94, GUM_SY, GUM_SZ * 0.94 }, Pos = { 0, jy, jz }, Color = GUM })
					local f = sqrt(1 - (0.05 / (GUM_SY / 2)) ^ 2)
					teethRow("LowerTooth", 10, jy + 0.05, jz, GUM_SX * 0.94 * f, GUM_SZ * 0.94 * f, 0.15, 70, -0.005)
					teethRow("LowerTooth2", 7, jy + 0.03, jz, GUM_SX * 0.94 * f, GUM_SZ * 0.94 * f, 0.11, 58, 0.06)
				end)

				-- Tail: peduncle swishes, the fin follows with a delay ---------------------
				k:Group({ Name = "Tail", Pos = { 0, 0.15, 1.65 }, Rot = { -8, 0, 0 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 14, Speed = RUN / 2, Phase = 0.5 } }, function()
					k:Part({ Name = "Peduncle", Shape = "Ellipsoid", Size = { 0.7, 0.85, 1.1 }, Pos = { 0, 0, 0.3 }, Color = SHARK })
					k:Part({ Name = "PeduncleBelly", Shape = "Ellipsoid", Size = { 0.52, 0.55, 0.95 }, Pos = { 0, -0.17, 0.22 }, Color = BELLY })
					k:Mirror(function()
						k:Part({ Name = "CaudalKeel", Shape = "Ellipsoid", Size = { 0.14, 0.09, 0.6 }, Pos = { 0.3, 0, 0.45 }, Color = SHARK_DARK })
					end)
					k:Group({ Name = "TailFin", Pos = { 0, 0.02, 0.55 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = RUN / 2, Phase = 0.62 } }, function()
						-- lunate tail: two swept blades meeting at a thick root
						local ua, la = 60, 60
						local function lobe(name, len, wid, ang, tipColor)
							local a = rad(ang)
							local dy, dz = sin(a), cos(a)
							k:Part({ Name = name, Shape = "Ellipsoid", Size = { 0.16, wid, len }, Pos = { 0, dy * len * 0.42, dz * len * 0.42 }, Rot = { -ang, 0, 0 }, Color = SHARK })
							k:Part({ Name = name .. "Tip", Shape = "Ellipsoid", Size = { 0.18, wid * 0.5, len * 0.26 }, Pos = { 0, dy * len * 0.8, dz * len * 0.8 }, Rot = { -ang, 0, 0 }, Color = tipColor })
						end
						lobe("UpperLobe", 1.8, 0.5, ua, SHARK_DARK)
						lobe("LowerLobe", 1.25, 0.46, -la, SHARK_DARK)
						k:Part({ Name = "TailRoot", Shape = "Ellipsoid", Size = { 0.24, 0.85, 0.55 }, Pos = { 0, 0.05, 0.05 }, Color = SHARK })
					end)
				end)
			end)
		end)

		----------------------------------------------------------------------------------
		-- Lights + particles
		----------------------------------------------------------------------------------
		k:Light({ Pos = { 0, 7.6, -1.2 }, Color = "#5fe3ff", Range = 12, Brightness = 1.2 })
		k:Light({ Pos = { 0, 0.8, 0 }, Color = "#3d8bff", Range = 9, Brightness = 1.5 })
		k:Particles({ Pos = { 0, 4.2, -2.8 }, Color = "#e8fbff", Color2 = "#7fdcff", Rate = 4, Size = 0.22, Speed = 1.2, Lifetime = 2, Spread = 25, Direction = "Top" })
		k:Particles({ Pos = { 0, 0.2, 0 }, Color = "#9fe8ff", Color2 = "#3d8bff", Rate = 8, Size = 0.35, Speed = 2.4, Lifetime = 0.8, Spread = 60, Direction = "Top" })
		k:Particles({ Pos = { 0, 5.4, 2.4 }, Color = "#bff6ff", Color2 = "#46d8ff", Rate = 3, Size = 0.2, Speed = 0.8, Lifetime = 1.6, Spread = 40, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- body + white belly, dorsal fin, crescent tail, black eyes, open mouth, 3 legs in blue sneakers
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.3, 1.2, 2.45 }, Pos = { 0, 0.3, -0.05 }, Color = SHARK })
		k:Part({ Name = "Belly", Shape = "Ellipsoid", Size = { 1.14, 0.94, 2.25 }, Pos = { 0, 0.1, -0.1 }, Color = BELLY })
		k:Part({ Name = "Dorsal", Shape = "Wedge", Size = { 0.13, 0.62, 0.6 }, Pos = { 0, 0.98, 0.05 }, Rot = { 10, 0, 0 }, Color = SHARK })
		k:Part({ Name = "Tail", Shape = "Ellipsoid", Size = { 0.12, 0.95, 0.36 }, Pos = { 0, 0.55, 0.98 }, Rot = { -25, 0, 0 }, Color = SHARK })
		k:Part({ Name = "Eyes", Shape = "Cylinder", Size = { 1.1, 0.2, 0.2 }, Pos = { 0, 0.48, -0.74 }, Color = EYE })
		k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { 0.7, 0.2, 0.3 }, Pos = { 0, 0.12, -1.1 }, Color = MOUTH })
		k:Mirror(function()
			k:Part({ Name = "FrontLeg", Shape = "Cylinder", Size = { 0.48, 0.25, 0.25 }, Pos = { 0.3, -0.44, -0.42 }, Rot = { 0, 0, 90 }, Color = LEG })
			k:Part({ Name = "FrontShoe", Shape = "Ellipsoid", Size = { 0.36, 0.27, 0.6 }, Pos = { 0.3, -0.75, -0.52 }, Color = SHOE })
		end)
		k:Part({ Name = "RearLeg", Shape = "Cylinder", Size = { 0.48, 0.25, 0.25 }, Pos = { 0, -0.44, 0.5 }, Rot = { 0, 0, 90 }, Color = LEG })
		k:Part({ Name = "RearShoe", Shape = "Ellipsoid", Size = { 0.36, 0.27, 0.6 }, Pos = { 0, -0.75, 0.4 }, Color = SHOE })
	end,
}
