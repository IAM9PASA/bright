-- style: amber "Exclusive Store" (large window) with blue / pink / green pack cards
-- node sim/run.mjs store

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local create = vide.create
local theme = ui.theme
local icon = theme.asset.icon

-- inset reward tile: dark, clipped sunburst, icon, amount bottom right
local function reward(image: string, amount: string, order: number, tint: Color3)
	return ui.card {
		Name = `reward_{order}`,
		tile = true,
		LayoutOrder = order,
		Size = UDim2.fromScale(0.3, 1),
		ui.square(),
		create "CanvasGroup" {
			Name = "Rays",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = -1,
			ui.sunburst { ImageColor3 = tint, ImageTransparency = 0.35 },
		},
		ui.icon { Image = image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.7, 0.7) },
		ui.text { Name = "Amount", Text = amount, align = "right", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.94, 0.97), Size = UDim2.fromScale(0.7, 0.26) },
	}
end

-- full-width pack: palette base + thick outline, glossy studded face, rays behind, title, buy, rewards
local function pack(opts)
	local palette = theme.palette[opts.palette]
	return create "Frame" {
		Name = opts.name,
		LayoutOrder = opts.order,
		BackgroundColor3 = palette.base,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.95, 0),
		ui.ratio(2.6),
		create "UIStroke" { Color = palette.stroke, Thickness = 0.03, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize },
		create "Frame" {
			Name = "Main",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(1, 0.96),
			ZIndex = -5,
			ui.gradient(palette.face),
			-- round studs: tile Y = tile X * card aspect (2.6)
			ui.studs(UDim2.fromScale(0.022, 0.022 * 2.6), ui.sequence(palette.studs), UDim2.fromScale(0.992, 0.96), -5),
		},
		create "CanvasGroup" {
			Name = "Rays",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = -2,
			ui.sunburst { ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.55, Position = UDim2.fromScale(0.22, 0.5), Size = UDim2.fromScale(0.6, 2) },
		},
		ui.title { Name = "Title", Text = opts.title, stroke = palette.text, Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.45, 0.24) },
		ui.text { Name = "Desc", Text = opts.desc, style = "item", align = "left", Position = UDim2.fromScale(0.045, 0.36), Size = UDim2.fromScale(0.4, 0.14) },
		ui.text { Name = "Sale", Text = opts.was, style = nil, TextColor3 = theme.color.sale, stroke = Color3.fromHex("410101"), Position = UDim2.fromScale(0.045, 0.53), Size = UDim2.fromScale(0.2, 0.12), align = "left",
			create "Frame" { Name = "Strike", BackgroundColor3 = Color3.fromHex("410101"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.55), Size = UDim2.fromScale(0.62, 0.12) },
		},
		ui.button { Name = "Buy", text = opts.price, palette = "purple", Position = UDim2.fromScale(0.04, 0.68), Size = UDim2.fromScale(0.3, 0.24) },
		ui.row {
			Name = "Items",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.97, 0.5),
			Size = UDim2.fromScale(0.52, 0.62),
			gap = 0.03,
			align = "end",
			reward(opts.rewards[1][1], opts.rewards[1][2], 1, opts.tint),
			reward(opts.rewards[2][1], opts.rewards[2][2], 2, opts.tint),
			reward(opts.rewards[3][1], opts.rewards[3][2], 3, opts.tint),
		},
	}
end

-- small pass card for the row of three
local function pass(name: string, palette_name: string, title: string, image: string, price: string, order: number)
	local palette = theme.palette[palette_name]
	return create "Frame" {
		Name = name,
		LayoutOrder = order,
		BackgroundColor3 = palette.base,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.3, 1),
		create "UIStroke" { Color = palette.stroke, Thickness = 0.04, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize },
		create "Frame" {
			Name = "Main",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(1, 0.96),
			ZIndex = -5,
			ui.gradient(palette.face),
			ui.studs(UDim2.fromScale(0.07, 0.07 * 0.92), ui.sequence(palette.studs), UDim2.fromScale(0.99, 0.96), -5),
		},
		create "CanvasGroup" {
			Name = "Rays",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = -2,
			ui.sunburst { ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.5, Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(1.33, 1.33) },
		},
		ui.title { Name = "Title", Text = title, align = "center", stroke = palette.text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.9, 0.15) },
		ui.icon { Image = image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.6, 0.48) },
		ui.button { Name = "Buy", text = price, palette = "purple", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.66, 0.22) },
	}
end

local screen = sim.screen("CakeUi")

vide.mount(function()
	return ui.window {
		Name = "Store",
		title = "Exclusive Store",
		icon = icon.store,
		palette = "amber",
		shape = "large",
		close = function() end,
		Size = UDim2.fromScale(0.7, 0.86),
		ui.adaptive { phone = 1 },

		ui.scroll_list {
			Name = "ShopMainScroll",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.559),
			Size = UDim2.fromScale(1, 0.86),
			pack {
				name = "StarterPack", order = 1, palette = "blue", title = "Starter Pack", desc = "BEST VALUE", was = "R$ 199", price = "R$ 99",
				tint = Color3.fromHex("0091FF"),
				rewards = { { icon.cash, "+50K" }, { icon.lucky_block, "x3" }, { ids.shark, "x1" } },
			},
			ui.box {
				Name = "Passes",
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.95, 0),
				ui.ratio(2.9),
				-- 0.04 of the row width is over twice a pass outline, so neighbours never touch
				ui.list_layout { direction = "row", gap = 0.04, align = "center" },
				pass("SellPrice", "green", "x2 Sell", ids.coin, "R$ 149", 1),
				pass("Speed", "gold", "x2 Speed", ids.bolt, "R$ 99", 2),
				pass("VIP", "pink", "VIP", ids.crown, "R$ 349", 3),
			},
			pack {
				name = "ProPack", order = 3, palette = "pink", title = "PRO Pack", desc = "LIMITED TIME", was = "R$ 999", price = "R$ 499",
				tint = Color3.fromHex("FF67FF"),
				rewards = { { ids.gem, "x250" }, { ids.gift, "x5" }, { ids.crown, "VIP" } },
			},
		},
	}
end, screen)

sim.snapshot("store")
sim.hover(screen.Store.ShopMainScroll.StarterPack.Buy)
sim.snapshot("hover buy")
