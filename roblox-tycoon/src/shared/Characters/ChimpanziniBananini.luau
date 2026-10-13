--[[
	Chimpanzini Bananini (Epic)
	Canonical look: a big glossy yellow banana standing upright on short chimp legs, with a
	gentle banana curve (the flower-end tip swings forward at the bottom). The top of the
	peel is split into four strips that fold over and droop outward (cream inner side
	showing, yellow edges, brown curled tips); one strip still carries the brown banana
	stem. Out of the opening pops a green chimp: green fur, a peach heart-shaped face with
	a big muzzle and toothy grin, huge round ears, a fur tuft on the crown and long monkey
	arms (right one waving). A curly monkey tail pokes out of the peel at the back.
	Epic flair: glossy banana-shine streaks, twinkling neon glints, golden sparkles (one
	stream trails off the waving hand), a warm banana glow, a green rim light and a gentle
	whole-body sway.

	Coordinates: feet on y = 0, faces -Z, right hand at +X.
]]

-- Palette ------------------------------------------------------------------------------
local YEL = "#ffd93a" -- dominant: banana yellow
local YEL_DEEP = "#eab21e" -- ridges / peel edge shade
local YEL_SHINE = "#fff7cc" -- glossy shine streaks
local CREAM = "#fff1bd" -- inside of the peel
local PEEL_BROWN = "#7a4b22" -- tips, sugar spots
local PEEL_BROWN_DARK = "#43280f"
local STEM = "#7c5f2a"
local STEM_DARK = "#4d3818"
local GLINT = "#fffbe2"

local FUR = "#5c8a2b" -- secondary: the green chimp
local FUR_DARK = "#3f6420"
local FUR_LIGHT = "#79a83b"
local SKIN = "#e8b18c" -- face / ears / hands / feet
local SKIN_LIGHT = "#f5cfaa" -- muzzle
local SKIN_DARK = "#c98a69" -- brow, wrinkles, palms, feet
local SOLE = "#a86a4c"
local EAR_IN = "#dc8b7c"
local BLUSH = "#f39a8c"
local LIP = "#b86a5a"

local EYE = "#fff8ec"
local IRIS = "#7a4519"
local PUPIL = "#1b1b24"
local SHINE = "#fffdf4"
local MOUTH = "#4a1c22"
local TEETH = "#fff8ec"
local TONGUE = "#e5707c"

-- Layout (world studs) -------------------------------------------------------------------
local RIM_Y = 5.45 -- top of the banana where the peel splits
local UP_R = 1.37 -- radius of the upper (cylindrical) banana section
local UP_Z = -0.04
local UP_BOT = 3.3
local TILT = 10 -- banana curve: the lower belly leans so its tip swings forward
-- Banana body volume { cx, cy, cz, semiX, semiY, semiZ, tiltX }: one smooth, glossy belly
-- that tapers down into the brown flower-end tip; above UP_BOT it becomes a cylinder.
local BELLY = { 0, 3.3, 0.02, 1.46, 2.42, 1.42, TILT }

local LIFT = 0.12 -- how far the chimp torso rises out of the peel (above the old layout)
local NECK = { 0, 6.25 + LIFT, -0.15 } -- head pivot
local HEAD_S = 1.1 -- the head is modelled at 1.0 and scaled up by this
-- Head volumes (head-local, unscaled, relative to NECK)
local CRAN = { 0, 1.0, 0.08, 1.08, 0.98, 0.98 }
local FACE_R = { 0.31, 1.06, -0.66, 0.43, 0.43, 0.27 } -- right half of the heart-shaped face
local MUZ = { 0, 0.44, -0.82, 0.7, 0.47, 0.5 }
local BROW_R = { 0.32, 1.42, -0.8, 0.36, 0.14, 0.24 } -- right half of the arched brow ridge
local MOUTH_E = { 0, 0.26, -1.06, 0.5, 0.17, 0.26 }

-- Math helpers ---------------------------------------------------------------------------
local function rad(d)
	return d * math.pi / 180
end
local function deg(r)
	return r * 180 / math.pi
end
local function vadd(a, b)
	return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end
local function vsub(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end
local function vmul(a, s)
	return { a[1] * s, a[2] * s, a[3] * s }
end
local function vlen(a)
	return math.sqrt(a[1] * a[1] + a[2] * a[2] + a[3] * a[3])
end
local function vunit(a)
	local l = vlen(a)
	if l < 1e-9 then
		return { 0, 1, 0 }
	end
	return { a[1] / l, a[2] / l, a[3] / l }
end
local function vcross(a, b)
	return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end
local function lerp(a, b, t)
	return a + (b - a) * t
end
-- rotate a vector about the X axis (same sense as CFrame.Angles(rx, 0, 0))
local function rotXv(v, d)
	local c, s = math.cos(rad(d)), math.sin(rad(d))
	return { v[1], v[2] * c - v[3] * s, v[2] * s + v[3] * c }
end

-- Euler angles (degrees, CFrame.Angles order X then Y then Z) of the rotation whose
-- columns are the local axes x, y, z.
local function euler(x, y, z)
	local sb = math.clamp(z[1], -1, 1)
	if math.abs(sb) > 0.99995 then
		return { 0, deg(math.asin(sb)), deg(math.atan2(x[2], y[2])) }
	end
	return { deg(math.atan2(-z[2], z[3])), deg(math.asin(sb)), deg(math.atan2(-y[1], x[1])) }
end

-- Rotation with local X along dir (cylinders, long ellipsoids)
local function alongX(dir, up)
	local x = vunit(dir)
	local z = vcross(x, up or { 0, 1, 0 })
	if vlen(z) < 1e-4 then
		z = vcross(x, { 0, 0, -1 })
	end
	z = vunit(z)
	return euler(x, vcross(z, x), z)
end

-- Rotation with local Y along dir; local Z leans toward `back`
local function alongY(dir, back)
	local y = vunit(dir)
	local x = vcross(y, back or { 0, 0, 1 })
	if vlen(x) < 1e-4 then
		x = vcross(y, { 1, 0, 0 })
	end
	x = vunit(x)
	return euler(x, y, vcross(x, y))
end

-- Rotation whose Front (-Z) face looks along the outward normal n, rolled by `roll` degrees
local function facing(n, roll)
	local z = vunit(vmul(n, -1))
	local x = vcross({ 0, 1, 0 }, z)
	if vlen(x) < 1e-4 then
		x = { 1, 0, 0 }
	end
	x = vunit(x)
	local y = vcross(z, x)
	if roll and roll ~= 0 then
		local c, s = math.cos(rad(roll)), math.sin(rad(roll))
		x, y = vadd(vmul(x, c), vmul(y, s)), vadd(vmul(x, -s), vmul(y, c))
	end
	return euler(x, y, z)
end

-- Ellipsoid volumes may carry an optional 7th entry: a tilt about X in degrees.
-- Outward normal of an ellipsoid volume at point p
local function ellNormal(e, p)
	local q = rotXv(vsub(p, e), -(e[7] or 0))
	return vunit(rotXv({ q[1] / (e[4] * e[4]), q[2] / (e[5] * e[5]), q[3] / (e[6] * e[6]) }, e[7] or 0))
end

-- Point on an ellipsoid along LOCAL direction d from its centre, pushed `out` along the normal
local function onEll(e, d, out)
	local s = math.sqrt((d[1] / e[4]) ^ 2 + (d[2] / e[5]) ^ 2 + (d[3] / e[6]) ^ 2)
	local p = vadd(e, rotXv({ d[1] / s, d[2] / s, d[3] / s }, e[7] or 0))
	local n = ellNormal(e, p)
	return vadd(p, vmul(n, out or 0)), n
end

-- Point on the FRONT (-Z) surface of an (untilted) ellipsoid at a given x, y
local function frontOf(e, x, y, out)
	local u = 1 - ((x - e[1]) / e[4]) ^ 2 - ((y - e[2]) / e[5]) ^ 2
	local p = { x, y, e[3] - e[6] * math.sqrt(math.max(u, 0)) }
	local n = ellNormal(e, p)
	return vadd(p, vmul(n, out or 0)), n
end

-- Distance along a ray to where it leaves ellipsoid e (-1 = miss)
local function exitT(e, o, d)
	local ol = rotXv(vsub(o, e), -(e[7] or 0))
	local dl = rotXv(d, -(e[7] or 0))
	local ox, oy, oz = ol[1] / e[4], ol[2] / e[5], ol[3] / e[6]
	local vx, vy, vz = dl[1] / e[4], dl[2] / e[5], dl[3] / e[6]
	local A = vx * vx + vy * vy + vz * vz
	local B = 2 * (ox * vx + oy * vy + oz * vz)
	local C = ox * ox + oy * oy + oz * oz - 1
	local disc = B * B - 4 * A * C
	if disc < 0 then
		return -1
	end
	return (-B + math.sqrt(disc)) / (2 * A)
end

-- Outer banana surface at height y, angle phi (0 = back/+Z, 90 = +X, 180 = front/-Z)
local function bananaAt(y, phi, out)
	local d = { math.sin(rad(phi)), 0, math.cos(rad(phi)) }
	local o = { 0, y, 0 }
	local best = exitT(BELLY, o, d)
	local n = if best > 0 then ellNormal(BELLY, vadd(o, vmul(d, best))) else d
	if y >= UP_BOT and y <= RIM_Y then
		-- circle of radius UP_R centred at z = UP_Z
		local b = d[3] * -UP_Z
		local t = -b + math.sqrt(b * b - (UP_Z * UP_Z - UP_R * UP_R))
		if t > best then
			best = t
			n = d
		end
	end
	local p = vadd(o, vmul(d, best))
	return vadd(p, vmul(n, out or 0)), n
end

-- A kit wrapper that scales every position and size by s around the current group origin
-- (used to build the head at a friendlier, bigger scale).
local function scaledKit(real, s)
	local function sc(v)
		return if v then { v[1] * s, v[2] * s, v[3] * s } else nil
	end
	local function copy(spec)
		local c = {}
		for key, v in spec do
			c[key] = v
		end
		c.Pos = sc(spec.Pos)
		return c
	end
	return {
		Part = function(_, spec)
			local c = copy(spec)
			c.Size = sc(spec.Size)
			return real:Part(c)
		end,
		Group = function(_, spec, fn)
			return real:Group(copy(spec), fn)
		end,
		Mirror = function(_, fn)
			return real:Mirror(fn)
		end,
		Light = function(_, spec)
			return real:Light(copy(spec))
		end,
		Particles = function(_, spec)
			return real:Particles(copy(spec))
		end,
	}
end

return {
	Id = "ChimpanziniBananini",
	Name = "Chimpanzini Bananini",
	Rarity = "Epic",
	Emoji = "🐒",
	Color = YEL,
	Tagline = "Half chimp, half banana, fully unpeeled.",
	Lore = "Looks like an ordinary banana until someone peels it - then a grinning chimp pops out and waves. "
		.. "Nobody knows where the banana ends and the monkey begins, and Chimpanzini refuses to explain. "
		.. "Its favourite snack is, worryingly, bananas.",

	Build = function(k)
		local K0 = k -- the real kit; `k` is swapped for a scaled wrapper while the head is built

		-- Small builders that need k --------------------------------------------------
		local function rod(a, b, d, color, name, mat)
			local dir = vsub(b, a)
			k:Part({
				Name = name,
				Shape = "Cylinder",
				Size = { vlen(dir), d, d },
				Pos = vmul(vadd(a, b), 0.5),
				Rot = alongX(dir),
				Color = color,
				Material = mat,
			})
		end
		-- Ellipsoid stretched between a and b (organic limbs, fingers, tail)
		local function limb(a, b, w, color, name, mat, extra)
			local dir = vsub(b, a)
			k:Part({
				Name = name,
				Shape = "Ellipsoid",
				Size = { vlen(dir) + w * (extra or 0.6), w, w },
				Pos = vmul(vadd(a, b), 0.5),
				Rot = alongX(dir),
				Color = color,
				Material = mat or "Fabric",
			})
		end
		-- Flat-ish part lying on a surface (p, n from a surface helper)
		local function decal(p, n, size, color, name, roll, extra)
			local spec = {
				Name = name,
				Shape = "Ellipsoid",
				Size = size,
				Pos = p,
				Rot = facing(n, roll),
				Color = color,
			}
			if extra then
				for key, v in extra do
					spec[key] = v
				end
			end
			k:Part(spec)
		end
		-- Fur clump sticking out of a surface along dir. `flat` (< 1) squashes it across
		-- `across` so it lies on the surface like a lock of fur instead of a bean.
		local function tuft(p, dir, w, h, color, name, flat, across)
			k:Part({
				Name = name or "FurTuft",
				Shape = "Ellipsoid",
				Size = { w, h, w * (flat or 1) },
				Pos = vadd(p, vmul(vunit(dir), h * 0.3)),
				Rot = alongY(dir, across),
				Color = color,
				Material = "Fabric",
			})
		end

		--------------------------------------------------------------------------------
		-- Legs and feet (short chimp legs poking out of the banana bottom)
		--------------------------------------------------------------------------------
		k:Mirror(function()
			local hip = { 0.56, 1.3, -0.02 }
			local knee = { 0.8, 0.8, -0.14 }
			local ankle = { 0.76, 0.42, -0.04 }
			limb(hip, knee, 0.6, FUR, "Thigh")
			limb(knee, ankle, 0.52, FUR, "Shin")
			tuft(vadd(knee, { 0.14, 0.02, -0.1 }), { 0.6, 0.2, -0.6 }, 0.22, 0.36, FUR_LIGHT, "KneeTuft", 0.55, { 0.6, 0, -0.6 })
			-- shaggy fur fringe where the leg meets the bare chimp foot
			k:Part({ Name = "AnkleFur", Shape = "Ellipsoid", Size = { 0.62, 0.22, 0.62 }, Pos = { 0.76, 0.5, -0.06 }, Color = FUR_DARK, Material = "Fabric" })
			tuft({ 0.98, 0.46, -0.16 }, { 0.6, -0.5, -0.4 }, 0.18, 0.28, FUR_DARK, "AnkleTuft", 0.6, { 0.6, 0, -0.4 })
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.64, 0.36, 1.0 }, Pos = { 0.77, 0.24, -0.18 }, Color = SKIN_DARK })
			k:Part({ Name = "Sole", Shape = "Ellipsoid", Size = { 0.68, 0.14, 1.08 }, Pos = { 0.77, 0.08, -0.2 }, Color = SOLE })
			k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.5, 0.3, 0.4 }, Pos = { 0.77, 0.16, 0.22 }, Color = SKIN_DARK })
			-- Toes on a little tapping joint
			k:Group({ Name = "Toes", Pos = { 0.77, 0.09, -0.64 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 7, Speed = 0.7, Phase = 0.2 } }, function()
				for i, tx in { -0.1, 0.05, 0.2 } do
					k:Part({ Name = "Toe", Shape = "Ellipsoid", Size = { 0.16, 0.15, if i == 3 then 0.24 else 0.3 }, Pos = { tx, 0.0, -0.17 + (if i == 3 then 0.03 else 0) }, Color = SKIN })
				end
				-- opposable big toe on the inner side
				k:Part({ Name = "BigToe", Shape = "Ellipsoid", Size = { 0.19, 0.16, 0.36 }, Pos = { -0.3, 0.0, 0.1 }, Rot = { 0, 40, 0 }, Color = SKIN })
			end)
		end)

		--------------------------------------------------------------------------------
		-- Everything above the legs sways gently on the hips (BananaSway pivots at y = 1)
		--------------------------------------------------------------------------------
		k:Group({ Name = "BananaSway", Pos = { 0, 1.0, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.2, Speed = 0.4, Phase = 0.15 } }, function()
			k:Group({ Name = "Body", Pos = { 0, -1.0, 0 } }, function() -- back to world coordinates
				------------------------------------------------------------------------
				-- Banana body
				------------------------------------------------------------------------
				local GLOSS = 0.12
				k:Part({ Name = "BananaBelly", Shape = "Ellipsoid", Size = { BELLY[4] * 2, BELLY[5] * 2, BELLY[6] * 2 }, Pos = { BELLY[1], BELLY[2], BELLY[3] }, Rot = { TILT, 0, 0 }, Color = YEL, Reflectance = GLOSS })
				k:Part({ Name = "BananaUpper", Shape = "Cylinder", Size = { RIM_Y - UP_BOT, UP_R * 2, UP_R * 2 }, Pos = { 0, (RIM_Y + UP_BOT) / 2, UP_Z }, Rot = { 0, 0, 90 }, Color = YEL, Reflectance = GLOSS })
				-- The brown flower-end tip of the banana, poking forward at the bottom of the curve
				do
					local p, n = onEll(BELLY, { 0, -1, -0.34 }, -0.04)
					k:Part({ Name = "TipNeck", Shape = "Ellipsoid", Size = { 0.66, 0.66, 0.3 }, Pos = p, Rot = facing(n, 0), Color = YEL_DEEP })
					k:Part({ Name = "TipNub", Shape = "Ellipsoid", Size = { 0.46, 0.46, 0.34 }, Pos = vadd(p, vmul(n, 0.11)), Rot = facing(n, 0), Color = PEEL_BROWN })
					k:Part({ Name = "TipEnd", Shape = "Ellipsoid", Size = { 0.26, 0.26, 0.2 }, Pos = vadd(p, vmul(n, 0.24)), Rot = facing(n, 0), Color = PEEL_BROWN_DARK })
				end
				-- Peel lip and the cream inside of the opening
				k:Part({ Name = "PeelLip", Shape = "Cylinder", Size = { 0.12, UP_R * 2 + 0.08, UP_R * 2 + 0.08 }, Pos = { 0, RIM_Y - 0.02, UP_Z }, Rot = { 0, 0, 90 }, Color = YEL_DEEP })
				k:Part({ Name = "PeelInside", Shape = "Cylinder", Size = { 0.08, UP_R * 2 - 0.16, UP_R * 2 - 0.16 }, Pos = { 0, RIM_Y + 0.03, UP_Z }, Rot = { 0, 0, 90 }, Color = CREAM })

				-- Ridges (5 like a real banana). A flat facet faces the front, so no ridge
				-- runs down the middle like a costume zip.
				local RIDGE_Y = { 1.3, 2.3, 3.3, 4.35, 5.4 }
				for _, phi in { 0, 72, 144, 216, 288 } do
					for i = 1, #RIDGE_Y - 1 do
						local a = bananaAt(RIDGE_Y[i], phi, 0)
						local b = bananaAt(RIDGE_Y[i + 1], phi, 0)
						local m = bananaAt((RIDGE_Y[i] + RIDGE_Y[i + 1]) / 2, phi, 0)
						-- slide the chord toward the surface so the ridge hugs the peel
						local off = vmul(vsub(m, vmul(vadd(a, b), 0.5)), 0.6)
						rod(vadd(a, off), vadd(b, off), 0.1, YEL_DEEP, "PeelRidge")
					end
				end

				-- Sugar spots (little brown freckles a ripe banana has), all the way round
				for _, s in {
					{ 205, 2.2, 0.2 }, { 172, 3.95, 0.14 }, { 120, 2.7, 0.17 }, { 196, 4.75, 0.12 },
					{ 300, 2.45, 0.18 }, { 20, 4.05, 0.15 }, { 345, 3.0, 0.2 }, { 70, 1.85, 0.14 },
					{ 250, 3.7, 0.16 }, { 30, 2.3, 0.13 }, { 330, 4.6, 0.12 }, { 100, 4.4, 0.15 },
				} do
					local p, n = bananaAt(s[2], s[1], 0)
					decal(p, n, { s[3], s[3] * 0.8, 0.06 }, PEEL_BROWN, "SugarSpot", s[1] * 0.3)
				end

				-- Glossy banana-shine: one long, soft, unbroken streak following the curve of
				-- the belly on the lit side, and a round sparkle dot above it.
				for _, s in { { 1.85, 2.6, 0.09 }, { 2.4, 3.45, 0.16 }, { 3.25, 4.3, 0.18 }, { 4.1, 4.85, 0.1 } } do
					local a = bananaAt(s[1], 164, 0)
					local b = bananaAt(s[2], 164, 0)
					local m, n = bananaAt((s[1] + s[2]) / 2, 164, 0.005)
					local len = vlen(vsub(b, a)) + 0.2
					k:Part({ Name = "BananaShine", Shape = "Ellipsoid", Size = { s[3], len, 0.05 }, Pos = m, Rot = alongY(vsub(b, a), vmul(n, -1)), Color = YEL_SHINE, Reflectance = 0.35 })
				end
				do
					local p, n = bananaAt(5.08, 164, 0.005)
					decal(p, n, { 0.13, 0.13, 0.05 }, YEL_SHINE, "ShineDot", 0, { Reflectance = 0.35 })
				end
				-- Twinkling neon star glints (Epic flair)
				for i, g in { { 4.55, 186, 0.5 }, { 2.3, 214, 0.4 }, { 3.5, 330, 0.44 } } do
					local p, n = bananaAt(g[1], g[2], 0.03)
					k:Group({ Name = "Glint", Pos = p, Rot = facing(n, 0) }, function()
						local pulse = { Type = "Pulse", Amount = 0.35, Speed = 0.8, Phase = i * 0.37 }
						k:Part({ Name = "GlintRay", Shape = "Ellipsoid", Size = { g[3], 0.06, 0.05 }, Color = GLINT, Material = "Neon", Anim = pulse })
						k:Part({ Name = "GlintRay", Shape = "Ellipsoid", Size = { 0.06, g[3] * 1.3, 0.05 }, Color = GLINT, Material = "Neon", Anim = pulse })
						k:Part({ Name = "GlintCore", Shape = "Ball", Size = { 0.11, 0.11, 0.11 }, Color = GLINT, Material = "Neon", Anim = pulse })
					end)
				end

				------------------------------------------------------------------------
				-- Peel strips: hinged on the rim, they arch up, fold over and droop
				-- OUTWARD like a skirt (the classic peeled-banana silhouette). Yellow skin
				-- on the outside, a cream inner layer that shows along the torn edges,
				-- sugar spots, and brown tips that flick outward.
				------------------------------------------------------------------------
				local FOLD_R = 0.2 -- radius of the rolled-over fold at the top of each strip
				-- hanging part of a strip, one entry per segment:
				-- { alpha (deg from straight up, + = outward), length, width }
				local DROOP = {
					{ 148, 0.62, 1.06 },
					{ 159, 0.72, 0.94 },
					{ 167, 0.56, 0.8 },
				}
				local function peelFlap(phi, phase, scale, withStem)
					local hinge = { 1.3 * math.sin(rad(phi)), RIM_Y - 0.05, UP_Z + 1.3 * math.cos(rad(phi)) }
					k:Group({ Name = "PeelFlap", Pos = hinge, Rot = { 0, phi, 0 } }, function()
						k:Group({ Name = "PeelSway", Anim = { Type = "Wiggle", Axis = "X", Amount = 5, Speed = 0.55, Phase = phase } }, function()
							local W = 1.12 * scale
							-- 1) the strip rises off the rim ...
							local riseA, riseL = 14, 0.3
							local ry, rz = math.cos(rad(riseA)) * riseL, math.sin(rad(riseA)) * riseL
							local rmid = { 0, ry / 2, rz / 2 }
							local rIn = { 0, -math.sin(rad(riseA)), math.cos(rad(riseA)) }
							k:Part({ Name = "PeelOuter", Size = { W * 0.86, riseL + 0.06, 0.1 }, Pos = vadd(rmid, vmul(rIn, 0.03)), Rot = { riseA, 0, 0 }, Color = YEL, Reflectance = 0.06 })
							k:Part({ Name = "PeelInner", Size = { W, riseL + 0.04, 0.07 }, Pos = vadd(rmid, vmul(rIn, -0.045)), Rot = { riseA, 0, 0 }, Color = CREAM })
							-- 2) ... rolls over a rounded fold (cream edges peek out of the roll) ...
							local fc = { 0, ry, rz + FOLD_R }
							k:Part({ Name = "PeelFold", Shape = "Cylinder", Size = { W * 0.86, FOLD_R * 2 + 0.1, FOLD_R * 2 + 0.1 }, Pos = fc, Color = YEL, Reflectance = 0.06 })
							k:Part({ Name = "PeelFoldEdge", Shape = "Cylinder", Size = { W, FOLD_R * 2 + 0.03, FOLD_R * 2 + 0.03 }, Pos = fc, Color = CREAM })
							-- 3) ... and hangs down and OUTWARD like a skirt
							local y, z = ry, rz + FOLD_R * 2
							local lastA = 0
							for i, seg in DROOP do
								local a, L, w = seg[1], seg[2] * scale, seg[3] * scale
								local dy, dz = math.cos(rad(a)), math.sin(rad(a))
								local mid = { 0, y + dy * L / 2, z + dz * L / 2 }
								local nIn = { 0, -dz, dy } -- the strip's concave side (faces the banana)
								k:Part({ Name = "PeelOuter", Size = { w * 0.86, L + 0.08, 0.1 }, Pos = vadd(mid, vmul(nIn, -0.03)), Rot = { a, 0, 0 }, Color = YEL, Reflectance = 0.06 })
								k:Part({ Name = "PeelInner", Size = { w, L + 0.06, 0.07 }, Pos = vadd(mid, vmul(nIn, 0.045)), Rot = { a, 0, 0 }, Color = CREAM })
								if i <= 2 then
									-- a sugar spot on the outside of the hanging strip
									local sx = if i == 1 then 0.2 else -0.16
									k:Part({ Name = "PeelSpot", Shape = "Ellipsoid", Size = { 0.14, 0.12, 0.05 }, Pos = vadd(vadd(mid, { sx * scale, 0.05, 0 }), vmul(nIn, -0.09)), Rot = { a, 0, i * 25 }, Color = PEEL_BROWN })
								end
								y, z = y + dy * L, z + dz * L
								lastA = a
							end
							if withStem then
								-- this strip kept the banana's stem: a yellow collar and a woody stalk
								local sa = lastA - 12
								local sd = { 0, math.cos(rad(sa)), math.sin(rad(sa)) }
								local base = { 0, y, z }
								k:Part({ Name = "StemCollar", Shape = "Ellipsoid", Size = { 0.52, 0.3, 0.34 }, Pos = base, Rot = { sa, 0, 0 }, Color = YEL_DEEP })
								rod(vadd(base, vmul(sd, 0.05)), vadd(base, vmul(sd, 0.56)), 0.24, STEM, "Stem", "Wood")
								k:Part({ Name = "StemEnd", Shape = "Cylinder", Size = { 0.1, 0.3, 0.3 }, Pos = vadd(base, vmul(sd, 0.59)), Rot = alongX(sd), Color = STEM_DARK, Material = "Wood" })
							else
								-- brown tip, flicking back outward
								local ta = lastA - 30
								local dy, dz = math.cos(rad(ta)), math.sin(rad(ta))
								k:Part({ Name = "PeelTip", Shape = "Ellipsoid", Size = { 0.7 * scale, 0.38, 0.13 }, Pos = { 0, y + dy * 0.1, z + dz * 0.1 }, Rot = { ta, 0, 0 }, Color = PEEL_BROWN })
							end
						end)
					end)
				end
				peelFlap(138, 0.0, 1.0, true) -- front right (stem end)
				peelFlap(222, 0.5, 1.0) -- front left
				peelFlap(42, 0.25, 0.96) -- back right
				peelFlap(318, 0.75, 0.96) -- back left

				------------------------------------------------------------------------
				-- Chimp torso popping out of the peel
				------------------------------------------------------------------------
				local CHEST = { 0, 5.72 + LIFT, -0.05, 1.12, 0.7, 0.9 }
				k:Part({ Name = "Chest", Shape = "Ellipsoid", Size = { CHEST[4] * 2, CHEST[5] * 2, CHEST[6] * 2 }, Pos = { CHEST[1], CHEST[2], CHEST[3] }, Color = FUR, Material = "Fabric", Anim = { Type = "Pulse", Amount = 0.02, Speed = 0.5 } })
				do
					local p, n = frontOf(CHEST, 0, CHEST[2] + 0.1, -0.07)
					decal(p, n, { 1.04, 0.66, 0.2 }, FUR_LIGHT, "ChestFur", 0, { Material = "Fabric" })
				end
				k:Mirror(function()
					k:Part({ Name = "Shoulder", Shape = "Ball", Size = { 0.8, 0.8, 0.8 }, Pos = { 0.97, 5.96 + LIFT, -0.12 }, Color = FUR, Material = "Fabric" })
				end)
				-- Shaggy fur collar where the chimp meets the peel
				k:Part({ Name = "FurCollar", Shape = "Ellipsoid", Size = { 2.64, 0.36, 2.58 }, Pos = { 0, RIM_Y + 0.1, UP_Z }, Color = FUR_DARK, Material = "Fabric" })
				for i = 0, 9 do
					local a = rad(i * 36 + 18)
					local dir = { math.sin(a), 0, math.cos(a) }
					local p = { dir[1] * 1.12, RIM_Y + 0.14, UP_Z + dir[3] * 1.1 }
					tuft(p, { dir[1], 0.75, dir[3] }, 0.3, 0.34, if i % 2 == 0 then FUR else FUR_DARK, "CollarFur", 0.5, dir)
				end

				------------------------------------------------------------------------
				-- Arms (long chimp arms with big hands)
				------------------------------------------------------------------------
				local HS = 1.3 -- hand scale
				local function hand(s, wristDir, palmFwd, curl)
					-- built at the wrist; wristDir = forearm direction, palmFwd = palm normal
					local d = vunit(wristDir)
					local side = vunit(vcross(palmFwd, d)) -- across the palm
					local rot = alongY(d, vmul(palmFwd, -1))
					k:Part({ Name = "Palm", Shape = "Ellipsoid", Size = { 0.44 * HS, 0.48 * HS, 0.2 * HS }, Pos = vmul(d, 0.2 * HS), Rot = rot, Color = SKIN_DARK })
					k:Part({ Name = "HandBack", Shape = "Ellipsoid", Size = { 0.4 * HS, 0.36 * HS, 0.12 * HS }, Pos = vmul(vadd(vmul(d, 0.15), vmul(palmFwd, -0.07)), HS), Rot = rot, Color = FUR_DARK, Material = "Fabric" })
					for i = 1, 4 do
						local off = (i - 2.5) * 0.1
						local spread = (i - 2.5) * 0.2
						local base = vmul(vadd(vmul(d, 0.36), vmul(side, off * s)), HS)
						local fdir = vunit(vadd(vadd(d, vmul(side, spread * s)), vmul(palmFwd, curl)))
						local len = (if i == 1 or i == 4 then 0.26 else 0.32) * HS
						limb(base, vadd(base, vmul(fdir, len)), 0.1 * HS, SKIN, "Finger", "SmoothPlastic", 0.5)
					end
					local tb = vmul(vadd(vmul(d, 0.14), vmul(side, -0.2 * s)), HS)
					local tdir = vunit(vadd(vadd(d, vmul(side, -1.0 * s)), vmul(palmFwd, 0.3)))
					limb(tb, vadd(tb, vmul(tdir, 0.26 * HS)), 0.11 * HS, SKIN, "Thumb", "SmoothPlastic", 0.5)
				end

				-- Right arm: raised high and waving hello
				k:Group({ Name = "RightArm", Pos = { 1.0, 5.98 + LIFT, -0.12 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.8 } }, function()
					local elbow = { 0.62, 0.8, -0.16 }
					limb({ 0, 0, 0 }, elbow, 0.54, FUR, "UpperArm")
					limb(vmul(elbow, 0.2), vmul(elbow, 0.68), 0.62, FUR, "Bicep")
					tuft(vadd(elbow, { 0.16, -0.06, 0.02 }), { 1, -0.5, 0.2 }, 0.2, 0.34, FUR_LIGHT, "ElbowTuft", 0.55, { 0, 0, -1 })
					k:Group({ Name = "RightForearm", Pos = elbow, Anim = { Type = "Wiggle", Axis = "Z", Amount = 20, Speed = 0.8, Phase = 0.2 } }, function()
						local wrist = { 0.1, 0.9, -0.08 }
						limb({ 0, 0, 0 }, wrist, 0.5, FUR, "Forearm")
						k:Part({ Name = "WristFur", Shape = "Ellipsoid", Size = { 0.5, 0.2, 0.5 }, Pos = vmul(wrist, 0.9), Rot = alongY(wrist), Color = FUR_DARK, Material = "Fabric" })
						k:Group({ Name = "RightHand", Pos = wrist, Anim = { Type = "Wiggle", Axis = "Y", Amount = 14, Speed = 0.8, Phase = 0.45 } }, function()
							hand(1, { 0.08, 1, 0 }, { 0, 0, -1 }, 0.05)
							-- golden sparkles trail off the waving hand (Epic flair)
							k:Particles({ Pos = { 0.05, 0.7, 0 }, Color = "#fff6a8", Color2 = "#ffc928", Rate = 3, Size = 0.18, Speed = 0.7, Lifetime = 1.1, Spread = 60, Direction = "Top" })
						end)
					end)
				end)

				-- Left arm: hanging long and loose like a chimp, swinging gently
				k:Group({ Name = "LeftArm", Pos = { -1.0, 5.94 + LIFT, -0.12 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 8, Speed = 0.6, Phase = 0.3 } }, function()
					local elbow = { -0.86, -0.6, -0.16 }
					limb({ 0, 0, 0 }, elbow, 0.54, FUR, "UpperArm")
					limb(vmul(elbow, 0.2), vmul(elbow, 0.68), 0.62, FUR, "Bicep")
					tuft(vadd(elbow, { -0.14, 0.02, 0.1 }), { -0.7, -0.1, 0.7 }, 0.2, 0.34, FUR_LIGHT, "ElbowTuft", 0.55, { 0, 1, 0 })
					k:Group({ Name = "LeftForearm", Pos = elbow, Anim = { Type = "Wiggle", Axis = "X", Amount = 10, Speed = 0.6, Phase = 0.45 } }, function()
						local wrist = { -0.34, -0.84, -0.14 }
						limb({ 0, 0, 0 }, wrist, 0.5, FUR, "Forearm")
						k:Part({ Name = "WristFur", Shape = "Ellipsoid", Size = { 0.5, 0.2, 0.5 }, Pos = vmul(wrist, 0.9), Rot = alongY(wrist), Color = FUR_DARK, Material = "Fabric" })
						k:Group({ Name = "LeftHand", Pos = wrist }, function()
							hand(-1, { -0.3, -1, -0.1 }, { 1, 0, 0 }, 0.45)
						end)
					end)
				end)

				------------------------------------------------------------------------
				-- Curly monkey tail poking out of the back of the peel
				------------------------------------------------------------------------
				do
					local tp = bananaAt(1.9, 12, -0.06)
					k:Group({ Name = "Tail", Pos = tp, Anim = { Type = "Wiggle", Axis = "Y", Amount = 16, Speed = 0.6 } }, function()
						local pts = {
							{ 0, 0, 0 }, { 0.06, -0.02, 0.38 }, { 0.14, 0.12, 0.72 }, { 0.2, 0.45, 0.95 }, { 0.24, 0.86, 0.98 },
							{ 0.26, 1.18, 0.82 }, { 0.27, 1.32, 0.56 }, { 0.27, 1.22, 0.34 }, { 0.26, 1.0, 0.32 }, { 0.25, 0.88, 0.48 },
						}
						for i = 1, #pts - 1 do
							local d = lerp(0.28, 0.15, (i - 1) / (#pts - 2))
							limb(pts[i], pts[i + 1], d, FUR, "TailSeg", "Fabric", 0.9)
						end
						k:Part({ Name = "TailTip", Shape = "Ellipsoid", Size = { 0.2, 0.22, 0.2 }, Pos = pts[#pts], Color = FUR_DARK, Material = "Fabric" })
					end)
				end

				------------------------------------------------------------------------
				-- Head (modelled at 1.0, built at HEAD_S through a scaled kit wrapper)
				------------------------------------------------------------------------
				k:Group({ Name = "HeadBob", Pos = NECK, Anim = { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 1.0 } }, function()
					k = scaledKit(K0, HEAD_S)
					k:Group({ Name = "Head", Anim = { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 0.5 } }, function()
						k:Part({ Name = "Cranium", Shape = "Ellipsoid", Size = { CRAN[4] * 2, CRAN[5] * 2, CRAN[6] * 2 }, Pos = { CRAN[1], CRAN[2], CRAN[3] }, Color = FUR, Material = "Fabric" })
						k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { MUZ[4] * 2, MUZ[5] * 2, MUZ[6] * 2 }, Pos = { MUZ[1], MUZ[2], MUZ[3] }, Color = SKIN_LIGHT })

						-- Mouth: wide toothy chimp grin framed by darker lips
						k:Part({ Name = "Lips", Shape = "Ellipsoid", Size = { MOUTH_E[4] * 2 + 0.1, MOUTH_E[5] * 2 + 0.08, MOUTH_E[6] * 2 }, Pos = { MOUTH_E[1], MOUTH_E[2], MOUTH_E[3] + 0.035 }, Color = LIP })
						k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { MOUTH_E[4] * 2, MOUTH_E[5] * 2, MOUTH_E[6] * 2 }, Pos = { MOUTH_E[1], MOUTH_E[2], MOUTH_E[3] }, Color = MOUTH })
						for i = -2, 2 do
							local x = i * 0.14
							local p, n = frontOf(MOUTH_E, x, 0.315 + math.abs(i) * 0.014, -0.01)
							decal(p, n, { 0.13, 0.13, 0.06 }, TEETH, "Tooth", i * 4)
						end
						do
							local p, n = frontOf(MOUTH_E, 0, 0.17, -0.01)
							decal(p, n, { 0.36, 0.14, 0.07 }, TONGUE, "Tongue", 0)
						end
						-- flat chimp nose with two nostrils
						local noseP, noseN = frontOf(MUZ, 0, 0.72, -0.03)
						decal(noseP, noseN, { 0.38, 0.19, 0.14 }, SKIN, "Nose", 0)

						k:Mirror(function()
							-- heart-shaped upper face
							k:Part({ Name = "FaceMask", Shape = "Ellipsoid", Size = { FACE_R[4] * 2, FACE_R[5] * 2, FACE_R[6] * 2 }, Pos = { FACE_R[1], FACE_R[2], FACE_R[3] }, Color = SKIN })
							-- big expressive eyes (all blink together)
							local blink = { Type = "Blink", Speed = 0.3, Phase = 0.1 }
							k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.47, 0.57, 0.22 }, Pos = { 0.31, 1.08, -0.9 }, Color = EYE, Anim = blink })
							k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.31, 0.36, 0.08 }, Pos = { 0.29, 1.05, -1.0 }, Color = IRIS, Anim = blink })
							k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.17, 0.2, 0.06 }, Pos = { 0.29, 1.05, -1.035 }, Color = PUPIL, Anim = blink })
							k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.09, 0.09, 0.09 }, Pos = { 0.345, 1.12, -1.06 }, Color = SHINE, Material = "Neon", Anim = blink })
							k:Part({ Name = "EyeShine2", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = { 0.245, 0.99, -1.055 }, Color = SHINE, Anim = blink })
							-- chimp brow ridge, tilted up in the middle: a happy, eager look
							k:Part({ Name = "BrowRidge", Shape = "Ellipsoid", Size = { BROW_R[4] * 2, BROW_R[5] * 2, BROW_R[6] * 2 }, Pos = { BROW_R[1], BROW_R[2], BROW_R[3] }, Rot = { 0, 0, -7 }, Color = SKIN })
							-- arched eyebrows (two strokes meeting at the peak of the arch)
							local b1, n1 = frontOf(BROW_R, 0.21, 1.48, -0.035)
							decal(b1, n1, { 0.24, 0.085, 0.08 }, FUR_DARK, "Eyebrow", 14, { Material = "Fabric" })
							local b2, n2 = frontOf(BROW_R, 0.43, 1.45, -0.035)
							decal(b2, n2, { 0.24, 0.085, 0.08 }, FUR_DARK, "Eyebrow", -26, { Material = "Fabric" })
							-- upturned grin corners
							local mp, mn = frontOf(MUZ, 0.43, 0.34, -0.005)
							decal(mp, mn, { 0.17, 0.075, 0.06 }, MOUTH, "MouthCorner", 32)
							-- lower fangs peeking up at the sides of the grin
							local tp, tn = frontOf(MOUTH_E, 0.25, 0.15, -0.01)
							decal(tp, tn, { 0.1, 0.11, 0.06 }, TEETH, "LowerTooth", 0)
							-- nostrils (on the nose), smile creases, blush
							local np = vadd(frontOf(MUZ, 0.085, 0.71, -0.03), vmul(noseN, 0.07))
							decal(np, noseN, { 0.1, 0.07, 0.05 }, PEEL_BROWN_DARK, "Nostril", 20)
							local cp, cn = frontOf(MUZ, 0.53, 0.46, -0.01)
							decal(cp, cn, { 0.18, 0.05, 0.05 }, SKIN_DARK, "SmileCrease", 60)
							local blp, bln = frontOf(MUZ, 0.5, 0.62, -0.01)
							decal(blp, bln, { 0.24, 0.13, 0.05 }, BLUSH, "Blush", 0)
							-- big round chimp ears that twitch
							k:Group({ Name = "Ear", Pos = { 1.02, 1.05, 0.12 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 8, Speed = 0.45, Phase = 0.3 } }, function()
								k:Part({ Name = "EarOuter", Shape = "Ellipsoid", Size = { 0.24, 0.8, 0.7 }, Pos = { 0.12, 0, 0 }, Rot = { 0, 25, 0 }, Color = SKIN })
								k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 0.1, 0.56, 0.46 }, Pos = { 0.19, 0, -0.04 }, Rot = { 0, 25, 0 }, Color = EAR_IN })
								k:Part({ Name = "EarFold", Shape = "Ellipsoid", Size = { 0.08, 0.24, 0.12 }, Pos = { 0.22, -0.1, -0.08 }, Rot = { 0, 25, 0 }, Color = SKIN_DARK })
							end)
							-- cheek fur: flat locks swept down and back, framing the face
							for _, d in { { 0.9, -0.1, -0.52 }, { 0.84, -0.42, -0.42 }, { 0.62, -0.72, -0.4 } } do
								local p, n = onEll(CRAN, d, -0.12)
								tuft(p, vadd(n, { 0, -0.9, 0.35 }), 0.26, 0.5, FUR, "CheekFur", 0.45, n)
							end
						end)

						-- shaggy fur on the crown: a forward quiff with side locks swept back
						for _, t in {
							{ { 0, 1, -0.3 }, { 0, 0.8, -1 }, 0.4, 0.66, FUR_LIGHT },
							{ { 0.32, 0.95, -0.12 }, { 0.6, 0.8, -0.5 }, 0.32, 0.52, FUR },
							{ { -0.32, 0.95, -0.12 }, { -0.6, 0.8, -0.5 }, 0.32, 0.52, FUR },
							{ { 0.14, 0.9, 0.36 }, { 0.3, 0.6, 1 }, 0.34, 0.54, FUR_DARK },
							{ { -0.16, 0.88, 0.4 }, { -0.35, 0.55, 1 }, 0.32, 0.5, FUR },
						} do
							local p, n = onEll(CRAN, t[1], -0.1)
							tuft(p, t[2], t[3], t[4], t[5], "HairTuft", 0.55, n)
						end
					end)
					k = K0
				end)
			end)
		end)

		--------------------------------------------------------------------------------
		-- Epic flair: banana glow, green rim light and golden sparkles
		--------------------------------------------------------------------------------
		k:Light({ Pos = { 0, 4.6, -2.3 }, Color = "#ffe08a", Range = 10, Brightness = 1.2 })
		k:Light({ Pos = { 0, 8.6, 1.4 }, Color = "#d9ff8f", Range = 7, Brightness = 0.7 })
		k:Particles({ Pos = { 0, 5.6, -0.2 }, Color = "#fff6a8", Color2 = "#ffcf2e", Rate = 5, Size = 0.22, Speed = 1.2, Lifetime = 1.6, Spread = 70, Direction = "Top" })
		k:Particles({ Pos = { 0, 3.0, 0 }, Color = "#ffe45c", Color2 = "#fff8d0", Rate = 3, Size = 0.16, Speed = 0.6, Lifetime = 2, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- Lifted slightly so the tilted banana stays inside the mini size limit.
		k:Group({ Name = "MiniLift", Pos = { 0, 0.09, 0 } }, function()
			-- curved banana body with a brown tip, cream peel strips drooping outward, and the
			-- green chimp head popping out of the top
			k:Part({ Name = "Banana", Shape = "Ellipsoid", Size = { 1.26, 1.78, 1.18 }, Pos = { 0, -0.43, 0.02 }, Rot = { 7, 0, 0 }, Color = YEL })
			k:Part({ Name = "BananaTip", Shape = "Ellipsoid", Size = { 0.28, 0.28, 0.28 }, Pos = { 0, -1.17, -0.08 }, Color = PEEL_BROWN })
			k:Part({ Name = "PeelInside", Shape = "Cylinder", Size = { 0.1, 1.08, 1.08 }, Pos = { 0, 0.12, 0 }, Rot = { 0, 0, 90 }, Color = CREAM })
			k:Part({ Name = "FlapRight", Shape = "Ellipsoid", Size = { 0.42, 0.96, 0.13 }, Pos = { 0.47, -0.16, -0.43 }, Rot = facing(vunit({ 0.7, -0.32, -0.7 }), 0), Color = CREAM })
			k:Part({ Name = "FlapLeft", Shape = "Ellipsoid", Size = { 0.42, 0.96, 0.13 }, Pos = { -0.47, -0.16, -0.43 }, Rot = facing(vunit({ -0.7, -0.32, -0.7 }), 0), Color = CREAM })
			k:Part({ Name = "FlapBack", Shape = "Ellipsoid", Size = { 0.46, 0.96, 0.14 }, Pos = { 0, -0.12, 0.66 }, Rot = facing(vunit({ 0, -0.32, 1 }), 0), Color = CREAM })
			k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.04, 0.96, 0.94 }, Pos = { 0, 0.72, -0.05 }, Color = FUR })
			k:Part({ Name = "Ears", Shape = "Ellipsoid", Size = { 1.42, 0.4, 0.18 }, Pos = { 0, 0.72, 0 }, Color = SKIN })
			k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 0.76, 0.62, 0.3 }, Pos = { 0, 0.71, -0.43 }, Color = SKIN })
			k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 0.6, 0.36, 0.3 }, Pos = { 0, 0.48, -0.55 }, Color = SKIN_LIGHT })
			k:Part({ Name = "EyeL", Shape = "Ellipsoid", Size = { 0.14, 0.18, 0.06 }, Pos = { -0.16, 0.78, -0.59 }, Color = PUPIL })
			k:Part({ Name = "EyeR", Shape = "Ellipsoid", Size = { 0.14, 0.18, 0.06 }, Pos = { 0.16, 0.78, -0.59 }, Color = PUPIL })
		end)
	end,
}
