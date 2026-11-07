-- inventory screen in the brainrot / cake style, laid out like CakeUi.Main.Inventory
-- node sim/run.mjs gallery        (add --shot for pngs + design checks)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)

local theme = ui.theme
local icon = theme.asset.icon

-- the sim cannot load roblox images, so show local stand-ins for the real ids
sim.asset(theme.asset.studs, "sim/assets/studs.svg")
sim.asset(theme.asset.sunburst, "sim/assets/sunburst.svg")
sim.asset(icon.inventory, "sim/assets/backpack.svg")
sim.asset(icon.store, "sim/assets/store.svg")
sim.asset(icon.lucky_block, "sim/assets/lucky.svg")
sim.asset(icon.cash, "sim/assets/cash.svg")
sim.asset(icon.brainrot, "sim/assets/cake.svg")
sim.asset("rbxassetid://9001", "sim/assets/donut.svg")
sim.asset("rbxassetid://9002", "sim/assets/cup.svg")
sim.asset("rbxassetid://9003", "sim/assets/shark.svg")

local ITEMS = {
	{ name = "Cakey Cakini", image = icon.brainrot, value = "$12/s", rarity = "common", rays = Color3.fromHex("0091FF") },
	{ name = "Donutelli", image = "rbxassetid://9001", value = "$40/s", rarity = "rare", rays = Color3.fromHex("0091FF") },
	{ name = "Cuppa Brr", image = "rbxassetid://9002", value = "$95/s", rarity = "epic", rays = Color3.fromHex("FF67FF") },
	{ name = "Sharkalino", image = "rbxassetid://9003", value = "$1.2K/s", rarity = "legendary", rays = Color3.fromHex("FFFF1A") },
	{ name = "Lucky Block", image = icon.lucky_block, value = "$5K/s", rarity = "rainbow", rays = Color3.fromHex("A6FF01") },
}

-- phones get a bigger window: the same screen fraction is too small to read or tap there
local phone = ui.device() == "phone"

local tab = vide.source("brainrots")
local selected = vide.source(0)

local function item_at(i: number)
	return ITEMS[(i - 1) % #ITEMS + 1]
end

local function current()
	local i = selected()
	return if i == 0 then nil else item_at(i)
end

local screen = sim.screen("CakeUi")

vide.mount(function()
	local cards = {}
	for i = 1, 11 do
		local item = item_at(i)
		table.insert(cards, ui.item_card {
			Name = `item_{i}`,
			LayoutOrder = i,
			name = item.name,
			image = item.image,
			value = item.value,
			rarity = item.rarity,
			sunburst = item.rays,
			selected = function()
				return selected() == i
			end,
			Activated = function()
				selected(i)
			end,
		})
	end

	return {
		-- left hud column, like Buttons.Left
		ui.column {
			Name = "Buttons",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.012, 0.5),
			Size = UDim2.fromScale(0.07, 0.5),
			gap = 0.03,
			ui.hud_button { Name = "Store", text = "Store", image = icon.store, notify = true, LayoutOrder = 1, Size = UDim2.fromScale(1, 0.3) },
			ui.hud_button { Name = "Bag", text = "Bag", image = icon.inventory, LayoutOrder = 2, Size = UDim2.fromScale(1, 0.3) },
			ui.hud_button { Name = "Lucky", text = "Lucky", image = icon.lucky_block, LayoutOrder = 3, Size = UDim2.fromScale(1, 0.3) },
		},

		ui.window {
			Name = "Inventory",
			title = "Inventory",
			icon = icon.inventory,
			palette = "blue",
			shape = "inventory",
			close = function() end,
			Size = if phone then UDim2.fromScale(0.8, 0.98) else UDim2.fromScale(0.62, 0.8),
			ui.adaptive { phone = 1 },

			-- left 67%: tabs, capacity bar, grid
			ui.box {
				Name = "Holder",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.347, 0.566),
				Size = UDim2.fromScale(0.674, 0.83),

				ui.row {
					Name = "Tabs",
					Size = UDim2.fromScale(0.62, if phone then 0.15 else 0.11),
					Position = UDim2.fromScale(0.03, 0.01),
					gap = 0.03,
					ui.tab { Name = "brainrots", text = "Brainrots", LayoutOrder = 1, Size = UDim2.fromScale(0.48, 1), active = function() return tab() == "brainrots" end },
					ui.tab { Name = "items", text = "Items", LayoutOrder = 2, Size = UDim2.fromScale(0.38, 1), palette = "orange", active = function() return tab() == "items" end },
				},
				ui.progress {
					Name = "Capacity",
					value = 11 / 30,
					text = "11 / 30",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(0.97, 0.025),
					Size = UDim2.fromScale(0.3, 0.08),
				},
				ui.scroll_grid {
					Name = "List",
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					Size = UDim2.fromScale(0.97, if phone then 0.81 else 0.85),
					columns = if phone then 3 else 4,
					ratio = 0.9,
					gap_x = 0.03,
					cards,
				},
			},

			-- right side: preview of the selected item + actions
			ui.card {
				Name = "Side",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.841, 0.568),
				Size = UDim2.fromScale(0.284, 0.805),

				ui.card {
					Name = "Main",
					tile = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.271),
					Size = UDim2.fromScale(0.832, 0.442),
					vide.create "CanvasGroup" {
						Name = "Rays",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						ZIndex = -1,
						ui.sunburst {
							ImageColor3 = function()
								local item = current()
								return if item then item.rays else Color3.fromHex("0091FF")
							end,
							Size = UDim2.fromScale(1.4, 1.4),
						},
					},
					ui.icon {
						Name = "Icon",
						Image = function()
							local item = current()
							return if item then item.image else icon.lucky_block
						end,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.52),
						Size = UDim2.fromScale(0.68, 0.68),
					},
					ui.title {
						Name = "Title",
						Text = function()
							local item = current()
							return if item then item.name else "Pick one!"
						end,
						align = "center",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.11),
						Size = UDim2.fromScale(0.92, 0.15),
					},
					ui.text {
						Name = "Rarity",
						Text = function()
							local item = current()
							if not item then return "" end
							return string.upper(if item.rarity == "rainbow" then "OP" else item.rarity)
						end,
						style = "legendary",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.91),
						Size = UDim2.fromScale(0.8, 0.13),
					},
				},

				ui.text {
					Name = "Cash",
					Text = function()
						local item = current()
						return if item then item.value else "$0/s"
					end,
					style = "cash",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.57),
					Size = UDim2.fromScale(0.8, 0.1),
				},
				ui.button {
					Name = "Equip",
					text = "Equip",
					palette = "green",
					disabled = function()
						return selected() == 0
					end,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, if phone then 0.71 else 0.725),
					Size = UDim2.fromScale(0.9, if phone then 0.17 else 0.14),
				},
				ui.button {
					Name = "Delete",
					text = "Delete",
					palette = "red",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, if phone then 0.895 else 0.9),
					Size = UDim2.fromScale(0.9, if phone then 0.17 else 0.14),
				},
			},
		},
	}
end, screen)

local window = screen.Inventory
sim.snapshot("default")

sim.click(window.Holder.List.item_4)
sim.hover(window.Side.Equip)
sim.press(window.Holder.List.item_2)
tab("items")
sim.snapshot("selected + hover + press")
