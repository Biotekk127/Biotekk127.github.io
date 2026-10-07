--[[
	Pop-up panels: Shop, Rebirth, Daily rewards, Codes.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Effects = require(script.Parent.Effects)

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

function Panels.Init(screen: ScreenGui, requestFn: Request)
	request = requestFn
	buildShop(screen)
	buildRebirth(screen)
	buildDaily(screen)
	buildCodes(screen)
end

function Panels.IsOpen(name: string): boolean
	return openName == name
end

return Panels
