-- the sim cannot load roblox images: point every id the examples use at a local stand-in drawing.
-- in a real game these ids are your own decals (theme.asset holds the reference ids)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local theme = require(ReplicatedStorage.Packages.bright).theme

local icon = theme.asset.icon

-- made-up ids for the extra example art
local ids = {
	donut = "rbxassetid://9001",
	cup = "rbxassetid://9002",
	shark = "rbxassetid://9003",
	gift = "rbxassetid://9004",
	crown = "rbxassetid://9005",
	bolt = "rbxassetid://9006",
	coin = "rbxassetid://9007",
	gem = "rbxassetid://9008",
	star = "rbxassetid://9009",
	check = "rbxassetid://9010",
}

return function()
	sim.asset(theme.asset.studs, "sim/assets/studs.svg")
	sim.asset(theme.asset.sunburst, "sim/assets/sunburst.svg")
	sim.asset(icon.inventory, "sim/assets/backpack.svg")
	sim.asset(icon.store, "sim/assets/store.svg")
	sim.asset(icon.lucky_block, "sim/assets/lucky.svg")
	sim.asset(icon.cash, "sim/assets/cash.svg")
	sim.asset(icon.brainrot, "sim/assets/cake.svg")
	sim.asset(icon.power, "sim/assets/fist.svg")
	sim.asset(icon.time, "sim/assets/clock.svg")
	sim.asset(icon.upgrades, "sim/assets/bolt.svg")
	sim.asset(icon.sell, "sim/assets/coin.svg")
	for name, id in ids do
		sim.asset(id, `sim/assets/{name}.svg`)
	end
	return ids
end
