-- counter: 1450 -> 1390 rolls through the NumberValue and ends on the formatted target

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ui = require(ReplicatedStorage.Packages.bright)
local vide = require(ReplicatedStorage.Packages.vide)

local screen = sim.screen("counter")
local gems = vide.source(1450)
local label

vide.mount(function()
	label = ui.counter { Name = "Gems", value = gems, style = "gems", Size = UDim2.fromScale(0.3, 0.1) }
	return label
end, screen)

assert(label.Text == "1,450", `start should read 1,450, got {label.Text}`)
gems(1390)
sim.step(1)
assert(label.Text == "1,390", `should roll to 1,390, got {label.Text}`)
assert(ui.thousands(1234567) == "1,234,567" and ui.thousands(-1500) == "-1,500" and ui.thousands(12) == "12", "thousands format")
print("counter ok")
