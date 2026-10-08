--[[
	Loads every character definition in Shared/Characters and hands them out by Id.
	A missing or broken file falls back to a placeholder so the game keeps running.
]]

local Items = require(script.Parent.Items)

local CharacterRegistry = {}

local byId: { [string]: any } = {}

local function placeholder(id: string): any
	return {
		Id = id,
		Name = id,
		Rarity = "Common",
		Emoji = "❓",
		Color = "#b4b4c8",
		Tagline = "Coming soon...",
		Lore = "This brainrot is still being sculpted.",
		Build = function(k)
			k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 3, 4, 3 }, Pos = { 0, 2, 0 }, Color = "#b4b4c8" })
			k:Part({ Name = "Mark", Size = { 1, 1.4, 0.2 }, Pos = { 0, 2.4, -1.5 }, Color = "#1b1b24", Text = { Text = "?", Color = "#ffffff" } })
		end,
		BuildMini = function(k)
			k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.6, 1.8, 1.6 }, Color = "#b4b4c8" })
		end,
	}
end

for _, module in script.Parent:WaitForChild("Characters"):GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, def = pcall(require, module)
		if ok and type(def) == "table" and type(def.Id) == "string" then
			byId[def.Id] = def
		else
			warn(`[CharacterRegistry] Could not load {module.Name}: {if ok then "bad definition" else def}`)
		end
	end
end

function CharacterRegistry.Get(id: string): any
	local def = byId[id]
	if not def then
		def = placeholder(id)
		byId[id] = def
	end
	return def
end

-- Characters in progression order (the order their droppers unlock).
CharacterRegistry.Ordered = {} :: { any }
for _, item in Items.List do
	if item.Type == "Dropper" and item.Character then
		table.insert(CharacterRegistry.Ordered, CharacterRegistry.Get(item.Character))
	end
end

return CharacterRegistry
