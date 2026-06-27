#!/usr/bin/env python3
"""
Icon asset pipeline for PeakLog.

Workflow:
    Edit assets/icon/app_icon.svg
        ↓
    python3 scripts/generate_icons.py
        ↓
    All iOS + Android icons regenerated

Source of truth: assets/icon/app_icon.svg
"""

import os
import sys

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------

try:
    import cairosvg
except (ImportError, OSError) as e:
    if "cairo" in str(e).lower() and "library" in str(e).lower():
        print("cairo native library not found.")
        print("On macOS, install it with:")
        print("  brew install cairo")
        print("Then ensure your shell uses the Homebrew Python (see assets/icon/README.md).")
    else:
        print("cairosvg is not installed. Run:")
        print("  pip3 install cairosvg")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG_SOURCE  = os.path.join(REPO_ROOT, "assets", "icon", "app_icon.svg")
IOS_DIR     = os.path.join(REPO_ROOT, "ios", "Runner", "Assets.xcassets",
                           "AppIcon.appiconset")
ANDROID_RES = os.path.join(REPO_ROOT, "android", "app", "src", "main", "res")

# ---------------------------------------------------------------------------
# Icon size tables
# (filename, pixel_size) — derived from iOS AppIcon.appiconset/Contents.json
# ---------------------------------------------------------------------------

IOS_ICONS = [
    ("Icon-App-20x20@1x.png",       20),
    ("Icon-App-20x20@2x.png",       40),
    ("Icon-App-20x20@3x.png",       60),
    ("Icon-App-29x29@1x.png",       29),
    ("Icon-App-29x29@2x.png",       58),
    ("Icon-App-29x29@3x.png",       87),
    ("Icon-App-40x40@1x.png",       40),
    ("Icon-App-40x40@2x.png",       80),
    ("Icon-App-40x40@3x.png",      120),
    ("Icon-App-50x50@1x.png",       50),
    ("Icon-App-50x50@2x.png",      100),
    ("Icon-App-57x57@1x.png",       57),
    ("Icon-App-57x57@2x.png",      114),
    ("Icon-App-60x60@2x.png",      120),
    ("Icon-App-60x60@3x.png",      180),
    ("Icon-App-72x72@1x.png",       72),
    ("Icon-App-72x72@2x.png",      144),
    ("Icon-App-76x76@1x.png",       76),
    ("Icon-App-76x76@2x.png",      152),
    ("Icon-App-83.5x83.5@2x.png",  167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

# (mipmap density folder, pixel_size)
ANDROID_ICONS = [
    ("mipmap-mdpi",     48),
    ("mipmap-hdpi",     72),
    ("mipmap-xhdpi",    96),
    ("mipmap-xxhdpi",  144),
    ("mipmap-xxxhdpi", 192),
]

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------

def render(svg_bytes, out_path, size):
    cairosvg.svg2png(bytestring=svg_bytes, write_to=out_path,
                     output_width=size, output_height=size)

def main():
    if not os.path.exists(SVG_SOURCE):
        print(f"Source SVG not found: {SVG_SOURCE}")
        sys.exit(1)

    with open(SVG_SOURCE, "rb") as f:
        svg_bytes = f.read()

    # iOS
    ios_ok = 0
    for filename, size in IOS_ICONS:
        out = os.path.join(IOS_DIR, filename)
        render(svg_bytes, out, size)
        if os.path.exists(out):
            ios_ok += 1

    # Android
    android_ok = 0
    for density, size in ANDROID_ICONS:
        out = os.path.join(ANDROID_RES, density, "ic_launcher.png")
        render(svg_bytes, out, size)
        if os.path.exists(out):
            android_ok += 1

    # Summary
    ios_total     = len(IOS_ICONS)
    android_total = len(ANDROID_ICONS)
    ios_status     = "✓" if ios_ok     == ios_total     else "✗"
    android_status = "✓" if android_ok == android_total else "✗"
    print(f"{ios_status} Generated {ios_ok}/{ios_total} iOS icons")
    print(f"{android_status} Generated {android_ok}/{android_total} Android icons")
    print("Done.")

    if ios_ok < ios_total or android_ok < android_total:
        sys.exit(1)

if __name__ == "__main__":
    main()
