-- style: the same settings window in four palettes. only `palette` changes, everything else is shared
-- node sim/run.mjs themes

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local theme = ui.theme
local icon = theme.asset.icon

local SETTINGS = {
	{ name = "Music", image = ids.star },
	{ name = "Sounds", image = ids.bolt },
	{ name = "Low Graphics", image = ids.gem },
}

local function settings_window(palette: string, title: string, position: UDim2)
	local rows = {}
	for i, setting in SETTINGS do
		local on = vide.source(i ~= 3)
		table.insert(rows, ui.card {
			Name = setting.name,
			LayoutOrder = i,
			Size = UDim2.fromScale(0.94, 0),
			ui.ratio(5.6),
			ui.icon { Name = "Icon", Image = setting.image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.1, 0.5), Size = UDim2.fromScale(0.14, 0.7) },
			ui.title { Name = "Title", Text = setting.name, Position = UDim2.fromScale(0.2, 0.28), Size = UDim2.fromScale(0.45, 0.42) },
			ui.toggle { Name = "Toggle", on = on, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.5), Size = UDim2.fromScale(0.3, 0.38) },
		})
	end

	return ui.window {
		Name = `Settings_{palette}`,
		title = title,
		icon = icon.upgrades,
		palette = palette,
		close = function() end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(0.44, 0.44),

		ui.scroll_list {
			Name = "List",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.573),
			Size = UDim2.fromScale(1, 0.853),
			rows,
		},
	}
end

local screen = sim.screen("CakeUi")

vide.mount(function()
	return {
		settings_window("blue", "Settings", UDim2.fromScale(0.27, 0.26)),
		settings_window("green", "Settings", UDim2.fromScale(0.73, 0.26)),
		settings_window("pink", "Settings", UDim2.fromScale(0.27, 0.75)),
		settings_window("orange", "Settings", UDim2.fromScale(0.73, 0.75)),
	}
end, screen)

sim.snapshot("four palettes")
