# UI sizing rules

Every UI built with bright follows these rules, so it looks the same on a 390pt phone and a 4K monitor.
`ui.lint(root)` checks the static rules, and `sim/` also measures the result on each device.

```lua
-- studio command bar
for _, p in require(game.ReplicatedStorage.Packages.bright).lint(game.StarterGui.CakeUi) do print(p.level, p.rule, p.path, p.message) end
```

```sh
node sim/run.mjs --strict          # exit 1 on any rule fail (use in CI)
```

## 1. Scale size, never offset

| Do | Don't |
| --- | --- |
| `Size = UDim2.fromScale(0.3, 0.1)` | `UDim2.new(0.3, 20, 0, 40)`, `UDim2.fromOffset(...)` |
| Keep a shape with `ui.square(ratio)` (`UIAspectRatioConstraint`) | Fixed px width and height |
| Grow small screens with `ui.adaptive()` (`UIScale`) or phone proportions from `ui.device()` | `UISizeConstraint` min/max (px) |
| `CornerRadius = UDim.new(0.17, 0)` (0.5 = round) | `UDim.new(0, 12)` |
| `ScrollBarThickness = 0` | Any px scrollbar |

- Offsets are px, and px look tiny on a 4K screen and huge on a phone. Scale is a share of the parent.
- `UIAspectRatioConstraint` only shrinks. Give the box a real size first, then let the ratio cut it.
- Inside a `ScrollingFrame`, scale follows the canvas, and an automatic canvas grows with its content. Size grid cells from the width (`ui.scroll_grid { columns = 4 }`), never from the height.
- Children of a `UIListLayout` or `UIGridLayout` ignore `Position` (and `Size` in a grid), so the linter skips those.

## 2. Padding and gaps: scale of the short side

`UIPadding` scale is per axis. `ui.padding(0.05)` on a 2:1 card pads the sides twice as wide as the top and bottom.

| Use | When |
| --- | --- |
| `ui.pad("md", aspect)` | Most frames. Same px on all four sides. `aspect` = width / height of the padded frame (windows: `theme.window[shape]`) |
| `ui.padding(x, y)` | You want different sides on purpose, like text inset in a `TextBox` |
| `gap = 0.02` on `ui.row` / `ui.column` | A list's gap is a share of the list's main axis: a row's gap scales with its width, a column's with its height |

Spacing steps (`theme.space`, share of the short side): `xs` 0.02, `sm` 0.04, `md` 0.06, `lg` 0.1. Pick a step instead of a new number.

Measured in the sim: padding where the sides and top differ by more than 1.6x is flagged as **even padding**.

## 3. Strokes: ScaledSize, Border on buttons

| Do | Don't |
| --- | --- |
| `StrokeSizingMode = ScaledSize`, `Thickness` = share of the element's short side | `FixedSize` (px) strokes |
| `ApplyStrokeMode = Border` on `TextButton`s that keep their label in a child | Default `Contextual` on those: it outlines the empty button text, so no border shows |
| `Contextual` on `TextLabel`s for the text outline | `TextStrokeTransparency` (px-thin, cannot grow) |
| `BorderSizePixel = 0`, outline with `UIStroke` | `BorderSizePixel` (px) |

- A scaled stroke grows with its element, so big things take small numbers. The tokens live in `theme.stroke`: window 0.01, card 0.03, header 0.07, button 0.07, label 0.1, title 0.12. On a 1080p screen they all land between about 3px and 8px.
- Stud texture `TileSize` is scale of the studded surface. For round studs, set tile Y = tile X × (width / height of the surface). Use the `theme.studs` tokens for headers and buttons.
- Measured in the sim: a border stroke under 1px, or a text outline under 0.75px, on a device is flagged as **thin stroke**. Raise the token instead of adding px.

## 4. Text: TextScaled, size the box

| Do | Don't |
| --- | --- |
| `TextScaled = true`, set the label's `Size` to the text height you want | `TextSize = 18` |
| Short labels: one line per box | `UITextSizeConstraint` (px) |

- The text height is the box height (for one line), so text keeps its size relative to the window on every screen.
- Measured in the sim: text under 12px on a phone (11px on desktop) is flagged as **text size**. Fix it with a taller box or phone proportions, not a px limit.

## 5. UIScale: one layout scale per window

| Do | Don't |
| --- | --- |
| One `ui.adaptive()` in the root window | A layout `UIScale` inside another one (they multiply) |
| `press_scale` / `pop_scale` for hover, press and pop animations (bright adds these) | Scale far outside 0.5–2 to fix a layout |

- `UIScale` scales a whole tree around its anchor point and keeps everything in scale. Use it to grow UI on phones and TVs, never to patch one element.
- The linter warns when two layout scales stack. The animation scales above are ignored for that check.
- Roblox applies only **one** `UIScale` per object. Two on the same object (say `ui.adaptive()` and a pop animation on one window) is a fail, `one scale per instance`, whatever their names. Put the second scale on a wrapper frame (`ui.presence` does this for you).

## Allowed exceptions

- Grid cell children may keep the engine's default px `Size`: the grid replaces it.
- `ScrollBarThickness` above 0 is a warning, not a fail, for lists that really need a visible bar.
- Anything outside bright (Roblox core GUI, plugins) is not linted.

## Rule names in reports

`scale size`, `scale position`, `scale padding`, `scaled stroke`, `scaled text`, `one ui scale`, `one scale per instance` (static, from `ui.lint`).
`even padding`, `thin stroke`, `text size` (measured per device in `sim/`).
