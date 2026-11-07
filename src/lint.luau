-- checks a gui tree against bright's sizing rules (RULES.md): scale instead of offset, scaled strokes,
-- scaled text, one layout UIScale per window. works anywhere:
--   studio command bar: print(require(game.ReplicatedStorage.Packages.bright).lint(game.StarterGui.MyGui))
--   sim/ runs it on every snapshot and lists the problems in the viewer
-- rules: scale size / position / padding, scaled stroke / text, one ui scale, one scale per instance
-- returns { { path, rule, level = "fail" | "warn", message } }

-- VARIABLES -------------------------

-- UIScales bright uses for hover / press / pop animation, they are not layout scaling
local ANIMATION_SCALES = { press_scale = true, pop_scale = true, presence_scale = true }

local TEXT_CLASSES = { "TextLabel", "TextButton", "TextBox" }

-- FUNCTIONS -------------------------

local function path_of(instance: Instance, root: Instance): string
	local parts = {}
	local node: Instance? = instance
	while node and node ~= root.Parent do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

local function udim2_text(value: UDim2): string
	return `\{{value.X.Scale}, {value.X.Offset}\}, \{{value.Y.Scale}, {value.Y.Offset}\}`
end

local function has_offset(value: UDim2): boolean
	return value.X.Offset ~= 0 or value.Y.Offset ~= 0
end

local function is_text(instance: Instance): boolean
	for _, class in TEXT_CLASSES do
		if instance:IsA(class) then return true end
	end
	return false
end

-- a layout scale above this one multiplies with it
local function layout_scale_above(instance: Instance): Instance?
	local node = instance.Parent and instance.Parent.Parent
	while node do
		for _, child in node:GetChildren() do
			if child:IsA("UIScale") and not ANIMATION_SCALES[child.Name] then
				return child
			end
		end
		node = node.Parent
	end
	return nil
end

local function lint(root: Instance)
	local problems = {}

	local function add(instance: Instance, level: "fail" | "warn", rule: string, message: string)
		table.insert(problems, { path = path_of(instance, root), level = level, rule = rule, message = message })
	end

	local function check(instance: Instance)
		local parent = instance.Parent

		-- roblox applies only one UIScale per object, whatever the names, so extra ones silently do nothing
		local scales = {}
		for _, child in instance:GetChildren() do
			if child:IsA("UIScale") then table.insert(scales, child.Name) end
		end
		if #scales > 1 then
			add(instance, "fail", "one scale per instance", `{#scales} UIScales ({table.concat(scales, ", ")}), only one applies: wrap the content in a frame and put the second scale there`)
		end

		if instance:IsA("GuiObject") then
			-- a layout in the parent decides position (list / grid) and size (grid), so those are ignored
			local layout = parent and parent:FindFirstChildWhichIsA("UIGridStyleLayout")
			local in_grid = layout ~= nil and layout:IsA("UIGridLayout")
			if not in_grid and has_offset(instance.Size) then
				add(instance, "fail", "scale size", `Size {udim2_text(instance.Size)} has a px offset, use scale (+ UIAspectRatioConstraint to keep a shape)`)
			end
			if layout == nil and has_offset(instance.Position) then
				add(instance, "fail", "scale position", `Position {udim2_text(instance.Position)} has a px offset, use scale`)
			end
			if instance.BorderSizePixel > 0 and instance.BackgroundTransparency < 1 then
				add(instance, "warn", "scaled stroke", `BorderSizePixel {instance.BorderSizePixel} is px, set it to 0 and outline with a ScaledSize UIStroke`)
			end
			if is_text(instance) then
				local text = (instance :: any).Text
				local placeholder = if instance:IsA("TextBox") then (instance :: any).PlaceholderText else ""
				if not (instance :: any).TextScaled and (text ~= "" or placeholder ~= "") then
					add(instance, "fail", "scaled text", `TextScaled is off (TextSize {(instance :: any).TextSize}px), turn it on and size the label box instead`)
				end
			end
			if instance:IsA("ScrollingFrame") and instance.ScrollBarThickness > 0 then
				add(instance, "warn", "scale size", `ScrollBarThickness {instance.ScrollBarThickness} is px, use 0`)
			end
		elseif instance:IsA("UIPadding") then
			for _, side in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do
				local value: UDim = (instance :: any)[side]
				if value.Offset ~= 0 then
					add(instance, "fail", "scale padding", `{side} has {value.Offset}px offset, use scale (ui.pad / ui.padding)`)
				end
			end
		elseif instance:IsA("UIListLayout") then
			if instance.Padding.Offset ~= 0 then
				add(instance, "fail", "scale padding", `list Padding has {instance.Padding.Offset}px offset, use scale (gap = 0.02)`)
			end
		elseif instance:IsA("UIGridLayout") then
			if has_offset(instance.CellSize) then
				add(instance, "fail", "scale size", `CellSize {udim2_text(instance.CellSize)} has a px offset, use scale (scroll_grid columns)`)
			end
			if has_offset(instance.CellPadding) then
				add(instance, "fail", "scale padding", `CellPadding {udim2_text(instance.CellPadding)} has a px offset, use scale`)
			end
		elseif instance:IsA("UICorner") then
			if instance.CornerRadius.Offset ~= 0 then
				add(instance, "fail", "scale size", `CornerRadius has {instance.CornerRadius.Offset}px offset, use scale (0.5 = round)`)
			end
		elseif instance:IsA("UIStroke") then
			if instance.StrokeSizingMode ~= Enum.StrokeSizingMode.ScaledSize then
				add(instance, "fail", "scaled stroke", `Thickness {instance.Thickness} is px, set StrokeSizingMode ScaledSize (thickness = share of the short side)`)
			elseif instance.Thickness > 0.25 then
				add(instance, "warn", "scaled stroke", `Thickness {instance.Thickness} is over a quarter of the short side`)
			end
			-- Contextual on a TextButton outlines its text, and these buttons keep their label in a child
			if parent and parent:IsA("TextButton") and (parent :: any).Text == "" and instance.ApplyStrokeMode ~= Enum.ApplyStrokeMode.Border then
				add(instance, "fail", "scaled stroke", "ApplyStrokeMode Contextual on a TextButton with no text outlines nothing, set Border")
			end
		elseif instance:IsA("UITextSizeConstraint") then
			add(instance, "fail", "scaled text", "UITextSizeConstraint is px, size the label box instead")
		elseif instance:IsA("UISizeConstraint") then
			local max = instance.MaxSize
			if instance.MinSize.X > 0 or instance.MinSize.Y > 0 or max.X < math.huge or max.Y < math.huge then
				add(instance, "fail", "scale size", "UISizeConstraint limits are px, use UIAspectRatioConstraint or ui.adaptive")
			end
		elseif instance:IsA("UIScale") and not ANIMATION_SCALES[instance.Name] then
			local above = layout_scale_above(instance)
			if above then
				add(instance, "warn", "one ui scale", `multiplies with {path_of(above, root)}, keep one layout UIScale per window (ui.adaptive)`)
			end
			if instance.Scale < 0.5 or instance.Scale > 2 then
				add(instance, "warn", "one ui scale", `Scale {instance.Scale} is extreme, resize the layout instead`)
			end
		end
	end

	check(root)
	for _, descendant in root:GetDescendants() do
		check(descendant)
	end
	return problems
end


-- MAIN -------------------------

return lint
