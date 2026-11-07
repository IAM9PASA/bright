-- style: glass. dark see-through windows, mint glow edges, glowing buttons, clean white text.
-- the neon / "script hub" look.

local extend = require(script.Parent.Parent.style).extend
local base = require(script.Parent.brainrot)

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

local function glow(top: string, bottom: string, edge: string, label: string?)
	return { base = rgb(edge), stroke = rgb(bottom), face = { rgb(top), rgb(bottom) }, studs = { rgb(top), rgb(bottom) }, text = rgb(edge), label = rgb(label or "06140C") }
end

return extend(base, {
	name = "glass",
	accent = "green",

	surface = {
		color = Color3.new(1, 1, 1),
		transparency = 0.12,
		gradient = { rgb("15241D"), rgb("0B1411"), rgb("070D0B") },
		stroke = rgb("4ADE80"),
		stroke_transparency = 0.55,
		tile_color = rgb("FFFFFF"),
		tile_transparency = 0.94,
		corner = UDim.new(0.04, 0),
		glow = { color = rgb("4ADE80"), transparency = 0.86, thickness = 0.02 },
	},
	text = { outline = false, drop = false, upper = false },
	header = { kind = "plain", height = 0.13, studs = false, close = "grey" },
	button = { kind = "glow", studs = false, corner = UDim.new(0.22, 0), outline = false },
	card = { corner = UDim.new(0.1, 0), rays = false },
	progress = { corner = UDim.new(0.5, 0) },

	palette = {
		green = glow("7CF5A8", "2FD47A", "0E3B22"),
		blue = glow("7CC8FF", "3B9BFF", "0B2647"),
		red = glow("FF8A8A", "FF4D4D", "4A0E0E", "1F0505"),
		orange = glow("FFC07A", "FF8F3D", "4A260B"),
		gold = glow("FFE58A", "FFC53D", "4A3A0B"),
		amber = glow("FFE58A", "FFB020", "4A350B"),
		purple = glow("C9A8FF", "9B6BFF", "2A1150", "12052A"),
		pink = glow("FF9BD2", "FF52A8", "4A0E2E", "24051A"),
		grey = { base = rgb("2A3330"), stroke = rgb("4B5A55"), face = { rgb("26302C"), rgb("1A221F") }, studs = { rgb("26302C"), rgb("1A221F") }, text = rgb("0A0F0D"), label = rgb("D7E5DD") },
	},

	text_gradient = {
		cash = { colors = { rgb("B6FFCF"), rgb("4ADE80") }, stroke = rgb("06140C") },
		legendary = { colors = { rgb("FFF1A8"), rgb("FFC53D") }, stroke = rgb("1A1405") },
		epic = { colors = { rgb("E2CCFF"), rgb("A97BFF") }, stroke = rgb("12052A") },
		rare = { colors = { rgb("C4E6FF"), rgb("5AB0FF") }, stroke = rgb("051226") },
		common = { colors = { rgb("FFFFFF"), rgb("B9C9C1") }, stroke = rgb("0A0F0D") },
		gems = { colors = { rgb("FFB8D6"), rgb("FF5C9A") }, stroke = rgb("24051A") },
		item = { colors = { rgb("FFD7A8"), rgb("FF9F4D") }, stroke = rgb("1F1005") },
		rainbow = { colors = { rgb("FF7A7A"), rgb("FFE27A"), rgb("7AFFA8"), rgb("7AD0FF"), rgb("D07AFF") }, stroke = rgb("0A0F0D"), rotation = 0 },
	},

	color = {
		text = rgb("F2FFF7"),
		text_dim = rgb("A3B8AD"),
		outline = rgb("06140C"),
		selected = rgb("4ADE80"),
		divider = rgb("4ADE80"),
	},

	font = {
		title = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
		body = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold),
	},

	stroke = { window = 0.004, card = 0.012, button = 0.03, header = 0, label = 0, title = 0 },
})
