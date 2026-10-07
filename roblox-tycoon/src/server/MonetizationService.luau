--[[
	Game passes and developer products.

	* Pass ownership is mirrored to the player attribute "Pass_<Key>".
	* ProcessReceipt is idempotent: purchase IDs are remembered in saved data so a
	  product is never granted twice, and nothing is granted before data has loaded.
	* In Studio (Config.StudioFreePurchases) the client can request free test grants.
	  These are session-only and never saved, so they can't leak into the live game.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)

local MonetizationService = {}

local MAX_STORED_RECEIPTS = 50

local Services
local passKeyById: { [number]: string } = {}
local productKeyById: { [number]: string } = {}

local function applyPass(player: Player, key: string)
	player:SetAttribute("Pass_" .. key, true)
	if key == "VIP" then
		player:SetAttribute("VIP", true)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and not root:FindFirstChildOfClass("Sparkles") then
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = Color3.fromRGB(255, 200, 40)
			sparkles.Parent = root
		end
	end
	Services.PlayerService.RefreshStats(player)
end

function MonetizationService.LoadPasses(player: Player, _data: any)
	for key, pass in Config.GamePasses do
		if pass.Id > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and owns then
				applyPass(player, key)
			end
		end
	end
end

local function grantPass(player: Player, key: string)
	if player:GetAttribute("Pass_" .. key) then
		return
	end
	applyPass(player, key)
	local pass = Config.GamePasses[key]
	Services.Remotes.Celebrate:FireClient(player, `{pass.Emoji} {pass.Name:upper()} UNLOCKED!`, pass.Description)
	Services.Remotes.NotifyAll(`💎 {player.DisplayName} bought {pass.Name}!`, "event")
end

local function grantProduct(player: Player, key: string)
	local product = Config.Products[key]
	if product.Kind == "Cash" then
		local income = player:GetAttribute("IncomePerSec") or 0
		local amount = Economy.ScaledReward(income, product.IncomeSeconds, product.Minimum)
		Services.PlayerService.AddCash(player, amount)
		Services.Remotes.CashPopup:FireClient(player, amount)
		Services.Remotes.NotifyPlayer(player, `{product.Emoji} +{Format.Cash(amount)}! Thanks for the support!`, "success")
	elseif product.Kind == "Event" then
		Services.EventService.StartEvent(product.Event, player)
	end
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = Services.DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = productKeyById[receipt.ProductId]
	if not key then
		warn("[Monetization] Unknown product id", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(grantProduct, player, key)
	if not ok then
		warn("[Monetization] Failed to grant", key, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.Receipts, receipt.PurchaseId)
	while #data.Receipts > MAX_STORED_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
	Services.DataService.Save(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function testPurchase(player: Player, payload: any): (boolean, string?)
	if not (RunService:IsStudio() and Config.StudioFreePurchases) then
		return false, "Not available"
	end
	if type(payload) ~= "table" or type(payload.Key) ~= "string" then
		return false, "Invalid"
	end
	if payload.Kind == "Pass" and Config.GamePasses[payload.Key] then
		grantPass(player, payload.Key)
		return true, "Studio test: pass granted for this session"
	elseif payload.Kind == "Product" and Config.Products[payload.Key] then
		grantProduct(player, payload.Key)
		return true, "Studio test: product granted"
	end
	return false, "Invalid"
end

function MonetizationService.Init(services)
	Services = services
	for key, pass in Config.GamePasses do
		if pass.Id > 0 then
			passKeyById[pass.Id] = key
		end
	end
	for key, product in Config.Products do
		if product.Id > 0 then
			productKeyById[product.Id] = key
		end
	end
	Services.PlayerService.RegisterRequest("TestPurchase", testPurchase)
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = passKeyById[passId]
		if purchased and key then
			grantPass(player, key)
		end
	end)
end

return MonetizationService
