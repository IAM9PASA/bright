-- fake roblox for the ui simulator. run by sim/run.mjs, never shipped in the package.
-- builds just enough of the engine (instances, datatypes, Enum, services, task) to run vide + bright
-- outside studio, then prints the gui tree as json for sim/view.html to draw.
--
-- run.mjs prepends a global SIM = { modules = { { path, source } }, main = { name, source }, viewport = { x, y } }

-- VARIABLES -------------------------

local SIM = SIM
local JSON_MARK = "\u{1}SIMJSON\u{1}"

local builtin_typeof = typeof
local env = {} -- globals every module and example sees

-- FUNCTIONS -------------------------

local function make_type(name: string, fields)
	fields.__type = name
	fields.__index = fields.__index or fields
	return fields
end

local function typeof(value)
	local meta = (type(value) == "table" or type(value) == "userdata") and getmetatable(value)
	if type(meta) == "table" and meta.__type then
		return meta.__type
	end
	return builtin_typeof(value)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- DATATYPES -------------------------

-- roblox values are userdata, and vide relies on that: a plain table in props means "nested props".
-- every value is a newproxy with a copy of its type's metatable, fields live in a weak store
local function proxy(template)
	local value = newproxy(true)
	local meta = getmetatable(value)
	for key, field in template do meta[key] = field end
	return value
end

local function datatype(name: string, getter: ((fields: any, key: string) -> any)?)
	local meta = {}
	local store = setmetatable({}, { __mode = "k" })
	local methods = {}
	meta.__type = name
	meta.__index = function(value, key)
		local fields = store[value]
		local field = fields[key]
		if field ~= nil then return field end
		if getter then
			field = getter(fields, key)
			if field ~= nil then return field end
		end
		local method = methods[key]
		if method == nil then error(`{key} is not a valid member of {name}`, 2) end
		return method
	end
	meta.__newindex = function(_, key) error(`{key} cannot be assigned to`, 2) end
	meta.__tostring = function() return name end
	local function new(fields)
		local value = proxy(meta)
		store[value] = fields
		return value
	end
	return meta, methods, new
end

local Color3 = {}
local Color3_meta, Color3_methods, new_color3 = datatype("Color3")
Color3_meta.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
Color3_meta.__tostring = function(self) return `{self.R}, {self.G}, {self.B}` end
function Color3.new(r, g, b) return new_color3({ R = r or 0, G = g or 0, B = b or 0 }) end
function Color3.fromRGB(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHex(hex: string)
	hex = hex:gsub("#", "")
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	local k = i % 6
	if k == 0 then return Color3.new(v, t, p) elseif k == 1 then return Color3.new(q, v, p)
	elseif k == 2 then return Color3.new(p, v, t) elseif k == 3 then return Color3.new(p, q, v)
	elseif k == 4 then return Color3.new(t, p, v) end
	return Color3.new(v, p, q)
end
function Color3_methods.Lerp(a, b, t) return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t)) end
function Color3_methods.ToHex(c)
	return string.format("%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end
function Color3_methods.ToHSV(c)
	local r, g, b = c.R, c.G, c.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local d = max - min
	local h = 0
	if d > 0 then
		if max == r then h = ((g - b) / d) % 6 elseif max == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h /= 6
	end
	return h, max == 0 and 0 or d / max, max
end

local UDim = {}
local UDim_meta, _, new_udim = datatype("UDim")
UDim_meta.__add = function(a, b) return UDim.new(a.Scale + b.Scale, a.Offset + b.Offset) end
UDim_meta.__sub = function(a, b) return UDim.new(a.Scale - b.Scale, a.Offset - b.Offset) end
UDim_meta.__eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end
function UDim.new(scale, offset) return new_udim({ Scale = scale or 0, Offset = offset or 0 }) end

local UDim2 = {}
local UDim2_meta, UDim2_methods, new_udim2 = datatype("UDim2", function(fields, key)
	if key == "Width" then return fields.X end
	if key == "Height" then return fields.Y end
	return nil
end)
UDim2_meta.__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
UDim2_meta.__sub = function(a, b) return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end
UDim2_meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
function UDim2.new(xs, xo, ys, yo)
	if typeof(xs) == "UDim" then
		return new_udim2({ X = xs, Y = xo })
	end
	return new_udim2({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) })
end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2_methods.Lerp(a, b, t)
	return UDim2.new(lerp(a.X.Scale, b.X.Scale, t), lerp(a.X.Offset, b.X.Offset, t), lerp(a.Y.Scale, b.Y.Scale, t), lerp(a.Y.Offset, b.Y.Offset, t))
end

local Vector2 = {}
local Vector2_meta, Vector2_methods, new_vector2 = datatype("Vector2", function(fields, key)
	if key == "Magnitude" then return math.sqrt(fields.X ^ 2 + fields.Y ^ 2) end
	return nil
end)
Vector2_meta.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2_meta.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2_meta.__mul = function(a, b)
	if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2_meta.__div = function(a, b)
	if type(b) == "number" then return Vector2.new(a.X / b, a.Y / b) end
	return Vector2.new(a.X / b.X, a.Y / b.Y)
end
Vector2_meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
function Vector2.new(x, y) return new_vector2({ X = x or 0, Y = y or 0 }) end
function Vector2_methods.Lerp(a, b, t) return Vector2.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t)) end
Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

local Vector3 = {}
local _, _, new_vector3 = datatype("Vector3")
function Vector3.new(x, y, z) return new_vector3({ X = x or 0, Y = y or 0, Z = z or 0 }) end
Vector3.zero = Vector3.new()
Vector3.one = Vector3.new(1, 1, 1)

-- only here so vide's aggregate table can index .new
local _, _, new_cframe = datatype("CFrame")
local CFrame = { new = function() return new_cframe({}) end }

local Rect = {}
local _, _, new_rect = datatype("Rect")
function Rect.new(a, b, c, d)
	if typeof(a) == "Vector2" then return new_rect({ Min = a, Max = b }) end
	return new_rect({ Min = Vector2.new(a, b), Max = Vector2.new(c, d) })
end

local ColorSequenceKeypoint = {}
local _, _, new_color_keypoint = datatype("ColorSequenceKeypoint")
function ColorSequenceKeypoint.new(time, value) return new_color_keypoint({ Time = time, Value = value }) end

local ColorSequence = {}
local _, _, new_color_sequence = datatype("ColorSequence")
function ColorSequence.new(a, b)
	local keypoints
	if typeof(a) == "Color3" then
		keypoints = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a) }
	else
		keypoints = a
		-- same rules roblox enforces, so a bad gradient fails here too
		assert(#keypoints >= 2, "ColorSequence: requires at least 2 keypoints")
		assert(keypoints[1].Time == 0 and keypoints[#keypoints].Time == 1, "ColorSequence: must start at time 0 and end at time 1")
		for i, keypoint in keypoints do
			assert(keypoint.Time == keypoint.Time, `ColorSequence: keypoint {i} time is NaN`)
		end
	end
	return new_color_sequence({ Keypoints = keypoints })
end

local NumberSequenceKeypoint = {}
local _, _, new_number_keypoint = datatype("NumberSequenceKeypoint")
function NumberSequenceKeypoint.new(time, value, envelope)
	return new_number_keypoint({ Time = time, Value = value, Envelope = envelope or 0 })
end

local NumberSequence = {}
local _, _, new_number_sequence = datatype("NumberSequence")
function NumberSequence.new(a, b)
	local keypoints
	if type(a) == "number" then
		keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) }
	else
		keypoints = a
	end
	return new_number_sequence({ Keypoints = keypoints })
end

local NumberRange = {}
local _, _, new_number_range = datatype("NumberRange")
function NumberRange.new(min, max) return new_number_range({ Min = min, Max = max or min }) end

local TweenInfo = {}
local _, _, new_tween_info = datatype("TweenInfo")
function TweenInfo.new(time, style, direction, repeats, reverses, delay)
	return new_tween_info({
		Time = time or 1, EasingStyle = style or "Quad", EasingDirection = direction or "Out",
		RepeatCount = repeats or 0, Reverses = reverses or false, DelayTime = delay or 0,
	})
end

-- every Enum.X.Y exists and items are cached so == works. enums listed in KNOWN are checked like
-- roblox does, so a typo such as FontWeight.Black errors here instead of in the game
local KNOWN_ENUMS = {
	FontWeight = { "Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Heavy" },
	FontStyle = { "Normal", "Italic" },
	ApplyStrokeMode = { "Contextual", "Border" },
	StrokeSizingMode = { "FixedSize", "ScaledSize" },
	LineJoinMode = { "Round", "Bevel", "Miter" },
	AspectType = { "FitWithinMaxSize", "ScaleWithParentSize" },
	DominantAxis = { "Width", "Height" },
	ScaleType = { "Stretch", "Slice", "Tile", "Fit", "Crop" },
	TextXAlignment = { "Left", "Center", "Right" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	FillDirection = { "Horizontal", "Vertical" },
	HorizontalAlignment = { "Center", "Left", "Right" },
	VerticalAlignment = { "Center", "Top", "Bottom" },
	EasingStyle = { "Linear", "Sine", "Back", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Cubic" },
	EasingDirection = { "In", "Out", "InOut" },
}
local Enum
do
	local item_meta, _, new_item = datatype("EnumItem")
	item_meta.__tostring = function(self) return `Enum.{self.EnumType}.{self.Name}` end
	local enum_meta = make_type("Enum", {})
	enum_meta.__index = function(self, name)
		local known = KNOWN_ENUMS[rawget(self, "__name")]
		if known and not table.find(known, name) then
			error(`{name} is not a valid member of "Enum.{rawget(self, "__name")}"`, 2)
		end
		local item = new_item({ Name = name, EnumType = rawget(self, "__name"), Value = 0 })
		rawset(self, name, item)
		return item
	end
	Enum = setmetatable({}, {
		__index = function(self, name)
			local enum = setmetatable({ __name = name }, enum_meta)
			rawset(self, name, enum)
			return enum
		end,
	})
end

local Font = {}
local _, _, new_font = datatype("Font")
function Font.new(family, weight, style)
	return new_font({ Family = family, Weight = weight or Enum.FontWeight.Regular, Style = style or Enum.FontStyle.Normal })
end
function Font.fromEnum(font) return Font.new(`rbxasset://fonts/families/{font.Name}.json`) end
function Font.fromName(name, weight, style) return Font.new(`rbxasset://fonts/families/{name}.json`, weight, style) end

-- SIGNALS -------------------------

local task_resume

local Connection_meta = make_type("RBXScriptConnection", {})
function Connection_meta.Disconnect(self)
	self.Connected = false
	local list = self._signal._list
	local index = table.find(list, self)
	if index then table.remove(list, index) end
end

local Signal_meta = make_type("RBXScriptSignal", {})
local function new_signal() return setmetatable({ _list = {} }, Signal_meta) end
function Signal_meta.Connect(self, callback)
	local connection = setmetatable({ Connected = true, _signal = self, _callback = callback }, Connection_meta)
	table.insert(self._list, connection)
	return connection
end
function Signal_meta.Once(self, callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end
function Signal_meta.Fire(self, ...)
	for _, connection in table.clone(self._list) do
		if connection.Connected then
			local ok, err = pcall(connection._callback, ...)
			if not ok then print(`[sim] error in event handler: {err}`) end
		end
	end
end
function Signal_meta.Wait(self)
	local thread = coroutine.running()
	self:Once(function(...) task_resume(thread, ...) end)
	return coroutine.yield()
end

-- TASK -------------------------

local clock = 0
local deferred = {}
local delayed = {}

function task_resume(thread, ...)
	local ok, err = coroutine.resume(thread, ...)
	if not ok then print(`[sim] error: {err}\n{debug.traceback(thread)}`) end
end

local task = {}
function task.spawn(callback, ...)
	local thread = type(callback) == "thread" and callback or coroutine.create(callback)
	task_resume(thread, ...)
	return thread
end
function task.defer(callback, ...)
	local thread = type(callback) == "thread" and callback or coroutine.create(callback)
	table.insert(deferred, { thread, table.pack(...) })
	return thread
end
function task.delay(seconds, callback, ...)
	local thread = type(callback) == "thread" and callback or coroutine.create(callback)
	table.insert(delayed, { clock + (seconds or 0), thread, table.pack(...) })
	return thread
end
function task.wait(seconds)
	local start = clock
	table.insert(delayed, { clock + (seconds or 0), coroutine.running(), table.pack() })
	coroutine.yield()
	return clock - start
end
function task.cancel(thread)
	for i = #deferred, 1, -1 do if deferred[i][1] == thread then table.remove(deferred, i) end end
	for i = #delayed, 1, -1 do if delayed[i][2] == thread then table.remove(delayed, i) end end
end

local function flush_deferred()
	for _ = 1, 100 do
		if #deferred == 0 then return end
		local queue = deferred
		deferred = {}
		for _, entry in queue do
			task_resume(entry[1], table.unpack(entry[2], 1, entry[2].n))
		end
	end
end

-- INSTANCES -------------------------

local is_a = {
	GuiObject = { "Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame", "CanvasGroup", "ViewportFrame", "VideoFrame" },
	GuiButton = { "TextButton", "ImageButton" },
	LayerCollector = { "ScreenGui", "SurfaceGui", "BillboardGui" },
	UIComponent = { "UICorner", "UIGradient", "UIStroke", "UIPadding", "UIScale", "UIListLayout", "UIGridLayout", "UIAspectRatioConstraint", "UISizeConstraint", "UITextSizeConstraint", "UIFlexItem", "UIPageLayout", "UITableLayout" },
	UIGridStyleLayout = { "UIListLayout", "UIGridLayout", "UIPageLayout", "UITableLayout" },
	UIConstraint = { "UIAspectRatioConstraint", "UISizeConstraint", "UITextSizeConstraint" },
}
is_a.GuiBase2d = table.clone(is_a.GuiObject)
for _, class in is_a.LayerCollector do table.insert(is_a.GuiBase2d, class) end
is_a.GuiBase = is_a.GuiBase2d
is_a.LuaSourceContainer = { "ModuleScript", "LocalScript", "Script" }

local events = {}
for _, name in {
	"MouseEnter", "MouseLeave", "MouseMoved", "MouseWheelForward", "MouseWheelBackward",
	"MouseButton1Down", "MouseButton1Up", "MouseButton1Click", "MouseButton2Down", "MouseButton2Up", "MouseButton2Click",
	"Activated", "InputBegan", "InputEnded", "InputChanged", "TouchTap", "TouchLongPress",
	"FocusLost", "Focused", "ReturnPressedFromOnScreenKeyboard", "SelectionGained", "SelectionLost",
	"Changed", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "AncestryChanged", "Destroying",
	"Completed", "Heartbeat", "RenderStepped", "Stepped", "PreRender", "PostSimulation",
	"PlayerAdded", "PlayerRemoving", "LastInputTypeChanged", "TextBoxFocused", "TextBoxFocusReleased",
} do
	events[name] = true
end

local white, black = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local zero_udim2 = UDim2.new()

-- read before anything is set, so typeof(instance[prop]) works for vide's aggregate and event checks
local property_defaults = {
	Size = UDim2.fromOffset(100, 100), Position = zero_udim2, AnchorPoint = Vector2.zero, Rotation = 0,
	BackgroundColor3 = Color3.fromRGB(163, 162, 165), BackgroundTransparency = 0,
	BorderColor3 = Color3.fromRGB(27, 42, 53), BorderSizePixel = 1,
	Visible = true, ZIndex = 1, LayoutOrder = 0, ClipsDescendants = false, Active = false, Interactable = true,
	AutomaticSize = Enum.AutomaticSize.None, SelectionOrder = 0, Selectable = false,
	Text = "Label", TextColor3 = Color3.fromRGB(27, 42, 53), TextSize = 14, TextScaled = false, TextWrapped = false,
	TextTransparency = 0, TextStrokeTransparency = 1, TextStrokeColor3 = black, RichText = false,
	TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
	TextTruncate = Enum.TextTruncate.None, LineHeight = 1, MaxVisibleGraphemes = -1,
	Font = Enum.Font.Legacy, FontFace = Font.new("rbxasset://fonts/families/LegacyArial.json"),
	PlaceholderText = "", PlaceholderColor3 = Color3.fromRGB(178, 178, 178), ClearTextOnFocus = true,
	MultiLine = false, TextEditable = true, CursorPosition = 1,
	Image = "", ImageColor3 = white, ImageTransparency = 0, ScaleType = Enum.ScaleType.Stretch,
	TileSize = UDim2.fromScale(1, 1), ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero, SliceCenter = Rect.new(0, 0, 0, 0), SliceScale = 1,
	HoverImage = "", PressedImage = "",
	AutoButtonColor = true, Modal = false, Selected = false,
	CanvasSize = UDim2.new(0, 0, 2, 0), CanvasPosition = Vector2.zero, AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollBarThickness = 12, ScrollBarImageColor3 = white, ScrollBarImageTransparency = 0,
	ScrollingDirection = Enum.ScrollingDirection.XY, ScrollingEnabled = true,
	VerticalScrollBarInset = Enum.ScrollBarInset.None, HorizontalScrollBarInset = Enum.ScrollBarInset.None,
	GroupTransparency = 0, GroupColor3 = white,
	-- ScreenGui
	Enabled = true, DisplayOrder = 0, IgnoreGuiInset = false, ResetOnSpawn = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	-- components
	CornerRadius = UDim.new(0, 8),
	Color = white, Transparency = 0, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Round,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
	Offset = Vector2.zero,
	PaddingLeft = UDim.new(), PaddingRight = UDim.new(), PaddingTop = UDim.new(), PaddingBottom = UDim.new(),
	Scale = 1,
	FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.Name, Padding = UDim.new(),
	HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top,
	HorizontalFlex = Enum.UIFlexAlignment.None, VerticalFlex = Enum.UIFlexAlignment.None, Wraps = false,
	ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
	CellSize = UDim2.fromOffset(100, 100), CellPadding = UDim2.fromOffset(5, 5),
	FillDirectionMaxCells = 0, StartCorner = Enum.StartCorner.TopLeft,
	AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize, DominantAxis = Enum.DominantAxis.Width,
	MinSize = Vector2.zero, MaxSize = Vector2.new(math.huge, math.huge), MinTextSize = 1, MaxTextSize = 100,
	FlexMode = Enum.UIFlexMode.None, GrowRatio = 0, ShrinkRatio = 0,
}
local class_defaults = {
	UIGradient = { Color = ColorSequence.new(white), Transparency = NumberSequence.new(0), Rotation = 0 },
	UIStroke = { Color = black },
	TextBox = { Text = "TextBox", Size = UDim2.fromOffset(200, 50) },
	TextLabel = { Size = UDim2.fromOffset(200, 50) },
	TextButton = { Text = "Button", Size = UDim2.fromOffset(200, 50) },
	ImageButton = {},
}
-- per class so a Color3 read off a UIGradient is a ColorSequence and off a UIStroke a Color3
local class_props = { UIGradient = { Transparency = true } }

local Instance = {}
local instance_meta = make_type("Instance", {})
local methods = {}
local internals = setmetatable({}, { __mode = "k" }) -- instance -> { class, props, children, parent, signals, changed }
local services = {}

local function get(self)
	return internals[self]
end

local function class_is_a(class, name)
	if class == name or name == "Instance" then return true end
	local list = is_a[name]
	return list ~= nil and table.find(list, class) ~= nil
end

instance_meta.__index = function(self, key)
	local data = get(self)
	if key == "Name" then return data.props.Name or data.class end
	if key == "ClassName" then return data.class end
	if key == "Parent" then return data.parent end
	if key == "AbsoluteSize" and data.absolute_size then return data.absolute_size end
	local method = methods[key]
	if method then return method end
	local value = data.props[key]
	if value ~= nil then return value end
	if events[key] then
		local signal = data.signals[key]
		if not signal then
			signal = new_signal()
			data.signals[key] = signal
		end
		return signal
	end
	-- real properties win over children with the same name, like in roblox
	local by_class = class_defaults[data.class]
	if by_class and by_class[key] ~= nil then return by_class[key] end
	if property_defaults[key] ~= nil and not (class_props[data.class] and class_props[data.class][key]) then
		return property_defaults[key]
	end
	return methods.FindFirstChild(self, key)
end

instance_meta.__newindex = function(self, key, value)
	local data = get(self)
	if key == "Parent" then
		if data.destroyed then error(`The Parent property of {self.Name} is locked`, 2) end
		local old = data.parent
		if old == value then return end
		if value == self then error("attempt to set parent to self", 2) end
		if old then
			local siblings = get(old).children
			local index = table.find(siblings, self)
			if index then table.remove(siblings, index) end
			if get(old).signals.ChildRemoved then get(old).signals.ChildRemoved:Fire(self) end
		end
		data.parent = value
		if value then
			table.insert(get(value).children, self)
			if get(value).signals.ChildAdded then get(value).signals.ChildAdded:Fire(self) end
		end
		if data.signals.AncestryChanged then data.signals.AncestryChanged:Fire(self, value) end
		return
	end
	if key == "ClassName" then error("ClassName is read only", 2) end
	if events[key] then error(`{key} is an event, use :Connect`, 2) end
	if data.props[key] == value then return end
	data.props[key] = value
	local changed = data.changed[key]
	if changed then changed:Fire() end
	if data.signals.Changed then data.signals.Changed:Fire(key) end
end

instance_meta.__tostring = function(self) return self.Name end

function Instance.new(class: string, parent)
	assert(type(class) == "string", "Instance.new expects a class name")
	local self = proxy(instance_meta)
	internals[self] = { class = class, props = {}, children = {}, signals = {}, changed = {}, attributes = {} }
	if parent then self.Parent = parent end
	return self
end

function methods.IsA(self, name) return class_is_a(get(self).class, name) end
function methods.GetChildren(self) return table.clone(get(self).children) end
function methods.GetDescendants(self)
	local out = {}
	local function walk(node)
		for _, child in get(node).children do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function methods.FindFirstChild(self, name, recursive)
	for _, child in get(self).children do
		if child.Name == name then return child end
	end
	if recursive then
		for _, child in get(self).children do
			local found = methods.FindFirstChild(child, name, true)
			if found then return found end
		end
	end
	return nil
end
function methods.WaitForChild(self, name)
	local child = methods.FindFirstChild(self, name)
	if not child then print(`[sim] WaitForChild("{name}") on {self:GetFullName()} would wait forever`) end
	return child
end
function methods.FindFirstChildOfClass(self, class)
	for _, child in get(self).children do
		if get(child).class == class then return child end
	end
	return nil
end
function methods.FindFirstChildWhichIsA(self, class, recursive)
	for _, child in (recursive and methods.GetDescendants(self) or get(self).children) do
		if child:IsA(class) then return child end
	end
	return nil
end
function methods.FindFirstAncestor(self, name)
	local node = get(self).parent
	while node and node.Name ~= name do node = get(node).parent end
	return node
end
function methods.FindFirstAncestorWhichIsA(self, class)
	local node = get(self).parent
	while node and not node:IsA(class) do node = get(node).parent end
	return node
end
function methods.IsDescendantOf(self, ancestor)
	local node = get(self).parent
	while node do
		if node == ancestor then return true end
		node = get(node).parent
	end
	return false
end
function methods.IsAncestorOf(self, descendant) return methods.IsDescendantOf(descendant, self) end
function methods.GetFullName(self)
	local parts = {}
	local node = self
	while node and node ~= env.game do
		table.insert(parts, 1, node.Name)
		node = get(node).parent
	end
	return table.concat(parts, ".")
end
function methods.GetPropertyChangedSignal(self, property)
	local data = get(self)
	local signal = data.changed[property]
	if not signal then
		signal = new_signal()
		data.changed[property] = signal
	end
	return signal
end
function methods.ClearAllChildren(self)
	for _, child in methods.GetChildren(self) do child:Destroy() end
end
function methods.Destroy(self)
	local data = get(self)
	if data.destroyed then return end
	if data.signals.Destroying then data.signals.Destroying:Fire() end
	for _, child in methods.GetChildren(self) do child:Destroy() end
	self.Parent = nil
	data.destroyed = true
end
function methods.Clone(self)
	local data = get(self)
	local copy = Instance.new(data.class)
	local copy_data = get(copy)
	for key, value in data.props do copy_data.props[key] = value end
	for key, value in data.attributes do copy_data.attributes[key] = value end
	copy_data.source = data.source
	for _, child in data.children do
		child:Clone().Parent = copy
	end
	return copy
end
function methods.SetAttribute(self, key, value) get(self).attributes[key] = value end
function methods.GetAttribute(self, key) return get(self).attributes[key] end
function methods.GetAttributes(self) return table.clone(get(self).attributes) end
function methods.GetAttributeChangedSignal(self, key) return methods.GetPropertyChangedSignal(self, "@" .. key) end
function methods.GetService(self, name)
	local service = services[name]
	if not service then
		service = Instance.new(name)
		get(service).props.Name = name
		services[name] = service
		service.Parent = self
	end
	return service
end
methods.FindService = methods.GetService

-- services carry a few extra methods / fields
local service_methods = {}
local base_index = instance_meta.__index
instance_meta.__index = function(self, key)
	local extra = service_methods[get(self).class]
	if extra and extra[key] ~= nil then
		local value = extra[key]
		if type(value) == "function" and key:sub(1, 1) == "_" then return value(self) end
		return value
	end
	return base_index(self, key)
end

-- SERVICES -------------------------

local game = Instance.new("DataModel")
get(game).props.Name = "Game"
env.game = game

local Tween_meta = make_type("Instance", {})
Tween_meta.__index = Tween_meta
function Tween_meta.Play(self)
	-- the sim is a snapshot, so tweens land on their goal right away
	for property, value in self._goals do
		self._target[property] = value
	end
	self.PlaybackState = Enum.PlaybackState.Completed
	self.Completed:Fire(Enum.PlaybackState.Completed)
end
function Tween_meta.Cancel(self) self.PlaybackState = Enum.PlaybackState.Cancelled end
function Tween_meta.Pause(self) self.PlaybackState = Enum.PlaybackState.Paused end
function Tween_meta.Destroy() end

service_methods.TweenService = {
	Create = function(_, target, info, goals)
		return setmetatable({
			_target = target, _goals = goals, TweenInfo = info, Instance = target,
			PlaybackState = Enum.PlaybackState.Begin, Completed = new_signal(),
		}, Tween_meta)
	end,
	GetValue = function(_, alpha) return alpha end,
}
service_methods.RunService = {
	IsStudio = function() return false end,
	IsClient = function() return true end,
	IsServer = function() return false end,
	IsRunning = function() return true end,
	BindToRenderStep = function(_, _, _, callback) service_methods.RunService._render_steps[callback] = true end,
	UnbindFromRenderStep = function() end,
	_render_steps = {},
}
service_methods.UserInputService = {
	TouchEnabled = false, KeyboardEnabled = true, MouseEnabled = true, GamepadEnabled = false,
	GetLastInputType = function() return Enum.UserInputType.MouseButton1 end,
	GetMouseLocation = function() return Vector2.zero end,
	IsKeyDown = function() return false end,
	GetFocusedTextBox = function() return nil end,
}
service_methods.GuiService = {
	GetGuiInset = function() return Vector2.new(0, 58), Vector2.zero end,
	TopbarInset = Rect.new(0, 0, 0, 58),
	SelectedObject = nil,
}
service_methods.HttpService = {
	GenerateGUID = function(_, braces)
		local id = string.gsub("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx", "[xy]", function(c)
			return string.format("%X", c == "x" and math.random(0, 15) or math.random(8, 11))
		end)
		return braces == false and id or `\{{id}\}`
	end,
}
service_methods.ContentProvider = { PreloadAsync = function() end }
service_methods.SoundService = { PlayLocalSound = function() end }

local players = game:GetService("Players")
local local_player = Instance.new("Player")
local_player.Name = "SimPlayer"
local_player.Parent = players
local player_gui = Instance.new("PlayerGui")
player_gui.Name = "PlayerGui"
player_gui.Parent = local_player
service_methods.Players = { LocalPlayer = local_player }

local workspace = game:GetService("Workspace")
local camera = Instance.new("Camera")
camera.Name = "Camera"
camera.ViewportSize = Vector2.new(SIM.viewport[1], SIM.viewport[2])
camera.Parent = workspace
service_methods.Workspace = { CurrentCamera = camera }

-- the device this run pretends to be (run.mjs runs every example once per device)
service_methods.UserInputService.TouchEnabled = SIM.touch == true
service_methods.UserInputService.MouseEnabled = not SIM.touch and not SIM.gamepad
service_methods.UserInputService.KeyboardEnabled = not SIM.touch and not SIM.gamepad
service_methods.UserInputService.GamepadEnabled = SIM.gamepad == true

game:GetService("ReplicatedStorage")
game:GetService("StarterGui")
game:GetService("TweenService")
game:GetService("RunService")
game:GetService("UserInputService")

-- MODULES -------------------------

local loaded = {}
local loading = {}

local function module_env(script)
	return setmetatable({ script = script }, { __index = env, __newindex = env })
end

local function run_chunk(source, chunk_name, script)
	local fn, err = loadstring(source, "=" .. chunk_name)
	if not fn then error(`[sim] could not compile {chunk_name}: {err}`, 0) end
	setfenv(fn, module_env(script))
	return fn
end

local function require_module(module)
	if type(module) == "string" then
		error(`[sim] require("{module}"): string requires are not simulated, require the instance instead`, 2)
	end
	if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
		error(`[sim] require expects a ModuleScript, got {typeof(module)}`, 2)
	end
	local result = loaded[module]
	if result ~= nil then return result end
	if loading[module] then error(`[sim] require loop at {module:GetFullName()}`, 2) end
	loading[module] = true
	local source = get(module).source
	local fn = run_chunk(source, module:GetFullName(), module)
	result = fn()
	if result == nil then error(`[sim] module {module:GetFullName()} did not return a value`, 2) end
	loaded[module] = result
	loading[module] = nil
	return result
end

-- paths like "ReplicatedStorage/Packages/bright/theme", parents come first
table.sort(SIM.modules, function(a, b)
	local _, depth_a = a.path:gsub("/", "")
	local _, depth_b = b.path:gsub("/", "")
	if depth_a ~= depth_b then return depth_a < depth_b end
	return a.path < b.path
end)
for _, module in SIM.modules do
	local parts = module.path:split("/")
	local node = game:GetService(parts[1])
	for i = 2, #parts - 1 do
		local child = node:FindFirstChild(parts[i])
		if not child then
			child = Instance.new("Folder")
			child.Name = parts[i]
			child.Parent = node
		end
		node = child
	end
	local script = Instance.new("ModuleScript")
	script.Name = parts[#parts]
	get(script).source = module.source
	script.Parent = node
end

-- JSON -------------------------

local function json_string(text: string)
	return '"' .. text:gsub('[%c"\\]', function(c)
		if c == '"' then return '\\"' end
		if c == "\\" then return "\\\\" end
		if c == "\n" then return "\\n" end
		if c == "\t" then return "\\t" end
		return string.format("\\u%04x", string.byte(c))
	end) .. '"'
end

local function json_number(n: number)
	if n ~= n then return "0" end
	if n == math.huge then return "1e300" end
	if n == -math.huge then return "-1e300" end
	if n == math.floor(n) and math.abs(n) < 1e15 then return string.format("%d", n) end
	return string.format("%.9g", n)
end

local encode_value
function encode_value(value)
	local kind = typeof(value)
	if kind == "number" then return json_number(value)
	elseif kind == "boolean" then return tostring(value)
	elseif kind == "string" then return json_string(value)
	elseif kind == "Color3" then return `\{"t":"C3","r":{json_number(value.R)},"g":{json_number(value.G)},"b":{json_number(value.B)}\}`
	elseif kind == "UDim" then return `\{"t":"U","s":{json_number(value.Scale)},"o":{json_number(value.Offset)}\}`
	elseif kind == "UDim2" then
		return `\{"t":"U2","xs":{json_number(value.X.Scale)},"xo":{json_number(value.X.Offset)},"ys":{json_number(value.Y.Scale)},"yo":{json_number(value.Y.Offset)}\}`
	elseif kind == "Vector2" then return `\{"t":"V2","x":{json_number(value.X)},"y":{json_number(value.Y)}\}`
	elseif kind == "EnumItem" then return json_string(value.Name)
	elseif kind == "Font" then
		return `\{"t":"F","f":{json_string(value.Family)},"w":{json_string(value.Weight.Name)},"s":{json_string(value.Style.Name)}\}`
	elseif kind == "ColorSequence" then
		local keys = {}
		for _, k in value.Keypoints do
			table.insert(keys, `[{json_number(k.Time)},{json_number(k.Value.R)},{json_number(k.Value.G)},{json_number(k.Value.B)}]`)
		end
		return `\{"t":"CS","k":[{table.concat(keys, ",")}]\}`
	elseif kind == "NumberSequence" then
		local keys = {}
		for _, k in value.Keypoints do table.insert(keys, `[{json_number(k.Time)},{json_number(k.Value)}]`) end
		return `\{"t":"NS","k":[{table.concat(keys, ",")}]\}`
	end
	return nil
end

local function encode_instance(node): string
	local data = get(node)
	local props = {}
	local keys = {}
	for key in data.props do table.insert(keys, key) end
	table.sort(keys)
	for _, key in keys do
		if key ~= "Name" then
			local encoded = encode_value(data.props[key])
			if encoded then table.insert(props, `{json_string(key)}:{encoded}`) end
		end
	end
	local children = {}
	for _, child in data.children do
		table.insert(children, encode_instance(child))
	end
	return `\{"c":{json_string(data.class)},"n":{json_string(node.Name)},"p":\{{table.concat(props, ",")}\},"k":[{table.concat(children, ",")}]\}`
end

-- SIM API -------------------------

local scenes = {}
local assets = {}

local sim = {}

-- a ScreenGui in PlayerGui, like a LocalScript would make
function sim.screen(name: string?, props: { [string]: any }?)
	local gui = Instance.new("ScreenGui")
	gui.Name = name or "ScreenGui"
	get(gui).absolute_size = Vector2.new(SIM.viewport[1], SIM.viewport[2] - 58)
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	for key, value in props or {} do gui[key] = value end
	gui.Parent = player_gui
	return gui
end

-- save the current gui as one scene in the viewer. call it after setting up each state you want to see
-- bright's own rule checker (src/lint.luau), run on every snapshot
local function lint_guis(guis)
	local packages = game:GetService("ReplicatedStorage"):FindFirstChild("Packages")
	local bright = packages and packages:FindFirstChild("bright")
	local module = bright and bright:FindFirstChild("lint")
	if not module then return "" end
	local lint = require_module(module)
	local out = {}
	for _, gui in guis do
		for _, problem in lint(gui) do
			table.insert(out, `\{"path":{json_string(problem.path)},"rule":{json_string(problem.rule)},"level":{json_string(problem.level)},"message":{json_string(problem.message)}\}`)
		end
	end
	return table.concat(out, ",")
end

function sim.snapshot(label: string?)
	flush_deferred()
	local guis, roots = {}, {}
	for _, gui in player_gui:GetChildren() do
		if gui:IsA("LayerCollector") then
			table.insert(guis, encode_instance(gui))
			table.insert(roots, gui)
		end
	end
	table.insert(scenes, `\{"name":{json_string(label or `scene {#scenes + 1}`)},"guis":[{table.concat(guis, ",")}],"lint":[{lint_guis(roots)}]\}`)
end

-- advance time: runs task.delay / task.wait / Heartbeat (vide springs) in 60 fps steps
function sim.step(seconds: number?)
	local remaining = seconds or 1 / 60
	local run_service = game:GetService("RunService")
	repeat
		local dt = math.min(remaining, 1 / 60)
		remaining -= dt
		clock += dt
		flush_deferred()
		for i = #delayed, 1, -1 do
			local entry = delayed[i]
			if entry[1] <= clock then
				table.remove(delayed, i)
				task_resume(entry[2], table.unpack(entry[3], 1, entry[3].n))
			end
		end
		run_service.Heartbeat:Fire(dt)
		run_service.RenderStepped:Fire(dt)
		for callback in service_methods.RunService._render_steps do callback(dt) end
		flush_deferred()
	until remaining <= 0
end

-- fire any event, e.g. sim.fire(button, "MouseEnter")
function sim.fire(target, event: string, ...)
	assert(typeof(target) == "Instance", `sim.fire: expected an Instance, got {typeof(target)}`)
	target[event]:Fire(...)
	flush_deferred()
end

local function find_button(target)
	if target:IsA("GuiButton") then return target end
	return target:FindFirstChildWhichIsA("GuiButton") or error(`sim: no button in {target:GetFullName()}`)
end
function sim.hover(target) sim.fire(find_button(target), "MouseEnter") end
function sim.leave(target) sim.fire(find_button(target), "MouseLeave") end
function sim.press(target)
	local button = find_button(target)
	sim.fire(button, "MouseEnter")
	sim.fire(button, "MouseButton1Down")
end
function sim.click(target)
	local button = find_button(target)
	sim.fire(button, "MouseButton1Down")
	sim.fire(button, "MouseButton1Up")
	sim.fire(button, "MouseButton1Click")
	sim.fire(button, "Activated")
end

-- show a real image for an asset id: sim.asset("rbxassetid://123", "sim/assets/coin.png")
function sim.asset(id: string, path: string)
	assets[id] = path
end

-- pretend to be a phone for UserInputService checks
function sim.touch(enabled: boolean)
	service_methods.UserInputService.TouchEnabled = enabled
	service_methods.UserInputService.MouseEnabled = not enabled
	service_methods.UserInputService.KeyboardEnabled = not enabled
end

-- ENV -------------------------

for name, value in {
	Color3 = Color3, UDim = UDim, UDim2 = UDim2, Vector2 = Vector2, Vector3 = Vector3, CFrame = CFrame, Rect = Rect,
	ColorSequence = ColorSequence, ColorSequenceKeypoint = ColorSequenceKeypoint,
	NumberSequence = NumberSequence, NumberSequenceKeypoint = NumberSequenceKeypoint, NumberRange = NumberRange,
	TweenInfo = TweenInfo, Enum = Enum, Font = Font, Instance = Instance,
	typeof = typeof, task = task, require = require_module, sim = sim,
	workspace = workspace, game = game,
	tick = function() return clock end, time = function() return clock end, elapsedTime = function() return clock end,
	wait = task.wait, spawn = task.spawn, delay = task.delay,
	warn = function(...) print("[warn]", ...) end,
} do
	env[name] = value
end
env.debug = setmetatable({ profilebegin = function() end, profileend = function() end, setmemorycategory = function() end }, { __index = debug })
setmetatable(env, { __index = getfenv(0) })

-- MAIN -------------------------

local main = Instance.new("LocalScript")
main.Name = SIM.main.name
main.Parent = local_player:FindFirstChild("PlayerGui")
local fn = run_chunk(SIM.main.source, SIM.main.name, main)
local thread = coroutine.create(fn)
local ok, err = coroutine.resume(thread)
if not ok then
	error(`{err}\n{debug.traceback(thread)}`, 0)
end
if #scenes == 0 then sim.snapshot("default") end

local asset_list = {}
for id, path in assets do table.insert(asset_list, `{json_string(id)}:{json_string(path)}`) end

print(JSON_MARK .. `\{"scenes":[{table.concat(scenes, ",")}],"assets":\{{table.concat(asset_list, ",")}\}\}`)
