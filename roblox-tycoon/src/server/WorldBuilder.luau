--[[
	Builds the lobby, lighting, ground, paths and scenery.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Builders = require(script.Parent.Builders)

local WorldBuilder = {}

local ORIGIN = CFrame.new()

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.Ambient = Color3.fromRGB(80, 70, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 180)

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Color = Color3.fromRGB(200, 190, 255)
	atmosphere.Decay = Color3.fromRGB(120, 100, 200)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Saturation = 0.2
	color.Contrast = 0.08
	color.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.06
	sunRays.Parent = Lighting
end

local function setupGround(parent: Instance)
	local ground = workspace:FindFirstChild("Baseplate") :: BasePart?
	if not ground then
		ground = Builders.Part(parent, ORIGIN, Vector3.new(2048, 16, 2048), Vector3.new(0, -8, 0), { Name = "Baseplate" })
	end
	local g = ground :: BasePart
	g.Color = Color3.fromRGB(100, 200, 110)
	g.Material = Enum.Material.Grass
	g.Locked = true
	local texture = g:FindFirstChildOfClass("Texture")
	if texture then
		texture:Destroy()
	end
end

local function cylinder(parent: Instance, diameter: number, height: number, centre: Vector3, props): Part
	local p = Builders.Part(parent, ORIGIN, Vector3.new(height, diameter, diameter), centre, props)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(centre) * CFrame.Angles(0, 0, math.rad(90))
	return p
end

local function makeBoard(parent: Instance, angleDegrees: number, radius: number, size: Vector2): (Part, Frame)
	local angle = math.rad(angleDegrees)
	local position = Vector3.new(math.cos(angle) * radius, 1 + size.Y / 2 + 1, math.sin(angle) * radius)
	local board = Builders.Part(parent, ORIGIN, Vector3.new(size.X, size.Y, 1), position, {
		Name = "Board",
		Color = Color3.fromRGB(25, 15, 45),
	})
	board.CFrame = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 30)
	padding.PaddingRight = UDim.new(0, 30)
	padding.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local trim = Builders.Part(parent, ORIGIN, Vector3.new(size.X + 1, size.Y + 1, 0.6), position, {
		Name = "Trim",
		Color = Color3.fromRGB(255, 80, 200),
		Material = Enum.Material.Neon,
	})
	trim.CFrame = board.CFrame * CFrame.new(0, 0, 0.6)
	return board, frame
end

local function boardLine(frame: Frame, text: string, height: number, color: Color3?, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.LayoutOrder = order
	label.Parent = frame
	return label
end

function WorldBuilder.Init()
	setupLighting()

	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace
	setupGround(world)

	-- Lobby platform + spawn.
	cylinder(world, 64, 1, Vector3.new(0, 0.5, 0), {
		Name = "Lobby",
		Color = Color3.fromRGB(60, 50, 90),
		Material = Enum.Material.Marble,
	})
	cylinder(world, 66, 0.8, Vector3.new(0, 0.4, 0), {
		Name = "LobbyRing",
		Color = Color3.fromRGB(255, 80, 200),
		Material = Enum.Material.Neon,
	})
	for _, existing in workspace:GetDescendants() do
		if existing:IsA("SpawnLocation") then
			existing:Destroy()
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 1.5, 0)
	spawn.Color = Color3.fromRGB(80, 220, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = world

	local titleAnchor = Builders.Part(world, ORIGIN, Vector3.one, Vector3.new(0, 28, 0), {
		Name = "TitleAnchor",
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local title = Builders.Billboard(titleAnchor, `🧠 {Config.GameName:upper()} 🏭`, Vector2.new(60, 8), 0, 600)
	title.TextColor3 = Color3.fromRGB(255, 220, 80)

	-- Paths from the lobby to each plot's front edge.
	for i = 1, Config.MaxPlots do
		local angle = (i - 1) / Config.MaxPlots * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local startRadius, endRadius = 31, Config.PlotRingRadius - Config.PlotSize / 2
		local centre = direction * (startRadius + endRadius) / 2 + Vector3.new(0, 0.3, 0)
		local path = Builders.Part(world, ORIGIN, Vector3.new(10, 0.6, endRadius - startRadius), centre, {
			Name = "Path",
			Color = Color3.fromRGB(230, 220, 200),
			Material = Enum.Material.Cobblestone,
		})
		path.CFrame = CFrame.lookAt(centre, centre + direction)
	end

	-- Scenery trees outside the plot ring (seeded so every server looks the same).
	local rng = Random.new(1337)
	local outer = Config.PlotRingRadius + Config.PlotSize * 0.75
	for _ = 1, 70 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(outer, outer + 220)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local height = rng:NextNumber(8, 16)
		Builders.Part(world, ORIGIN, Vector3.new(2, height, 2), base + Vector3.new(0, height / 2, 0), {
			Name = "Trunk",
			Color = Color3.fromRGB(110, 70, 40),
			Material = Enum.Material.Wood,
		})
		local leaves = rng:NextNumber(9, 16)
		local colors = { Color3.fromRGB(80, 180, 90), Color3.fromRGB(255, 150, 210), Color3.fromRGB(120, 210, 100) }
		Builders.Part(world, ORIGIN, Vector3.new(leaves, leaves, leaves), base + Vector3.new(0, height + leaves / 3, 0), {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Color = colors[rng:NextInteger(1, #colors)],
			Material = Enum.Material.Grass,
		})
	end

	-- Leaderboard board (filled in by LeaderboardService) between two paths.
	local _, leaderFrame = makeBoard(world, 22.5, 28, Vector2.new(14, 18))
	WorldBuilder.LeaderboardFrame = leaderFrame
	boardLine(leaderFrame, "🏆 TOP EARNERS", 70, Color3.fromRGB(255, 220, 80), 0)

	-- How-to-play board.
	local _, tips = makeBoard(world, 202.5, 28, Vector2.new(14, 18))
	boardLine(tips, "📖 HOW TO PLAY", 70, Color3.fromRGB(80, 220, 255), 0)
	local lines = {
		"1. Step on green buttons to build",
		"2. Brainrots ride the conveyor",
		"3. Walk on COLLECT to grab cash",
		"4. Rare GOLD / DIAMOND / RAINBOW",
		"   brainrots are worth way more!",
		"5. Finish your factory & REBIRTH",
		"   for a permanent multiplier",
		"",
		"👯 Play with friends: +10% each!",
		"🎁 Free gift every 8 minutes",
		"📅 Daily rewards - keep your streak!",
	}
	for i, line in lines do
		boardLine(tips, line, 48, nil, i)
	end
end

WorldBuilder.LeaderboardFrame = nil :: Frame?
WorldBuilder.BoardLine = boardLine

return WorldBuilder
