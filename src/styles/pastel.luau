-- style: pastel. soft cream windows, round everything, bubbly pill buttons with a light rim,
-- rounded friendly font. for cute pet, cafe and dress-up games.

local extend = require(script.Parent.Parent.style).extend
local base = require(script.Parent.brainrot)

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

local function bubble(top: string, bottom: string, rim: string, outline: string)
	return { base = rgb(rim), stroke = rgb(rim), face = { rgb(top), rgb(bottom) }, studs = { rgb(top), rgb(bottom) }, text = rgb(outline), label = rgb("FFFFFF") }
end

return extend(base, {
	name = "pastel",
	accent = "pink",

	surface = {
		color = rgb("FFF7FB"),
		transparency = 0,
		stroke = rgb("FFFFFF"),
		stroke_transparency = 0,
		tile_color = rgb("FCE7F3"),
		tile_transparency = 0,
		corner = UDim.new(0.07, 0),
	},
	-- white outline: bubbly on the cream window, and keeps white titles readable on pastel bars
	text = { outline = true, drop = false, upper = false },
	header = { kind = "bar", height = 0.14, studs = false, corner = UDim.new(0.35, 0), close = "red" },
	button = { kind = "candy", studs = false, corner = UDim.new(0.5, 0), outline = true },
	card = { corner = UDim.new(0.16, 0), rays = false },
	progress = { corner = UDim.new(0.5, 0) },

	palette = {
		pink = bubble("FFB8DA", "FF7EB9", "E85A9C", "A8336B"),
		blue = bubble("A8D8FF", "6FB8FF", "4A93E0", "2A5E9C"),
		green = bubble("B5F0C0", "6FD98A", "4AB86A", "2A7A45"),
		red = bubble("FFB3B3", "FF7A7A", "E05555", "9C2E2E"),
		purple = bubble("D9C2FF", "B08CFF", "8F66E8", "5A3A9C"),
		orange = bubble("FFD2A8", "FFAA6F", "E88A4A", "9C5A2A"),
		gold = bubble("FFEFA8", "FFD45C", "E8B43A", "8F6A12"),
		amber = bubble("FFE2A8", "FFC06F", "E8A04A", "8F5E12"),
		grey = bubble("EDE4EC", "CFC2CE", "B3A4B2", "6E5E6D"),
	},

	text_gradient = {
		cash = { colors = { rgb("23874A"), rgb("1A6E3B") }, stroke = rgb("FFFFFF") },
		legendary = { colors = { rgb("C26A00"), rgb("A35800") }, stroke = rgb("FFFFFF") },
		epic = { colors = { rgb("7A3FE0"), rgb("632CC4") }, stroke = rgb("FFFFFF") },
		rare = { colors = { rgb("1F6FD0"), rgb("1A5CB0") }, stroke = rgb("FFFFFF") },
		common = { colors = { rgb("6E5A6C"), rgb("5A485A") }, stroke = rgb("FFFFFF") },
		gems = { colors = { rgb("C42C70"), rgb("A8225E") }, stroke = rgb("FFFFFF") },
		item = { colors = { rgb("A8561E"), rgb("8A4416") }, stroke = rgb("FFFFFF") },
		rainbow = { colors = { rgb("D93A64"), rgb("B87A00"), rgb("23874A"), rgb("1F6FD0"), rgb("7A3FE0") }, stroke = rgb("FFFFFF"), rotation = 0 },
	},

	color = {
		text = rgb("5B3A6E"),
		text_dim = rgb("947AA3"),
		outline = rgb("FFFFFF"),
		selected = rgb("FF7EB9"),
		divider = rgb("F9D2E6"),
	},

	font = {
		title = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
		body = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
	},

	stroke = { window = 0.012, card = 0.03, button = 0.06, header = 0.05, label = 0.08, title = 0.09 },
})
