-- vide building blocks. every function takes a vide props table (children go in the array part)
-- and returns an instance. extra keys like gap / align / style are read and removed before create.
--
-- ui.panel / ui.card / ui.pill / ui.box      frames
-- ui.text "hi" / ui.text { style = "title" | "dim" | "faint", align = "left" | "center" | "right" }
-- ui.input { PlaceholderText = "Search" }    textbox
-- ui.icon { Image = id }                     square image
-- ui.row / ui.column { gap = 0.02, align = "center", cross = "center", fill = true }   gap = scale
-- ui.list_layout { direction = "row" | "column", gap, align, cross, fill }   layout only
-- ui.scroll_grid { columns = 6, gap_x = 0.0135, gap_y }   square cells sized from the width, all scale
--   (or cell = 0.155 for a fixed cell width instead of a column count)
-- ui.tab { Name, text, active }              pill tab with "label" + "button", active = bool or source
-- ui.button { text, style, disabled }       text button, style: primary (accent, one per screen) / secondary / ghost
-- ui.icon_button { Name, image }             square button with "image"
-- ui.hit { hover = true, ... }               invisible full-size "button" (hover lightens parent)
-- ui.square(ratio?) / ui.padding(x, y?)      constraints, padding is scale per axis
-- ui.device()                               "phone" | "tablet" | "desktop" | "console"
-- ui.adaptive(scales?)                       UIScale that grows the ui on small screens, put it in the root panel
-- everything is scale (user rule): no px offsets, no text size px limits
-- ui.pop(gui, from?) / ui.pop_on(gui, property, from?, watch?)   scale-in animation (now / on change)
-- ui.gradient(colors, rotation?)             UIGradient from a color list, 90 = top to bottom
--   multiplies the parent color (white base = exact colors), tints only its parent not children,
--   inside a UIStroke it colors the border

-- SERVICES -------------------------

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


-- MODULES -------------------------

local vide = require(script.Parent.vide)
local theme = require(script.theme)


-- VARIABLES -------------------------

local create = vide.create

local state_tween = TweenInfo.new(theme.motion.fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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

local button_styles = {
	-- the fill multiplies the accent gradient: rest a little dim so hover can brighten to the full accent
	primary = { fill = Color3.fromRGB(222, 222, 222), hover = Color3.new(1, 1, 1), gradient = theme.gradient.accent, text = theme.color.text_on_accent, transparency = 0 },
	secondary = { fill = theme.color.card, gradient = theme.gradient.shade, text = theme.color.text, transparency = 0 },
	ghost = { fill = theme.color.card, gradient = theme.gradient.shade, text = theme.color.text_dim, transparency = 1 },
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

local function corner(radius: UDim)
	return create "UICorner" { CornerRadius = radius }
end

-- gamepad / keyboard focus ring. roblox clones SelectionImageObject over the selected button,
-- the default is a thin grey box that disappears on dark ui
local selection_ring = create "Frame" {
	Name = "selection_ring",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	corner(theme.radius.button),
	create "UIStroke" {
		Color = theme.color.accent,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = 0.06,
	},
}

function ui.gradient(colors: { Color3 }, rotation: number?)
	-- one color has no span to spread over, ColorSequence.new(color) fills it flat
	if #colors == 1 then
		return create "UIGradient" { Color = ColorSequence.new(colors[1]), Rotation = rotation or 90 }
	end

	local keypoints = {}
	for i, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
	end
	return create "UIGradient" { Color = ColorSequence.new(keypoints), Rotation = rotation or 90 }
end

function ui.square(ratio: number?)
	return create "UIAspectRatioConstraint" { AspectRatio = ratio or 1 }
end

-- scale of the parent on each axis, so give y separately for wide boxes
function ui.padding(x: number, y: number?)
	local pad_x, pad_y = UDim.new(x, 0), UDim.new(y or x, 0)
	return create "UIPadding" { PaddingLeft = pad_x, PaddingRight = pad_x, PaddingTop = pad_y, PaddingBottom = pad_y }
end

function ui.box(props)
	defaults(props, { BackgroundTransparency = 1, BorderSizePixel = 0 })
	return create "Frame" (props)
end

-- white base so the panel gradient shows its real colors, border uses the accent gradient
function ui.panel(props)
	defaults(props, {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = theme.transparency.panel,
		BorderSizePixel = 0,
	})
	table.insert(props, corner(theme.radius.panel))
	table.insert(props, ui.gradient(theme.gradient.panel))
	table.insert(props, create "UIStroke" {
		Color = Color3.new(1, 1, 1),
		Transparency = theme.transparency.line,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = 0.003,
		ui.gradient(theme.gradient.accent, 45),
	})
	return create "Frame" (props)
end

-- shade darkens toward the bottom so cards look lit from above
function ui.card(props)
	defaults(props, { BackgroundColor3 = theme.color.card, BorderSizePixel = 0 })
	table.insert(props, corner(theme.radius.card))
	table.insert(props, ui.gradient(theme.gradient.shade))
	return create "Frame" (props)
end

function ui.pill(props)
	defaults(props, { BackgroundColor3 = theme.color.card, BorderSizePixel = 0 })
	table.insert(props, corner(theme.radius.pill))
	table.insert(props, ui.gradient(theme.gradient.shade))
	return create "Frame" (props)
end

function ui.text(props)
	if type(props) == "string" then
		props = { Text = props }
	end

	local style = take(props, "style")
	local align = take(props, "align")

	local font, color = theme.font.medium, theme.color.text
	if style == "title" then
		font = theme.font.bold
	elseif style == "dim" then
		color = theme.color.text_dim
	elseif style == "faint" then
		font, color = theme.font.bold, theme.color.text_faint
	end

	defaults(props, {
		BackgroundTransparency = 1,
		TextScaled = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = font,
		TextColor3 = color,
		TextXAlignment = text_alignments[align or "center"],
	})
	return create "TextLabel" (props)
end

function ui.input(props)
	defaults(props, {
		BackgroundTransparency = 1,
		TextScaled = true,
		FontFace = theme.font.medium,
		TextColor3 = theme.color.text,
		PlaceholderColor3 = theme.color.text_dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = "",
	})
	return create "TextBox" (props)
end

function ui.icon(props)
	defaults(props, { BackgroundTransparency = 1 })
	table.insert(props, ui.square())
	return create "ImageLabel" (props)
end

-- hover lightens, press darkens, both tweened. target defaults to the button's parent at event time
local function bind_states(button: GuiButton, target: GuiObject?, hover_color: Color3?)
	local hover = hover_color or theme.color.card_hover
	local base_color

	local function tween_to(color)
		local frame = target or button.Parent :: GuiObject
		TweenService:Create(frame, state_tween, { BackgroundColor3 = color }):Play()
	end

	button.MouseEnter:Connect(function()
		local frame = target or button.Parent :: GuiObject
		base_color = base_color or frame.BackgroundColor3
		tween_to(hover)
	end)
	button.MouseLeave:Connect(function()
		if not base_color then return end
		tween_to(base_color)
	end)
	button.MouseButton1Down:Connect(function()
		if not base_color then return end
		tween_to(base_color:Lerp(Color3.new(), 0.3))
	end)
	button.MouseButton1Up:Connect(function()
		if not base_color then return end
		tween_to(hover)
	end)
	-- touch never fires MouseLeave, so a tapped card stayed on the hover color: reset when the touch ends
	button.InputEnded:Connect(function(input)
		if not base_color or input.UserInputType ~= Enum.UserInputType.Touch then return end
		tween_to(base_color)
	end)
end

-- scale target from `from` back to 1. own UIScale so it never fights components.button's scale
function ui.pop(target: GuiObject, from: number?)
	local scale = target:FindFirstChild("pop_scale") :: UIScale?
	if not scale then
		scale = create "UIScale" { Name = "pop_scale", Parent = target }
	end
	scale.Scale = from or 0.94
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

-- handlers and components.button look for a child named "button"
-- hover = true gives the parent card hover + pressed states
-- any other props (Activated handlers, LayoutOrder, ...) pass through to the button
function ui.hit(props)
	props = props or {}
	local hover = take(props, "hover")

	defaults(props, {
		Name = "button",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ZIndex = 2,
		SelectionImageObject = selection_ring,
	})
	local button = create "ImageButton" (props)
	if hover then
		bind_states(button)
	end
	return button
end

-- use inside any container when children must stay direct children (ui.pill { ui.list_layout {...}, ... })
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

-- cell and gaps are scale of the scroll frame window
-- inside a scrolling frame scale follows the canvas, and an automatic canvas grows with its content,
-- so a plain square constraint shrank cells to a fraction of the height (12 tiny columns instead of 6).
-- ScaleWithParentSize + Width sizes every cell from the width only: columns stay put on every screen
function ui.scroll_grid(props)
	local columns = take(props, "columns")
	local gap_x = take(props, "gap_x") or 0.0135
	local gap_y = take(props, "gap_y") or gap_x
	-- cells + gaps add up to exactly 1, and UDim scale is a 32 bit float: round-off can push the last
	-- column onto the next row, so leave a hair of slack
	local cell = take(props, "cell") or (columns and (1 - gap_x * (columns - 1)) / columns - 0.0005) or 0.2

	defaults(props, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.color.scrollbar,
	})
	table.insert(props, create "UIGridLayout" {
		CellSize = UDim2.fromScale(cell, cell),
		CellPadding = UDim2.fromScale(gap_x, gap_y),
		SortOrder = Enum.SortOrder.LayoutOrder,
		create "UIAspectRatioConstraint" {
			AspectRatio = 1,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Width,
		},
	})
	return create "ScrollingFrame" (props)
end

function ui.tab(props)
	local text = take(props, "text")
	local active = take(props, "active")

	-- active can be a plain bool or a vide source, so the tab follows state without a rebuild
	local function pick(on, off)
		if type(active) == "function" then
			return function()
				return if active() then on else off
			end
		end
		return if active then on else off
	end

	defaults(props, {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = pick(0, 1),
		BorderSizePixel = 0,
	})
	table.insert(props, corner(theme.radius.pill))
	table.insert(props, ui.gradient(theme.gradient.tab))
	table.insert(props, ui.text {
		Name = "label",
		Text = text,
		style = "title",
		TextColor3 = pick(theme.color.text, theme.color.text_dim),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.5),
	})
	table.insert(props, ui.hit())
	return create "Frame" (props)
end

-- aspect constraints only shrink, so the box needs a real height before the square kicks in
function ui.icon_button(props)
	local image = take(props, "image")

	defaults(props, {
		Size = UDim2.fromScale(1, 0.3),
		BackgroundColor3 = theme.color.panel,
		BackgroundTransparency = theme.transparency.panel,
		AutoButtonColor = false,
		Text = "",
		SelectionImageObject = selection_ring,
	})
	table.insert(props, corner(theme.radius.button))
	table.insert(props, ui.gradient(theme.gradient.shade))
	table.insert(props, ui.square())
	table.insert(props, ui.icon {
		Name = "image",
		Image = image,
		ImageColor3 = theme.color.icon,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.5),
	})
	local button = create "TextButton" (props)
	bind_states(button, button)
	return button
end


-- reserve "primary" for the one main action on a screen (buy, play, confirm): game ui guides and
-- roblox's adaptive design guide both say the accent should point at the key action only
function ui.button(props)
	local text = take(props, "text")
	local style = button_styles[take(props, "style") or "secondary"] or button_styles.secondary
	local disabled = take(props, "disabled")

	-- disabled can be a bool or a vide source
	local function when_disabled(on, off)
		if type(disabled) == "function" then
			return function()
				return if disabled() then on else off
			end
		end
		return if disabled then on else off
	end

	local fill_transparency = style.transparency
	if fill_transparency < 1 then
		fill_transparency = when_disabled(theme.disabled.transparency, style.transparency)
	end

	defaults(props, {
		Size = UDim2.fromScale(0.2, 0.08),
		BackgroundColor3 = style.fill,
		BackgroundTransparency = fill_transparency,
		AutoButtonColor = false,
		Interactable = when_disabled(false, true),
		Text = "",
		SelectionImageObject = selection_ring,
	})
	table.insert(props, corner(theme.radius.pill))
	table.insert(props, ui.gradient(style.gradient))
	table.insert(props, ui.text {
		Name = "label",
		Text = text,
		style = "title",
		TextColor3 = style.text,
		TextTransparency = when_disabled(theme.disabled.transparency, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.46),
	})
	local button = create "TextButton" (props)
	-- ghost buttons have no fill to lighten, so they only get the label color
	if style.transparency < 1 then
		bind_states(button, button, style.hover)
	end
	return button
end

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
