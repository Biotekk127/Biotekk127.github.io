--[[
	Frigo Camelo (Epic)
	Canonical look ("Frigo Camello Buffo Fardello", @ofuscabreno, Feb 2025; the Steal a
	Brainrot model): a camel whose body is an upright white refrigerator. The camel's LONG
	tan neck and head rise out of the top of the fridge (heavy droopy eyelids, long lashes,
	big floppy split lips, small round ears), and two camel legs stomp around underneath in
	giant wheat-coloured work boots. Cold vapour drifts from its mouth ("Che freddo qui
	dentro..."). Proud but exhausted.

	Fridge: freezer door on top, main door below (ajar, glowing cool blue, food inside),
	chrome handles + hinges, badge plate, frost, snow and icicles (Epic flair), condenser
	coil and a power-cord "tail" on the back.

	Coordinates: feet on y = 0, faces -Z. Parts that animate are written in world
	coordinates inside "pivot" groups (joint group + inverse offset), except the head, eyes
	and limbs which are written in their own local frames.
]]

-- Palette ------------------------------------------------------------------------------
local FRIDGE = "#f4f1e8" -- dominant: warm white enamel
local DOOR = "#fbf8f0"
local SEAM = "#6f6d6a"
local GASKET = "#8e939b"
local CHROME = "#e2e7ee"
local CHROME_DARK = "#98a1ad"
local LINER = "#d4efff" -- fridge interior
local GLOW = "#8fe0ff" -- cool interior light (Neon accent)
local ICE = "#c4ecff"
local FROST = "#f4fbff"
local DARK = "#2a2b33"
local COIL = "#34353d"

local FUR = "#c4935f" -- secondary: sandy camel tan
local FUR_DARK = "#8f6239"
local FUR_LIGHT = "#e0c193"
local FUR_MID = "#ad7c4b"
local MUZZLE = "#dcc39d"
local LIP = "#bf9468"
local MOUTH = "#3a2321"
local TEETH = "#f3e6c2"
local NOSTRIL = "#4a3022"
local EAR_IN = "#d9a58a"
local EYE_WHITE = "#fff8ec"
local IRIS = "#6b3d1f"
local PUPIL = "#1b1b24"
local SHINE = "#ffffff"
local LID = "#a9784a"
local LASH = "#2b1d17"
local CALLUS = "#7d5f49"

local BOOT = "#e3a43a" -- accent: golden wheat nubuck work boots
local BOOT_DARK = "#c2832a"
local COLLAR = "#4e3222"
local SOLE = "#3c2a20"
local WELT = "#9a6a35"
local LACE = "#7d5130"
local EYELET = "#d8b25a"

local RED = "#e8463e"
local YELLOW = "#ffd23a"
local BLUE = "#3f8cff"
local PAPER = "#fff8ec"

-- Layout (world studs) ------------------------------------------------------------------
local FX = 1.3 -- fridge half width
local FZ0 = -0.95 -- cabinet front plane (doors sit in front of it)
local FZ1 = 1.0 -- cabinet back plane
local FB = 2.75 -- fridge bottom
local FT = 6.35 -- fridge top (cabinet); a rounded top cap sits on it
local R = 0.25 -- rounded vertical corner radius
local FH = FT - FB
local FY = (FB + FT) / 2
local DT = 0.26 -- door thickness
local CAP = 0.14 -- top cap thickness
local CAV_B, CAV_T, CAV_Z = FB + 0.35, FB + 2.28, -0.05 -- main compartment cavity
local MAIN_B, MAIN_T = FB + 0.27, FB + 2.31 -- main door
local FRZ_B, FRZ_T = FB + 2.39, FT - 0.03 -- freezer door
local SEAM_Y = (MAIN_T + FRZ_B) / 2

local HIP_Y = 2.9
local NECK0 = { 0, FT + CAP, -0.26 } -- neck base on top of the fridge
local J = { 0, 8.15, -0.92 } -- head joint
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
		-- rubber seals where the camel legs come out of the bottom
		post(k, "HipSeal", { 0.62, FB - 0.03, 0.1 }, 0.07, 0.74, GASKET, "Rubber")
	end)
	-- back half (solid), freezer block and plinth in front of it, cavity between
	k:Part({ Name = "CabinetBack", Size = { 2 * (FX - R), FH, FZ1 - CAV_Z }, Pos = { 0, FY, (FZ1 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "FreezerBlock", Size = { 2 * (FX - R), FT - CAV_T, CAV_Z - FZ0 }, Pos = { 0, (FT + CAV_T) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "Plinth", Size = { 2 * (FX - R), CAV_B - FB, CAV_Z - FZ0 }, Pos = { 0, (FB + CAV_B) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })

	-- rounded top cap (bullnose front edge flush with the door fronts)
	local capZ0 = FZ0 - DT
	k:Part({ Name = "TopCap", Size = { 2 * FX - 0.04, CAP, FZ1 - 0.05 - (capZ0 + CAP / 2) }, Pos = { 0, FT + CAP / 2, (FZ1 - 0.05 + capZ0 + CAP / 2) / 2 }, Color = FRIDGE })
	k:Part({ Name = "TopCapNose", Shape = "Cylinder", Size = { 2 * FX - 0.04, CAP, CAP }, Pos = { 0, FT + CAP / 2, capZ0 + CAP / 2 }, Color = FRIDGE })

	-- interior (seen through the ajar door; the door hinges on +X so the gap is at -X)
	local cavH = CAV_T - CAV_B
	local cavY = (CAV_B + CAV_T) / 2
	k:Part({ Name = "LinerBack", Size = { 1.7, cavH, 0.05 }, Pos = { 0, cavY, CAV_Z - 0.025 }, Color = LINER })
	k:Part({ Name = "LinerSide", Size = { 0.26, cavH, 0.55 }, Pos = { -0.93, cavY, -0.33 }, Color = LINER })
	k:Part({ Name = "FridgeLamp", Size = { 1.3, 0.06, 0.14 }, Pos = { 0, CAV_T - 0.04, -0.45 }, Color = GLOW, Material = "Neon" })
	k:Part({ Name = "GlowStrip", Size = { 0.05, cavH - 0.2, 0.08 }, Pos = { -0.79, cavY, -0.5 }, Color = GLOW, Material = "Neon" })
	local S1, S2 = CAV_B + 0.66, CAV_B + 1.32
	for _, y in { S1, S2 } do
		k:Part({ Name = "GlassShelf", Size = { 1.62, 0.06, 0.62 }, Pos = { 0, y, -0.37 }, Color = "#d6f2ff", Material = "Glass", Transparency = 0.3 })
	end
	-- food
	k:Part({ Name = "MilkCarton", Size = { 0.3, 0.5, 0.3 }, Pos = { -0.5, CAV_B + 0.25, -0.35 }, Color = "#fbfbf6" })
	k:Part({ Name = "MilkBand", Size = { 0.32, 0.12, 0.32 }, Pos = { -0.5, CAV_B + 0.36, -0.35 }, Color = BLUE })
	k:Part({ Name = "Cheese", Shape = "Wedge", Size = { 0.42, 0.24, 0.34 }, Pos = { -0.48, S1 + 0.15, -0.35 }, Rot = { 0, 180, 0 }, Color = "#ffcf4a" })
	k:Part({ Name = "Apple", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = { -0.05, S1 + 0.16, -0.4 }, Color = RED })
	post(k, "Bottle", { -0.52, S2 + 0.28, -0.38 }, 0.5, 0.18, "#3fae6a", "Glass")
	post(k, "Jar", { -0.14, S2 + 0.16, -0.38 }, 0.26, 0.26, "#ff9a3c")

	-- seam between freezer and main compartment
	k:Part({ Name = "DoorSeam", Size = { 2.5, 0.07, 0.08 }, Pos = { 0, SEAM_Y, FZ0 - 0.03 }, Color = SEAM })

	-- kick-plate vent grille under the main door
	k:Part({ Name = "Grille", Size = { 1.9, 0.2, 0.05 }, Pos = { 0, FB + 0.13, FZ0 - 0.02 }, Color = DARK })
	for i = 0, 2 do
		k:Part({ Name = "GrilleSlat", Size = { 0.5, 0.05, 0.05 }, Pos = { 0, FB + 0.07 + i * 0.06, FZ0 - 0.045 }, Color = CHROME_DARK, Material = "Metal" })
	end

	-- barrel hinges on the right (+X) edge
	for _, y in { FRZ_T + 0.02, SEAM_Y, MAIN_B - 0.02 } do
		post(k, "Hinge", { FX - 0.02, y, FZ0 - 0.07 }, 0.24, 0.16, CHROME, "Metal", { Reflectance = 0.2 })
	end

	-- frost overflowing the front edge: an ice rim with icicles hanging from it
	local iz = capZ0 + 0.06
	k:Part({ Name = "IceRim", Shape = "Ellipsoid", Size = { 2.4, 0.12, 0.16 }, Pos = { 0, FT - 0.02, iz }, Color = ICE, Material = "Ice", Transparency = 0.15, Reflectance = 0.15 })
	local icicles = { { -0.98, 0.3 }, { -0.52, 0.46 }, { -0.05, 0.24 }, { 0.42, 0.52 }, { 0.9, 0.34 } }
	for _, ic in icicles do
		local x, len = ic[1], ic[2]
		k:Part({ Name = "IcicleRoot", Shape = "Ellipsoid", Size = { 0.15, 0.2, 0.12 }, Pos = { x, FT - 0.12, iz }, Color = ICE, Material = "Ice", Transparency = 0.1, Reflectance = 0.15 })
		k:Part({ Name = "Icicle", Shape = "Ellipsoid", Size = { 0.08, len, 0.08 }, Pos = { x, FT - 0.16 - len / 2 + 0.03, iz }, Color = ICE, Material = "Ice", Transparency = 0.1, Reflectance = 0.15 })
	end
	-- snow drifts on the top corners
	k:Part({ Name = "SnowDrift", Shape = "Ellipsoid", Size = { 0.8, 0.22, 0.62 }, Pos = { -0.82, FT + CAP + 0.02, capZ0 + 0.42 }, Rot = { 0, 15, 0 }, Color = FROST, Material = "Snow" })
	k:Part({ Name = "SnowDrift", Shape = "Ellipsoid", Size = { 0.62, 0.18, 0.5 }, Pos = { 0.88, FT + CAP + 0.01, 0.62 }, Rot = { 0, -20, 0 }, Color = FROST, Material = "Snow" })

	-- energy sticker on the right side
	k:Part({ Name = "EnergySticker", Size = { 0.05, 0.34, 0.5 }, Pos = { FX + 0.01, FB + 0.75, 0.45 }, Color = CHROME, Material = "Metal", Text = { Text = "A+++", Color = "#2f9e5a", Face = "Right" } })

	-- back: serpentine condenser coil (horizontal tubes, end headers, thin vertical wires)
	local cy0, cy1 = FB + 0.85, FT - 0.55
	for i = 0, 3 do
		local y = cy0 + (cy1 - cy0) * i / 3
		k:Part({ Name = "CoilTube", Shape = "Cylinder", Size = { 1.76, 0.09, 0.09 }, Pos = { 0, y, FZ1 + 0.05 }, Color = COIL, Material = "Metal" })
	end
	for _, x in { -0.88, 0.88 } do
		post(k, "CoilHeader", { x, (cy0 + cy1) / 2, FZ1 + 0.05 }, cy1 - cy0 + 0.09, 0.11, COIL, "Metal")
	end
	for _, x in { -0.45, 0, 0.45 } do
		post(k, "CoilWire", { x, (cy0 + cy1) / 2, FZ1 + 0.11 }, cy1 - cy0 + 0.3, 0.05, COIL, "Metal")
	end
	k:Part({ Name = "Compressor", Shape = "Ellipsoid", Size = { 0.7, 0.42, 0.34 }, Pos = { 0.35, FB + 0.38, FZ1 + 0.06 }, Color = DARK, Material = "Metal" })
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
		handle(k, -h / 2 + 0.38, 0.5)
		local fz = -DT - 0.02
		-- badge plate (generic, not a brand)
		k:Part({ Name = "Badge", Size = { 0.72, 0.2, 0.05 }, Pos = { -FX, 0.24, fz }, Color = CHROME, Material = "Metal", Reflectance = 0.25, Text = { Text = "FRIGO", Color = "#2d5f8a", Face = "Front" } })
		-- digital thermometer
		k:Part({ Name = "TempDisplay", Size = { 0.46, 0.2, 0.05 }, Pos = { -FX, -0.14, fz }, Color = DARK, Text = { Text = "-18°", Color = GLOW, Face = "Front" } })
		k:Part({ Name = "PowerLed", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { -FX - 0.33, -0.14, fz }, Color = GLOW, Material = "Neon", Anim = { Type = "Pulse", Amount = 0.35, Speed = 0.7 } })
		-- neon snowflake emblem
		for i = 0, 2 do
			k:Part({ Name = "Snowflake", Size = { 0.44, 0.06, 0.05 }, Pos = { -0.55, 0.02, fz - 0.005 }, Rot = { 0, 0, i * 60 }, Color = GLOW, Material = "Neon", Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.5, Phase = 0.3 } })
		end
		-- frosted-over corner (Epic ice flair)
		k:Part({ Name = "FrostPatch", Shape = "Ellipsoid", Size = { 0.8, 0.5, 0.05 }, Pos = { -(2 * FX - 0.42), h / 2 - 0.2, fz + 0.005 }, Color = "#e8f8ff", Material = "Ice", Transparency = 0.2, Reflectance = 0.1 })
	end)
end

local function buildMainDoor(k)
	local h = MAIN_T - MAIN_B
	-- hinge pivot at the back corner of the door; the door hangs open
	k:Group({ Name = "MainDoorHinge", Pos = { FX, (MAIN_B + MAIN_T) / 2, FZ0 }, Rot = { 0, -17, 0 } }, function()
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
	local base = { -0.5, FB + 0.45, FZ1 + 0.05 }
	k:Group({ Name = "PowerCord", Pos = base, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.45, Phase = 0.6 } }, function()
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
-- Neck (long, smooth, tapering capsule chain), hump
--------------------------------------------------------------------------------------------
local NECK = { NECK0, { 0, FT + 0.7, -0.33 }, { 0, FT + 1.2, -0.5 }, { 0, FT + 1.58, -0.72 }, J }
local NECK_D = { 0.84, 0.74, 0.66, 0.6 }

local function buildNeck(k)
	for i = 1, #NECK - 1 do
		local a, b = NECK[i], NECK[i + 1]
		segment(k, "Neck", a, b, NECK_D[i], FUR, "SmoothPlastic", 0)
		if i > 1 then
			k:Part({ Name = "NeckJoint", Shape = "Ball", Size = { NECK_D[i], NECK_D[i], NECK_D[i] }, Pos = a, Color = FUR })
		end
	end
	-- dark mane ridge down the back of the neck (overlapping, flush with the neck)
	for i = 1, 4 do
		local a, b = NECK[i], NECK[i + 1]
		local dy, dz = b[2] - a[2], b[3] - a[3]
		local len = math.sqrt(dy * dy + dz * dz)
		k:Part({ Name = "Mane", Shape = "Ellipsoid", Size = { 0.26, len + 0.2, 0.26 }, Pos = { 0, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 + NECK_D[i] * 0.4 }, Rot = { deg(math.atan2(dz, dy)), 0, 0 }, Color = FUR_DARK, Material = "Fabric" })
	end
	-- shaggy throat beard on the front of the lower neck
	for i, t in { { 0.25, 0.42, 0.5 }, { 0.62, 0.36, 0.44 } } do
		local a, b = NECK[i], NECK[i + 1]
		local y = a[2] + (b[2] - a[2]) * 0.5
		local z = a[3] + (b[3] - a[3]) * 0.5 - NECK_D[i] * 0.4
		k:Part({ Name = "ThroatFur", Shape = "Ellipsoid", Size = { t[2], t[3], 0.28 }, Pos = { 0, y - t[1] * 0.3, z }, Rot = { 12, 0, 0 }, Color = FUR_MID, Material = "Fabric" })
	end
end

local function buildNeckBase(k)
	-- rubber gasket collar where the neck pokes through the fridge top
	post(k, "NeckGasket", { NECK0[1], FT + CAP + 0.03, NECK0[3] }, 0.06, 1.14, GASKET, "Rubber")
	post(k, "NeckSeal", { NECK0[1], FT + CAP + 0.1, NECK0[3] }, 0.12, 0.96, GASKET, "Rubber")
	-- small dromedary hump behind the neck
	k:Part({ Name = "Hump", Shape = "Ellipsoid", Size = { 1.1, 0.8, 1.0 }, Pos = { 0, FT + CAP + 0.02, 0.48 }, Color = FUR })
	k:Part({ Name = "HumpTuft", Shape = "Ellipsoid", Size = { 0.58, 0.22, 0.58 }, Pos = { 0, FT + CAP + 0.36, 0.52 }, Color = FUR_DARK, Material = "Fabric" })
end

--------------------------------------------------------------------------------------------
-- Head (local to the head joint; authored unscaled, scaled by HS)
--------------------------------------------------------------------------------------------
local E_CRAN = { 0, 0.3, 0.05, 0.47, 0.43, 0.52 }
local E_FACE = { 0, 0.17, -0.58, 0.35, 0.34, 0.66 }
local E_MUZ = { 0, -0.06, -1.18, 0.34, 0.33, 0.42 }

local function ell(k, name, E, color, material)
	hpart(k, { Name = name, Shape = "Ellipsoid", Size = { E[4] * 2, E[5] * 2, E[6] * 2 }, Pos = { E[1], E[2], E[3] }, Color = color, Material = material })
end

local function buildEye(k)
	local ER = 0.23
	local c, n = surf(E_CRAN, 0.62, 0.25, -0.75, -0.07)
	k:Group({ Name = "Eye", Pos = hv(c), Rot = faceRot(n) }, function()
		local BLINK = { Type = "Blink", Speed = 0.22, Phase = 0.35 }
		local function onEye(yaw, pitch, depth)
			local r = ER + depth
			return { math.sin(math.rad(yaw)) * math.cos(math.rad(pitch)) * r, math.sin(math.rad(pitch)) * r, -math.cos(math.rad(yaw)) * math.cos(math.rad(pitch)) * r }
		end
		hpart(k, { Name = "Eyeball", Shape = "Ball", Size = { ER * 2, ER * 2, ER * 2 }, Color = EYE_WHITE, Anim = BLINK })
		hpart(k, { Name = "Iris", Shape = "Ellipsoid", Size = { 0.3, 0.32, 0.08 }, Pos = onEye(-24, -8, -0.025), Rot = { -8, 24, 0 }, Color = IRIS, Anim = BLINK })
		hpart(k, { Name = "Pupil", Shape = "Ellipsoid", Size = { 0.17, 0.19, 0.06 }, Pos = onEye(-24, -8, 0.0), Rot = { -8, 24, 0 }, Color = PUPIL, Anim = BLINK })
		hpart(k, { Name = "EyeShine", Shape = "Ball", Size = { 0.075, 0.075, 0.075 }, Pos = onEye(-34, -3, 0.02), Color = SHINE, Material = "Neon", Anim = BLINK })
		hpart(k, { Name = "EyeShine2", Shape = "Ball", Size = { 0.045, 0.045, 0.045 }, Pos = onEye(-14, -16, 0.02), Color = SHINE, Material = "Neon", Anim = BLINK })
		-- heavy, droopy upper lid (half closed: proud but tired)
		hpart(k, { Name = "UpperLid", Shape = "Ellipsoid", Size = { ER * 2 + 0.06, 0.32, ER * 2 + 0.05 }, Pos = { 0, 0.13, 0.0 }, Rot = { 0, 0, -12 }, Color = LID })
		hpart(k, { Name = "LowerLid", Shape = "Ellipsoid", Size = { ER * 2 + 0.02, 0.1, ER * 2 - 0.04 }, Pos = { 0, -0.2, 0.0 }, Color = FUR_LIGHT })
		hpart(k, { Name = "Brow", Shape = "Ellipsoid", Size = { 0.52, 0.1, 0.22 }, Pos = { 0.02, 0.36, 0.03 }, Rot = { 0, 0, -16 }, Color = FUR_DARK, Material = "Fabric" })
		-- long lashes hanging from the outer half of the lid rim, curling down and out
		for _, phi in { 8, 34, 60 } do
			local s, co = math.sin(math.rad(phi)), math.cos(math.rad(phi))
			local r = ER + 0.035
			local yb = -0.02 - 0.05 * s
			local base = hv({ r * s, yb, -r * co })
			local tip = hv({ r * s + 0.03 + 0.07 * s, yb - 0.1 + 0.03 * s, -r * co - 0.05 * co })
			segment(k, "Lash", base, tip, 0.05, LASH, "SmoothPlastic", 0.0)
		end
	end)
end

local function buildEar(k)
	local p = surf(E_CRAN, 0.55, 0.78, 0.4, -0.06)
	k:Group({ Name = "Ear", Pos = hv(p), Rot = { -18, 0, -38 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 16, Speed = 0.45, Phase = 0.1 } }, function()
		hpart(k, { Name = "EarOuter", Shape = "Ellipsoid", Size = { 0.26, 0.36, 0.14 }, Pos = { 0, 0.14, 0 }, Color = FUR })
		hpart(k, { Name = "EarInner", Shape = "Ellipsoid", Size = { 0.15, 0.24, 0.05 }, Pos = { 0, 0.14, -0.06 }, Color = EAR_IN })
	end)
end

local function buildHead(k)
	ell(k, "Cranium", E_CRAN, FUR)
	ell(k, "Face", E_FACE, FUR)
	ell(k, "Muzzle", E_MUZ, MUZZLE)
	-- roman-nose bridge: the camel's long arched snout line
	hpart(k, { Name = "NoseBridge", Shape = "Ellipsoid", Size = { 0.38, 0.22, 0.86 }, Pos = { 0, 0.36, -0.86 }, Color = FUR_MID })
	hpart(k, { Name = "ThroatLatch", Shape = "Ellipsoid", Size = { 0.62, 0.62, 0.66 }, Pos = { 0, 0.0, 0.08 }, Color = FUR })

	-- woolly topknot between the ears
	hpart(k, { Name = "Topknot", Shape = "Ellipsoid", Size = { 0.44, 0.24, 0.42 }, Pos = surf(E_CRAN, 0, 1, 0.12, -0.06), Color = FUR_DARK, Material = "Fabric" })
	for _, t in { { 0.13, 0.95, -0.2, 0.22 }, { -0.12, 0.96, -0.24, 0.2 } } do
		local p = surf(E_CRAN, t[1], t[2], t[3], -0.04)
		hpart(k, { Name = "Forelock", Shape = "Ball", Size = { t[4], t[4], t[4] }, Pos = p, Color = FUR_DARK, Material = "Fabric" })
	end

	k:Mirror(function()
		buildEye(k)
		buildEar(k)
		-- slit nostrils on top of the muzzle
		local np, nn = surf(E_MUZ, 0.34, 0.45, -0.82, -0.015)
		hpart(k, { Name = "Nostril", Shape = "Ellipsoid", Size = { 0.17, 0.05, 0.1 }, Pos = np, Rot = faceRot(nn, 28), Color = NOSTRIL })
		-- split, floppy upper lip lobes with buck teeth peeking out under them
		hpart(k, { Name = "UpperLip", Shape = "Ellipsoid", Size = { 0.42, 0.34, 0.46 }, Pos = { 0.16, -0.27, -1.4 }, Color = LIP })
		hpart(k, { Name = "Tooth", Size = { 0.1, 0.12, 0.05 }, Pos = { 0.058, -0.42, -1.57 }, Color = TEETH })
	end)

	-- chewing lower jaw: side-to-side grind around a pivot behind the mouth
	local JP = { 0, -0.2, -0.55 }
	k:Group({ Name = "JawChew", Pos = hv(JP), Anim = { Type = "Wiggle", Axis = "Y", Amount = 7, Speed = 1.1 } }, function()
		k:Group({ Name = "JawOpen", Anim = { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 1.1, Phase = 0.25 } }, function()
			k:Group({ Name = "JawOffset", Pos = hv({ -JP[1], -JP[2], -JP[3] }) }, function()
				hpart(k, { Name = "JawUnder", Shape = "Ellipsoid", Size = { 0.56, 0.3, 1.0 }, Pos = { 0, -0.31, -0.98 }, Color = FUR })
				hpart(k, { Name = "LowerLip", Shape = "Ellipsoid", Size = { 0.54, 0.24, 0.44 }, Pos = { 0, -0.52, -1.38 }, Color = LIP })
				hpart(k, { Name = "MouthLine", Shape = "Ellipsoid", Size = { 0.58, 0.05, 0.44 }, Pos = { 0, -0.43, -1.4 }, Color = MOUTH })
				hpart(k, { Name = "ChinTuft", Shape = "Ellipsoid", Size = { 0.24, 0.2, 0.22 }, Pos = { 0, -0.6, -1.18 }, Color = FUR_DARK, Material = "Fabric" })
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
	-- chunky lug sole with rounded toe + stitched welt
	k:Part({ Name = "Sole", Size = { 0.98, 0.2, 1.05 }, Pos = { 0, BG + 0.1, -0.12 }, Color = SOLE, Material = "Rubber" })
	post(k, "SoleToe", { 0, BG + 0.1, -0.64 }, 0.2, 0.98, SOLE, "Rubber")
	k:Part({ Name = "Welt", Size = { 1.0, 0.07, 1.07 }, Pos = { 0, BG + 0.235, -0.12 }, Color = WELT, Material = "Leather" })
	post(k, "WeltToe", { 0, BG + 0.235, -0.64 }, 0.07, 1.0, WELT, "Leather")
	-- upper: shaft at the back, sloped vamp in front, round toe box + darker toe cap
	post(k, "Shaft", { 0, 0.0, 0.14 }, 1.08, 0.82, BOOT, "Fabric")
	k:Part({ Name = "Vamp", Shape = "Ellipsoid", Size = { 0.84, 1.15, 0.62 }, Pos = VAMP_C, Rot = { VAMP_A, 0, 0 }, Color = BOOT, Material = "Fabric" })
	k:Part({ Name = "ToeBox", Shape = "Ellipsoid", Size = { 0.92, 0.6, 0.9 }, Pos = { 0, BG + 0.44, -0.58 }, Color = BOOT, Material = "Fabric" })
	k:Part({ Name = "ToeCap", Shape = "Ellipsoid", Size = { 0.94, 0.48, 0.56 }, Pos = { 0, BG + 0.39, -0.78 }, Color = BOOT_DARK, Material = "Fabric" })
	k:Part({ Name = "HeelCounter", Shape = "Ellipsoid", Size = { 0.88, 0.56, 0.5 }, Pos = { 0, BG + 0.48, 0.36 }, Color = BOOT_DARK, Material = "Fabric" })
	-- puffy padded leather collar, fur spilling out of it, small pull tab
	k:Part({ Name = "Collar", Shape = "Ellipsoid", Size = { 0.98, 0.3, 0.94 }, Pos = { 0, 0.55, 0.12 }, Color = COLLAR, Material = "Leather" })
	k:Part({ Name = "FurCuff", Shape = "Ellipsoid", Size = { 0.58, 0.26, 0.58 }, Pos = { 0, 0.72, 0.1 }, Color = FUR_DARK, Material = "Fabric" })
	k:Part({ Name = "PullTab", Size = { 0.14, 0.16, 0.06 }, Pos = { 0, 0.66, 0.6 }, Color = COLLAR, Material = "Leather" })
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
		k:Part({ Name = "Thigh", Shape = "Ellipsoid", Size = { 0.6, 1.3, 0.66 }, Pos = { 0, -0.42, 0 }, Color = FUR })
		k:Group({ Name = "Knee", Pos = { 0, -0.95, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = -SW * 2, Speed = SP } }, function()
			k:Part({ Name = "KneeKnob", Shape = "Ball", Size = { 0.46, 0.46, 0.46 }, Pos = { 0, 0, -0.02 }, Color = FUR })
			k:Part({ Name = "KneeCallus", Shape = "Ellipsoid", Size = { 0.32, 0.3, 0.2 }, Pos = { 0, -0.01, -0.15 }, Color = CALLUS, Material = "Fabric" })
			k:Part({ Name = "Shin", Shape = "Ellipsoid", Size = { 0.34, 1.05, 0.38 }, Pos = { 0, -0.5, 0.02 }, Color = FUR })
			k:Group({ Name = "Ankle", Pos = { 0, -1.3, 0 }, Rot = { 0, -6, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = SW, Speed = SP } }, function()
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

			k:Light({ Pos = { -0.3, CAV_B + 1.1, -0.6 }, Color = GLOW, Range = 7, Brightness = 1.6 })
			k:Light({ Pos = { 0, FT + 0.8, -1.6 }, Color = "#bfefff", Range = 9, Brightness = 0.8 })
			k:Particles({ Pos = { -1.15, CAV_B + 0.9, -1.25 }, Color = "#dff6ff", Color2 = "#9fdcff", Rate = 5, Size = 0.4, Speed = 0.5, Lifetime = 2, Spread = 30, Direction = "Bottom" })
			k:Particles({ Pos = { 0, FT + 0.25, -0.2 }, Color = "#ffffff", Color2 = GLOW, Rate = 3, Size = 0.15, Speed = 0.6, Lifetime = 2.5, Spread = 80, Direction = "Top" })
		end)
	end,

	BuildMini = function(k)
		-- white fridge body with freezer seam and handle
		k:Part({ Name = "Fridge", Size = { 1.1, 1.25, 0.95 }, Pos = { 0, -0.14, 0.12 }, Color = FRIDGE })
		k:Part({ Name = "Seam", Size = { 1.12, 0.06, 0.97 }, Pos = { 0, 0.16, 0.12 }, Color = SEAM })
		k:Part({ Name = "Handle", Size = { 0.09, 0.36, 0.1 }, Pos = { -0.4, -0.08, -0.38 }, Color = CHROME, Material = "Metal" })
		-- long neck + camel head with droopy lips
		k:Part({ Name = "Neck", Shape = "Ellipsoid", Size = { 0.34, 0.9, 0.36 }, Pos = { 0, 0.72, -0.08 }, Rot = { -18, 0, 0 }, Color = FUR })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.5, 0.46, 0.92 }, Pos = { 0, 1.07, -0.45 }, Color = FUR })
		k:Part({ Name = "Lips", Shape = "Ellipsoid", Size = { 0.4, 0.3, 0.36 }, Pos = { 0, 0.96, -0.86 }, Color = LIP })
		-- one dark rod through the head: its end caps bulge out as both eyes
		k:Part({ Name = "Eyes", Shape = "Cylinder", Size = { 0.6, 0.16, 0.16 }, Pos = { 0, 1.15, -0.5 }, Color = PUPIL })
		-- dromedary hump behind the neck
		k:Part({ Name = "Hump", Shape = "Ellipsoid", Size = { 0.6, 0.42, 0.55 }, Pos = { 0, 0.5, 0.3 }, Color = FUR })
		k:Mirror(function()
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.4, 0.17, 0.17 }, Pos = { 0.28, -0.92, 0.12 }, Rot = { 0, 0, 90 }, Color = FUR })
			k:Part({ Name = "Boot", Shape = "Ellipsoid", Size = { 0.4, 0.36, 0.62 }, Pos = { 0.28, -1.17, 0.0 }, Color = BOOT })
		end)
	end,
}
