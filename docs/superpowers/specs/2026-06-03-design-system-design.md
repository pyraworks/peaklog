# PeakLog Design System Spec

**Stage 1 of PeakLog MVP implementation.**
**Status:** Approved 2026-06-03

---

## Structure

```
lib/core/
  design/
    app_colors.dart       — color tokens
    app_typography.dart   — type scale
    app_spacing.dart      — 4pt grid
    app_radius.dart       — corner radii
  theme/
    app_theme.dart        — Material3 ThemeData
```

---

## AppColors

Figma / iOS HIG naming convention.

| Token | Value | Usage |
|---|---|---|
| `primary` | #3478F6 | iOS system blue — buttons, links, badges |
| `primarySoft` | #3478F6 @ 10% | light blue tint backgrounds |
| `background` | #F2F2F7 | scaffold background |
| `card` | #FFFFFF | card / sheet surfaces |
| `chip` | #E5E5EA | unselected chip background |
| `chipSelected` | #000000 | selected chip background |
| `label1` | #000000 | primary text |
| `label2` | #8E8E93 | secondary text |
| `label3` | #C7C7CC | placeholder / disabled text |
| `separator` | #E5E5EA | dividers, borders |
| `destructive` | #FF3B30 | delete / error actions |
| `success` | #34C759 | confirmation states |
| `pbGold` | #BF8700 | PR / PB badge amber |

---

## AppTypography

| Token | Size | Weight | Letter spacing | Usage |
|---|---|---|---|---|
| `appTitle` | 34 | w700 | -0.5 | Home "PeakLog" title |
| `screenTitle` | 24 | w700 | -0.3 | AppBar screen titles |
| `pbValue` | 48 | w700 | -1.0 | Personal best large value |
| `cardValue` | 36 | w700 | -0.5 | Card numeric value |
| `headline` | 17 | w600 | — | Section headers |
| `cardTitle` | 16 | w600 | — | Card titles |
| `body` | 15 | w400 | — | Body text |
| `footnote` | 14 | w400 | — | Supporting text |
| `caption` | 11 | w600 | 0.8 | Uppercase section labels |
| `inputValue` | 40 | w700 | — | Record input values |
| `badge` | 13 | w600 | — | Badge text |

---

## AppSpacing — 4pt grid

| Token | Value | Semantic alias |
|---|---|---|
| `s4` | 4 | smallGap |
| `s8` | 8 | itemGap |
| `s12` | 12 | cardPadding inner |
| `s16` | 16 | screenPadding, cardPadding |
| `s20` | 20 | cardPaddingLarge |
| `s24` | 24 | sectionGap |
| `s32` | 32 | large section gap |

---

## AppRadius

| Token | Value | Usage |
|---|---|---|
| `card` | 12 | card containers |
| `chip` | 999 | category chips (pill) |
| `button` | 12 | buttons, dialogs |
| `input` | 12 | input fields |
| `badge` | 6 | small badges |

---

## AppTheme (Material3)

- **ColorScheme**: primary=#3478F6, surface=card, scaffoldBg=background
- **AppBarTheme**: card bg, label1 title (17/w600), primary icons, elevation 0
- **CardTheme**: card color, radius=card, elevation 0, margin 0
- **InputDecorationTheme**: card fill, separator border 0.5px, focused primary 1.5px
- **ElevatedButtonTheme**: primary blue, radius=button, padding v12/h20, w600 16pt
- **DividerTheme**: separator color, 0.5px thickness
- **DialogTheme**: card bg, radius=button
- **Legacy aliases** in `AppTheme`: `background`, `card`, `accent`, `textPrimary`, `textSecondary`, `separator` — retained until all screens migrated

---

## PbBadge

Uses `AppColors.pbGold` (amber) for PR/PB text, not `primary` (blue).
