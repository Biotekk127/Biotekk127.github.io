--[[
	Frigo Camelo (Epic)
	Canonical look ("Frigo Camello Buffo Fardello", @ofuscabreno, Feb 2025; the Steal a
	Brainrot model): a camel whose body is an upright white refrigerator. The camel's LONG
	tan neck and head rise out of the top of the fridge (heavy droopy eyelids, long lashes,
	big floppy split lips, small round ears), and two camel legs stomp around underneath in
	giant wheat-coloured work boots. Cold vapour drifts from its mouth ("Che freddo qui
	dentro..."). Proud but exhausted.

	Fridge: tall retro top-freezer fridge with a rounded crown, freezer door on top, main
	door below (ajar, glowing cool blue, food inside), chrome handles + hinges, badge plate,
	frost, snow and icicles (Epic flair), meltwater drips, condenser coil and a power-cord
	"tail" on the back.

	Coordinates: feet on y = 0, faces -Z. Parts that animate are written in world
	coordinates inside "pivot" groups (joint group + inverse offset), except the head, eyes
	and limbs which are written in their own local frames.
]]

-- Palette ------------------------------------------------------------------------------
local FRIDGE = "#f3f1ea" -- dominant: warm white enamel
local DOOR = "#fcfaf3"
local SEAM = "#5f5d5b"
local GASKET = "#8e939b"
local CHROME = "#e2e7ee"
local CHROME_DARK = "#98a1ad"
local LINER = "#d4efff" -- fridge interior
local GLOW = "#8fe0ff" -- cool interior light (Neon accent)
local ICE = "#b4e3ff"
local FROST = "#f4fbff"
local DARK = "#2a2b33"
local GRILLE = "#4a4d57"
local COIL = "#454852"
local WATER = "#9fd8ff"

local FUR = "#c4935f" -- secondary: sandy camel tan
local FUR_DARK = "#8f6239"
local FUR_LIGHT = "#e0c193"
local FUR_MID = "#b58352"
local MUZZLE = "#d9bb92"
local LIP = "#b98a5e"
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
local FX = 1.25 -- fridge half width
local FZ0 = -0.95 -- cabinet front plane (doors sit in front of it)
local FZ1 = 1.0 -- cabinet back plane
local FB = 2.5 -- fridge bottom
local FT = 6.55 -- very top of the rounded crown
local R = 0.25 -- corner / crown radius
local BODY_T = FT - R -- top of the straight walls; the crown rounds off above it
local FH = BODY_T - FB
local FY = (FB + BODY_T) / 2
local DT = 0.26 -- door thickness
local DZ = FZ0 - DT -- door front plane
local CAV_B, CAV_T, CAV_Z = FB + 0.35, FB + 2.55, -0.05 -- main compartment cavity
local MAIN_B, MAIN_T = FB + 0.27, FB + 2.6 -- main door
local FRZ_B, FRZ_T = MAIN_T + 0.08, BODY_T - 0.01 -- freezer door
local SEAM_Y = (MAIN_T + FRZ_B) / 2

local HIP_Y = FB + 0.15
local NECK0 = { 0, FT - 0.05, -0.2 } -- neck base, just inside the crown
local J = { 0, 8.2, -0.95 } -- head joint
local HS = 1.15 -- head scale
local BS = 1.06 -- boot scale

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

-- Scaled-space helpers (head parts scaled by HS, boot parts by BS)
local function scaled(s)
	return function(k, spec)
		spec.Size = { spec.Size[1] * s, spec.Size[2] * s, spec.Size[3] * s }
		if spec.Pos then
			spec.Pos = { spec.Pos[1] * s, spec.Pos[2] * s, spec.Pos[3] * s }
		end
		k:Part(spec)
	end
end
local hpart = scaled(HS)
local bpart = scaled(BS)
local function hv(v)
	return { v[1] * HS, v[2] * HS, v[3] * HS }
end

-- Thin 6-armed frost crystal lying in a -Z facing plane
local function frostStar(k, pos, size, color, material, anim)
	for i = 0, 2 do
		k:Part({ Name = "FrostStar", Size = { size, 0.05, 0.05 }, Pos = pos, Rot = { 0, 0, i * 60 + 15 }, Color = color, Material = material, Anim = anim })
	end
end

--------------------------------------------------------------------------------------------
-- Fridge cabinet (static shell, rounded crown, cavity, food, back, frost)
--------------------------------------------------------------------------------------------
local function buildCabinet(k)
	-- rounded vertical corners + side walls + rounded crown edges
	local czF, czB = DZ + R, FZ1 - R -- crown front / back edge centres
	k:Mirror(function()
		post(k, "CornerFront", { FX - R, FY, FZ0 + R }, FH, R * 2, FRIDGE)
		post(k, "CornerBack", { FX - R, FY, FZ1 - R }, FH, R * 2, FRIDGE)
		k:Part({ Name = "SideWall", Size = { R, FH, (FZ1 - R) - (FZ0 + R) }, Pos = { FX - R / 2, FY, (FZ0 + FZ1) / 2 }, Color = FRIDGE })
		k:Part({ Name = "CrownSide", Shape = "Cylinder", Size = { czB - czF, R * 2, R * 2 }, Pos = { FX - R, BODY_T, (czF + czB) / 2 }, Rot = { 0, 90, 0 }, Color = FRIDGE })
		k:Part({ Name = "CrownCornerF", Shape = "Ball", Size = { R * 2, R * 2, R * 2 }, Pos = { FX - R, BODY_T, czF }, Color = DOOR })
		k:Part({ Name = "CrownCornerB", Shape = "Ball", Size = { R * 2, R * 2, R * 2 }, Pos = { FX - R, BODY_T, czB }, Color = FRIDGE })
		-- rubber seals where the camel legs come out of the bottom
		post(k, "HipSeal", { 0.62, FB - 0.03, 0.1 }, 0.07, 0.76, GASKET, "Rubber")
	end)
	k:Part({ Name = "CrownTop", Size = { 2 * (FX - R), R, czB - czF }, Pos = { 0, BODY_T + R / 2, (czF + czB) / 2 }, Color = FRIDGE })
	k:Part({ Name = "CrownFront", Shape = "Cylinder", Size = { 2 * (FX - R), R * 2, R * 2 }, Pos = { 0, BODY_T, czF }, Color = DOOR })
	k:Part({ Name = "CrownBack", Shape = "Cylinder", Size = { 2 * (FX - R), R * 2, R * 2 }, Pos = { 0, BODY_T, czB }, Color = FRIDGE })
	-- chrome trim line where the crown meets the freezer door
	k:Part({ Name = "CrownTrim", Size = { 2 * (FX - R) + 0.1, 0.05, 0.05 }, Pos = { 0, BODY_T - 0.02, DZ - 0.01 }, Color = CHROME_DARK, Material = "Metal" })

	-- back half (solid), freezer block and plinth in front of it, cavity between
	k:Part({ Name = "CabinetBack", Size = { 2 * (FX - R), FH, FZ1 - CAV_Z }, Pos = { 0, FY, (FZ1 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "FreezerBlock", Size = { 2 * (FX - R), BODY_T - CAV_T, CAV_Z - FZ0 }, Pos = { 0, (BODY_T + CAV_T) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })
	k:Part({ Name = "Plinth", Size = { 2 * (FX - R), CAV_B - FB, CAV_Z - FZ0 }, Pos = { 0, (FB + CAV_B) / 2, (FZ0 + CAV_Z) / 2 }, Color = FRIDGE })

	-- interior (seen through the ajar door; the door hinges on +X so the gap is at -X)
	local cavH = CAV_T - CAV_B
	local cavY = (CAV_B + CAV_T) / 2
	k:Part({ Name = "LinerBack", Size = { 2 * (FX - R), cavH, 0.05 }, Pos = { 0, cavY, CAV_Z - 0.025 }, Color = LINER })
	k:Part({ Name = "LinerSide", Size = { 0.05, cavH, CAV_Z - FZ0 }, Pos = { -(FX - R) + 0.025, cavY, (FZ0 + CAV_Z) / 2 }, Color = LINER })
	k:Part({ Name = "LinerFloor", Size = { 2 * (FX - R), 0.05, CAV_Z - FZ0 }, Pos = { 0, CAV_B + 0.025, (FZ0 + CAV_Z) / 2 }, Color = LINER })
	k:Part({ Name = "FridgeLamp", Size = { 1.5, 0.08, 0.16 }, Pos = { 0, CAV_T - 0.05, -0.45 }, Color = GLOW, Material = "Neon" })
	k:Part({ Name = "GlowStrip", Size = { 0.06, cavH - 0.2, 0.08 }, Pos = { -(FX - R) + 0.06, cavY, -0.62 }, Color = GLOW, Material = "Neon" })
	local S1, S2 = CAV_B + 0.74, CAV_B + 1.48
	for _, y in { S1, S2 } do
		k:Part({ Name = "GlassShelf", Size = { 1.96, 0.06, 0.82 }, Pos = { 0, y, -0.5 }, Color = "#d6f2ff", Material = "Glass", Transparency = 0.3 })
		k:Part({ Name = "ShelfTrim", Size = { 1.96, 0.06, 0.05 }, Pos = { 0, y, -0.9 }, Color = CHROME, Material = "Metal" })
	end
	-- food (packed toward the open -X side so it shows through the gap)
	k:Part({ Name = "MilkCarton", Size = { 0.3, 0.5, 0.3 }, Pos = { -0.72, CAV_B + 0.3, -0.5 }, Color = "#fbfbf6" })
	k:Part({ Name = "MilkBand", Size = { 0.32, 0.12, 0.32 }, Pos = { -0.72, CAV_B + 0.4, -0.5 }, Color = BLUE })
	k:Part({ Name = "MilkRoof", Shape = "Wedge", Size = { 0.3, 0.12, 0.15 }, Pos = { -0.72, CAV_B + 0.61, -0.575 }, Color = "#fbfbf6" })
	k:Part({ Name = "Watermelon", Shape = "Ellipsoid", Size = { 0.46, 0.34, 0.4 }, Pos = { -0.25, CAV_B + 0.22, -0.45 }, Color = "#3c9a4a" })
	k:Part({ Name = "Cheese", Shape = "Wedge", Size = { 0.42, 0.24, 0.34 }, Pos = { -0.66, S1 + 0.15, -0.55 }, Rot = { 0, 180, 0 }, Color = "#ffcf4a" })
	k:Part({ Name = "Apple", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = { -0.25, S1 + 0.16, -0.6 }, Color = RED })
	k:Part({ Name = "AppleStem", Size = { 0.05, 0.08, 0.05 }, Pos = { -0.25, S1 + 0.31, -0.6 }, Color = FUR_DARK })
	post(k, "Bottle", { -0.72, S2 + 0.28, -0.55 }, 0.5, 0.18, "#3fae6a", "Glass")
	post(k, "BottleNeck", { -0.72, S2 + 0.6, -0.55 }, 0.16, 0.08, "#3fae6a", "Glass")
	post(k, "Jar", { -0.36, S2 + 0.16, -0.55 }, 0.26, 0.26, "#ff9a3c")
	post(k, "JarLid", { -0.36, S2 + 0.31, -0.55 }, 0.05, 0.28, RED)

	-- seam between freezer and main compartment
	k:Part({ Name = "DoorSeam", Size = { 2.45, 0.07, 0.08 }, Pos = { 0, SEAM_Y, FZ0 - 0.03 }, Color = SEAM })

	-- kick-plate vent grille under the main door
	k:Part({ Name = "Grille", Size = { 1.9, 0.18, 0.05 }, Pos = { 0, FB + 0.13, FZ0 - 0.02 }, Color = GRILLE })
	for i = 0, 2 do
		k:Part({ Name = "GrilleSlat", Size = { 1.7, 0.05, 0.05 }, Pos = { 0, FB + 0.07 + i * 0.06, FZ0 - 0.045 }, Color = CHROME_DARK, Material = "Metal" })
	end

	-- barrel hinges on the right (+X) edge
	for _, y in { FRZ_T - 0.08, SEAM_Y, MAIN_B + 0.04 } do
		post(k, "Hinge", { FX - 0.02, y, FZ0 - 0.07 }, 0.24, 0.16, CHROME, "Metal", { Reflectance = 0.2 })
	end

	-- frost overflowing the crown's front edge: an ice rim with icicles hanging from it
	local iz = DZ - 0.05
	k:Part({ Name = "IceRim", Shape = "Ellipsoid", Size = { 2.3, 0.14, 0.2 }, Pos = { 0, BODY_T + 0.02, DZ + 0.04 }, Color = ICE, Material = "Ice", Transparency = 0.1, Reflectance = 0.15 })
	local icicles = { { -1.0, 0.34 }, { -0.68, 0.5 }, { -0.45, 0.22 }, { 0.5, 0.28 }, { 0.74, 0.54 }, { 1.0, 0.3 } }
	for _, ic in icicles do
		local x, len = ic[1], ic[2]
		k:Part({ Name = "IcicleRoot", Shape = "Ellipsoid", Size = { 0.16, 0.18, 0.14 }, Pos = { x, BODY_T - 0.04, iz }, Color = ICE, Material = "Ice", Transparency = 0.05, Reflectance = 0.15 })
		k:Part({ Name = "Icicle", Shape = "Ellipsoid", Size = { 0.1, len, 0.1 }, Pos = { x, BODY_T - 0.1 - len / 2 + 0.04, iz }, Color = ICE, Material = "Ice", Transparency = 0.05, Reflectance = 0.15 })
	end
	-- snow caps on the crown's front corners
	k:Part({ Name = "SnowCap", Shape = "Ellipsoid", Size = { 0.86, 0.16, 0.6 }, Pos = { -0.72, FT + 0.01, -0.82 }, Rot = { 0, 12, 0 }, Color = FROST, Material = "Snow" })
	k:Part({ Name = "SnowCap", Shape = "Ellipsoid", Size = { 0.64, 0.14, 0.5 }, Pos = { 0.8, FT + 0.0, -0.78 }, Rot = { 0, -15, 0 }, Color = FROST, Material = "Snow" })
	k:Part({ Name = "SnowCap", Shape = "Ellipsoid", Size = { 0.5, 0.12, 0.46 }, Pos = { -0.78, FT - 0.01, 0.62 }, Rot = { 0, 30, 0 }, Color = FROST, Material = "Snow" })

	-- side details: energy sticker (right), frost bloom + meltwater drips (left)
	k:Part({ Name = "EnergySticker", Size = { 0.05, 0.42, 0.56 }, Pos = { FX + 0.01, FB + 0.8, 0.45 }, Color = CHROME, Material = "Metal", Text = { Text = "A+++", Color = "#2f9e5a", Face = "Right" } })
	for i, c in { { "#2f9e5a", 0.13 }, { "#9ccf3a", 0.03 }, { "#f2c12e", -0.07 }, { "#e8463e", -0.17 } } do
		k:Part({ Name = "EnergyBar", Size = { 0.05, 0.06, 0.18 + i * 0.05 }, Pos = { FX + 0.025, FB + 0.8 + c[2], 0.32 + i * 0.025 }, Color = c[1] })
	end
	k:Part({ Name = "SideFrost", Shape = "Ellipsoid", Size = { 0.05, 0.7, 1.1 }, Pos = { -FX - 0.005, BODY_T - 0.32, 0.05 }, Color = FROST, Material = "Ice", Transparency = 0.15 })
	for _, d in { { 0.35, 0.5 }, { -0.25, 0.32 } } do
		k:Part({ Name = "MeltDrip", Shape = "Ellipsoid", Size = { 0.05, d[2], 0.08 }, Pos = { -FX - 0.01, BODY_T - 0.62 - d[2] / 2, d[1] }, Color = WATER, Material = "Glass", Transparency = 0.2 })
		k:Part({ Name = "MeltDrop", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { -FX - 0.015, BODY_T - 0.64 - d[2], d[1] }, Color = WATER, Material = "Glass", Transparency = 0.2 })
	end

	-- back: serpentine condenser coil (horizontal tubes, end headers, thin vertical wires)
	local cy0, cy1 = FB + 0.9, BODY_T - 0.45
	for i = 0, 4 do
		local y = cy0 + (cy1 - cy0) * i / 4
		k:Part({ Name = "CoilTube", Shape = "Cylinder", Size = { 1.7, 0.08, 0.08 }, Pos = { 0, y, FZ1 + 0.05 }, Color = COIL, Material = "Metal" })
	end
	for _, x in { -0.85, 0.85 } do
		post(k, "CoilHeader", { x, (cy0 + cy1) / 2, FZ1 + 0.05 }, cy1 - cy0 + 0.08, 0.1, COIL, "Metal")
	end
	for _, x in { -0.42, 0.42 } do
		post(k, "CoilWire", { x, (cy0 + cy1) / 2, FZ1 + 0.1 }, cy1 - cy0 + 0.25, 0.05, COIL, "Metal")
	end
	k:Part({ Name = "RatingPlate", Size = { 0.5, 0.3, 0.05 }, Pos = { 0.62, FB + 0.62, FZ1 + 0.02 }, Color = CHROME, Material = "Metal", Text = { Text = "220V", Color = "#2d3a4a", Face = "Back" } })
	k:Part({ Name = "Compressor", Shape = "Ellipsoid", Size = { 0.62, 0.38, 0.32 }, Pos = { -0.1, FB + 0.36, FZ1 + 0.06 }, Color = DARK, Material = "Metal" })
	for i = 0, 3 do
		k:Part({ Name = "BackVent", Size = { 0.08, 0.14, 0.05 }, Pos = { 0.42 + i * 0.13, FB + 0.22, FZ1 + 0.02 }, Color = GRILLE })
	end
end

--------------------------------------------------------------------------------------------
-- Doors. Both hinge on the +X edge; door-local x runs from 0 (hinge) to -2*FX (free edge).
--------------------------------------------------------------------------------------------
local function doorSlab(k, name, h)
	k:Part({ Name = name, Size = { 2 * FX - DT, h, DT }, Pos = { -FX, 0, -DT / 2 }, Color = DOOR })
	post(k, name .. "EdgeHinge", { -DT / 2, 0, -DT / 2 }, h, DT, DOOR)
	post(k, name .. "EdgeFree", { -(2 * FX - DT / 2), 0, -DT / 2 }, h, DT, DOOR)
	-- slightly raised panel line inset on the door face
	k:Part({ Name = name .. "Panel", Size = { 2 * FX - 0.5, h - 0.24, 0.05 }, Pos = { -FX, 0, -DT - 0.01 }, Color = "#f6f2e8" })
end

local function handle(k, y, len)
	local x = -(2 * FX - 0.3)
	post(k, "HandleBar", { x, y, -DT - 0.19 }, len, 0.13, CHROME, "Metal", { Reflectance = 0.3 })
	for _, s in { -1, 1 } do
		k:Part({ Name = "HandlePost", Size = { 0.1, 0.1, 0.2 }, Pos = { x, y + s * (len / 2 - 0.08), -DT - 0.09 }, Color = CHROME_DARK, Material = "Metal" })
		k:Part({ Name = "HandleCap", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = { x, y + s * len / 2, -DT - 0.19 }, Color = CHROME, Material = "Metal" })
	end
end

local function buildFreezerDoor(k)
	local h = FRZ_T - FRZ_B
	k:Group({ Name = "FreezerDoor", Pos = { FX, (FRZ_B + FRZ_T) / 2, FZ0 } }, function()
		doorSlab(k, "FreezerDoor", h)
		handle(k, -h / 2 + 0.36, 0.44)
		local fz = -DT - 0.03
		-- badge plate (generic, not a brand)
		k:Part({ Name = "Badge", Size = { 0.74, 0.2, 0.05 }, Pos = { -FX, 0.2, fz }, Color = CHROME, Material = "Metal", Reflectance = 0.25, Text = { Text = "FRIGO", Color = "#2d5f8a", Face = "Front" } })
		k:Part({ Name = "BadgeRim", Size = { 0.8, 0.26, 0.05 }, Pos = { -FX, 0.2, fz + 0.015 }, Color = CHROME_DARK, Material = "Metal" })
		-- digital thermometer
		k:Part({ Name = "TempDisplay", Size = { 0.46, 0.2, 0.05 }, Pos = { -FX, -0.16, fz }, Color = DARK, Text = { Text = "-18°", Color = GLOW, Face = "Front" } })
		k:Part({ Name = "TempDigits", Size = { 0.3, 0.07, 0.05 }, Pos = { -FX - 0.02, -0.16, fz - 0.02 }, Color = GLOW, Material = "Neon" })
		k:Part({ Name = "PowerLed", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { -FX - 0.33, -0.16, fz }, Color = GLOW, Material = "Neon", Anim = { Type = "Pulse", Amount = 0.35, Speed = 0.7 } })
		-- neon snowflake emblem (gently pulsing)
		frostStar(k, { -0.5, 0.0, fz - 0.005 }, 0.44, GLOW, "Neon", { Type = "Pulse", Amount = 0.12, Speed = 0.5, Phase = 0.3 })
		k:Part({ Name = "SnowflakeHub", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { -0.5, 0.0, fz - 0.01 }, Color = FROST, Material = "Neon" })
		-- frosted-over corner by the handle: layered frost blooms + crystals (Epic ice flair)
		local cx, cy = -(2 * FX - 0.42), h / 2 - 0.2
		k:Part({ Name = "FrostBloom", Shape = "Ellipsoid", Size = { 0.7, 0.36, 0.05 }, Pos = { cx, cy + 0.04, fz + 0.01 }, Color = FROST, Material = "Ice", Transparency = 0.1 })
		k:Part({ Name = "FrostBloom", Shape = "Ellipsoid", Size = { 0.42, 0.3, 0.05 }, Pos = { cx + 0.26, cy - 0.1, fz + 0.005 }, Color = FROST, Material = "Ice", Transparency = 0.1 })
		frostStar(k, { cx - 0.1, cy - 0.02, fz - 0.015 }, 0.22, "#ffffff", "Ice")
		frostStar(k, { cx + 0.3, cy - 0.16, fz - 0.015 }, 0.14, "#ffffff", "Ice")
	end)
end

local function buildMainDoor(k)
	local h = MAIN_T - MAIN_B
	-- hinge pivot at the back corner of the door; the door hangs open
	k:Group({ Name = "MainDoorHinge", Pos = { FX, (MAIN_B + MAIN_T) / 2, FZ0 }, Rot = { 0, -22, 0 } }, function()
		k:Group({ Name = "MainDoor", Anim = { Type = "Wiggle", Axis = "Y", Amount = 5, Speed = 0.3 } }, function()
			doorSlab(k, "MainDoor", h)
			handle(k, h / 2 - 0.55, 0.74)
			-- inside of the door
			k:Part({ Name = "DoorLiner", Size = { 2.2, h - 0.2, 0.05 }, Pos = { -FX, 0, 0.025 }, Color = LINER })
			k:Part({ Name = "DoorGasket", Size = { 0.06, h - 0.12, 0.06 }, Pos = { -(2 * FX - 0.16), 0, 0.03 }, Color = GASKET, Material = "Rubber" })
			for _, by in { -0.55, 0.25 } do
				k:Part({ Name = "BinLip", Size = { 1.6, 0.16, 0.05 }, Pos = { -1.3, by + 0.08, 0.3 }, Color = "#eef8ff", Material = "Glass", Transparency = 0.3 })
				k:Part({ Name = "BinFloor", Size = { 1.6, 0.05, 0.3 }, Pos = { -1.3, by, 0.15 }, Color = "#eef8ff" })
			end
			post(k, "DoorBottle", { -1.85, -0.33, 0.15 }, 0.44, 0.17, "#3fae6a", "Glass")
			post(k, "JuiceBottle", { -2.08, -0.35, 0.15 }, 0.4, 0.17, "#ffb13b")
			for i = 0, 3 do
				k:Part({ Name = "Egg", Shape = "Ellipsoid", Size = { 0.11, 0.15, 0.11 }, Pos = { -1.95 + i * 0.15, 0.33, 0.15 }, Color = "#fff1d8" })
			end
			-- fridge magnets + a kid's drawing of Frigo Camelo on the front
			local fz = -DT - 0.03
			k:Part({ Name = "Drawing", Size = { 0.6, 0.72, 0.05 }, Pos = { -0.82, 0.22, fz }, Rot = { 0, 0, -5 }, Color = PAPER })
			k:Part({ Name = "DrawingFridge", Size = { 0.2, 0.26, 0.05 }, Pos = { -0.84, 0.07, fz - 0.01 }, Rot = { 0, 0, -5 }, Color = "#9fd4ff" })
			k:Part({ Name = "DrawingNeck", Size = { 0.05, 0.22, 0.05 }, Pos = { -0.81, 0.3, fz - 0.01 }, Rot = { 0, 0, -12 }, Color = FUR_DARK })
			k:Part({ Name = "DrawingHead", Shape = "Ellipsoid", Size = { 0.14, 0.09, 0.05 }, Pos = { -0.74, 0.41, fz - 0.01 }, Color = FUR_DARK })
			k:Part({ Name = "DrawingBoots", Size = { 0.22, 0.06, 0.05 }, Pos = { -0.85, -0.1, fz - 0.01 }, Rot = { 0, 0, -5 }, Color = BOOT })
			k:Part({ Name = "DrawingSun", Shape = "Ellipsoid", Size = { 0.1, 0.1, 0.05 }, Pos = { -1.0, 0.46, fz - 0.01 }, Color = YELLOW })
			k:Part({ Name = "DrawingMagnet", Shape = "Cylinder", Size = { 0.06, 0.13, 0.13 }, Pos = { -0.86, 0.55, fz - 0.035 }, Rot = { 0, 90, 0 }, Color = BLUE })
			for _, s in { -1, 1 } do
				k:Part({ Name = "HeartLobe", Shape = "Ellipsoid", Size = { 0.15, 0.15, 0.05 }, Pos = { -1.62 + s * 0.055, 0.7, fz - 0.02 }, Color = RED })
			end
			k:Part({ Name = "HeartTip", Size = { 0.13, 0.13, 0.05 }, Pos = { -1.62, 0.635, fz - 0.02 }, Rot = { 0, 0, 45 }, Color = RED })
			k:Part({ Name = "PizzaMagnet", Shape = "Wedge", Size = { 0.05, 0.3, 0.24 }, Pos = { -1.6, -0.45, fz - 0.02 }, Rot = { 0, -90, 0 }, Color = YELLOW })
			k:Part({ Name = "Pepperoni", Shape = "Cylinder", Size = { 0.05, 0.07, 0.07 }, Pos = { -1.6, -0.5, fz - 0.05 }, Rot = { 0, 90, 0 }, Color = RED })
			k:Part({ Name = "LemonMagnet", Shape = "Ellipsoid", Size = { 0.22, 0.15, 0.06 }, Pos = { -0.55, -0.62, fz - 0.02 }, Rot = { 0, 0, 20 }, Color = YELLOW })
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Power cord "tail" at the back
--------------------------------------------------------------------------------------------
local function buildCord(k)
	local base = { -0.55, FB + 0.5, FZ1 + 0.05 }
	k:Group({ Name = "PowerCord", Pos = base, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.45, Phase = 0.6 } }, function()
		local pts = { { 0, 0, 0 }, { 0, -0.15, 0.38 }, { 0.06, -0.75, 0.48 }, { 0.08, -1.18, 0.24 } }
		for i = 1, #pts - 1 do
			segment(k, "Cord", pts[i], pts[i + 1], 0.07, DARK, "Rubber", 0.06)
		end
		k:Part({ Name = "CordGrommet", Shape = "Cylinder", Size = { 0.08, 0.14, 0.14 }, Pos = { 0, 0, -0.01 }, Rot = { 0, 90, 0 }, Color = DARK, Material = "Rubber" })
		local p = pts[#pts]
		k:Part({ Name = "Plug", Size = { 0.18, 0.22, 0.14 }, Pos = { p[1], p[2] - 0.1, p[3] }, Color = DARK, Material = "Rubber" })
		for _, s in { -1, 1 } do
			k:Part({ Name = "PlugPin", Shape = "Cylinder", Size = { 0.16, 0.05, 0.05 }, Pos = { p[1] + s * 0.05, p[2] - 0.27, p[3] }, Rot = { 0, 0, 90 }, Color = CHROME, Material = "Metal" })
		end
	end)
end

--------------------------------------------------------------------------------------------
-- Neck: a smooth S-curve (cubic Bezier) of tapering tube segments, mane + throat fur
--------------------------------------------------------------------------------------------
local NECK_N = 7
local NECK_PTS, NECK_D = {}, {}
do
	local B = { { NECK0[2], NECK0[3] }, { 7.15, -0.25 }, { 7.45, -1.05 }, { J[2] - 0.02, J[3] } }
	for i = 0, NECK_N do
		local t = i / NECK_N
		local u = 1 - t
		local w = { u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t }
		local y = w[1] * B[1][1] + w[2] * B[2][1] + w[3] * B[3][1] + w[4] * B[4][1]
		local z = w[1] * B[1][2] + w[2] * B[2][2] + w[3] * B[3][2] + w[4] * B[4][2]
		NECK_PTS[i + 1] = { 0, y, z }
		NECK_D[i + 1] = 0.86 - 0.28 * t
	end
end

local function buildNeck(k)
	for i = 1, NECK_N do
		local a, b = NECK_PTS[i], NECK_PTS[i + 1]
		local d = (NECK_D[i] + NECK_D[i + 1]) / 2
		segment(k, "Neck", a, b, d, FUR, "SmoothPlastic", 0)
		k:Part({ Name = "NeckJoint", Shape = "Ball", Size = { NECK_D[i], NECK_D[i], NECK_D[i] }, Pos = a, Color = FUR })
	end
	-- shaggy mane ridge down the back of the neck and fluffy throat fur in front
	for i = 2, NECK_N do
		local a, b = NECK_PTS[i], NECK_PTS[i + 1]
		local dy, dz = b[2] - a[2], b[3] - a[3]
		local len = math.sqrt(dy * dy + dz * dz)
		local ty, tz = dy / len, dz / len
		local ny, nz = -tz, ty -- back-pointing normal in the YZ plane
		local r = (NECK_D[i] + NECK_D[i + 1]) / 4
		local my, mz = (a[2] + b[2]) / 2, (a[3] + b[3]) / 2
		local tilt = deg(math.atan2(dz, dy))
		k:Part({ Name = "Mane", Shape = "Ellipsoid", Size = { 0.24, len * 1.5, 0.22 }, Pos = { 0, my + ny * (r - 0.02), mz + nz * (r - 0.02) }, Rot = { tilt, 0, 0 }, Color = FUR_DARK, Material = "Fabric" })
		if i <= 4 then
			k:Part({ Name = "ThroatFur", Shape = "Ellipsoid", Size = { 0.44 - i * 0.04, len * 1.5, 0.26 }, Pos = { 0, my - ny * (r - 0.03), mz - nz * (r - 0.03) }, Rot = { tilt + 8, 0, 0 }, Color = FUR_MID, Material = "Fabric" })
		end
	end
end

local function buildNeckBase(k)
	-- rubber gasket collar where the neck pokes through the fridge top
	post(k, "NeckGasket", { NECK0[1], FT + 0.03, NECK0[3] }, 0.06, 1.16, GASKET, "Rubber")
	post(k, "NeckSeal", { NECK0[1], FT + 0.1, NECK0[3] }, 0.12, 0.98, GASKET, "Rubber")
	for i = 0, 5 do
		local a = math.rad(i * 60 + 30)
		k:Part({ Name = "SealBolt", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { math.cos(a) * 0.53, FT + 0.07, NECK0[3] + math.sin(a) * 0.53 }, Color = CHROME, Material = "Metal" })
	end
	-- dromedary hump behind the neck, with a woolly tuft
	k:Part({ Name = "Hump", Shape = "Ellipsoid", Size = { 1.2, 0.92, 1.0 }, Pos = { 0, FT + 0.04, 0.5 }, Color = FUR })
	k:Part({ Name = "HumpTuft", Shape = "Ellipsoid", Size = { 0.62, 0.24, 0.6 }, Pos = { 0, FT + 0.42, 0.54 }, Color = FUR_DARK, Material = "Fabric" })
	k:Part({ Name = "HumpSnow", Shape = "Ellipsoid", Size = { 0.36, 0.1, 0.32 }, Pos = { 0.12, FT + 0.53, 0.58 }, Rot = { 0, 20, 8 }, Color = FROST, Material = "Snow" })
end

--------------------------------------------------------------------------------------------
-- Head (local to the head joint; authored unscaled, scaled by HS)
--------------------------------------------------------------------------------------------
local E_CRAN = { 0, 0.3, 0.05, 0.47, 0.45, 0.5 }
local E_FACE = { 0, 0.14, -0.52, 0.36, 0.35, 0.6 }
local E_MUZ = { 0, -0.07, -1.04, 0.34, 0.33, 0.4 }

local function ell(k, name, E, color, material)
	hpart(k, { Name = name, Shape = "Ellipsoid", Size = { E[4] * 2, E[5] * 2, E[6] * 2 }, Pos = { E[1], E[2], E[3] }, Color = color, Material = material })
end

local ER = 0.25
local function buildEye(k)
	local c, n = surf(E_CRAN, 0.62, 0.22, -0.75, -0.08)
	k:Group({ Name = "Eye", Pos = hv(c), Rot = faceRot(n) }, function()
		local BLINK = { Type = "Blink", Speed = 0.22, Phase = 0.35 }
		local function onEye(yaw, pitch, depth)
			local r = ER + depth
			return { math.sin(math.rad(yaw)) * math.cos(math.rad(pitch)) * r, math.sin(math.rad(pitch)) * r, -math.cos(math.rad(yaw)) * math.cos(math.rad(pitch)) * r }
		end
		hpart(k, { Name = "Eyeball", Shape = "Ball", Size = { ER * 2, ER * 2, ER * 2 }, Color = EYE_WHITE, Anim = BLINK })
		hpart(k, { Name = "Iris", Shape = "Ellipsoid", Size = { 0.32, 0.34, 0.08 }, Pos = onEye(-22, -10, -0.025), Rot = { -10, 22, 0 }, Color = IRIS, Anim = BLINK })
		hpart(k, { Name = "Pupil", Shape = "Ellipsoid", Size = { 0.18, 0.2, 0.06 }, Pos = onEye(-22, -10, 0.0), Rot = { -10, 22, 0 }, Color = PUPIL, Anim = BLINK })
		hpart(k, { Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = onEye(-32, -6, 0.02), Color = SHINE, Material = "Neon", Anim = BLINK })
		hpart(k, { Name = "EyeShine2", Shape = "Ball", Size = { 0.045, 0.045, 0.045 }, Pos = onEye(-12, -22, 0.02), Color = SHINE, Material = "Neon", Anim = BLINK })
		-- heavy, droopy upper lid (half closed: proud but tired) with a dark lash line
		hpart(k, { Name = "UpperLid", Shape = "Ellipsoid", Size = { ER * 2 + 0.06, 0.34, ER * 2 + 0.06 }, Pos = { 0, 0.16, 0.0 }, Rot = { 0, 0, -10 }, Color = LID })
		hpart(k, { Name = "LashLine", Shape = "Ellipsoid", Size = { ER * 2 + 0.07, 0.05, ER * 2 + 0.07 }, Pos = { 0.005, 0.0, 0.0 }, Rot = { 0, 0, -10 }, Color = LASH })
		hpart(k, { Name = "LowerLid", Shape = "Ellipsoid", Size = { ER * 2 + 0.02, 0.1, ER * 2 - 0.03 }, Pos = { 0, -0.22, 0.0 }, Color = FUR_LIGHT })
		hpart(k, { Name = "Brow", Shape = "Ellipsoid", Size = { 0.54, 0.11, 0.24 }, Pos = { 0.02, 0.38, 0.03 }, Rot = { 0, 0, -14 }, Color = FUR_DARK, Material = "Fabric" })
		-- long lashes fanning out of the lash line, curling down and outward
		for i, phi in { -12, 18, 46, 72 } do
			local s, co = math.sin(math.rad(phi)), math.cos(math.rad(phi))
			local r = ER + 0.03
			local yb = -0.005 - 0.17 * s * r
			local base = { r * s, yb, -r * co }
			local L = 0.08 + i * 0.022
			local dx, dy, dz = s * 0.75 + 0.3, -0.5, -co * 0.75
			local dl = math.sqrt(dx * dx + dy * dy + dz * dz)
			local tip = { base[1] + dx / dl * L, base[2] + dy / dl * L, base[3] + dz / dl * L }
			segment(k, "Lash", hv(base), hv(tip), 0.045 * HS, LASH, "SmoothPlastic", 0.02)
		end
	end)
end

local function buildEar(k)
	local p = surf(E_CRAN, 0.55, 0.78, 0.4, -0.06)
	k:Group({ Name = "Ear", Pos = hv(p), Rot = { -18, 0, -38 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 16, Speed = 0.45, Phase = 0.1 } }, function()
		hpart(k, { Name = "EarOuter", Shape = "Ellipsoid", Size = { 0.27, 0.38, 0.15 }, Pos = { 0, 0.15, 0 }, Color = FUR })
		hpart(k, { Name = "EarInner", Shape = "Ellipsoid", Size = { 0.16, 0.26, 0.05 }, Pos = { 0, 0.15, -0.065 }, Color = EAR_IN })
		hpart(k, { Name = "EarTip", Shape = "Ellipsoid", Size = { 0.16, 0.12, 0.1 }, Pos = { 0, 0.3, 0.01 }, Color = FUR_DARK, Material = "Fabric" })
	end)
end

local function buildHead(k)
	ell(k, "Cranium", E_CRAN, FUR)
	ell(k, "Face", E_FACE, FUR)
	ell(k, "Muzzle", E_MUZ, MUZZLE)
	-- roman-nose bridge: the camel's long arched snout line
	hpart(k, { Name = "NoseBridge", Shape = "Ellipsoid", Size = { 0.36, 0.22, 0.8 }, Pos = { 0, 0.32, -0.82 }, Rot = { -6, 0, 0 }, Color = FUR_MID })
	hpart(k, { Name = "ThroatLatch", Shape = "Ellipsoid", Size = { 0.62, 0.62, 0.66 }, Pos = { 0, 0.0, 0.08 }, Color = FUR })

	-- woolly topknot between the ears
	hpart(k, { Name = "Topknot", Shape = "Ellipsoid", Size = { 0.46, 0.26, 0.44 }, Pos = surf(E_CRAN, 0, 1, 0.12, -0.06), Color = FUR_DARK, Material = "Fabric" })
	for _, t in { { 0.13, 0.95, -0.2, 0.22 }, { -0.12, 0.96, -0.24, 0.2 }, { 0.0, 0.9, -0.38, 0.18 } } do
		local p = surf(E_CRAN, t[1], t[2], t[3], -0.04)
		hpart(k, { Name = "Forelock", Shape = "Ball", Size = { t[4], t[4], t[4] }, Pos = p, Color = FUR_DARK, Material = "Fabric" })
	end
	-- dark split ("cleft") between the two upper lip lobes
	hpart(k, { Name = "LipCleft", Shape = "Ellipsoid", Size = { 0.05, 0.26, 0.14 }, Pos = { 0, -0.25, -1.47 }, Color = MOUTH })

	k:Mirror(function()
		buildEye(k)
		buildEar(k)
		-- slit nostrils on top of the muzzle
		local np, nn = surf(E_MUZ, 0.34, 0.45, -0.82, -0.015)
		hpart(k, { Name = "Nostril", Shape = "Ellipsoid", Size = { 0.18, 0.055, 0.11 }, Pos = np, Rot = faceRot(nn, 28), Color = NOSTRIL })
		-- light cheek/jowl patch under the eye
		hpart(k, { Name = "Cheek", Shape = "Ellipsoid", Size = { 0.2, 0.3, 0.5 }, Pos = { 0.26, -0.06, -0.5 }, Color = FUR_LIGHT })
		-- split, floppy upper lip lobes with buck teeth peeking out under them
		hpart(k, { Name = "UpperLip", Shape = "Ellipsoid", Size = { 0.42, 0.36, 0.46 }, Pos = { 0.16, -0.26, -1.3 }, Color = LIP })
		hpart(k, { Name = "Tooth", Size = { 0.1, 0.12, 0.05 }, Pos = { 0.058, -0.42, -1.47 }, Color = TEETH })
	end)

	-- chewing lower jaw: side-to-side grind around a pivot behind the mouth
	local JP = { 0, -0.2, -0.5 }
	k:Group({ Name = "JawChew", Pos = hv(JP), Anim = { Type = "Wiggle", Axis = "Y", Amount = 7, Speed = 1.1 } }, function()
		k:Group({ Name = "JawOpen", Anim = { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 1.1, Phase = 0.25 } }, function()
			k:Group({ Name = "JawOffset", Pos = hv({ -JP[1], -JP[2], -JP[3] }) }, function()
				hpart(k, { Name = "JawUnder", Shape = "Ellipsoid", Size = { 0.56, 0.3, 0.95 }, Pos = { 0, -0.31, -0.9 }, Color = FUR })
				hpart(k, { Name = "LowerLip", Shape = "Ellipsoid", Size = { 0.56, 0.26, 0.44 }, Pos = { 0, -0.52, -1.27 }, Color = LIP })
				hpart(k, { Name = "MouthLine", Shape = "Ellipsoid", Size = { 0.6, 0.05, 0.44 }, Pos = { 0, -0.42, -1.3 }, Color = MOUTH })
				hpart(k, { Name = "Tongue", Shape = "Ellipsoid", Size = { 0.24, 0.06, 0.18 }, Pos = { 0.04, -0.43, -1.46 }, Color = "#d9767a" })
				hpart(k, { Name = "ChinTuft", Shape = "Ellipsoid", Size = { 0.26, 0.22, 0.24 }, Pos = { 0, -0.62, -1.06 }, Color = FUR_DARK, Material = "Fabric" })
			end)
		end)
	end)

	-- cold breath
	k:Particles({ Pos = hv({ 0, -0.35, -1.62 }), Color = "#eaf8ff", Color2 = "#bfe6ff", Rate = 4, Size = 0.25, Speed = 0.8, Lifetime = 1.6, Spread = 25, Direction = "Front" })
end

--------------------------------------------------------------------------------------------
-- Camel leg in a giant wheat work boot. Written for the right (+X) side; mirrored.
--------------------------------------------------------------------------------------------
local BG = -0.65 -- ground, relative to the ankle (unscaled boot space)
local VAMP_C = { 0, 0.04, -0.28 } -- sloped lacing panel (ellipsoid tilted back 35 degrees)
local VAMP_A = 35

-- point on the front of the vamp: v = position along its long axis, x = sideways
local function vampFront(v, x, out)
	local a = math.rad(VAMP_A)
	local zl = -(0.31 + out) * math.sqrt(math.max(0, 1 - (x / 0.42) ^ 2))
	return { x, VAMP_C[2] + math.cos(a) * v - math.sin(a) * zl, VAMP_C[3] + math.sin(a) * v + math.cos(a) * zl }
end

local function bpost(k, name, pos, height, diameter, color, material)
	bpart(k, { Name = name, Shape = "Cylinder", Size = { height, diameter, diameter }, Pos = pos, Rot = { 0, 0, 90 }, Color = color, Material = material })
end

local function buildBoot(k)
	-- chunky lug sole with rounded toe + stitched welt
	bpart(k, { Name = "Sole", Size = { 0.98, 0.2, 1.05 }, Pos = { 0, BG + 0.1, -0.12 }, Color = SOLE, Material = "Rubber" })
	bpost(k, "SoleToe", { 0, BG + 0.1, -0.64 }, 0.2, 0.98, SOLE, "Rubber")
	for i = 0, 3 do
		bpart(k, { Name = "SoleLug", Size = { 1.0, 0.07, 0.1 }, Pos = { 0, BG + 0.05, -0.5 + i * 0.26 }, Color = "#2b1e17", Material = "Rubber" })
	end
	bpart(k, { Name = "Welt", Size = { 1.0, 0.07, 1.07 }, Pos = { 0, BG + 0.235, -0.12 }, Color = WELT, Material = "Leather" })
	bpost(k, "WeltToe", { 0, BG + 0.235, -0.64 }, 0.07, 1.0, WELT, "Leather")
	-- upper: shaft at the back, sloped vamp in front, round toe box + darker toe cap
	bpost(k, "Shaft", { 0, 0.0, 0.14 }, 1.08, 0.82, BOOT, "Fabric")
	bpart(k, { Name = "Vamp", Shape = "Ellipsoid", Size = { 0.84, 1.15, 0.62 }, Pos = VAMP_C, Rot = { VAMP_A, 0, 0 }, Color = BOOT, Material = "Fabric" })
	bpart(k, { Name = "ToeBox", Shape = "Ellipsoid", Size = { 0.92, 0.6, 0.9 }, Pos = { 0, BG + 0.44, -0.58 }, Color = BOOT, Material = "Fabric" })
	bpart(k, { Name = "ToeCap", Shape = "Ellipsoid", Size = { 0.94, 0.48, 0.56 }, Pos = { 0, BG + 0.39, -0.78 }, Color = BOOT_DARK, Material = "Fabric" })
	bpart(k, { Name = "HeelCounter", Shape = "Ellipsoid", Size = { 0.88, 0.56, 0.5 }, Pos = { 0, BG + 0.48, 0.36 }, Color = BOOT_DARK, Material = "Fabric" })
	-- generic side stripe (no logo) and a heel pull loop
	bpart(k, { Name = "SideStripe", Shape = "Ellipsoid", Size = { 0.86, 0.08, 0.6 }, Pos = { 0, BG + 0.62, 0.0 }, Rot = { -12, 0, 0 }, Color = BOOT_DARK, Material = "Leather" })
	-- puffy padded leather collar, fur spilling out of it, small pull tab
	bpart(k, { Name = "Collar", Shape = "Ellipsoid", Size = { 0.98, 0.3, 0.94 }, Pos = { 0, 0.55, 0.12 }, Color = COLLAR, Material = "Leather" })
	bpart(k, { Name = "FurCuff", Shape = "Ellipsoid", Size = { 0.6, 0.28, 0.6 }, Pos = { 0, 0.72, 0.1 }, Color = FUR_DARK, Material = "Fabric" })
	bpart(k, { Name = "PullTab", Size = { 0.14, 0.18, 0.06 }, Pos = { 0, 0.66, 0.6 }, Color = COLLAR, Material = "Leather" })
	-- tongue + criss-cross laces down the sloped front
	local tp = vampFront(0.12, 0, -0.02)
	bpart(k, { Name = "Tongue", Size = { 0.32, 1.0, 0.08 }, Pos = tp, Rot = { VAMP_A, 0, 0 }, Color = BOOT, Material = "Fabric" })
	for i = 0, 2 do
		local v = -0.28 + i * 0.25
		for _, sx in { -1, 1 } do
			bpart(k, { Name = "Eyelet", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = vampFront(v, sx * 0.18, 0.0), Color = EYELET, Material = "Foil" })
		end
		bpart(k, { Name = "Lace", Size = { 0.36, 0.06, 0.06 }, Pos = vampFront(v + 0.03, 0, 0.05), Rot = { VAMP_A, 0, if i % 2 == 0 then 12 else -12 }, Color = LACE })
	end
	-- bow at the top
	for _, sx in { -1, 1 } do
		bpart(k, { Name = "BowLoop", Shape = "Ellipsoid", Size = { 0.2, 0.11, 0.06 }, Pos = vampFront(0.5, sx * 0.11, 0.06), Rot = { VAMP_A, 0, sx * 25 }, Color = LACE })
	end
end

local function buildLeg(k)
	local SW, SP = 3, 0.5
	k:Group({ Name = "Leg", Pos = { 0.62, HIP_Y, 0.1 }, Anim = { Type = "Wiggle", Axis = "X", Amount = SW, Speed = SP } }, function()
		k:Part({ Name = "Thigh", Shape = "Ellipsoid", Size = { 0.62, 1.2, 0.68 }, Pos = { 0, -0.36, 0 }, Color = FUR })
		-- shaggy fur spilling out where the leg leaves the fridge
		k:Part({ Name = "HipFur", Shape = "Ellipsoid", Size = { 0.76, 0.32, 0.8 }, Pos = { 0, -0.14, 0 }, Color = FUR_DARK, Material = "Fabric" })
		for i = 0, 3 do
			local a = math.rad(i * 90 + 45)
			k:Part({ Name = "HipTuft", Shape = "Ellipsoid", Size = { 0.2, 0.26, 0.2 }, Pos = { math.cos(a) * 0.3, -0.27, math.sin(a) * 0.3 }, Color = FUR_DARK, Material = "Fabric" })
		end
		k:Group({ Name = "Knee", Pos = { 0, -0.9, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = -SW * 2, Speed = SP } }, function()
			k:Part({ Name = "KneeKnob", Shape = "Ball", Size = { 0.46, 0.46, 0.46 }, Pos = { 0, 0, -0.02 }, Color = FUR })
			k:Part({ Name = "KneeCallus", Shape = "Ellipsoid", Size = { 0.32, 0.3, 0.2 }, Pos = { 0, -0.01, -0.15 }, Color = CALLUS, Material = "Fabric" })
			k:Part({ Name = "Shin", Shape = "Ellipsoid", Size = { 0.34, 1.05, 0.38 }, Pos = { 0, -0.5, 0.02 }, Color = FUR })
			k:Group({ Name = "Ankle", Pos = { 0, -BG * BS - (HIP_Y - 0.9), 0 }, Rot = { 0, -6, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = SW, Speed = SP } }, function()
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

			k:Light({ Pos = { -0.4, CAV_B + 1.1, -0.6 }, Color = GLOW, Range = 7, Brightness = 1.8 })
			k:Light({ Pos = { 0, FT + 0.8, -1.6 }, Color = "#bfefff", Range = 9, Brightness = 0.8 })
			k:Particles({ Pos = { -1.15, CAV_B + 0.9, -1.4 }, Color = "#dff6ff", Color2 = "#9fdcff", Rate = 5, Size = 0.4, Speed = 0.5, Lifetime = 2, Spread = 30, Direction = "Bottom" })
			k:Particles({ Pos = { 0, FT + 0.25, -0.2 }, Color = "#ffffff", Color2 = GLOW, Rate = 3, Size = 0.15, Speed = 0.6, Lifetime = 2.5, Spread = 80, Direction = "Top" })
		end)
	end,

	BuildMini = function(k)
		-- white fridge body with freezer seam and handle
		k:Part({ Name = "Fridge", Size = { 1.0, 1.32, 0.9 }, Pos = { 0, -0.2, 0.12 }, Color = DOOR })
		k:Part({ Name = "Seam", Size = { 1.02, 0.06, 0.92 }, Pos = { 0, 0.12, 0.12 }, Color = SEAM })
		k:Part({ Name = "Handle", Size = { 0.08, 0.4, 0.1 }, Pos = { -0.36, -0.24, -0.36 }, Color = CHROME, Material = "Metal" })
		-- long neck + camel head with droopy lips
		k:Part({ Name = "Neck", Shape = "Ellipsoid", Size = { 0.34, 0.95, 0.36 }, Pos = { 0, 0.66, -0.08 }, Rot = { -18, 0, 0 }, Color = FUR })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.52, 0.48, 0.9 }, Pos = { 0, 1.07, -0.42 }, Color = FUR })
		k:Part({ Name = "Lips", Shape = "Ellipsoid", Size = { 0.42, 0.32, 0.36 }, Pos = { 0, 0.95, -0.84 }, Color = MUZZLE })
		k:Mirror(function()
			-- round dark eyes bulging from the sides of the head
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.16, 0.16, 0.16 }, Pos = { 0.21, 1.16, -0.5 }, Color = PUPIL })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.36, 0.17, 0.17 }, Pos = { 0.26, -0.98, 0.12 }, Rot = { 0, 0, 90 }, Color = FUR })
			k:Part({ Name = "Boot", Shape = "Ellipsoid", Size = { 0.42, 0.4, 0.64 }, Pos = { 0.26, -1.15, 0.0 }, Color = BOOT })
		end)
	end,
}
