--[[
	Economy formulas shared by server and client so both always agree.
]]

local Config = require(script.Parent.Config)
local Items = require(script.Parent.Items)

local Economy = {}

function Economy.RebirthCost(rebirths: number): number
	return math.floor(Config.Rebirth.BaseCost * Config.Rebirth.CostGrowth ^ rebirths)
end

function Economy.RebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.Rebirth.MultiplierPerRebirth
end

-- Cash per second a plot produces before player multipliers (ignores mutations).
function Economy.PlotIncome(owned: { [string]: boolean }, fastDroppers: boolean): number
	local perDrop = 0
	local multiplier = 1
	for id in owned do
		local item = Items.ById[id]
		if item then
			if item.Type == "Dropper" then
				perDrop += item.Value
			elseif item.Type == "Upgrader" or item.Type == "Collector" then
				multiplier *= item.Multiplier
			end
		end
	end
	local interval = Config.DropInterval * (if fastDroppers then Config.FastDropperMultiplier else 1)
	return perDrop / interval * multiplier
end

-- Reward that scales with how far along the player is, with a floor for new players.
function Economy.ScaledReward(incomePerSecond: number, seconds: number, minimum: number): number
	return math.floor(math.max(minimum, incomePerSecond * seconds))
end

return Economy
