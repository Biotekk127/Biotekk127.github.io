--[[
	Bombardiro Crocodilo (Legendary)
	Canonical look: a green crocodile HEAD (long toothy jaws open, yellow slit-pupil eyes on
	top, scaly bumps, nostril mound) fused onto the front of an olive-drab WWII four-engine
	bomber: riveted fuselage, long wings with four radial engines and black/yellow-tipped
	propellers, glass gun turrets, bombs slung under the belly and wings, a tall swept tail
	fin with stabilisers and the crocodile's own scaly tail sticking out of the tail cone.
	Sits on its landing gear (two main wheels + tail wheel) on y = 0, nose toward -Z.

	Coordinates are world studs. Everything above the gear lives in the "Airframe" group
	(pivot at the main-gear strut tops) that slowly banks; an un-animated offset group
	inside it lets every part be written in world coordinates.
]]

-- Palette -----------------------------------------------------------------------------
local OLIVE = "#5d6a32" -- dominant: olive-drab airframe
local OLIVE_DARK = "#454f24" -- panel lines, control surfaces
local OLIVE_LIGHT = "#76844a" -- rivets, highlights
local BELLY_GREY = "#8d927a" -- neutral-grey underside

local CROC = "#4f9d38" -- crocodile skin
local CROC_DARK = "#2e6a26" -- scutes, brows, scales
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
local RUBBER_LIGHT = "#33333b"
local PROP = "#26272d"
local PROP_TIP = "#ffcc2e"
local GOLD = "#e8b93a"
local GLASS = "#a6dcff"
local GLASS_DARK = "#36506e"
local GLOW = "#ff8a2a"
local BOMB = "#3c4527"
local BOMB_FIN = "#333b21"
local BOMB_BAND = "#e6c040"
local ITA_GREEN = "#1f9e4a"
local ITA_WHITE = "#f4f1e6"
local ITA_RED = "#d8323c"

-- Layout (world studs) -------------------------------------------------------------------
local FY = 2.05 -- fuselage axis height
local FR = 0.8 -- fuselage radius
local WY = FY - 0.38 -- wing plane (low-mid wing)
local WING_X, WING_Z, DIHEDRAL = 0.7, 0.3, 4
local PIVOT_Y = 1.42 -- banking pivot = main gear strut tops (inner nacelle underside)
local GX = 1.5 -- main gear x (under the inner nacelles)
local GZ = 0.05

-- Head volumes {cx, cy, cz, semiX, semiY, semiZ}
local SKULL = { 0, FY + 0.16, -1.2, 0.92, 0.52, 0.85 }
local SNOUT = { 0, FY + 0.04, -2.05, 0.62, 0.27, 1.12 }
local LIP = { 0, FY - 0.1, -1.98, 0.66, 0.14, 1.1 }
local LJAW = { 0, FY - 0.42, -1.95, 0.57, 0.19, 1.03 }
local HINGE_Y, HINGE_Z = FY - 0.16, -0.95

local function deg(r)
	return r * 180 / math.pi
end

-- y on the top surface of ellipsoid e at (x, z)
local function topY(e, x, z)
	local a = 1 - ((x - e[1]) / e[4]) ^ 2 - ((z - e[3]) / e[6]) ^ 2
	return e[2] + e[5] * math.sqrt(math.max(a, 0))
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

		-- Concentric tricolore roundel. Built as cylinders along X, `rot` tilts it.
		local function roundel(name, pos, rot, dia)
			local t = 0.05
			local parts = { { ITA_GREEN, 1 }, { ITA_WHITE, 0.66 }, { ITA_RED, 0.33 } }
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
			k:Part({ Name = name .. "Nacelle", Shape = "Ellipsoid", Size = { 0.52, 0.5, 1.55 }, Pos = { ex, ey - 0.01, -0.25 }, Color = OLIVE })
			k:Part({ Name = name .. "Cowl", Shape = "Cylinder", Size = { 0.55, 0.6, 0.6 }, Pos = { ex, ey, -0.92 }, Rot = { 0, 90, 0 }, Color = OLIVE })
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
		-- Static main-gear wheels (world)
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
			k:Group({ Name = "World", Pos = { 0, -PIVOT_Y, 0 } }, function()
				-------------------------------------------------------------------------
				-- Fuselage
				-------------------------------------------------------------------------
				k:Part({ Name = "FuselageMid", Shape = "Cylinder", Size = { 2.0, FR * 2, FR * 2 }, Pos = { 0, FY, 0.25 }, Rot = { 0, 90, 0 }, Color = OLIVE })
				k:Part({ Name = "FuselageNose", Shape = "Ellipsoid", Size = { FR * 2, FR * 2, 1.2 }, Pos = { 0, FY, -0.7 }, Color = OLIVE })
				k:Part({ Name = "TailCone", Shape = "Ellipsoid", Size = { 1.58, 1.52, 2.7 }, Pos = { 0, FY + 0.04, 1.0 }, Color = OLIVE })
				k:Part({ Name = "BellyPanel", Shape = "Ellipsoid", Size = { 1.36, 0.42, 2.9 }, Pos = { 0, FY - 0.64, 0.55 }, Color = BELLY_GREY })
				-- panel rings + rivets
				for _, z in { 0.25, 0.95 } do
					k:Part({ Name = "PanelRing", Shape = "Cylinder", Size = { 0.05, FR * 2 + 0.025, FR * 2 + 0.025 }, Pos = { 0, FY, z }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK })
					for _, a in { 25, 90, 155 } do
						local r = math.rad(a)
						k:Part({ Name = "Rivet", Shape = "Ball", Size = { 0.06, 0.06, 0.06 }, Pos = { math.cos(r) * (FR + 0.01), FY + math.sin(r) * (FR + 0.01), z - 0.08 }, Color = OLIVE_LIGHT, Material = "Metal" })
					end
				end
				-- neck collar where crocodile meets bomber
				k:Part({ Name = "NeckCollar", Shape = "Cylinder", Size = { 0.13, FR * 2 + 0.08, FR * 2 + 0.08 }, Pos = { 0, FY, -0.6 }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK, Material = "Metal" })
				for i = 0, 5 do
					local r = math.rad(i * 60 + 30)
					k:Part({ Name = "CollarRivet", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { math.cos(r) * (FR + 0.045), FY + math.sin(r) * (FR + 0.045), -0.6 }, Color = METAL, Material = "Metal" })
				end

				k:Mirror(function()
					-- cockpit side windows
					local wa = 30
					for i, z in { -0.36, -0.08 } do
						k:Part({
							Name = "CockpitWindow" .. i,
							Size = { 0.05, 0.22, 0.24 },
							Pos = { math.cos(math.rad(wa)) * FR, FY + math.sin(math.rad(wa)) * FR, z },
							Rot = { 0, 0, wa },
							Color = GLASS_DARK,
							Material = "Glass",
						})
					end
					-- fuselage roundel
					roundel("FuselageRoundel", { 0.78, FY + 0.2, 0.6 }, { 0, 0, 14.5 }, 0.5)
					-- waist gun window + gun
					k:Part({ Name = "WaistWindow", Size = { 0.05, 0.26, 0.38 }, Pos = { 0.73, FY + 0.15, 1.5 }, Rot = { 0, 0, 10 }, Color = GLASS_DARK, Material = "Glass" })
					rod("WaistGun", { 0.66, FY + 0.12, 1.5 }, { 1.05, FY + 0.06, 1.36 }, 0.06, GUNMETAL)
				end)

				-- top gun turret (swivels)
				k:Group({ Name = "TopTurret", Pos = { 0, FY + FR - 0.04, -0.18 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 28, Speed = 0.25 } }, function()
					k:Part({ Name = "TurretRing", Shape = "Cylinder", Size = { 0.12, 0.7, 0.7 }, Pos = { 0, 0.04, 0 }, Rot = { 0, 0, 90 }, Color = METAL_DARK, Material = "Metal" })
					k:Part({ Name = "TurretDome", Shape = "Ball", Size = { 0.58, 0.58, 0.58 }, Pos = { 0, 0.12, 0 }, Color = GLASS, Material = "Glass", Transparency = 0.35 })
					k:Mirror(function()
						rod("TurretGun", { 0.1, 0.14, -0.2 }, { 0.1, 0.16, -0.66 }, 0.06, GUNMETAL)
					end)
				end)

				-- antenna mast + wire to the fin
				rod("AntennaMast", { 0, FY + FR - 0.02, 0.3 }, { 0, FY + 1.25, 0.42 }, 0.05, METAL_DARK)
				rod("AntennaWire", { 0, FY + 1.25, 0.42 }, { 0, FY + 2.4, 1.78 }, 0.05, METAL_DARK)

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
				k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { SKULL[4] * 2, SKULL[5] * 2, SKULL[6] * 2 }, Pos = { SKULL[1], SKULL[2], SKULL[3] }, Color = CROC })
				k:Part({ Name = "Snout", Shape = "Ellipsoid", Size = { SNOUT[4] * 2, SNOUT[5] * 2, SNOUT[6] * 2 }, Pos = { SNOUT[1], SNOUT[2], SNOUT[3] }, Color = CROC })
				k:Part({ Name = "UpperLip", Shape = "Ellipsoid", Size = { LIP[4] * 2, LIP[5] * 2, LIP[6] * 2 }, Pos = { LIP[1], LIP[2], LIP[3] }, Color = CROC_DARK })
				k:Part({ Name = "Palate", Shape = "Ellipsoid", Size = { 1.1, 0.1, 1.95 }, Pos = { 0, FY - 0.22, -1.92 }, Color = MOUTH })
				k:Part({ Name = "Throat", Shape = "Ellipsoid", Size = { 1.4, 0.64, 1.25 }, Pos = { 0, FY - 0.44, -0.82 }, Color = CROC_BELLY })

				-- nostril mound
				local ny = topY(SNOUT, 0, -2.85)
				k:Part({ Name = "NostrilMound", Shape = "Ellipsoid", Size = { 0.46, 0.2, 0.4 }, Pos = { 0, ny - 0.02, -2.85 }, Color = CROC })

				-- center scute row on the skull
				for i, z in { -0.95, -0.68 } do
					k:Part({ Name = "HeadScuteMid" .. i, Shape = "Ellipsoid", Size = { 0.16, 0.12, 0.2 }, Pos = { 0, topY(SKULL, 0, z) - 0.01, z }, Color = CROC_DARK })
				end

				k:Mirror(function()
					-- nostrils
					k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.1, 0.06, 0.12 }, Pos = { 0.1, ny + 0.07, -2.9 }, Color = PUPIL })
					-- snout bumps
					for i, z in { -1.6, -2.0, -2.4 } do
						k:Part({ Name = "SnoutBump" .. i, Shape = "Ellipsoid", Size = { 0.14, 0.09, 0.18 }, Pos = { 0.24, topY(SNOUT, 0.24, z) - 0.01, z }, Color = CROC_DARK })
					end
					-- skull scutes behind the eyes
					for i, z in { -0.95, -0.68 } do
						k:Part({ Name = "HeadScute" .. i, Shape = "Ellipsoid", Size = { 0.15, 0.11, 0.19 }, Pos = { 0.26, topY(SKULL, 0.26, z) - 0.01, z }, Color = CROC_DARK })
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
					}
					for i, c in cheeks do
						local p = onEll(c[1], c[2], c[3], c[4], -0.03)
						k:Part({ Name = "CheekScale" .. i, Shape = "Ellipsoid", Size = { 0.12, 0.14, 0.17 }, Pos = p, Color = c[5] })
					end

					-- eye: socket, eyeball, slit pupil, highlight, angry brow
					k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.58, 0.5, 0.6 }, Pos = { 0.43, FY + 0.62, -1.56 }, Color = CROC })
					k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.46, 0.46, 0.46 }, Pos = { 0.44, FY + 0.72, -1.68 }, Color = EYE, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.08, 0.3, 0.06 }, Pos = { 0.515, FY + 0.72, -1.89 }, Rot = { 0, -20, 0 }, Color = PUPIL, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { 0.41, FY + 0.83, -1.86 }, Color = SHINE, Anim = { Type = "Blink", Speed = 0.22 } })
					k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.54, 0.16, 0.46 }, Pos = { 0.45, FY + 0.92, -1.62 }, Rot = { -15, 0, 14 }, Color = CROC_DARK })

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
						k:Part({ Name = "WingMain", Size = { 2.3, 0.17, 0.98 }, Pos = { 1.15, 0, 0.21 }, Color = OLIVE })
						k:Part({ Name = "WingLeadingEdge", Shape = "Wedge", Size = { 0.17, 2.3, 0.47 }, Pos = { 1.15, 0, -0.515 }, Rot = { 0, 0, -90 }, Color = OLIVE })
						k:Part({ Name = "WingTip", Shape = "Ellipsoid", Size = { 0.3, 0.15, 0.98 }, Pos = { 2.3, 0, 0.21 }, Color = OLIVE })
						k:Part({ Name = "Flap", Size = { 1.0, 0.1, 0.2 }, Pos = { 0.55, -0.01, 0.8 }, Color = OLIVE_DARK })
						k:Part({ Name = "Aileron", Size = { 1.1, 0.1, 0.2 }, Pos = { 1.72, -0.01, 0.8 }, Color = OLIVE_DARK })
						roundel("WingRoundel", { 2.02, 0.09, 0.42 }, { 0, 0, 90 }, 0.46)

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
				k:Part({ Name = "FinFront", Shape = "Wedge", Size = { 0.14, 2.3, 1.3 }, Pos = { 0, FY + 0.2 + 1.15, 1.03 }, Color = OLIVE })
				k:Part({ Name = "FinRear", Size = { 0.14, 2.3, 0.55 }, Pos = { 0, FY + 0.2 + 1.15, 1.955 }, Color = OLIVE })
				k:Part({ Name = "FinCap", Shape = "Ellipsoid", Size = { 0.15, 0.24, 0.8 }, Pos = { 0, FY + 2.5, 1.9 }, Color = OLIVE })
				k:Mirror(function()
					for i, c in { ITA_GREEN, ITA_WHITE, ITA_RED } do
						k:Part({ Name = "FinFlash" .. i, Size = { 0.05, 1.0, 0.18 }, Pos = { 0.07, FY + 1.75, 1.77 + (i - 1) * 0.18 }, Color = c })
					end
				end)
				k:Group({ Name = "Rudder", Pos = { 0, FY + 1.42, 2.23 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 12, Speed = 0.4 } }, function()
					k:Part({ Name = "RudderPanel", Size = { 0.12, 1.95, 0.28 }, Pos = { 0, 0, 0.14 }, Color = OLIVE_DARK })
				end)
				k:Mirror(function()
					k:Part({ Name = "StabMain", Size = { 1.1, 0.1, 0.5 }, Pos = { 0.65, FY + 0.16, 1.95 }, Color = OLIVE })
					k:Part({ Name = "StabLeadingEdge", Shape = "Wedge", Size = { 0.1, 1.1, 0.3 }, Pos = { 0.65, FY + 0.16, 1.55 }, Rot = { 0, 0, -90 }, Color = OLIVE })
					k:Part({ Name = "StabTip", Shape = "Ellipsoid", Size = { 0.2, 0.1, 0.5 }, Pos = { 1.2, FY + 0.16, 1.95 }, Color = OLIVE })
					k:Group({ Name = "Elevator", Pos = { 0, FY + 0.16, 2.2 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 8, Speed = 0.4, Phase = 0.25 } }, function()
						k:Part({ Name = "ElevatorPanel", Size = { 1.05, 0.07, 0.2 }, Pos = { 0.65, 0, 0.1 }, Color = OLIVE_DARK })
					end)
				end)

				-- tail cone collar + the crocodile's own tail
				k:Part({ Name = "TailCollar", Shape = "Cylinder", Size = { 0.07, 0.64, 0.64 }, Pos = { 0, FY - 0.02, 2.2 }, Rot = { 0, 90, 0 }, Color = OLIVE_DARK, Material = "Metal" })
				k:Group({ Name = "CrocTail", Pos = { 0, FY - 0.04, 2.12 }, Anim = { Type = "Wiggle", Axis = "Y", Amount = 14, Speed = 0.5 } }, function()
					local segs = {
						{ 0.56, 0.5, 0.62, 0, 0.12 },
						{ 0.44, 0.4, 0.52, 0.04, 0.42 },
						{ 0.34, 0.3, 0.44, 0.1, 0.66 },
						{ 0.22, 0.2, 0.32, 0.17, 0.85 },
					}
					for i, s in segs do
						k:Part({ Name = "TailSeg" .. i, Shape = "Ellipsoid", Size = { s[1], s[2], s[3] }, Pos = { 0, s[4], s[5] }, Color = CROC })
						if i < 4 then
							k:Part({ Name = "TailSpike" .. i, Shape = "Wedge", Size = { 0.07, 0.16 - i * 0.02, 0.18 }, Pos = { 0, s[4] + s[2] / 2 + 0.03, s[5] }, Color = CROC_DARK })
						end
					end
					k:Mirror(function()
						for i = 1, 2 do
							local s = segs[i]
							k:Part({ Name = "TailSideSpike" .. i, Shape = "Wedge", Size = { 0.06, 0.12, 0.15 }, Pos = { s[1] * 0.28, s[4] + s[2] * 0.4, s[5] }, Rot = { 0, 0, -25 }, Color = CROC_DARK })
						end
					end)
				end)

				-- tail wheel
				k:Part({ Name = "TailTire", Shape = "Cylinder", Size = { 0.15, 0.4, 0.4 }, Pos = { 0, 0.2, 1.95 }, Color = RUBBER, Material = "Rubber" })
				k:Part({ Name = "TailHub", Shape = "Cylinder", Size = { 0.17, 0.2, 0.2 }, Pos = { 0, 0.2, 1.95 }, Color = METAL, Material = "Metal" })
				k:Mirror(function()
					k:Part({ Name = "TailFork", Size = { 0.05, 0.34, 0.08 }, Pos = { 0.1, 0.34, 1.95 }, Color = METAL_DARK, Material = "Metal" })
				end)
				rod("TailStrut", { 0, 0.52, 1.95 }, { 0, 1.62, 1.82 }, 0.1, METAL_DARK)
			end)
		end)

		-- Legendary flair: warm engine glow + face light, golden sparkle
		k:Light({ Pos = { 0, WY, -1.7 }, Color = GLOW, Range = 8, Brightness = 1.2 })
		k:Light({ Pos = { 0, FY + 1.3, -2.3 }, Color = "#ffe39a", Range = 7, Brightness = 0.8 })
		k:Particles({ Pos = { 0, FY + 1.3, -1.0 }, Color = GOLD, Color2 = "#fff3b0", Rate = 3, Size = 0.18, Speed = 0.6, Lifetime = 1.6, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Part({ Name = "Fuselage", Shape = "Ellipsoid", Size = { 0.74, 0.72, 1.9 }, Pos = { 0, 0.05, 0.35 }, Color = OLIVE })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.8, 0.42, 1.25 }, Pos = { 0, 0.05, -0.68 }, Color = CROC })
		k:Part({ Name = "TeethRim", Shape = "Ellipsoid", Size = { 0.76, 0.09, 1.15 }, Pos = { 0, -0.13, -0.72 }, Color = TOOTH })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.24, 0.24, 0.24 }, Pos = { 0.19, 0.27, -0.72 }, Color = EYE })
			k:Part({ Name = "PropInner", Shape = "Cylinder", Size = { 0.08, 0.38, 0.38 }, Pos = { 0.62, -0.1, -0.05 }, Rot = { 0, 90, 0 }, Color = "#3a3b42", Transparency = 0.4 })
			k:Part({ Name = "PropOuter", Shape = "Cylinder", Size = { 0.08, 0.38, 0.38 }, Pos = { 1.08, -0.1, -0.02 }, Rot = { 0, 90, 0 }, Color = "#3a3b42", Transparency = 0.4 })
		end)
		k:Part({ Name = "Wing", Size = { 2.5, 0.08, 0.5 }, Pos = { 0, -0.1, 0.25 }, Color = OLIVE })
		k:Part({ Name = "Fin", Shape = "Wedge", Size = { 0.08, 0.62, 0.55 }, Pos = { 0, 0.62, 1.0 }, Color = OLIVE })
		k:Part({ Name = "Stabiliser", Size = { 1.1, 0.06, 0.3 }, Pos = { 0, 0.12, 1.1 }, Color = OLIVE })
	end,
}
