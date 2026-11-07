# Bright

UI building blocks on top of [vide](https://github.com/centau/vide). Started from the playground `ui_kit` module.
Change `src/theme.luau` to restyle everything built with it. All sizes are scale (no px, no UITextSizeConstraint).

## Use

```toml
# wally.toml
[dependencies]
bright = "iam9pasa/bright@0.1.0"
```

```lua
local ui = require(ReplicatedStorage.Packages.bright)

ui.panel {
	Name = "main",
	Size = UDim2.fromScale(1, 1),
	Parent = frame,
	ui.text { Text = "Inventory", style = "title", align = "left", Size = UDim2.fromScale(0.3, 0.05) },
	ui.scroll_grid { Name = "list", Size = UDim2.fromScale(1, 0.7), columns = 6 },
	ui.button { text = "Equip", style = "primary", Size = UDim2.fromScale(0.2, 0.08) },
}
```

Full API: header comment of `src/init.luau`.

## Design rules built in

- Text colors pass WCAG AA contrast (4.5:1) on cards and hovered cards.
- `ui.button { style = "primary" }` uses the accent. Keep it for the one main action per screen.
- Buttons get an accent focus ring for gamepad and keyboard (`SelectionImageObject`).
- `ui.scroll_grid { columns = n }` sizes cells from the width, so the column count stays the same on every screen.
- `ui.device()` and `ui.adaptive()` handle phones, which are physically small: use bigger proportions or a UIScale there. Everything stays scale.

## Simulator: see the UI without Studio

`sim/` runs the real bright + vide code on a fake Roblox (`sim/roblox.luau`) and draws it in a browser page.
Each example runs once per device (phones, tablet, desktop, console), so code that checks the screen gets real answers.

```sh
rokit install                        # gets luau (rokit.toml)
node sim/run.mjs                     # every example -> sim/out/<name>.html, open it in a browser
node sim/run.mjs gallery --serve     # http://localhost:5173, rebuilds + reloads when you save
node sim/run.mjs --shot              # pngs per device + design checks in the terminal (needs playwright)
```

Examples live in `sim/examples/`. They are normal client code plus a `sim` global:

```lua
local screen = sim.screen("shop")            -- a ScreenGui in PlayerGui
vide.mount(function() return ui.panel { ... } end, screen)
sim.snapshot("default")                      -- one scene in the viewer
sim.hover(button) sim.press(button) sim.click(button) sim.fire(instance, "Event", ...)
sim.step(0.5)                                -- advance time: task.delay / task.wait / springs
sim.asset("rbxassetid://123", "sim/assets/coin.png")   -- show a real image instead of a placeholder
```

The viewer has device presets with the Roblox top bar and notch safe areas, a game-world, dark or light backdrop, and an inspector (hover for the instance path and size).
Its design checks flag low text contrast (WCAG 2.2), text under 12px on phones, tap targets under 44pt (64px on TV), and buttons under the top bar or a notch.
Tweens jump to their end value, and images without `sim.asset` show as placeholders.
The layout follows Roblox's rules closely but not perfectly, so give final polish a look in Studio.
