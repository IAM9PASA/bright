-- bright: vide building blocks for any ui style. every function takes a vide props table (children go
-- in the array part) and returns an instance. extra keys like palette / align are read and removed before
-- create. everything is scale: no px offsets, no text size px limits (RULES.md).
--
-- STYLES
-- local ui = require(Packages.bright)                 default style (theme.luau, brainrot)
-- local ui = require(Packages.bright).with(ui.styles.glass)   any style, several can live side by side
-- ui.styles.brainrot | clean | glass | scifi | fantasy | pastel
-- ui.extend(base, { surface = { corner = UDim.new(0.1, 0) } })   make your own style from another one
--
-- WINDOWS
-- ui.window { title, icon, palette, shape = "standard" | "inventory" | "large" | "popup", close, open }
--   open = source(bool) wraps the window in ui.presence (spring scale + fade in and out)
-- ui.presence { open, scale_from = 0.9, fade = true }   open / close transition for any children
-- ui.header { title, icon, palette, close }  the header alone (bar / plain / banner, from the style)
-- ui.card { tile = false, selected }         surface card, tile = inset
-- ui.panel                                    plain surface with the window outline
--
-- TEXT
-- ui.text "hi" / ui.text { style, align, stroke }   label in the style's body font
--   style = nil | "dim" | "cash" | "legendary" | "epic" | "rare" | "common" | "gems" | "item" | "rainbow"
-- ui.title { Text, align, stroke, style }    title font (+ drop edge when the style has one)
-- ui.counter { value, format, style, time }  number that rolls to its new value (source(number))
--
-- CONTROLS
-- ui.button { text, image, palette, amount, disabled, locked }   candy / flat / outline / glow, from the style
--   disabled = grey + no input: the action does not apply right now (maxed, already claimed)
--   locked   = grey but clickable: shakes and skips Activated (can't afford, needs a level). bool or source
-- ui.close_button {} / ui.icon_button { image, palette }
-- ui.tab { text, active, palette }           palette when active, grey when not (active = bool or source)
-- ui.input { PlaceholderText }               inset textbox
-- ui.toggle { on }                           on/off switch, on = bool or vide source (click flips a source)
-- ui.hud_button { text, image, notify }     square side button with caption
-- ui.hud_column { side = "left", cell = 0.28, gap = 0.03 }   screen-edge column the hud buttons stack in
-- ui.hit { hover = true, ... }                invisible full-size "button", hover pops the parent
--
-- CONTENT
-- ui.item_card { name, image, value, rarity, sunburst, selected }
-- ui.sunburst { ImageColor3 } / ui.studs(tile, colors) / ui.progress { value, text } / ui.icon { Image }
-- ui.hex { color }                           pointy-top hexagon (3 rotated bands, or theme.asset.hex image)
-- ui.hex_stack(palette, props?)              border + rim + raised face hex, palette = name or source of one
-- ui.hex_grid { radius, cell = function(q, r) -> Instance, gap = 0.94 }   axial hex grid
--
-- LAYOUT
-- ui.box / ui.row / ui.column { gap = 0.02, align = "center", cross = "center", fill = true }
-- ui.list_layout { direction, gap, align, cross, fill }
-- ui.scroll_grid { columns = 4, ratio = 1, gap_x, gap_y } / ui.scroll_list { gap }
-- ui.square(ratio?) / ui.ratio(w / h) / ui.padding(x, y?) / ui.pad(space, aspect?)
-- ui.gradient(colors, rotation?) / ui.sequence(colors)
--
-- SCREEN + RULES
-- ui.device() / ui.adaptive(scales?) / ui.pop(gui, from?) / ui.pop_on(gui, property, from?, watch?)
-- ui.lint(root)                               list sizing-rule breaks, see RULES.md
-- ui.motion.loop / bob / spin / pause / tween / pop / shake   idle loops and feedback (src/motion.luau)

-- SERVICES -------------------------

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


-- MODULES -------------------------

local vide = require(script.Parent.vide)
local lint = require(script.lint)
local motion = require(script.motion)
local style = require(script.style)


-- VARIABLES -------------------------

local create = vide.create

-- styles load on first use, so one broken style only breaks the code that picks it
local styles = setmetatable({}, {
	__index = function(self, name)
		local module = script.styles:FindFirstChild(name)
		if not module then return nil end
		local loaded = require(module)
		rawset(self, name, loaded)
		return loaded
	end,
})

local alignments = {
	start = { Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top },
	center = { Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center },
	["end"] = { Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom },
}

local text_alignments = {
	left = Enum.TextXAlignment.Left,
	center = Enum.TextXAlignment.Center,
	right = Enum.TextXAlignment.Right,
}

-- UIScales bright uses for animation (lint ignores these names)
local PRESS_SCALE, POP_SCALE = "press_scale", "pop_scale"


-- FUNCTIONS -------------------------

local function defaults(props, values)
	for key, value in values do
		if props[key] == nil then
			props[key] = value
		end
	end
	return props
end

local function take(props, key)
	local value = props[key]
	props[key] = nil
	return value
end

local function to_udim(gap)
	if typeof(gap) == "UDim" then return gap end
	return UDim.new(gap or 0, 0)
end

local function sequence(colors: { Color3 }): ColorSequence
	-- one color has no span to spread over
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keypoints = {}
	for i, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keypoints)
end

-- a bool or a vide source picks between two values
local function pick(flag, on, off)
	if type(flag) == "function" then
		return function()
			return if flag() then on else off
		end
	end
	return if flag then on else off
end

-- a value or a vide source of one, passed through a function
local function map(value, fn)
	if type(value) == "function" then
		return function() return fn(value()) end
	end
	return fn(value)
end

local function read(value)
	if type(value) == "function" then return value() end
	return value
end

local function center(size: UDim2, y: number?)
	return { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y or 0.5), Size = size }
end

-- build the whole api for one style
local function build(theme)
	local ui = {}
	ui.theme = theme
	ui.styles = styles
	ui.extend = style.extend
	ui.lint = lint
	ui.motion = motion
	ui.sequence = sequence
	ui.with = build

	local fast_tween = TweenInfo.new(theme.motion.fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	-- back out overshoots a little, reads as a "pop"
	local pop_tween = TweenInfo.new(theme.motion.normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local function get_palette(name)
		return theme.palette[name] or theme.palette[theme.accent] or theme.palette.blue
	end

	-- palette can be a name or a vide source of a name, so tabs / disabled buttons recolor without a rebuild
	local function from_palette(source, getter)
		if type(source) == "function" then
			return function()
				return getter(get_palette(source()))
			end
		end
		return getter(get_palette(source))
	end

	local function label_color(p)
		return p.label or theme.color.text
	end

	-- outlines are scaled so they grow with the element
	local function stroke(color, thickness: number, transparency: number?, contextual: boolean?)
		return create "UIStroke" {
			Color = color,
			Thickness = thickness,
			Transparency = transparency or 0,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			ApplyStrokeMode = if contextual then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		}
	end

	local function corner(radius: UDim?)
		if not radius or (radius.Scale == 0 and radius.Offset == 0) then return nil end
		return create "UICorner" { CornerRadius = radius }
	end

	-- text outline only when the style uses outlines
	local function text_stroke(color, thickness)
		if not theme.text.outline or thickness <= 0 then return nil end
		return stroke(color, thickness, 0, true)
	end

	local function cased(text)
		if not theme.text.upper or text == nil then return text end
		return map(text, function(value) return string.upper(tostring(value)) end)
	end

	-- a soft ring outside the element: glow on glass / neon styles
	-- color can be a vide source
	local function halo(color, transparency: number, thickness: number, radius: UDim?)
		return create "Frame" {
			Name = "Glow",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			corner(radius),
			stroke(color, thickness, transparency),
		}
	end

	-- sci-fi corner marks: an L in each corner, just outside the edge
	local function brackets(color: Color3)
		local marks = {}
		for _, spot in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
			local x, y = spot[1], spot[2]
			table.insert(marks, create "Frame" {
				Name = "Bracket",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(x, y),
				Position = UDim2.fromScale(x + (x * 2 - 1) * 0.006, y + (y * 2 - 1) * 0.009),
				Size = UDim2.fromScale(0.07, 0.07),
				ZIndex = 6,
				create "UIAspectRatioConstraint" { AspectRatio = 1 },
				create "Frame" { Name = "H", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(x, y), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(1, 0.12) },
				create "Frame" { Name = "V", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(x, y), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(0.12, 1) },
			})
		end
		return marks
	end

	function ui.gradient(colors: { Color3 }, rotation: number?)
		return create "UIGradient" { Color = sequence(colors), Rotation = rotation or 90 }
	end

	function ui.square(ratio: number?)
		return create "UIAspectRatioConstraint" { AspectRatio = ratio or 1 }
	end

	-- height from width only. inside a scrolling frame Y scale follows the growing canvas, so rows use this
	function ui.ratio(ratio: number)
		return create "UIAspectRatioConstraint" {
			AspectRatio = ratio,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Width,
		}
	end

	-- scale of the parent on each axis, so give y separately for wide boxes
	function ui.padding(x: number, y: number?)
		local pad_x, pad_y = UDim.new(x, 0), UDim.new(y or x, 0)
		return create "UIPadding" { PaddingLeft = pad_x, PaddingRight = pad_x, PaddingTop = pad_y, PaddingBottom = pad_y }
	end

	-- UIPadding scale is per axis, so ui.padding(0.05) on a 2:1 frame pads the sides twice as wide as the
	-- top. ui.pad measures from the short side instead: same px on all four sides at any screen size
	function ui.pad(space: string | number, aspect: number?)
		local amount = if type(space) == "string" then theme.space[space] else space
		assert(type(amount) == "number", `ui.pad: unknown space {space}`)
		local ratio = aspect or 1
		if ratio >= 1 then
			return ui.padding(amount / ratio, amount)
		end
		return ui.padding(amount, amount * ratio)
	end

	function ui.box(props)
		defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
		return create "Frame" (props)
	end

	function ui.icon(props)
		defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
		table.insert(props, ui.square())
		return create "ImageLabel" (props)
	end

	-- the stud texture. under a gradient it reads as raised studs in the surface color.
	-- colors = ColorSequence or a vide source of one
	function ui.studs(tile: UDim2?, colors, size: UDim2?, z: number?)
		return create "ImageLabel" {
			Name = "Layout",
			Image = theme.asset.studs,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = tile or theme.studs.button,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = z or 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size or UDim2.fromScale(0.97, 0.885),
			create "UIGradient" { Rotation = 90, Color = colors },
		}
	end

	-- TEXT -------------------------

	local function text_style(name)
		if name == nil or name == "dim" then
			return nil
		end
		return theme.text_gradient[name]
	end

	function ui.text(props)
		if type(props) == "string" then
			props = { Text = props }
		end

		local name = take(props, "style")
		local align = take(props, "align")
		local outline = take(props, "stroke")
		local gradient = text_style(name)

		props.Text = cased(props.Text)
		defaults(props, {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextScaled = true,
			FontFace = theme.font.body,
			TextColor3 = if name == "dim" then theme.color.text_dim elseif gradient then Color3.new(1, 1, 1) else theme.color.text,
			TextXAlignment = text_alignments[align or "center"],
		})
		table.insert(props, text_stroke(outline or (gradient and gradient.stroke) or theme.color.outline, theme.stroke.label))
		if gradient then
			table.insert(props, ui.gradient(gradient.colors, gradient.rotation))
		end
		return create "TextLabel" (props)
	end

	-- title font. styles with a drop edge put a dark copy a little lower
	function ui.title(props)
		local text = cased(take(props, "Text"))
		local align = take(props, "align") or "left"
		local outline = take(props, "stroke") or theme.color.outline
		local color = take(props, "color")
		local gradient = text_style(take(props, "style"))

		defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
		table.insert(props, create "TextLabel" {
			Name = "TitleUp",
			Text = text,
			ZIndex = 3,
			BackgroundTransparency = 1,
			TextScaled = true,
			FontFace = theme.font.title,
			TextColor3 = color or (if gradient then Color3.new(1, 1, 1) else theme.color.text),
			TextXAlignment = text_alignments[align],
			Size = UDim2.fromScale(1, 1),
			text_stroke(outline, theme.stroke.title),
			gradient and ui.gradient(gradient.colors, gradient.rotation) or nil,
		})
		if theme.text.drop then
			table.insert(props, create "TextLabel" {
				Name = "TitleDown",
				Text = text,
				ZIndex = 2,
				BackgroundTransparency = 1,
				TextScaled = true,
				FontFace = theme.font.title,
				TextColor3 = outline,
				TextXAlignment = text_alignments[align],
				Position = UDim2.fromScale(0, 0.08),
				Size = UDim2.fromScale(1, 1),
				text_stroke(outline, theme.stroke.title),
			})
		end
		return create "Frame" (props)
	end

	-- 1234567 -> "1,234,567"
	local function thousands(n: number): string
		local whole = tostring(math.round(n))
		local sign, digits = whole:match("^(%-?)(%d+)$")
		local grouped = (digits :: string):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		return (sign or "") .. grouped
	end
	ui.thousands = thousands

	-- rolls instead of jumping: a NumberValue tweens to each new value (quart out) and the label follows
	function ui.counter(props)
		local value = take(props, "value")
		local format = take(props, "format") or thousands
		local time = take(props, "time") or 0.6
		assert(type(value) == "function", "ui.counter: value must be a vide source")

		local shown = Instance.new("NumberValue")
		shown.Value = value()
		props.Text = format(shown.Value)
		local label = ui.text(props)
		shown.Parent = label

		shown:GetPropertyChangedSignal("Value"):Connect(function()
			label.Text = cased(format(shown.Value)) :: any
		end)
		local tween_info = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		vide.effect(function()
			local target = value()
			if target ~= shown.Value then
				TweenService:Create(shown, tween_info, { Value = target }):Play()
			end
		end)
		return label
	end

	-- MOTION -------------------------

	local function scale_of(target: GuiObject, name: string): UIScale
		local scale = target:FindFirstChild(name) :: UIScale?
		if not scale then
			scale = create "UIScale" { Name = name, Parent = target }
		end
		return scale :: UIScale
	end

	function ui.pop(target: GuiObject, from: number?)
		local scale = scale_of(target, POP_SCALE)
		scale.Scale = from or 0.9
		TweenService:Create(scale, pop_tween, { Scale = 1 }):Play()
	end

	function ui.pop_on(target: GuiObject, property: string, from: number?, watch: Instance?)
		local source = watch or target
		source:GetPropertyChangedSignal(property):Connect(function()
			local value = (source :: any)[property]
			if value == false or value == "" then return end
			ui.pop(target, from)
		end)
	end

	-- hover grows, press squashes (and pushes a candy face into its rim).
	-- target = what scales, nil = the button's parent at event time (ui.hit)
	local function bind_press(button: GuiButton, target: GuiObject?, face: GuiObject?, label: GuiObject?)
		local function scale_to(value)
			local frame = target or button.Parent :: GuiObject
			TweenService:Create(scale_of(frame, PRESS_SCALE), fast_tween, { Scale = value }):Play()
		end
		local function push(down)
			if face then
				TweenService:Create(face, fast_tween, { Position = UDim2.fromScale(0.5, if down then 0.5 else 0.465) }):Play()
			end
			if label then
				TweenService:Create(label, fast_tween, { Position = UDim2.fromScale(0.5, if down then 0.5 else 0.467) }):Play()
			end
		end

		button.MouseEnter:Connect(function() scale_to(1.05) end)
		button.MouseLeave:Connect(function()
			scale_to(1)
			push(false)
		end)
		button.MouseButton1Down:Connect(function()
			scale_to(0.95)
			push(true)
		end)
		button.MouseButton1Up:Connect(function()
			scale_to(1.05)
			push(false)
		end)
		-- touch never fires MouseLeave, so reset when the finger lifts
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			scale_to(1)
			push(false)
		end)
	end

	-- gamepad / keyboard focus ring. roblox clones SelectionImageObject over the selected button
	local selection_ring = create "Frame" {
		Name = "selection_ring",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		corner(theme.button.corner),
		stroke(theme.color.selected, 0.06),
	}

	-- WINDOWS -------------------------

	function ui.card(props)
		local tile = take(props, "tile")
		local selected = take(props, "selected")
		defaults(props, {
			BackgroundColor3 = if tile then theme.surface.tile_color else theme.surface.color,
			BackgroundTransparency = if tile then theme.surface.tile_transparency else theme.surface.transparency,
			BorderSizePixel = 0,
		})
		if not tile and theme.surface.gradient then
			table.insert(props, ui.gradient(theme.surface.gradient))
		end
		table.insert(props, corner(theme.card.corner))
		table.insert(props, create "UIStroke" {
			Color = pick(selected, theme.color.selected, theme.surface.stroke),
			Thickness = pick(selected, math.max(theme.stroke.card * 2, 0.02), theme.stroke.card),
			Transparency = pick(selected, 0, if tile then math.max(theme.surface.stroke_transparency, 0.5) else theme.surface.stroke_transparency),
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		})
		return create "Frame" (props)
	end

	function ui.panel(props)
		defaults(props, {
			BackgroundColor3 = theme.surface.color,
			BackgroundTransparency = theme.surface.transparency,
			BorderSizePixel = 0,
		})
		if theme.surface.gradient then
			table.insert(props, ui.gradient(theme.surface.gradient))
		end
		table.insert(props, corner(theme.surface.corner))
		table.insert(props, stroke(theme.surface.stroke, theme.stroke.window, theme.surface.stroke_transparency))
		return create "Frame" (props)
	end

	-- CONTROLS -------------------------

	-- one api, four looks: candy (rim + glossy face), flat (one fill), outline (see-through + edge),
	-- glow (flat + halo). palette and disabled can be vide sources
	function ui.button(props)
		local text = cased(take(props, "text"))
		local amount = take(props, "amount")
		local disabled = take(props, "disabled")
		local locked = take(props, "locked")
		local studs = take(props, "studs") or theme.studs.button
		local image = take(props, "image")
		local palette = take(props, "palette") or theme.accent
		local kind = theme.button.kind

		-- disabled buttons turn grey and stop taking input
		local effective = palette
		if disabled ~= nil or locked ~= nil then
			effective = function()
				if read(disabled) or read(locked) then return "grey" end
				return read(palette)
			end
		end

		-- locked buttons still take the click so the player gets a "no" instead of nothing
		local button
		if locked ~= nil then
			local on_activated = take(props, "Activated")
			props.Activated = function(...)
				if read(locked) then
					motion.shake(button)
					return
				end
				if on_activated then on_activated(...) end
			end
		end
		local function paint(getter)
			return from_palette(effective, getter)
		end

		defaults(props, {
			Size = UDim2.fromScale(0.25, 0.1),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			SelectionImageObject = selection_ring,
			Interactable = if disabled == nil then true else pick(disabled, false, true),
		})

		local face
		if kind == "candy" then
			props.BackgroundColor3 = props.BackgroundColor3 or paint(function(p) return p.base end)
			face = create "Frame" {
				Name = "Color",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.465),
				Size = UDim2.fromScale(1, 0.91),
				corner(theme.button.corner),
				create "UIGradient" { Rotation = 90, Color = paint(function(p) return sequence(p.face) end) },
				if theme.button.studs then ui.studs(studs, paint(function(p) return sequence(p.studs) end)) else nil,
			}
			table.insert(props, face)
		elseif kind == "outline" then
			props.BackgroundColor3 = props.BackgroundColor3 or paint(function(p) return p.base end)
			props.BackgroundTransparency = 0.55
		else -- flat / glow
			props.BackgroundColor3 = props.BackgroundColor3 or Color3.new(1, 1, 1)
			table.insert(props, create "UIGradient" { Rotation = 90, Color = paint(function(p) return sequence(p.face) end) })
		end

		table.insert(props, corner(theme.button.corner))
		-- Border mode matters: on a TextButton the default (Contextual) outlines the empty text, not the button
		table.insert(props, create "UIStroke" {
			Color = paint(function(p) return p.stroke end),
			Thickness = theme.stroke.button,
			Transparency = if kind == "flat" then 0.4 else 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			LineJoinMode = Enum.LineJoinMode.Round,
		})
		if kind == "glow" then
			table.insert(props, halo(paint(function(p) return p.face[2] end), 0.75, 0.16, theme.button.corner))
		end

		local label
		if image then
			label = ui.icon(defaults(center(UDim2.fromScale(0.7, 0.7), if face then 0.467 else 0.5), { Name = "Icon", Image = image, ZIndex = 2 }))
		else
			label = create "TextLabel" {
				Name = "Title",
				Text = text,
				ZIndex = 2,
				BackgroundTransparency = 1,
				TextScaled = true,
				FontFace = theme.font.title,
				TextColor3 = paint(label_color),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, if face then 0.467 else 0.5),
				Size = UDim2.fromScale(0.84, if face then 0.6 else 0.52),
				if theme.button.outline then stroke(paint(function(p) return p.text end), theme.stroke.title, 0, true) else nil,
			}
		end
		table.insert(props, label)

		if amount then
			table.insert(props, ui.text {
				Name = "Amount",
				Text = amount,
				ZIndex = 3,
				align = "left",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.04, 0.05),
				Size = UDim2.fromScale(0.35, 0.36),
			})
		end

		button = create "TextButton" (props)
		bind_press(button, button, face, if face then label else nil)
		return button
	end

	function ui.close_button(props)
		props = props or {}
		defaults(props, { Name = "Close", text = "X", palette = theme.header.close, studs = theme.studs.square })
		table.insert(props, ui.square())
		return ui.button(props)
	end

	function ui.icon_button(props)
		defaults(props, { palette = theme.accent, studs = theme.studs.square, Size = UDim2.fromScale(1, 1) })
		table.insert(props, ui.square())
		return ui.button(props)
	end

	-- active tab keeps its palette, the others go grey. active can be a bool or a vide source
	function ui.tab(props)
		local active = take(props, "active")
		local palette = take(props, "palette") or theme.accent
		props.palette = pick(active, palette, "grey")
		return ui.button(props)
	end

	function ui.input(props)
		defaults(props, {
			BackgroundColor3 = theme.surface.tile_color,
			BackgroundTransparency = math.max(theme.surface.tile_transparency - 0.1, 0),
			BorderSizePixel = 0,
			TextScaled = true,
			FontFace = theme.font.body,
			TextColor3 = theme.color.text,
			PlaceholderColor3 = theme.color.text_dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Text = "",
		})
		table.insert(props, corner(theme.button.corner))
		table.insert(props, create "UIStroke" {
			Color = theme.surface.stroke,
			Thickness = math.max(theme.stroke.card * 2, 0.02),
			Transparency = theme.surface.stroke_transparency,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
		-- text padding inside the box keeps the whole box tappable
		table.insert(props, ui.padding(0.05, 0.22))
		return create "TextBox" (props)
	end

	-- track with a knob that slides right and turns green when on
	function ui.toggle(props)
		local on = take(props, "on")
		local is_on = function() return read(on) end

		defaults(props, {
			Size = UDim2.fromScale(0.3, 0.12),
			BackgroundColor3 = theme.surface.tile_color,
			BackgroundTransparency = math.min(theme.surface.tile_transparency, 0.45),
			BorderSizePixel = 0,
		})
		table.insert(props, corner(theme.button.corner))
		table.insert(props, stroke(theme.surface.stroke, 0.08, theme.surface.stroke_transparency))
		table.insert(props, ui.button {
			Name = "Bool",
			text = function() return if is_on() then "ON" else "OFF" end,
			palette = function() return if is_on() then "green" else "red" end,
			studs = theme.studs.square,
			AnchorPoint = function() return Vector2.new(if is_on() then 1 else 0, 0.5) end,
			Position = function() return UDim2.fromScale(if is_on() then 1 else 0, 0.5) end,
			Size = UDim2.fromScale(0.55, 1.1),
			Activated = function()
				if type(on) == "function" then on(not on()) end
			end,
		})
		return create "Frame" (props)
	end

	-- invisible full-size button. hover = true pops the parent
	function ui.hit(props)
		props = props or {}
		local hover = take(props, "hover")
		defaults(props, {
			Name = "button",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = 5,
			SelectionImageObject = selection_ring,
		})
		local button = create "ImageButton" (props)
		if hover then
			bind_press(button, nil, nil, nil)
		end
		return button
	end

	-- square side button with an icon and a caption
	function ui.hud_button(props)
		local text = take(props, "text")
		local image = take(props, "image")
		local notify = take(props, "notify")

		defaults(props, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.surface.color,
			BackgroundTransparency = theme.surface.transparency,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			SelectionImageObject = selection_ring,
		})
		if theme.surface.gradient then
			table.insert(props, ui.gradient(theme.surface.gradient))
		end
		table.insert(props, ui.square())
		table.insert(props, corner(if theme.card.corner.Scale > 0 then theme.card.corner else UDim.new(0.015, 0)))
		table.insert(props, stroke(theme.surface.stroke, math.max(theme.stroke.card, 0.02), theme.surface.stroke_transparency))
		table.insert(props, ui.icon(defaults(center(UDim2.fromScale(0.68, 0.68), 0.42), { Name = "Icon", Image = image, ZIndex = 2 })))
		table.insert(props, ui.title {
			Name = "Caption",
			Text = text,
			align = "center",
			ZIndex = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.82),
			Size = UDim2.fromScale(0.9, 0.24),
		})
		if notify ~= nil then
			local red = get_palette("red")
			table.insert(props, create "Frame" {
				Name = "Info",
				Visible = pick(notify, true, false),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 4,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.9, 0.1),
				Size = UDim2.fromScale(0.28, 0.28),
				create "UICorner" { CornerRadius = UDim.new(0.5, 0) },
				ui.gradient(red.face),
				stroke(red.stroke, 0.12),
				create "TextLabel" {
					Name = "Mark", Text = "!", ZIndex = 5, BackgroundTransparency = 1, TextScaled = true, FontFace = theme.font.title,
					TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.75, 0.75),
					stroke(red.text, 0.14, 0, true),
				},
			})
		end
		local button = create "TextButton" (props)
		bind_press(button, button, nil, nil)
		return button
	end

	-- left (or right) screen edge, centered vertically. each button child gets an even share of the
	-- height (cell) and stacks by LayoutOrder, so side buttons line up on every screen
	function ui.hud_column(props)
		local side = take(props, "side") or "left"
		local cell = take(props, "cell") or 0.28
		local gap = take(props, "gap") or 0.03
		local right = side == "right"

		for key, child in props do
			if type(key) == "number" and typeof(child) == "Instance" and child:IsA("GuiObject") then
				child.Size = UDim2.fromScale(1, cell)
			end
		end
		defaults(props, {
			Name = "Hud",
			AnchorPoint = Vector2.new(if right then 1 else 0, 0.5),
			Position = UDim2.fromScale(if right then 0.988 else 0.012, 0.5),
			Size = UDim2.fromScale(0.07, 0.56),
		})
		table.insert(props, ui.list_layout { direction = "column", gap = gap, align = "center", cross = "center" })
		return ui.box(props)
	end

	-- HEADER -------------------------

	local function close_for(close, position: UDim2, size: UDim2)
		if not close then return nil end
		return ui.close_button {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = size,
			ZIndex = 4,
			Activated = if type(close) == "function" then close else nil,
		}
	end

	-- the top of every window, three kinds from the style:
	-- bar = colored (studded) bar across the top, plain = icon + title + divider, banner = ribbon in the middle
	function ui.header(props)
		local title = take(props, "title")
		local icon = take(props, "icon")
		local palette = get_palette(take(props, "palette"))
		local close = take(props, "close")
		local tile = take(props, "studs") or theme.studs.header
		local kind = theme.header.kind

		defaults(props, {
			Name = "Top",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, theme.header.height / 2),
			Size = UDim2.fromScale(1, theme.header.height),
			ZIndex = 2,
		})

		if kind == "plain" then
			props.BackgroundTransparency = 1
			table.insert(props, icon and ui.icon {
				Name = "Icon", Image = icon, ZIndex = 3,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.055, 0.5), Size = UDim2.fromScale(0.07, 0.62),
			} or nil)
			table.insert(props, ui.title {
				Name = "Title",
				Text = title,
				stroke = palette.text,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(if icon then 0.105 else 0.04, 0.5),
				Size = UDim2.fromScale(0.6, 0.5),
			})
			table.insert(props, create "Frame" {
				Name = "Divider",
				BackgroundColor3 = theme.color.divider,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(0.94, 0.025),
			})
			table.insert(props, close_for(close, UDim2.fromScale(0.95, 0.5), UDim2.fromScale(0.06, 0.6)))
		elseif kind == "banner" then
			props.BackgroundTransparency = 1
			table.insert(props, create "Frame" {
				Name = "Banner",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.42),
				Size = UDim2.fromScale(0.5, 0.86),
				ZIndex = 3,
				corner(theme.header.corner),
				ui.gradient(palette.face),
				stroke(palette.stroke, theme.stroke.header),
				icon and ui.icon {
					Name = "Icon", Image = icon, ZIndex = 4,
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.0, 0.5), Size = UDim2.fromScale(0.3, 1.3),
				} or nil,
				ui.title {
					Name = "Title",
					Text = title,
					align = "center",
					color = label_color(palette),
					stroke = palette.text,
					ZIndex = 4,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.78, 0.58),
				},
			})
			table.insert(props, close_for(close, UDim2.fromScale(0.955, 0.5), UDim2.fromScale(0.062, 0.62)))
		else -- bar
			props.BackgroundColor3 = palette.base
			table.insert(props, corner(theme.header.corner))
			table.insert(props, stroke(palette.stroke, theme.stroke.header))
			table.insert(props, create "Frame" {
				Name = "Main",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.454),
				Size = UDim2.fromScale(1, 0.908),
				corner(theme.header.corner),
				ui.gradient(palette.face),
				if theme.header.studs then ui.studs(tile, sequence(palette.studs), UDim2.fromScale(0.99, 0.91)) else nil,
				icon and ui.icon {
					Name = "Icon",
					Image = icon,
					ZIndex = 4,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.068, 0.5),
					Size = UDim2.fromScale(0.11, 1.256),
				} or nil,
				ui.title {
					Name = "Title",
					Text = title,
					color = label_color(palette),
					stroke = palette.text,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(if icon then 0.351 else 0.27, 0.463),
					Size = UDim2.fromScale(0.436, 0.75),
				},
				close_for(close, UDim2.fromScale(0.955, 0.512), UDim2.fromScale(0.066, 0.82)),
			})
		end
		return create "Frame" (props)
	end

	-- open / close transition. a spring drives one UIScale on the outer frame; children fade inside a
	-- CanvasGroup only while moving, then sit in a plain frame so idle animations don't re-render the
	-- canvas texture every frame. closed = invisible = no input, no cost
	function ui.presence(props)
		local open = take(props, "open")
		local scale_from = take(props, "scale_from") or 0.9
		local fade = take(props, "fade")
		if fade == nil then fade = true end
		assert(type(open) == "function", "ui.presence: open must be a vide source")

		local progress = vide.spring(function() return if open() then 1 else 0 end, 0.3, 0.75)

		-- everything in the array part becomes content
		local children = {}
		for key, value in props do
			if type(key) == "number" then
				children[key] = value
				props[key] = nil
			end
		end

		local content = create "Frame" { Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), children }
		local canvas = create "CanvasGroup" {
			Name = "Fade",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = function() return 1 - math.clamp(progress(), 0, 1) end,
		}
		local still = create "Frame" { Name = "Still", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }

		vide.effect(function()
			local settled = open() and math.abs(progress() - 1) < 0.003
			local home = if settled or not fade then still else canvas
			if content.Parent ~= home then content.Parent = home end
		end)

		defaults(props, {
			Name = "Presence",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = function() return open() or progress() > 0.01 end,
		})
		table.insert(props, create "UIScale" {
			Name = "presence_scale",
			Scale = function() return scale_from + (1 - scale_from) * progress() end,
		})
		table.insert(props, canvas)
		table.insert(props, still)
		local frame = create "Frame" (props)

		-- idle loops under a closed presence stop running
		local was_closed
		vide.effect(function()
			local closed = not open() and progress() <= 0.01
			if closed ~= was_closed then
				was_closed = closed
				motion.pause(frame, closed)
			end
		end)
		return frame
	end

	-- shape picks the reference window proportions, the window keeps them on every screen
	function ui.window(props)
		local open = take(props, "open")
		if open ~= nil then
			-- the presence takes the window's place and box, the window fills it
			local outer = {
				open = open,
				Name = take(props, "Name") or "Window",
				AnchorPoint = take(props, "AnchorPoint") or Vector2.new(0.5, 0.5),
				Position = take(props, "Position") or UDim2.fromScale(0.5, 0.5),
				Size = take(props, "Size") or UDim2.fromScale(0.6, 0.7),
				ZIndex = take(props, "ZIndex"),
				LayoutOrder = take(props, "LayoutOrder"),
				Parent = take(props, "Parent"),
			}
			props.Name = "Window"
			props.Size = UDim2.fromScale(1, 1)
			table.insert(outer, ui.window(props))
			return ui.presence(outer)
		end
		local title = take(props, "title")
		local icon = take(props, "icon")
		local palette = take(props, "palette") or theme.accent
		local close = take(props, "close")
		local shape = take(props, "shape") or "standard"

		defaults(props, {
			BackgroundColor3 = theme.surface.color,
			BackgroundTransparency = theme.surface.transparency,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.6, 0.7),
		})
		if theme.surface.gradient then
			table.insert(props, ui.gradient(theme.surface.gradient))
		end
		table.insert(props, corner(theme.surface.corner))
		table.insert(props, stroke(theme.surface.stroke, theme.stroke.window, theme.surface.stroke_transparency))
		local glow = theme.surface.glow
		if glow then
			table.insert(props, halo(glow.color, glow.transparency, glow.thickness, theme.surface.corner))
		end
		if theme.surface.brackets then
			for _, mark in brackets(theme.surface.brackets) do
				table.insert(props, mark)
			end
		end

		local aspect = theme.window[shape] or theme.window.standard
		local header_height = theme.header.height * (if shape == "popup" then 1.35 else 1)
		-- round studs: the stud layer is 0.99 x 0.91 of a header that is (aspect / header_height) wide
		local tile_y = theme.studs.header.Y.Scale
		local tile_x = tile_y * 0.91 / (0.99 * aspect / header_height)

		table.insert(props, ui.square(aspect))
		table.insert(props, ui.header {
			title = title,
			icon = icon,
			palette = palette,
			close = close,
			studs = UDim2.fromScale(tile_x, tile_y),
			Size = UDim2.fromScale(1, header_height),
			Position = UDim2.fromScale(0.5, header_height / 2),
		})
		return create "Frame" (props)
	end

	-- CONTENT -------------------------

	function ui.sunburst(props)
		props = props or {}
		defaults(props, {
			Name = "Sunburst",
			Image = theme.asset.sunburst,
			ImageColor3 = Color3.fromHex("FFFF1A"),
			ImageTransparency = 0.3,
			BackgroundTransparency = 1,
			ZIndex = -1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.25, 1.25),
		})
		table.insert(props, ui.square())
		return create "ImageLabel" (props)
	end

	-- a grid cell: icon, name colored by rarity, value top right. rays behind it, or a rarity stripe
	function ui.item_card(props)
		local name = take(props, "name")
		local image = take(props, "image")
		local value = take(props, "value")
		local rarity = take(props, "rarity")
		local rays = take(props, "sunburst")
		local selected = take(props, "selected")

		defaults(props, {
			BackgroundColor3 = theme.surface.tile_color,
			BackgroundTransparency = if theme.card.rays then theme.surface.transparency else theme.surface.tile_transparency,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			SelectionImageObject = selection_ring,
		})
		table.insert(props, corner(theme.card.corner))
		table.insert(props, create "UIStroke" {
			Color = pick(selected, theme.color.selected, theme.surface.stroke),
			Thickness = pick(selected, 0.05, math.max(theme.stroke.card, 0.012)),
			Transparency = pick(selected, 0, math.max(theme.surface.stroke_transparency, 0.15)),
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		})
		local gradient = theme.text_gradient[rarity or "common"] or theme.text_gradient.common
		if theme.card.rays then
			table.insert(props, create "CanvasGroup" {
				Name = "Rays",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				ZIndex = -1,
				ui.sunburst { ImageColor3 = rays or Color3.fromHex("0091FF"), ImageTransparency = 0.45, Position = UDim2.fromScale(0.5, 0.45) },
			})
		else
			-- soft rarity glow behind the icon + a stripe along the bottom
			table.insert(props, create "Frame" {
				Name = "Backdrop",
				BackgroundColor3 = gradient.colors[#gradient.colors],
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				ZIndex = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.45),
				Size = UDim2.fromScale(0.62, 0.62),
				create "UICorner" { CornerRadius = UDim.new(0.5, 0) },
				create "UIAspectRatioConstraint" { AspectRatio = 1 },
			})
			table.insert(props, create "Frame" {
				Name = "Stripe",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 1,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.985),
				Size = UDim2.fromScale(0.5, 0.025),
				create "UICorner" { CornerRadius = UDim.new(0.5, 0) },
				ui.gradient(gradient.colors, 0),
			})
		end
		table.insert(props, ui.icon(defaults(center(UDim2.fromScale(0.62, 0.62), 0.45), { Name = "Icon", Image = image, ZIndex = 1 })))
		table.insert(props, ui.text {
			Name = "Name",
			Text = name,
			style = rarity,
			ZIndex = 2,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.86),
			Size = UDim2.fromScale(0.9, 0.15),
		})
		if value then
			table.insert(props, ui.text {
				Name = "Value",
				Text = value,
				style = "cash",
				align = "right",
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.7, 0.13),
				Size = UDim2.fromScale(0.5, 0.17),
			})
		end
		local button = create "TextButton" (props)
		bind_press(button, button, nil, nil)
		return button
	end

	-- value: number 0-1 or a vide source of one
	function ui.progress(props)
		local value = take(props, "value") or 0
		local text = take(props, "text")
		local fill = theme.text_gradient.cash
		defaults(props, {
			BackgroundColor3 = theme.surface.tile_color,
			BackgroundTransparency = math.min(theme.surface.tile_transparency, 0.5),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.5, 0.06),
		})
		table.insert(props, corner(theme.progress.corner))
		table.insert(props, stroke(theme.surface.stroke, 0.1, theme.surface.stroke_transparency))
		table.insert(props, create "CanvasGroup" {
			Name = "Fill",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			corner(theme.progress.corner),
			create "Frame" {
				Name = "Bar",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Size = map(value, function(v) return UDim2.fromScale(math.clamp(v, 0, 1), 1) end),
				corner(theme.progress.corner),
				ui.gradient(fill.colors),
			},
		})
		if text then
			table.insert(props, ui.text {
				Name = "Label",
				Text = text,
				ZIndex = 3,
				stroke = fill.stroke,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.7),
			})
		end
		return create "Frame" (props)
	end

	-- HEX -------------------------

	local SQRT3 = math.sqrt(3)

	-- pointy-top hexagon: a w x h/2 band rotated 0 / 60 / -60 inside a box of aspect sqrt(3)/2 covers
	-- exactly a hex. a style can set theme.asset.hex (white hex image) to get one image with a gradient
	-- instead. color = Color3 or source
	function ui.hex(props)
		local color = take(props, "color") or theme.surface.color
		local transparency = take(props, "transparency") or 0
		local gradient = take(props, "gradient")

		local children = {}
		for key, value in props do
			if type(key) == "number" then
				children[key] = value
				props[key] = nil
			end
		end

		defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
		table.insert(props, create "UIAspectRatioConstraint" { AspectRatio = SQRT3 / 2 })
		if theme.asset.hex then
			table.insert(props, create "ImageLabel" {
				Name = "Shape",
				Image = theme.asset.hex,
				ImageColor3 = color,
				ImageTransparency = transparency,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				gradient and ui.gradient(gradient) or nil,
			})
		else
			for _, angle in { 0, 60, -60 } do
				table.insert(props, create "Frame" {
					Name = "Band",
					BackgroundColor3 = color,
					BackgroundTransparency = transparency,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.5),
					Rotation = angle,
				})
			end
		end
		-- content goes over the shape
		table.insert(props, create "Frame" { Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, children })
		return create "Frame" (props)
	end

	-- candy bevel as hexes: dark border, base rim peeking out below, raised face on top.
	-- the three colors are worked out once per palette change, not once per band
	function ui.hex_stack(palette, props)
		props = props or {}
		local colors = map(palette, function(name)
			local p = get_palette(name)
			return { border = p.stroke, rim = p.base, face = p.face[1]:Lerp(p.face[2], 0.55) }
		end)
		local derived = if type(colors) == "function" then vide.derive(colors) else nil
		local function color_of(key)
			if derived then return function() return derived()[key] end end
			return colors[key]
		end

		local children = {}
		for key, value in props do
			if type(key) == "number" then
				children[key] = value
				props[key] = nil
			end
		end
		defaults(props, { Name = "HexStack", Size = UDim2.fromScale(1, 1) })
		table.insert(props, ui.hex { Name = "Border", color = color_of("border"), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1) })
		table.insert(props, ui.hex { Name = "Rim", color = color_of("rim"), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.88, 0.88) })
		table.insert(props, ui.hex {
			Name = "Face",
			color = color_of("face"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.47),
			Size = UDim2.fromScale(0.84, 0.84),
			ZIndex = 2,
			children,
		})
		return ui.hex(props)
	end

	-- axial coordinates (q, r), pointy-top. the box keeps the aspect of the whole grid, cells sit at
	-- `gap` of their slot so the borders don't touch. cell(q, r) returns an instance sized 1 x 1
	function ui.hex_grid(props)
		local radius = take(props, "radius") or 2
		local cell = take(props, "cell")
		local gap = take(props, "gap") or 0.94
		assert(type(cell) == "function", "ui.hex_grid: cell must be a function(q, r)")

		-- in units of the hex circumradius
		local width = SQRT3 * (2 * radius + 1)
		local height = 1.5 * 2 * radius + 2

		defaults(props, { Name = "HexGrid", BackgroundTransparency = 1, BorderSizePixel = 0 })
		table.insert(props, create "UIAspectRatioConstraint" { AspectRatio = width / height })
		for q = -radius, radius do
			for r = math.max(-radius, -q - radius), math.min(radius, -q + radius) do
				local slot = create "Frame" {
					Name = `hex_{q}_{r}`,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5 + SQRT3 * (q + r / 2) / width, 0.5 + 1.5 * r / height),
					Size = UDim2.fromScale(SQRT3 / width * gap, 2 / height * gap),
					cell(q, r),
				}
				table.insert(props, slot)
			end
		end
		return create "Frame" (props)
	end

	-- LAYOUT -------------------------

	function ui.list_layout(props)
		local is_row = props.direction ~= "column"
		local align = alignments[props.align or "start"]
		local cross = alignments[props.cross or "start"]

		return create "UIListLayout" {
			FillDirection = is_row and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = to_udim(props.gap),
			HorizontalAlignment = is_row and align[1] or cross[1],
			VerticalAlignment = is_row and cross[2] or align[2],
			HorizontalFlex = (props.fill and is_row) and Enum.UIFlexAlignment.Fill or Enum.UIFlexAlignment.None,
			VerticalFlex = (props.fill and not is_row) and Enum.UIFlexAlignment.Fill or Enum.UIFlexAlignment.None,
		}
	end

	local function list(props, direction)
		table.insert(props, ui.list_layout {
			direction = direction,
			gap = take(props, "gap"),
			align = take(props, "align"),
			cross = take(props, "cross"),
			fill = take(props, "fill"),
		})
		return ui.box(props)
	end

	function ui.row(props)
		return list(props, "row")
	end

	function ui.column(props)
		return list(props, "column")
	end

	local function scroller(props)
		return defaults(props, {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
			ClipsDescendants = true,
		})
	end

	-- inside a scrolling frame scale follows the canvas, and an automatic canvas grows with its content,
	-- so cells are sized from the width only. ratio = cell width / height
	function ui.scroll_grid(props)
		local columns = take(props, "columns") or 4
		local ratio = take(props, "ratio") or 1
		local gap_x = take(props, "gap_x") or 0.027
		local gap_y = take(props, "gap_y") or gap_x
		-- cells + gaps add up to exactly 1 and UDim scale is a 32 bit float: leave a hair of slack
		local cell = take(props, "cell") or (1 - gap_x * (columns - 1)) / columns - 0.0005

		scroller(props)
		table.insert(props, create "UIGridLayout" {
			CellSize = UDim2.fromScale(cell, cell),
			CellPadding = UDim2.fromScale(gap_x, gap_y),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			create "UIAspectRatioConstraint" {
				AspectRatio = ratio,
				AspectType = Enum.AspectType.ScaleWithParentSize,
				DominantAxis = Enum.DominantAxis.Width,
			},
		})
		-- strokes are drawn outside each cell, padding keeps the edge ones from being clipped.
		-- y is a bit bigger than x so it looks even on the usual 1.4 - 2:1 grid areas
		table.insert(props, ui.padding(0.01, 0.015))
		return create "ScrollingFrame" (props)
	end

	-- vertical list of cards. the spacers keep the first and last card off the edges
	function ui.scroll_list(props)
		local gap = take(props, "gap") or 0.04
		scroller(props)
		table.insert(props, ui.list_layout { direction = "column", gap = gap, cross = "center" })
		table.insert(props, ui.box { Name = "Top", LayoutOrder = -1e6, Size = UDim2.fromScale(1, 0.005) })
		table.insert(props, ui.box { Name = "Bottom", LayoutOrder = 1e6, Size = UDim2.fromScale(1, 0.025) })
		return create "ScrollingFrame" (props)
	end

	-- SCREEN -------------------------

	function ui.device(): "phone" | "tablet" | "desktop" | "console"
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
		if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
			return "console"
		end
		if UserInputService.TouchEnabled then
			return if math.min(viewport.X, viewport.Y) < 500 then "phone" else "tablet"
		end
		return "desktop"
	end

	-- a UIScale (still pure scale) that grows the ui on phones so text and buttons stay readable and tappable
	function ui.adaptive(scales: { [string]: number }?)
		local picks = scales or theme.adaptive
		local scale = create "UIScale" { Name = "adaptive_scale" }

		local function update()
			local device = ui.device()
			scale.Scale = picks[device] or theme.adaptive[device] or 1
		end
		update()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		end
		return scale
	end

	return ui
end


-- MAIN -------------------------

return build(require(script.theme))
