--[[
	Pop-up panels: Shop, Rebirth, Daily rewards, Codes.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterKit = require(Shared:WaitForChild("CharacterKit"))
local CharacterRegistry = require(Shared:WaitForChild("CharacterRegistry"))
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Items = require(Shared:WaitForChild("Items"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Ui = require(script.Parent.Ui)
local Effects = require(script.Parent.Effects)
local Animator = require(script.Parent.Animator)

local Panels = {}

local player = Players.LocalPlayer
local PASS_ORDER = { "DoubleCash", "AutoCollect", "LuckyMutations", "FastDroppers", "VIP" }
local PRODUCT_ORDER = { "CashSmall", "CashMedium", "CashLarge", "RainbowRain", "CashFrenzy" }
local TEST_MODE = RunService:IsStudio() and Config.StudioFreePurchases

type Request = (action: string, payload: any?) -> boolean

local request: Request
local panels: { [string]: Frame } = {}
local refreshers: { () -> () } = {}
local openName: string? = nil

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

----------------------------------------------------------------------------------------
-- Panel frame
----------------------------------------------------------------------------------------

local function makePanel(screen: ScreenGui, name: string, title: string, color: Color3): Frame
	local panel = Ui.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(580, 430),
		BackgroundColor3 = Ui.Theme.Panel,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	}, {
		Ui.corner(18),
		Ui.stroke(color, 4),
		Ui.new("UIScale", { Name = "PopScale" }),
	})
	local header = Ui.new("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = color,
		ZIndex = 21,
		Parent = panel,
	}, { Ui.corner(18), Ui.gradient(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) })
	Ui.label({
		Size = UDim2.new(1, -140, 0, 44),
		Position = UDim2.fromOffset(20, 8),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
		Parent = header,
	})
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(44, 44),
		Text = "X",
		BackgroundColor3 = Ui.Theme.Red,
		ZIndex = 23,
		Parent = header,
	}, function()
		Panels.Close()
	end)

	local body = Ui.new("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(1, -32, 1, -86),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = panel,
	})
	panels[name] = panel
	return body
end

function Panels.Close()
	if openName then
		panels[openName].Visible = false
		openName = nil
	end
end

function Panels.Open(name: string)
	Panels.Close()
	local panel = panels[name]
	panel.Visible = true
	openName = name
	local scale = panel:FindFirstChild("PopScale") :: UIScale
	scale.Scale = 0.7
	Ui.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	Panels.Refresh()
end

function Panels.Toggle(name: string)
	if openName == name then
		Panels.Close()
	else
		Panels.Open(name)
	end
end

function Panels.Refresh()
	for _, refresh in refreshers do
		refresh()
	end
end

----------------------------------------------------------------------------------------
-- Shop
----------------------------------------------------------------------------------------

local function sectionTitle(parent: Instance, text: string, order: number)
	Ui.label({
		Size = UDim2.new(1, 0, 0, 34),
		Text = text,
		TextColor3 = Ui.Theme.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		ZIndex = 22,
		Parent = parent,
	})
end

local function shopCard(parent: Instance, order: number, emoji: string, name: string, onBuy: () -> ()): (TextLabel, TextButton)
	local card = Ui.new("Frame", {
		Size = UDim2.new(1, -10, 0, 86),
		BackgroundColor3 = Ui.Theme.PanelLight,
		LayoutOrder = order,
		ZIndex = 22,
		Parent = parent,
	}, { Ui.corner(14) })
	Ui.label({ Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(10, 11), Text = emoji, ZIndex = 23, Parent = card })
	Ui.label({
		Size = UDim2.new(1, -230, 0, 32),
		Position = UDim2.fromOffset(84, 8),
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
		Parent = card,
	})
	local description = Ui.label({
		Size = UDim2.new(1, -230, 0, 36),
		Position = UDim2.fromOffset(84, 42),
		Text = "",
		TextColor3 = Ui.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 23,
		Parent = card,
	})
	local button = Ui.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(130, 52),
		Text = "...",
		ZIndex = 23,
		Parent = card,
	}, onBuy)
	return description, button
end

local function fetchPrice(id: number, infoType: Enum.InfoType, button: TextButton)
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			button:SetAttribute("PriceText", `R$ {info.PriceInRobux}`)
			Panels.Refresh()
		end
	end)
end

local function buildShop(screen: ScreenGui)
	local body = makePanel(screen, "Shop", "🛒 SHOP", Ui.Theme.Accent)
	local scroll = Ui.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 22,
		Parent = body,
	}, { Ui.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })

	sectionTitle(scroll, "💎 GAME PASSES (forever!)", 0)
	for i, key in PASS_ORDER do
		local pass = Config.GamePasses[key]
		local description, button
		description, button = shopCard(scroll, i, pass.Emoji, pass.Name, function()
			if attr("Pass_" .. key, false) then
				return
			end
			if pass.Id > 0 then
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			elseif TEST_MODE then
				request("TestPurchase", { Kind = "Pass", Key = key })
			else
				Effects.Notify("Coming soon!", "info")
			end
		end)
		description.Text = pass.Description
		if pass.Id > 0 then
			fetchPrice(pass.Id, Enum.InfoType.GamePass, button)
		end
		table.insert(refreshers, function()
			if attr("Pass_" .. key, false) then
				button.Text = "OWNED ✅"
				button.BackgroundColor3 = Ui.Theme.PanelLight
			else
				button.Text = button:GetAttribute("PriceText") or (if TEST_MODE then "TEST FREE" else "SOON")
				button.BackgroundColor3 = Ui.Theme.Green
			end
		end)
	end

	sectionTitle(scroll, "💰 CASH PACKS & SERVER BOOSTS", 100)
	for i, key in PRODUCT_ORDER do
		local product = Config.Products[key]
		local description, button
		description, button = shopCard(scroll, 100 + i, product.Emoji, product.Name, function()
			if product.Id > 0 then
				MarketplaceService:PromptProductPurchase(player, product.Id)
			elseif TEST_MODE then
				request("TestPurchase", { Kind = "Product", Key = key })
			else
				Effects.Notify("Coming soon!", "info")
			end
		end)
		if product.Id > 0 then
			fetchPrice(product.Id, Enum.InfoType.Product, button)
		end
		table.insert(refreshers, function()
			if product.Kind == "Cash" then
				local amount = Economy.ScaledReward(attr("IncomePerSec", 0), product.IncomeSeconds, product.Minimum)
				description.Text = `Get {Format.Cash(amount)} instantly!`
			else
				local event = Config.Events[product.Event]
				local effect = if event.CashMultiplier > 1
					then `{event.CashMultiplier}x cash`
					else `{event.LuckMultiplier}x mutation luck`
				description.Text = `{effect} for EVERYONE for {event.Duration // 60} min!`
			end
			button.Text = button:GetAttribute("PriceText") or (if TEST_MODE then "TEST FREE" else "SOON")
		end)
	end
end

----------------------------------------------------------------------------------------
-- Rebirth
----------------------------------------------------------------------------------------

local function buildRebirth(screen: ScreenGui)
	local body = makePanel(screen, "Rebirth", "🔁 REBIRTH", Ui.Theme.Gold)
	local info = Ui.label({ Size = UDim2.new(1, 0, 0, 40), Text = "", ZIndex = 22, Parent = body })
	local multiplier = Ui.label({
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 60),
		Text = "",
		TextColor3 = Ui.Theme.Gold,
		ZIndex = 22,
		Parent = body,
	})
	local barBack = Ui.new("Frame", {
		Position = UDim2.fromOffset(0, 124),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Ui.Theme.Outline,
		ZIndex = 22,
		Parent = body,
	}, { Ui.corner(20) })
	local barFill = Ui.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.Theme.Gold,
		ZIndex = 23,
		Parent = barBack,
	}, { Ui.corner(20), Ui.gradient(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 150, 40)) })
	local barText = Ui.label({
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		Text = "",
		ZIndex = 24,
		Parent = barBack,
	})
	Ui.label({
		Position = UDim2.fromOffset(0, 176),
		Size = UDim2.new(1, 0, 0, 56),
		Text = "Rebirthing resets your cash and factory,\nbut your cash multiplier is PERMANENT!",
		TextColor3 = Ui.Theme.SubText,
		ZIndex = 22,
		Parent = body,
	})
	local button = Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(280, 70),
		Text = "REBIRTH",
		ZIndex = 22,
		Parent = body,
	}, function()
		if request("Rebirth") then
			Panels.Close()
		end
	end)

	table.insert(refreshers, function()
		local rebirths = attr("Rebirths", 0)
		local cost = attr("RebirthCost", Economy.RebirthCost(rebirths))
		local cash = attr("Cash", 0)
		info.Text = `Rebirths: {rebirths}`
		multiplier.Text = `x{Economy.RebirthMultiplier(rebirths)} ➜ x{Economy.RebirthMultiplier(rebirths + 1)} cash`
		local progress = math.clamp(cash / cost, 0, 1)
		barFill.Size = UDim2.fromScale(progress, 1)
		barText.Text = `{Format.Cash(cash)} / {Format.Cash(cost)}`
		button.BackgroundColor3 = if cash >= cost then Ui.Theme.Green else Ui.Theme.PanelLight
	end)
end

----------------------------------------------------------------------------------------
-- Daily rewards
----------------------------------------------------------------------------------------

local function buildDaily(screen: ScreenGui)
	local body = makePanel(screen, "Daily", "📅 DAILY REWARDS", Ui.Theme.Cyan)
	local row = Ui.new("Frame", {
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundTransparency = 1,
		ZIndex = 22,
		Parent = body,
	}, {
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local tiles = {}
	for day = 1, #Config.DailyRewards do
		local tile = Ui.new("Frame", {
			Size = UDim2.new(1 / #Config.DailyRewards, -6, 1, 0),
			BackgroundColor3 = Ui.Theme.PanelLight,
			LayoutOrder = day,
			ZIndex = 22,
			Parent = row,
		}, { Ui.corner(12), Ui.stroke(Ui.Theme.Outline, 3) })
		Ui.label({ Size = UDim2.new(1, -8, 0, 26), Position = UDim2.fromOffset(4, 6), Text = `Day {day}`, ZIndex = 23, Parent = tile })
		Ui.label({
			Size = UDim2.new(1, -8, 0, 44),
			Position = UDim2.fromOffset(4, 36),
			Text = if day == #Config.DailyRewards then "🏆" else "💵",
			ZIndex = 23,
			Parent = tile,
		})
		local amount = Ui.label({
			Size = UDim2.new(1, -8, 0, 26),
			Position = UDim2.fromOffset(4, 110),
			Text = "",
			TextColor3 = Ui.Theme.Green,
			ZIndex = 23,
			Parent = tile,
		})
		tiles[day] = { Tile = tile, Amount = amount }
	end
	local status = Ui.label({
		Position = UDim2.fromOffset(0, 165),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextColor3 = Ui.Theme.SubText,
		ZIndex = 22,
		Parent = body,
	})
	local button = Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(280, 70),
		Text = "CLAIM!",
		ZIndex = 22,
		Parent = body,
	}, function()
		request("ClaimDaily")
	end)

	table.insert(refreshers, function()
		local streak = attr("DailyStreak", 0)
		local readyAt = attr("DailyReadyAt", 0)
		local lastClaim = readyAt - Config.DailyCooldown
		local ready = serverNow() >= readyAt
		local streakAlive = serverNow() - lastClaim <= Config.DailyStreakWindow
		local nextDay = if streakAlive then streak % #Config.DailyRewards + 1 else 1
		local income = attr("IncomePerSec", 0)
		for day, tile in tiles do
			local reward = Config.DailyRewards[day]
			tile.Amount.Text = Format.Cash(Economy.ScaledReward(income, reward.IncomeSeconds, reward.Minimum))
			local stroke = tile.Tile:FindFirstChildOfClass("UIStroke") :: UIStroke
			stroke.Color = if day == nextDay then Ui.Theme.Gold else Ui.Theme.Outline
		end
		if ready then
			status.Text = `Streak: {if streakAlive then streak else 0} days 🔥  Claim Day {nextDay}!`
			button.Text = "CLAIM!"
			button.BackgroundColor3 = Ui.Theme.Green
		else
			status.Text = `Streak: {streak} days 🔥  Don't break it!`
			button.Text = Format.Time(readyAt - serverNow())
			button.BackgroundColor3 = Ui.Theme.PanelLight
		end
	end)
end

----------------------------------------------------------------------------------------
-- Codes
----------------------------------------------------------------------------------------

local function buildCodes(screen: ScreenGui)
	local body = makePanel(screen, "Codes", "🎟️ CODES", Ui.Theme.Green)
	Ui.label({
		Size = UDim2.new(1, 0, 0, 50),
		Text = "Follow us for new codes! 👀",
		TextColor3 = Ui.Theme.SubText,
		ZIndex = 22,
		Parent = body,
	})
	local box = Ui.new("TextBox", {
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = Ui.Theme.PanelLight,
		PlaceholderText = "Enter code...",
		PlaceholderColor3 = Ui.Theme.SubText,
		Text = "",
		Font = Ui.Theme.Font,
		TextScaled = true,
		TextColor3 = Ui.Theme.Text,
		ClearTextOnFocus = false,
		ZIndex = 22,
		Parent = body,
	}, { Ui.corner(14), Ui.stroke(Ui.Theme.Outline, 3), Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
	Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(280, 70),
		Text = "REDEEM",
		ZIndex = 22,
		Parent = body,
	}, function()
		if box.Text ~= "" and request("RedeemCode", box.Text) then
			box.Text = ""
		end
	end)
end

----------------------------------------------------------------------------------------
-- Brainrot Index
----------------------------------------------------------------------------------------

local VARIANTS = Economy.IndexVariants()
local VARIANT_ICONS = { Normal = "⚪", Gold = "🟡", Diamond = "💎", Rainbow = "🌈" }
local SILHOUETTE = Color3.fromRGB(22, 18, 34)

local valueByCharacter: { [string]: number } = {}
for _, item in Items.List do
	if item.Type == "Dropper" and item.Character then
		valueByCharacter[item.Character] = item.Value
	end
end

local function discovered(characterId: string, variant: string): boolean
	return player:GetAttribute(`Idx_{characterId}_{variant}`) == true
end

-- Builds (or rebuilds) a character inside a ViewportFrame. Undiscovered = silhouette.
local function fillViewport(viewport: ViewportFrame, def: any, known: boolean, distance: number)
	viewport:ClearAllChildren()
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local model = CharacterKit.Build(def, "Full")
	if not known then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Color = SILHOUETTE
				descendant.Material = Enum.Material.SmoothPlastic
				descendant.Reflectance = 0
			elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Light") or descendant:IsA("SurfaceGui") then
				descendant:Destroy()
			end
		end
	end
	model:PivotTo(CFrame.Angles(0, math.rad(-25), 0)) -- slight 3/4 view (characters face the camera at -Z)
	model.Parent = world
	if known then
		Animator.Track(model)
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 5.2, -distance), Vector3.new(0, 4.4, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport:SetAttribute("Known", known)
	viewport:SetAttribute("Spin", known)
end

local turntables: { ViewportFrame } = {}

local function buildIndex(screen: ScreenGui)
	local body = makePanel(screen, "Index", "📖 BRAINROT INDEX", Ui.Theme.Cyan)
	local summary = Ui.label({
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		TextColor3 = Ui.Theme.SubText,
		ZIndex = 22,
		Parent = body,
	})
	local scroll = Ui.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 22,
		Parent = body,
	}, {
		Ui.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(126, 178),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Detail view (covers the grid when a card is clicked)
	local detail = Ui.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Ui.Theme.Panel,
		Visible = false,
		ZIndex = 30,
		Parent = body,
	})
	local detailViewport = Ui.new("ViewportFrame", {
		Size = UDim2.new(0, 230, 1, 0),
		BackgroundColor3 = Ui.Theme.PanelLight,
		Ambient = Color3.fromRGB(170, 170, 190),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.4, -1, 0.6),
		ZIndex = 31,
		Parent = detail,
	}, { Ui.corner(14) })
	table.insert(turntables, detailViewport)
	local detailName = Ui.label({
		Position = UDim2.fromOffset(244, 0),
		Size = UDim2.new(1, -244, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
		Parent = detail,
	})
	local detailRarity = Ui.label({
		Position = UDim2.fromOffset(244, 42),
		Size = UDim2.new(1, -244, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
		Parent = detail,
	})
	local detailText = Ui.label({
		Position = UDim2.fromOffset(244, 76),
		Size = UDim2.new(1, -244, 0, 130),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextScaled = false,
		TextSize = 17,
		TextColor3 = Ui.Theme.SubText,
		ZIndex = 31,
		Parent = detail,
	})
	local detailVariants = Ui.label({
		Position = UDim2.fromOffset(244, 212),
		Size = UDim2.new(1, -244, 0, 50),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 31,
		Parent = detail,
	})
	Ui.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(140, 48),
		Text = "◀ BACK",
		BackgroundColor3 = Ui.Theme.PanelLight,
		ZIndex = 32,
		Parent = detail,
	}, function()
		detail.Visible = false
	end)
	local detailDef: any = nil

	local function refreshDetail()
		if not detailDef or not detail.Visible then
			return
		end
		local def = detailDef
		local tier = Rarity.Get(def.Rarity)
		local known = discovered(def.Id, "Normal")
		if detailViewport:GetAttribute("CharacterId") ~= def.Id or detailViewport:GetAttribute("Known") ~= known then
			fillViewport(detailViewport, def, known, 13)
			detailViewport:SetAttribute("CharacterId", def.Id)
		end
		detailName.Text = if known then `{def.Emoji} {def.Name}` else "??? Undiscovered"
		detailRarity.Text = tier.Name:upper()
		detailRarity.TextColor3 = tier.Color
		if known then
			detailText.Text = `"{def.Tagline}"\n\n{def.Lore}\n\nWorth {Format.Cash(valueByCharacter[def.Id] or 0)} per drop.`
		else
			detailText.Text = "Build its dropper to discover this brainrot!"
		end
		local parts = {}
		for _, variant in VARIANTS do
			local have = discovered(def.Id, variant)
			table.insert(parts, `{if have then VARIANT_ICONS[variant] else "🔒"} {variant}`)
		end
		detailVariants.Text = table.concat(parts, "   ")
	end

	local cards = {}
	for order, def in CharacterRegistry.Ordered do
		local tier = Rarity.Get(def.Rarity)
		local card = Ui.new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Ui.Theme.PanelLight,
			LayoutOrder = order,
			ZIndex = 22,
			Parent = scroll,
		}, { Ui.corner(12), Ui.stroke(tier.Color, 3) })
		local viewport = Ui.new("ViewportFrame", {
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.new(1, -8, 0, 112),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(170, 170, 190),
			LightDirection = Vector3.new(-0.4, -1, 0.6),
			ZIndex = 23,
			Parent = card,
		})
		table.insert(turntables, viewport)
		local name = Ui.label({
			Position = UDim2.fromOffset(4, 116),
			Size = UDim2.new(1, -8, 0, 20),
			Text = "",
			ZIndex = 23,
			Parent = card,
		})
		local rarityLabel = Ui.label({
			Position = UDim2.fromOffset(4, 136),
			Size = UDim2.new(1, -8, 0, 16),
			Text = tier.Name:upper(),
			TextColor3 = tier.Color,
			ZIndex = 23,
			Parent = card,
		})
		local variants = Ui.label({
			Position = UDim2.fromOffset(4, 154),
			Size = UDim2.new(1, -8, 0, 18),
			Text = "",
			ZIndex = 23,
			Parent = card,
		})
		card.Activated:Connect(function()
			Ui.playClick()
			detailDef = def
			detail.Visible = true
			refreshDetail()
		end)
		cards[def.Id] = { Viewport = viewport, Name = name, Rarity = rarityLabel, Variants = variants, Def = def }
	end

	table.insert(refreshers, function()
		if not Panels.IsOpen("Index") then
			return
		end
		local count = player:GetAttribute("IndexCount") or 0
		local total = #CharacterRegistry.Ordered * #VARIANTS
		summary.Text = `{count} / {total} discovered   •   +{Format.Short(Economy.IndexBonus(count) * 100)}% cash forever`
		for id, card in cards do
			local known = discovered(id, "Normal")
			if card.Viewport:GetAttribute("Known") ~= known then
				fillViewport(card.Viewport, card.Def, known, 15)
			end
			card.Name.Text = if known then card.Def.Name else "???"
			local icons = {}
			for _, variant in VARIANTS do
				table.insert(icons, if discovered(id, variant) then VARIANT_ICONS[variant] else "▫️")
			end
			card.Variants.Text = table.concat(icons, " ")
		end
		refreshDetail()
	end)

	-- Slow turntable for every visible viewport.
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not Panels.IsOpen("Index") then
			return
		end
		for _, viewport in turntables do
			if viewport:GetAttribute("Spin") and viewport.Visible then
				local world = viewport:FindFirstChildOfClass("WorldModel")
				local model = world and world:FindFirstChildOfClass("Model")
				if model then
					model:PivotTo(model:GetPivot() * CFrame.Angles(0, dt * 0.6, 0))
				end
			end
		end
	end)
end

----------------------------------------------------------------------------------------

function Panels.Init(screen: ScreenGui, requestFn: Request)
	request = requestFn
	buildShop(screen)
	buildRebirth(screen)
	buildDaily(screen)
	buildCodes(screen)
	buildIndex(screen)
end

function Panels.IsOpen(name: string): boolean
	return openName == name
end

return Panels
