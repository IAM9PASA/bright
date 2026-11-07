-- every bright component on one inventory screen
-- node sim/run.mjs gallery        (add --shot for pngs + design checks)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)

-- fake asset ids so the sim can show real icons instead of placeholders
local GEM = "rbxassetid://1001"
local CLOSE = "rbxassetid://1002"
sim.asset(GEM, "sim/assets/gem.svg")
sim.asset(CLOSE, "sim/assets/close.svg")

-- phones get their own proportions: same layout, fewer columns, taller rows. scaling the desktop
-- layout down leaves 8px text and 20px buttons (the sim's checks flag it on the phone presets)
local phone = ui.device() == "phone"

local tab = vide.source("items")
local selected = vide.source(0)

local function item(i: number)
	return ui.card {
		Name = `item_{i}`,
		LayoutOrder = i,
		ui.icon {
			Name = "icon",
			Image = GEM,
			ImageColor3 = ui.theme.color.icon,
			AnchorPoint = Vector2.new(0.5, 0.42),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromScale(0.5, 0.5),
		},
		ui.text {
			Name = "count",
			Text = `x{i * 3}`,
			style = "faint",
			align = "right",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(0.92, 0.95),
			Size = UDim2.fromScale(0.5, 0.22),
		},
		ui.hit {
			hover = true,
			Activated = function()
				selected(i)
			end,
		},
	}
end

local screen = sim.screen("inventory")

-- reactive props (functions) need a vide scope, same as in a real game
vide.mount(function()
	local items = {}
	for i = 1, 14 do
		table.insert(items, item(i))
	end

	local function tab_button(name: string, text: string, order: number)
		return ui.tab {
			Name = name,
			LayoutOrder = order,
			text = text,
			active = function()
				return tab() == name
			end,
			Size = UDim2.fromScale(0.3, 1),
		}
	end

	return ui.panel {
		Name = "main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = if phone then UDim2.fromScale(0.96, 0.97) else UDim2.fromScale(0.62, 0.72),
		-- phones already got a bigger layout above, so only tablets / consoles scale up
		ui.adaptive { phone = 1 },
		ui.padding(0.03, 0.045),

		ui.column {
			Name = "body",
			Size = UDim2.fromScale(1, 1),
			gap = if phone then 0.025 else 0.03,

			ui.row {
				Name = "header",
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, if phone then 0.16 else 0.1),
				gap = 0.015,
				cross = "center",
				ui.text { Name = "title", Text = "Inventory", style = "title", align = "left", Size = UDim2.fromScale(0.3, 0.8), LayoutOrder = 1 },
				ui.pill {
					Name = "search",
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.36, 0.8),
					ui.padding(0.06, 0),
					-- padding inside the textbox insets the text but keeps the whole pill tappable
					ui.input { Name = "box", PlaceholderText = "Search items", Size = UDim2.fromScale(1, 1), ui.padding(0, 0.24) },
				},
				ui.icon_button { Name = "close", image = CLOSE, LayoutOrder = 3, Size = UDim2.fromScale(1, 1) },
			},

			ui.row {
				Name = "tabs",
				LayoutOrder = 2,
				Size = UDim2.fromScale(if phone then 0.6 else 0.5, if phone then 0.15 else 0.085),
				gap = 0.01,
				tab_button("items", "Items", 1),
				tab_button("pets", "Pets", 2),
				tab_button("gear", "Gear", 3),
			},

			ui.scroll_grid {
				Name = "list",
				LayoutOrder = 3,
				Size = UDim2.fromScale(1, if phone then 0.41 else 0.59),
				columns = if phone then 5 else 6,
				items,
			},

			ui.row {
				Name = "footer",
				LayoutOrder = 4,
				Size = UDim2.fromScale(1, if phone then 0.16 else 0.1),
				gap = 0.015,
				align = "end",
				ui.button { Name = "upgrade", text = "Upgrade", style = "ghost", disabled = true, LayoutOrder = 1, Size = UDim2.fromScale(0.18, 1) },
				ui.button { Name = "sell", text = "Sell", LayoutOrder = 2, Size = UDim2.fromScale(0.18, 1) },
				ui.button {
					Name = "equip",
					text = "Equip",
					style = "primary",
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.22, 1),
					disabled = function()
						return selected() == 0
					end,
				},
			},
		},
	}
end, screen)

local panel = screen.main
sim.snapshot("default")

sim.click(panel.body.list.item_3)
sim.hover(panel.body.list.item_2)
sim.press(panel.body.list.item_5)
sim.hover(panel.body.footer.equip)
tab("pets")
sim.snapshot("selected + hover + pets tab")
