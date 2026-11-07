-- ui tokens, change here to restyle every ui built with bright

return {
	color = {
		panel = Color3.fromRGB(13, 22, 17),
		card = Color3.fromRGB(27, 47, 36),
		card_active = Color3.fromRGB(34, 58, 44),
		card_hover = Color3.fromRGB(36, 62, 47),
		accent = Color3.fromRGB(74, 222, 128),
		-- text colors keep wcag aa contrast (4.5:1) on card and card_hover, checked in sim/
		text = Color3.fromRGB(236, 246, 240),
		text_dim = Color3.fromRGB(152, 178, 164),
		text_faint = Color3.fromRGB(134, 160, 146),
		-- text on accent fills (primary buttons), 10:1 on accent
		text_on_accent = Color3.fromRGB(10, 26, 17),
		icon = Color3.fromRGB(196, 222, 206),
		line = Color3.fromRGB(74, 222, 128),
		scrollbar = Color3.fromRGB(64, 110, 84),
	},

	-- uigradient multiplies the element color: white base shows these exactly, grey stops darken
	gradient = {
		shade = { Color3.new(1, 1, 1), Color3.fromRGB(196, 196, 196) },
		panel = { Color3.fromRGB(19, 37, 27), Color3.fromRGB(13, 22, 17), Color3.fromRGB(9, 15, 12) },
		tab = { Color3.fromRGB(46, 112, 74), Color3.fromRGB(28, 70, 46) },
		accent = { Color3.fromRGB(74, 222, 128), Color3.fromRGB(45, 212, 191) },
	},

	-- disabled controls fade to this, and keep their shape so the layout does not jump
	disabled = {
		transparency = 0.55,
	},

	-- ui.adaptive scale-up per screen: phones are physically small, so the same screen fraction is
	-- too small to read or tap. touch targets should end up near 44pt (apple hig) / 48dp (material)
	adaptive = {
		phone = 1.3,
		tablet = 1.1,
		desktop = 1,
		console = 1.15,
	},

	-- seconds. fast = hover / press, normal = open / pop
	motion = {
		fast = 0.12,
		normal = 0.22,
	},

	transparency = {
		panel = 0.04,
		line = 0.85,
	},

	font = {
		bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
		medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	},

	-- scale of the shorter side, 0.5 = fully round
	radius = {
		panel = UDim.new(0.026, 0),
		button = UDim.new(0.17, 0),
		card = UDim.new(0.085, 0),
		pill = UDim.new(0.5, 0),
	},
}
