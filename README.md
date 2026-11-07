# Bright

UI building blocks on top of [vide](https://github.com/centau/vide) that make any UI style easier to build and prettier by default.
You write the screen once with `ui.window`, `ui.button`, `ui.item_card` and friends. The **style** decides how it looks: fonts, corners, outlines, header kind, button kind, glow, palettes.
All sizes are scale: no px offsets, scaled strokes, scaled text. The rules are in [RULES.md](RULES.md), and `ui.lint(root)` checks them in Studio or in the simulator.

## Styles

| Style | Look | Good for |
| --- | --- | --- |
| `brainrot` (default) | navy glass, glossy studded header bars, 3D candy buttons, heavy outlined text | simulators, tycoons, meme games |
| `clean` | white rounded windows, flat solid buttons, dark text | menus, settings, modern app-like UI |
| `glass` | dark see-through windows, mint glow edges, glowing buttons | neon, script-hub, nightlife |
| `scifi` | navy, cyan lines, square corners with bracket marks, outline buttons, uppercase | shooters, space, tech |
| `fantasy` | wood and gold, parchment banner title, beveled buttons, serif text | RPG, adventure, quests |
| `pastel` | cream, round everything, bubbly pill buttons, rounded font | pets, cafe, dress-up, cute games |

```lua
local bright = require(ReplicatedStorage.Packages.bright)   -- default style (src/theme.luau)
local ui = bright.with(bright.styles.glass)                  -- or any style, several can live side by side
```

Make your own style from any of them. Only list what changes:

```lua
local candy_night = bright.extend(bright.styles.brainrot, {
	surface = { color = Color3.fromHex("1A0B2E"), corner = UDim.new(0.04, 0) },
	button = { studs = false, corner = UDim.new(0.5, 0) },
	palette = { blue = { face = { Color3.fromHex("C9A8FF"), Color3.fromHex("8A4DFF") } } },
})
local ui = bright.with(candy_night)
```

Style settings (see `src/styles/brainrot.luau` for every key):
- **Surface:** `surface` sets the window and card fill, transparency, outline, `corner`, optional `gradient`, `glow` and sci-fi `brackets`.
- **Kinds:** `header.kind` is `bar`, `plain` or `banner`. `button.kind` is `candy`, `flat`, `outline` or `glow`. `button.studs` and `header.studs` turn the stud texture on or off.
- **Text:** `text` sets `outline`, `drop` (dark copy under titles) and `upper` (uppercase). `font` sets the `title` and `body` fonts.
- **Cards:** `card.rays` puts sunbursts behind items. Without it, items get a rarity glow and stripe.
- **Colors:** `palette` sets the named colors (blue, green, red, gold, purple, pink, orange, amber, grey). Each has a dark `base`, an outline `stroke`, a `face` gradient, a `label` color and a `text` outline color. `text_gradient` sets the cash and rarity text.

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

Open and close with a spring instead of popping, and roll numbers instead of jumping:

```lua
local open = vide.source(false)
ui.window { title = "Shop", open = open, ... }        -- springs in and out, closed = no input, no cost

ui.counter { value = cash, style = "cash" }           -- 1,450 rolls to 1,390
ui.button { text = "$95K", locked = function() return cash() < 95000 end }   -- grey, shakes on click
```

- `disabled`: the action doesn't apply right now (maxed, already claimed). Grey and no input.
- `locked`: the player can't do it yet (can't afford, needs a level). Grey, but a click shakes the button instead of running `Activated`.

Full API: header comment of `src/init.luau`.

## Publishing

bright is not on the Wally index yet, so `iam9pasa/bright@0.1.0` only resolves after the owner publishes it:

```sh
wally login                 # once, with the GitHub account that owns iam9pasa
wally package --list        # check what ships: src/, default.project.json, wally.toml, README, RULES
wally publish
```

Until then, add it as a git submodule or copy `src/` into your project as `Packages/bright` next to vide. The pieces:
- **Windows:** `window`, `header`, `card`, `panel`.
- **Text:** `text` (styles `cash`, `legendary`, `epic`, `rare`, `common`, `gems`, `item`, `rainbow`), `title` (white over dark drop edge).
- **Controls:** `button` (`palette`, `disabled` and `locked` can be vide sources), `close_button`, `icon_button`, `tab`, `input`, `toggle`, `hud_button`, `hit`.
- **Content:** `item_card`, `counter`, `sunburst`, `studs`, `progress`, `icon`, `hex`, `hex_stack`, `hex_grid { radius, cell }`.
- **Layout:** `row`, `column`, `scroll_grid { columns }`, `scroll_list` (gaps stay the same share of the width at any item count), `hud_column`, `padding`, `pad`, `square`, `ratio`.
- **Motion:** `presence { open }` (spring open / close), `motion.loop`, `bob`, `spin`, `pause`, `tween`, `pop`, `shake`.
- **Screen:** `device()`, `adaptive()`, `lint(root)`.
- **Types:** `WindowProps`, `ButtonProps`, `TextProps` and friends, for autocomplete and typo checks.

Asset ids for the stud texture, sunburst and icons live in `theme.asset`. Replace them with your own game's ids.

## Simulator: see the UI without Studio

`sim/` runs the real bright + vide code on a fake Roblox (`sim/roblox.luau`) and draws it in a browser page.
Each example runs once per device (phones, tablet, desktop, console), so code that checks the screen gets real answers.

```sh
rokit install                        # gets luau (rokit.toml)
node sim/run.mjs                     # every example -> sim/out/<name>.html, open it in a browser
node sim/run.mjs gallery --serve     # http://localhost:5173, rebuilds + reloads when you save
node sim/run.mjs --shot              # pngs per device + design checks in the terminal (needs playwright)
node sim/run.mjs --strict            # headless: exit 1 on any crash or sizing-rule fail (what CI runs)
node sim/run.mjs --tests --strict    # sim/tests: lint fixtures and behaviour asserts
```

CI (`.github/workflows/check.yml`) runs the two headless commands on every push and PR. You never need to open the viewer.

Examples live in `sim/examples/`, one per style:

| Example | Style | Shows |
| --- | --- | --- |
| `gallery` | inventory in all 6 styles (one scene each) | same screen code, only the style changes, `hud_column` |
| `styles` | all 6 styles side by side | tabs, progress, toggle, buttons, item card per style |
| `store` | amber large window | pack cards (blue / pink / green), passes, sale price, robux buttons |
| `upgrades` | gold | rows sized with `ui.ratio`, level bars, rolling cash `counter`, maxed (disabled) and can't-afford (locked) buttons |
| `daily` | pink | 7-day grid, claimed / today / locked cells, reactive claim button |
| `popups` | red and green popups | `open` springs popups in and out, a spinning sunburst that pauses while closed |
| `skilltree` | purple | radius-3 `hex_grid`, owned / open / locked nodes, points `counter` |
| `lists` | blue | the same `scroll_list` with 2 and 6 items, same gap |
| `themes` | one style, 4 palettes | only `palette` changes |

`sim/shared/stand_ins.luau` maps the asset ids to local preview drawings. They are normal client code plus a `sim` global:

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

## License

MIT, free to use, change and ship in any game. See [LICENSE](LICENSE).
