-- style: gold "Upgrades" window, rows with stat icon, level bar and buy button.
-- maxed rows are disabled (nothing to do), too-expensive rows are locked (click = shake, no buy)
-- node sim/run.mjs upgrades

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local theme = ui.theme
local icon = theme.asset.icon

local UPGRADES = {
	{ name = "Stomach", stat = "+25 Capacity", image = icon.brainrot, level = 3, max = 10, price = "$1.2K", cost = 1200 },
	{ name = "Power", stat = "+5 Strength", image = icon.power, level = 7, max = 10, price = "$18K", cost = 18000 },
	{ name = "Speed", stat = "+2 Walk Speed", image = ids.bolt, level = 1, max = 5, price = "$450", cost = 450 },
	{ name = "Luck", stat = "+1% Luck", image = ids.star, level = 5, max = 5, price = "MAX", cost = 0 },
	{ name = "Cooldown", stat = "-0.1s Eat Time", image = icon.time, level = 2, max = 8, price = "$95K", cost = 95000 },
}

local cash = vide.source(25_000)

local function row(index: number, upgrade)
	local level = vide.source(upgrade.level)
	local maxed = function() return level() >= upgrade.max end

	return ui.card {
		Name = upgrade.name,
		LayoutOrder = index,
		Size = UDim2.fromScale(0.96, 0),
		ui.ratio(5.2),

		-- icon tile on the left
		ui.card {
			Name = "Main",
			tile = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.08, 0.5),
			Size = UDim2.fromScale(0.13, 0.8),
			ui.square(),
			ui.icon { Name = "Icon", Image = upgrade.image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.85, 0.85) },
		},
		ui.title { Name = "Title", Text = upgrade.name, Position = UDim2.fromScale(0.17, 0.1), Size = UDim2.fromScale(0.4, 0.33) },
		ui.text { Name = "Stat", Text = upgrade.stat, style = "cash", align = "left", Position = UDim2.fromScale(0.17, 0.5), Size = UDim2.fromScale(0.4, 0.2) },
		ui.progress {
			Name = "Level",
			value = function() return level() / upgrade.max end,
			text = function() return if maxed() then "MAX" else `Lv {level()} / {upgrade.max}` end,
			Position = UDim2.fromScale(0.17, 0.74),
			Size = UDim2.fromScale(0.42, 0.17),
		},
		ui.button {
			Name = "Buy",
			text = function() return if maxed() then "MAX" else upgrade.price end,
			palette = "green",
			disabled = maxed,
			locked = function() return not maxed() and cash() < upgrade.cost end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.85, 0.5),
			Size = UDim2.fromScale(0.24, 0.55),
			Activated = function()
				if maxed() then return end
				cash(cash() - upgrade.cost)
				level(level() + 1)
			end,
		},
	}
end

local screen = sim.screen("CakeUi")

vide.mount(function()
	local rows = {}
	for i, upgrade in UPGRADES do
		table.insert(rows, row(i, upgrade))
	end

	return ui.window {
		Name = "Upgrades",
		title = "Upgrades",
		icon = icon.upgrades,
		palette = "gold",
		close = function() end,
		Size = UDim2.fromScale(0.55, 0.8),
		ui.adaptive { phone = 1.25 },

		ui.counter {
			Name = "Cash",
			value = cash,
			format = function(n) return `$ {ui.thousands(n)}` end,
			style = "cash",
			align = "right",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.86, 0.067),
			Size = UDim2.fromScale(0.3, 0.07),
			ZIndex = 5,
		},
		ui.scroll_list {
			Name = "List",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.573),
			Size = UDim2.fromScale(1, 0.853),
			rows,
		},
	}
end, screen)

sim.snapshot("upgrades")

-- cooldown costs $95K with $25K cash: locked, so the click shakes and buys nothing
local cooldown = screen.Upgrades.List.Cooldown
sim.click(cooldown.Buy)
assert(cooldown.Buy.Interactable ~= false, "locked buttons must stay clickable")
assert(cash() == 25000, "a locked click must not run Activated")

sim.click(screen.Upgrades.List.Speed.Buy)
assert(cash() == 25000 - 450, "an unlocked click buys")
assert(screen.Upgrades.Cash.Text == "$ 24,550", `counter should roll to $ 24,550, got {screen.Upgrades.Cash.Text}`)
sim.hover(screen.Upgrades.List.Power.Buy)
sim.snapshot("bought speed + hover")
