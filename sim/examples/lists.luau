-- the same scroll_list with 2 and with 6 cards: the gap between cards is the same in both, because
-- gaps are a share of the list width, not of the canvas (which grows with every card)
-- node sim/run.mjs lists

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local NAMES = { "Sharkalino", "Donutelli", "Cuppa Brr", "Cakey Cakini", "Lucky Block", "Crowny" }
local IMAGES = { ids.shark, ids.donut, ids.cup, ui.theme.asset.icon.brainrot, ui.theme.asset.icon.lucky_block, ids.crown }

local function list(count: number, position: UDim2)
	local rows = {}
	for i = 1, count do
		table.insert(rows, ui.card {
			Name = `row_{i}`,
			LayoutOrder = i,
			Size = UDim2.fromScale(0.94, 0),
			ui.ratio(5),
			ui.icon { Image = IMAGES[i], AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.1, 0.5), Size = UDim2.fromScale(0.15, 0.75) },
			ui.title { Text = NAMES[i], Position = UDim2.fromScale(0.21, 0.28), Size = UDim2.fromScale(0.5, 0.44) },
		})
	end
	return ui.window {
		Name = `List{count}`,
		title = `{count} items`,
		icon = ids.star,
		close = function() end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(0.44, 0.8),
		ui.scroll_list {
			Name = "List",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.573),
			Size = UDim2.fromScale(1, 0.853),
			rows,
		},
	}
end

local screen = sim.screen("Game")

vide.mount(function()
	return { list(2, UDim2.fromScale(0.26, 0.52)), list(6, UDim2.fromScale(0.74, 0.52)) }
end, screen)

sim.snapshot("2 and 6 items")
