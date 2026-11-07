# Bright

UI building blocks on top of [vide](https://github.com/centau/vide), in the "brainrot / cake" cartoon style:
dark translucent navy windows, glossy studded headers, chunky 3D candy buttons, and heavy white text with a thick dark outline.
Change `src/theme.luau` to restyle everything built with it: palettes, text gradients, fonts, outlines and asset ids.
All sizes are scale (no px, no UITextSizeConstraint).

## Use

```toml
# wally.toml
[dependencies]
bright = "iam9pasa/bright@0.1.0"
```

```lua
local ui = require(ReplicatedStorage.Packages.bright)

ui.window {
	title = "Inventory",
	icon = ui.theme.asset.icon.inventory,
	palette = "blue",            -- blue, orange, gold, amber, green, red, purple, pink, grey
	shape = "inventory",         -- standard, inventory, large, popup (reference proportions)
	close = function() end,
	Parent = screen_gui,

	ui.scroll_grid { columns = 4, Size = UDim2.fromScale(0.65, 0.8), Position = UDim2.fromScale(0.02, 0.17),
		ui.item_card { name = "Sharkalino", image = id, value = "$1.2K/s", rarity = "legendary" },
	},
	ui.button { text = "Equip", palette = "green", Size = UDim2.fromScale(0.25, 0.11) },
}
```

Full API: header comment of `src/init.luau`. The pieces:
- **Windows:** `window`, `header`, `card`, `panel`.
- **Text:** `text` (styles `cash`, `legendary`, `epic`, `rare`, `common`, `gems`, `item`, `rainbow`), `title` (white over dark drop edge).
- **Controls:** `button` (3D candy, `palette` and `disabled` can be vide sources), `close_button`, `icon_button`, `tab`, `input`, `hud_button`, `hit`.
- **Content:** `item_card`, `sunburst`, `studs`, `progress`, `icon`.
- **Layout:** `row`, `column`, `scroll_grid { columns }`, `scroll_list`, `padding`, `square`.
- **Screen:** `device()`, `adaptive()`.

Asset ids for the stud texture, sunburst and icons live in `theme.asset`. Replace them with your own game's ids.

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
