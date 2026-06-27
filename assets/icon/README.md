# App Icon

`assets/icon/app_icon.svg` is the single source of truth for the PeakLog launcher icon.

**Edit only this file when changing the app icon.**

## Regenerating icons

```bash
make icons
```

Or, if Make isn't available:

```bash
python3 scripts/generate_icons.py
```

This overwrites every iOS AppIcon asset under
`ios/Runner/Assets.xcassets/AppIcon.appiconset/` and every Android launcher
icon under `android/app/src/main/res/mipmap-*/ic_launcher.png`.

## Setup

### Python dependency

```bash
pip3 install cairosvg
```

### macOS — cairo native library

cairosvg requires the native cairo graphics library. Install it via Homebrew:

```bash
brew install cairo
```

If `python3` on your PATH is the Xcode stub (`/usr/bin/python3`), it won't
see the Homebrew cairo. The fix is to ensure the Homebrew Python comes first:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="/opt/homebrew/bin:$PATH"
```

Then open a new shell and rerun `pip3 install cairosvg`.
