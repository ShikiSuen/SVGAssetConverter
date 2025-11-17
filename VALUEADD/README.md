# VALUEADD - Generated PNG Template Assets

This directory contains 18 PNG template images generated from SVG source files, optimized for use in watchOS widgets and other Apple platforms.

## Generation Date
Generated: November 17, 2024

## Contents

All files are 96x96 pixel PNG images with RGBA color space and transparency.

### Game: Genshin Impact
- `icon.dailyTask.gi.png` (2,735 bytes) - Daily commission tasks icon
- `icon.expedition.gi.png` (3,678 bytes) - Expedition icon
- `icon.resin.png` (1,977 bytes) - Original Resin icon  
- `icon.transformer.png` (4,005 bytes) - Parametric Transformer icon
- `icon.trounceBlossom.png` (2,656 bytes) - Trounce Blossom (weekly boss) icon
- `icon.homeCoin.png` (4,298 bytes) - Realm Currency icon

### Game: Honkai: Star Rail
- `icon.dailyTask.hsr.png` (3,159 bytes) - Daily training icon
- `icon.expedition.hsr.png` (2,801 bytes) - Assignment icon
- `icon.trailblazePower.png` (5,736 bytes) - Trailblaze Power icon
- `icon.echoOfWar.png` (2,986 bytes) - Echo of War (weekly boss) icon
- `icon.simulatedUniverse.png` (6,213 bytes) - Simulated Universe icon

### Game: Zenless Zone Zero
- `icon.dailyTask.zzz.png` (2,596 bytes) - Daily engagement icon
- `icon.zzzBattery.png` (5,055 bytes) - Battery icon
- `icon.zzzVHSStore.png` (3,227 bytes) - VHS Store icon
- `icon.zzzScratch.png` (2,729 bytes) - Scratch Card icon
- `icon.zzzBounty.png` (3,668 bytes) - Bounty Commission icon
- `icon.zzzInvestigation.png` (2,279 bytes) - Investigation icon

### General
- `icon.info.unavailable.png` (2,902 bytes) - Information unavailable icon

## Usage in Xcode

1. Add these PNG files to your Xcode asset catalog
2. For each asset, set the "Render As" property to "Template Image" in the Attributes Inspector
3. The icons will automatically adapt to your app's tint color

Example in SwiftUI:
```swift
Image("icon.resin")
    .renderingMode(.template)
    .foregroundColor(.accentColor)
```

## Regeneration

To regenerate these assets from the source SVG files, run:
```bash
python3 convert_svg_to_png.py
```

This will process all SVG files in `Sources/SVGAssetConverter/Resources/Media.xcassets/Icons4EmbeddedWidgets/` and output updated PNG files to this directory.

## Validation

All assets have been validated to ensure:
- ✓ Correct dimensions (96x96 pixels)
- ✓ Valid PNG format with RGBA color space
- ✓ Visible content (not all-transparent)
- ✓ Proper alpha channel for transparency/tinting

## License

These assets are part of the SVGAssetConverter project and are released under the AGPL v3.0 License or later.

© 2024 and onwards Pizza Studio
