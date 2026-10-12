--[[
	Mini-game rooms (Phase 2): three themed rooms reached through doors on the hub.

	Each room is a ModuleScript in server/Rooms (see docs/PHASE2_CONTRACTS.md):
	  Room.Id, Room.Name, Room.Emoji, Room.DoorColor, Room.Scene (optional scene definition)
	  Room.Build(origin, sceneModel) -> { Spawn = CFrame }   build gameplay, return the spawn
	  Room.Init(services)      register requests etc.
	  Room.OnEnter(player) / Room.OnLeave(player)
	  Room.GrantProduct(player, productKey)   optional, for Kind = "Room" developer products

	Rooms are built far away from the main map in the same server. The player's current
	room is mirrored on the "Room" player attribute; the client (RoomsClient) plays the
	transition and room-specific UI/lighting from that.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterKit = require(ReplicatedStorage.Shared.CharacterKit)
local Builders = require(script.Parent.Builders)

local RoomService = {}

-- Room order matches WorldBuilder.HubDoorSlots. Origins are far from the main map
-- (the baseplate spans +-1024) so the themed rooms never overlap it or each other.
local ROOM_ORDER = { "Obby", "Fishing", "Wheel" }
local ROOM_ORIGINS = {
	Obby = CFrame.new(2600, 300, 0),
	Fishing = CFrame.new(0, 20, 2600),
	Wheel = CFrame.new(-2600, 20, 0),
}
local TRAVEL_COOLDOWN = 1.5

type RoomInfo = { Module: any, Spawn: CFrame, Door: CFrame, Model: Model? }

local Services
local rooms: { [string]: RoomInfo } = {}
local lastTravel: { [Player]: number } = {}

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if character and character:FindFirstChildOfClass("Humanoid") then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local function canTravel(player: Player): boolean
	local now = os.clock()
	if (lastTravel[player] or 0) + TRAVEL_COOLDOWN > now then
		return false
	end
	lastTravel[player] = now
	return true
end

function RoomService.GetRoom(player: Player): string?
	return player:GetAttribute("Room") :: string?
end

function RoomService.Enter(player: Player, roomId: string)
	local info = rooms[roomId]
	local character = player.Character
	if not info or not character or not Services.DataService.Get(player) then
		return
	end
	local current = RoomService.GetRoom(player)
	if current == roomId then
		return
	end
	if current and rooms[current] then
		pcall(rooms[current].Module.OnLeave, player)
	end
	player:SetAttribute("Room", roomId)
	character:PivotTo(info.Spawn)
	local ok, err = pcall(info.Module.OnEnter, player)
	if not ok then
		warn(`[RoomService] {roomId}.OnEnter failed: {err}`)
	end
end

-- Back to the hub, in front of the room's door.
function RoomService.Leave(player: Player)
	local current = RoomService.GetRoom(player)
	if not current then
		return
	end
	local info = rooms[current]
	player:SetAttribute("Room", nil)
	if info then
		pcall(info.Module.OnLeave, player)
		local character = player.Character
		if character then
			character:PivotTo(info.Door * CFrame.new(0, 3, -6)) -- 6 studs in front, facing the hub
		end
	end
end

function RoomService.GrantProduct(roomId: string, player: Player, productKey: string)
	local info = rooms[roomId]
	assert(info and info.Module.GrantProduct, `Room {roomId} cannot grant products`)
	info.Module.GrantProduct(player, productKey)
end

-- Per-room save data (created on first use). Rooms own the shape of their table.
function RoomService.Data(player: Player, roomId: string): any?
	local data = Services.DataService.Get(player)
	if not data then
		return nil
	end
	data.Rooms[roomId] = data.Rooms[roomId] or {}
	return data.Rooms[roomId]
end

-- Sends a room-specific event to one player's client room module.
function RoomService.Fire(player: Player, roomId: string, eventName: string, payload: any?)
	Services.Remotes.RoomEvent:FireClient(player, roomId, eventName, payload)
end

local function buildDoor(module: any, slot: CFrame, parent: Instance): BasePart
	local m = Instance.new("Model")
	m.Name = "Door_" .. module.Id
	m.Parent = parent
	local color = module.DoorColor or Color3.fromRGB(80, 220, 255)
	local frameColor = Color3.fromRGB(40, 32, 64)
	for _, x in { -3.5, 3.5 } do
		Builders.Part(m, slot, Vector3.new(1.2, 10, 1.2), Vector3.new(x, 5, 0), {
			Name = "Post",
			Color = frameColor,
			Material = Enum.Material.Metal,
		})
	end
	Builders.Part(m, slot, Vector3.new(8.2, 1.2, 1.2), Vector3.new(0, 10.4, 0), {
		Name = "Lintel",
		Color = frameColor,
		Material = Enum.Material.Metal,
	})
	local portal = Builders.Part(m, slot, Vector3.new(5.8, 9.4, 0.4), Vector3.new(0, 4.7, 0), {
		Name = "Portal",
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	Builders.Billboard(portal, `{module.Emoji or "🚪"} {module.Name}`, Vector2.new(12, 2.4), 7.2, 120)
	return portal
end

function RoomService.Init(services)
	Services = services
	local folder = Instance.new("Folder")
	folder.Name = "Rooms"
	folder.Parent = workspace
	local doors = Instance.new("Folder")
	doors.Name = "RoomDoors"
	doors.Parent = workspace

	local moduleFolder = script.Parent:WaitForChild("Rooms")
	for index, roomId in ROOM_ORDER do
		local moduleScript = moduleFolder:FindFirstChild(roomId)
		if not moduleScript then
			warn(`[RoomService] Missing room module {roomId}`)
			continue
		end
		local module = require(moduleScript) :: any
		local origin = ROOM_ORIGINS[roomId]
		local doorSlot = services.WorldBuilder.HubDoorSlots[index]

		local sceneModel: Model? = nil
		if module.Scene then
			sceneModel = CharacterKit.Build(module.Scene, "Full")
			local scene = sceneModel :: Model
			scene.Name = roomId .. "Scene"
			scene:PivotTo(origin)
			scene.Parent = folder
		end
		local ok, result = pcall(module.Build, origin, sceneModel)
		if not ok or type(result) ~= "table" or typeof(result.Spawn) ~= "CFrame" then
			warn(`[RoomService] {roomId}.Build failed: {result}`)
			continue
		end
		rooms[roomId] = { Module = module, Spawn = result.Spawn, Door = doorSlot, Model = sceneModel }
		if module.Init then
			module.Init(services, RoomService)
		end

		local portal = buildDoor(module, doorSlot, doors)
		portal.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and not RoomService.GetRoom(player) and canTravel(player) then
				RoomService.Enter(player, roomId)
			end
		end)

		-- Any scene part with Role = "Exit" sends the player back to the hub.
		if sceneModel then
			for _, part in sceneModel:GetDescendants() do
				if part:IsA("BasePart") and part:GetAttribute("Role") == "Exit" then
					part.CanTouch = true
					part.Touched:Connect(function(hit)
						local player = playerFromHit(hit)
						if player and RoomService.GetRoom(player) == roomId and canTravel(player) then
							RoomService.Leave(player)
						end
					end)
				end
			end
		end
	end

	services.PlayerService.RegisterRequest("LeaveRoom", function(player)
		RoomService.Leave(player)
		return true
	end)
end

function RoomService.Start()
	local function watch(player: Player)
		-- Respawning (e.g. falling out of a room) always puts you back at your plot.
		player.CharacterAdded:Connect(function()
			local current = RoomService.GetRoom(player)
			if current and rooms[current] then
				pcall(rooms[current].Module.OnLeave, player)
			end
			player:SetAttribute("Room", nil)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local current = RoomService.GetRoom(player)
		if current and rooms[current] then
			pcall(rooms[current].Module.OnLeave, player)
		end
		lastTravel[player] = nil
	end)
end

return RoomService
