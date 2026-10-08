--[[
	Brainrot Factory Tycoon - client entry point.
	Builds the HUD and keeps it in sync with the player's attributes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script:WaitForChild("Ui"))
local Effects = require(script:WaitForChild("Effects"))
local Panels = require(script:WaitForChild("Panels"))
local Animator = require(script:WaitForChild("Animator"))

local player = Players.LocalPlayer
local Theme = Ui.Theme

local function attr(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function request(action: string, payload: any?): boolean
	local ok, result = pcall(function()
		return (Remotes:WaitForChild("Request") :: RemoteFunction):InvokeServer(action, payload)
	end)
	if not ok or type(result) ~= "table" then
		return false
	end
	if result.Message then
		Effects.Notify(result.Message, if result.Ok then "success" else "error")
	end
	return result.Ok == true
end

----------------------------------------------------------------------------------------
-- Screen
----------------------------------------------------------------------------------------

local screen = Ui.new("ScreenGui", {
	Name = "TycoonUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiScale = Ui.new("UIScale", { Parent = screen })
local function updateScale()
	local viewport = workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(viewport.X / 1150, viewport.Y / 680), 0.5, 1.2)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

Effects.Init(screen)
Panels.Init(screen, request)
Animator.Start()

-- Cash display
local cashPill = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 88),
	BackgroundColor3 = Theme.Panel,
	Parent = screen,
}, { Ui.corner(22), Ui.stroke(Theme.Green, 3.5) })
local cashLabel = Ui.label({
	Position = UDim2.fromOffset(16, 4),
	Size = UDim2.new(1, -32, 0, 52),
	Text = "$0",
	TextColor3 = Theme.Green,
	Parent = cashPill,
})
local incomeLabel = Ui.label({
	Position = UDim2.fromOffset(16, 56),
	Size = UDim2.new(1, -32, 0, 26),
	Text = "",
	TextColor3 = Theme.SubText,
	Parent = cashPill,
})
local cashScale = Ui.new("UIScale", { Parent = cashPill })

-- Event banners under the cash display
local bannerHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 100),
	Size = UDim2.fromOffset(460, 140),
	BackgroundTransparency = 1,
	Parent = screen,
}, { Ui.new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }) })

-- Left menu
local menu = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(90, 480),
	BackgroundTransparency = 1,
	Parent = screen,
}, { Ui.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

local menuButtons = {}
for i, entry in
	{
		{ Panel = "Shop", Emoji = "🛒", Label = "Shop", Color = Theme.Accent },
		{ Panel = "Index", Emoji = "📖", Label = "Index", Color = Color3.fromRGB(70, 170, 255) },
		{ Panel = "Rebirth", Emoji = "🔁", Label = "Rebirth", Color = Theme.Gold },
		{ Panel = "Daily", Emoji = "📅", Label = "Daily", Color = Theme.Cyan },
		{ Panel = "Codes", Emoji = "🎟️", Label = "Codes", Color = Theme.Green },
	}
do
	local button = Ui.button({
		Size = UDim2.fromOffset(84, 84),
		Text = "",
		BackgroundColor3 = entry.Color,
		LayoutOrder = i,
		Parent = menu,
	}, function()
		Panels.Toggle(entry.Panel)
	end)
	Ui.label({ Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 4), Text = entry.Emoji, Parent = button })
	Ui.label({ Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, 56), Text = entry.Label, Parent = button })
	local dot = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.Red,
		Visible = false,
		Parent = button,
	}, { Ui.corner(11), Ui.stroke(Theme.Outline, 2) })
	Ui.label({ Size = UDim2.fromScale(1, 1), Text = "!", Parent = dot })
	menuButtons[entry.Panel] = { Button = button, Dot = dot }
end

-- Free gift (right side)
local giftButton = Ui.button({
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(100, 110),
	Text = "",
	BackgroundColor3 = Theme.Accent,
	Parent = screen,
}, function()
	request("ClaimGift")
end)
Ui.label({ Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, 6), Text = "🎁", Parent = giftButton })
local giftLabel = Ui.label({ Size = UDim2.new(1, -10, 0, 34), Position = UDim2.fromOffset(5, 66), Text = "", Parent = giftButton })

-- Loading message until the server has set the player up.
local loading = Ui.label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(600, 60),
	Text = "Loading your factory... 🏭",
	Visible = not attr("Loaded", false),
	Parent = screen,
})
player:GetAttributeChangedSignal("Loaded"):Connect(function()
	loading.Visible = not attr("Loaded", false)
end)

----------------------------------------------------------------------------------------
-- Cash counter (smoothly counts up)
----------------------------------------------------------------------------------------

local shownCash = attr("Cash", 0)
local lastCash = shownCash
RunService.RenderStepped:Connect(function(dt)
	local target = attr("Cash", 0)
	if target > lastCash then
		cashScale.Scale = 1.08
		Ui.tween(cashScale, 0.25, { Scale = 1 })
	end
	lastCash = target
	shownCash += (target - shownCash) * math.min(1, dt * 10)
	if math.abs(target - shownCash) < 1 then
		shownCash = target
	end
	cashLabel.Text = Format.Cash(math.floor(shownCash))
end)

local function updateIncome()
	incomeLabel.Text = `+{Format.Cash(attr("IncomePerSec", 0))}/s   •   x{Format.Short(attr("Multiplier", 1))} cash`
end
player:GetAttributeChangedSignal("IncomePerSec"):Connect(updateIncome)
player:GetAttributeChangedSignal("Multiplier"):Connect(updateIncome)
updateIncome()

----------------------------------------------------------------------------------------
-- Own plot: button colours, guide arrow, bank popups
----------------------------------------------------------------------------------------

local AFFORDABLE = Color3.fromRGB(70, 220, 110)
local TOO_EXPENSIVE = Color3.fromRGB(230, 70, 90)

local guideBeam = Ui.new("Beam", {
	Color = ColorSequence.new(Theme.Gold),
	Width0 = 0.5,
	Width1 = 0.5,
	FaceCamera = true,
	LightEmission = 1,
	Transparency = NumberSequence.new(0.2),
	Enabled = false,
	Parent = workspace,
})
local guideTarget = Ui.new("Attachment", { Name = "GuideTarget" })
local guideArrow = Ui.new("BillboardGui", {
	Size = UDim2.fromOffset(70, 70),
	StudsOffsetWorldSpace = Vector3.new(0, 7, 0),
	AlwaysOnTop = true,
	Enabled = false,
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
})
Ui.label({ Size = UDim2.fromScale(1, 1), Text = "⬇️", Parent = guideArrow })

local function myPlot(): Model?
	local plotId = attr("PlotId", nil)
	local plots = workspace:FindFirstChild("Plots")
	if not plotId or not plots then
		return nil
	end
	return plots:FindFirstChild("Plot" .. plotId) :: Model?
end

local function updateButtons()
	local plot = myPlot()
	local buttons = plot and plot:FindFirstChild("Buttons")
	local cash = attr("Cash", 0)
	local cheapest: BasePart? = nil
	local cheapestPrice = math.huge
	if buttons then
		for _, button in buttons:GetChildren() do
			local pad = button:FindFirstChild("Pad") :: BasePart?
			local price = button:GetAttribute("Price")
			if pad and price then
				pad.Color = if cash >= price then AFFORDABLE else TOO_EXPENSIVE
				if price < cheapestPrice then
					cheapestPrice = price
					cheapest = pad
				end
			end
		end
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if cheapest and root then
		guideTarget.Parent = cheapest
		guideArrow.Adornee = cheapest
		guideArrow.Enabled = true
		local rootAttachment = root:FindFirstChild("GuideAttachment") :: Attachment?
		if not rootAttachment then
			rootAttachment = Ui.new("Attachment", { Name = "GuideAttachment", Parent = root })
		end
		guideBeam.Attachment0 = rootAttachment
		guideBeam.Attachment1 = guideTarget
		local close = (root.Position - cheapest.Position).Magnitude < 8
		guideBeam.Enabled = cash >= cheapestPrice and not close
	else
		guideArrow.Enabled = false
		guideBeam.Enabled = false
	end
end

-- Bouncing guide arrow
task.spawn(function()
	while true do
		Ui.tween(guideArrow, 0.5, { StudsOffsetWorldSpace = Vector3.new(0, 8.5, 0) }, Enum.EasingStyle.Sine).Completed:Wait()
		Ui.tween(guideArrow, 0.5, { StudsOffsetWorldSpace = Vector3.new(0, 7, 0) }, Enum.EasingStyle.Sine).Completed:Wait()
	end
end)

-- "+$X" popups over the collector as the bank fills.
local bankConnection: RBXScriptConnection? = nil
local pendingBank = 0
local lastBank = 0
local function watchBank()
	if bankConnection then
		bankConnection:Disconnect()
		bankConnection = nil
	end
	local plot = myPlot()
	if not plot then
		return
	end
	lastBank = plot:GetAttribute("Bank") or 0
	bankConnection = plot:GetAttributeChangedSignal("Bank"):Connect(function()
		local bank = plot:GetAttribute("Bank") or 0
		if bank > lastBank then
			pendingBank += bank - lastBank
		end
		lastBank = bank
	end)
end
player:GetAttributeChangedSignal("PlotId"):Connect(watchBank)
watchBank()

task.spawn(function()
	while true do
		task.wait(0.7)
		if pendingBank > 0 then
			local plot = myPlot()
			local anchor = plot and plot:FindFirstChild("BankAnchor", true) :: BasePart?
			if anchor then
				Effects.CashPopup(pendingBank, anchor.Position - Vector3.new(0, 4, 0))
			end
			pendingBank = 0
		end
	end
end)

----------------------------------------------------------------------------------------
-- Event banners
----------------------------------------------------------------------------------------

local banners: { [string]: TextLabel } = {}
local function updateBanners()
	for key, event in Config.Events do
		local endsAt = ReplicatedStorage:GetAttribute("Event_" .. key)
		local active = endsAt and endsAt > serverNow()
		local banner = banners[key]
		if active and not banner then
			local frame = Ui.new("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Theme.Panel,
				Parent = bannerHolder,
			}, { Ui.corner(20), Ui.stroke(Theme.Gold, 3) })
			banner = Ui.label({
				Size = UDim2.new(1, -20, 1, -8),
				Position = UDim2.fromOffset(10, 4),
				TextColor3 = Theme.Gold,
				Parent = frame,
			})
			banners[key] = banner
		elseif not active and banner then
			(banner.Parent :: Instance):Destroy()
			banners[key] = nil
			banner = nil
		end
		if banner then
			local effect = if event.CashMultiplier > 1
				then `{event.CashMultiplier}x CASH`
				else `{event.LuckMultiplier}x LUCK`
			banner.Text = `{event.Emoji} {event.Name} - {effect} - {Format.Time(endsAt - serverNow())}`
		end
	end
end

----------------------------------------------------------------------------------------
-- Periodic refresh (countdowns, dots, panels)
----------------------------------------------------------------------------------------

task.spawn(function()
	while true do
		local now = serverNow()
		local giftAt = attr("NextGiftAt", math.huge)
		if now >= giftAt then
			giftLabel.Text = "CLAIM!"
			giftButton.BackgroundColor3 = Theme.Green
		else
			giftLabel.Text = if giftAt == math.huge then "..." else Format.Time(giftAt - now)
			giftButton.BackgroundColor3 = Theme.Accent
		end
		menuButtons.Daily.Dot.Visible = attr("Loaded", false) and now >= attr("DailyReadyAt", math.huge)
		menuButtons.Rebirth.Dot.Visible = attr("Cash", 0) >= attr("RebirthCost", math.huge)

		updateBanners()
		updateButtons()
		Panels.Refresh()
		task.wait(0.5)
	end
end)

----------------------------------------------------------------------------------------
-- Server messages
----------------------------------------------------------------------------------------

Remotes:WaitForChild("Notify").OnClientEvent:Connect(Effects.Notify)
Remotes:WaitForChild("CashPopup").OnClientEvent:Connect(Effects.CashPopup)
Remotes:WaitForChild("Celebrate").OnClientEvent:Connect(Effects.Celebrate)

----------------------------------------------------------------------------------------
-- Chat tags: [VIP] and rebirth count
----------------------------------------------------------------------------------------

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker then
		local prefix = ""
		if speaker:GetAttribute("VIP") then
			prefix ..= "<font color='#FFC832'>[VIP]</font> "
		end
		local rebirths = speaker:GetAttribute("Rebirths") or 0
		if rebirths > 0 then
			prefix ..= `<font color='#FF50C8'>[R{rebirths}]</font> `
		end
		properties.PrefixText = prefix .. message.PrefixText
	end
	return properties
end

print("[BrainrotTycoon] Client ready")
