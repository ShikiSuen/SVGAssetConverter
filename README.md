# SVGAssetConverter

A Python utility to convert Apple SF Symbol template SVG files into 96x96 PNG "template" images suitable for tinting in watchOS widgets.

## Overview

This project contains a collection of custom icon assets designed for embedded widgets in game companion apps. The icons are provided as SVG files in Apple SF Symbol format and are converted to PNG templates that can be tinted in watchOS and other Apple platforms.

## Generated Assets

All generated PNG assets are located in the `VALUEADD/` directory. These are 96x96 pixel PNG images with transparency, optimized for use as template images that can be tinted to match your app's color scheme.

### Available Icons

- `icon.dailyTask.gi.png` - Genshin Impact daily task icon
- `icon.dailyTask.hsr.png` - Honkai: Star Rail daily task icon
- `icon.dailyTask.zzz.png` - Zenless Zone Zero daily task icon
- `icon.echoOfWar.png` - Echo of War icon
- `icon.expedition.gi.png` - Genshin Impact expedition icon
- `icon.expedition.hsr.png` - Honkai: Star Rail expedition icon
- `icon.homeCoin.png` - Home Coin icon
- `icon.info.unavailable.png` - Information unavailable icon
- `icon.resin.png` - Original Resin icon
- `icon.simulatedUniverse.png` - Simulated Universe icon
- `icon.trailblazePower.png` - Trailblaze Power icon
- `icon.transformer.png` - Parametric Transformer icon
- `icon.trounceBlossom.png` - Trounce Blossom icon
- `icon.zzzBattery.png` - ZZZ Battery icon
- `icon.zzzBounty.png` - ZZZ Bounty icon
- `icon.zzzInvestigation.png` - ZZZ Investigation icon
- `icon.zzzScratch.png` - ZZZ Scratch Card icon
- `icon.zzzVHSStore.png` - ZZZ VHS Store icon

## Usage

### Converting SVG to PNG

To regenerate all PNG assets from the source SVG files:

```bash
python3 convert_svg_to_png.py
```

This will:
1. Extract the symbol content from each Apple SF Symbol template SVG
2. Convert them to 96x96 PNG files with black fills
3. Verify that each PNG is valid and contains visible content
4. Output all files to the `VALUEADD/` directory

### Requirements

The conversion script requires the following tools to be installed:

- **Python 3.x**
- **Inkscape** - For SVG to PNG conversion
- **ImageMagick** - For PNG verification

#### Installing Dependencies on Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y inkscape imagemagick python3
```

#### Installing Dependencies on macOS

```bash
brew install inkscape imagemagick python3
```

## Technical Details

### SVG Format

The source SVG files use the Apple SF Symbol template format, which includes:
- Multiple weight variations (Ultralight, Thin, Light, Regular, Medium, Semibold, Bold, Heavy, Black)
- Multiple scale variations (Small, Medium, Large)
- Guides and metadata for symbol design

The conversion script extracts the "Regular-M" (Regular weight, Medium scale) or "Regular-S" (Regular weight, Small scale) symbol from each SVG file.

### PNG Format

Generated PNG files are:
- **Size**: 96x96 pixels
- **Color**: RGBA (with alpha channel for transparency)
- **Format**: PNG
- **Usage**: Template images (can be tinted in code)

### Template Images for watchOS

These PNG files are designed to work as template images in watchOS widgets. To use them in your Xcode project:

1. Add the PNG files to your asset catalog
2. In the asset inspector, set "Render As" to "Template Image"
3. The icon will automatically adapt to your widget's tint color

## License

This code is released under the AGPL v3.0 License or later.

© 2024 and onwards Pizza Studio

## Source Files

The original SVG files are located in:
```
Sources/SVGAssetConverter/Resources/Media.xcassets/Icons4EmbeddedWidgets/
```

Each icon is stored in its own `.symbolset` directory following Apple's SF Symbol format.
