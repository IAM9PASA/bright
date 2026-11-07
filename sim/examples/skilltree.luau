-- radius-3 hex skill tree: owned nodes glow green, the ones next to them can be bought (gold),
-- the rest are locked. clicking a gold node spends a point and opens its neighbours
-- node sim/run.mjs skilltree

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)
local ids = require(ReplicatedStorage.Shared.stand_ins)()

local icon = ui.theme.asset.icon
local ICONS = { icon.power, ids.bolt, ids.star, ids.gem, icon.time, ids.coin }
local NEIGHBOURS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, -1 }, { -1, 1 } }

local owned = vide.source({ ["0,0"] = true })
local points = vide.source(3)

local function key(q, r)
	return `{q},{r}`
end

local function state(q, r)
	local have = owned()
	if have[key(q, r)] then return "owned" end
	for _, step in NEIGHBOURS do
		if have[key(q + step[1], r + step[2])] then return "open" end
	end
	return "locked"
end

local PALETTE = { owned = "green", open = "gold", locked = "grey" }

local function node(q, r)
	local current = function() return state(q, r) end
	local center = q == 0 and r == 0
	local image = ICONS[(q * 3 + r * 5) % #ICONS + 1]

	return ui.hex_stack(function() return if center then "blue" else PALETTE[current()] end, {
		Name = "Node",
		ui.icon {
			Name = "Icon",
			Image = if center then icon.store else image,
			ImageTransparency = function() return if current() == "locked" then 0.55 else 0 end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(0.5, 0.5),
		},
		ui.hit {
			hover = true,
			Activated = function()
				if current() ~= "open" or points() <= 0 then return end
				local have = table.clone(owned())
				have[key(q, r)] = true
				owned(have)
				points(points() - 1)
			end,
		},
	})
end

local screen = sim.screen("Game")

vide.mount(function()
	return ui.window {
		Name = "Skills",
		title = "Skill Tree",
		icon = ids.star,
		palette = "purple",
		close = function() end,
		Size = UDim2.fromScale(0.62, 0.86),
		ui.adaptive { phone = 1 },

		ui.counter {
			Name = "Points",
			value = points,
			format = function(n) return if math.round(n) == 1 then "1 point" else `{math.round(n)} points` end,
			style = "legendary",
			align = "right",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.9, 0.067),
			Size = UDim2.fromScale(0.3, 0.07),
			ZIndex = 5,
		},
		ui.hex_grid {
			Name = "Tree",
			radius = 3,
			cell = node,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.57),
			Size = UDim2.fromScale(0.94, 0.8),
		},
	}
end, screen)

sim.snapshot("start")
local tree = screen.Skills.Tree
assert(#tree:GetChildren() == 37 + 1, `radius 3 should have 37 cells, got {#tree:GetChildren() - 1}`)

local function button(slot)
	return tree[slot]:FindFirstChild("button", true)
end
sim.click(button("hex_1_0"))
sim.click(button("hex_2_0"))
assert(points() == 1, `two buys should leave 1 point, got {points()}`)
sim.hover(button("hex_-1_1"))
sim.snapshot("bought two")
