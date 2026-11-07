-- hud_button adds one square constraint, or keeps yours instead of adding a second

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ui = require(ReplicatedStorage.Packages.bright)

local function count(button)
	local n = 0
	for _, child in button:GetChildren() do
		if child:IsA("UIAspectRatioConstraint") then n += 1 end
	end
	return n
end

local plain = ui.hud_button { text = "Store" }
assert(count(plain) == 1, "default hud_button should square itself once")

local wide = ui.hud_button { text = "Wide", ui.square(1.5) }
assert(count(wide) == 1, `a passed constraint should replace the default, found {count(wide)}`)
assert(wide:FindFirstChildWhichIsA("UIAspectRatioConstraint").AspectRatio == 1.5, "the passed ratio should win")
sim.screen("hud")
print("hud_button ok")
