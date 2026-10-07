--[[
	Plots: creation, claiming, buy buttons, purchases, the cash bank and collecting.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Builders = require(script.Parent.Builders)

local PlotService = {}

export type Dropper = { Item: any, SpawnCF: CFrame, Next: number }

export type Plot = {
	Id: number,
	CFrame: CFrame,
	Parts: Builders.PlotParts,
	Owner: Player?,
	Owned: { [string]: boolean },
	Bank: number,
	Droppers: { Dropper },
	CollectorMultiplier: number,
	DropCount: number,
	ButtonCooldown: { [string]: number },
}

PlotService.Plots = {} :: { Plot }

local plotByPlayer: { [Player]: Plot } = {}
local Services

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if character and character:FindFirstChildOfClass("Humanoid") then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

function PlotService.GetPlot(player: Player): Plot?
	return plotByPlayer[player]
end

function PlotService.SpawnCFrame(plot: Plot): CFrame
	-- Stand at the front of the plot looking toward the conveyor.
	local position = plot.CFrame * Builders.SPAWN_POS
	local lookAt = plot.CFrame * Vector3.new(0, Builders.SPAWN_POS.Y, 0)
	return CFrame.lookAt(position, lookAt)
end

----------------------------------------------------------------------------------------
-- Bank
----------------------------------------------------------------------------------------

local function updateBankLabel(plot: Plot)
	plot.Parts.BankLabel.Text = Format.Cash(plot.Bank)
	plot.Parts.Model:SetAttribute("Bank", plot.Bank)
end

function PlotService.AddToBank(plot: Plot, amount: number)
	plot.Bank += amount
	updateBankLabel(plot)
end

-- Moves banked cash into the owner's wallet. Returns the amount collected.
function PlotService.Collect(player: Player, silent: boolean?): number
	local plot = plotByPlayer[player]
	if not plot or plot.Bank <= 0 then
		return 0
	end
	local amount = plot.Bank
	plot.Bank = 0
	updateBankLabel(plot)
	Services.PlayerService.AddCash(player, amount)
	if not silent then
		Services.Remotes.CashPopup:FireClient(player, amount, plot.Parts.CollectPad.Position)
	end
	return amount
end

-- True while the player's character is standing on their own collect pad.
function PlotService.IsOnCollectPad(player: Player): boolean
	local plot = plotByPlayer[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not plot or not root then
		return false
	end
	local offset = plot.Parts.CollectPad.CFrame:PointToObjectSpace(root.Position)
	return math.abs(offset.X) < 3.5 and math.abs(offset.Z) < 3.5 and offset.Y > 0 and offset.Y < 6
end

----------------------------------------------------------------------------------------
-- Building items
----------------------------------------------------------------------------------------

local function buildItem(plot: Plot, item: any, animate: boolean)
	local folder = plot.Parts.ItemsFolder
	local m: Model
	if item.Type == "Dropper" then
		local spawnCF
		m, spawnCF = Builders.Dropper(item, plot.CFrame, folder)
		table.insert(plot.Droppers, { Item = item, SpawnCF = spawnCF, Next = os.clock() + 0.5 })
	elseif item.Type == "Upgrader" then
		local laser
		m, laser = Builders.Upgrader(item, plot.CFrame, folder)
		Services.DropService.HookUpgrader(plot, item, laser)
	elseif item.Type == "Collector" then
		m = Builders.CollectorUpgrade(item, plot.CFrame, folder)
		plot.CollectorMultiplier *= item.Multiplier
		plot.Parts.Collector.Color = Color3.fromRGB(255, 200, 40)
	else
		m = Builders.Decor(item, plot.CFrame, folder)
	end
	if animate then
		Builders.PlayBuildAnimation(m)
		Builders.Confetti(plot.Parts.Model, m:GetPivot().Position + Vector3.new(0, 4, 0))
	end
end

----------------------------------------------------------------------------------------
-- Buttons
----------------------------------------------------------------------------------------

local function isVisible(plot: Plot, item: any): boolean
	if plot.Owned[item.Id] then
		return false
	end
	return item.Requires == nil or plot.Owned[item.Requires] == true
end

local function onButtonTouched(plot: Plot, item: any, hit: BasePart)
	local player = playerFromHit(hit)
	if not player or player ~= plot.Owner then
		return
	end
	local now = os.clock()
	if (plot.ButtonCooldown[item.Id] or 0) > now then
		return
	end
	plot.ButtonCooldown[item.Id] = now + 1
	PlotService.TryBuy(player, item.Id)
end

function PlotService.RefreshButtons(plot: Plot)
	local folder = plot.Parts.ButtonsFolder
	for _, button in folder:GetChildren() do
		local item = Items.ById[button:GetAttribute("ItemId")]
		if not plot.Owner or not item or not isVisible(plot, item) then
			button:Destroy()
		end
	end
	if not plot.Owner then
		return
	end
	for _, item in Items.List do
		if isVisible(plot, item) and not folder:FindFirstChild("Button_" .. item.Id) then
			local priceText = if item.Price == 0 then "FREE" else Format.Cash(item.Price)
			local _, pad = Builders.Button(item, plot.CFrame, folder, priceText)
			pad.Touched:Connect(function(hit)
				onButtonTouched(plot, item, hit)
			end)
		end
	end
end

function PlotService.TryBuy(player: Player, itemId: string): (boolean, string?)
	local plot = plotByPlayer[player]
	local item = Items.ById[itemId]
	if not plot or not item then
		return false, "Invalid item"
	end
	if not isVisible(plot, item) then
		return false, "Not available yet"
	end
	if not Services.PlayerService.SpendCash(player, item.Price) then
		local cash = Services.PlayerService.GetCash(player)
		Services.Remotes.NotifyPlayer(player, `Need {Format.Cash(item.Price - cash)} more for {item.Name}!`, "error")
		return false, "Not enough cash"
	end

	plot.Owned[item.Id] = true
	local data = Services.DataService.Get(player)
	if data then
		data.Items[item.Id] = true
	end
	buildItem(plot, item, true)
	PlotService.RefreshButtons(plot)
	Services.PlayerService.RefreshStats(player)
	Services.Remotes.NotifyPlayer(player, `Built {item.Name}!`, "success")

	if item.Id == Items.List[#Items.List].Id then
		Services.Remotes.Celebrate:FireClient(player, "FACTORY COMPLETE!", "Rebirth for a permanent cash multiplier!")
	end
	return true
end

----------------------------------------------------------------------------------------
-- Ownership
----------------------------------------------------------------------------------------

local function clearPlot(plot: Plot)
	plot.Parts.ItemsFolder:ClearAllChildren()
	plot.Parts.DropsFolder:ClearAllChildren()
	plot.Owned = {}
	plot.Droppers = {}
	plot.CollectorMultiplier = 1
	plot.Bank = 0
	plot.DropCount = 0
	plot.ButtonCooldown = {}
	plot.Parts.Collector.Color = Color3.fromRGB(60, 230, 120)
	Services.DropService.ClearPlot(plot)
	updateBankLabel(plot)
end

function PlotService.Claim(player: Player, ownedItems: { [string]: boolean }): Plot?
	for _, plot in PlotService.Plots do
		if plot.Owner == nil then
			clearPlot(plot)
			plot.Owner = player
			plotByPlayer[player] = plot
			plot.Parts.OwnerLabel.Text = `{player.DisplayName}'s Factory`
			plot.Parts.Model:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("PlotId", plot.Id)

			for _, item in Items.List do
				if ownedItems[item.Id] then
					plot.Owned[item.Id] = true
					buildItem(plot, item, false)
				end
			end
			PlotService.RefreshButtons(plot)
			return plot
		end
	end
	return nil
end

function PlotService.Release(player: Player)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	plotByPlayer[player] = nil
	plot.Owner = nil
	clearPlot(plot)
	PlotService.RefreshButtons(plot)
	plot.Parts.OwnerLabel.Text = "Empty Factory"
	plot.Parts.Model:SetAttribute("OwnerUserId", nil)
end

function PlotService.ResetForRebirth(player: Player)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	clearPlot(plot)
	PlotService.RefreshButtons(plot)
end

----------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------

function PlotService.Init(services)
	Services = services

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace

	for i = 1, Config.MaxPlots do
		local angle = (i - 1) / Config.MaxPlots * math.pi * 2
		local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRingRadius
		-- Rotate so the plot's front (+Z) faces the lobby at the origin.
		local plotCF = CFrame.lookAt(position, Vector3.zero) * CFrame.Angles(0, math.pi, 0)

		local parts = Builders.PlotBase(plotCF, i, plotsFolder)
		local plot: Plot = {
			Id = i,
			CFrame = plotCF,
			Parts = parts,
			Owner = nil,
			Owned = {},
			Bank = 0,
			Droppers = {},
			CollectorMultiplier = 1,
			DropCount = 0,
			ButtonCooldown = {},
		}
		table.insert(PlotService.Plots, plot)

		parts.CollectPad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and player == plot.Owner then
				PlotService.Collect(player)
			end
		end)
		Services.DropService.HookCollector(plot)
	end
end

return PlotService
