--[[
	CharLab mock kit: runs a character definition OUTSIDE Roblox, records every part
	with its final world transform, validates the definition and prints JSON.

	This file is bundled by tools/charlab/charlab.py together with one character file.
	It mirrors the semantics of src/shared/CharacterKit.luau exactly (transform order,
	mirroring, animation formulas) so the preview renders match what you see in game.
]]

local MATERIALS = {
	SmoothPlastic = true, Plastic = true, Neon = true, Glass = true, Metal = true, Foil = true,
	Fabric = true, Wood = true, WoodPlanks = true, Marble = true, Granite = true, Slate = true,
	Concrete = true, Brick = true, Cobblestone = true, Sand = true, Grass = true, Ice = true,
	DiamondPlate = true, CorrodedMetal = true, Pebble = true, ForceField = true, Salt = true,
	Rubber = true, Leather = true, Cardboard = true, Carpet = true, Plaster = true, Asphalt = true,
	Basalt = true, Rock = true, Snow = true, Mud = true, Limestone = true, Pavement = true,
	CeramicTiles = true, ClayRoofTiles = true, RoofShingles = true, CrackedLava = true, Glacier = true,
}
local SHAPES = { Block = true, Ball = true, Ellipsoid = true, Cylinder = true, Wedge = true }
local PART_ANIMS = { Spin = true, Wiggle = true, Bob = true, Pulse = true, Blink = true }
local GROUP_ANIMS = { Spin = true, Wiggle = true, Bob = true }
local AXES = { X = true, Y = true, Z = true }
local FACES = { Front = true, Back = true, Left = true, Right = true, Top = true, Bottom = true }

-- 3x4 rigid transforms stored as { px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
local function mul(a, b)
	local r = {}
	r[4] = a[4] * b[4] + a[5] * b[7] + a[6] * b[10]
	r[5] = a[4] * b[5] + a[5] * b[8] + a[6] * b[11]
	r[6] = a[4] * b[6] + a[5] * b[9] + a[6] * b[12]
	r[7] = a[7] * b[4] + a[8] * b[7] + a[9] * b[10]
	r[8] = a[7] * b[5] + a[8] * b[8] + a[9] * b[11]
	r[9] = a[7] * b[6] + a[8] * b[9] + a[9] * b[12]
	r[10] = a[10] * b[4] + a[11] * b[7] + a[12] * b[10]
	r[11] = a[10] * b[5] + a[11] * b[8] + a[12] * b[11]
	r[12] = a[10] * b[6] + a[11] * b[9] + a[12] * b[12]
	r[1] = a[1] + a[4] * b[1] + a[5] * b[2] + a[6] * b[3]
	r[2] = a[2] + a[7] * b[1] + a[8] * b[2] + a[9] * b[3]
	r[3] = a[3] + a[10] * b[1] + a[11] * b[2] + a[12] * b[3]
	return r
end

local function rotX(a)
	local c, s = math.cos(a), math.sin(a)
	return { 0, 0, 0, 1, 0, 0, 0, c, -s, 0, s, c }
end
local function rotY(a)
	local c, s = math.cos(a), math.sin(a)
	return { 0, 0, 0, c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rotZ(a)
	local c, s = math.cos(a), math.sin(a)
	return { 0, 0, 0, c, -s, 0, s, c, 0, 0, 0, 1 }
end
local function translate(x, y, z)
	return { x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
end

-- CFrame.new(pos) * CFrame.Angles(rx, ry, rz)  (Angles = Rx * Ry * Rz)
local function fromPosRot(pos, rot)
	local m = translate(pos[1], pos[2], pos[3])
	m = mul(m, rotX(math.rad(rot[1])))
	m = mul(m, rotY(math.rad(rot[2])))
	m = mul(m, rotZ(math.rad(rot[3])))
	return m
end

-- Mirror across the YZ plane: M * T * M with M = diag(-1, 1, 1)
local function conj(m)
	return { -m[1], m[2], m[3], m[4], -m[5], -m[6], -m[7], m[8], m[9], -m[10], m[11], m[12] }
end

local issues = {}
local function issue(level, message)
	table.insert(issues, { level = level, message = message })
end

local function isNumber(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function checkVec(v, what, n)
	if v == nil then
		return true
	end
	if type(v) ~= "table" or #v ~= (n or 3) then
		issue("error", `{what} must be a table of {n or 3} numbers`)
		return false
	end
	for i = 1, n or 3 do
		if not isNumber(v[i]) then
			issue("error", `{what}[{i}] is not a finite number`)
			return false
		end
	end
	return true
end

local function checkColor(c, what)
	if type(c) ~= "string" or not c:match("^#%x%x%x%x%x%x$") then
		issue("error", `{what} must be a hex colour like "#ff8800" (got {tostring(c)})`)
		return false
	end
	return true
end

-- Same formula as CharacterKit.AnimTransform
local function animTransform(anim, t)
	local speed = anim.Speed or 1
	local phase = anim.Phase or 0
	local amount = anim.Amount
	local axis = anim.Axis or "Y"
	local cycle = 2 * math.pi * (speed * t + phase)
	local function rot(angle)
		if axis == "X" then
			return rotX(angle)
		elseif axis == "Y" then
			return rotY(angle)
		end
		return rotZ(angle)
	end
	if anim.Type == "Spin" then
		return rot(cycle)
	elseif anim.Type == "Wiggle" then
		return rot(math.rad(amount or 15) * math.sin(cycle))
	elseif anim.Type == "Bob" then
		local d = (amount or 0.2) * math.sin(cycle)
		return translate(if axis == "X" then d else 0, if axis == "Y" then d else 0, if axis == "Z" then d else 0)
	end
	return translate(0, 0, 0)
end

-- Same formula as CharacterKit.AnimScale (Pulse / Blink change the part's size)
local function animScale(anim, t)
	local speed = anim.Speed or 1
	local phase = anim.Phase or 0
	if anim.Type == "Pulse" then
		local s = 1 + (anim.Amount or 0.1) * math.sin(2 * math.pi * (speed * t + phase))
		return { s, s, s }
	elseif anim.Type == "Blink" then
		local p = (speed * t + phase) % 1
		return { 1, if p < 0.06 then 0.1 else 1, 1 }
	end
	return { 1, 1, 1 }
end

local function checkAnim(anim, allowed, what)
	if anim == nil then
		return true
	end
	if type(anim) ~= "table" or not allowed[anim.Type] then
		issue("error", `{what}: Anim.Type must be one of the allowed types (got {tostring(anim and anim.Type)})`)
		return false
	end
	if anim.Axis ~= nil and not AXES[anim.Axis] then
		issue("error", `{what}: Anim.Axis must be "X", "Y" or "Z"`)
		return false
	end
	for _, key in { "Speed", "Amount", "Phase" } do
		if anim[key] ~= nil and not isNumber(anim[key]) then
			issue("error", `{what}: Anim.{key} must be a number`)
			return false
		end
	end
	if anim.Speed and math.abs(anim.Speed) > 4 then
		issue("warning", `{what}: Anim.Speed {anim.Speed} is very fast (keep it calm, <= 2)`)
	end
	return true
end

local function newKit(t)
	local parts, lights, particles = {}, {}, {}
	local stack = { { world = translate(0, 0, 0), mirrored = false } }
	local counts = { parts = 0, animated = 0, groups = 0, text = 0 }
	local kit = {}

	local function top()
		return stack[#stack]
	end

	local function localTransform(spec, what)
		local okPos = checkVec(spec.Pos, what .. ".Pos")
		local okRot = checkVec(spec.Rot, what .. ".Rot")
		local m = fromPosRot(if okPos and spec.Pos then spec.Pos else { 0, 0, 0 }, if okRot and spec.Rot then spec.Rot else { 0, 0, 0 })
		if top().mirrored then
			m = conj(m)
		end
		return m
	end

	function kit:Part(spec)
		local name = tostring(spec.Name or `Part{counts.parts + 1}`)
		local what = `Part "{name}"`
		if type(spec) ~= "table" then
			issue("error", "Part spec must be a table")
			return
		end
		local shape = spec.Shape or "Block"
		if not SHAPES[shape] then
			issue("error", `{what}: unknown Shape "{tostring(shape)}"`)
			shape = "Block"
		end
		if not checkVec(spec.Size, what .. ".Size") or spec.Size == nil then
			issue("error", `{what}: Size is required`)
			return
		end
		local size = { spec.Size[1], spec.Size[2], spec.Size[3] }
		for i = 1, 3 do
			if size[i] < 0.05 then
				issue("error", `{what}: Size[{i}] = {size[i]} is below the 0.05 minimum`)
				size[i] = 0.05
			end
		end
		if shape == "Ball" and (math.abs(size[1] - size[2]) > 1e-3 or math.abs(size[2] - size[3]) > 1e-3) then
			issue("warning", `{what}: Ball should have equal sizes (Roblox uses the smallest). Use "Ellipsoid" for stretched spheres.`)
		end
		if shape == "Cylinder" and math.abs(size[2] - size[3]) > 1e-3 then
			issue("warning", `{what}: Cylinder runs along X; Size[2] and Size[3] should match (diameter)`)
		end
		local color = spec.Color or "#a3a2a5"
		checkColor(color, what .. ".Color")
		local material = spec.Material or "SmoothPlastic"
		if not MATERIALS[material] then
			issue("error", `{what}: unknown Material "{tostring(material)}"`)
			material = "SmoothPlastic"
		end
		local transparency = spec.Transparency or 0
		if not isNumber(transparency) or transparency < 0 or transparency > 1 then
			issue("error", `{what}: Transparency must be 0..1`)
			transparency = 0
		end
		if spec.Reflectance ~= nil and (not isNumber(spec.Reflectance) or spec.Reflectance < 0 or spec.Reflectance > 1) then
			issue("error", `{what}: Reflectance must be 0..1`)
		end
		if spec.Text ~= nil then
			counts.text += 1
			if type(spec.Text) ~= "table" or type(spec.Text.Text) ~= "string" then
				issue("error", what .. ': Text must be { Text = "...", Color = "#hex", Face = "Front" }')
			else
				if spec.Text.Color then
					checkColor(spec.Text.Color, what .. ".Text.Color")
				end
				if spec.Text.Face and not FACES[spec.Text.Face] then
					issue("error", `{what}: Text.Face must be Front/Back/Left/Right/Top/Bottom`)
				end
			end
		end
		for key in spec do
			if
				key ~= "Name" and key ~= "Shape" and key ~= "Size" and key ~= "Pos" and key ~= "Rot"
				and key ~= "Color" and key ~= "Material" and key ~= "Transparency" and key ~= "Reflectance"
				and key ~= "Anim" and key ~= "Text"
			then
				issue("warning", `{what}: unknown field "{tostring(key)}" is ignored`)
			end
		end

		local world = mul(top().world, localTransform(spec, what))
		if spec.Anim then
			if checkAnim(spec.Anim, PART_ANIMS, what) then
				counts.animated += 1
				if t then
					local a = animTransform(spec.Anim, t)
					if top().mirrored then
						a = conj(a)
					end
					world = mul(world, a)
					local s = animScale(spec.Anim, t)
					size = { size[1] * s[1], size[2] * s[2], size[3] * s[3] }
				end
			end
		end
		counts.parts += 1
		table.insert(parts, {
			name = name,
			shape = shape,
			size = size,
			cf = world,
			color = color,
			material = material,
			transparency = transparency,
		})
	end

	function kit:Group(spec, fn)
		if type(spec) ~= "table" or type(fn) ~= "function" then
			issue("error", "Group must be called as k:Group({ Pos = ..., Rot = ... }, function() ... end)")
			return
		end
		local what = `Group "{tostring(spec.Name or "?")}"`
		local world = mul(top().world, localTransform(spec, what))
		if spec.Anim then
			if checkAnim(spec.Anim, GROUP_ANIMS, what) then
				counts.animated += 1
				if t then
					local a = animTransform(spec.Anim, t)
					if top().mirrored then
						a = conj(a)
					end
					world = mul(world, a)
				end
			end
		end
		counts.groups += 1
		table.insert(stack, { world = world, mirrored = top().mirrored })
		fn()
		table.remove(stack)
	end

	function kit:Mirror(fn)
		fn()
		table.insert(stack, { world = top().world, mirrored = not top().mirrored })
		fn()
		table.remove(stack)
	end

	local function worldPoint(pos)
		local m = mul(top().world, localTransform({ Pos = pos }, "point"))
		return { m[1], m[2], m[3] }
	end

	function kit:Light(spec)
		checkVec(spec.Pos, "Light.Pos")
		checkColor(spec.Color or "#ffffff", "Light.Color")
		table.insert(lights, { pos = worldPoint(spec.Pos or { 0, 0, 0 }), color = spec.Color or "#ffffff" })
	end

	function kit:Particles(spec)
		checkVec(spec.Pos, "Particles.Pos")
		checkColor(spec.Color or "#ffffff", "Particles.Color")
		if spec.Color2 then
			checkColor(spec.Color2, "Particles.Color2")
		end
		if spec.Rate and spec.Rate > 30 then
			issue("warning", "Particles.Rate above 30 is heavy - every plot shows this character")
		end
		table.insert(particles, { pos = worldPoint(spec.Pos or { 0, 0, 0 }), color = spec.Color or "#ffffff" })
	end

	function kit:_result()
		return parts, lights, particles, counts
	end
	return kit
end

----------------------------------------------------------------------------------------
-- JSON
----------------------------------------------------------------------------------------

local function encode(v)
	local tv = type(v)
	if tv == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			return "null"
		end
		return string.format("%.5g", v)
	elseif tv == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c)
			return string.format("\\u%04x", string.byte(c))
		end) .. '"'
	elseif tv == "boolean" then
		return tostring(v)
	elseif tv == "table" then
		if #v > 0 or next(v) == nil then
			local out = {}
			for i = 1, #v do
				out[i] = encode(v[i])
			end
			return "[" .. table.concat(out, ",") .. "]"
		end
		local out = {}
		for k, val in v do
			table.insert(out, encode(tostring(k)) .. ":" .. encode(val))
		end
		return "{" .. table.concat(out, ",") .. "}"
	end
	return "null"
end

----------------------------------------------------------------------------------------
-- Run
----------------------------------------------------------------------------------------

local RARITY_MIN_PARTS = { Common = 45, Uncommon = 60, Rare = 80, Epic = 100, Legendary = 130, Mythic = 160, Secret = 200 }
local RARITY_MAX_PARTS = 400

return function(def, mode, t)
	if type(def) ~= "table" then
		issue("error", "Character file must return a table")
		print(encode({ issues = issues }))
		return
	end
	for _, key in { "Id", "Name", "Rarity", "Emoji", "Tagline", "Lore" } do
		if type(def[key]) ~= "string" or def[key] == "" then
			issue("error", `Character.{key} must be a non-empty string`)
		end
	end
	if def.Rarity and not RARITY_MIN_PARTS[def.Rarity] then
		issue("error", `Character.Rarity must be one of Common/Uncommon/Rare/Epic/Legendary/Mythic/Secret`)
	end
	if def.Color then
		checkColor(def.Color, "Character.Color")
	else
		issue("error", "Character.Color (signature hex colour) is required")
	end

	local builder = if mode == "mini" then def.BuildMini else def.Build
	if type(builder) ~= "function" then
		issue("error", `Character.{if mode == "mini" then "BuildMini" else "Build"} must be a function(k)`)
		print(encode({ issues = issues }))
		return
	end
	local kit = newKit(t)
	local ok, err = pcall(builder, kit)
	if not ok then
		issue("error", "Build crashed: " .. tostring(err))
	end
	local parts, lights, particles, counts = kit:_result()

	-- Bounds use the corners of each part's oriented box (conservative for round shapes).
	local minB, maxB = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
	for _, p in parts do
		local m, s = p.cf, p.size
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local lx, ly, lz = s[1] * sx, s[2] * sy, s[3] * sz
					local w = {
						m[1] + m[4] * lx + m[5] * ly + m[6] * lz,
						m[2] + m[7] * lx + m[8] * ly + m[9] * lz,
						m[3] + m[10] * lx + m[11] * ly + m[12] * lz,
					}
					for i = 1, 3 do
						minB[i] = math.min(minB[i], w[i])
						maxB[i] = math.max(maxB[i], w[i])
					end
				end
			end
		end
	end

	if t == 0 or t == nil then
		if mode == "mini" then
			if counts.parts > 12 then
				issue("error", `Mini has {counts.parts} parts; the limit is 12 (it rides the conveyor in big numbers)`)
			end
			if counts.parts < 3 then
				issue("warning", "Mini has fewer than 3 parts - give it a recognisable silhouette")
			end
			if #lights > 0 or #particles > 0 or counts.animated > 0 or counts.text > 0 then
				issue("error", "Mini must not use Light, Particles, Anim or Text")
			end
			for i = 1, 3 do
				if minB[i] < -1.35 or maxB[i] > 1.35 then
					issue("error", string.format("Mini must fit inside a 2.7 stud cube centred on the origin (axis %d spans %.2f..%.2f)", i, minB[i], maxB[i]))
				end
			end
		elseif #parts > 0 then
			local minParts = RARITY_MIN_PARTS[def.Rarity] or 45
			if counts.parts < minParts then
				issue("error", `{def.Rarity} characters need at least {minParts} parts for the required detail (has {counts.parts})`)
			end
			if counts.parts > RARITY_MAX_PARTS then
				issue("error", `Too many parts ({counts.parts} > {RARITY_MAX_PARTS})`)
			end
			if minB[2] < -0.1 then
				issue("error", string.format("Character goes below the ground: lowest point y = %.2f (feet must sit on y = 0)", minB[2]))
			end
			if minB[2] > 0.35 then
				issue("error", string.format("Character floats: lowest point y = %.2f (feet must touch y = 0)", minB[2]))
			end
			if maxB[2] > 9.5 then
				issue("error", string.format("Too tall: top y = %.2f (max 9.5)", maxB[2]))
			end
			if maxB[2] < 4.5 then
				issue("error", string.format("Too small: top y = %.2f (min 4.5)", maxB[2]))
			end
			for _, i in { 1, 3 } do
				if minB[i] < -3.2 or maxB[i] > 3.2 then
					issue("error", string.format("Too wide: %s spans %.2f..%.2f (must stay within -3.2..3.2)", if i == 1 then "X" else "Z", minB[i], maxB[i]))
				end
			end
			if #lights > 2 then
				issue("error", `At most 2 Lights per character (has {#lights})`)
			end
			if #particles > 3 then
				issue("error", `At most 3 Particles emitters per character (has {#particles})`)
			end
		end
	end

	print(encode({
		mode = mode,
		t = t or 0,
		parts = parts,
		lights = lights,
		particles = particles,
		issues = issues,
		stats = {
			parts = counts.parts,
			animated = counts.animated,
			groups = counts.groups,
			lights = #lights,
			particles = #particles,
			min = minB,
			max = maxB,
		},
	}))
end
