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
	ui.scroll_grid { Name = "list", Size = UDim2.fromScale(1, 0.8), cell = 0.155 },
}
```

Full API: header comment of `src/init.luau`.
