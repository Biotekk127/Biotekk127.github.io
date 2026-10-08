--[[
	Chimpanzini Bananini (Epic)
	Canonical look: a big glossy yellow banana standing upright on short chimp legs. The
	peel is split open at the top into five flaps that fold outward and droop (cream inner
	side showing, brown tips); the tall back flap still carries the brown banana stem.
	Out of the opening pops a green-tinted chimp: olive fur, a pink-tan heart-shaped face
	with a big muzzle and toothy grin, huge round ears, a spiky fur tuft on the crown and
	long monkey arms (right one waving). A curly monkey tail pokes out of the peel at the
	back. Epic flair: glossy banana-shine streaks, twinkling neon glints, golden sparkles
	and a warm banana glow.

	Coordinates: feet on y = 0, faces -Z, right hand at +X.
]]

-- Palette ------------------------------------------------------------------------------
local YEL = "#ffd83a" -- dominant: banana yellow
local YEL_DEEP = "#efb823" -- ridges / peel edge shade
local YEL_SHINE = "#fff7cc" -- glossy shine streaks
local CREAM = "#fff3c0" -- inside of the peel
local PEEL_BROWN = "#7a4b22" -- tips, sugar spots
local PEEL_BROWN_DARK = "#43280f"
local STEM = "#7c5f2a"
local STEM_DARK = "#4d3818"
local GLINT = "#fffbe2"

local FUR = "#66702b" -- secondary: olive, green-tinted chimp fur
local FUR_DARK = "#4b5320"
local FUR_LIGHT = "#86903a"
local SKIN = "#e6ad88" -- face / ears / hands / feet
local SKIN_LIGHT = "#f3c9a4" -- muzzle
local SKIN_DARK = "#c68865" -- brow, wrinkles, palms
local EAR_IN = "#d98a7a"
local BLUSH = "#f2998b"

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
-- Banana body volume { cx, cy, cz, semiX, semiY, semiZ }: one smooth, glossy belly that
-- tapers down into the brown flower-end tip; above UP_BOT it becomes a cylinder.
local BELLY = { 0, 3.3, -0.06, 1.46, 2.42, 1.42 }

local NECK = { 0, 6.25, -0.15 } -- head pivot
-- Head volumes (head-local, relative to NECK)
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

-- Outward normal of an ellipsoid volume at point p
local function ellNormal(e, p)
	return vunit({ (p[1] - e[1]) / (e[4] * e[4]), (p[2] - e[2]) / (e[5] * e[5]), (p[3] - e[3]) / (e[6] * e[6]) })
end

-- Point on an ellipsoid along direction d from its centre, pushed `out` along the normal
local function onEll(e, d, out)
	local s = math.sqrt((d[1] / e[4]) ^ 2 + (d[2] / e[5]) ^ 2 + (d[3] / e[6]) ^ 2)
	local p = { e[1] + d[1] / s, e[2] + d[2] / s, e[3] + d[3] / s }
	local n = ellNormal(e, p)
	return vadd(p, vmul(n, out or 0)), n
end

-- Point on the FRONT (-Z) surface of an ellipsoid at a given x, y
local function frontOf(e, x, y, out)
	local u = 1 - ((x - e[1]) / e[4]) ^ 2 - ((y - e[2]) / e[5]) ^ 2
	local p = { x, y, e[3] - e[6] * math.sqrt(math.max(u, 0)) }
	local n = ellNormal(e, p)
	return vadd(p, vmul(n, out or 0)), n
end

-- Distance along a ray to where it leaves ellipsoid e (-1 = miss)
local function exitT(e, o, d)
	local ox, oy, oz = (o[1] - e[1]) / e[4], (o[2] - e[2]) / e[5], (o[3] - e[3]) / e[6]
	local vx, vy, vz = d[1] / e[4], d[2] / e[5], d[3] / e[6]
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
	local best, n = -1, d
	for _, e in { BELLY } do
		local t = exitT(e, o, d)
		if t > best then
			best = t
			n = ellNormal(e, vadd(o, vmul(d, t)))
		end
	end
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
		-- Fur tuft sticking out of a surface along direction dir
		local function tuft(p, dir, w, h, color, name)
			k:Part({
				Name = name or "FurTuft",
				Shape = "Ellipsoid",
				Size = { w, h, w },
				Pos = vadd(p, vmul(vunit(dir), h * 0.3)),
				Rot = alongY(dir),
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
			limb(hip, knee, 0.56, FUR, "Thigh")
			limb(knee, ankle, 0.48, FUR, "Shin")
			tuft(vadd(knee, { 0.12, 0.02, -0.12 }), { 0.5, 0.3, -0.6 }, 0.22, 0.34, FUR_LIGHT, "KneeTuft")
			k:Part({ Name = "AnkleFur", Shape = "Ellipsoid", Size = { 0.58, 0.26, 0.58 }, Pos = { 0.76, 0.46, -0.06 }, Color = FUR_DARK, Material = "Fabric" })
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.66, 0.38, 1.0 }, Pos = { 0.77, 0.25, -0.18 }, Color = FUR, Material = "Fabric" })
			k:Part({ Name = "Sole", Shape = "Ellipsoid", Size = { 0.7, 0.16, 1.12 }, Pos = { 0.77, 0.09, -0.22 }, Color = SKIN_DARK })
			k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.5, 0.3, 0.4 }, Pos = { 0.77, 0.16, 0.24 }, Color = SKIN })
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
		-- Banana body
		--------------------------------------------------------------------------------
		local GLOSS = 0.08
		k:Part({ Name = "BananaBelly", Shape = "Ellipsoid", Size = { BELLY[4] * 2, BELLY[5] * 2, BELLY[6] * 2 }, Pos = { BELLY[1], BELLY[2], BELLY[3] }, Color = YEL, Reflectance = GLOSS })
		k:Part({ Name = "BananaUpper", Shape = "Cylinder", Size = { RIM_Y - UP_BOT, UP_R * 2, UP_R * 2 }, Pos = { 0, (RIM_Y + UP_BOT) / 2, UP_Z }, Rot = { 0, 0, 90 }, Color = YEL, Reflectance = GLOSS })
		-- The brown flower-end tip of the banana, tucked between the legs
		do
			local p, n = onEll(BELLY, { 0, -1, 0.42 }, -0.04)
			k:Part({ Name = "TipNub", Shape = "Ellipsoid", Size = { 0.42, 0.34, 0.42 }, Pos = p, Rot = facing(n, 0), Color = PEEL_BROWN })
			k:Part({ Name = "TipEnd", Shape = "Ellipsoid", Size = { 0.22, 0.2, 0.22 }, Pos = vadd(p, vmul(n, 0.14)), Color = PEEL_BROWN_DARK })
		end
		-- Peel lip and the cream inside of the opening
		k:Part({ Name = "PeelLip", Shape = "Cylinder", Size = { 0.12, UP_R * 2 + 0.08, UP_R * 2 + 0.08 }, Pos = { 0, RIM_Y - 0.02, UP_Z }, Rot = { 0, 0, 90 }, Color = YEL_DEEP })
		k:Part({ Name = "PeelInside", Shape = "Cylinder", Size = { 0.08, UP_R * 2 - 0.16, UP_R * 2 - 0.16 }, Pos = { 0, RIM_Y + 0.03, UP_Z }, Rot = { 0, 0, 90 }, Color = CREAM })

		-- Ridges where the peel splits (5 like a real banana)
		local RIDGE_Y = { 1.3, 2.3, 3.3, 4.35, 5.4 }
		for _, phi in { 180, 108, 252, 36, 324 } do
			for i = 1, #RIDGE_Y - 1 do
				local a = bananaAt(RIDGE_Y[i], phi, 0)
				local b = bananaAt(RIDGE_Y[i + 1], phi, 0)
				local m = bananaAt((RIDGE_Y[i] + RIDGE_Y[i + 1]) / 2, phi, 0)
				-- slide the chord halfway toward the surface so the ridge hugs the peel
				local off = vmul(vsub(m, vmul(vadd(a, b), 0.5)), 0.6)
				rod(vadd(a, off), vadd(b, off), 0.1, YEL_DEEP, "PeelRidge")
			end
		end

		-- Sugar spots (little brown freckles a ripe banana has)
		for _, s in {
			{ 205, 2.2, 0.2 }, { 160, 3.95, 0.14 }, { 128, 2.7, 0.17 }, { 232, 4.7, 0.12 },
			{ 300, 2.45, 0.18 }, { 20, 4.05, 0.15 }, { 345, 3.0, 0.2 }, { 70, 1.85, 0.14 },
		} do
			local p, n = bananaAt(s[2], s[1], 0)
			decal(p, n, { s[3], s[3] * 0.8, 0.06 }, PEEL_BROWN, "SugarSpot", s[1] * 0.3)
		end

		-- Glossy banana-shine streaks (screen-left, where the key light hits)
		-- one long highlight stroke following the curve of the belly, plus a thin echo
		for _, s in { { 2.45, 3.2, 148, 0.15 }, { 3.2, 4.0, 148, 0.17 }, { 4.0, 4.75, 149, 0.13 }, { 3.0, 3.75, 137, 0.08 } } do
			local a = bananaAt(s[1], s[3], 0)
			local b = bananaAt(s[2], s[3], 0)
			local m, n = bananaAt((s[1] + s[2]) / 2, s[3], 0.005)
			local len = vlen(vsub(b, a)) + 0.25
			k:Part({ Name = "BananaShine", Shape = "Ellipsoid", Size = { s[4], len, 0.05 }, Pos = m, Rot = alongY(vsub(b, a), vmul(n, -1)), Color = YEL_SHINE, Reflectance = 0.35 })
		end
		-- Twinkling neon glints (Epic flair)
		for i, g in { { 4.95, 150, 0.42 }, { 2.2, 222, 0.32 } } do
			local p, n = bananaAt(g[1], g[2], 0.03)
			k:Group({ Name = "Glint", Pos = p, Rot = facing(n, 0) }, function()
				for _, r in { 0, 90 } do
					k:Part({
						Name = "GlintRay",
						Shape = "Ellipsoid",
						Size = { g[3], 0.07, 0.05 },
						Rot = { 0, 0, r },
						Color = GLINT,
						Material = "Neon",
						Anim = { Type = "Pulse", Amount = 0.35, Speed = 0.8, Phase = i * 0.37 },
					})
				end
			end)
		end

		--------------------------------------------------------------------------------
		-- Peel flaps (hinged on the rim; cream inner side shows as they fold outward)
		--------------------------------------------------------------------------------
		-- each petal: { alpha (deg from straight up, + = outward), length, width }
		local PETAL = { { 14, 0.3, 1.02 }, { 70, 0.28, 1.0 }, { 126, 0.28, 0.98 }, { 164, 0.7, 0.96 }, { 171, 0.6, 0.66 } }
		local function peelFlap(phi, phase, scale)
			local hinge = { 1.3 * math.sin(rad(phi)), RIM_Y - 0.05, UP_Z + 1.3 * math.cos(rad(phi)) }
			k:Group({ Name = "PeelFlap", Pos = hinge, Rot = { 0, phi, 0 } }, function()
				k:Group({ Name = "PeelSway", Anim = { Type = "Wiggle", Axis = "X", Amount = 6, Speed = 0.55, Phase = phase } }, function()
					local y, z = 0, 0
					local th = 0.15
					local lastA = 0
					for _, seg in PETAL do
						local a, L, w = seg[1], seg[2] * scale, seg[3] * scale
						local dy, dz = math.cos(rad(a)), math.sin(rad(a))
						local mid = { 0, y + dy * L / 2, z + dz * L / 2 }
						local nc = { 0, math.sin(rad(a)), -math.cos(rad(a)) } -- cream (inner) side
						local over = if L > 0.4 then 0.45 else 0.3
						k:Part({ Name = "PeelOuter", Shape = "Ellipsoid", Size = { w, L + over, th }, Pos = mid, Rot = { a, 0, 0 }, Color = YEL, Reflectance = 0.06 })
						k:Part({ Name = "PeelInner", Shape = "Ellipsoid", Size = { w * 0.8, L + over - 0.06, th * 0.6 }, Pos = vadd(mid, vmul(nc, th * 0.32)), Rot = { a, 0, 0 }, Color = CREAM })
						y, z = y + dy * L, z + dz * L
						lastA = a
					end
					-- brown tip, curling outward a little
					local ta = lastA - 22
					local dy, dz = math.cos(rad(ta)), math.sin(rad(ta))
					k:Part({ Name = "PeelTip", Shape = "Ellipsoid", Size = { 0.3 * scale, 0.36, 0.13 }, Pos = { 0, y - 0.02 + dy * 0.08, z + dz * 0.08 }, Rot = { ta, 0, 0 }, Color = PEEL_BROWN })
				end)
			end)
		end
		peelFlap(144, 0.0, 1.0) -- front right
		peelFlap(216, 0.5, 1.0) -- front left
		peelFlap(64, 0.25, 0.96) -- side right
		peelFlap(296, 0.75, 0.96) -- side left

		-- Back flap: the stem end of the peel still stands up behind the head and curls
		-- back like the top of a banana, brown stem and all.
		k:Group({ Name = "BackFlap", Pos = { 0, RIM_Y - 0.1, UP_Z + 1.2 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 0.55, Phase = 0.1 } }, function()
			local pts = { { 0, 0, 0 }, { 0, 0.62, 0.16 }, { 0, 1.2, 0.4 }, { 0, 1.68, 0.76 }, { 0, 1.98, 1.14 } }
			local wid = { 1.34, 1.12, 0.86, 0.6 }
			local dep = { 0.42, 0.38, 0.33, 0.28 }
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				local dir = vsub(b, a)
				local mid = vmul(vadd(a, b), 0.5)
				local rot = alongY(dir, { 0, 0, 1 })
				k:Part({ Name = "BackPeel", Shape = "Ellipsoid", Size = { wid[i], vlen(dir) + 0.55, dep[i] }, Pos = mid, Rot = rot, Color = YEL, Reflectance = 0.06 })
				-- cream inner face looking toward the chimp
				local inward = vunit(vcross(dir, { 1, 0, 0 }))
				k:Part({ Name = "BackPeelInner", Shape = "Ellipsoid", Size = { wid[i] * 0.78, vlen(dir) + 0.3, 0.12 }, Pos = vadd(mid, vmul(inward, dep[i] * 0.42)), Rot = rot, Color = CREAM })
			end
			-- ridge down the back of the flap
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				local out = vunit(vcross({ 1, 0, 0 }, vsub(b, a)))
				rod(vadd(a, vmul(out, dep[i] * 0.47)), vadd(b, vmul(out, dep[math.min(i + 1, #dep)] * 0.47)), 0.09, YEL_DEEP, "BackRidge")
			end
			local tip = pts[#pts]
			local sDir = vunit({ 0, 0.62, 0.78 })
			k:Part({ Name = "StemCollar", Shape = "Ellipsoid", Size = { 0.5, 0.28, 0.36 }, Pos = tip, Rot = alongY(sDir), Color = YEL_DEEP })
			rod(vsub(tip, vmul(sDir, 0.05)), vadd(tip, vmul(sDir, 0.48)), 0.24, STEM, "Stem", "Wood")
			k:Part({ Name = "StemEnd", Shape = "Cylinder", Size = { 0.1, 0.3, 0.3 }, Pos = vadd(tip, vmul(sDir, 0.5)), Rot = alongX(sDir), Color = STEM_DARK, Material = "Wood" })
		end)

		--------------------------------------------------------------------------------
		-- Chimp torso popping out of the peel
		--------------------------------------------------------------------------------
		local CHEST = { 0, 5.72, -0.05, 1.1, 0.68, 0.88 }
		k:Part({ Name = "Chest", Shape = "Ellipsoid", Size = { CHEST[4] * 2, CHEST[5] * 2, CHEST[6] * 2 }, Pos = { CHEST[1], CHEST[2], CHEST[3] }, Color = FUR, Material = "Fabric" })
		k:Mirror(function()
			k:Part({ Name = "Shoulder", Shape = "Ball", Size = { 0.72, 0.72, 0.72 }, Pos = { 0.96, 5.96, -0.12 }, Color = FUR, Material = "Fabric" })
		end)
		-- Fluffy fur ring where the chimp meets the peel
		for i = 0, 5 do
			local a = rad(i * 60 + 30)
			local dir = { math.sin(a), 0, math.cos(a) }
			local p = { dir[1] * 1.0, RIM_Y + 0.1, -0.05 + dir[3] * 0.8 }
			tuft(p, { dir[1], 0.9, dir[3] }, 0.36, 0.42, if i % 2 == 0 then FUR_DARK else FUR, "RimFluff")
		end

		--------------------------------------------------------------------------------
		-- Arms
		--------------------------------------------------------------------------------
		local function hand(s, wristDir, palmFwd, curl)
			-- built at the wrist; wristDir = forearm direction, palmFwd = palm normal
			local d = vunit(wristDir)
			local side = vunit(vcross(palmFwd, d)) -- across the palm
			k:Part({ Name = "Palm", Shape = "Ellipsoid", Size = { 0.42, 0.46, 0.2 }, Pos = vmul(d, 0.2), Rot = alongY(d, vmul(palmFwd, -1)), Color = SKIN_DARK })
			k:Part({ Name = "HandBack", Shape = "Ellipsoid", Size = { 0.38, 0.34, 0.12 }, Pos = vadd(vmul(d, 0.16), vmul(palmFwd, -0.07)), Rot = alongY(d, vmul(palmFwd, -1)), Color = FUR_DARK, Material = "Fabric" })
			for i = 1, 4 do
				local off = (i - 2.5) * 0.1
				local spread = (i - 2.5) * 0.2
				local base = vadd(vmul(d, 0.36), vmul(side, off * s))
				local fdir = vunit(vadd(vadd(d, vmul(side, spread * s)), vmul(palmFwd, curl)))
				local len = if i == 1 or i == 4 then 0.26 else 0.32
				limb(base, vadd(base, vmul(fdir, len)), 0.1, SKIN, "Finger", "SmoothPlastic", 0.5)
			end
			local tb = vadd(vmul(d, 0.14), vmul(side, -0.2 * s))
			local tdir = vunit(vadd(vadd(d, vmul(side, -1.0 * s)), vmul(palmFwd, 0.3)))
			limb(tb, vadd(tb, vmul(tdir, 0.26)), 0.11, SKIN, "Thumb", "SmoothPlastic", 0.5)
		end

		-- Right arm: raised high and waving hello
		k:Group({ Name = "RightArm", Pos = { 1.0, 5.98, -0.12 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.8 } }, function()
			local elbow = { 0.6, 0.82, -0.16 }
			limb({ 0, 0, 0 }, elbow, 0.46, FUR, "UpperArm")
			tuft(vadd(elbow, { 0.14, -0.06, 0.02 }), { 1, -0.4, 0.2 }, 0.2, 0.32, FUR_LIGHT, "ElbowTuft")
			k:Group({ Name = "RightForearm", Pos = elbow, Anim = { Type = "Wiggle", Axis = "Z", Amount = 20, Speed = 0.8, Phase = 0.2 } }, function()
				local wrist = { 0.1, 0.92, -0.08 }
				limb({ 0, 0, 0 }, wrist, 0.42, FUR, "Forearm")
				k:Part({ Name = "WristFur", Shape = "Ellipsoid", Size = { 0.44, 0.18, 0.44 }, Pos = vmul(wrist, 0.9), Rot = alongY(wrist), Color = FUR_LIGHT, Material = "Fabric" })
				k:Group({ Name = "RightHand", Pos = wrist }, function()
					hand(1, { 0.08, 1, 0 }, { 0, 0, -1 }, 0.05)
				end)
			end)
		end)

		-- Left arm: hanging long and loose like a chimp, swinging gently
		k:Group({ Name = "LeftArm", Pos = { -1.0, 5.94, -0.12 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 9, Speed = 0.6, Phase = 0.3 } }, function()
			local elbow = { -0.72, -0.7, -0.16 }
			limb({ 0, 0, 0 }, elbow, 0.46, FUR, "UpperArm")
			tuft(vadd(elbow, { -0.12, 0.0, 0.1 }), { -0.6, -0.2, 0.8 }, 0.2, 0.32, FUR_LIGHT, "ElbowTuft")
			k:Group({ Name = "LeftForearm", Pos = elbow, Anim = { Type = "Wiggle", Axis = "X", Amount = 10, Speed = 0.6, Phase = 0.45 } }, function()
				local wrist = { -0.3, -0.82, -0.12 }
				limb({ 0, 0, 0 }, wrist, 0.42, FUR, "Forearm")
				k:Part({ Name = "WristFur", Shape = "Ellipsoid", Size = { 0.44, 0.18, 0.44 }, Pos = vmul(wrist, 0.9), Rot = alongY(wrist), Color = FUR_LIGHT, Material = "Fabric" })
				k:Group({ Name = "LeftHand", Pos = wrist }, function()
					hand(-1, { -0.3, -1, -0.1 }, { 1, 0, 0 }, 0.45)
				end)
			end)
		end)

		--------------------------------------------------------------------------------
		-- Monkey tail curling out of the back of the peel
		--------------------------------------------------------------------------------
		k:Group({ Name = "Tail", Pos = { 0, 2.5, 1.2 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 18, Speed = 0.6 } }, function()
			local pts = { { 0, 0, 0 }, { 0.05, 0.05, 0.42 }, { 0.12, 0.36, 0.74 }, { 0.17, 0.8, 0.86 }, { 0.17, 1.2, 0.74 }, { 0.1, 1.42, 0.48 }, { 0.03, 1.36, 0.27 } }
			for i = 1, #pts - 1 do
				local d = lerp(0.26, 0.15, (i - 1) / (#pts - 2))
				limb(pts[i], pts[i + 1], d, FUR, "TailSeg", "Fabric", 0.9)
			end
			k:Part({ Name = "TailTip", Shape = "Ellipsoid", Size = { 0.2, 0.24, 0.2 }, Pos = pts[#pts], Color = FUR_DARK, Material = "Fabric" })
		end)

		--------------------------------------------------------------------------------
		-- Head
		--------------------------------------------------------------------------------
		k:Group({ Name = "HeadBob", Pos = NECK, Anim = { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 1.0 } }, function()
			k:Group({ Name = "Head", Anim = { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 0.5 } }, function()
				k:Part({ Name = "Cranium", Shape = "Ellipsoid", Size = { CRAN[4] * 2, CRAN[5] * 2, CRAN[6] * 2 }, Pos = { CRAN[1], CRAN[2], CRAN[3] }, Color = FUR, Material = "Fabric" })
				k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { MUZ[4] * 2, MUZ[5] * 2, MUZ[6] * 2 }, Pos = { MUZ[1], MUZ[2], MUZ[3] }, Color = SKIN_LIGHT })

				-- Mouth: wide toothy chimp grin
				k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { MOUTH_E[4] * 2, MOUTH_E[5] * 2, MOUTH_E[6] * 2 }, Pos = { MOUTH_E[1], MOUTH_E[2], MOUTH_E[3] }, Color = MOUTH })
				for i = -2, 2 do
					local x = i * 0.14
					local p, n = frontOf(MOUTH_E, x, 0.315 + math.abs(i) * 0.014, -0.01)
					decal(p, n, { 0.13, 0.13, 0.06 }, TEETH, "Tooth", i * 4)
				end
				do
					local p, n = frontOf(MOUTH_E, 0, 0.17, -0.01)
					decal(p, n, { 0.4, 0.15, 0.07 }, TONGUE, "Tongue", 0)
				end
				local noseP, noseN = frontOf(MUZ, 0, 0.74, -0.04)
				decal(noseP, noseN, { 0.4, 0.2, 0.16 }, SKIN, "Nose", 0)

				k:Mirror(function()
					-- heart-shaped upper face
					k:Part({ Name = "FaceMask", Shape = "Ellipsoid", Size = { FACE_R[4] * 2, FACE_R[5] * 2, FACE_R[6] * 2 }, Pos = { FACE_R[1], FACE_R[2], FACE_R[3] }, Color = SKIN })
					-- big expressive eyes (all blink together)
					local blink = { Type = "Blink", Speed = 0.3, Phase = 0.1 }
					k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.42, 0.52, 0.22 }, Pos = { 0.31, 1.08, -0.9 }, Color = EYE, Anim = blink })
					k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.29, 0.33, 0.08 }, Pos = { 0.29, 1.06, -1.0 }, Color = IRIS, Anim = blink })
					k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.15, 0.18, 0.06 }, Pos = { 0.29, 1.06, -1.03 }, Color = PUPIL, Anim = blink })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { 0.34, 1.13, -1.06 }, Color = SHINE, Material = "Neon", Anim = blink })
					-- arched chimp brow ridge with happy raised eyebrows
					k:Part({ Name = "BrowRidge", Shape = "Ellipsoid", Size = { BROW_R[4] * 2, BROW_R[5] * 2, BROW_R[6] * 2 }, Pos = { BROW_R[1], BROW_R[2], BROW_R[3] }, Rot = { 0, 0, 6 }, Color = SKIN })
					local bp, bn = frontOf(BROW_R, 0.33, 1.49, -0.03)
					decal(bp, bn, { 0.42, 0.1, 0.08 }, FUR_DARK, "Eyebrow", 12, { Material = "Fabric" })
					-- upturned grin corners
					local mp, mn = frontOf(MUZ, 0.43, 0.34, -0.005)
					decal(mp, mn, { 0.17, 0.075, 0.06 }, MOUTH, "MouthCorner", 32)
					-- nostrils, smile creases, blush, under-eye wrinkles
					local np, nn = frontOf(MUZ, 0.1, 0.72, -0.01)
					decal(np, nn, { 0.09, 0.065, 0.05 }, PEEL_BROWN_DARK, "Nostril", 20)
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
					-- fur sideburns framing the face
					for _, d in { { 0.92, -0.15, -0.5 }, { 0.82, -0.45, -0.45 }, { 0.62, -0.72, -0.42 } } do
						local p, n = onEll(CRAN, d, -0.05)
						tuft(p, vadd(n, { 0, -0.6, 0 }), 0.26, 0.44, FUR, "Sideburn")
					end
				end)

				-- chunky fur tuft on the crown, swept like a cowlick
				for i, t in {
					{ { 0, 1, -0.2 }, { 0, 1, -0.55 }, 0.74, FUR_LIGHT },
					{ { 0.28, 0.95, -0.1 }, { 0.45, 1, -0.3 }, 0.56, FUR },
					{ { -0.28, 0.95, -0.1 }, { -0.45, 1, -0.3 }, 0.56, FUR },
					{ { 0.12, 0.9, 0.3 }, { 0.2, 1, 0.4 }, 0.6, FUR_LIGHT },
					{ { -0.14, 0.9, 0.32 }, { -0.25, 1, 0.45 }, 0.52, FUR },
				} do
					local p = onEll(CRAN, t[1], -0.06)
					tuft(p, t[2], 0.3, t[3], t[4], "HairTuft")
				end
			end)
		end)

		--------------------------------------------------------------------------------
		-- Epic flair: banana glow and golden sparkles
		--------------------------------------------------------------------------------
		k:Light({ Pos = { 0, 4.6, -2.3 }, Color = "#ffe08a", Range = 10, Brightness = 1.2 })
		k:Particles({ Pos = { 0, 5.6, -0.2 }, Color = "#fff6a8", Color2 = "#ffcf2e", Rate = 5, Size = 0.22, Speed = 1.2, Lifetime = 1.6, Spread = 70, Direction = "Top" })
		k:Particles({ Pos = { 0, 3.0, 0 }, Color = "#ffe45c", Color2 = "#fff8d0", Rate = 3, Size = 0.16, Speed = 0.6, Lifetime = 2, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- banana body with a brown tip, peel flaps, cream opening, chimp head popping out
		k:Part({ Name = "Banana", Shape = "Ellipsoid", Size = { 1.3, 1.75, 1.2 }, Pos = { 0, -0.45, 0 }, Color = YEL })
		k:Part({ Name = "BananaTip", Shape = "Ellipsoid", Size = { 0.3, 0.3, 0.3 }, Pos = { 0, -1.18, 0.22 }, Color = PEEL_BROWN })
		k:Part({ Name = "PeelInside", Shape = "Cylinder", Size = { 0.1, 1.12, 1.12 }, Pos = { 0, 0.12, 0 }, Rot = { 0, 0, 90 }, Color = CREAM })
		k:Part({ Name = "FlapLeft", Shape = "Ellipsoid", Size = { 0.5, 0.9, 0.14 }, Pos = { -0.58, -0.05, -0.32 }, Rot = { 0, 35, -32 }, Color = CREAM })
		k:Part({ Name = "FlapRight", Shape = "Ellipsoid", Size = { 0.5, 0.9, 0.14 }, Pos = { 0.58, -0.05, -0.32 }, Rot = { 0, -35, 32 }, Color = CREAM })
		k:Part({ Name = "FlapBack", Shape = "Ellipsoid", Size = { 0.55, 1.0, 0.16 }, Pos = { 0, 0.45, 0.6 }, Rot = { -18, 0, 0 }, Color = YEL })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.0, 0.92, 0.92 }, Pos = { 0, 0.68, -0.05 }, Color = FUR })
		k:Part({ Name = "Ears", Shape = "Ellipsoid", Size = { 1.36, 0.38, 0.18 }, Pos = { 0, 0.68, 0 }, Color = SKIN })
		k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 0.74, 0.62, 0.3 }, Pos = { 0, 0.66, -0.42 }, Color = SKIN })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 0.58, 0.36, 0.3 }, Pos = { 0, 0.44, -0.53 }, Color = SKIN_LIGHT })
		k:Part({ Name = "EyeL", Shape = "Ellipsoid", Size = { 0.14, 0.18, 0.06 }, Pos = { -0.16, 0.75, -0.58 }, Color = PUPIL })
		k:Part({ Name = "EyeR", Shape = "Ellipsoid", Size = { 0.14, 0.18, 0.06 }, Pos = { 0.16, 0.75, -0.58 }, Color = PUPIL })
	end,
}
