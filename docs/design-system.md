# MeetOverlay Design System

MeetOverlay uses a native macOS utility style: quiet settings, clear calendar hierarchy, and a high-contrast reminder overlay.

## Principles

- Use platform controls, SF Symbols, system fonts, and semantic system colors.
- Respect the user's macOS accent color for primary emphasis.
- Keep Settings calm and compact.
- Make the fullscreen overlay unmistakable and legible.
- Add new UI through `MeetOverlayTheme` tokens before introducing new ad-hoc styling.

## Tokens

- Colors: semantic macOS backgrounds, text, separators, warnings, and accent color.
- Surfaces: card, inset list, overlay panel.
- Typography: system hierarchy for Settings, large system type for overlay.
- Spacing: shared small, medium, large, card, page, and overlay spacing.
- Radius: icon badge, inset, card, and overlay panel radii.

## Usage

- Settings cards use the shared card surface and icon badge treatment.
- Calendar lists use the shared inset surface.
- The overlay uses a fixed dark backdrop, the shared accent color, and the same panel/border rhythm as Settings.
