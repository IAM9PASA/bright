-- idle loops and feedback animation. exposed as ui.motion
--
-- motion.loop(step)                      vide action: step(dt, time, instance) every frame
-- motion.bob(amp, speed?, phase?, sway?) vide action: float up and down (scale), optional tilt in degrees
-- motion.spin(deg_per_sec)               vide action: rotate forever (sunbursts, loading)
-- motion.pause(target, paused)           pause loops under a ScreenGui, or under any frame (closed windows)
-- motion.tween(instance, time, goals, style?, direction?)
-- motion.pop(instance, from?, time?, delay?, name?)   scale in with a little overshoot
-- motion.shake(instance)                 "no" wiggle, safe to spam: always ends at the resting rotation
--
-- all loops share one RenderStepped connection, and a loop only looks up its ScreenGui once

-- SERVICES -------------------------

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")


-- MODULES -------------------------

local vide = require(script.Parent.Parent.vide)


-- VARIABLES -------------------------

local REST_ATTRIBUTE = "bright_rest_rotation"
local SHAKE_ATTRIBUTE = "bright_shake"
local SHAKE_ANGLES = { 9, -8, 6, -4, 2, 0 }
local SHAKE_STEP = 0.035

local loops = {} -- entry -> true. entry = { instance, step, screen, held }
local paused_screens = setmetatable({}, { __mode = "k" })
local held_roots = setmetatable({}, { __mode = "k" }) -- frames paused with motion.pause
local connection: RBXScriptConnection? = nil
local clock = 0

local motion = {}


-- FUNCTIONS -------------------------

-- a loop under a frame that was paused before the loop started
local function held_by_roots(instance: Instance, held)
	for root in held_roots do
		if instance == root or instance:IsDescendantOf(root) then
			held[root] = true
		end
	end
end

local function run(dt: number)
	clock += dt
	for entry in loops do
		local screen = entry.screen
		if screen == nil then
			-- look up once; not parented yet means try again next frame
			screen = entry.instance:FindFirstAncestorWhichIsA("LayerCollector")
			if not screen then continue end
			entry.screen = screen
			held_by_roots(entry.instance, entry.held)
		end
		if paused_screens[screen] or next(entry.held) then continue end
		entry.step(dt, clock, entry.instance)
	end
end

local function add(instance: Instance, step)
	local entry = { instance = instance, step = step, screen = nil, held = {} }
	loops[entry] = true
	if not connection then
		connection = RunService.RenderStepped:Connect(run)
	end
	local function remove()
		loops[entry] = nil
		if next(loops) == nil and connection then
			connection:Disconnect()
			connection = nil
		end
	end
	instance.Destroying:Connect(remove)
	return remove
end

-- vide action: put it in a props table like a child
function motion.loop(step: (dt: number, time: number, instance: Instance) -> ())
	return vide.action(function(instance)
		local remove = add(instance, step)
		-- inside a vide scope the loop also stops with the scope; outside one Destroying is enough
		pcall(vide.cleanup, remove)
	end)
end

-- float on the Y axis by amp (scale of the parent height), with an optional tilt (degrees)
function motion.bob(amp: number, speed: number?, phase: number?, sway: number?)
	local rate, offset = speed or 2, phase or 0
	-- resting values per instance, so one bob action can be reused on many elements
	local rest = setmetatable({}, { __mode = "k" })
	return motion.loop(function(_, time, instance: any)
		local start = rest[instance]
		if not start then
			start = { position = instance.Position, rotation = instance.Rotation }
			rest[instance] = start
		end
		local wave = math.sin(time * rate + offset)
		instance.Position = start.position + UDim2.fromScale(0, amp * wave)
		if sway then
			instance.Rotation = start.rotation + sway * math.sin(time * rate * 0.5 + offset)
		end
	end)
end

function motion.spin(deg_per_sec: number)
	return motion.loop(function(dt, _, instance: any)
		instance.Rotation = (instance.Rotation + deg_per_sec * dt) % 360
	end)
end

-- target = a ScreenGui (every loop in it) or any instance (loops inside it, like a closed window)
function motion.pause(target: Instance, paused: boolean)
	if target:IsA("LayerCollector") then
		paused_screens[target] = if paused then true else nil
		return
	end
	held_roots[target] = if paused then true else nil
	for entry in loops do
		local instance = entry.instance
		if instance == target or instance:IsDescendantOf(target) then
			entry.held[target] = if paused then true else nil
		end
	end
end

function motion.tween(instance: Instance, time: number, goals: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local tween = TweenService:Create(instance, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goals)
	tween:Play()
	return tween
end

-- scale from `from` to 1 with Back easing. own UIScale (name) so it never fights another one,
-- but an instance can only have one UIScale: pop a wrapper if the frame already has ui.adaptive
function motion.pop(instance: Instance, from: number?, time: number?, delay: number?, name: string?)
	local scale_name = name or "pop_scale"
	local scale = instance:FindFirstChild(scale_name) :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = scale_name
		scale.Parent = instance
	end
	local target = scale :: UIScale
	target.Scale = from or 0.85
	local function play()
		motion.tween(target, time or 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if delay and delay > 0 then task.delay(delay, play) else play() end
	return target
end

-- the resting rotation is saved once, and each shake takes a token: a newer shake stops the older
-- one, and the last step always lands on rest, so spamming clicks can't make it drift
function motion.shake(instance: GuiObject)
	local rest = instance:GetAttribute(REST_ATTRIBUTE)
	if rest == nil then
		rest = instance.Rotation
		instance:SetAttribute(REST_ATTRIBUTE, rest)
	end
	local token = (instance:GetAttribute(SHAKE_ATTRIBUTE) or 0) + 1
	instance:SetAttribute(SHAKE_ATTRIBUTE, token)

	task.spawn(function()
		for _, angle in SHAKE_ANGLES do
			if instance:GetAttribute(SHAKE_ATTRIBUTE) ~= token then return end
			motion.tween(instance, SHAKE_STEP, { Rotation = rest + angle }, Enum.EasingStyle.Sine)
			task.wait(SHAKE_STEP)
		end
		if instance:GetAttribute(SHAKE_ATTRIBUTE) == token then
			instance.Rotation = rest
		end
	end)
end


-- MAIN -------------------------

return motion
