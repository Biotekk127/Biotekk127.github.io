--[[
	Frigo Camelo (Epic)
	Canonical look ("Frigo Camello Buffo Fardello", @ofuscabreno, Feb 2025): a camel whose
	body is an upright white refrigerator. The camel's long tan neck and head rise out of
	the top of the fridge (heavy droopy eyelids, long lashes, big split lips, small ears),
	and two camel legs stomp around underneath in giant wheat-coloured work boots. Cold
	vapour drifts from its mouth ("Che freddo qui dentro...").

	Fridge: freezer door on top, main door below (slightly ajar, glowing cool blue, food
	inside), chrome handles + hinges, badge plate, frost and icicles (Epic flair).

	Coordinates: feet on y = 0, faces -Z. Parts that animate are written in world
	coordinates inside "pivot" groups (joint group + inverse offset), except the head and
	eyes which are written in their own local frames.
]]

-- Palette ------------------------------------------------------------------------------
local FRIDGE = "#f6f2e7" -- dominant: warm retro cream-white enamel
local DOOR = "#fcf8ee"
local SEAM = "#7d7b78"
local GASKET = "#9a9ea6"
local CHROME = "#dfe4ea"
local CHROME_DARK = "#9aa2ad"
local LINER = "#dcf1ff" -- fridge interior
local GLOW = "#8fe0ff" -- cool interior light (Neon accent)
local ICE = "#bfeaff"
local FROST = "#f2fbff"
local DARK = "#2a2b33"
local COIL = "#34353d"

local FUR = "#c8995c" -- secondary: camel tan
local FUR_DARK = "#9f713d"
local FUR_LIGHT = "#e3c38f"
local FUR_MID = "#b6864d"
local MUZZLE = "#dcc29b"
local LIP = "#c39a6e"
local LIP_DARK = "#6e4a33"
local MOUTH = "#3a2321"
local TEETH = "#f4e9cc"
local NOSTRIL = "#4a3022"
local EAR_IN = "#d9a58a"
local EYE_WHITE = "#fff8ec"
local IRIS = "#5a3420"
local PUPIL = "#1b1b24"
local SHINE = "#ffffff"
local LID = "#b9874d"
local LASH = "#2b1d17"
local CALLUS = "#7b5d48"

local BOOT = "#d49c4b" -- accent: wheat nubuck work boots
local BOOT_DARK = "#b88234"
local COLLAR = "#5b3a25"
local SOLE = "#4a3427"
local WELT = "#8a5f36"
local LACE = "#a06d3c"
local EYELET = "#c9a24f"
local STITCH = "#f1d9a6"

local RED = "#e8463e"
local YELLOW = "#ffd23a"
local GREEN = "#4cc36b"
local BLUE = "#3f8cff"
local PAPER = "#fff8ec"

-- Layout (world studs) ------------------------------------------------------------------
local FX = 1.3 -- fridge half width
local FZ0 = -0.95 -- cabinet front plane (doors sit in front of it)
local FZ1 = 1.0 -- cabinet back plane
local FB = 2.85 -- fridge bottom
local FT = 6.75 -- fridge top
local R = 0.25 -- rounded vertical corner radius
local FH = FT - FB
local FY = (FB + FT) / 2
local DT = 0.26 -- door thickness
local CAV_B, CAV_T, CAV_Z = 3.2, 5.3, -0.05 -- main compartment cavity
local MAIN_B, MAIN_T = 3.12, 5.26 -- main door
local FRZ_B, FRZ_T = 5.33, 6.7 -- freezer door

local HIP_Y = 3.0
local NECK0 = { 0, 6.78, -0.3 } -- neck base on top of the fridge
local J = { 0, 8.2, -0.82 } -- head joint
local HS = 1.22 -- head scale

local function deg(r)
	return r * 180 / math.pi
end

-- Rotation that points a Cylinder's axis (local X) along vector v
local function axisRot(vx, vy, vz)
	local l = math.sqrt(vx * vx + vy * vy + vz * vz)
	vx, vy, vz = vx / l, vy / l, vz / l
	return { 0, deg(math.atan2(-vz, vx)), deg(math.asin(vy)) }
end

-- Rotation that turns a part's front (-Z) to face unit normal n
local function faceRot(n, rz)
	return { deg(math.atan2(n[2], -n[3])), deg(-math.asin(n[1])), rz or 0 }
end

-- Cylinder segment between two points
local function segment(k, name, a, b, diameter, color, material, extra)
	local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(vx * vx + vy * vy + vz * vz)
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { len + (extra or diameter * 0.5), diameter, diameter },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(vx, vy, vz),
		Color = color,
		Material = material or "SmoothPlastic",
	})
end

-- Upright cylinder (round in XZ)
local function post(k, name, pos, height, diameter, color, material, extra)
	local spec = {
		Name = name,
		Shape = "Cylinder",
		Size = { height, diameter, diameter },
		Pos = pos,
		Rot = { 0, 0, 90 },
		Color = color,
		Material = material or "SmoothPlastic",
	}
	if extra then
		for key, v in extra do
			spec[key] = v
		end
	end
	k:Part(spec)
end

-- Joint group whose contents are written in world coordinates
local function pivot(k, name, pos, anim, fn)
	k:Group({ Name = name, Pos = pos, Anim = anim }, function()
		k:Group({ Name = name .. "Offset", Pos = { -pos[1], -pos[2], -pos[3] } }, fn)
	end)
end

-- Point on an (unrotated) ellipsoid E = {cx, cy, cz, ax, ay, az} along direction u from its
-- centre, pushed `out` along the surface normal. Returns position and unit normal.
local function surf(E, ux, uy, uz, out)
	local l = math.sqrt(ux * ux + uy * uy + uz * uz)
	ux, uy, uz = ux / l, uy / l, uz / l
	local t = 1 / math.sqrt((ux / E[4]) ^ 2 + (uy / E[5]) ^ 2 + (uz / E[6]) ^ 2)
	local px, py, pz = ux * t, uy * t, uz * t
	local nx, ny, nz = px / (E[4] * E[4]), py / (E[5] * E[5]), pz / (E[6] * E[6])
	local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
	nx, ny, nz = nx / nl, ny / nl, nz / nl
	return { E[1] + px + nx * out, E[2] + py + ny * out, E[3] + pz + nz * out }, { nx, ny, nz }
end

-- Head-space helpers (head parts are authored unscaled, then scaled by HS)
local function hv(v)
	return { v[1] * HS, v[2] * HS, v[3] * HS }
end
local function hpart(k, spec)
	spec.Size = hv(spec.Size)
	if spec.Pos then
		spec.Pos = hv(spec.Pos)
	end
	k:Part(spec)
end

--------------------------------------------------------------------------------------------
-- Fridge cabinet (static shell, cavity, food, back, frost)
--------------------------------------------------------------------------------------------
local function buildCabinet(k)
	-- rounded vertical corners + side walls
	k:Mirror(function()
		post(k, "CornerFront", { FX - R, FY, FZ0 + R }, FH, R * 2, FRIDGE)
		post(k, "CornerBack", { FX - R, FY, FZ1 - R }, FH, R * 2, FRIDGE)
		k:Part({ Name = "SideWall", Size = { R, FH, (FZ1 - R) - (FZ0 + R) }, Pos = { FX - R / 2, FY, (FZ0 + FZ1) / 2 }, Color = FRIDGE })
	end)
	-- back half (solid), freezer block and plinth in front of it, cavity between
	k:Part({ Name = "CabinetBack", Size = { 2 * (FX - R), FH, FZ1 - CAV_Z }, Pos = { 0, FY, (FZ1 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "FreezerBlock", Size = { 2 * (FX - R), FT - CAV_T, CAV_Z - FZ0 }, Pos = { 0, (FT + CAV_T) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "Plinth", Size = { 2 * (FX - R), CAV_B - FB, CAV_Z - FZ0 }, Pos = { 0, (FB + CAV_B) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })

	-- interior (seen through the ajar door; the door hinges on +X so the gap is at -X)
	local cavH = CAV_T - CAV_B
	local cavY = (CAV_B + CAV_T) / 2
	k:Part({ Name = "LinerBack", Size = { 1.7, cavH, 0.05 }, Pos = { 0, cavY, CAV_Z - 0.025 }, Color = LINER })
	k:Part({ Name = "LinerSide", Size = { 0.26, cavH, 0.55 }, Pos = { -0.93, cavY, -0.33 }, Color = LINER })
	k:Part({ Name = "FridgeLamp", Size = { 1.3, 0.06, 0.14 }, Pos = { 0, CAV_T - 0.04, -0.45 }, Color = GLOW, Material = "Neon" })
	for _, y in { 3.92, 4.6 } do
		k:Part({ Name = "GlassShelf", Size = { 1.62, 0.06, 0.62 }, Pos = { 0, y, -0.37 }, Color = "#d6f2ff", Material = "Glass", Transparency = 0.3 })
	end
	-- food
	k:Part({ Name = "MilkCarton", Size = { 0.3, 0.5, 0.3 }, Pos = { -0.5, CAV_B + 0.25, -0.35 }, Color = "#fbfbf6" })
	k:Part({ Name = "MilkBand", Size = { 0.32, 0.12, 0.32 }, Pos = { -0.5, CAV_B + 0.36, -0.35 }, Color = BLUE })
	k:Part({ Name = "Cheese", Shape = "Wedge", Size = { 0.42, 0.24, 0.34 }, Pos = { -0.48, 3.95 + 0.12, -0.35 }, Rot = { 0, 180, 0 }, Color = "#ffcf4a" })
	k:Part({ Name = "Apple", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = { -0.05, 3.95 + 0.13, -0.4 }, Color = RED })
	post(k, "Bottle", { -0.52, 4.63 + 0.25, -0.38 }, 0.5, 0.18, "#3fae6a", "Glass")
	post(k, "Jar", { -0.14, 4.63 + 0.13, -0.38 }, 0.26, 0.26, "#ff9a3c")

	-- seam between freezer and main compartment
	k:Part({ Name = "DoorSeam", Size = { 2.5, 0.07, 0.08 }, Pos = { 0, (MAIN_T + FRZ_B) / 2, FZ0 - 0.03 }, Color = SEAM })

	-- kick-plate vent grille under the main door
	k:Part({ Name = "Grille", Size = { 1.9, 0.2, 0.05 }, Pos = { 0, 2.98, FZ0 - 0.02 }, Color = DARK })
	for i = -2, 2 do
		k:Part({ Name = "GrilleSlat", Size = { 0.08, 0.16, 0.05 }, Pos = { i * 0.34, 2.98, FZ0 - 0.04 }, Color = CHROME_DARK, Material = "Metal" })
	end

	-- barrel hinges on the right (+X) edge
	for _, y in { FRZ_T + 0.02, (MAIN_T + FRZ_B) / 2, MAIN_B - 0.02 } do
		post(k, "Hinge", { FX - 0.02, y, FZ0 - 0.07 }, 0.24, 0.16, CHROME, "Metal", { Reflectance = 0.2 })
	end

	-- overhanging top trim above the freezer door, icicles hanging off it
	k:Part({ Name = "Canopy", Size = { 2.5, 0.14, 0.34 }, Pos = { 0, FT + 0.01, FZ0 - 0.15 }, Color = FRIDGE })
	k:Part({ Name = "CanopyLip", Shape = "Cylinder", Size = { 2.5, 0.14, 0.14 }, Pos = { 0, FT + 0.01, FZ0 - 0.32 }, Color = FRIDGE })
	local icicles = { { -0.98, 0.3 }, { -0.5, 0.46 }, { 0.02, 0.26 }, { 0.46, 0.52 }, { 0.92, 0.34 } }
	for _, ic in icicles do
		local x, len = ic[1], ic[2]
		local z = FZ0 - 0.31
		k:Part({ Name = "IcicleRoot", Shape = "Ellipsoid", Size = { 0.17, 0.22, 0.13 }, Pos = { x, FT - 0.06, z }, Color = ICE, Material = "Ice", Transparency = 0.1, Reflectance = 0.15 })
		k:Part({ Name = "Icicle", Shape = "Ellipsoid", Size = { 0.08, len, 0.08 }, Pos = { x, FT - 0.1 - len / 2 + 0.03, z }, Color = ICE, Material = "Ice", Transparency = 0.1, Reflectance = 0.15 })
	end
	-- snowy frost crust along the top edges
	k:Mirror(function()
		k:Part({ Name = "FrostCrust", Shape = "Ellipsoid", Size = { 0.62, 0.1, 0.42 }, Pos = { 0.82, FT + 0.01, 0.55 }, Rot = { 0, 20, 0 }, Color = FROST, Material = "Snow" })
	end)

	-- energy sticker on the right side
	k:Part({ Name = "EnergySticker", Size = { 0.05, 0.34, 0.5 }, Pos = { FX + 0.01, 3.55, 0.45 }, Color = CHROME, Material = "Metal", Text = { Text = "A+++", Color = "#2f9e5a", Face = "Right" } })

	-- back: condenser coil grid, compressor
	for i = 0, 4 do
		local x = -0.8 + i * 0.4
		post(k, "CoilTube", { x, 5.0, FZ1 + 0.04 }, 2.8, 0.08, COIL, "Metal")
	end
	for _, y in { 4.1, 5.9 } do
		k:Part({ Name = "CoilWire", Shape = "Cylinder", Size = { 1.76, 0.05, 0.05 }, Pos = { 0, y, FZ1 + 0.1 }, Color = COIL, Material = "Metal" })
	end
	k:Part({ Name = "Compressor", Shape = "Ellipsoid", Size = { 0.7, 0.42, 0.34 }, Pos = { 0.35, 3.25, FZ1 + 0.06 }, Color = DARK, Material = "Metal" })
end

--------------------------------------------------------------------------------------------
-- Doors. Both hinge on the +X edge; door-local x runs from 0 (hinge) to -2*FX (free edge).
--------------------------------------------------------------------------------------------
local function doorSlab(k, name, h)
	k:Part({ Name = name, Size = { 2 * FX - DT, h, DT }, Pos = { -FX, 0, -DT / 2 }, Color = DOOR })
	post(k, name .. "EdgeHinge", { -DT / 2, 0, -DT / 2 }, h, DT, DOOR)
	post(k, name .. "EdgeFree", { -(2 * FX - DT / 2), 0, -DT / 2 }, h, DT, DOOR)
end

local function handle(k, y, len)
	local x = -(2 * FX - 0.3)
	post(k, "HandleBar", { x, y, -DT - 0.17 }, len, 0.12, CHROME, "Metal", { Reflectance = 0.3 })
	for _, s in { -1, 1 } do
		k:Part({ Name = "HandlePost", Size = { 0.09, 0.09, 0.18 }, Pos = { x, y + s * (len / 2 - 0.08), -DT - 0.08 }, Color = CHROME_DARK, Material = "Metal" })
	end
end

local function buildFreezerDoor(k)
	local h = FRZ_T - FRZ_B
	k:Group({ Name = "FreezerDoor", Pos = { FX, (FRZ_B + FRZ_T) / 2, FZ0 } }, function()
		doorSlab(k, "FreezerDoor", h)
		handle(k, -h / 2 + 0.42, 0.55)
		local fz = -DT - 0.02
		-- badge plate (generic, not a brand)
		k:Part({ Name = "Badge", Size = { 0.72, 0.2, 0.05 }, Pos = { -FX, 0.3, fz }, Color = CHROME, Material = "Metal", Reflectance = 0.25, Text = { Text = "FRIGO", Color = "#2d5f8a", Face = "Front" } })
		-- digital thermometer
		k:Part({ Name = "TempDisplay", Size = { 0.46, 0.2, 0.05 }, Pos = { -FX, -0.12, fz }, Color = DARK, Text = { Text = "-18°", Color = GLOW, Face = "Front" } })
		k:Part({ Name = "PowerLed", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { -FX - 0.33, -0.12, fz }, Color = GLOW, Material = "Neon", Anim = { Type = "Pulse", Amount = 0.35, Speed = 0.7 } })
		-- neon snowflake emblem
		for i = 0, 2 do
			k:Part({ Name = "Snowflake", Size = { 0.44, 0.06, 0.05 }, Pos = { -0.55, 0.05, fz - 0.005 }, Rot = { 0, 0, i * 60 }, Color = GLOW, Material = "Neon", Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.5 } })
		end
	end)
end

local function buildMainDoor(k)
	local h = MAIN_T - MAIN_B
	-- hinge pivot at the back corner of the door; the door hangs slightly open
	k:Group({ Name = "MainDoorHinge", Pos = { FX, (MAIN_B + MAIN_T) / 2, FZ0 }, Rot = { 0, -11, 0 } }, function()
		k:Group({ Name = "MainDoor", Anim = { Type = "Wiggle", Axis = "Y", Amount = 5, Speed = 0.3 } }, function()
			doorSlab(k, "MainDoor", h)
			handle(k, h / 2 - 0.5, 0.7)
			-- inside of the door
			k:Part({ Name = "DoorLiner", Size = { 2.2, h - 0.2, 0.05 }, Pos = { -FX, 0, 0.025 }, Color = LINER })
			k:Part({ Name = "DoorGasket", Size = { 0.06, h - 0.12, 0.06 }, Pos = { -(2 * FX - 0.16), 0, 0.03 }, Color = GASKET, Material = "Rubber" })
			k:Part({ Name = "BinLip", Size = { 1.35, 0.16, 0.05 }, Pos = { -1.4, -0.49, 0.3 }, Color = "#eef8ff", Material = "Glass", Transparency = 0.3 })
			k:Part({ Name = "BinFloor", Size = { 1.35, 0.05, 0.3 }, Pos = { -1.4, -0.57, 0.15 }, Color = "#eef8ff" })
			post(k, "DoorBottle", { -1.85, -0.33, 0.15 }, 0.44, 0.17, "#3fae6a", "Glass")
			post(k, "JuiceBottle", { -2.08, -0.35, 0.15 }, 0.4, 0.17, "#ffb13b")
			-- fridge magnets + a kid's drawing of Frigo Camelo on the front
			local fz = -DT - 0.02
			k:Part({ Name = "Drawing", Size = { 0.6, 0.72, 0.05 }, Pos = { -0.82, 0.12, fz }, Rot = { 0, 0, -5 }, Color = PAPER })
			k:Part({ Name = "DrawingFridge", Size = { 0.2, 0.26, 0.05 }, Pos = { -0.84, -0.03, fz - 0.01 }, Rot = { 0, 0, -5 }, Color = "#9fd4ff" })
			k:Part({ Name = "DrawingNeck", Size = { 0.05, 0.22, 0.05 }, Pos = { -0.81, 0.2, fz - 0.01 }, Rot = { 0, 0, -12 }, Color = FUR_DARK })
			k:Part({ Name = "DrawingHead", Shape = "Ellipsoid", Size = { 0.14, 0.09, 0.05 }, Pos = { -0.74, 0.31, fz - 0.01 }, Color = FUR_DARK })
			k:Part({ Name = "DrawingMagnet", Shape = "Cylinder", Size = { 0.06, 0.13, 0.13 }, Pos = { -0.86, 0.45, fz - 0.035 }, Rot = { 0, 90, 0 }, Color = BLUE })
			for _, s in { -1, 1 } do
				k:Part({ Name = "HeartLobe", Shape = "Ellipsoid", Size = { 0.15, 0.15, 0.05 }, Pos = { -1.62 + s * 0.055, 0.6, fz - 0.02 }, Color = RED })
			end
			k:Part({ Name = "HeartTip", Size = { 0.13, 0.13, 0.05 }, Pos = { -1.62, 0.535, fz - 0.02 }, Rot = { 0, 0, 45 }, Color = RED })
			k:Part({ Name = "PizzaMagnet", Shape = "Wedge", Size = { 0.05, 0.3, 0.24 }, Pos = { -1.6, -0.4, fz - 0.02 }, Rot = { 0, -90, 0 }, Color = YELLOW })
			k:Part({ Name = "Pepperoni", Shape = "Cylinder", Size = { 0.05, 0.07, 0.07 }, Pos = { -1.6, -0.45, fz - 0.05 }, Rot = { 0, 90, 0 }, Color = RED })
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Power cord "tail" at the back
--------------------------------------------------------------------------------------------
local function buildCord(k)
	local base = { -0.5, 3.3, FZ1 + 0.05 }
	k:Group({ Name = "PowerCord", Pos = base, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.45 } }, function()
		local pts = { { 0, 0, 0 }, { 0, -0.15, 0.38 }, { 0.06, -0.75, 0.48 }, { 0.08, -1.18, 0.24 } }
		for i = 1, #pts - 1 do
			segment(k, "Cord", pts[i], pts[i + 1], 0.07, DARK, "Rubber", 0.06)
		end
		local p = pts[#pts]
		k:Part({ Name = "Plug", Size = { 0.18, 0.22, 0.14 }, Pos = { p[1], p[2] - 0.1, p[3] }, Color = DARK, Material = "Rubber" })
		for _, s in { -1, 1 } do
			k:Part({ Name = "PlugPin", Shape = "Cylinder", Size = { 0.16, 0.05, 0.05 }, Pos = { p[1] + s * 0.05, p[2] - 0.27, p[3] }, Rot = { 0, 0, 90 }, Color = CHROME, Material = "Metal" })
		end
	end)
end

--------------------------------------------------------------------------------------------
-- Neck (smooth capsule chain), hump
--------------------------------------------------------------------------------------------
local NECK = { NECK0, { 0, 7.3, -0.36 }, { 0, 7.75, -0.52 }, { 0, 8.08, -0.72 }, J }
local NECK_D = { 0.9, 0.84, 0.78, 0.72 }

local function buildNeck(k)
	for i = 1, #NECK - 1 do
		local a, b = NECK[i], NECK[i + 1]
		segment(k, "Neck", a, b, NECK_D[i], FUR, "SmoothPlastic", 0)
		if i > 1 then
			k:Part({ Name = "NeckJoint", Shape = "Ball", Size = { NECK_D[i], NECK_D[i], NECK_D[i] }, Pos = a, Color = FUR })
		end
	end
	-- dark mane ridge down the back of the neck
	for i = 1, 3 do
		local a, b = NECK[i], NECK[i + 1]
		local dy, dz = b[2] - a[2], b[3] - a[3]
		k:Part({ Name = "Mane", Shape = "Ellipsoid", Size = { 0.3, 0.62, 0.3 }, Pos = { 0, (a[2] + b[2]) / 2 + 0.04, (a[3] + b[3]) / 2 + NECK_D[i] * 0.44 }, Rot = { deg(math.atan2(dz, dy)), 0, 0 }, Color = FUR_DARK, Material = "Fabric" })
	end
	-- shaggy throat fur on the front of the neck
	for i, t in { { 7.1, 0.56, 0.3 }, { 7.6, 0.5, 0.28 } } do
		k:Part({ Name = "ThroatFur", Shape = "Ellipsoid", Size = { t[2], 0.62, t[3] }, Pos = { 0, t[1], NECK[i + 1][3] - 0.34 }, Rot = { 10, 0, 0 }, Color = FUR_MID, Material = "Fabric" })
	end
end

local function buildNeckBase(k)
	-- rubber gasket collar where the neck pokes through the fridge top
	post(k, "NeckGasket", { NECK0[1], FT + 0.03, NECK0[3] }, 0.1, 1.12, GASKET, "Rubber")
	-- fluffy fur ruff around the base
	for i = 0, 5 do
		local a = math.rad(i * 60 + 30)
		k:Part({ Name = "Ruff", Shape = "Ellipsoid", Size = { 0.42, 0.22, 0.34 }, Pos = { math.cos(a) * 0.44, FT + 0.12, NECK0[3] + math.sin(a) * 0.44 }, Rot = { 0, -i * 60 - 30, 0 }, Color = if i % 2 == 0 then FUR_DARK else FUR, Material = "Fabric" })
	end
	-- small dromedary hump behind the neck
	k:Part({ Name = "Hump", Shape = "Ellipsoid", Size = { 1.2, 0.9, 1.1 }, Pos = { 0, FT + 0.02, 0.45 }, Color = FUR })
	k:Part({ Name = "HumpTuft", Shape = "Ellipsoid", Size = { 0.62, 0.26, 0.62 }, Pos = { 0, FT + 0.4, 0.5 }, Color = FUR_DARK, Material = "Fabric" })
end

--------------------------------------------------------------------------------------------
-- Head (local to the head joint; authored unscaled, scaled by HS)
--------------------------------------------------------------------------------------------
local E_CRAN = { 0, 0.3, 0.05, 0.48, 0.44, 0.53 }
local E_FACE = { 0, 0.18, -0.6, 0.39, 0.37, 0.68 }
local E_MUZ = { 0, -0.05, -1.2, 0.4, 0.36, 0.42 }

local function ell(k, name, E, color, material)
	hpart(k, { Name = name, Shape = "Ellipsoid", Size = { E[4] * 2, E[5] * 2, E[6] * 2 }, Pos = { E[1], E[2], E[3] }, Color = color, Material = material })
end

local function buildEye(k)
	local ER = 0.2
	local c, n = surf(E_CRAN, 0.6, 0.22, -0.8, -0.05)
	k:Group({ Name = "Eye", Pos = hv(c), Rot = faceRot(n) }, function()
		local BLINK = { Type = "Blink", Speed = 0.22, Phase = 0.35 }
		local function onEye(yaw, pitch, depth)
			local r = ER + depth
			return { math.sin(math.rad(yaw)) * math.cos(math.rad(pitch)) * r, math.sin(math.rad(pitch)) * r, -math.cos(math.rad(yaw)) * math.cos(math.rad(pitch)) * r }
		end
		hpart(k, { Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.54, 0.5, 0.24 }, Pos = { 0, -0.01, 0.07 }, Color = FUR_DARK })
		hpart(k, { Name = "Eyeball", Shape = "Ball", Size = { ER * 2, ER * 2, ER * 2 }, Color = EYE_WHITE, Anim = BLINK })
		hpart(k, { Name = "Iris", Shape = "Ellipsoid", Size = { 0.26, 0.28, 0.08 }, Pos = onEye(-22, -6, -0.025), Rot = { -6, 22, 0 }, Color = IRIS, Anim = BLINK })
		hpart(k, { Name = "Pupil", Shape = "Ellipsoid", Size = { 0.15, 0.17, 0.06 }, Pos = onEye(-22, -6, 0.0), Rot = { -6, 22, 0 }, Color = PUPIL, Anim = BLINK })
		hpart(k, { Name = "EyeShine", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = onEye(-32, 4, 0.02), Color = SHINE, Material = "Neon", Anim = BLINK })
		-- heavy, droopy upper lid (half closed: proud but tired)
		hpart(k, { Name = "UpperLid", Shape = "Ellipsoid", Size = { 0.5, 0.3, 0.47 }, Pos = { 0, 0.15, -0.005 }, Rot = { 0, 0, -12 }, Color = LID })
		hpart(k, { Name = "LowerLid", Shape = "Ellipsoid", Size = { 0.44, 0.1, 0.4 }, Pos = { 0, -0.17, 0.0 }, Color = FUR_LIGHT })
		hpart(k, { Name = "Brow", Shape = "Ellipsoid", Size = { 0.5, 0.1, 0.22 }, Pos = { 0, 0.34, 0.03 }, Rot = { 0, 0, -15 }, Color = FUR_DARK, Material = "Fabric" })
		-- long lashes fanning out from the lid edge
		for _, phi in { -40, 0, 40 } do
			local s, co = math.sin(math.rad(phi)), math.cos(math.rad(phi))
			local yb = 0.0 - 0.02 * (phi / 40)
			local base = hv({ 0.24 * s, yb, -0.24 * co })
			local tip = hv({ 0.3 * s, yb - 0.1, -0.3 * co })
			segment(k, "Lash", base, tip, 0.05, LASH, "SmoothPlastic", 0.0)
		end
	end)
end

local function buildEar(k)
	local p = surf(E_CRAN, 0.55, 0.78, 0.4, -0.06)
	k:Group({ Name = "Ear", Pos = hv(p), Rot = { -18, 0, -38 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 16, Speed = 0.45, Phase = 0.1 } }, function()
		hpart(k, { Name = "EarOuter", Shape = "Ellipsoid", Size = { 0.24, 0.36, 0.14 }, Pos = { 0, 0.14, 0 }, Color = FUR })
		hpart(k, { Name = "EarInner", Shape = "Ellipsoid", Size = { 0.14, 0.24, 0.05 }, Pos = { 0, 0.14, -0.06 }, Color = EAR_IN })
	end)
end

local function buildHead(k)
	ell(k, "Cranium", E_CRAN, FUR)
	ell(k, "Face", E_FACE, FUR)
	ell(k, "Muzzle", E_MUZ, MUZZLE)
	hpart(k, { Name = "ThroatLatch", Shape = "Ellipsoid", Size = { 0.62, 0.62, 0.66 }, Pos = { 0, 0.0, 0.08 }, Color = FUR })

	-- forelock tuft between the ears
	for i, t in { { 0, 0.98, -0.12, 0.3 }, { 0.15, 0.95, 0.06, 0.26 }, { -0.15, 0.95, 0.06, 0.26 } } do
		local p = surf(E_CRAN, t[1], t[2], t[3], -0.04)
		hpart(k, { Name = "Forelock", Shape = "Ball", Size = { t[4], t[4], t[4] }, Pos = p, Color = if i == 1 then FUR_DARK else FUR, Material = "Fabric" })
	end

	k:Mirror(function()
		buildEye(k)
		buildEar(k)
		-- slit nostrils on top of the muzzle
		local np, nn = surf(E_MUZ, 0.34, 0.45, -0.82, -0.015)
		hpart(k, { Name = "Nostril", Shape = "Ellipsoid", Size = { 0.17, 0.05, 0.1 }, Pos = np, Rot = faceRot(nn, 28), Color = NOSTRIL })
		-- split upper lip lobes
		hpart(k, { Name = "UpperLip", Shape = "Ellipsoid", Size = { 0.42, 0.34, 0.46 }, Pos = { 0.16, -0.27, -1.42 }, Color = LIP })
	end)

	-- chewing lower jaw: side-to-side grind around a pivot behind the mouth
	local JP = { 0, -0.2, -0.55 }
	k:Group({ Name = "JawChew", Pos = hv(JP), Anim = { Type = "Wiggle", Axis = "Y", Amount = 7, Speed = 1.1 } }, function()
		k:Group({ Name = "JawOpen", Anim = { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 1.1, Phase = 0.25 } }, function()
			k:Group({ Name = "JawOffset", Pos = hv({ -JP[1], -JP[2], -JP[3] }) }, function()
				hpart(k, { Name = "JawUnder", Shape = "Ellipsoid", Size = { 0.6, 0.3, 1.0 }, Pos = { 0, -0.31, -0.98 }, Color = FUR })
				hpart(k, { Name = "LowerLip", Shape = "Ellipsoid", Size = { 0.56, 0.24, 0.44 }, Pos = { 0, -0.51, -1.4 }, Color = LIP })
				hpart(k, { Name = "MouthLine", Shape = "Ellipsoid", Size = { 0.6, 0.05, 0.46 }, Pos = { 0, -0.42, -1.41 }, Color = MOUTH })
				for _, x in { -0.055, 0.055 } do
					hpart(k, { Name = "Tooth", Size = { 0.09, 0.08, 0.05 }, Pos = { x, -0.41, -1.62 }, Color = TEETH })
				end
				hpart(k, { Name = "ChinTuft", Shape = "Ellipsoid", Size = { 0.24, 0.2, 0.22 }, Pos = { 0, -0.58, -1.2 }, Color = FUR_DARK, Material = "Fabric" })
			end)
		end)
	end)

	-- cold breath
	k:Particles({ Pos = hv({ 0, -0.35, -1.75 }), Color = "#eaf8ff", Color2 = "#bfe6ff", Rate = 4, Size = 0.25, Speed = 0.8, Lifetime = 1.6, Spread = 25, Direction = "Front" })
end

--------------------------------------------------------------------------------------------
-- Camel leg in a giant wheat work boot. Written for the right (+X) side; mirrored.
--------------------------------------------------------------------------------------------
local BG = -0.65 -- ground, relative to the ankle
local VAMP_C = { 0, 0.04, -0.28 } -- sloped lacing panel (ellipsoid tilted back 35 degrees)
local VAMP_A = 35

-- point on the front of the vamp: v = position along its long axis, x = sideways
local function vampFront(v, x, out)
	local a = math.rad(VAMP_A)
	local zl = -(0.31 + out) * math.sqrt(math.max(0, 1 - (x / 0.42) ^ 2))
	return { x, VAMP_C[2] + math.cos(a) * v - math.sin(a) * zl, VAMP_C[3] + math.sin(a) * v + math.cos(a) * zl }
end

local function buildBoot(k)
	-- lugged sole with rounded toe + welt
	k:Part({ Name = "Sole", Size = { 0.96, 0.16, 1.05 }, Pos = { 0, BG + 0.08, -0.12 }, Color = SOLE, Material = "Rubber" })
	post(k, "SoleToe", { 0, BG + 0.08, -0.62 }, 0.16, 0.96, SOLE, "Rubber")
	k:Part({ Name = "Welt", Size = { 0.98, 0.08, 1.07 }, Pos = { 0, BG + 0.19, -0.12 }, Color = WELT, Material = "Leather" })
	post(k, "WeltToe", { 0, BG + 0.19, -0.62 }, 0.08, 0.98, WELT, "Leather")
	-- upper: shaft at the back, sloped vamp in front, round toe box + darker toe cap
	post(k, "Shaft", { 0, 0.02, 0.14 }, 1.1, 0.84, BOOT, "Fabric")
	k:Part({ Name = "Vamp", Shape = "Ellipsoid", Size = { 0.84, 1.15, 0.62 }, Pos = VAMP_C, Rot = { VAMP_A, 0, 0 }, Color = BOOT, Material = "Fabric" })
	k:Part({ Name = "ToeBox", Shape = "Ellipsoid", Size = { 0.92, 0.6, 0.9 }, Pos = { 0, BG + 0.4, -0.58 }, Color = BOOT, Material = "Fabric" })
	k:Part({ Name = "ToeCap", Shape = "Ellipsoid", Size = { 0.94, 0.48, 0.56 }, Pos = { 0, BG + 0.35, -0.76 }, Color = BOOT_DARK, Material = "Fabric" })
	k:Part({ Name = "HeelCounter", Shape = "Ellipsoid", Size = { 0.88, 0.56, 0.5 }, Pos = { 0, BG + 0.44, 0.36 }, Color = BOOT_DARK, Material = "Fabric" })
	post(k, "Collar", { 0, 0.62, 0.14 }, 0.22, 0.94, COLLAR, "Leather")
	k:Part({ Name = "PullTab", Size = { 0.14, 0.22, 0.06 }, Pos = { 0, 0.76, 0.62 }, Color = COLLAR, Material = "Leather" })
	-- tongue + criss-cross laces down the sloped front
	local tp = vampFront(0.12, 0, -0.02)
	k:Part({ Name = "Tongue", Size = { 0.32, 1.0, 0.08 }, Pos = tp, Rot = { VAMP_A, 0, 0 }, Color = BOOT, Material = "Fabric" })
	for i = 0, 2 do
		local v = -0.28 + i * 0.25
		for _, sx in { -1, 1 } do
			k:Part({ Name = "Eyelet", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = vampFront(v, sx * 0.18, 0.0), Color = EYELET, Material = "Foil" })
		end
		k:Part({ Name = "Lace", Size = { 0.36, 0.06, 0.06 }, Pos = vampFront(v + 0.03, 0, 0.05), Rot = { VAMP_A, 0, if i % 2 == 0 then 12 else -12 }, Color = LACE })
	end
	-- bow at the top
	for _, sx in { -1, 1 } do
		k:Part({ Name = "BowLoop", Shape = "Ellipsoid", Size = { 0.2, 0.11, 0.06 }, Pos = vampFront(0.5, sx * 0.11, 0.06), Rot = { VAMP_A, 0, sx * 25 }, Color = LACE })
	end
end

local function buildLeg(k)
	local SW, SP = 3, 0.5
	k:Group({ Name = "Leg", Pos = { 0.62, HIP_Y, 0.1 }, Anim = { Type = "Wiggle", Axis = "X", Amount = SW, Speed = SP } }, function()
		k:Part({ Name = "Thigh", Shape = "Ellipsoid", Size = { 0.58, 1.3, 0.64 }, Pos = { 0, -0.45, 0 }, Color = FUR })
		k:Group({ Name = "Knee", Pos = { 0, -1.0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = -SW * 2, Speed = SP } }, function()
			k:Part({ Name = "KneeKnob", Shape = "Ball", Size = { 0.46, 0.46, 0.46 }, Pos = { 0, 0, -0.02 }, Color = FUR })
			k:Part({ Name = "KneeCallus", Shape = "Ellipsoid", Size = { 0.28, 0.26, 0.1 }, Pos = { 0, 0, -0.22 }, Color = CALLUS })
			k:Part({ Name = "Shin", Shape = "Ellipsoid", Size = { 0.34, 1.05, 0.38 }, Pos = { 0, -0.5, 0.02 }, Color = FUR })
			k:Group({ Name = "Ankle", Pos = { 0, -1.35, 0 }, Rot = { 0, -6, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = SW, Speed = SP } }, function()
				buildBoot(k)
			end)
		end)
	end)
end

return {
	Id = "FrigoCamelo",
	Name = "Frigo Camelo",
	Rarity = "Epic",
	Emoji = "🐪",
	Color = FUR,
	Tagline = "Che freddo qui dentro... half camel, all fridge.",
	Lore = "Frigo Camelo wanders the streets of Rome, Paris and Milan in his favourite giant boots, puffing little clouds of frost. Nobody knows why a camel traded its body for a fridge, but his milk is always cold and his snacks never spoil. Please close the door.",

	Build = function(k)
		k:Mirror(function()
			buildLeg(k)
		end)

		-- fridge, neck and head sway together on the hips
		pivot(k, "Body", { 0, HIP_Y, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 1.5, Speed = 0.4 }, function()
			buildCabinet(k)
			buildFreezerDoor(k)
			buildMainDoor(k)
			buildCord(k)
			buildNeckBase(k)

			-- long neck sways side to side and nods
			pivot(k, "NeckSway", NECK0, { Type = "Wiggle", Axis = "Z", Amount = 4, Speed = 0.3 }, function()
				pivot(k, "NeckNod", NECK0, { Type = "Wiggle", Axis = "X", Amount = 3, Speed = 0.42, Phase = 0.2 }, function()
					buildNeck(k)
					-- head held proudly, snout slightly raised
					k:Group({ Name = "HeadLook", Pos = J, Rot = { 6, 0, 0 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 7, Speed = 0.2 } }, function()
						k:Group({ Name = "Head", Anim = { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 0.5, Phase = 0.4 } }, function()
							buildHead(k)
						end)
					end)
				end)
			end)

			k:Light({ Pos = { -0.3, 4.3, -0.5 }, Color = GLOW, Range = 7, Brightness = 1.5 })
			k:Light({ Pos = { 0, 7.2, -1.6 }, Color = "#bfefff", Range = 9, Brightness = 0.8 })
			k:Particles({ Pos = { -1.05, 4.0, -1.15 }, Color = "#dff6ff", Color2 = "#9fdcff", Rate = 5, Size = 0.4, Speed = 0.5, Lifetime = 2, Spread = 30, Direction = "Bottom" })
			k:Particles({ Pos = { 0, FT + 0.2, 0 }, Color = "#ffffff", Color2 = GLOW, Rate = 3, Size = 0.15, Speed = 0.6, Lifetime = 2.5, Spread = 80, Direction = "Top" })
		end)
	end,

	BuildMini = function(k)
		-- fridge body with freezer seam and handle
		k:Part({ Name = "Fridge", Size = { 1.1, 1.25, 0.95 }, Pos = { 0, -0.14, 0.12 }, Color = FRIDGE })
		k:Part({ Name = "Seam", Size = { 1.12, 0.06, 0.97 }, Pos = { 0, 0.16, 0.12 }, Color = SEAM })
		k:Part({ Name = "Handle", Size = { 0.09, 0.36, 0.1 }, Pos = { -0.4, -0.08, -0.38 }, Color = CHROME, Material = "Metal" })
		-- long neck + camel head with droopy lips
		k:Part({ Name = "Neck", Shape = "Ellipsoid", Size = { 0.36, 0.85, 0.38 }, Pos = { 0, 0.72, -0.08 }, Rot = { -18, 0, 0 }, Color = FUR })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.52, 0.46, 0.92 }, Pos = { 0, 1.07, -0.45 }, Color = FUR })
		k:Part({ Name = "Lips", Shape = "Ellipsoid", Size = { 0.4, 0.3, 0.36 }, Pos = { 0, 0.96, -0.86 }, Color = LIP })
		-- one dark rod through the head: only its end caps show, as both eyes
		k:Part({ Name = "Eyes", Shape = "Cylinder", Size = { 0.5, 0.15, 0.15 }, Pos = { 0, 1.14, -0.55 }, Color = PUPIL })
		-- dromedary hump behind the neck
		k:Part({ Name = "Hump", Shape = "Ellipsoid", Size = { 0.6, 0.42, 0.55 }, Pos = { 0, 0.5, 0.3 }, Color = FUR })
		k:Mirror(function()
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.38, 0.17, 0.17 }, Pos = { 0.28, -0.92, 0.12 }, Rot = { 0, 0, 90 }, Color = FUR })
			k:Part({ Name = "Boot", Shape = "Ellipsoid", Size = { 0.38, 0.34, 0.6 }, Pos = { 0.28, -1.18, 0.0 }, Color = BOOT })
		end)
	end,
}
