--[[
	Client side of the mini-game rooms (Phase 2).

	Watches the "Room" player attribute set by server/RoomService and:
	  * plays a short fade transition,
	  * applies the room's Lighting preset (restored when you leave),
	  * gives the room module its own ScreenGui and calls Enter(ctx) / Leave(),
	  * shows a "Back to hub" button,
	  * routes RoomEvent messages to the active room module (OnEvent).
	Room modules live in client/Rooms - see docs/PHASE2_CONTRACTS.md.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(script.Parent.Ui)
local Effects = require(script.Parent.Effects)

local RoomsClient = {}

local player = Players.LocalPlayer
local modules: { [string]: any } = {}
local activeId: string? = nil
local activeGui: ScreenGui? = nil
local savedLighting: { [Instance]: { [string]: any } } = {}
local request: (string, any?) -> boolean
local fader: Frame
local leaveButton: TextButton

export type Context = {
	Player: Player,
	Screen: ScreenGui, -- this room's own ScreenGui (destroyed on leave)
	Model: Model?, -- the room's scene model in workspace.Rooms
	Request: (action: string, payload: any?) -> boolean, -- PlayerService request
	Notify: (text: string, style: string?) -> (),
	CashPopup: (amount: number, worldPosition: Vector3?) -> (),
	Celebrate: (title: string, subtitle: string?) -> (),
}

local function applyProps(instance: Instance, props: { [string]: any })
	savedLighting[instance] = savedLighting[instance] or {}
	for key, value in props do
		if savedLighting[instance][key] == nil then
			savedLighting[instance][key] = (instance :: any)[key]
		end
		(instance :: any)[key] = value
	end
end

-- preset = { ClockTime = 0, Ambient = Color3..., Atmosphere = { Density = 0.4, ... }, ... }
local function applyLighting(preset: { [string]: any }?)
	if not preset then
		return
	end
	local lightingProps = {}
	for key, value in preset do
		if type(value) == "table" then
			local child = Lighting:FindFirstChild(key)
			if child then
				applyProps(child, value)
			end
		else
			lightingProps[key] = value
		end
	end
	applyProps(Lighting, lightingProps)
end

local function restoreLighting()
	for instance, props in savedLighting do
		for key, value in props do
			pcall(function()
				(instance :: any)[key] = value
			end)
		end
	end
	table.clear(savedLighting)
end

local function fade()
	fader.Visible = true
	fader.BackgroundTransparency = 0
	task.delay(0.15, function()
		Ui.tween(fader, 0.45, { BackgroundTransparency = 1 }).Completed:Once(function()
			fader.Visible = false
		end)
	end)
end

local function leaveActive()
	if activeId and modules[activeId] then
		local ok, err = pcall(modules[activeId].Leave)
		if not ok then
			warn(`[RoomsClient] {activeId}.Leave failed: {err}`)
		end
	end
	if activeGui then
		activeGui:Destroy()
		activeGui = nil
	end
	restoreLighting()
	activeId = nil
	leaveButton.Visible = false
end

local function onRoomChanged()
	local roomId = player:GetAttribute("Room") :: string?
	if roomId == activeId then
		return
	end
	fade()
	leaveActive()
	local module = roomId and modules[roomId]
	if not roomId or not module then
		return
	end
	activeId = roomId
	local gui = Ui.new("ScreenGui", {
		Name = "Room_" .. roomId,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	activeGui = gui
	applyLighting(module.Lighting)
	leaveButton.Visible = true
	local rooms = workspace:FindFirstChild("Rooms")
	local ctx: Context = {
		Player = player,
		Screen = gui,
		Model = if rooms then rooms:FindFirstChild(roomId .. "Scene") :: Model? else nil,
		Request = request,
		Notify = Effects.Notify,
		CashPopup = Effects.CashPopup,
		Celebrate = Effects.Celebrate,
	}
	local ok, err = pcall(module.Enter, ctx)
	if not ok then
		warn(`[RoomsClient] {roomId}.Enter failed: {err}`)
	end
end

function RoomsClient.Start(screen: ScreenGui, requestFn: (string, any?) -> boolean)
	request = requestFn
	for _, moduleScript in script.Parent:WaitForChild("Rooms"):GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			local ok, module = pcall(require, moduleScript)
			if ok and type(module) == "table" and module.Id then
				modules[module.Id] = module
			else
				warn(`[RoomsClient] Could not load room {moduleScript.Name}: {module}`)
			end
		end
	end

	fader = Ui.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 100,
		Parent = screen,
	})
	leaveButton = Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(170, 52),
		Text = "⬅ Back to hub",
		BackgroundColor3 = Ui.Theme.Accent,
		Visible = false,
		ZIndex = 60,
		Parent = screen,
	}, function()
		request("LeaveRoom")
	end)

	player:GetAttributeChangedSignal("Room"):Connect(onRoomChanged)
	onRoomChanged()

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoomEvent") :: RemoteEvent
	remote.OnClientEvent:Connect(function(roomId: string, eventName: string, payload: any)
		local module = modules[roomId]
		if module and module.OnEvent and roomId == activeId then
			local ok, err = pcall(module.OnEvent, eventName, payload)
			if not ok then
				warn(`[RoomsClient] {roomId}.OnEvent({eventName}) failed: {err}`)
			end
		elseif module and module.OnEventAnywhere then
			-- Rooms may opt in to events while the player is elsewhere (e.g. daily spin ready).
			pcall(module.OnEventAnywhere, eventName, payload)
		end
	end)
end

return RoomsClient
