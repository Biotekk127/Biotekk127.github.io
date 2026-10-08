--[[
	CharacterKit: turns a character definition (src/shared/Characters/*.luau) into a Model.

	A definition's Build(k) / BuildMini(k) only talks to the `k` builder below, so the
	exact same file can be rendered outside Roblox by tools/charlab (keep the transform
	and animation maths here identical to tools/charlab/mockkit.luau).

	Animations are declarative: parts and animated groups carry Anim* attributes and the
	client Animator (src/client/Animator.luau) plays them locally - the server never
	moves anything, so hundreds of animated parts cost no network traffic.
]]

local CollectionService = game:GetService("CollectionService")

local CharacterKit = {}

CharacterKit.AnimatedTag = "BrainrotAnimated"
CharacterKit.RainbowTag = "RainbowCycle"

----------------------------------------------------------------------------------------
-- Maths shared with the Animator
----------------------------------------------------------------------------------------

-- Mirror across the YZ plane (M * cf * M with M = diag(-1, 1, 1)).
function CharacterKit.Mirror(cf: CFrame): CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

local function vec(v: { number }?): Vector3
	if v then
		return Vector3.new(v[1], v[2], v[3])
	end
	return Vector3.zero
end

function CharacterKit.LocalTransform(pos: { number }?, rot: { number }?, mirrored: boolean): CFrame
	local r = rot or { 0, 0, 0 }
	local cf = CFrame.new(vec(pos)) * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
	return if mirrored then CharacterKit.Mirror(cf) else cf
end

export type AnimParams = {
	Type: string,
	Axis: string?,
	Speed: number?,
	Amount: number?,
	Phase: number?,
	Mirror: boolean?,
}

local function axisVector(axis: string?): Vector3
	if axis == "X" then
		return Vector3.xAxis
	elseif axis == "Z" then
		return Vector3.zAxis
	end
	return Vector3.yAxis
end

-- Local animation transform at time t (seconds). Identical to mockkit.animTransform.
function CharacterKit.AnimTransform(anim: AnimParams, t: number): CFrame
	local cycle = 2 * math.pi * ((anim.Speed or 1) * t + (anim.Phase or 0))
	local axis = axisVector(anim.Axis)
	local cf
	if anim.Type == "Spin" then
		cf = CFrame.fromAxisAngle(axis, cycle)
	elseif anim.Type == "Wiggle" then
		cf = CFrame.fromAxisAngle(axis, math.rad(anim.Amount or 15) * math.sin(cycle))
	elseif anim.Type == "Bob" then
		cf = CFrame.new(axis * ((anim.Amount or 0.2) * math.sin(cycle)))
	else
		return CFrame.identity
	end
	return if anim.Mirror then CharacterKit.Mirror(cf) else cf
end

-- Size multiplier for Pulse / Blink part animations. Identical to mockkit.animScale.
function CharacterKit.AnimScale(anim: AnimParams, t: number): Vector3
	if anim.Type == "Pulse" then
		local s = 1 + (anim.Amount or 0.1) * math.sin(2 * math.pi * ((anim.Speed or 1) * t + (anim.Phase or 0)))
		return Vector3.new(s, s, s)
	elseif anim.Type == "Blink" then
		local p = ((anim.Speed or 1) * t + (anim.Phase or 0)) % 1
		return Vector3.new(1, if p < 0.06 then 0.1 else 1, 1)
	end
	return Vector3.one
end

function CharacterKit.ReadAnim(instance: Instance): AnimParams?
	local animType = instance:GetAttribute("AnimType")
	if type(animType) ~= "string" then
		return nil
	end
	return {
		Type = animType,
		Axis = instance:GetAttribute("AnimAxis") :: string?,
		Speed = instance:GetAttribute("AnimSpeed") :: number?,
		Amount = instance:GetAttribute("AnimAmount") :: number?,
		Phase = instance:GetAttribute("AnimPhase") :: number?,
		Mirror = instance:GetAttribute("AnimMirror") == true,
	}
end

local function writeAnim(instance: Instance, anim: any, mirrored: boolean)
	instance:SetAttribute("AnimType", anim.Type)
	instance:SetAttribute("AnimAxis", anim.Axis)
	instance:SetAttribute("AnimSpeed", anim.Speed)
	instance:SetAttribute("AnimAmount", anim.Amount)
	instance:SetAttribute("AnimPhase", anim.Phase)
	if mirrored then
		instance:SetAttribute("AnimMirror", true)
	end
end

----------------------------------------------------------------------------------------
-- Builder
----------------------------------------------------------------------------------------

local SHAPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function color(hex: string?): Color3
	local ok, result = pcall(Color3.fromHex, hex or "#a3a2a5")
	return if ok then result else Color3.fromRGB(163, 162, 165)
end

local function material(name: string?): Enum.Material
	local ok, result = pcall(function()
		return (Enum.Material :: any)[name or "SmoothPlastic"]
	end)
	return if ok and result then result else Enum.Material.SmoothPlastic
end

type Frame = { CF: CFrame, Mirrored: boolean, Container: Instance }

local function newBuilder(root: Model)
	local stack: { Frame } = { { CF = CFrame.identity, Mirrored = false, Container = root } }
	local animated = false
	local count = 0
	local k = {}

	local function top(): Frame
		return stack[#stack]
	end

	function k:Part(spec: any)
		local frame = top()
		local shape = spec.Shape or "Block"
		local part: BasePart
		if shape == "Wedge" then
			part = Instance.new("WedgePart")
		else
			local p = Instance.new("Part")
			p.Shape = SHAPES[shape] or Enum.PartType.Block
			if shape == "Ellipsoid" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			end
			part = p
		end
		count += 1
		part.Name = spec.Name or ("Part" .. count)
		part.Size = vec(spec.Size)
		part.CFrame = frame.CF * CharacterKit.LocalTransform(spec.Pos, spec.Rot, frame.Mirrored)
		part.Color = color(spec.Color)
		part.Material = material(spec.Material)
		part.Transparency = spec.Transparency or 0
		part.Reflectance = spec.Reflectance or 0
		part.Anchored = true
		part.CanTouch = false
		part.CanQuery = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth

		if spec.Text and type(spec.Text.Text) == "string" then
			local gui = Instance.new("SurfaceGui")
			gui.Face = (Enum.NormalId :: any)[spec.Text.Face or "Front"] or Enum.NormalId.Front
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 50
			gui.LightInfluence = 0
			gui.Parent = part
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.Text = spec.Text.Text
			label.TextColor3 = color(spec.Text.Color or "#ffffff")
			label.Parent = gui
		end

		if spec.Anim then
			writeAnim(part, spec.Anim, frame.Mirrored)
			animated = true
		end
		part.Parent = frame.Container
		return part
	end

	function k:Group(spec: any, fn: () -> ())
		local frame = top()
		local cf = frame.CF * CharacterKit.LocalTransform(spec.Pos, spec.Rot, frame.Mirrored)
		local container = frame.Container
		if spec.Anim then
			-- Animated groups become Models whose pivot is the group origin (the joint).
			local group = Instance.new("Model")
			group.Name = spec.Name or "Group"
			writeAnim(group, spec.Anim, frame.Mirrored)
			group.Parent = frame.Container
			group.WorldPivot = cf
			container = group
			animated = true
		end
		table.insert(stack, { CF = cf, Mirrored = frame.Mirrored, Container = container })
		fn()
		table.remove(stack)
	end

	function k:Mirror(fn: () -> ())
		fn()
		local frame = top()
		table.insert(stack, { CF = frame.CF, Mirrored = not frame.Mirrored, Container = frame.Container })
		fn()
		table.remove(stack)
	end

	local function attachmentPart(spec: any, name: string): Part
		local frame = top()
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.Transparency = 1
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Anchored = true
		p.CFrame = frame.CF * CharacterKit.LocalTransform(spec.Pos, nil, frame.Mirrored)
		p.Parent = frame.Container
		return p
	end

	function k:Light(spec: any)
		local p = attachmentPart(spec, "LightSource")
		local light = Instance.new("PointLight")
		light.Color = color(spec.Color or "#ffffff")
		light.Range = math.clamp(spec.Range or 10, 2, 16)
		light.Brightness = math.clamp(spec.Brightness or 1, 0.2, 3)
		light.Parent = p
	end

	function k:Particles(spec: any)
		local p = attachmentPart(spec, "ParticleSource")
		local emitter = Instance.new("ParticleEmitter")
		local c1 = color(spec.Color or "#ffffff")
		emitter.Color = ColorSequence.new(c1, if spec.Color2 then color(spec.Color2) else c1)
		emitter.Rate = math.clamp(spec.Rate or 4, 0, 30)
		local size = spec.Size or 0.3
		emitter.Size = NumberSequence.new(size, 0)
		local speed = spec.Speed or 1.5
		emitter.Speed = NumberRange.new(speed * 0.6, speed)
		local lifetime = spec.Lifetime or 1.5
		emitter.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
		local spread = spec.Spread or 30
		emitter.SpreadAngle = Vector2.new(spread, spread)
		emitter.LightEmission = 0.6
		emitter.Transparency = NumberSequence.new(0.1, 1)
		emitter.EmissionDirection = (Enum.NormalId :: any)[spec.Direction or "Top"] or Enum.NormalId.Top
		emitter.Parent = p
	end

	function k:_finish(): (boolean, number)
		return animated, count
	end
	return k
end

-- Builds a character. mode "Full" = detailed display model (feet at the pivot),
-- "Mini" = tiny conveyor version (centred on the pivot).
function CharacterKit.Build(def: any, mode: string?): Model
	local model = Instance.new("Model")
	model.Name = def.Name or def.Id or "Character"
	model:SetAttribute("CharacterId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)

	local rootPart = Instance.new("Part")
	rootPart.Name = "Root"
	rootPart.Size = Vector3.new(0.2, 0.2, 0.2)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.CanTouch = false
	rootPart.CanQuery = false
	rootPart.Anchored = true
	rootPart.CFrame = CFrame.identity
	rootPart.Parent = model
	model.PrimaryPart = rootPart

	local builder = newBuilder(model)
	local buildFn = if mode == "Mini" then def.BuildMini else def.Build
	local ok, err = pcall(buildFn, builder)
	if not ok then
		warn(`[CharacterKit] {def.Id} failed to build ({mode or "Full"}): {err}`)
	end
	local animated = builder:_finish()
	if animated and mode ~= "Mini" then
		CollectionService:AddTag(model, CharacterKit.AnimatedTag)
	end
	return model
end

----------------------------------------------------------------------------------------
-- Mutations (Gold / Diamond / Rainbow) recolour a built model
----------------------------------------------------------------------------------------

local GOLD = Color3.fromRGB(255, 196, 40)
local DIAMOND = Color3.fromRGB(150, 235, 255)

function CharacterKit.ApplyMutation(model: Model, mutationName: string?)
	if not mutationName then
		return
	end
	model:SetAttribute("Mutation", mutationName)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			if mutationName == "Gold" then
				part.Color = part.Color:Lerp(GOLD, 0.75)
				part.Material = Enum.Material.Foil
			elseif mutationName == "Diamond" then
				part.Color = part.Color:Lerp(DIAMOND, 0.7)
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.25
			elseif mutationName == "Rainbow" then
				part.Material = Enum.Material.Neon
			end
		end
	end
	if mutationName == "Rainbow" then
		CollectionService:AddTag(model, CharacterKit.RainbowTag)
	end
end

-- Height of a built Full model (for placing nameplates above it).
function CharacterKit.Height(model: Model): number
	local cf, size = model:GetBoundingBox()
	local root = model.PrimaryPart
	local base = if root then root.Position.Y else cf.Position.Y - size.Y / 2
	return cf.Position.Y + size.Y / 2 - base
end

return CharacterKit
