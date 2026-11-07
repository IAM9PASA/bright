-- ui tokens, change here to restyle every ui built with bright.
-- look: "brainrot / cake" cartoon style. dark translucent navy windows, glossy studded headers,
-- chunky 3d candy buttons, heavy white text with a thick dark outline.
-- colors are free to change: keep each palette light on top, saturated at the bottom, dark outline.

local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

return {
	-- every window, card and bar sits on this
	surface = {
		color = rgb("070F18"),
		transparency = 0.5,
		stroke = rgb("05102B"),
		stroke_transparency = 0.1,
		-- inset item tiles are darker
		tile_transparency = 0.85,
	},

	-- one palette per role. base = dark rim under the face, face = light > saturated gradient,
	-- studs = the stud texture tint (more saturated than face), text = outline color for labels on it
	palette = {
		blue = { base = rgb("0059A6"), stroke = rgb("05102B"), face = { rgb("ABFFFC"), rgb("00B3FF") }, studs = { rgb("00E5FF"), rgb("008BD6") }, text = rgb("021F3D") },
		orange = { base = rgb("C9772F"), stroke = rgb("05102B"), face = { rgb("FFBF7E"), rgb("D09C6E") }, studs = { rgb("FFCCA7"), rgb("D69B70") }, text = rgb("3A1F05") },
		gold = { base = rgb("7F5307"), stroke = rgb("462E03"), face = { rgb("FFF78C"), rgb("FF8C18") }, studs = { rgb("FFFF17"), rgb("FF670F") }, text = rgb("271B03") },
		amber = { base = rgb("814E08"), stroke = rgb("261D03"), face = { rgb("FFF8A7"), rgb("FF961D") }, studs = { rgb("FFFF17"), rgb("FF670F") }, text = rgb("271B03") },
		green = { base = rgb("0E8800"), stroke = rgb("084600"), face = { rgb("D4FF00"), rgb("57FF4E") }, studs = { rgb("91FF00"), rgb("1DDA00") }, text = rgb("052700") },
		red = { base = rgb("9C0505"), stroke = rgb("5F0A0A"), face = { rgb("FF7D7D"), rgb("FF1E1E") }, studs = { rgb("FF1E1E"), rgb("CC0A0A") }, text = rgb("410101") },
		purple = { base = rgb("7A1678"), stroke = rgb("380D3E"), face = { rgb("FF89EB"), rgb("F238FF") }, studs = { rgb("FF42FC"), rgb("AF26FE") }, text = rgb("2A0530") },
		pink = { base = rgb("621964"), stroke = rgb("3D0E43"), face = { rgb("FF9BFF"), rgb("FF4AF0") }, studs = { rgb("FF4CFF"), rgb("B12BFF") }, text = rgb("2A0530") },
		grey = { base = rgb("3A4653"), stroke = rgb("1E242B"), face = { rgb("A9B6C4"), rgb("6B7B8C") }, studs = { rgb("9AA8B7"), rgb("5D6C7C") }, text = rgb("10151B") },
	},

	-- vertical text gradients, the label stays white so the gradient shows. stroke = outline to pair with
	text_gradient = {
		cash = { colors = { rgb("E5FF00"), rgb("0BE100") }, stroke = rgb("022703") },
		legendary = { colors = { rgb("FFF823"), rgb("FF8E1D") }, stroke = rgb("2A1503") },
		gems = { colors = { rgb("FF5C87"), rgb("DF0043") }, stroke = rgb("3D0012") },
		item = { colors = { rgb("E76B18"), rgb("B1861A") }, stroke = rgb("271B03") },
		epic = { colors = { rgb("E59BFF"), rgb("9B30FF") }, stroke = rgb("1F0533") },
		rare = { colors = { rgb("8FF1FF"), rgb("1E8CFF") }, stroke = rgb("021F3D") },
		common = { colors = { rgb("FFFFFF"), rgb("B8C2CC") }, stroke = rgb("10151B") },
		rainbow = { colors = { rgb("FF0000"), rgb("FFEA08"), rgb("0DFF00"), rgb("00D0FF"), rgb("F831FF") }, stroke = rgb("1A0A2A"), rotation = 60 },
	},

	color = {
		text = Color3.new(1, 1, 1),
		text_dim = rgb("B9C6D6"),
		outline = Color3.new(0, 0, 0),
		sale = rgb("FF2323"),
		notify = rgb("FF0000"),
	},

	font = {
		heavy = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
		bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	},

	-- spacing, as a share of the element's SHORT side (ui.pad turns it into per-axis scale).
	-- one step of the scale everywhere keeps gaps consistent between windows, cards and buttons
	space = {
		xs = 0.02,
		sm = 0.04,
		md = 0.06,
		lg = 0.1,
	},

	-- outline thickness as a share of the element's short side (StrokeSizingMode ScaledSize).
	-- big things need small numbers: 0.01 of a window is about as wide as 0.07 of a button.
	-- sim/ shows the real px per device and flags outlines under 1px
	stroke = {
		title = 0.12,
		label = 0.1,
		window = 0.01,
		header = 0.07,
		button = 0.07,
		card = 0.03,
	},

	asset = {
		studs = "rbxassetid://10509779001",
		sunburst = "rbxassetid://135083906498742",
		glow = "rbxassetid://85606468393354",
		icon = {
			store = "rbxassetid://114395480108146",
			inventory = "rbxassetid://73950877705674",
			upgrades = "rbxassetid://110770743970769",
			sell = "rbxassetid://96101669745081",
			cash = "rbxassetid://123304244394727",
			brainrot = "rbxassetid://116678090422340",
			lucky_block = "rbxassetid://107655551725983",
			power = "rbxassetid://97665426185670",
			time = "rbxassetid://135589380103002",
		},
	},

	-- stud texture TileSize (scale of the studded surface). keeps studs about 3 rows tall
	studs = {
		button = UDim2.fromScale(0.08, 0.325),
		square = UDim2.fromScale(0.25, 0.25),
		header = UDim2.fromScale(0.022, 0.315),
		popup_header = UDim2.fromScale(0.05, 0.315),
		card = UDim2.fromScale(0.022, 0.12),
	},

	-- window aspect ratios (width / height) from the reference panels
	window = {
		standard = 6.25 / 4.49,
		inventory = 6.99 / 4.66,
		large = 8.09 / 5.39,
		popup = 5.18 / 3.25,
	},

	-- seconds. fast = hover / press, normal = open / pop
	motion = {
		fast = 0.08,
		normal = 0.22,
	},

	-- ui.adaptive scale-up per screen: phones are physically small, so the same screen fraction is
	-- too small to read or tap. touch targets should end up near 44pt (apple hig) / 48dp (material)
	adaptive = {
		phone = 1.3,
		tablet = 1.1,
		desktop = 1,
		console = 1.15,
	},

	-- disabled controls get a dark veil, the shape stays so the layout does not jump
	disabled = {
		veil = 0.45,
	},
}
