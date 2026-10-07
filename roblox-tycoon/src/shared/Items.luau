--[[
	Everything a player can buy on their plot, in progression order.

	Fields
	  Id        unique key (saved in player data - don't rename once the game is live)
	  Name      shown on the buy button
	  Price     cost in cash
	  Requires  Id that must be owned before this button appears (nil = always visible)
	  Type      "Dropper" | "Upgrader" | "Collector" | "Decor"

	  Dropper:   Value (cash per drop) and Creature (what falls out)
	  Upgrader:  Multiplier applied to every drop that passes through it, Color
	  Collector: Multiplier applied when drops are collected
	  Decor:     Build = name of a builder in server/Builders.luau

	Pacing was tuned with tools/economy_sim.py - keep the two in sync.
]]

local Items = {}

Items.List = {
	{
		Id = "D1",
		Name = "Noodle Goblin Dropper",
		Price = 0,
		Type = "Dropper",
		Value = 2,
		Creature = { Name = "Noodle Goblin", Emoji = "🍜", Color = Color3.fromRGB(255, 214, 110), Shape = "Ball" },
	},
	{
		Id = "D2",
		Name = "Chonky Croissant Dropper",
		Price = 60,
		Requires = "D1",
		Type = "Dropper",
		Value = 6,
		Creature = { Name = "Chonky Croissant", Emoji = "🥐", Color = Color3.fromRGB(230, 160, 70), Shape = "Block" },
	},
	{ Id = "Walls", Name = "Factory Walls", Price = 200, Requires = "D2", Type = "Decor", Build = "Walls" },
	{
		Id = "D3",
		Name = "Sir Wobbleton Dropper",
		Price = 350,
		Requires = "D2",
		Type = "Dropper",
		Value = 15,
		Creature = { Name = "Sir Wobbleton", Emoji = "🍮", Color = Color3.fromRGB(255, 180, 120), Shape = "Ball" },
	},
	{
		Id = "Up1",
		Name = "Bubble Wash (x1.5)",
		Price = 1_000,
		Requires = "D3",
		Type = "Upgrader",
		Multiplier = 1.5,
		Color = Color3.fromRGB(90, 200, 255),
	},
	{
		Id = "D4",
		Name = "Banana Bandit Dropper",
		Price = 2_000,
		Requires = "D3",
		Type = "Dropper",
		Value = 40,
		Creature = { Name = "Banana Bandit", Emoji = "🍌", Color = Color3.fromRGB(255, 235, 60), Shape = "Block" },
	},
	{ Id = "Lights", Name = "Disco Lamps", Price = 4_000, Requires = "D4", Type = "Decor", Build = "Lights" },
	{
		Id = "D5",
		Name = "Toastie McBlast Dropper",
		Price = 9_000,
		Requires = "D4",
		Type = "Dropper",
		Value = 100,
		Creature = { Name = "Toastie McBlast", Emoji = "🍞", Color = Color3.fromRGB(200, 130, 60), Shape = "Block" },
	},
	{ Id = "Sign", Name = "Giant Neon Sign", Price = 18_000, Requires = "D5", Type = "Decor", Build = "Sign" },
	{
		Id = "D6",
		Name = "Espresso Ninja Dropper",
		Price = 35_000,
		Requires = "D5",
		Type = "Dropper",
		Value = 250,
		Creature = { Name = "Espresso Ninja", Emoji = "☕", Color = Color3.fromRGB(110, 70, 45), Shape = "Ball" },
	},
	{
		Id = "Up2",
		Name = "Rizz Laser (x2)",
		Price = 60_000,
		Requires = "D6",
		Type = "Upgrader",
		Multiplier = 2,
		Color = Color3.fromRGB(255, 60, 160),
	},
	{
		Id = "D7",
		Name = "Sharky Sneakerz Dropper",
		Price = 100_000,
		Requires = "D6",
		Type = "Dropper",
		Value = 650,
		Creature = { Name = "Sharky Sneakerz", Emoji = "🦈", Color = Color3.fromRGB(90, 140, 220), Shape = "Ball" },
	},
	{ Id = "Garden", Name = "Meme Garden", Price = 180_000, Requires = "D7", Type = "Decor", Build = "Garden" },
	{
		Id = "D8",
		Name = "Cactus Cowboy Dropper",
		Price = 350_000,
		Requires = "D7",
		Type = "Dropper",
		Value = 1_600,
		Creature = { Name = "Cactus Cowboy", Emoji = "🌵", Color = Color3.fromRGB(80, 190, 90), Shape = "Block" },
	},
	{
		Id = "Collector",
		Name = "Golden Collector (x1.5)",
		Price = 700_000,
		Requires = "D8",
		Type = "Collector",
		Multiplier = 1.5,
	},
	{
		Id = "D9",
		Name = "Disco Llama Dropper",
		Price = 1_400_000,
		Requires = "D8",
		Type = "Dropper",
		Value = 4_000,
		Creature = { Name = "Disco Llama", Emoji = "🦙", Color = Color3.fromRGB(240, 240, 255), Shape = "Ball" },
	},
	{ Id = "Fountain", Name = "Cash Fountain", Price = 2_800_000, Requires = "D9", Type = "Decor", Build = "Fountain" },
	{
		Id = "D10",
		Name = "Pickle Wizard Dropper",
		Price = 5_500_000,
		Requires = "D9",
		Type = "Dropper",
		Value = 10_000,
		Creature = { Name = "Pickle Wizard", Emoji = "🥒", Color = Color3.fromRGB(120, 200, 60), Shape = "Block" },
	},
	{
		Id = "Up3",
		Name = "Galaxy Portal (x3)",
		Price = 12_000_000,
		Requires = "D10",
		Type = "Upgrader",
		Multiplier = 3,
		Color = Color3.fromRGB(150, 90, 255),
	},
	{
		Id = "D11",
		Name = "Moon Moai Dropper",
		Price = 25_000_000,
		Requires = "D10",
		Type = "Dropper",
		Value = 25_000,
		Creature = { Name = "Moon Moai", Emoji = "🗿", Color = Color3.fromRGB(170, 170, 185), Shape = "Block" },
	},
	{ Id = "Statue", Name = "Golden Goblin Statue", Price = 40_000_000, Requires = "D11", Type = "Decor", Build = "Statue" },
	{
		Id = "D12",
		Name = "Cosmic Brainrot King Dropper",
		Price = 70_000_000,
		Requires = "D11",
		Type = "Dropper",
		Value = 70_000,
		Creature = { Name = "Cosmic Brainrot King", Emoji = "👑", Color = Color3.fromRGB(255, 120, 255), Shape = "Ball" },
	},
	{ Id = "Throne", Name = "Brainrot Throne", Price = 120_000_000, Requires = "D12", Type = "Decor", Build = "Throne" },
	{ Id = "Rocket", Name = "Brainrot Rocket", Price = 220_000_000, Requires = "Throne", Type = "Decor", Build = "Rocket" },
}

Items.ById = {}
local dropperSlot, upgraderSlot = 0, 0
for index, item in Items.List do
	item.Index = index
	if item.Type == "Dropper" then
		dropperSlot += 1
		item.Slot = dropperSlot
	elseif item.Type == "Upgrader" then
		upgraderSlot += 1
		item.Slot = upgraderSlot
	end
	assert(Items.ById[item.Id] == nil, "Duplicate item id " .. item.Id)
	Items.ById[item.Id] = item
end

for _, item in Items.List do
	assert(item.Requires == nil or Items.ById[item.Requires], `Item {item.Id} requires unknown item {item.Requires}`)
end

return Items
