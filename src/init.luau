-- vide building blocks. every function takes a vide props table (children go in the array part)
-- and returns an instance. extra keys like gap / align / style are read and removed before create.
--
-- ui.panel / ui.card / ui.pill / ui.box      frames
-- ui.text "hi" / ui.text { style = "title" | "dim" | "faint", align = "left" | "center" | "right" }
-- ui.input { PlaceholderText = "Search" }    textbox
-- ui.icon { Image = id }                     square image
-- ui.row / ui.column { gap = 0.02, align = "center", cross = "center", fill = true }   gap = scale
-- ui.list_layout { direction = "row" | "column", gap, align, cross, fill }   layout only
-- ui.scroll_grid { cell = 0.155, gap_x = 0.0135, gap_y = 0.0135 }   square cells, all scale
-- ui.tab { Name, text, active }              pill tab with "label" + "button"
-- ui.icon_button { Name, image }             square button with "image"
-- ui.hit { hover = true }                    invisible full-size "button" (hover lightens parent)
-- ui.square(ratio?) / ui.padding(x, y?)      constraints, padding is scale per axis
-- everything is scale (user rule): no px offsets, no text size px limits
-- ui.pop(gui, from?) / ui.pop_on(gui, property, from?, watch?)   scale-in animation (now / on change)
-- ui.gradient(colors, rotation?)             UIGradient from a color list, 90 = top to bottom
--   multiplies the parent color (white base = exact colors), tints only its parent not children,
--   inside a UIStroke it colors the border

-- SERVICES -------------------------

local TweenService = game:GetService("TweenService")


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

function ui.gradient(colors: { Color3 }, rotation: number?)
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
local function bind_states(button: GuiButton, target: GuiObject?)
	local base_color

	local function tween_to(color)
		local frame = target or button.Parent :: GuiObject
		TweenService:Create(frame, state_tween, { BackgroundColor3 = color }):Play()
	end

	button.MouseEnter:Connect(function()
		local frame = target or button.Parent :: GuiObject
		base_color = base_color or frame.BackgroundColor3
		tween_to(theme.color.card_hover)
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
		tween_to(theme.color.card_hover)
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
function ui.hit(props)
	local button = create "ImageButton" {
		Name = "button",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ZIndex = 2,
	}
	if props and props.hover then
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
function ui.scroll_grid(props)
	local cell = take(props, "cell") or 0.2
	local gap_x = take(props, "gap_x") or 0.0135
	local gap_y = take(props, "gap_y") or gap_x

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
		ui.square(),
	})
	return create "ScrollingFrame" (props)
end

function ui.tab(props)
	local text = take(props, "text")
	local active = take(props, "active")

	defaults(props, {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = active and 0 or 1,
		BorderSizePixel = 0,
	})
	table.insert(props, corner(theme.radius.pill))
	table.insert(props, ui.gradient(theme.gradient.tab))
	table.insert(props, ui.text {
		Name = "label",
		Text = text,
		style = "title",
		TextColor3 = active and theme.color.text or theme.color.text_dim,
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


-- MAIN -------------------------

return ui
