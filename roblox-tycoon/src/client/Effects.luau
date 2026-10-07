--[[
	Visual feedback: toast notifications, floating cash popups and big celebrations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local Effects = {}

local MAX_TOASTS = 4
local STYLE_COLORS = {
	info = Ui.Theme.Cyan,
	success = Ui.Theme.Green,
	error = Ui.Theme.Red,
	rare = Ui.Theme.Accent,
	event = Ui.Theme.Gold,
}

local toastHolder: Frame
local celebrateHolder: Frame
local screen: ScreenGui

function Effects.Init(gui: ScreenGui)
	screen = gui
	toastHolder = Ui.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.new(0, 520, 0, 230),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Ui.new("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})
	celebrateHolder = Ui.new("Frame", {
		Name = "Celebrate",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})
end

local toastOrder = 0
function Effects.Notify(text: string, style: string?)
	local color = STYLE_COLORS[style or "info"] or Ui.Theme.Cyan
	toastOrder += 1

	local toasts = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #toasts >= MAX_TOASTS do
		local oldest = table.remove(toasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	local toast = Ui.new("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Ui.Theme.Panel,
		BackgroundTransparency = 0.1,
		LayoutOrder = toastOrder,
		Parent = toastHolder,
	}, { Ui.corner(12), Ui.stroke(color, 2.5) })
	local label = Ui.label({
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
		Text = text,
		TextColor3 = color,
		Parent = toast,
	})
	local scale = Ui.new("UIScale", { Scale = 0.6, Parent = toast })
	Ui.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	task.delay(4, function()
		if toast.Parent then
			Ui.tween(toast, 0.4, { BackgroundTransparency = 1 })
			Ui.fadeText(label, 0.4)
			Debris:AddItem(toast, 0.45)
		end
	end)
end

-- Floating "+$123" text. With a world position it floats in 3D, otherwise on screen.
function Effects.CashPopup(amount: number, worldPosition: Vector3?)
	local text = "+" .. Format.Cash(amount)
	if worldPosition then
		local anchor = Ui.new("Part", {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Transparency = 1,
			Size = Vector3.one,
			Position = worldPosition + Vector3.new(math.random(-15, 15) / 10, 3, math.random(-15, 15) / 10),
			Parent = workspace,
		})
		local gui = Ui.new("BillboardGui", {
			Size = UDim2.fromOffset(220, 60),
			AlwaysOnTop = true,
			LightInfluence = 0,
			MaxDistance = 120,
			Parent = anchor,
		})
		local label = Ui.label({ Size = UDim2.fromScale(1, 1), Text = text, TextColor3 = Ui.Theme.Green, Parent = gui })
		Ui.tween(anchor, 1.2, { Position = anchor.Position + Vector3.new(0, 6, 0) })
		Ui.fadeText(label, 1.2)
		Debris:AddItem(anchor, 1.3)
		return
	end

	local label = Ui.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + math.random(-8, 8) / 100, 0.45),
		Size = UDim2.fromOffset(360, 70),
		Text = text,
		TextColor3 = Ui.Theme.Green,
		ZIndex = 40,
		Parent = screen,
	})
	local scale = Ui.new("UIScale", { Scale = 0.3, Parent = label })
	Ui.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	Ui.tween(label, 1.4, { Position = label.Position - UDim2.fromScale(0, 0.12) })
	task.delay(0.9, function()
		Ui.fadeText(label, 0.5)
	end)
	Debris:AddItem(label, 1.5)
end

-- Big centred title for milestones (rebirths, passes, welcome back).
function Effects.Celebrate(title: string, subtitle: string?)
	celebrateHolder:ClearAllChildren()
	local titleLabel = Ui.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromScale(0.8, 0.13),
		Text = title,
		TextColor3 = Ui.Theme.Gold,
		ZIndex = 51,
		Parent = celebrateHolder,
	})
	Ui.gradient(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 40)).Parent = titleLabel
	local subLabel = Ui.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.7, 0.06),
		Text = subtitle or "",
		ZIndex = 51,
		Parent = celebrateHolder,
	})
	local scale = Ui.new("UIScale", { Scale = 0.2, Parent = titleLabel })
	Ui.tween(scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

	-- Confetti
	local colors = { Ui.Theme.Accent, Ui.Theme.Gold, Ui.Theme.Cyan, Ui.Theme.Green }
	for _ = 1, 40 do
		local size = math.random(8, 16)
		local piece = Ui.new("Frame", {
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Size = UDim2.fromOffset(size, size * 1.6),
			Rotation = math.random(0, 360),
			BackgroundColor3 = colors[math.random(1, #colors)],
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = celebrateHolder,
		})
		Ui.tween(piece, math.random(18, 30) / 10, {
			Position = UDim2.new(piece.Position.X.Scale + math.random(-10, 10) / 100, 0, 1.05, 0),
			Rotation = piece.Rotation + math.random(-360, 360),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end

	task.delay(3.2, function()
		if titleLabel.Parent then
			Ui.fadeText(titleLabel, 0.4)
			Ui.fadeText(subLabel, 0.4)
		end
	end)
	task.delay(3.7, function()
		if titleLabel.Parent then
			celebrateHolder:ClearAllChildren()
		end
	end)
end

return Effects
