--[[
	Bombardiro Crocodilo (Legendary)
	Canonical look: a green crocodile HEAD (long toothy jaws open, yellow slit-pupil eyes on
	top, scaly bumps, nostril mound) fused onto the front of an olive-drab WWII four-engine
	bomber: riveted fuselage, long wings with four radial engines and black/yellow-tipped
	propellers, glass gun turrets, bombs slung under the belly and wings, a tall swept tail
	fin with stabilisers and the crocodile's own scaly tail sticking out of the tail cone.
	Sits on its landing gear (two main wheels + tail wheel) on y = 0, nose toward -Z.

	Structure: a "Stance" group tilts the whole plane 7 degrees nose-up around the main-wheel
	axles (tail-dragger pose, tail wheel computed to touch y = 0). Inside it, everything above
	the main wheels lives in the "Airframe" group (pivot at the main-gear strut tops) that
	slowly banks. Un-animated offset groups let every part be written in "plane space":
	studs, y up, nose toward -Z, as if the plane sat level.
	Animated: 4 propellers (Spin, phase offsets), lower jaw snap, banking airframe, 4 bombs
	swaying, eye blink, both turrets swivelling, rudder, elevators, crocodile tail, glowing
	engines/exhausts and pulsing nav lights.
]]

-- Palette -----------------------------------------------------------------------------
local OLIVE = "#5d6a32" -- dominant: olive-drab airframe
local OLIVE_DARK = "#454f24" -- panel lines, control surfaces
local OLIVE_LIGHT = "#76844a" -- rivets, highlights
local BELLY_GREY = "#8d927a" -- neutral-grey underside

local CROC = "#4f9d38" -- crocodile skin
local CROC_DARK = "#2e6a26" -- scutes, scales, lip
local CROC_LID = "#3f8a2e" -- heavy reptile eyelids
local CROC_LIGHT = "#72bd4e" -- light scale bumps
local CROC_BELLY = "#d3d886" -- pale throat / jaw underside
local MOUTH = "#a8343f"
local TONGUE = "#de6670"
local TOOTH = "#fff8ec"
local EYE = "#ffd23a"
local PUPIL = "#1b1b24"
local SHINE = "#fffdf5"

local METAL = "#a3a9b1"
local METAL_DARK = "#3b3f47"
local GUNMETAL = "#2b2e35"
local RUBBER = "#24242a"
local PROP = "#26272d"
local PROP_TIP = "#ffcc2e"
local GOLD = "#e8b93a"
local GLASS = "#a6dcff"
local GLASS_DARK = "#36506e"
local GLOW = "#ff8a2a"
local BOMB = "#3c4527"
local BOMB_FIN = "#333b21"
local BOMB_BAND = "#e6c040"
local SQUAD_YELLOW = "#f0c53c" -- generic "croc squadron" roundel: yellow ring, dark ring and a
local SQUAD_DARK = "#26302a" -- croc-green centre (deliberately not a real national insignia)
local IRIS = "#e08a1c"
local GUM = "#c8505c"
local ITA_GREEN = "#1f9e4a"
local ITA_WHITE = "#f4f1e6"
local ITA_RED = "#d8323c"

-- Layout (plane-space studs) ------------------------------------------------------------
local FY = 2.05 -- fuselage axis height
local FR = 0.8 -- fuselage radius
local WY = FY - 0.38 -- wing plane (low-mid wing)
local WING_X, WING_Z, DIHEDRAL = 0.7, 0.3, 4
local PIVOT_Y = 1.42 -- banking pivot = main gear strut tops (inner nacelle underside)
local GX = 1.5 -- main gear x (under the inner nacelles)
local GZ = 0.05
local AXLE_Y = 0.42 -- main wheel axle height
local PITCH = 7 -- tail-dragger stance: the whole plane pivots nose-up around the main axles
local SHIFT_Z = -0.1 -- nudge forward so the pitched model stays centred in the plot
-- tail wheel centre (plane coordinates) so that, after the pitch, it rests on y = 0
local TW_Z = 1.95
local TW_Y = AXLE_Y + (0.2 - AXLE_Y + math.sin(math.rad(PITCH)) * (TW_Z - GZ)) / math.cos(math.rad(PITCH))

-- Head volumes {cx, cy, cz, semiX, semiY, semiZ}
local SKULL = { 0, FY + 0.14, -1.15, 0.86, 0.5, 0.95 }
local SNOUT = { 0, FY + 0.04, -2.05, 0.64, 0.27, 1.12 }
local LIP = { 0, FY - 0.1, -1.98, 0.68, 0.14, 1.1 }
local LJAW = { 0, FY - 0.42, -1.95, 0.57, 0.19, 1.03 }
local NECK = { 0, FY + 0.02, -0.82, 0.83, 0.78, 0.55 } -- thick croc neck plugging into the collar
local HINGE_Y, HINGE_Z = FY - 0.16, -0.95

local function deg(r)
	return r * 180 / math.pi
end

-- y on the top surface of ellipsoid e at (x, z)
local function topY(e, x, z)
	local a = 1 - ((x - e[1]) / e[4]) ^ 2 - ((z - e[3]) / e[6]) ^ 2
	return e[2] + e[5] * math.sqrt(math.max(a, 0))
end

-- highest head surface (skull / neck / snout) at (x, z)
local function headTop(x, z)
	return math.max(topY(SKULL, x, z), topY(NECK, x, z), topY(SNOUT, x, z))
end

-- y on the bottom surface of ellipsoid e at (x, z)
local function bottomY(e, x, z)
	local a = 1 - ((x - e[1]) / e[4]) ^ 2 - ((z - e[3]) / e[6]) ^ 2
	return e[2] - e[5] * math.sqrt(math.max(a, 0))
end

-- half-width of ellipsoid e at its equator for a given z
local function halfW(e, z)
	local a = 1 - ((z - e[3]) / e[6]) ^ 2
	return e[4] * math.sqrt(math.max(a, 0))
end

-- point on ellipsoid e in direction (dx, dy, dz) from its centre, pushed `out` along the normal
local function onEll(e, dx, dy, dz, out)
	local len = math.sqrt((dx / e[4]) ^ 2 + (dy / e[5]) ^ 2 + (dz / e[6]) ^ 2)
	local x, y, z = dx / len, dy / len, dz / len
	local nx, ny, nz = x / (e[4] * e[4]), y / (e[5] * e[5]), z / (e[6] * e[6])
	local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
	return { e[1] + x + nx / nl * out, e[2] + y + ny / nl * out, e[3] + z + nz / nl * out }
end

return {
	Id = "BombardiroCrocodilo",
	Name = "Bombardiro Crocodilo",
	Rarity = "Legendary",
	Emoji = "🐊",
	Color = CROC,
	Tagline = "Half crocodile, half bomber, zero chill.",
	Lore = "Nobody knows who taught a crocodile to fly a WWII bomber, and nobody is brave enough to ask. Bombardiro Crocodilo patrols the skies above the factory with four roaring propellers, snapping jaws and a belly full of bombs. Rumour says the bombs are full of pure brainrot.",

	Build = function(k)
		-- Cylinder (axis X) between two points
		local function rod(name, a, b, d, color, material)
			local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
			local len = math.sqrt(dx * dx + dy * dy + dz * dz)
			local ux, uy, uz = dx / len, dy / len, dz / len
			k:Part({
				Name = name,
				Shape = "Cylinder",
				Size = { len, d, d },
				Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
				Rot = { 0, deg(math.atan2(-uz, ux)), deg(math.asin(math.clamp(uy, -1, 1))) },
				Color = color,
				Material = material or "Metal",
			})
		end

		-- Concentric generic "croc squadron" roundel (not a real national insignia).
		-- Built as cylinders along X, `rot` tilts it.
		local function roundel(name, pos, rot, dia)
			local t = 0.05
			local parts = { { SQUAD_YELLOW, 1 }, { SQUAD_DARK, 0.7 }, { CROC_LIGHT, 0.4 } }
			for i, p in parts do
				-- step each disc slightly outward along its local X
				local r = math.rad(rot[3])
				local off = (i - 1) * 0.008
				k:Part({
					Name = name .. i,
					Shape = "Cylinder",
					Size = { t + off * 2, dia * p[2], dia * p[2] },
					Pos = { pos[1] + math.cos(r) * off, pos[2] + math.sin(r) * off, pos[3] },
					Rot = rot,
					Color = p[1],
				})
			end
		end

		-- A bomb hanging from `pos`, swaying fore/aft around the pylon
		local function bomb(name, pos, s, phase, compact)
			k:Group({ Name = name, Pos = pos, Anim = { Type = "Wiggle", Axis = "X", Amount = 7, Speed = 0.55, Phase = phase } }, function()
				local cy = -0.34 * s
				k:Part({ Name = name .. "Pylon", Size = { 0.07, 0.2 * s, 0.34 * s }, Pos = { 0, -0.07 * s, 0 }, Color = METAL_DARK, Material = "Metal" })
				k:Part({ Name = name .. "Body", Shape = "Ellipsoid", Size = { 0.38 * s, 0.38 * s, 0.98 * s }, Pos = { 0, cy, -0.02 * s }, Color = BOMB })
				k:Part({ Name = name .. "Band", Shape = "Cylinder", Size = { 0.07 * s, 0.39 * s, 0.39 * s }, Pos = { 0, cy, -0.22 * s }, Rot = { 0, 90, 0 }, Color = BOMB_BAND })
				if not compact then
					k:Part({ Name = name .. "Fuse", Shape = "Cylinder", Size = { 0.1 * s, 0.09 * s, 0.09 * s }, Pos = { 0, cy, -0.52 * s }, Rot = { 0, 90, 0 }, Color = METAL, Material = "Metal" })
					k:Part({ Name = name .. "TailCone", Shape = "Cylinder", Size = { 0.3 * s, 0.17 * s, 0.17 * s }, Pos = { 0, cy, 0.5 * s }, Rot = { 0, 90, 0 }, Color = BOMB })
				end
				k:Part({ Name = name .. "FinH", Size = { 0.44 * s, 0.05, 0.24 * s }, Pos = { 0, cy, 0.58 * s }, Color = BOMB_FIN })
				k:Part({ Name = name .. "FinV", Size = { 0.05, 0.44 * s, 0.24 * s }, Pos = { 0, cy, 0.58 * s }, Color = BOMB_FIN })
			end)
		end

		-- Fang: a thin wedge whose triangle shows from the side; side teeth are turned 30
		-- degrees toward the front so the triangle also reads from the 3/4 and front views.
		local function tooth(name, pos, h, up, front)
			local rot
			if front then
				rot = if up then { 0, 90, 0 } else { 0, 90, 180 }
			else
				rot = if up then { 0, 30, 0 } else { 0, 30, 180 }
			end
			local size = if front then { 0.13, h, 0.11 } else { 0.07, h, 0.16 }
			k:Part({ Name = name, Shape = "Wedge", Size = size, Pos = pos, Rot = rot, Color = TOOTH })
		end

		-- One radial engine with cowl, glow, hub and a spinning 3-blade propeller.
		-- Written in wing-local coordinates (x outward along the wing).
		local function engine(name, ex, phase)
			local ey = -0.06
			k:Part({ Name = name .. "Nacelle", Shape = "Ellipsoid", Size = { 0.52, 0.5, 1.55 }, Pos = { ex, ey - 0.01, -0.25 }, Color = OLIVE, Material = "Metal" })
			k:Part({ Name = name .. "Cowl", Shape = "Cylinder", Size = { 0.55, 0.6, 0.6 }, Pos = { ex, ey, -0.92 }, Rot = { 0, 90, 0 }, Color = OLIVE, Material = "Metal" })
			k:Part({ Name = name .. "CowlLip", Shape = "Cylinder", Size = { 0.06, 0.63, 0.63 }, Pos = { ex, ey, -1.2 }, Rot = { 0, 90, 0 }, Color = METAL_DARK, Material = "Metal" })
			k:Part({
				Name = name .. "Glow",
				Shape = "Cylinder",
				Size = { 0.05, 0.44, 0.44 },
				Pos = { ex, ey, -1.225 },
				Rot = { 0, 90, 0 },
				Color = GLOW,
				Material = "Neon",
				Anim = { Type = "Pulse", Amount = 0.08, Speed = 1.3, Phase = phase },
			})
			-- radial engine: dark cylinder heads silhouetted against the hot glow
			for i = 0, 3 do
				local a = math.rad(i * 90 + 45)
				k:Part({ Name = name .. "CylHead", Shape = "Cylinder", Size = { 0.13, 0.08, 0.08 }, Pos = { ex + math.cos(a) * 0.15, ey + math.sin(a) * 0.15, -1.235 }, Rot = { 0, 0, i * 90 + 45 }, Color = METAL_DARK, Material = "Metal" })
			end
			k:Part({ Name = name .. "CowlFlaps", Shape = "Cylinder", Size = { 0.07, 0.56, 0.56 }, Pos = { ex, ey, -0.62 }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK, Material = "Metal" })
			k:Part({ Name = name .. "Hub", Shape = "Ellipsoid", Size = { 0.17, 0.17, 0.26 }, Pos = { ex, ey, -1.3 }, Color = GOLD, Material = "Foil" })
			k:Group({ Name = name .. "Prop", Pos = { ex, ey, -1.28 }, Anim = { Type = "Spin", Axis = "Z", Speed = 1.8, Phase = phase } }, function()
				for i = 0, 2 do
					k:Group({ Name = name .. "Blade" .. i, Rot = { 0, 0, i * 120 + 15 } }, function()
						k:Part({ Name = name .. "Blade", Size = { 0.12, 0.34, 0.05 }, Pos = { 0, 0.24, 0 }, Rot = { 0, 22, 0 }, Color = PROP })
						k:Part({ Name = name .. "BladeTip", Size = { 0.125, 0.1, 0.055 }, Pos = { 0, 0.455, 0 }, Rot = { 0, 22, 0 }, Color = PROP_TIP })
					end)
				end
			end)
			-- turbo exhaust on the outboard side, glowing
			k:Part({ Name = name .. "Exhaust", Shape = "Cylinder", Size = { 0.32, 0.1, 0.1 }, Pos = { ex + 0.2, -0.25, 0.12 }, Rot = { 0, 90, 0 }, Color = METAL_DARK, Material = "Metal" })
			k:Part({
				Name = name .. "ExhaustGlow",
				Shape = "Cylinder",
				Size = { 0.05, 0.09, 0.09 },
				Pos = { ex + 0.2, -0.25, 0.29 },
				Rot = { 0, 90, 0 },
				Color = GLOW,
				Material = "Neon",
				Anim = { Type = "Pulse", Amount = 0.2, Speed = 1.6, Phase = phase + 0.4 },
			})
		end

		---------------------------------------------------------------------------------
		-- Stance: nose-up around the main axles. Inside, coordinates are "plane space".
		---------------------------------------------------------------------------------
		k:Group({ Name = "Stance", Pos = { 0, AXLE_Y, GZ + SHIFT_Z }, Rot = { PITCH, 0, 0 } }, function()
			k:Group({ Name = "PlaneSpace", Pos = { 0, -AXLE_Y, -GZ } }, function()
				---------------------------------------------------------------------------------
				-- Main-gear wheels: they sit exactly on the pitch axis, so they stay put on the ground
				---------------------------------------------------------------------------------
				k:Mirror(function()
					k:Part({ Name = "MainTire", Shape = "Cylinder", Size = { 0.3, 0.84, 0.84 }, Pos = { GX, 0.42, GZ }, Color = RUBBER, Material = "Rubber" })
					k:Part({ Name = "MainHub", Shape = "Cylinder", Size = { 0.32, 0.44, 0.44 }, Pos = { GX, 0.42, GZ }, Color = METAL, Material = "Metal" })
					k:Part({ Name = "MainHubCap", Shape = "Cylinder", Size = { 0.35, 0.16, 0.16 }, Pos = { GX, 0.42, GZ }, Color = GOLD, Material = "Foil" })
					k:Part({ Name = "ForkIn", Size = { 0.06, 0.52, 0.12 }, Pos = { GX - 0.2, 0.68, GZ }, Color = METAL_DARK, Material = "Metal" })
					k:Part({ Name = "ForkOut", Size = { 0.06, 0.52, 0.12 }, Pos = { GX + 0.2, 0.68, GZ }, Color = METAL_DARK, Material = "Metal" })
					k:Part({ Name = "ForkCrown", Size = { 0.46, 0.08, 0.16 }, Pos = { GX, 0.95, GZ }, Color = METAL_DARK, Material = "Metal" })
				end)

				---------------------------------------------------------------------------------
				-- Airframe: everything above the main wheels, slowly banking
				---------------------------------------------------------------------------------
				k:Group({ Name = "Airframe", Pos = { 0, PIVOT_Y, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.2, Speed = 0.35 } }, function()
					k:Group({ Name = "AirframeSpace", Pos = { 0, -PIVOT_Y, 0 } }, function()
						-------------------------------------------------------------------------
						-- Fuselage
						-------------------------------------------------------------------------
						k:Part({ Name = "FuselageMid", Shape = "Cylinder", Size = { 1.87, FR * 2, FR * 2 }, Pos = { 0, FY, 0.315 }, Rot = { 0, 90, 0 }, Color = OLIVE, Material = "Metal" })
						k:Part({ Name = "TailCone", Shape = "Ellipsoid", Size = { 1.58, 1.52, 2.5 }, Pos = { 0, FY + 0.04, 0.95 }, Color = OLIVE, Material = "Metal" })
						k:Part({ Name = "BellyPanel", Shape = "Ellipsoid", Size = { 1.36, 0.42, 2.9 }, Pos = { 0, FY - 0.64, 0.55 }, Color = BELLY_GREY })
						-- tail-cone panel rings (diameter follows the cone)
						for _, rz in { { 1.35, 1.52 }, { 1.75, 1.24 } } do
							k:Part({ Name = "ConeRing", Shape = "Cylinder", Size = { 0.05, rz[2], rz[2] }, Pos = { 0, FY + 0.04, rz[1] }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK })
						end
						k:Mirror(function()
							-- longitudinal rivet rows high and low on the fuselage sides
							for _, a in { 50 } do
							local r = math.rad(a)
							for _, z in { -0.35, 0.02, 0.5, 1.1 } do
									k:Part({ Name = "SideRivet", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { math.cos(r) * (FR + 0.005), FY + math.sin(r) * (FR + 0.005), z }, Color = OLIVE_LIGHT, Material = "Metal" })
								end
							end
							-- longitudinal panel seam
							local sr = math.rad(-15)
							k:Part({ Name = "SideSeam", Size = { 0.05, 0.05, 1.75 }, Pos = { math.cos(sr) * FR, FY + math.sin(sr) * FR, 0.33 }, Rot = { 0, 0, -15 }, Color = OLIVE_DARK })
						end)
						-- panel rings + rivets
						for _, z in { 0.25, 0.95 } do
							k:Part({ Name = "PanelRing", Shape = "Cylinder", Size = { 0.05, FR * 2 + 0.025, FR * 2 + 0.025 }, Pos = { 0, FY, z }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK })

						end
						-- neck collar where crocodile meets bomber
						k:Part({ Name = "NeckCollar", Shape = "Cylinder", Size = { 0.13, FR * 2 + 0.08, FR * 2 + 0.08 }, Pos = { 0, FY, -0.6 }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK, Material = "Metal" })
						for i = 0, 5 do
							local r = math.rad(i * 60 + 30)
							k:Part({ Name = "CollarRivet", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { math.cos(r) * (FR + 0.045), FY + math.sin(r) * (FR + 0.045), -0.6 }, Color = METAL, Material = "Metal" })
						end

						k:Mirror(function()
							-- cockpit side window (sits on the fuselage curve, 30 degrees up)
							k:Part({
								Name = "CockpitWindow",
								Size = { 0.05, 0.22, 0.5 },
								Pos = { math.cos(math.rad(30)) * FR, FY + math.sin(math.rad(30)) * FR, -0.22 },
								Rot = { 0, 0, 30 },
								Color = GLASS_DARK,
								Material = "Glass",
							})
							-- fuselage roundel
							roundel("FuselageRoundel", { 0.78, FY + 0.2, 0.6 }, { 0, 0, 14.5 }, 0.5)
							-- waist gun window + gun
							k:Part({ Name = "WaistWindow", Size = { 0.05, 0.26, 0.38 }, Pos = { 0.73, FY + 0.15, 1.5 }, Rot = { 0, 0, 10 }, Color = GLASS_DARK, Material = "Glass" })
							rod("WaistGun", { 0.66, FY + 0.12, 1.5 }, { 1.05, FY + 0.06, 1.36 }, 0.06, GUNMETAL)
						end)

						-- B-17 style framed cockpit canopy right behind the crocodile's neck
						k:Part({ Name = "Canopy", Shape = "Ellipsoid", Size = { 0.76, 0.52, 0.84 }, Pos = { 0, FY + 0.78, -0.12 }, Color = GLASS_DARK, Material = "Glass", Reflectance = 0.15 })
						for i, fz in { { -0.38, 0.62, 0.36 }, { -0.14, 0.74, 0.5 }, { 0.12, 0.64, 0.38 } } do
							k:Part({ Name = "CanopyFrame" .. i, Shape = "Ellipsoid", Size = { fz[2] + 0.04, fz[3] + 0.04, 0.05 }, Pos = { 0, FY + 0.78, fz[1] }, Color = OLIVE_DARK, Material = "Metal" })
						end
						k:Part({ Name = "CanopySpine", Size = { 0.05, 0.05, 0.4 }, Pos = { 0, FY + 1.02, -0.12 }, Color = OLIVE_DARK, Material = "Metal" })
						k:Part({ Name = "CanopyGlint", Shape = "Ellipsoid", Size = { 0.1, 0.05, 0.2 }, Pos = { 0.17, FY + 0.99, -0.3 }, Rot = { 0, 0, -25 }, Color = SHINE })

						-- top gun turret (swivels)
						k:Group({ Name = "TopTurret", Pos = { 0, FY + FR - 0.04, 0.55 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 28, Speed = 0.25 } }, function()
							k:Part({ Name = "TurretRing", Shape = "Cylinder", Size = { 0.12, 0.7, 0.7 }, Pos = { 0, 0.04, 0 }, Rot = { 0, 0, 90 }, Color = METAL_DARK, Material = "Metal" })
							k:Part({ Name = "TurretDome", Shape = "Ball", Size = { 0.58, 0.58, 0.58 }, Pos = { 0, 0.12, 0 }, Color = GLASS, Material = "Glass", Transparency = 0.35 })
							k:Mirror(function()
								rod("TurretGun", { 0.1, 0.14, -0.2 }, { 0.1, 0.16, -0.66 }, 0.06, GUNMETAL)
							end)
						end)

						-- antenna mast on the canopy + wire to the fin top
						rod("AntennaMast", { 0, FY + 0.98, 0.12 }, { 0, FY + 1.36, 0.22 }, 0.05, METAL_DARK)
						rod("AntennaWire", { 0, FY + 1.36, 0.22 }, { 0, FY + 2.48, 1.56 }, 0.05, METAL_DARK)

						-- ball turret under the belly (swivels)
						k:Group({ Name = "BallTurret", Pos = { 0, FY - 0.7, 1.45 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 40, Speed = 0.2, Phase = 0.5 } }, function()
							k:Part({ Name = "BallMount", Shape = "Cylinder", Size = { 0.12, 0.38, 0.38 }, Pos = { 0, 0, 0 }, Rot = { 0, 0, 90 }, Color = METAL_DARK, Material = "Metal" })
							k:Part({ Name = "BallShell", Shape = "Ball", Size = { 0.5, 0.5, 0.5 }, Pos = { 0, -0.2, 0 }, Color = METAL, Material = "Metal" })
							k:Part({ Name = "BallWindow", Shape = "Ellipsoid", Size = { 0.26, 0.26, 0.1 }, Pos = { 0, -0.2, 0.22 }, Color = GLASS, Material = "Glass", Transparency = 0.2 })
							k:Mirror(function()
								rod("BallGun", { 0.07, -0.24, 0.18 }, { 0.07, -0.34, 0.62 }, 0.05, GUNMETAL)
							end)
						end)

						-- belly bombs
						bomb("BellyBombR", { 0.34, FY - 0.84, 0.3 }, 1, 0)
						bomb("BellyBombL", { -0.34, FY - 0.84, 0.3 }, 1, 0.5)

						-------------------------------------------------------------------------
						-- Crocodile head
						-------------------------------------------------------------------------
						k:Part({ Name = "Neck", Shape = "Ellipsoid", Size = { NECK[4] * 2, NECK[5] * 2, NECK[6] * 2 }, Pos = { NECK[1], NECK[2], NECK[3] }, Color = CROC })
						k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { SKULL[4] * 2, SKULL[5] * 2, SKULL[6] * 2 }, Pos = { SKULL[1], SKULL[2], SKULL[3] }, Color = CROC })
						k:Part({ Name = "Snout", Shape = "Ellipsoid", Size = { SNOUT[4] * 2, SNOUT[5] * 2, SNOUT[6] * 2 }, Pos = { SNOUT[1], SNOUT[2], SNOUT[3] }, Color = CROC })
						k:Part({ Name = "UpperLip", Shape = "Ellipsoid", Size = { LIP[4] * 2, LIP[5] * 2, LIP[6] * 2 }, Pos = { LIP[1], LIP[2], LIP[3] }, Color = CROC_DARK })
						k:Part({ Name = "Palate", Shape = "Ellipsoid", Size = { 1.1, 0.1, 1.95 }, Pos = { 0, FY - 0.22, -1.92 }, Color = MOUTH })
						k:Part({ Name = "Throat", Shape = "Ellipsoid", Size = { 1.4, 0.64, 1.25 }, Pos = { 0, FY - 0.44, -0.82 }, Color = CROC_BELLY })

						-- nostril mound
						local ny = topY(SNOUT, 0, -2.85)
						k:Part({ Name = "NostrilMound", Shape = "Ellipsoid", Size = { 0.46, 0.2, 0.4 }, Pos = { 0, ny - 0.02, -2.85 }, Color = CROC })

						-- osteoderm scutes: a centre row from between the eyes back over the neck
						for i, z in { -1.42, -1.18, -0.95, -0.74 } do
							local w = 0.13 + i * 0.015
							k:Part({ Name = "HeadScuteMid" .. i, Shape = "Ellipsoid", Size = { w, 0.13, 0.2 }, Pos = { 0, headTop(0, z) - 0.02, z }, Color = CROC_DARK })
						end

						k:Mirror(function()
							-- nostrils
							k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.1, 0.06, 0.12 }, Pos = { 0.1, ny + 0.07, -2.9 }, Color = PUPIL })
							-- lumpy snout: two staggered rows of warty bumps
							local bumps = { { 0.15, -2.1 }, { 0.15, -2.45 }, { 0.35, -1.98 }, { 0.35, -2.3 }, { 0.32, -2.62 } }
							for i, b in bumps do
								local col = if i <= 2 then CROC_LIGHT else CROC_DARK
								k:Part({ Name = "SnoutBump" .. i, Shape = "Ellipsoid", Size = { 0.13, 0.08, 0.15 }, Pos = { b[1], topY(SNOUT, b[1], b[2]) - 0.015, b[2] }, Color = col })
							end
							-- paired scute rows behind the eyes and over the neck
							for i, sc in { { 0.27, -1.08 }, { 0.25, -0.86 }, { 0.5, -0.86 } } do
								k:Part({ Name = "HeadScute" .. i, Shape = "Ellipsoid", Size = { 0.16, 0.12, 0.19 }, Pos = { sc[1], headTop(sc[1], sc[2]) - 0.02, sc[2] }, Color = CROC_DARK })
							end
							-- cheek scales
							-- a row of scales along each cheek and the snout side
							local cheeks = {
								{ SKULL, 1, 0.3, -0.55, CROC_DARK },
								{ SKULL, 1, -0.1, -0.22, CROC_LIGHT },
								{ SKULL, 1, 0.25, 0.12, CROC_DARK },
								{ SKULL, 1, -0.2, 0.45, CROC_LIGHT },
								{ SNOUT, 1, 0.45, 0.05, CROC_DARK },
								{ SNOUT, 1, 0.45, -0.4, CROC_DARK },
								{ NECK, 1, 0.3, 0.15, CROC_DARK },
							}
							for i, c in cheeks do
								local p = onEll(c[1], c[2], c[3], c[4], -0.035)
								k:Part({ Name = "CheekScale" .. i, Shape = "Ellipsoid", Size = { 0.1, 0.13, 0.16 }, Pos = p, Color = c[5] })
							end

							-- eye: socket, eyeball, slit pupil, highlight, angry brow
							k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.52, 0.4, 0.56 }, Pos = { 0.4, FY + 0.55, -1.55 }, Color = CROC })
							k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.44, 0.44, 0.44 }, Pos = { 0.41, FY + 0.66, -1.66 }, Color = EYE, Anim = { Type = "Blink", Speed = 0.22 } })
							k:Part({ Name = "Iris", Shape = "Cylinder", Size = { 0.05, 0.3, 0.3 }, Pos = { 0.478, FY + 0.652, -1.845 }, Rot = { 0, 70, 0 }, Color = IRIS, Anim = { Type = "Blink", Speed = 0.22 } })
							k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.08, 0.3, 0.06 }, Pos = { 0.485, FY + 0.65, -1.865 }, Rot = { 0, -20, 0 }, Color = PUPIL, Anim = { Type = "Blink", Speed = 0.22 } })
							k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.09, 0.09, 0.09 }, Pos = { 0.36, FY + 0.7, -1.86 }, Color = SHINE, Anim = { Type = "Blink", Speed = 0.22 } })
							-- heavy upper lid wrapping the top of the eyeball, slanted down toward the
							-- middle for the menacing crocodile glare
							k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.49, 0.3, 0.5 }, Pos = { 0.4, FY + 0.8, -1.64 }, Rot = { -8, 0, 16 }, Color = CROC_LID })

							-- upper teeth (pointing down) along the lip
							for i = 1, 6 do
								local z = -1.3 - (i - 1) * 0.31
								local h = if i == 5 then 0.3 else 0.22
								local x = halfW(LIP, z) - 0.07
								tooth("UpperTooth" .. i, { x, bottomY(LIP, x, z) + 0.03 - h / 2, z }, h, false, false)
							end
							tooth("UpperFrontTooth", { 0.13, bottomY(LIP, 0.13, -2.94) + 0.03 - 0.1, -2.94 }, 0.2, false, true)
						end)

						-- lower jaw: hinged at the back of the mouth, open and snapping
						k:Group({ Name = "LowerJaw", Pos = { 0, HINGE_Y, HINGE_Z }, Rot = { -16, 0, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 9, Speed = 0.7 } }, function()
							k:Group({ Name = "JawSpace", Pos = { 0, -HINGE_Y, -HINGE_Z } }, function()
								k:Part({ Name = "Jaw", Shape = "Ellipsoid", Size = { LJAW[4] * 2, LJAW[5] * 2, LJAW[6] * 2 }, Pos = { LJAW[1], LJAW[2], LJAW[3] }, Color = CROC })
								k:Part({ Name = "JawUnder", Shape = "Ellipsoid", Size = { 0.98, 0.26, 1.85 }, Pos = { 0, FY - 0.52, -1.85 }, Color = CROC_BELLY })
								k:Part({ Name = "MouthFloor", Shape = "Ellipsoid", Size = { 0.98, 0.08, 1.85 }, Pos = { 0, FY - 0.25, -1.92 }, Color = MOUTH })
								k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.5, 0.12, 0.95 }, Pos = { 0, FY - 0.23, -1.6 }, Color = TONGUE })
								k:Mirror(function()
									for i = 1, 5 do
										local z = -1.45 - (i - 1) * 0.3
										local h = if i == 4 then 0.26 else 0.2
										local x = halfW(LJAW, z) - 0.07
										tooth("LowerTooth" .. i, { x, topY(LJAW, x, z) - 0.03 + h / 2, z }, h, true, false)
									end
									tooth("LowerFrontTooth", { 0.13, topY(LJAW, 0.13, -2.84) - 0.03 + 0.09, -2.84 }, 0.18, true, true)
								end)
							end)
						end)

						-------------------------------------------------------------------------
						-- Wings with engines (dihedral), written once and mirrored
						-------------------------------------------------------------------------
						k:Mirror(function()
							k:Group({ Name = "Wing", Pos = { WING_X, WY, WING_Z }, Rot = { 0, 0, DIHEDRAL } }, function()
								k:Part({ Name = "WingMain", Size = { 2.3, 0.17, 0.98 }, Pos = { 1.15, 0, 0.21 }, Color = OLIVE, Material = "Metal" })
								k:Part({ Name = "WingLeadingEdge", Shape = "Wedge", Size = { 0.17, 2.3, 0.47 }, Pos = { 1.15, 0, -0.515 }, Rot = { 0, 0, -90 }, Color = OLIVE, Material = "Metal" })
								k:Part({ Name = "WingTip", Shape = "Ellipsoid", Size = { 0.3, 0.15, 0.98 }, Pos = { 2.3, 0, 0.21 }, Color = OLIVE, Material = "Metal" })
								k:Part({ Name = "Flap", Size = { 1.0, 0.1, 0.2 }, Pos = { 0.55, -0.01, 0.8 }, Color = OLIVE_DARK })
								k:Part({ Name = "Aileron", Size = { 1.1, 0.1, 0.2 }, Pos = { 1.72, -0.01, 0.8 }, Color = OLIVE_DARK })
								roundel("WingRoundel", { 2.02, 0.09, 0.42 }, { 0, 0, 90 }, 0.46)
								k:Part({ Name = "WingSeam", Size = { 2.2, 0.05, 0.05 }, Pos = { 1.15, 0.075, 0.02 }, Color = OLIVE_DARK })

								engine("InnerEngine", 0.78, 0)
								engine("OuterEngine", 1.8, 0.31)
								bomb("WingBomb", { 1.29, -0.09, 0.12 }, 0.75, 0.25, true)

								-- exhaust smoke from the inner engines
								k:Particles({ Pos = { 0.98, -0.25, 0.4 }, Color = "#8c8c8c", Color2 = "#ece8df", Rate = 6, Size = 0.35, Speed = 1.4, Lifetime = 1.3, Spread = 12, Direction = "Back" })
							end)

							-- main gear strut, brace and door (move with the airframe)
							rod("GearPiston", { GX, 0.95, GZ }, { GX, 1.16, GZ }, 0.09, METAL, "Foil")
							rod("GearSleeve", { GX, 1.1, GZ }, { GX, 1.46, GZ - 0.02 }, 0.15, METAL_DARK)
							rod("GearBrace", { GX, 1.04, GZ }, { GX, 1.42, 0.42 }, 0.07, METAL_DARK)
						end)

						-- wingtip navigation lights (starboard green on +X, port red on -X)
						local tipX = WING_X + 2.42 * math.cos(math.rad(DIHEDRAL))
						local tipY = WY + 2.42 * math.sin(math.rad(DIHEDRAL))
						k:Part({ Name = "NavLightStarboard", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = { tipX - 0.02, tipY, 0.5 }, Color = "#3dff7a", Material = "Neon", Anim = { Type = "Pulse", Amount = 0.25, Speed = 0.8 } })
						k:Part({ Name = "NavLightPort", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = { -(tipX - 0.02), tipY, 0.5 }, Color = "#ff3d4a", Material = "Neon", Anim = { Type = "Pulse", Amount = 0.25, Speed = 0.8, Phase = 0.5 } })

						-------------------------------------------------------------------------
						-- Tail: swept fin with tricolore flash, rudder, stabilisers, croc tail
						-------------------------------------------------------------------------
						local TZ = -0.15 -- tail surfaces moved forward to leave room for the croc tail
						k:Part({ Name = "FinFront", Shape = "Wedge", Size = { 0.14, 2.55, 1.35 }, Pos = { 0, FY + 0.1 + 1.275, 1.005 + TZ }, Color = OLIVE, Material = "Metal" })
						k:Part({ Name = "FinRear", Size = { 0.14, 2.55, 0.55 }, Pos = { 0, FY + 0.1 + 1.275, 1.955 + TZ }, Color = OLIVE, Material = "Metal" })
						k:Part({ Name = "FinCap", Shape = "Ellipsoid", Size = { 0.15, 0.24, 0.8 }, Pos = { 0, FY + 2.65, 1.9 + TZ }, Color = OLIVE, Material = "Metal" })
						k:Mirror(function()
							for i, c in { ITA_GREEN, ITA_WHITE, ITA_RED } do
								k:Part({ Name = "FinFlash" .. i, Size = { 0.05, 1.0, 0.18 }, Pos = { 0.07, FY + 1.85, 1.77 + TZ + (i - 1) * 0.18 }, Color = c })
							end
													end)
						k:Group({ Name = "Rudder", Pos = { 0, FY + 1.5, 2.23 + TZ }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.4 } }, function()
							k:Part({ Name = "RudderPanel", Size = { 0.12, 2.1, 0.28 }, Pos = { 0, 0, 0.14 }, Color = OLIVE_DARK })
							k:Part({ Name = "RudderTrim", Size = { 0.13, 0.5, 0.05 }, Pos = { 0, -0.6, 0.26 }, Color = METAL_DARK, Material = "Metal" })
						end)
						k:Mirror(function()
							k:Part({ Name = "StabMain", Size = { 1.1, 0.1, 0.5 }, Pos = { 0.65, FY + 0.16, 1.95 + TZ }, Color = OLIVE, Material = "Metal" })
							k:Part({ Name = "StabLeadingEdge", Shape = "Wedge", Size = { 0.1, 1.1, 0.3 }, Pos = { 0.65, FY + 0.16, 1.55 + TZ }, Rot = { 0, 0, -90 }, Color = OLIVE, Material = "Metal" })
							k:Part({ Name = "StabTip", Shape = "Ellipsoid", Size = { 0.2, 0.1, 0.5 }, Pos = { 1.2, FY + 0.16, 1.95 + TZ }, Color = OLIVE, Material = "Metal" })
							k:Group({ Name = "Elevator", Pos = { 0, FY + 0.16, 2.2 + TZ }, Anim = { Type = "Wiggle", Axis = "X", Amount = 8, Speed = 0.4, Phase = 0.25 } }, function()
								k:Part({ Name = "ElevatorPanel", Size = { 0.88, 0.07, 0.2 }, Pos = { 0.76, 0, 0.1 }, Color = OLIVE_DARK })
							end)
						end)

						-- tail cone collar + the crocodile's own tail (laterally flat, scute crest, pale belly),
						-- two jointed sections that swish with a delay
						k:Part({ Name = "TailCollar", Shape = "Cylinder", Size = { 0.08, 0.84, 0.84 }, Pos = { 0, FY + 0.03, 2.02 }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK, Material = "Metal" })

						local TB = { 0, 0, 0.18, 0.28, 0.29, 0.31 } -- tail base ellipsoid (CrocTail group space)
						local TM = { 0, -0.03, 0.47, 0.22, 0.23, 0.25 }
						k:Group({ Name = "CrocTail", Pos = { 0, FY - 0.03, 1.95 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 9, Speed = 0.5 } }, function()
							k:Part({ Name = "TailBase", Shape = "Ellipsoid", Size = { TB[4] * 2, TB[5] * 2, TB[6] * 2 }, Pos = { TB[1], TB[2], TB[3] }, Color = CROC })
							k:Part({ Name = "TailMid", Shape = "Ellipsoid", Size = { TM[4] * 2, TM[5] * 2, TM[6] * 2 }, Pos = { TM[1], TM[2], TM[3] }, Color = CROC })
							k:Part({ Name = "TailBelly", Shape = "Ellipsoid", Size = { 0.4, 0.26, 0.78 }, Pos = { 0, -0.17, 0.32 }, Color = CROC_BELLY })
							k:Mirror(function()
								-- double crest of upright scutes
								for i, z in { 0.04, 0.2, 0.36, 0.52 } do
									local top = math.max(topY(TB, 0.08, z), topY(TM, 0.08, z))
									local h = 0.17 - i * 0.015
									k:Part({ Name = "TailScute" .. i, Shape = "Wedge", Size = { 0.05, h, 0.14 }, Pos = { 0.08, top + h / 2 - 0.05, z }, Color = CROC_DARK })
								end
								-- side scale rows
								for i, sc in { { TB, 0.06, 0.18 }, { TB, -0.1, 0.22 }, { TM, 0.02, 0.45 } } do
									local e = sc[1]
									k:Part({ Name = "TailSideScale" .. i, Shape = "Ellipsoid", Size = { 0.06, 0.12, 0.15 }, Pos = { halfW(e, sc[3]) - 0.015, e[2] + sc[2], sc[3] }, Color = if i == 2 then CROC_LIGHT else CROC_DARK })
								end
							end)
							k:Group({ Name = "TailTip", Pos = { 0, -0.04, 0.68 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 16, Speed = 0.5, Phase = 0.18 } }, function()
								local TE1 = { 0, 0, 0.1, 0.17, 0.18, 0.21 }
								local TE2 = { 0, 0.01, 0.28, 0.1, 0.12, 0.18 }
								k:Part({ Name = "TailEnd1", Shape = "Ellipsoid", Size = { TE1[4] * 2, TE1[5] * 2, TE1[6] * 2 }, Pos = { TE1[1], TE1[2], TE1[3] }, Color = CROC })
								k:Part({ Name = "TailEnd2", Shape = "Ellipsoid", Size = { TE2[4] * 2, TE2[5] * 2, TE2[6] * 2 }, Pos = { TE2[1], TE2[2], TE2[3] }, Color = CROC })
								for i, z in { 0.0, 0.14, 0.28 } do
									local h = 0.15 - i * 0.02
									local top = math.max(topY(TE1, 0, z), topY(TE2, 0, z))
									k:Part({ Name = "TailTipScute" .. i, Shape = "Wedge", Size = { 0.05, h, 0.13 }, Pos = { 0, top + h / 2 - 0.05, z }, Color = CROC_DARK })
								end
							end)
						end)

						-- tail wheel
						k:Part({ Name = "TailTire", Shape = "Cylinder", Size = { 0.15, 0.4, 0.4 }, Pos = { 0, TW_Y, TW_Z }, Color = RUBBER, Material = "Rubber" })
						k:Mirror(function()
							k:Part({ Name = "TailFork", Size = { 0.05, 0.34, 0.08 }, Pos = { 0.1, TW_Y + 0.14, TW_Z }, Color = METAL_DARK, Material = "Metal" })
						end)
						rod("TailStrut", { 0, TW_Y + 0.3, TW_Z }, { 0, 1.62, 1.82 }, 0.1, METAL_DARK)
					end)
				end)
			end)
		end)

		-- Legendary flair: warm engine glow + face light, golden sparkle
		k:Light({ Pos = { 0, WY, -1.7 }, Color = GLOW, Range = 8, Brightness = 1.2 })
		k:Light({ Pos = { 0, FY + 1.3, -2.3 }, Color = "#ffe39a", Range = 7, Brightness = 0.8 })
		k:Particles({ Pos = { 0, FY + 1.3, -1.0 }, Color = GOLD, Color2 = "#fff3b0", Rate = 3, Size = 0.18, Speed = 0.6, Lifetime = 1.6, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Part({ Name = "Fuselage", Shape = "Ellipsoid", Size = { 0.74, 0.72, 1.9 }, Pos = { 0, 0.05, 0.35 }, Color = OLIVE })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.8, 0.4, 1.25 }, Pos = { 0, 0.1, -0.68 }, Color = CROC })
		k:Part({ Name = "TeethRim", Shape = "Ellipsoid", Size = { 0.74, 0.1, 1.12 }, Pos = { 0, -0.06, -0.72 }, Color = TOOTH })
		k:Part({ Name = "LowerJaw", Shape = "Ellipsoid", Size = { 0.62, 0.22, 1.0 }, Pos = { 0, -0.2, -0.66 }, Rot = { -12, 0, 0 }, Color = CROC })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = { 0.2, 0.3, -0.72 }, Color = EYE })
			k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.06, 0.2, 0.06 }, Pos = { 0.215, 0.3, -0.85 }, Color = PUPIL })
			k:Part({ Name = "Prop", Shape = "Cylinder", Size = { 0.06, 0.5, 0.5 }, Pos = { 0.86, -0.1, -0.1 }, Rot = { 0, 90, 0 }, Color = "#3a3b42", Transparency = 0.35 })
		end)
		k:Part({ Name = "Wing", Size = { 2.5, 0.08, 0.5 }, Pos = { 0, -0.1, 0.25 }, Color = OLIVE })
		k:Part({ Name = "Fin", Shape = "Wedge", Size = { 0.08, 0.62, 0.55 }, Pos = { 0, 0.62, 1.0 }, Color = OLIVE })
	end,
}
