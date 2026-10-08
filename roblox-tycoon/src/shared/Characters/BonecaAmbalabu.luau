--[[
	Boneca Ambalabu (Common)
	Canonical look: a glossy green frog head with huge bulging eyes, sitting on top of an
	upright black car tyre (tread, sidewall, grey rim + hub), standing on two long, thin,
	bare human legs with knees, ankles and wiggly toes.

	Coordinates: feet on y = 0, faces -Z. Most parts are written in world coordinates by
	nesting an un-animated "offset" group inside each animated joint group.
]]

-- Palette ------------------------------------------------------------------------------
local FROG = "#4fb83a" -- dominant: glossy frog green
local FROG_DARK = "#2f7f2a" -- eyelid ridges
local FROG_SPOT = "#3b9531" -- dorsal mottling
local THROAT = "#d2e37a" -- pale yellow-green chin / throat
local MOUTH = "#1d3519" -- mouth line, nostrils
local EAR = "#3f9a33" -- tympanum disc
local EYE_WHITE = "#fff6dc"
local IRIS = "#e8b22c" -- golden frog iris
local PUPIL = "#1b1b24"
local SHINE = "#fff8ec"

local RUBBER = "#25252d" -- tyre
local RUBBER_DARK = "#1c1c23"
local RUBBER_LIGHT = "#34343e" -- tread blocks / ribs
local RIM = "#b8bdc5"
local RIM_DARK = "#6c717a"
local HUB = "#d6d9de"
local LUG = "#8a8f98"

local SKIN = "#efbd96" -- bare human legs
local SKIN_DARK = "#e2a986"
local SKIN_LIGHT = "#f6d0b0"
local NAIL = "#f7dccb"

-- Layout (world studs) -------------------------------------------------------------------
local HIP_Y = 3.935 -- hip joints (top of the legs, inside the tyre bottom)
local TIRE_Y = 5.55 -- tyre centre
local TIRE_R = 1.8 -- tyre radius
local TIRE_W = 1.7 -- tyre width (along Z)
local NECK_Y = 7.1 -- head pivot (where the chin rests on the tread)

-- Head volumes {cx, cy, cz, semiX, semiY, semiZ}
local SKULL = { 0, 7.95, -0.2, 1.84, 0.92, 1.55 }
local JAW = { 0, 7.25, -0.45, 1.45, 0.425, 1.18 }

local function deg(r)
	return r * 180 / math.pi
end

-- Distance along a ray (origin p, unit dir d) to where it leaves ellipsoid e (-1 = miss)
local function exitT(e, px, py, pz, dx, dy, dz)
	local ox, oy, oz = (px - e[1]) / e[4], (py - e[2]) / e[5], (pz - e[3]) / e[6]
	local vx, vy, vz = dx / e[4], dy / e[5], dz / e[6]
	local A = vx * vx + vy * vy + vz * vz
	local B = 2 * (ox * vx + oy * vy + oz * vz)
	local C = ox * ox + oy * oy + oz * oz - 1
	local disc = B * B - 4 * A * C
	if disc < 0 then
		return -1
	end
	return (-B + math.sqrt(disc)) / (2 * A)
end

-- Point on the frog-head surface (skull + jaw) seen from (px,py,pz) along (dx,dy,dz),
-- pushed `out` studs outward. Returns position and outward unit normal.
local function headSurface(px, py, pz, dx, dy, dz, out)
	local len = math.sqrt(dx * dx + dy * dy + dz * dz)
	dx, dy, dz = dx / len, dy / len, dz / len
	local t1 = exitT(SKULL, px, py, pz, dx, dy, dz)
	local t2 = exitT(JAW, px, py, pz, dx, dy, dz)
	local e, t = SKULL, t1
	if t2 > t1 then
		e, t = JAW, t2
	end
	local x, y, z = px + dx * t, py + dy * t, pz + dz * t
	local nx = (x - e[1]) / (e[4] * e[4])
	local ny = (y - e[2]) / (e[5] * e[5])
	local nz = (z - e[3]) / (e[6] * e[6])
	local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
	nx, ny, nz = nx / nl, ny / nl, nz / nl
	return { x + nx * out, y + ny * out, z + nz * out }, { nx, ny, nz }
end

-- Rotation that points a Cylinder's axis (local X) along unit vector v
local function axisRot(vx, vy, vz)
	local l = math.sqrt(vx * vx + vy * vy + vz * vz)
	vx, vy, vz = vx / l, vy / l, vz / l
	return { 0, deg(math.atan2(-vz, vx)), deg(math.asin(vy)) }
end

-- Cylinder segment between two points
local function segment(k, name, a, b, diameter, color, material)
	local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(vx * vx + vy * vy + vz * vz)
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { len + diameter * 0.6, diameter, diameter },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(vx, vy, vz),
		Color = color,
		Material = material or "SmoothPlastic",
	})
end

--------------------------------------------------------------------------------------------
-- Tyre (built around its own centre; the axle runs along Z so the hub faces the front)
--------------------------------------------------------------------------------------------
local function buildTire(k)
	local AXLE = { 0, 90, 0 } -- turns a Cylinder's X axis onto Z
	local function disc(name, width, diameter, color, material)
		k:Part({
			Name = name,
			Shape = "Cylinder",
			Size = { width, diameter, diameter },
			Rot = AXLE,
			Color = color,
			Material = material or "Rubber",
		})
	end

	-- big forms
	disc("Tire", TIRE_W, TIRE_R * 2, RUBBER)
	disc("Sidewall", TIRE_W + 0.12, 3.3, RUBBER)
	disc("SidewallRib", TIRE_W + 0.16, 2.72, RUBBER_LIGHT)
	disc("Bead", TIRE_W + 0.2, 2.42, RUBBER_DARK)
	-- the wheel
	disc("RimFlange", TIRE_W + 0.26, 2.2, RIM, "Metal")
	disc("RimDish", TIRE_W + 0.3, 1.86, RIM_DARK, "Metal")
	disc("HubCap", TIRE_W + 0.4, 0.95, HUB, "Metal")
	disc("CenterCap", TIRE_W + 0.48, 0.42, RIM_DARK, "Metal")

	-- five spokes, visible on both faces (they run straight through the wheel)
	for i = 0, 4 do
		local a = math.rad(90 + i * 72)
		k:Part({
			Name = "Spoke",
			Size = { 0.46, 0.22, TIRE_W + 0.34 },
			Pos = { math.cos(a) * 0.7, math.sin(a) * 0.7, 0 },
			Rot = { 0, 0, deg(a) },
			Color = RIM,
			Material = "Metal",
		})
	end
	-- five lug nuts on the hub cap
	for i = 0, 4 do
		local a = math.rad(90 + 36 + i * 72)
		k:Part({
			Name = "LugNut",
			Shape = "Cylinder",
			Size = { TIRE_W + 0.46, 0.14, 0.14 },
			Pos = { math.cos(a) * 0.3, math.sin(a) * 0.3, 0 },
			Rot = AXLE,
			Color = LUG,
			Material = "Metal",
		})
	end

	-- valve stem poking out of the front of the rim
	local va = math.rad(235)
	k:Part({ Name = "ValveStem", Shape = "Cylinder", Size = { 0.34, 0.1, 0.1 }, Pos = { math.cos(va) * 0.99, math.sin(va) * 0.99, -0.92 }, Rot = AXLE, Color = RUBBER_DARK, Material = "Rubber" })
	k:Part({ Name = "ValveCap", Shape = "Cylinder", Size = { 0.1, 0.13, 0.13 }, Pos = { math.cos(va) * 0.99, math.sin(va) * 0.99, -1.12 }, Rot = AXLE, Color = LUG, Material = "Metal" })

	-- tread: two staggered rows of blocks around the whole circumference
	local N = 10
	for row = 0, 1 do
		local z = if row == 0 then -0.42 else 0.42
		for i = 0, N - 1 do
			local a = math.rad((i + row * 0.5) * 360 / N)
			k:Part({
				Name = "Tread",
				Size = { 0.2, 0.62, 0.74 },
				Pos = { math.cos(a) * (TIRE_R + 0.0), math.sin(a) * (TIRE_R + 0.0), z },
				Rot = { 0, 0, deg(a) },
				Color = RUBBER_LIGHT,
				Material = "Rubber",
			})
		end
	end
end

--------------------------------------------------------------------------------------------
-- Frog head (world coordinates)
--------------------------------------------------------------------------------------------
local function buildHead(k)
	k:Part({
		Name = "Skull",
		Shape = "Ellipsoid",
		Size = { SKULL[4] * 2, SKULL[5] * 2, SKULL[6] * 2 },
		Pos = { SKULL[1], SKULL[2], SKULL[3] },
		Color = FROG,
		Reflectance = 0.08,
	})
	k:Part({
		Name = "Throat",
		Shape = "Ellipsoid",
		Size = { JAW[4] * 2, JAW[5] * 2, JAW[6] * 2 },
		Pos = { JAW[1], JAW[2], JAW[3] },
		Color = THROAT,
		Reflectance = 0.05,
	})

	-- Wide, flat smiling mouth line wrapping around the snout (corners turn up)
	local pts = {}
	local SEG = 8
	local PHI = 88
	for i = 0, SEG do
		local f = (i / SEG) * 2 - 1 -- -1..1
		local phi = math.rad(f * PHI)
		local y = 7.56 + 0.2 * f * f + 0.12 * f * f * f * f
		local p = headSurface(0, y, -0.3, math.sin(phi), 0, -math.cos(phi), 0.025)
		table.insert(pts, p)
	end
	for i = 1, SEG do
		segment(k, "Mouth", pts[i], pts[i + 1], 0.15, MOUTH)
	end

	do
		local p, n = headSurface(0, 8.0, -0.2, 0, 0.62, 0.8, -0.025)
		k:Part({ Name = "Spot", Shape = "Cylinder", Size = { 0.08, 0.52, 0.52 }, Pos = p, Rot = axisRot(n[1], n[2], n[3]), Color = FROG_SPOT, Reflectance = 0.05 })
	end

	k:Mirror(function()
		-- mouth corner dimples
		local c = pts[SEG + 1]
		k:Part({ Name = "MouthCorner", Shape = "Ball", Size = { 0.17, 0.17, 0.17 }, Pos = { c[1] - 0.03, c[2] + 0.03, c[3] }, Color = MOUTH })

		-- Nostrils
		local np = headSurface(0, 8.0, -0.2, 0.17, 0.02, -1, -0.02)
		k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.17, 0.11, 0.12 }, Pos = np, Rot = { 10, 0, 0 }, Color = MOUTH })

		-- Tympanum (round ear drum) behind each eye
		local tp, tn = headSurface(0, 8.0, -0.2, 0.95, 0.08, 0.35, -0.02)
		k:Part({ Name = "Tympanum", Shape = "Cylinder", Size = { 0.1, 0.62, 0.62 }, Pos = tp, Rot = axisRot(tn[1], tn[2], tn[3]), Color = EAR, Reflectance = 0.1 })

		-- Dorsal mottling: flat darker patches lying on the skin
		local spots = {
			{ 0.36, 0.85, 0.4, 0.48 },
			{ 0.74, 0.42, 0.62, 0.4 },
		}
		for _, s in spots do
			local p, n = headSurface(0, 8.0, -0.2, s[1], s[2], s[3], -0.025)
			k:Part({ Name = "Spot", Shape = "Cylinder", Size = { 0.08, s[4], s[4] }, Pos = p, Rot = axisRot(n[1], n[2], n[3]), Color = FROG_SPOT, Reflectance = 0.05 })
		end

		-- Huge bulging eye
		local EC = { 0.9, 8.76, -0.84 } -- eyeball centre
		local ER = 0.57
		k:Part({ Name = "EyeDome", Shape = "Ball", Size = { 1.34, 1.34, 1.34 }, Pos = { 0.88, 8.68, -0.68 }, Color = FROG, Reflectance = 0.08 })
		k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 1.2, 0.42, 1.12 }, Pos = { 0.88, 9.08, -0.64 }, Rot = { -12, 0, -6 }, Color = FROG_DARK, Reflectance = 0.06 })
		local BLINK = { Type = "Blink", Speed = 0.28, Phase = 0.3 }
		k:Part({ Name = "Eyeball", Shape = "Ball", Size = { ER * 2, ER * 2, ER * 2 }, Pos = EC, Color = EYE_WHITE, Anim = BLINK })
		-- iris / pupil are flattened lenses sunk into the eyeball: only their front caps show,
		-- so their edges never poke out of the white. They look forward and slightly outward.
		local function onEye(yaw, pitch, r)
			local dx = math.sin(math.rad(yaw))
			local dy = math.sin(math.rad(pitch)) * math.cos(math.rad(yaw))
			local dz = -math.cos(math.rad(pitch)) * math.cos(math.rad(yaw))
			return { EC[1] + dx * r, EC[2] + dy * r, EC[3] + dz * r }
		end
		local LOOK = { 6, -16, 0 }
		k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.74, 0.74, 0.32 }, Pos = onEye(16, 6, 0.43), Rot = LOOK, Color = IRIS, Anim = BLINK })
		k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.5, 0.54, 0.28 }, Pos = onEye(16, 6, 0.49), Rot = LOOK, Color = PUPIL, Anim = BLINK })
		k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.15, 0.15, 0.15 }, Pos = onEye(7, 17, 0.61), Color = SHINE, Material = "Neon", Anim = BLINK })
	end)
end

--------------------------------------------------------------------------------------------
-- One long, thin, bare human leg. side = 1 (right, +X) or -1 (left, -X).
-- stride = forward swing at the hip (degrees): the meme is "frozen mid-stride".
--------------------------------------------------------------------------------------------
local function buildLeg(k, side, phase, stride)
	local SWING = 7
	local SPEED = 0.55
	k:Group({
		Name = if side > 0 then "RightLeg" else "LeftLeg",
		Pos = { 0.56 * side, HIP_Y, 0.05 },
		Rot = { stride, 0, 2 * side },
		Anim = { Type = "Wiggle", Axis = "X", Amount = SWING, Speed = SPEED, Phase = phase },
	}, function()
		-- one long tapering thigh: widest mid-thigh, narrowing into the knee
		k:Part({ Name = "Thigh", Shape = "Ellipsoid", Size = { 0.66, 2.75, 0.72 }, Pos = { 0, -0.92, 0 }, Color = SKIN })

		-- knee bends the opposite way so the foot stays planted (a little knee-dip shuffle)
		k:Group({
			Name = "Knee",
			Pos = { 0, -1.95, 0 },
			Anim = { Type = "Wiggle", Axis = "X", Amount = -SWING * 2, Speed = SPEED, Phase = phase },
		}, function()
			k:Part({ Name = "KneeCap", Shape = "Ellipsoid", Size = { 0.32, 0.38, 0.22 }, Pos = { 0, 0.02, -0.14 }, Color = SKIN })
			k:Part({ Name = "Shin", Shape = "Ellipsoid", Size = { 0.46, 2.1, 0.48 }, Pos = { 0, -0.8, 0 }, Color = SKIN })
			k:Part({ Name = "Calf", Shape = "Ellipsoid", Size = { 0.44, 1.3, 0.42 }, Pos = { 0.01 * side, -0.66, 0.065 }, Color = SKIN })

			k:Group({
				Name = "Ankle",
				Pos = { 0, -1.68, 0 },
				Rot = { -stride, -8 * side, -2 * side },
				Anim = { Type = "Wiggle", Axis = "X", Amount = SWING, Speed = SPEED, Phase = phase },
			}, function()
				-- ankle knob (the outer one sits a little lower, like a real ankle)
				k:Part({ Name = "AnkleBone", Shape = "Ellipsoid", Size = { 0.33, 0.3, 0.3 }, Pos = { 0.015 * side, -0.02, 0.02 }, Color = SKIN })
				k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.56, 0.34, 1.3 }, Pos = { 0.03 * side, -0.15, -0.36 }, Color = SKIN })
				k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.38, 0.34, 0.42 }, Pos = { 0, -0.15, 0.1 }, Color = SKIN })

				-- toes curl and wiggle around their base knuckle
				k:Group({
					Name = "Toes",
					Pos = { 0, -0.2, -0.86 },
					Anim = { Type = "Wiggle", Axis = "X", Amount = 14, Speed = 1.1, Phase = phase + 0.2 },
				}, function()
					-- inner (big) toe -> outer (little) toe: {x, z, diameter}
					local toes = {
						{ -0.15, -0.12, 0.25 },
						{ -0.01, -0.1, 0.18 },
						{ 0.1, -0.07, 0.165 },
						{ 0.195, -0.03, 0.15 },
						{ 0.27, 0.03, 0.13 },
					}
					for i, t in toes do
						local d = t[3]
						-- toe bottoms rest on the ground (ground is local y = -0.12 here)
						k:Part({ Name = "Toe", Shape = "Ball", Size = { d, d, d }, Pos = { (t[1] + 0.03) * side, -0.12 + d / 2, t[2] }, Color = if i == 1 then SKIN else SKIN_DARK })
					end
					k:Part({ Name = "BigToeNail", Shape = "Ellipsoid", Size = { 0.15, 0.05, 0.12 }, Pos = { -0.12 * side, 0.0, -0.19 }, Rot = { 14, 0, 0 }, Color = NAIL })
				end)
			end)
		end)
	end)
end

return {
	Id = "BonecaAmbalabu",
	Name = "Boneca Ambalabu",
	Rarity = "Common",
	Emoji = "🐸",
	Color = FROG,
	Tagline = "Frog head. Car tyre. Human legs. Ambalabu.",
	Lore = "Spotted at dawn strolling down a quiet street: a frog head on a car tyre on two very human legs. Nobody knows where the rest of the frog went, and nobody dares to ask. It never blinks first.",

	Build = function(k)
		-- Legs (written separately so they shuffle out of phase)
		buildLeg(k, 1, 0, 8)
		buildLeg(k, -1, 0.5, -6)

		-- Tyre torso + head sway together around the hips
		k:Group({ Name = "Body", Pos = { 0, HIP_Y, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.4 } }, function()
			k:Group({ Name = "BodyOffset", Pos = { 0, -HIP_Y, 0 } }, function()
				-- the tyre rocks a little on its own axle
				k:Group({ Name = "Wheel", Pos = { 0, TIRE_Y, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.3, Phase = 0.25 } }, function()
					buildTire(k)
				end)

				-- head bobs and tilts on the neck
				k:Group({ Name = "HeadBob", Pos = { 0, NECK_Y, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.07, Speed = 0.8 } }, function()
					k:Group({ Name = "Head", Anim = { Type = "Wiggle", Axis = "Z", Amount = 7, Speed = 0.35, Phase = 0.1 } }, function()
						k:Group({ Name = "HeadOffset", Pos = { 0, -NECK_Y, 0 } }, function()
							buildHead(k)
						end)
					end)
				end)
			end)
		end)
	end,

	BuildMini = function(k)
		-- legs + feet
		k:Mirror(function()
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.78, 0.2, 0.2 }, Pos = { 0.26, -0.92, 0 }, Rot = { 0, 0, 90 }, Color = SKIN })
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.26, 0.15, 0.44 }, Pos = { 0.28, -1.26, -0.09 }, Color = SKIN })
		end)
		-- tyre with grey hub, facing front
		k:Part({ Name = "Tire", Shape = "Cylinder", Size = { 0.7, 1.34, 1.34 }, Pos = { 0, -0.05, 0 }, Rot = { 0, 90, 0 }, Color = RUBBER, Material = "Rubber" })
		k:Part({ Name = "Hub", Shape = "Cylinder", Size = { 0.78, 0.66, 0.66 }, Pos = { 0, -0.05, 0 }, Rot = { 0, 90, 0 }, Color = RIM, Material = "Metal" })
		-- frog head
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.5, 0.82, 1.3 }, Pos = { 0, 0.82, -0.05 }, Color = FROG })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.44, 0.44, 0.44 }, Pos = { 0.36, 1.08, -0.4 }, Color = EYE_WHITE })
			k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.22, 0.22, 0.22 }, Pos = { 0.39, 1.08, -0.58 }, Color = PUPIL })
		end)
		-- thin dark disc: only its rim pokes out of the head = wrap-around mouth line
		k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { 1.42, 0.06, 1.28 }, Pos = { 0, 0.66, -0.1 }, Color = MOUTH })
	end,
}
