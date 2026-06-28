# PeakLog Icon Design

**Source of truth:** `assets/icon/app_icon.svg`  
**Regenerate icons:** `make icons`

## Origin

Chosen as the final PeakLog app icon design (Variation C — Glint).

## Chosen design

Colorway: **ink** — near-black background `#0B0B0C`, off-white ink `#F5F5F3`.

A connected progress line with three intermediate nodes, a larger peak node,
and a 4-point sparkle sitting above-left of the peak.

## Geometry

All coordinates are in a `viewBox="0 0 100 100"` space. The artwork group
carries an `artTransform` that auto-centres and scales the content to maintain
an 18-unit margin on the dominant axis.

| Parameter | Value |
|---|---|
| Ascent (tweakable %) | 20 |
| Peak Y | 36.2 |
| Peak radius | 6.56 |
| Mid-node Y (node 3) | 60.8 |
| Line points | `24,66 40,55 52,60.8 74,36.2` |
| Sparkle centre | (55.5, 24.2) |
| Sparkle radius | 6.8 |
| `artTransform` | `translate(-2.53 3.85) scale(1.05)` |

### artTransform derivation

Bounding box of all elements (nodes + sparkle) in original space:

- X: 19.5 → 80.56 (width 61.06)
- Y: 17.4 → 70.5 (height 53.1)
- Centre: (50.03, 43.95)

Scale: `64 / 61.06 = 1.05` (dominant axis fills `100 − 2×18 = 64` units)  
Translate: `(50 − 1.05×50.03, 50 − 1.05×43.95) = (−2.53, 3.85)`
