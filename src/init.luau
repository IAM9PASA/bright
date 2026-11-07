-- vide building blocks in the "brainrot / cake" cartoon style. every function takes a vide props table
-- (children go in the array part) and returns an instance. extra keys like palette / align are read and
-- removed before create. everything is scale: no px offsets, no text size px limits.
--
-- WINDOWS
-- ui.window { title, icon, palette = "blue", shape = "standard" | "inventory" | "large" | "popup", close }
--   dark translucent window with the studded header (Top > Main > Layout, Icon, title, Close)
-- ui.header { title, icon, palette, close }  the header alone
-- ui.card { tile = false, selected }        neutral surface card (tile = darker inset). square corners
-- ui.panel                                   alias of ui.card with the thin window outline
--
-- TEXT
-- ui.text "hi" / ui.text { style, align, stroke }   heavy outlined label
--   style = nil (white) | "dim" | "cash" | "legendary" | "epic" | "rare" | "common" | "gems" | "item" | "rainbow"
-- ui.title { Text, align, stroke, style }   two stacked labels (white over dark) for the 3d drop edge
--
-- CONTROLS
-- ui.button { text, palette = "green", amount, disabled, studs }   3d candy button, palette may be a source
-- ui.close_button {}                        red "X" candy button
-- ui.icon_button { image, palette }         square candy button with an icon
-- ui.tab { text, active, palette }          candy button that goes grey when not active (active = bool or source)
-- ui.input { PlaceholderText }              dark inset textbox
-- ui.toggle { on }                          on/off switch, on = bool or vide source (click flips a source)
-- ui.hud_button { text, image, notify }    square side button with caption (store, inventory...)
-- ui.hit { hover = true, ... }               invisible full-size "button", hover pops the parent
--
-- CONTENT
-- ui.item_card { name, image, value, rarity, sunburst, selected }   grid cell like the inventory
-- ui.sunburst { color }                      rays behind an icon, clip it with a CanvasGroup parent
-- ui.studs(tile, colors)                     the stud texture layer every header / button face uses
-- ui.progress { value, text }               bar with the cash gradient, value = number or source (0-1)
-- ui.icon { Image = id }                     square image
--
-- LAYOUT
-- ui.box / ui.row / ui.column { gap = 0.02, align = "center", cross = "center", fill = true }
-- ui.list_layout { direction = "row" | "column", gap, align, cross, fill }   layout only
-- ui.scroll_grid { columns = 4, ratio = 1, gap_x = 0.027, gap_y }   cells sized from the width
-- ui.scroll_list { gap = 0.04 }              vertical list with edge spacers
-- ui.square(ratio?) / ui.padding(x, y?)      constraints, padding is scale per axis
-- ui.ratio(width / height)                   height follows the width (rows inside scroll_list)
-- ui.pad(space, aspect?)                     even padding: space = "sm" | number, share of the short side,
--                                            aspect = width / height of the padded frame
-- ui.lint(root)                              list rule breaks (offsets, px strokes, unscaled text), see RULES.md
-- ui.gradient(colors, rotation?)             UIGradient from a color list, 90 = top to bottom
-- ui.sequence(colors)                        ColorSequence from a color list
--
-- SCREEN
-- ui.device()                                "phone" | "tablet" | "desktop" | "console"
-- ui.adaptive(scales?)                       UIScale that grows the ui on small screens
-- ui.pop(gui, from?) / ui.pop_on(gui, property, from?, watch?)   scale-in animation

-- SERVICES -------------------------

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


-- MODULES -------------------------

local vide = require(script.Parent.vide)
local theme = require(script.theme)


-- VARIABLES -------------------------

local create = vide.create

local fast_tween = TweenInfo.new(theme.motion.fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- back out overshoots a little, reads as a "pop"
local pop_tween = TweenInfo.new(theme.motion.normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

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

local ui = {}
ui.theme = theme


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

ui.sequence = sequence

local function get_palette(name)
	return theme.palette[name] or theme.palette.blue
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

-- a bool or a vide source picks between two values
local function pick(flag, on, off)
	if type(flag) == "function" then
		return function()
			return if flag() then on else off
		end
	end
	return if flag then on else off
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

local function center(size: UDim2, y: number?)
	return { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y or 0.5), Size = size }
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

ui.lint = require(script.lint)

function ui.box(props)
	defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
	return create "Frame" (props)
end

function ui.icon(props)
	defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
	table.insert(props, ui.square())
	return create "ImageLabel" (props)
end

-- the stud texture. under a gradient it reads as raised studs in the surface color
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

local function text_style(style)
	if style == nil or style == "dim" then
		return nil
	end
	return theme.text_gradient[style]
end

-- heavy white label with a thick outline. styles add a vertical gradient to the text
function ui.text(props)
	if type(props) == "string" then
		props = { Text = props }
	end

	local style = take(props, "style")
	local align = take(props, "align")
	local outline = take(props, "stroke")
	local gradient = text_style(style)

	defaults(props, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextScaled = true,
		FontFace = theme.font.heavy,
		TextColor3 = if style == "dim" then theme.color.text_dim else theme.color.text,
		TextXAlignment = text_alignments[align or "center"],
	})
	table.insert(props, stroke(outline or (gradient and gradient.stroke) or theme.color.outline, theme.stroke.label, 0, true))
	if gradient then
		table.insert(props, ui.gradient(gradient.colors, gradient.rotation))
	end
	return create "TextLabel" (props)
end

-- white label over a dark copy a little lower: the 3d drop edge on every title
function ui.title(props)
	local text = take(props, "Text")
	local align = take(props, "align") or "left"
	local outline = take(props, "stroke") or theme.color.outline
	local style = take(props, "style")
	local gradient = text_style(style)

	defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
	table.insert(props, create "TextLabel" {
		Name = "TitleUp",
		Text = text,
		ZIndex = 3,
		BackgroundTransparency = 1,
		TextScaled = true,
		FontFace = theme.font.heavy,
		TextColor3 = theme.color.text,
		TextXAlignment = text_alignments[align],
		Size = UDim2.fromScale(1, 1),
		stroke(outline, theme.stroke.title, 0, true),
		gradient and ui.gradient(gradient.colors, gradient.rotation) or nil,
	})
	table.insert(props, create "TextLabel" {
		Name = "TitleDown",
		Text = text,
		ZIndex = 2,
		BackgroundTransparency = 1,
		TextScaled = true,
		FontFace = theme.font.heavy,
		TextColor3 = outline,
		TextXAlignment = text_alignments[align],
		Position = UDim2.fromScale(0, 0.08),
		Size = UDim2.fromScale(1, 1),
		stroke(outline, theme.stroke.title, 0, true),
	})
	return create "Frame" (props)
end

-- MOTION -------------------------

local function scale_of(target: GuiObject, name: string): UIScale
	local scale = target:FindFirstChild(name) :: UIScale?
	if not scale then
		scale = create "UIScale" { Name = name, Parent = target }
	end
	return scale :: UIScale
end

-- scale target from `from` back to 1. own UIScale so it never fights the press scale
function ui.pop(target: GuiObject, from: number?)
	local scale = scale_of(target, "pop_scale")
	scale.Scale = from or 0.9
	TweenService:Create(scale, pop_tween, { Scale = 1 }):Play()
end

-- pop every time a property flips to a truthy value / changes (Visible, Text, Image)
function ui.pop_on(target: GuiObject, property: string, from: number?, watch: Instance?)
	local source = watch or target
	source:GetPropertyChangedSignal(property):Connect(function()
		local value = (source :: any)[property]
		if value == false or value == "" then return end
		ui.pop(target, from)
	end)
end

-- hover grows, press squashes and pushes the face down into its rim.
-- target = what scales, nil = the button's parent at event time (ui.hit)
local function bind_press(button: GuiButton, target: GuiObject?, face: GuiObject?, label: GuiObject?)
	local function scale_to(value)
		local frame = target or button.Parent :: GuiObject
		TweenService:Create(scale_of(frame, "press_scale"), fast_tween, { Scale = value }):Play()
	end
	local function push(down)
		if face then
			TweenService:Create(face, fast_tween, { Position = UDim2.fromScale(0.5, if down then 0.5 else 0.465) }):Play()
		end
		if label then
			TweenService:Create(label, fast_tween, { Position = UDim2.fromScale(0.5, if down then 0.5 else 0.467) }):Play()
		end
	end

	button.MouseEnter:Connect(function() scale_to(1.06) end)
	button.MouseLeave:Connect(function()
		scale_to(1)
		push(false)
	end)
	button.MouseButton1Down:Connect(function()
		scale_to(0.94)
		push(true)
	end)
	button.MouseButton1Up:Connect(function()
		scale_to(1.06)
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
	stroke(Color3.fromHex("FFF823"), 0.06),
}

-- WINDOWS -------------------------

function ui.card(props)
	local tile = take(props, "tile")
	local selected = take(props, "selected")
	defaults(props, {
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = if tile then theme.surface.tile_transparency else theme.surface.transparency,
		BorderSizePixel = 0,
	})
	table.insert(props, create "UIStroke" {
		Color = pick(selected, theme.text_gradient.legendary.colors[1], theme.surface.stroke),
		Thickness = pick(selected, theme.stroke.card * 2, theme.stroke.card),
		Transparency = pick(selected, 0, if tile then 0.7 else theme.surface.stroke_transparency),
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
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
	table.insert(props, stroke(theme.surface.stroke, theme.stroke.window, theme.surface.stroke_transparency))
	return create "Frame" (props)
end

-- CONTROLS -------------------------

-- the signature control: dark base rim, light gradient face with studs, outlined label on top
function ui.button(props)
	local text = take(props, "text")
	local amount = take(props, "amount")
	local disabled = take(props, "disabled")
	local studs = take(props, "studs") or theme.studs.button
	local image = take(props, "image")
	local palette = take(props, "palette") or "green"

	-- disabled buttons turn grey and stop taking input
	local effective = palette
	if disabled ~= nil then
		effective = function()
			local off = if type(disabled) == "function" then disabled() else disabled
			if off then return "grey" end
			return if type(palette) == "function" then palette() else palette
		end
	end

	defaults(props, {
		Size = UDim2.fromScale(0.25, 0.1),
		BackgroundColor3 = from_palette(effective, function(p) return p.base end),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		SelectionImageObject = selection_ring,
		Interactable = if disabled == nil then true else pick(disabled, false, true),
	})
	-- Border mode matters: on a TextButton the default (Contextual) outlines the empty text, not the button
	table.insert(props, create "UIStroke" {
		Color = from_palette(effective, function(p) return p.stroke end),
		Thickness = theme.stroke.button,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		LineJoinMode = Enum.LineJoinMode.Round,
	})

	local face = create "Frame" {
		Name = "Color",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.465),
		Size = UDim2.fromScale(1, 0.91),
		create "UIGradient" { Rotation = 90, Color = from_palette(effective, function(p) return sequence(p.face) end) },
		ui.studs(studs, from_palette(effective, function(p) return sequence(p.studs) end)),
	}
	table.insert(props, face)

	local label
	if image then
		label = ui.icon(defaults(center(UDim2.fromScale(0.7, 0.7), 0.467), { Name = "Icon", Image = image, ZIndex = 2 }))
	else
		label = create "TextLabel" {
			Name = "Title",
			Text = text,
			ZIndex = 2,
			BackgroundTransparency = 1,
			TextScaled = true,
			FontFace = theme.font.heavy,
			TextColor3 = theme.color.text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.467),
			Size = UDim2.fromScale(0.86, 0.6),
			stroke(from_palette(effective, function(p) return p.text end), theme.stroke.title, 0, true),
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

	local button = create "TextButton" (props)
	bind_press(button, button, face, label)
	return button
end

function ui.close_button(props)
	props = props or {}
	defaults(props, { Name = "Close", text = "X", palette = "red", studs = theme.studs.square })
	table.insert(props, ui.square())
	return ui.button(props)
end

-- aspect constraints only shrink, so give the box a real height before the square kicks in
function ui.icon_button(props)
	defaults(props, { palette = "blue", studs = theme.studs.square, Size = UDim2.fromScale(1, 1) })
	table.insert(props, ui.square())
	return ui.button(props)
end

-- active tab keeps its palette, the others go grey. active can be a bool or a vide source
function ui.tab(props)
	local active = take(props, "active")
	local palette = take(props, "palette") or "blue"
	props.palette = pick(active, palette, "grey")
	return ui.button(props)
end

function ui.input(props)
	defaults(props, {
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = theme.surface.tile_transparency - 0.1,
		BorderSizePixel = 0,
		TextScaled = true,
		FontFace = theme.font.heavy,
		TextColor3 = theme.color.text,
		PlaceholderColor3 = theme.color.text_dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = "",
	})
	table.insert(props, create "UIStroke" {
		Color = theme.surface.stroke,
		Thickness = theme.stroke.card * 2,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	-- text padding inside the box keeps the whole box tappable
	table.insert(props, ui.padding(0.05, 0.22))
	return create "TextBox" (props)
end

-- dark track with a candy knob that slides right and turns green when on
function ui.toggle(props)
	local on = take(props, "on")
	local is_on = function()
		if type(on) == "function" then return on() end
		return on
	end

	defaults(props, {
		Size = UDim2.fromScale(0.3, 0.12),
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = 0.43,
		BorderSizePixel = 0,
	})
	table.insert(props, stroke(theme.surface.stroke, 0.12))
	table.insert(props, ui.button {
		Name = "Bool",
		text = function() return if is_on() then "ON" else "OFF" end,
		palette = function() return if is_on() then "green" else "red" end,
		studs = theme.studs.square,
		AnchorPoint = function() return Vector2.new(if is_on() then 1 else 0, 0.5) end,
		Position = function() return UDim2.fromScale(if is_on() then 1 else 0, 0.5) end,
		Size = UDim2.fromScale(0.55, 1.15),
		Activated = function()
			if type(on) == "function" then on(not on()) end
		end,
	})
	return create "Frame" (props)
end

-- invisible full-size button. hover = true pops the parent like a candy button
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

-- square side button with an icon and a caption, like the store / inventory hud buttons
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
	table.insert(props, ui.square())
	table.insert(props, create "UICorner" { CornerRadius = UDim.new(0.015, 0) })
	table.insert(props, stroke(Color3.fromHex("030A1A"), 0.04))
	table.insert(props, create "Frame" (defaults(center(UDim2.fromScale(0.925, 0.925)), {
		Name = "Color",
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
	})))
	table.insert(props, ui.icon(defaults(center(UDim2.fromScale(0.75, 0.75), 0.43), { Name = "Icon", Image = image, ZIndex = 2 })))
	table.insert(props, ui.title {
		Name = "Caption",
		Text = text,
		align = "center",
		ZIndex = 3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.815),
		Size = UDim2.fromScale(0.975, 0.275),
	})
	if notify ~= nil then
		table.insert(props, create "Frame" {
			Name = "Info",
			Visible = pick(notify, true, false),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 4,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.9, 0.1),
			Size = UDim2.fromScale(0.26, 0.26),
			create "UICorner" { CornerRadius = UDim.new(0.5, 0) },
			ui.gradient({ Color3.fromHex("FF0000"), Color3.fromHex("BF0000") }),
			stroke(Color3.fromHex("410101"), 0.12),
			ui.text { Text = "!", ZIndex = 5, Size = UDim2.fromScale(0.8, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) },
		})
	end
	local button = create "TextButton" (props)
	bind_press(button, button, nil, nil)
	return button
end

-- the header bar every window shares: dark base, glossy studded face, icon poking out, title, close
function ui.header(props)
	local title = take(props, "title")
	local icon = take(props, "icon")
	local palette = get_palette(take(props, "palette"))
	local close = take(props, "close")
	local tile = take(props, "studs") or theme.studs.header

	defaults(props, {
		Name = "Top",
		BackgroundColor3 = palette.base,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.067),
		Size = UDim2.fromScale(1, 0.134),
		ZIndex = 2,
	})
	table.insert(props, stroke(palette.stroke, theme.stroke.header))
	table.insert(props, create "Frame" {
		Name = "Main",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.454),
		Size = UDim2.fromScale(1, 0.908),
		ui.gradient(palette.face),
		ui.studs(tile, sequence(palette.studs), UDim2.fromScale(0.99, 0.91)),
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
			stroke = palette.text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(if icon then 0.351 else 0.27, 0.463),
			Size = UDim2.fromScale(0.436, 0.75),
		},
		close and ui.close_button {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.955, 0.512),
			Size = UDim2.fromScale(0.066, 0.82),
			ZIndex = 4,
			Activated = if type(close) == "function" then close else nil,
		} or nil,
	})
	return create "Frame" (props)
end

-- shape picks the reference window proportions, the window keeps them on every screen
function ui.window(props)
	local title = take(props, "title")
	local icon = take(props, "icon")
	local palette = take(props, "palette") or "blue"
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
	table.insert(props, stroke(theme.surface.stroke, theme.stroke.window, theme.surface.stroke_transparency))
	local aspect = theme.window[shape] or theme.window.standard
	local header_height = if shape == "popup" then 0.184 else 0.134
	-- round studs: the stud layer is 0.99 x 0.91 of a header that is (aspect / header_height) wide,
	-- so tile X = tile Y * layer height / layer width
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

-- an inventory / index grid cell: clipped sunburst, big icon, name at the bottom, value top right
function ui.item_card(props)
	local name = take(props, "name")
	local image = take(props, "image")
	local value = take(props, "value")
	local rarity = take(props, "rarity")
	local rays = take(props, "sunburst")
	local selected = take(props, "selected")

	defaults(props, {
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = theme.surface.transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		SelectionImageObject = selection_ring,
	})
	table.insert(props, create "UIStroke" {
		Color = pick(selected, theme.text_gradient.legendary.colors[1], theme.surface.stroke),
		Thickness = pick(selected, 0.06, 0.033),
		Transparency = pick(selected, 0, 0.15),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
	table.insert(props, create "CanvasGroup" {
		Name = "Rays",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = -1,
		ui.sunburst { ImageColor3 = rays or Color3.fromHex("0091FF"), ImageTransparency = 0.45, Position = UDim2.fromScale(0.5, 0.45) },
	})
	table.insert(props, ui.icon(defaults(center(UDim2.fromScale(0.72, 0.72), 0.45), { Name = "Icon", Image = image, ZIndex = 0 })))
	table.insert(props, ui.text {
		Name = "Name",
		Text = name,
		style = rarity,
		ZIndex = 2,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.88),
		Size = UDim2.fromScale(0.925, 0.17),
	})
	if value then
		table.insert(props, ui.text {
			Name = "Value",
			Text = value,
			style = "cash",
			align = "right",
			ZIndex = 2,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.707, 0.125),
			Size = UDim2.fromScale(0.511, 0.193),
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
	defaults(props, {
		BackgroundColor3 = theme.surface.color,
		BackgroundTransparency = theme.surface.transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.5, 0.06),
	})
	table.insert(props, stroke(theme.surface.stroke, 0.12, 0))
	table.insert(props, create "CanvasGroup" {
		Name = "Fill",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		create "Frame" {
			Name = "Bar",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = if type(value) == "function"
				then function() return UDim2.fromScale(math.clamp(value(), 0, 1), 1) end
				else UDim2.fromScale(math.clamp(value, 0, 1), 1),
			ui.gradient(theme.text_gradient.cash.colors),
		},
	})
	if text then
		table.insert(props, ui.text {
			Name = "Label",
			Text = text,
			ZIndex = 3,
			stroke = theme.text_gradient.cash.stroke,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.75),
		})
	end
	return create "Frame" (props)
end

-- LAYOUT -------------------------

-- use inside any container when children must stay direct children
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
-- so cells are sized from the width only (ScaleWithParentSize + Width): columns stay put on every screen.
-- ratio = cell width / height
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

-- what kind of screen this is, from the viewport and input. phones are touch with a short side under 500pt
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

-- a UIScale (still pure scale) that grows the ui on phones so text and buttons stay readable and tappable.
-- updates when the viewport changes (rotation, window resize)
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


-- MAIN -------------------------

return ui
