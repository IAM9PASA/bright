---
name: roblox-ui-design
description: Design and build good-looking Roblox UI (ScreenGui panels, shops, inventories, HUDs, popups) in any visual style, with vide + bright or plain instances. Use whenever the user asks to make, restyle, review or "make prettier" any Roblox UI, even without naming a style. Covers the design process (reference, direction, hierarchy, spacing, color, type, depth, motion, states), Roblox-specific build rules (scale only, aspect, UIStroke, TextScaled, safe areas), the common mistakes that make UI look cheap, and how to check the result.
---

# Roblox UI design

Good UI is not a theme you pick. It comes from decisions made for **this** game and **this** screen.
Follow the steps in order. Do not start writing instances until steps 1–3 are done.

## 1. Get a reference, never design from nothing

- Ask the user for 1–3 screenshots of UI they like (other games, Dribbble, their own art). If they have none, propose 2–3 named directions in one line each and let them pick ("chunky cartoon like pet sims", "thin dark glass like FPS menus", "soft rounded pastel").
- From the reference, write down 5 facts before building: background (solid / translucent / textured), corner shape, edge treatment (outline / shadow / glow / none), button shape and depth, and the type (weight, case, outline).
- If the user has existing UI in Studio, scan it first and match it. Consistency beats taste.

## 2. Pick one direction and commit

Write a short style spec (10 lines max) and keep it in the code as a bright style table or a theme module:

- **Surface:** one window color plus one inset color. Pick one corner radius for all windows and one for all controls.
- **Accent:** one main color, used only for the main action and the selected state.
- **Support colors:** at most two extra colors (for example red for danger, gold for currency).
- **Type:** one display font for titles and numbers, and one body font. Don't add a third.
- **Edges:** one way to separate things: outline, shadow or contrast. Mixing two at the same level looks noisy.

If you use bright, write this as `bright.extend(base, {...})`. Don't just take a built-in style unchanged. Built-in styles are starting points, not answers.

## 3. Lay out the screen on paper first (hierarchy)

Every screen has exactly **one** thing the player should see first. Decide it, then rank everything:

1. **Focus:** the item preview, the big buy button, the reward. Make it the biggest, brightest or most saturated.
2. **Actions:** the buttons. The primary action gets the accent fill, secondary actions are neutral, and destructive ones are red and smaller.
3. **Content:** the lists and grids. Keep them calm and uniform.
4. **Chrome:** the title, close button and tabs. These should be the quietest.

Make the difference between levels obvious: about 1.5× or more in size, or a clearly different weight or color. Small differences look like mistakes.

## 4. Spacing makes it look designed

- Use one spacing scale everywhere: 4 steps such as 0.02, 0.04, 0.06 and 0.1 of the short side. In bright these are `theme.space` and `ui.pad(step, aspect)`.
- Leave more space between groups than inside them. Related items sit close together, and unrelated groups get at least twice the gap.
- Give windows real padding, at least the `md` step. Content touching the edges is the number one "looks cheap" signal.
- Align to edges. Every element should line up with something else.

## 5. Color recipe

- Build each colored control from one hue: a dark base or rim, a lighter face (gradient top light, bottom saturated), and a darkest shade for the outline or text stroke.
- Neutral surfaces should be tinted toward the accent hue (navy for blue UI, warm brown for gold UI), never pure grey or black.
- Contrast: body text at least 4.5:1, big titles at least 3:1. Outlined text counts against its outline.
- Grey out disabled controls. Don't hide them.

## 6. Type

- `TextScaled = true`, and control the size with the label box height. A title box should be about 2× a body box.
- Keep labels short. Two words beats a sentence, and numbers beat words.
- Heavy outline + drop shadow suits only cartoon styles. Clean, glass and sci-fi styles use no outline and get their contrast from the background.
- Use uppercase only for short labels, and only with a wide font.

## 7. Depth and polish (where "pretty" comes from)

Use one or two of these and do them well, instead of everything at once:
- **Rim depth:** a dark base peeking under a lighter face (candy buttons).
- **Gradient:** a vertical gradient on surfaces (light top), with a subtle 10–20% shift.
- **Glow:** a translucent outer stroke on the focus element only.
- **Texture:** studs, noise or paper. Keep it low contrast (it should barely show).
- **Backdrop light:** a sunburst or radial glow behind the focus item only. Not behind every grid cell.
- **Real art:** icons that are custom, consistent in line weight, and the same size in every cell. Placeholder icons make any UI look bad. Tell the user which icons they need to provide.

## 8. States and motion

Every button has rest, hover (scale 1.05 or lighten), press (scale 0.95, face pushed down), disabled and selected (accent outline) states. Gamepad users need a `SelectionImageObject`. Windows open with a quick pop (Back easing, about 0.2s). Never animate more than one thing for attention at once.

## 9. Roblox build rules (non-negotiable)

- Scale only, never offsets. Keep shapes with `UIAspectRatioConstraint`. Size scroll content from the width (`ScaleWithParentSize` + `Width`).
- Use `UIStroke` with `ScaledSize`, and `ApplyStrokeMode.Border` on TextButtons.
- Set `UIPadding` from the short side so all four sides match.
- Use one layout `UIScale` per window to make phones bigger, or use phone-specific proportions.
- Keep buttons out of the top bar (58px) and notch areas. Tap targets should be at least 44px on phones.
- Use `ZIndexBehavior.Sibling`, and put decoration in the 0 to -2 range under content.
- `RULES.md` and `ui.lint(root)` check all of these.

## 10. Check it, then check it in Studio

1. Run `node sim/run.mjs <example> --shot --device phone,desktop` and read the checks.
2. Look at the PNG and judge it against the reference side by side. Ask: what is the focus? Is any spacing uneven? Is any color or edge style used for no reason?
3. The simulator is an approximation (fonts, images and 3D behind the UI differ). Final polish always happens in Studio, with real icons and in-game lighting behind the UI.
4. Show the user one screen first and iterate before building the rest.

## Mistakes that make Roblox UI look bad

- Every element outlined, glowing and gradiented, so nothing stands out.
- Several accent colors, or the accent used on secondary buttons.
- Same-sized everything: the title, buttons and grid cells all at one visual weight.
- Cramped windows, or content touching the edges.
- A sunburst behind every grid cell, or textures at high contrast.
- Placeholder or mismatched icons.
- Generic layouts copied between screens without asking what each screen is for.
- Building six variants before one screen looks good.
