--[[
	Rarity pedestals and nameplates for the showcase brainrot on top of every dropper.

	Each tier stacks more effects on the one below it:
	  Common     marble pedestal with a coloured trim ring
	  Uncommon   + floating sparkle aura
	  Rare       + glow light and a glass top
	  Epic       + orbiting ring of gems
	  Legendary  + light beam and sparkles
	  Mythic     + counter-rotating second ring and stardust
	  Secret     + rainbow-cycling everything
	Orbit rings use the same Anim* attributes as characters, so the client Animator
	spins them locally.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterKit = require(ReplicatedStorage.Shared.CharacterKit)
local Format = require(ReplicatedStorage.Shared.Format)
local Rarity = require(ReplicatedStorage.Shared.Rarity)

local RarityFX = {}

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

-- Upright cylinder (Roblox cylinders run along X, so rotate onto Y).
local function disc(parent: Instance, cf: CFrame, diameter: number, height: number, props: { [string]: any }): Part
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	return part(parent, props)
end

local function orbitRing(parent: Model, center: CFrame, radius: number, count: number, color: Color3, speed: number, tilt: number, rainbow: boolean)
	local ring = Instance.new("Model")
	ring.Name = "OrbitRing"
	ring:SetAttribute("AnimType", "Spin")
	ring:SetAttribute("AnimAxis", "Y")
	ring:SetAttribute("AnimSpeed", speed)
	ring.Parent = parent
	local ringCF = center * CFrame.Angles(math.rad(tilt), 0, 0)
	ring.WorldPivot = ringCF
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2
		local gem = part(ring, {
			Name = "Gem",
			Size = Vector3.new(0.35, 0.35, 0.35),
			CFrame = ringCF * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius) * CFrame.Angles(math.rad(45), math.rad(45), 0),
			Color = color,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		if rainbow then
			CollectionService:AddTag(gem, CharacterKit.RainbowTag)
		end
	end
end

-- Builds the pedestal. `topCF` is the centre of the pedestal's top surface.
function RarityFX.Pedestal(rarityKey: string, topCF: CFrame, parent: Instance): Model
	local tier = Rarity.Get(rarityKey)
	local order = tier.Order
	local model = Instance.new("Model")
	model.Name = "Pedestal"
	model.Parent = parent

	local base = disc(model, topCF * CFrame.new(0, -0.35, 0), 6, 0.7, {
		Name = "Base",
		Color = if tier.Rainbow then Color3.fromRGB(20, 20, 30) else Color3.fromRGB(235, 235, 245),
		Material = Enum.Material.Marble,
	})
	model.PrimaryPart = base
	local trim = disc(model, topCF * CFrame.new(0, -0.35, 0), 6.3, 0.25, {
		Name = "Trim",
		Color = tier.Color,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	if tier.Rainbow then
		CollectionService:AddTag(trim, CharacterKit.RainbowTag)
	end

	if order >= 3 then
		disc(model, topCF * CFrame.new(0, 0.03, 0), 5.4, 0.06, {
			Name = "GlassTop",
			Color = tier.Color,
			Material = Enum.Material.Glass,
			Transparency = 0.5,
			CanCollide = false,
		})
		local light = Instance.new("PointLight")
		light.Color = tier.Color
		light.Range = 8 + order
		light.Brightness = 0.6 + order * 0.15
		light.Parent = trim
	end

	if order >= 2 then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(tier.Color, tier.Color2)
		emitter.Size = NumberSequence.new(0.25 + order * 0.03, 0)
		emitter.Lifetime = NumberRange.new(1.2, 2)
		emitter.Speed = NumberRange.new(1, 2.5)
		emitter.Rate = 2 + order * 1.5
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.LightEmission = 0.8
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Shape = Enum.ParticleEmitterShape.Disc
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		emitter.Parent = trim
		emitter.Transparency = NumberSequence.new(0.2, 1)
	end

	if order >= 4 then
		orbitRing(model, topCF * CFrame.new(0, 1.2, 0), 3.4, 10, tier.Color, 0.25, 0, tier.Rainbow)
	end

	if order >= 5 then
		disc(model, topCF * CFrame.new(0, 8, 0), 2.2, 16, {
			Name = "Beam",
			Color = tier.Color,
			Material = Enum.Material.Neon,
			Transparency = 0.88,
			CanCollide = false,
			CastShadow = false,
		})
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = tier.Color
		sparkles.Parent = base
	end

	if order >= 6 then
		orbitRing(model, topCF * CFrame.new(0, 4.5, 0), 3.6, 14, tier.Color2, -0.18, 18, tier.Rainbow)
		local stars = Instance.new("ParticleEmitter")
		stars.Color = ColorSequence.new(Color3.new(1, 1, 1), tier.Color)
		stars.Size = NumberSequence.new(0.18, 0)
		stars.Lifetime = NumberRange.new(2, 3)
		stars.Speed = NumberRange.new(0.2, 0.6)
		stars.Rate = 6
		stars.SpreadAngle = Vector2.new(180, 180)
		stars.LightEmission = 1
		stars.Parent = base
	end

	if model:FindFirstChild("OrbitRing") then
		CollectionService:AddTag(model, CharacterKit.AnimatedTag)
	end
	return model
end

-- Floating name / rarity / value label above the character.
function RarityFX.Nameplate(def: any, valuePerDrop: number, anchorCF: CFrame, parent: Instance): BillboardGui
	local tier = Rarity.Get(def.Rarity)
	local anchor = part(parent, {
		Name = "NameplateAnchor",
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = anchorCF,
		Transparency = 1,
		CanCollide = false,
	})

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(9, 3)
	gui.LightInfluence = 0
	gui.MaxDistance = 110
	gui.Adornee = anchor
	gui.Parent = anchor

	local function line(text: string, y: number, height: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, y)
		label.Size = UDim2.fromScale(1, height)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = color
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(15, 10, 25)
		stroke.Parent = label
		return label
	end

	line(def.Name, 0, 0.42, Color3.new(1, 1, 1))
	local rarityLabel = line(tier.Name:upper(), 0.42, 0.3, Color3.new(1, 1, 1))
	local gradient = Instance.new("UIGradient")
	if tier.Rainbow then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 110)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 170, 255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(185, 95, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200)),
		})
	else
		gradient.Color = ColorSequence.new(tier.Color, tier.Color2)
		gradient.Rotation = 90
	end
	gradient.Parent = rarityLabel
	line(`{Format.Cash(valuePerDrop)} / drop`, 0.74, 0.26, Color3.fromRGB(120, 255, 150))
	return gui
end

return RarityFX
