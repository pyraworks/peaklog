# Design System

PeakLog uses a centralized token-based design system. All visual values are imported from `lib/core/design/`.

---

## File Structure

```
lib/core/design/
  app_colors.dart      color tokens
  app_typography.dart  type scale
  app_spacing.dart     4pt grid spacing
  app_icons.dart       icon registry (Material Icons)
lib/core/theme/
  app_theme.dart       Material3 ThemeData assembly
```

---

## Color Tokens — AppColors

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#3478F6` | Buttons, links, badges (iOS system blue) |
| `primarySoft` | `#3478F6 @ 10%` | Light blue tint backgrounds |
| `background` | `#F2F2F7` | Scaffold background |
| `card` | `#FFFFFF` | Card and sheet surfaces |
| `chip` | `#E5E5EA` | Unselected chip background |
| `chipSelected` | `#000000` | Selected chip background |
| `label1` | `#000000` | Primary text |
| `label2` | `#8E8E93` | Secondary text |
| `label3` | `#C7C7CC` | Placeholder / disabled text |
| `separator` | `#E5E5EA` | Dividers, borders |
| `destructive` | `#FF3B30` | Delete / error actions |
| `success` | `#34C759` | Confirmation states |
| `pbGold` | `#BF8700` | PR / PB badge amber |

---

## Typography Tokens — AppTypography

| Token | Size | Weight | Letter Spacing | Usage |
|-------|------|--------|----------------|-------|
| `appTitle` | 34 | w700 | −0.5 | Home "PeakLog" title |
| `pageTitle` | 24 | w700 | −0.3 | Screen titles in ScreenHeader |
| `cardTitle` | 17 | w600 | −0.2 | Card primary text |
| `body` | 15 | w400 | 0 | Body / list item text |
| `footnote` | 13 | w400 | 0 | Dates, secondary metadata |
| `sectionLabel` | 11 | w600 | +0.8 | Section headers (UPPERCASE) |
| `pbValue` | 32 | w800 | −0.8 | PB card value display |

---

## Spacing — AppSpacing (4pt grid)

```dart
s4  = 4.0
s8  = 8.0
s12 = 12.0
s16 = 16.0
s20 = 20.0
s24 = 24.0
s32 = 32.0
```

---

## Icon Registry — AppIcons

All icons are registered in `lib/core/design/app_icons.dart`.

When the icon set changes, only this one file needs to be updated.
Do not import icon packages directly in feature screens.

```dart
// Usage
Icon(AppIcons.share, size: 13, color: Color(0xFF3478F6))
```

Current backend: Material Icons (`package:flutter/material.dart`).

---

## ScreenHeader

All secondary screens use the shared `ScreenHeader` widget.

```dart
ScreenHeader(
  backLabel: 'Back',
  title: 'Settings',          // or titleWidget for rich layout
  trailing: ...,              // optional right-side action
)
```

Spacing (as of 2026-06-07):
- Top padding (SafeArea → Back row): **20pt**
- Bottom padding (title → divider): **16pt**

---

## Rules

- Use design tokens. Do not hardcode color hex values or font sizes in widget files.
- Follow the 4pt grid for all spacing values.
- iOS HIG conventions for font weight and spacing.
- `RepaintBoundary` is forbidden during export rendering (interferes with canvas capture).
