-- style: clean. light, flat and minimal: white rounded windows, soft grey lines, solid buttons,
-- dark text without outlines. reads like a modern app.

local extend = require(script.Parent.Parent.style).extend
local base = require(script.Parent.brainrot)

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

local function solid(fill: string, edge: string, label: string?)
	return { base = rgb(edge), stroke = rgb(edge), face = { rgb(fill), rgb(fill) }, studs = { rgb(fill), rgb(fill) }, text = rgb(edge), label = rgb(label or "FFFFFF") }
end

return extend(base, {
	name = "clean",
	accent = "blue",

	surface = {
		color = rgb("FFFFFF"),
		transparency = 0,
		stroke = rgb("E3E7EC"),
		stroke_transparency = 0,
		tile_color = rgb("F4F6F8"),
		tile_transparency = 0,
		corner = UDim.new(0.045, 0),
	},
	text = { outline = false, drop = false, upper = false },
	header = { kind = "plain", height = 0.13, studs = false, close = "grey" },
	button = { kind = "flat", studs = false, corner = UDim.new(0.3, 0), outline = false },
	card = { corner = UDim.new(0.1, 0), rays = false },
	progress = { corner = UDim.new(0.5, 0) },

	palette = {
		blue = solid("2F6BFF", "1F4FD1"),
		orange = solid("E5701F", "C25812"),
		gold = solid("F5B000", "C98F00", "3A2A00"),
		amber = solid("FFB020", "D68A00", "3A2A00"),
		green = solid("149A4F", "0E7A3D"),
		red = solid("E0352B", "B8261E"),
		purple = solid("8B5CF6", "6D3FE0"),
		pink = solid("D9337F", "B31F66"),
		grey = solid("EEF1F4", "D5DBE2", "3C4652"),
	},

	text_gradient = {
		cash = { colors = { rgb("0E8A45"), rgb("0B7339") }, stroke = rgb("FFFFFF") },
		legendary = { colors = { rgb("C2620A"), rgb("A34F06") }, stroke = rgb("FFFFFF") },
		epic = { colors = { rgb("7C3AED"), rgb("6425D0") }, stroke = rgb("FFFFFF") },
		rare = { colors = { rgb("2160E0"), rgb("1A4FC0") }, stroke = rgb("FFFFFF") },
		common = { colors = { rgb("6B7480"), rgb("525B66") }, stroke = rgb("FFFFFF") },
		gems = { colors = { rgb("D21B5C"), rgb("B0144C") }, stroke = rgb("FFFFFF") },
		item = { colors = { rgb("C2610C"), rgb("9A4A08") }, stroke = rgb("FFFFFF") },
		rainbow = { colors = { rgb("EF4444"), rgb("F59E0B"), rgb("22C55E"), rgb("3B82F6"), rgb("A855F7") }, stroke = rgb("FFFFFF"), rotation = 0 },
	},

	color = {
		text = rgb("1C2330"),
		text_dim = rgb("5E6B7A"),
		outline = rgb("FFFFFF"),
		selected = rgb("2F6BFF"),
		divider = rgb("E3E7EC"),
	},

	font = {
		title = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
		body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
	},

	stroke = { window = 0.004, card = 0.012, button = 0.03, header = 0, label = 0, title = 0 },
})
