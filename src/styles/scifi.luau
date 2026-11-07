-- style: sci-fi. dark navy, cyan lines, square corners with bracket marks, outline buttons,
-- uppercase wide text. for shooters, space and tech games.

local extend = require(script.Parent.Parent.style).extend
local base = require(script.Parent.brainrot)

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

local function line(bright: string, deep: string)
	return { base = rgb(deep), stroke = rgb(bright), face = { rgb(bright), rgb(bright) }, studs = { rgb(bright), rgb(bright) }, text = rgb("020812"), label = rgb(bright) }
end

return extend(base, {
	name = "scifi",
	accent = "blue",

	surface = {
		color = Color3.new(1, 1, 1),
		transparency = 0.08,
		gradient = { rgb("0E1B2E"), rgb("08111E"), rgb("050A13") },
		stroke = rgb("22D3EE"),
		stroke_transparency = 0.45,
		tile_color = rgb("22D3EE"),
		tile_transparency = 0.93,
		corner = UDim.new(0, 0),
		brackets = rgb("22D3EE"),
	},
	text = { outline = false, drop = false, upper = true },
	header = { kind = "plain", height = 0.13, studs = false, close = "red" },
	button = { kind = "outline", studs = false, corner = UDim.new(0, 0), outline = false },
	card = { corner = UDim.new(0, 0), rays = false },
	progress = { corner = UDim.new(0, 0) },

	palette = {
		blue = line("5CE1FF", "0B3A55"),
		green = line("5CFFB0", "0B4A33"),
		red = line("FF6B7A", "4A0B16"),
		orange = line("FFB05C", "4A2A0B"),
		gold = line("FFE45C", "4A400B"),
		amber = line("FFC85C", "4A350B"),
		purple = line("B88CFF", "2A1150"),
		pink = line("FF7AD9", "4A0B3A"),
		grey = line("7F95A8", "1A2533"),
	},

	text_gradient = {
		cash = { colors = { rgb("9CFFD0"), rgb("3DFFA0") }, stroke = rgb("020812") },
		legendary = { colors = { rgb("FFF09C"), rgb("FFC53D") }, stroke = rgb("020812") },
		epic = { colors = { rgb("D9C2FF"), rgb("A178FF") }, stroke = rgb("020812") },
		rare = { colors = { rgb("B5F3FF"), rgb("40D7FF") }, stroke = rgb("020812") },
		common = { colors = { rgb("E0F2FA"), rgb("9FB8C6") }, stroke = rgb("020812") },
		gems = { colors = { rgb("FFB5DF"), rgb("FF5CB8") }, stroke = rgb("020812") },
		item = { colors = { rgb("FFD3A0"), rgb("FFA64D") }, stroke = rgb("020812") },
		rainbow = { colors = { rgb("FF6B7A"), rgb("FFE45C"), rgb("5CFFB0"), rgb("5CE1FF"), rgb("B88CFF") }, stroke = rgb("020812"), rotation = 0 },
	},

	color = {
		text = rgb("E3F8FF"),
		text_dim = rgb("86A9BA"),
		outline = rgb("020812"),
		selected = rgb("5CE1FF"),
		divider = rgb("22D3EE"),
	},

	font = {
		title = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular),
		body = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Medium),
	},

	stroke = { window = 0.003, card = 0.01, button = 0.035, header = 0, label = 0, title = 0 },
})
