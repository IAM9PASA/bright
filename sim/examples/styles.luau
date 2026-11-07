-- every built-in style side by side. each window is the same function, only the style passed in changes.
-- node sim/run.mjs styles

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bright = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local icon = bright.theme.asset.icon

local ORDER = { "brainrot", "clean", "glass", "scifi", "fantasy", "pastel" }
local NAMES = { brainrot = "Brainrot", clean = "Clean", glass = "Glass", scifi = "Sci-fi", fantasy = "Fantasy", pastel = "Pastel" }

local function sample(ui, name: string, position: UDim2)
	local music = vide.source(true)
	local tab = vide.source(1)

	return ui.window {
		Name = name,
		title = NAMES[name],
		icon = icon.store,
		close = function() end,
		shape = "standard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(0.31, 0.44),

		ui.row {
			Name = "Tabs",
			Position = UDim2.fromScale(0.05, 0.2),
			Size = UDim2.fromScale(0.56, 0.12),
			gap = 0.04,
			ui.tab { Name = "Shop", text = "Shop", LayoutOrder = 1, Size = UDim2.fromScale(0.48, 1), active = function() return tab() == 1 end },
			ui.tab { Name = "Bag", text = "Bag", LayoutOrder = 2, Size = UDim2.fromScale(0.48, 1), active = function() return tab() == 2 end },
		},
		ui.progress { Name = "Level", value = 0.62, text = "Lv 12", Position = UDim2.fromScale(0.05, 0.38), Size = UDim2.fromScale(0.56, 0.09) },
		ui.text { Name = "Music", Text = "Music", align = "left", Position = UDim2.fromScale(0.05, 0.53), Size = UDim2.fromScale(0.25, 0.09) },
		ui.toggle { Name = "Toggle", on = music, Position = UDim2.fromScale(0.33, 0.52), Size = UDim2.fromScale(0.28, 0.11) },
		ui.row {
			Name = "Buttons",
			Position = UDim2.fromScale(0.05, 0.72),
			Size = UDim2.fromScale(0.9, 0.17),
			gap = 0.03,
			ui.button { Name = "Play", text = "Play", LayoutOrder = 1, Size = UDim2.fromScale(0.36, 1) },
			ui.button { Name = "Buy", text = "Buy", palette = "gold", LayoutOrder = 2, Size = UDim2.fromScale(0.3, 1) },
			ui.button { Name = "Quit", text = "Quit", palette = "red", LayoutOrder = 3, Size = UDim2.fromScale(0.28, 1) },
		},
		ui.column {
			Name = "Cards",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(0.95, 0.19),
			Size = UDim2.fromScale(0.3, 0.48),
			gap = 0.04,
			ui.item_card { Name = "Shark", name = "Sharkalino", image = ids.shark, value = "$1.2K/s", rarity = "legendary", sunburst = Color3.fromHex("FFFF1A"), selected = true, LayoutOrder = 1, Size = UDim2.fromScale(1, 1), ui.square(0.9) },
		},
	}
end

local screen = sim.screen("Game")

vide.mount(function()
	local windows = {}
	for i, name in ORDER do
		local column, row = (i - 1) % 3, (i - 1) // 3
		table.insert(windows, sample(bright.with(bright.styles[name]), name, UDim2.fromScale(0.175 + column * 0.325, 0.29 + row * 0.47)))
	end
	return windows
end, screen)

sim.snapshot("six styles")
sim.hover(screen.glass.Buttons.Play)
sim.press(screen.pastel.Buttons.Buy)
sim.snapshot("hover + press")
