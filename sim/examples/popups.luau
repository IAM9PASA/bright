-- style: small popups over a dimmed screen. red "delete?" confirm, green "you got" reward.
-- each window has `open = source`, so it springs in and out (ui.presence) instead of popping
-- node sim/run.mjs popups

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local create = vide.create
local theme = ui.theme
local icon = theme.asset.icon

local open = vide.source("confirm") -- "confirm" | "reward" | nil

local function dim()
	return create "Frame" {
		Name = "Dim",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = function() return open() ~= nil end,
	}
end

local function confirm()
	return ui.window {
		Name = "Confirmation",
		title = "Delete?",
		icon = icon.sell,
		palette = "red",
		shape = "popup",
		close = function() open(nil) end,
		open = function() return open() == "confirm" end,
		Size = UDim2.fromScale(0.42, 0.5),
		ZIndex = 10,
		ui.adaptive { phone = 1.35 },

		ui.card {
			Name = "Preview",
			tile = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.17, 0.52),
			Size = UDim2.fromScale(0.24, 0.45),
			ui.square(),
			ui.icon { Image = ids.shark, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.85, 0.85) },
		},
		ui.title { Name = "Question", Text = "Delete Sharkalino?", Position = UDim2.fromScale(0.33, 0.3), Size = UDim2.fromScale(0.62, 0.15) },
		ui.text { Name = "Warning", Text = "You can't get it back!", style = "dim", align = "left", Position = UDim2.fromScale(0.33, 0.5), Size = UDim2.fromScale(0.6, 0.1) },
		ui.text { Name = "Value", Text = "Earns $1.2K/s", style = "cash", align = "left", Position = UDim2.fromScale(0.33, 0.62), Size = UDim2.fromScale(0.5, 0.1) },
		ui.button { Name = "No", text = "No", palette = "grey", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.3, 0.86), Size = UDim2.fromScale(0.36, 0.16), Activated = function() open(nil) end },
		ui.button { Name = "Yes", text = "Delete", palette = "red", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.7, 0.86), Size = UDim2.fromScale(0.36, 0.16), Activated = function() open(nil) end },
	}
end

local function reward()
	return ui.window {
		Name = "Reward",
		title = "You got!",
		icon = ids.gift,
		palette = "green",
		shape = "popup",
		open = function() return open() == "reward" end,
		Size = UDim2.fromScale(0.42, 0.5),
		ZIndex = 10,
		ui.adaptive { phone = 1.35 },

		create "CanvasGroup" {
			Name = "Rays",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(1, 0.6),
			ZIndex = -1,
			ui.sunburst { ImageColor3 = Color3.fromHex("A6FF01"), ImageTransparency = 0.2, Size = UDim2.fromScale(1.6, 1.6) },
		},
		ui.icon { Name = "Icon", Image = icon.lucky_block, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.36, 0.38) },
		ui.title { Name = "Amount", Text = "x3 Lucky Block", style = "rainbow", align = "center", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.71), Size = UDim2.fromScale(0.8, 0.13) },
		ui.button { Name = "Ok", text = "Awesome!", palette = "green", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.88), Size = UDim2.fromScale(0.46, 0.15), Activated = function() open(nil) end },
	}
end

local screen = sim.screen("CakeUi", { DisplayOrder = 5 })

vide.mount(function()
	return { dim(), confirm(), reward() }
end, screen)

local function find(name)
	return screen:FindFirstChild(name, true)
end

sim.snapshot("confirm delete")
sim.hover(find("Yes"))
sim.snapshot("hover delete")

-- switch popups: the confirm springs out while the reward springs in
open("reward")
sim.step(0.06)
sim.snapshot("switching (60ms in)")
sim.step(1)
assert(screen.Confirmation.Visible == false, "closed presence should hide itself")
assert(screen.Reward.Fade:FindFirstChild("Content") == nil and screen.Reward.Still:FindFirstChild("Content"), "settled content should leave the canvas")
sim.snapshot("reward")

open(nil)
sim.step(0.08)
assert(screen.Reward.Fade:FindFirstChild("Content"), "closing content should be back in the canvas")
sim.snapshot("closing (80ms in)")
