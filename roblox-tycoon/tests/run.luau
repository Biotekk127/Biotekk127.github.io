--[[
	Offline unit tests for the shared (engine-independent) modules.
	Run from roblox-tycoon/:   python3 tests/run_tests.py
	(Uses tiny stand-ins for the Roblox globals the shared modules touch.)
]]

-- `load` is provided by tests/run_tests.py, which bundles src/shared into this file.
local load = ...

local passed, failed = 0, 0
local function check(name: string, actual: any, expected: any)
	if actual == expected then
		passed += 1
	else
		failed += 1
		print(`FAIL {name}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

local Format = load("Format")
check("short 0", Format.Short(0), "0")
check("short 999", Format.Short(999), "999")
check("short 13.5", Format.Short(13.5), "13.5")
check("short 1000", Format.Short(1000), "1K")
check("short 1234", Format.Short(1234), "1.23K")
check("short 15300", Format.Short(15300), "15.3K")
check("short 150000", Format.Short(150000), "150K")
check("short 100000", Format.Short(100000), "100K")
check("short 1e6", Format.Short(1e6), "1M")
check("short 2.5e9", Format.Short(2.5e9), "2.5B")
check("short 1.999e6", Format.Short(1.999e6), "1.99M")
check("short neg", Format.Short(-2500), "-2.5K")
check("short nan", Format.Short(0 / 0), "0")
check("cash", Format.Cash(220e6), "$220M")
check("time m", Format.Time(125), "2:05")
check("time h", Format.Time(3725), "1:02:05")
check("time neg", Format.Time(-5), "0:00")

local Items = load("Items")
check("items count", #Items.List, 24)
check("first free", Items.List[1].Price, 0)
local droppers, upgraders = 0, 0
local lastPrice = -1
for _, item in Items.List do
	if item.Type == "Dropper" then
		droppers += 1
		check("dropper slot " .. item.Id, item.Slot, droppers)
	elseif item.Type == "Upgrader" then
		upgraders += 1
	end
	-- Buy buttons are laid out on an 11 x 4 grid.
	check("fits grid " .. item.Id, item.Index <= 44, true)
	lastPrice = item.Price
end
check("12 droppers (6 per side)", droppers, 12)
check("3 upgraders", upgraders, 3)
check("last item price", lastPrice, 220_000_000)

local Config = load("Config")
local Economy = load("Economy")
check("rebirth cost 0", Economy.RebirthCost(0), 300_000_000)
check("rebirth cost 1", Economy.RebirthCost(1), 660_000_000)
check("rebirth mult 0", Economy.RebirthMultiplier(0), 1)
check("rebirth mult 3", Economy.RebirthMultiplier(3), 4)
check("income D1", Economy.PlotIncome({ D1 = true }, false), 1)
check("income D1 fast", math.floor(Economy.PlotIncome({ D1 = true }, true) * 100), 149)
check("income D1+Up1", Economy.PlotIncome({ D1 = true, Up1 = true }, false), 1.5)
check("income unknown id ignored", Economy.PlotIncome({ D1 = true, Removed = true }, false), 1)
check("scaled reward floor", Economy.ScaledReward(0, 60, 500), 500)
check("scaled reward income", Economy.ScaledReward(100, 60, 500), 6000)

local total = 0
for _, mutation in Config.Mutations do
	total += mutation.Chance
end
check("mutation chance sane", total < 0.1, true)
for key, product in Config.Products do
	if product.Kind == "Event" then
		check("product event exists " .. key, Config.Events[product.Event] ~= nil, true)
	end
end
for code in Config.Codes do
	check("code uppercase " .. code, code, string.upper(code))
end

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	error("tests failed")
end
