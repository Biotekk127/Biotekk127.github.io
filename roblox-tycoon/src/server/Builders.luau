--[[
	Procedural model builders. Every model in the game is generated from code, so the
	place file needs no hand-built assets.

	All positions are in PLOT-LOCAL space: the plot centre is (0, 0, 0), the floor top
	is y = 1, the conveyor runs along +X at z = 0, and the front (buy buttons and the
	spawn point) faces +Z toward the lobby.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local CharacterKit = require(ReplicatedStorage.Shared.CharacterKit)
local CharacterRegistry = require(ReplicatedStorage.Shared.CharacterRegistry)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local RarityFX = require(script.Parent.RarityFX)

local Builders = {}

Builders.FLOOR_TOP = 1
Builders.CONVEYOR_TOP = 2
Builders.CONVEYOR_START_X = -36
Builders.CONVEYOR_END_X = 34
Builders.COLLECTOR_X = 37
Builders.COLLECT_PAD_POS = Vector3.new(37, 1.2, 11)
Builders.SPAWN_POS = Vector3.new(0, 4, 47)

local BUTTON_COLUMNS = 11

type PartProps = { [string]: any }

-- Create an anchored part positioned in plot-local space.
local function part(parent: Instance, plotCF: CFrame, size: Vector3, localPos: Vector3, props: PartProps?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = plotCF * CFrame.new(localPos)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props then
		for key, value in props do
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end
Builders.Part = part

local function model(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- A camera-facing label. Use for prices, names and emoji.
function Builders.Billboard(adornee: BasePart, text: string, sizeStuds: Vector2, offsetY: number, maxDistance: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(sizeStuds.X, sizeStuds.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 90
	gui.Adornee = adornee
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(20, 20, 30)
	stroke.Parent = label
	return label
end

-- Model "rises" out of the floor when purchased.
function Builders.PlayBuildAnimation(m: Model)
	local finalPivot = m:GetPivot()
	local _, size = m:GetBoundingBox()
	local start = finalPivot * CFrame.new(0, -size.Y, 0)
	local value = Instance.new("CFrameValue")
	value.Value = start
	m:PivotTo(start)
	value.Changed:Connect(function(cf)
		if m.Parent then
			m:PivotTo(cf)
		end
	end)
	local tween = TweenService:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Value = finalPivot,
	})
	tween.Completed:Once(function()
		value:Destroy()
	end)
	tween:Play()
end

-- Confetti burst at a world position (used on purchases).
function Builders.Confetti(parent: Instance, position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 220, 255)),
	})
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Speed = NumberRange.new(18, 30)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Rate = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = anchor
	emitter:Emit(60)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

----------------------------------------------------------------------------------------
-- Plot base
----------------------------------------------------------------------------------------

export type PlotParts = {
	Model: Model,
	Conveyor: BasePart,
	Collector: BasePart,
	CollectPad: BasePart,
	BankLabel: TextLabel,
	OwnerLabel: TextLabel,
	ItemsFolder: Folder,
	ButtonsFolder: Folder,
	DropsFolder: Folder,
}

function Builders.PlotBase(plotCF: CFrame, plotId: number, parent: Instance): PlotParts
	local m = model("Plot" .. plotId, parent)
	m:SetAttribute("PlotId", plotId)
	local base = model("Base", m)

	local floor = part(base, plotCF, Vector3.new(100, 1, 100), Vector3.new(0, 0.5, 0), {
		Name = "Floor",
		Color = Color3.fromRGB(70, 75, 95),
		Material = Enum.Material.Concrete,
	})
	m.PrimaryPart = floor

	-- Neon border so plots look great from the lobby.
	for _, data in
		{
			{ Vector3.new(100, 0.3, 1), Vector3.new(0, 1.15, 49.5) },
			{ Vector3.new(100, 0.3, 1), Vector3.new(0, 1.15, -49.5) },
			{ Vector3.new(1, 0.3, 100), Vector3.new(49.5, 1.15, 0) },
			{ Vector3.new(1, 0.3, 100), Vector3.new(-49.5, 1.15, 0) },
		}
	do
		part(base, plotCF, data[1], data[2], {
			Name = "Border",
			Color = Color3.fromRGB(120, 90, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end

	-- Conveyor belt (anchored part with a velocity carries anything on top of it).
	local length = Builders.CONVEYOR_END_X - Builders.CONVEYOR_START_X
	local midX = (Builders.CONVEYOR_END_X + Builders.CONVEYOR_START_X) / 2
	local conveyor = part(base, plotCF, Vector3.new(length, 1, 6), Vector3.new(midX, 1.5, 0), {
		Name = "Conveyor",
		Color = Color3.fromRGB(35, 35, 45),
		Material = Enum.Material.DiamondPlate,
	})
	conveyor.AssemblyLinearVelocity = plotCF.RightVector * Config.ConveyorSpeed

	for _, z in { -3.25, 3.25 } do
		part(base, plotCF, Vector3.new(length + 6, 1.5, 0.5), Vector3.new(midX + 3, 2.75, z), {
			Name = "Rail",
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Metal,
		})
		part(base, plotCF, Vector3.new(length, 0.2, 0.3), Vector3.new(midX, 3.6, z), {
			Name = "RailGlow",
			Color = Color3.fromRGB(80, 220, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	part(base, plotCF, Vector3.new(0.5, 2, 7), Vector3.new(Builders.CONVEYOR_START_X - 0.25, 3, 0), {
		Name = "StartWall",
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Metal,
	})

	-- Collector: drops that touch it are turned into cash in the plot's bank.
	local collector = part(base, plotCF, Vector3.new(6, 1, 7), Vector3.new(Builders.COLLECTOR_X, 1.5, 0), {
		Name = "Collector",
		Color = Color3.fromRGB(60, 230, 120),
		Material = Enum.Material.Neon,
	})
	part(base, plotCF, Vector3.new(0.5, 6, 7), Vector3.new(Builders.COLLECTOR_X + 3.25, 4, 0), {
		Name = "CollectorWall",
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Metal,
	})
	local sign = part(base, plotCF, Vector3.new(1, 1, 1), Vector3.new(Builders.COLLECTOR_X, 10, 0), {
		Name = "BankAnchor",
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local bankLabel = Builders.Billboard(sign, "$0", Vector2.new(14, 4), 0, 150)
	bankLabel.TextColor3 = Color3.fromRGB(120, 255, 150)

	-- Collect pad: owner steps here to move the bank into their wallet.
	local collectPad = part(base, plotCF, Vector3.new(6, 0.4, 6), Builders.COLLECT_PAD_POS, {
		Name = "CollectPad",
		Color = Color3.fromRGB(60, 230, 120),
		Material = Enum.Material.Neon,
	})
	part(base, plotCF, Vector3.new(7, 0.3, 7), Builders.COLLECT_PAD_POS - Vector3.new(0, 0.2, 0), {
		Name = "CollectPadRim",
		Color = Color3.fromRGB(25, 25, 35),
	})
	Builders.Billboard(collectPad, "💰 COLLECT", Vector2.new(8, 2), 3, 80)

	-- Floating owner name above the front of the plot.
	local ownerAnchor = part(base, plotCF, Vector3.new(1, 1, 1), Vector3.new(0, 16, 46), {
		Name = "OwnerAnchor",
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local ownerLabel = Builders.Billboard(ownerAnchor, "Empty Factory", Vector2.new(30, 5), 0, 400)

	local items = Instance.new("Folder")
	items.Name = "Items"
	items.Parent = m
	local buttons = Instance.new("Folder")
	buttons.Name = "Buttons"
	buttons.Parent = m
	local drops = Instance.new("Folder")
	drops.Name = "Drops"
	drops.Parent = m

	return {
		Model = m,
		Conveyor = conveyor,
		Collector = collector,
		CollectPad = collectPad,
		BankLabel = bankLabel,
		OwnerLabel = ownerLabel,
		ItemsFolder = items,
		ButtonsFolder = buttons,
		DropsFolder = drops,
	}
end

----------------------------------------------------------------------------------------
-- Buy buttons
----------------------------------------------------------------------------------------

function Builders.ButtonPosition(index: number): Vector3
	local row = (index - 1) // BUTTON_COLUMNS
	local column = (index - 1) % BUTTON_COLUMNS
	return Vector3.new(-40 + column * 8, 1.3, 20 + row * 7)
end

function Builders.Button(item: any, plotCF: CFrame, parent: Instance, priceText: string): (Model, BasePart)
	local m = model("Button_" .. item.Id, parent)
	local pos = Builders.ButtonPosition(item.Index)
	part(m, plotCF, Vector3.new(5.6, 0.4, 5.6), pos - Vector3.new(0, 0.25, 0), {
		Name = "Rim",
		Color = Color3.fromRGB(25, 25, 35),
	})
	local pad = part(m, plotCF, Vector3.new(5, 0.6, 5), pos, {
		Name = "Pad",
		Color = Color3.fromRGB(70, 220, 110),
		Material = Enum.Material.Neon,
	})
	m.PrimaryPart = pad
	m:SetAttribute("ItemId", item.Id)
	m:SetAttribute("Price", item.Price)

	local label = Builders.Billboard(pad, `{item.Name}\n{priceText}`, Vector2.new(9, 3.2), 3.2, 70)
	label.Name = "Label"
	return m, pad
end

----------------------------------------------------------------------------------------
-- Droppers, upgraders, collector upgrade
----------------------------------------------------------------------------------------

-- Droppers alternate sides of the conveyor. The back row is shifted half a slot and
-- raised so its showcase brainrots aren't hidden behind the front row.
function Builders.DropperLayout(slot: number): (number, number, number)
	local pair = (slot - 1) // 2
	local side = if slot % 2 == 1 then -1 else 1
	local x = -30 + pair * 8 + (if side == -1 then 4 else 0)
	local pillarTop = if side == -1 then 14 else 11
	return x, side, pillarTop
end

-- Returns the model and the world CFrame drops spawn at. The dropper is topped by the
-- full-size brainrot standing on its rarity pedestal.
function Builders.Dropper(item: any, plotCF: CFrame, parent: Instance): (Model, CFrame)
	local def = CharacterRegistry.Get(item.Character)
	local tier = Rarity.Get(def.Rarity)
	local x, side, pillarTop = Builders.DropperLayout(item.Slot)
	local accent = tier.Color

	local m = model(item.Id, parent)
	local baseBlock = part(m, plotCF, Vector3.new(4, 1, 4), Vector3.new(x, 1.5, 9 * side), {
		Name = "Base",
		Color = Color3.fromRGB(40, 40, 52),
		Material = Enum.Material.Metal,
	})
	m.PrimaryPart = baseBlock
	local pillarHeight = pillarTop - 2
	part(m, plotCF, Vector3.new(2, pillarHeight, 2), Vector3.new(x, 2 + pillarHeight / 2, 9 * side), {
		Name = "Pillar",
		Color = Color3.fromRGB(230, 230, 240),
	})
	for _, y in { 4.5, pillarTop - 1.5 } do
		part(m, plotCF, Vector3.new(2.2, 0.5, 2.2), Vector3.new(x, y, 9 * side), {
			Name = "Stripe",
			Color = accent,
			Material = Enum.Material.Neon,
		})
	end
	part(m, plotCF, Vector3.new(2, 2, 9), Vector3.new(x, 10, 4.5 * side), {
		Name = "Arm",
		Color = Color3.fromRGB(230, 230, 240),
	})
	part(m, plotCF, Vector3.new(3, 2.5, 3), Vector3.new(x, 8.25, 1.5 * side), {
		Name = "Hopper",
		Color = accent,
	})

	-- Pedestal + showcase character facing the front of the plot (+Z).
	local topCF = plotCF * CFrame.new(x, pillarTop + 0.7, 9 * side)
	RarityFX.Pedestal(def.Rarity, topCF, m)
	local character = CharacterKit.Build(def, "Full")
	character:PivotTo(topCF * CFrame.Angles(0, math.pi, 0))
	character.Parent = m
	local height = CharacterKit.Height(character)
	RarityFX.Nameplate(def, item.Value, topCF * CFrame.new(0, height + 2, 0), m)

	local spawnCF = plotCF * CFrame.new(x, 5.5, 1.5 * side)
	return m, spawnCF
end

-- Returns the model and the laser part that upgrades drops passing through it.
function Builders.Upgrader(item: any, plotCF: CFrame, parent: Instance): (Model, BasePart)
	local x = 11 + item.Slot * 6
	local m = model(item.Id, parent)
	for _, z in { -4.25, 4.25 } do
		part(m, plotCF, Vector3.new(1, 6, 1), Vector3.new(x, 4, z), {
			Name = "Post",
			Color = Color3.fromRGB(40, 40, 52),
			Material = Enum.Material.Metal,
		})
	end
	local top = part(m, plotCF, Vector3.new(1.4, 1.2, 9.5), Vector3.new(x, 7.6, 0), {
		Name = "Top",
		Color = item.Color,
		Material = Enum.Material.Neon,
	})
	m.PrimaryPart = top
	local laser = part(m, plotCF, Vector3.new(0.6, 4, 6.2), Vector3.new(x, 4.2, 0), {
		Name = "Laser",
		Color = item.Color,
		Material = Enum.Material.Neon,
		Transparency = 0.55,
		CanCollide = false,
		CanQuery = false,
	})
	local label = Builders.Billboard(top, `x{item.Multiplier}`, Vector2.new(4, 2), 2.2, 80)
	label.TextColor3 = item.Color
	return m, laser
end

function Builders.CollectorUpgrade(item: any, plotCF: CFrame, parent: Instance): Model
	local m = model(item.Id, parent)
	local gold = Color3.fromRGB(255, 200, 40)
	for _, z in { -4.5, 4.5 } do
		part(m, plotCF, Vector3.new(1.2, 9, 1.2), Vector3.new(Builders.COLLECTOR_X, 5.5, z), {
			Name = "Post",
			Color = gold,
			Material = Enum.Material.Foil,
		})
	end
	local arch = part(m, plotCF, Vector3.new(2, 1.5, 10.2), Vector3.new(Builders.COLLECTOR_X, 10.5, 0), {
		Name = "Arch",
		Color = gold,
		Material = Enum.Material.Foil,
	})
	m.PrimaryPart = arch
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = gold
	sparkles.Parent = arch
	return m
end

----------------------------------------------------------------------------------------
-- Decorations (purely cosmetic, but they make the factory feel like it's growing)
----------------------------------------------------------------------------------------

local Decor = {}

function Decor.Walls(plotCF: CFrame, m: Model)
	local wallColor = Color3.fromRGB(150, 110, 230)
	local trim = Color3.fromRGB(255, 220, 80)
	m.PrimaryPart = part(m, plotCF, Vector3.new(100, 8, 1), Vector3.new(0, 5, -49.5), { Name = "BackWall", Color = wallColor })
	for _, x in { -49.5, 49.5 } do
		part(m, plotCF, Vector3.new(1, 8, 70), Vector3.new(x, 5, -15), { Name = "SideWall", Color = wallColor })
		part(m, plotCF, Vector3.new(1.4, 0.6, 70), Vector3.new(x, 9.2, -15), {
			Name = "Trim",
			Color = trim,
			Material = Enum.Material.Neon,
		})
	end
	part(m, plotCF, Vector3.new(100, 0.6, 1.4), Vector3.new(0, 9.2, -49.5), {
		Name = "Trim",
		Color = trim,
		Material = Enum.Material.Neon,
	})
end

function Decor.Lights(plotCF: CFrame, m: Model)
	local colors = {
		Color3.fromRGB(255, 80, 200),
		Color3.fromRGB(80, 220, 255),
		Color3.fromRGB(255, 230, 60),
		Color3.fromRGB(120, 255, 120),
	}
	for i, pos in { Vector3.new(-46, 0, 46), Vector3.new(46, 0, 46), Vector3.new(-46, 0, -46), Vector3.new(46, 0, -46) } do
		local pole = part(m, plotCF, Vector3.new(0.8, 14, 0.8), pos + Vector3.new(0, 8, 0), {
			Name = "Pole",
			Color = Color3.fromRGB(40, 40, 52),
			Material = Enum.Material.Metal,
		})
		if i == 1 then
			m.PrimaryPart = pole
		end
		local bulb = part(m, plotCF, Vector3.new(3, 3, 3), pos + Vector3.new(0, 16, 0), {
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Color = colors[i],
			Material = Enum.Material.Neon,
		})
		local light = Instance.new("PointLight")
		light.Color = colors[i]
		light.Range = 30
		light.Brightness = 2
		light.Parent = bulb
	end
end

function Decor.Sign(plotCF: CFrame, m: Model)
	for _, x in { -16, 16 } do
		part(m, plotCF, Vector3.new(1.5, 22, 1.5), Vector3.new(x, 12, -46), {
			Name = "Pole",
			Color = Color3.fromRGB(40, 40, 52),
			Material = Enum.Material.Metal,
		})
	end
	local board = part(m, plotCF, Vector3.new(40, 10, 1), Vector3.new(0, 20, -46), {
		Name = "Board",
		Color = Color3.fromRGB(25, 15, 45),
	})
	m.PrimaryPart = board
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 200)
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "🧠 BRAINROT FACTORY 🏭"
	label.TextColor3 = Color3.fromRGB(255, 120, 230)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 220, 255)
	stroke.Thickness = 4
	stroke.Parent = label
end

local function tree(m: Model, plotCF: CFrame, pos: Vector3, leafColor: Color3)
	part(m, plotCF, Vector3.new(1.6, 8, 1.6), pos + Vector3.new(0, 5, 0), {
		Name = "Trunk",
		Color = Color3.fromRGB(110, 70, 40),
		Material = Enum.Material.Wood,
	})
	part(m, plotCF, Vector3.new(8, 8, 8), pos + Vector3.new(0, 11, 0), {
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Color = leafColor,
		Material = Enum.Material.Grass,
	})
end

function Decor.Garden(plotCF: CFrame, m: Model)
	m.PrimaryPart = part(m, plotCF, Vector3.new(12, 0.4, 20), Vector3.new(40, 1.2, -30), {
		Name = "Grass",
		Color = Color3.fromRGB(90, 200, 90),
		Material = Enum.Material.Grass,
	})
	tree(m, plotCF, Vector3.new(44, 0, -18), Color3.fromRGB(255, 150, 210))
	tree(m, plotCF, Vector3.new(36, 0, -44), Color3.fromRGB(90, 200, 90))
	tree(m, plotCF, Vector3.new(-44, 0, -18), Color3.fromRGB(255, 150, 210))
	local flowerColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 230, 60), Color3.fromRGB(180, 110, 255) }
	for i = 0, 8 do
		local x = 36 + (i % 3) * 4
		local z = -36 + (i // 3) * 5
		part(m, plotCF, Vector3.new(1.4, 1.4, 1.4), Vector3.new(x, 2, z), {
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Color = flowerColors[i % 3 + 1],
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
end

function Decor.Fountain(plotCF: CFrame, m: Model)
	local center = Vector3.new(-22, 0, -32)
	local basin = part(m, plotCF, Vector3.new(2, 12, 12), center + Vector3.new(0, 2, 0), {
		Name = "Basin",
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(220, 220, 235),
		Material = Enum.Material.Marble,
	})
	basin.CFrame = basin.CFrame * CFrame.Angles(0, 0, math.rad(90))
	m.PrimaryPart = basin
	local water = part(m, plotCF, Vector3.new(0.4, 10.5, 10.5), center + Vector3.new(0, 3.05, 0), {
		Name = "Water",
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(60, 230, 120),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		CanCollide = false,
	})
	water.CFrame = water.CFrame * CFrame.Angles(0, 0, math.rad(90))
	local spout = part(m, plotCF, Vector3.new(1.5, 7, 1.5), center + Vector3.new(0, 5.5, 0), {
		Name = "Spout",
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Foil,
	})
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(80, 255, 140))
	emitter.Size = NumberSequence.new(0.8, 0.2)
	emitter.Speed = NumberRange.new(12, 16)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Lifetime = NumberRange.new(1, 1.3)
	emitter.Rate = 40
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = spout
	Builders.Billboard(spout, "💵", Vector2.new(3, 3), 6, 100)
end

function Decor.Statue(plotCF: CFrame, m: Model)
	local center = Vector3.new(22, 0, -32)
	local gold = Color3.fromRGB(255, 200, 40)
	m.PrimaryPart = part(m, plotCF, Vector3.new(8, 3, 8), center + Vector3.new(0, 2.5, 0), {
		Name = "Pedestal",
		Color = Color3.fromRGB(60, 60, 75),
		Material = Enum.Material.Marble,
	})
	for _, x in { -1.2, 1.2 } do
		part(m, plotCF, Vector3.new(1.8, 4, 1.8), center + Vector3.new(x, 6, 0), { Name = "Leg", Color = gold, Material = Enum.Material.Foil })
	end
	part(m, plotCF, Vector3.new(5, 5, 3.5), center + Vector3.new(0, 10.5, 0), { Name = "Body", Color = gold, Material = Enum.Material.Foil })
	local head = part(m, plotCF, Vector3.new(5, 5, 5), center + Vector3.new(0, 15.5, 0), {
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Color = gold,
		Material = Enum.Material.Foil,
	})
	Builders.Billboard(head, "🧠", Vector2.new(3, 3), 4, 120)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = gold
	sparkles.Parent = head
end

function Decor.Throne(plotCF: CFrame, m: Model)
	local center = Vector3.new(0, 0, -38)
	local purple = Color3.fromRGB(140, 60, 255)
	local gold = Color3.fromRGB(255, 200, 40)
	m.PrimaryPart = part(m, plotCF, Vector3.new(14, 1, 10), center + Vector3.new(0, 1.5, 0), { Name = "Step1", Color = gold, Material = Enum.Material.Foil })
	part(m, plotCF, Vector3.new(10, 1, 7), center + Vector3.new(0, 2.5, -0.5), { Name = "Step2", Color = purple })
	local seat = Instance.new("Seat")
	seat.Anchored = true
	seat.Size = Vector3.new(5, 1.5, 4)
	seat.CFrame = plotCF * CFrame.new(center + Vector3.new(0, 3.75, -1)) * CFrame.Angles(0, math.pi, 0)
	seat.Color = Color3.fromRGB(200, 40, 80)
	seat.Material = Enum.Material.Fabric
	seat.Parent = m
	part(m, plotCF, Vector3.new(6, 10, 1.2), center + Vector3.new(0, 8, -3.4), { Name = "Back", Color = purple, Material = Enum.Material.Neon })
	for _, x in { -2.5, 2.5 } do
		part(m, plotCF, Vector3.new(1, 2, 4), center + Vector3.new(x, 5, -1), { Name = "Arm", Color = gold, Material = Enum.Material.Foil })
	end
	local crown = part(m, plotCF, Vector3.new(3, 2, 3), center + Vector3.new(0, 14, -3.4), { Name = "Crown", Color = gold, Material = Enum.Material.Foil })
	Builders.Billboard(crown, "👑", Vector2.new(4, 4), 3, 150)
end

function Decor.Rocket(plotCF: CFrame, m: Model)
	local center = Vector3.new(-40, 0, -40)
	part(m, plotCF, Vector3.new(12, 1, 12), center + Vector3.new(0, 1.5, 0), {
		Name = "Pad",
		Color = Color3.fromRGB(50, 50, 60),
		Material = Enum.Material.DiamondPlate,
	})
	local body = part(m, plotCF, Vector3.new(20, 6, 6), center + Vector3.new(0, 13, 0), {
		Name = "Body",
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(240, 240, 250),
	})
	body.CFrame = body.CFrame * CFrame.Angles(0, 0, math.rad(90))
	m.PrimaryPart = body
	local nose = part(m, plotCF, Vector3.new(6, 6, 6), center + Vector3.new(0, 23, 0), {
		Name = "Nose",
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(255, 60, 120),
	})
	Builders.Billboard(nose, "🧠", Vector2.new(4, 4), 5, 200)
	for i = 0, 3 do
		local angle = math.rad(i * 90)
		local offset = Vector3.new(math.cos(angle) * 3.5, 5, math.sin(angle) * 3.5)
		local fin = part(m, plotCF, Vector3.new(1, 6, 3), center + offset, {
			Name = "Fin",
			Color = Color3.fromRGB(255, 60, 120),
		})
		fin.CFrame = plotCF * CFrame.new(center + offset) * CFrame.Angles(0, -angle, 0)
	end
	local flame = part(m, plotCF, Vector3.new(2, 2, 2), center + Vector3.new(0, 2.5, 0), {
		Name = "Flame",
		Transparency = 1,
		CanCollide = false,
	})
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 15
	fire.Color = Color3.fromRGB(255, 120, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 230, 60)
	fire.Parent = flame
end

function Builders.Decor(item: any, plotCF: CFrame, parent: Instance): Model
	local builder = Decor[item.Build]
	assert(builder, `No decor builder named {item.Build}`)
	local m = model(item.Id, parent)
	builder(plotCF, m)
	return m
end

----------------------------------------------------------------------------------------
-- Drops (the brainrot creatures riding the conveyor)
----------------------------------------------------------------------------------------

-- A drop is an invisible physics box carrying a welded mini model of the brainrot.
function Builders.Drop(def: any, mutation: any?, spawnCF: CFrame, parent: Instance): BasePart
	local root = Instance.new("Part")
	root.Name = "Drop"
	root.Size = Vector3.new(2.2, 2.2, 2.2)
	root.Transparency = 1
	root.CFrame = spawnCF * CFrame.Angles(0, -math.pi / 2, 0) -- face the way the belt moves
	root.CollisionGroup = "Drops"
	root.CanQuery = false

	local mini = CharacterKit.Build(def, "Mini")
	CharacterKit.ApplyMutation(mini, if mutation then mutation.Name else nil)
	mini:PivotTo(root.CFrame)
	for _, descendant in mini:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.CollisionGroup = "Drops"
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
	mini.Parent = root

	if mutation then
		root:SetAttribute("Mutation", mutation.Name)
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = mutation.Color
		sparkles.Parent = root
		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.fromScale(5, 1)
		tag.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
		tag.MaxDistance = 90
		tag.LightInfluence = 0
		tag.Parent = root
		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Font = Enum.Font.FredokaOne
		tagLabel.TextScaled = true
		tagLabel.Text = string.upper(mutation.Name)
		tagLabel.TextColor3 = mutation.Color
		tagLabel.Parent = tag
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = tagLabel
	end

	root.Parent = parent
	return root
end

return Builders
