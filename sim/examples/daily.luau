-- style: pink "Daily Rewards" window, 7 day grid with claimed / today / locked cells
-- node sim/run.mjs daily

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local create = vide.create
local theme = ui.theme
local icon = theme.asset.icon

local REWARDS = {
	{ image = icon.cash, amount = "+5K" },
	{ image = ids.gem, amount = "x10" },
	{ image = icon.lucky_block, amount = "x1" },
	{ image = icon.cash, amount = "+25K" },
	{ image = ids.gift, amount = "x2" },
	{ image = ids.gem, amount = "x50" },
	{ image = ids.crown, amount = "VIP 1d" },
}

local today = vide.source(3)
local claimed = vide.source(2) -- days already claimed

local function day(i: number, reward)
	local state = function()
		if i <= claimed() then return "claimed" end
		if i == today() then return "today" end
		return "locked"
	end

	return ui.card {
		Name = `day_{i}`,
		LayoutOrder = i,
		tile = true,
		selected = function() return state() == "today" end,
		create "CanvasGroup" {
			Name = "Rays",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = -1,
			GroupTransparency = function() return if state() == "locked" then 0.8 else 0 end,
			ui.sunburst { ImageColor3 = if i == 7 then Color3.fromHex("FFFF1A") else Color3.fromHex("FF67FF"), Position = UDim2.fromScale(0.5, 0.48) },
		},
		ui.title { Name = "Day", Text = `Day {i}`, align = "center", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.8, 0.17) },
		ui.icon {
			Name = "Icon",
			Image = reward.image,
			ImageTransparency = function() return if state() == "locked" then 0.5 else 0 end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.55, 0.55),
		},
		ui.text { Name = "Amount", Text = reward.amount, style = if i == 7 then "legendary" else nil, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.85, 0.17) },
		ui.icon {
			Name = "Check",
			Image = ids.check,
			Visible = function() return state() == "claimed" end,
			ZIndex = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.6, 0.6),
		},
	}
end

local screen = sim.screen("CakeUi")

vide.mount(function()
	local cells = {}
	for i, reward in REWARDS do
		table.insert(cells, day(i, reward))
	end

	return ui.window {
		Name = "DailyRewards",
		title = "Daily Rewards",
		icon = ids.gift,
		palette = "pink",
		close = function() end,
		Size = UDim2.fromScale(0.58, 0.8),
		ui.adaptive { phone = 1.2 },

		ui.scroll_grid {
			Name = "Days",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.17),
			Size = UDim2.fromScale(0.94, 0.62),
			columns = 4,
			ratio = 0.85,
			gap_x = 0.03,
			cells,
		},
		ui.text {
			Name = "Streak",
			Text = function() return `Streak: {claimed()} days` end,
			style = "legendary",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.04, 0.89),
			Size = UDim2.fromScale(0.4, 0.07),
			align = "left",
		},
		ui.button {
			Name = "Claim",
			text = function() return if claimed() >= today() then "Come back!" else "Claim" end,
			palette = "gold",
			disabled = function() return claimed() >= today() end,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.96, 0.89),
			Size = UDim2.fromScale(0.32, 0.11),
			Activated = function() claimed(today()) end,
		},
	}
end, screen)

sim.snapshot("day 3 ready")
sim.click(screen.DailyRewards.Claim)
sim.snapshot("claimed")
