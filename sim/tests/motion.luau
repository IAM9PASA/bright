-- motion: loops run, pause holds them, presence pauses loops while closed, shake can't drift

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)

local screen = sim.screen("motion")
local open = vide.source(true)
local spinner, bobber, inner

vide.mount(function()
	spinner = ui.icon { Name = "Spinner", Size = UDim2.fromScale(0.1, 0.1), ui.motion.spin(90) }
	bobber = ui.icon { Name = "Bobber", Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1), ui.motion.bob(0.02, 3, 0, 4) }
	inner = ui.icon { Name = "Inner", Size = UDim2.fromScale(0.2, 0.2), ui.motion.spin(180) }
	return {
		spinner,
		bobber,
		ui.presence { Name = "Popup", open = open, Size = UDim2.fromScale(0.4, 0.4), inner },
	}
end, screen)

sim.step(1)
assert(math.abs(spinner.Rotation - 90) < 3, `spin should turn 90 deg in 1s, got {spinner.Rotation}`)
assert(bobber.Position ~= UDim2.fromScale(0.5, 0.5), "bob should move")

-- pausing the screen holds every loop
ui.motion.pause(screen, true)
local held = spinner.Rotation
sim.step(0.5)
assert(spinner.Rotation == held, "paused screen should hold loops")
ui.motion.pause(screen, false)

-- a closed presence pauses loops inside it but not outside
open(false)
sim.step(1)
local inner_held, outer_before = inner.Rotation, spinner.Rotation
sim.step(0.5)
assert(inner.Rotation == inner_held, "loops in a closed presence should stop")
assert(spinner.Rotation ~= outer_before, "loops outside should keep running")
open(true)
sim.step(0.5)
assert(inner.Rotation ~= inner_held, "loops resume when the presence opens")

-- spam shake: always back to the resting rotation
local button = ui.button { Name = "Shaky", text = "No", Parent = screen, Rotation = 5 }
for _ = 1, 6 do
	ui.motion.shake(button)
	sim.step(0.03)
end
sim.step(1)
assert(button.Rotation == 5, `shake should land on rest (5), got {button.Rotation}`)
print("motion ok")
