-- lint fixture: two UIScales on one object must fail `one scale per instance`, one must pass

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ui = require(ReplicatedStorage.Packages.bright)

local function rules(root)
	local found = {}
	for _, problem in ui.lint(root) do
		found[problem.rule] = (found[problem.rule] or 0) + 1
	end
	return found
end

local screen = sim.screen("lint")

-- broken: adaptive scale and a pop scale on the same window
local bad = ui.window { Name = "bad", title = "Bad", Parent = screen, ui.adaptive() }
ui.pop(bad)
assert(rules(bad)["one scale per instance"] == 1, "double UIScale was not reported")

-- fixed: the pop goes on a wrapper (what ui.presence does)
local wrapper = ui.box { Name = "wrapper", Parent = screen, Size = UDim2.fromScale(0.5, 0.5) }
local good = ui.window { Name = "good", title = "Good", Parent = wrapper, ui.adaptive() }
ui.pop(wrapper)
assert(rules(wrapper)["one scale per instance"] == nil, "single UIScale per object was reported")
good:Destroy()
bad:Destroy()
print("lint_scales ok")
