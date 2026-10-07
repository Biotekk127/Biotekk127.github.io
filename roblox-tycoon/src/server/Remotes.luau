--[[
	Creates the RemoteEvents/RemoteFunctions the client talks to.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local function make(className: string, name: string): any
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

Remotes.Notify = make("RemoteEvent", "Notify") :: RemoteEvent -- (text, style)
Remotes.CashPopup = make("RemoteEvent", "CashPopup") :: RemoteEvent -- (amount, worldPosition?)
Remotes.Celebrate = make("RemoteEvent", "Celebrate") :: RemoteEvent -- (title, subtitle)
Remotes.Request = make("RemoteFunction", "Request") :: RemoteFunction -- (action, payload) -> result

folder.Parent = ReplicatedStorage

function Remotes.NotifyPlayer(player: Player, text: string, style: string?)
	Remotes.Notify:FireClient(player, text, style or "info")
end

function Remotes.NotifyAll(text: string, style: string?)
	Remotes.Notify:FireAllClients(text, style or "info")
end

return Remotes
