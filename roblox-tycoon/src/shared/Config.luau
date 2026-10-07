--[[
	Brainrot Factory Tycoon - global configuration.

	This is the main file you edit to tune the game:
	  * Paste your Game Pass / Developer Product IDs into GamePasses / Products.
	  * Add or remove promo codes in Codes.
	  * Tweak economy numbers (run tools/economy_sim.py after big changes).
]]

local Config = {}

Config.GameName = "Brainrot Factory Tycoon"

-- Bump the version suffix to wipe everyone's progress (e.g. after a big economy change).
Config.DataStoreName = "BrainrotTycoon_v1"
Config.LeaderboardStoreName = "BrainrotTycoon_TotalEarned_v1"

-- When true, buying passes/products inside Roblox Studio grants them for free so you
-- can test everything before you create the real passes. Has no effect in live games.
Config.StudioFreePurchases = true

-- Optional: your Roblox group ID. Members get a cash bonus (great for growing a community).
Config.GroupId = 0
Config.GroupBonus = 0.10

-- Every friend in the same server gives +10% cash (max +40%). Encourages invites.
Config.FriendBonusPer = 0.10
Config.FriendBonusMax = 0.40

-- World layout. IMPORTANT: set your game's Max Players (Places > Settings) to MaxPlots.
Config.MaxPlots = 8
Config.PlotRingRadius = 190
Config.PlotSize = 100

-- Drops
Config.DropInterval = 2 -- seconds between drops for every dropper
Config.FastDropperMultiplier = 0.67 -- interval multiplier with the Fast Droppers pass
Config.DropLifetime = 30
Config.MaxDropsPerPlot = 90
Config.ConveyorSpeed = 11
Config.AutoCollectInterval = 1

Config.Rebirth = {
	BaseCost = 300_000_000,
	CostGrowth = 2.2,
	MultiplierPerRebirth = 1.0, -- each rebirth adds +100% cash permanently
}

-- Rare "mutations" a drop can roll when it spawns. Checked top to bottom.
Config.Mutations = {
	{ Name = "Rainbow", Chance = 0.002, Multiplier = 50, Color = Color3.fromRGB(255, 80, 200), Announce = true },
	{ Name = "Diamond", Chance = 0.01, Multiplier = 10, Color = Color3.fromRGB(120, 230, 255), Announce = true },
	{ Name = "Gold", Chance = 0.05, Multiplier = 3, Color = Color3.fromRGB(255, 205, 50), Announce = false },
}

--[[
	GAME PASSES - create them on create.roblox.com (Your game > Monetization > Passes),
	then paste each ID below. Id = 0 means "not set up yet".
]]
Config.GamePasses = {
	DoubleCash = {
		Id = 0,
		Name = "2x Cash",
		Emoji = "💸",
		Description = "Double ALL cash you earn, forever!",
		SuggestedPrice = 199,
	},
	AutoCollect = {
		Id = 0,
		Name = "Auto Collect",
		Emoji = "🧲",
		Description = "Cash flows straight into your wallet. No more walking to the collector!",
		SuggestedPrice = 149,
	},
	LuckyMutations = {
		Id = 0,
		Name = "Lucky Mutations",
		Emoji = "🍀",
		Description = "3x chance for Gold, Diamond and Rainbow brainrots!",
		SuggestedPrice = 249,
	},
	FastDroppers = {
		Id = 0,
		Name = "Fast Droppers",
		Emoji = "⚡",
		Description = "All your droppers spawn brainrots 50% faster!",
		SuggestedPrice = 299,
	},
	VIP = {
		Id = 0,
		Name = "VIP",
		Emoji = "👑",
		Description = "+50% cash, a golden [VIP] chat tag and VIP sparkles!",
		SuggestedPrice = 399,
	},
}

--[[
	DEVELOPER PRODUCTS - repeatable purchases (Monetization > Developer Products).
	Cash packs scale with the player's income so they stay valuable all game long.
]]
Config.Products = {
	CashSmall = {
		Id = 0,
		Name = "Pile of Cash",
		Emoji = "💵",
		Kind = "Cash",
		IncomeSeconds = 15 * 60,
		Minimum = 2_500,
		SuggestedPrice = 49,
	},
	CashMedium = {
		Id = 0,
		Name = "Bag of Cash",
		Emoji = "💰",
		Kind = "Cash",
		IncomeSeconds = 60 * 60,
		Minimum = 15_000,
		SuggestedPrice = 149,
	},
	CashLarge = {
		Id = 0,
		Name = "Vault of Cash",
		Emoji = "🏦",
		Kind = "Cash",
		IncomeSeconds = 6 * 60 * 60,
		Minimum = 100_000,
		SuggestedPrice = 499,
	},
	RainbowRain = {
		Id = 0,
		Name = "Rainbow Rain (Server Event)",
		Emoji = "🌈",
		Kind = "Event",
		Event = "RainbowRain",
		SuggestedPrice = 99,
	},
	CashFrenzy = {
		Id = 0,
		Name = "Cash Frenzy (Server Event)",
		Emoji = "🤑",
		Kind = "Event",
		Event = "CashFrenzy",
		SuggestedPrice = 79,
	},
}

-- Server-wide events. Random ones fire on their own; paid ones are bought by players
-- and boost EVERYONE in the server (people love being the hero, and it's very shareable).
Config.Events = {
	GoldRush = { Name = "GOLD RUSH", Emoji = "⛏️", Duration = 180, LuckMultiplier = 3, CashMultiplier = 1, Random = true },
	CashFrenzy = { Name = "CASH FRENZY", Emoji = "🤑", Duration = 300, LuckMultiplier = 1, CashMultiplier = 2, Random = true },
	RainbowRain = { Name = "RAINBOW RAIN", Emoji = "🌈", Duration = 300, LuckMultiplier = 10, CashMultiplier = 1, Random = false },
}
Config.RandomEventDelay = { Min = 8 * 60, Max = 14 * 60 }

-- Daily login rewards (streak of 7, then loops). Reward = max(Minimum, income * IncomeSeconds).
Config.DailyRewards = {
	{ IncomeSeconds = 2 * 60, Minimum = 500 },
	{ IncomeSeconds = 4 * 60, Minimum = 1_500 },
	{ IncomeSeconds = 6 * 60, Minimum = 4_000 },
	{ IncomeSeconds = 8 * 60, Minimum = 10_000 },
	{ IncomeSeconds = 10 * 60, Minimum = 25_000 },
	{ IncomeSeconds = 15 * 60, Minimum = 60_000 },
	{ IncomeSeconds = 30 * 60, Minimum = 150_000 },
}
Config.DailyCooldown = 20 * 60 * 60 -- can claim again after 20h
Config.DailyStreakWindow = 48 * 60 * 60 -- streak resets if you miss more than this

-- Free gift every few minutes of playtime (keeps sessions long, which the algorithm loves).
Config.PlaytimeGift = { Interval = 8 * 60, IncomeSeconds = 90, Minimum = 300 }

-- Money earned while offline.
Config.OfflineEarnings = { Rate = 0.25, MaxSeconds = 4 * 60 * 60, MinSeconds = 120 }

--[[
	PROMO CODES - post new ones on your social media / Discord to drive traffic.
	Codes are case-insensitive. Reward is Cash (flat) and/or IncomeSeconds (scales).
]]
Config.Codes = {
	RELEASE = { Cash = 1_000 },
	BRAINROT = { IncomeSeconds = 5 * 60, Minimum = 2_500 },
	THANKS = { IncomeSeconds = 10 * 60, Minimum = 5_000 },
}

return Config
