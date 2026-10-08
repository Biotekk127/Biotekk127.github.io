--[[
	Rarity tiers for brainrot characters. Higher tiers get flashier pedestals,
	auras and nameplates (see server/RarityFX.luau) and more detailed models.
]]

local Rarity = {}

export type Tier = {
	Key: string,
	Name: string,
	Order: number,
	Color: Color3,
	Color2: Color3, -- gradient partner for nameplates
	Rainbow: boolean,
}

Rarity.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

Rarity.Tiers = {
	Common = { Name = "Common", Color = Color3.fromRGB(190, 190, 205), Color2 = Color3.fromRGB(140, 140, 160) },
	Uncommon = { Name = "Uncommon", Color = Color3.fromRGB(90, 230, 110), Color2 = Color3.fromRGB(40, 170, 80) },
	Rare = { Name = "Rare", Color = Color3.fromRGB(70, 170, 255), Color2 = Color3.fromRGB(40, 100, 230) },
	Epic = { Name = "Epic", Color = Color3.fromRGB(185, 95, 255), Color2 = Color3.fromRGB(120, 50, 220) },
	Legendary = { Name = "Legendary", Color = Color3.fromRGB(255, 205, 60), Color2 = Color3.fromRGB(255, 130, 30) },
	Mythic = { Name = "Mythic", Color = Color3.fromRGB(255, 70, 140), Color2 = Color3.fromRGB(200, 30, 90) },
	Secret = { Name = "SECRET", Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(20, 20, 30), Rainbow = true },
} :: { [string]: any }

for order, key in Rarity.Order do
	local tier = Rarity.Tiers[key]
	tier.Key = key
	tier.Order = order
	tier.Rainbow = tier.Rainbow == true
end

function Rarity.Get(key: string?): Tier
	return Rarity.Tiers[key or "Common"] or Rarity.Tiers.Common
end

return Rarity
