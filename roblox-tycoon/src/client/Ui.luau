--[[
	Tiny UI toolkit: instance creation, theme, and bouncy buttons.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Ui = {}

Ui.Theme = {
	Font = Enum.Font.FredokaOne,
	Panel = Color3.fromRGB(34, 24, 58),
	PanelLight = Color3.fromRGB(56, 42, 92),
	Accent = Color3.fromRGB(255, 80, 200),
	Cyan = Color3.fromRGB(80, 220, 255),
	Green = Color3.fromRGB(70, 220, 110),
	Red = Color3.fromRGB(240, 70, 90),
	Gold = Color3.fromRGB(255, 205, 50),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(200, 190, 230),
	Outline = Color3.fromRGB(15, 10, 25),
}

-- Ui.new("Frame", { Size = ..., Parent = ... }, { children })
function Ui.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Ui.corner(radius: number?): UICorner
	return Ui.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Ui.stroke(color: Color3?, thickness: number?): UIStroke
	return Ui.new("UIStroke", {
		Color = color or Ui.Theme.Outline,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Ui.textStroke(thickness: number?): UIStroke
	return Ui.new("UIStroke", { Color = Ui.Theme.Outline, Thickness = thickness or 2 })
end

function Ui.gradient(top: Color3, bottom: Color3): UIGradient
	return Ui.new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = 90 })
end

function Ui.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Ui.Theme.Font,
		TextColor3 = Ui.Theme.Text,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	local label = Ui.new("TextLabel", defaults)
	Ui.textStroke(1.5).Parent = label
	return label
end

function Ui.tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

-- Fades a label's text and its outline together.
function Ui.fadeText(label: TextLabel, seconds: number)
	Ui.tween(label, seconds, { TextTransparency = 1 })
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		Ui.tween(stroke, seconds, { Transparency = 1 })
	end
end

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
clickSound.Volume = 0.4
clickSound.Parent = SoundService

function Ui.playClick()
	pcall(function()
		SoundService:PlayLocalSound(clickSound)
	end)
end

-- A chunky button that squishes when pressed.
function Ui.button(props: { [string]: any }, onClick: () -> ()): TextButton
	local defaults = {
		AutoButtonColor = false,
		Font = Ui.Theme.Font,
		TextColor3 = Ui.Theme.Text,
		TextScaled = true,
		BackgroundColor3 = Ui.Theme.Green,
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = Ui.new("TextButton", defaults)
	Ui.corner(10).Parent = button
	Ui.stroke(Ui.Theme.Outline, 2.5).Parent = button
	Ui.textStroke(1.5).Parent = button
	local scale = Ui.new("UIScale", { Parent = button })

	button.MouseEnter:Connect(function()
		Ui.tween(scale, 0.12, { Scale = 1.06 })
	end)
	button.MouseLeave:Connect(function()
		Ui.tween(scale, 0.12, { Scale = 1 })
	end)
	button.Activated:Connect(function()
		scale.Scale = 0.9
		Ui.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		Ui.playClick()
		onClick()
	end)
	return button
end

return Ui
