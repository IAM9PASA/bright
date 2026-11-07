-- style: fantasy. dark wood windows with gold edges, a parchment banner title, beveled buttons
-- without studs, serif text with a soft dark outline. for rpg, adventure and simulator quests.

local extend = require(script.Parent.Parent.style).extend
local base = require(script.Parent.brainrot)

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

local function bevel(base_hex: string, edge: string, top: string, bottom: string, outline: string)
	return { base = rgb(base_hex), stroke = rgb(edge), face = { rgb(top), rgb(bottom) }, studs = { rgb(top), rgb(bottom) }, text = rgb(outline), label = rgb("FFF6DD") }
end

return extend(base, {
	name = "fantasy",
	accent = "gold",

	surface = {
		color = Color3.new(1, 1, 1),
		transparency = 0.04,
		gradient = { rgb("4A2E19"), rgb("3A2313"), rgb("2A190D") },
		stroke = rgb("C9A24B"),
		stroke_transparency = 0,
		tile_color = rgb("1C0F06"),
		tile_transparency = 0.55,
		corner = UDim.new(0.025, 0),
	},
	text = { outline = true, drop = false, upper = false },
	header = { kind = "banner", height = 0.14, studs = false, corner = UDim.new(0.12, 0), close = "red" },
	button = { kind = "candy", studs = false, corner = UDim.new(0.16, 0), outline = true },
	card = { corner = UDim.new(0.06, 0), rays = false },
	progress = { corner = UDim.new(0.3, 0) },

	palette = {
		-- dark lettering with a light rim reads as engraved gold
		gold = { base = rgb("6B4A12"), stroke = rgb("2A1A05"), face = { rgb("FBE7A1"), rgb("D9A63A") }, studs = { rgb("FBE7A1"), rgb("D9A63A") }, text = rgb("FFF3CF"), label = rgb("3A2405") },
		amber = { base = rgb("6B4A12"), stroke = rgb("2A1A05"), face = { rgb("FFE2B0"), rgb("E39A3B") }, studs = { rgb("FFE2B0"), rgb("E39A3B") }, text = rgb("FFF3CF"), label = rgb("3A2405") },
		green = bevel("1F4A1C", "0B1F09", "8CCB6A", "3E8A2E", "0B1F09"),
		red = bevel("5A1414", "200606", "E0735F", "A3312A", "200606"),
		blue = bevel("17305A", "070F20", "7EA8E8", "3463B0", "070F20"),
		purple = bevel("3A1A5A", "13072A", "B38CE8", "6B3FB0", "13072A"),
		pink = bevel("5A1A3E", "250715", "E89AC4", "B04682", "250715"),
		orange = bevel("5A3014", "251205", "F0A86A", "C46A2A", "251205"),
		grey = bevel("3B342C", "15110C", "A99C8A", "6E6252", "15110C"),
	},

	text_gradient = {
		cash = { colors = { rgb("FFF2B0"), rgb("E9B949") }, stroke = rgb("2A1A05") },
		legendary = { colors = { rgb("FFE38A"), rgb("FF9F3D") }, stroke = rgb("2A1405") },
		epic = { colors = { rgb("E7C6FF"), rgb("A86BFF") }, stroke = rgb("1A0A2A") },
		rare = { colors = { rgb("C6E2FF"), rgb("5E9BFF") }, stroke = rgb("0A1530") },
		common = { colors = { rgb("F5E6C4"), rgb("CBB68A") }, stroke = rgb("1C0F06") },
		gems = { colors = { rgb("FFC2D6"), rgb("E0476F") }, stroke = rgb("2A0512") },
		item = { colors = { rgb("F5D49A"), rgb("C98A3B") }, stroke = rgb("1C0F06") },
		rainbow = { colors = { rgb("FF8A6B"), rgb("FFE38A"), rgb("9FE07A"), rgb("7AB8FF"), rgb("D08AFF") }, stroke = rgb("1C0F06"), rotation = 60 },
	},

	color = {
		text = rgb("F7E9C8"),
		text_dim = rgb("CDB88E"),
		outline = rgb("1A0E05"),
		selected = rgb("FFD45C"),
		divider = rgb("C9A24B"),
	},

	font = {
		title = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Black),
		body = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold),
	},

	stroke = { window = 0.008, card = 0.02, button = 0.05, header = 0.05, label = 0.07, title = 0.08 },
})
