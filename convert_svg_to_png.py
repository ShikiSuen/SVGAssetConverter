#!/usr/bin/env python3
"""
SVG to PNG Converter for watchOS Widget Icons
Converts all SVG icon assets to 96x96 template PNG files.
"""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple

# Mapping from SVGIconAsset enum cases to their SVG file paths
ICON_MAPPINGS = {
    'icon.info.unavailable': 'icon.info.unavailable.symbolset/icon.info.unavailable.svg',
    'icon.resin': 'icon.resin.symbolset/resin.icon.svg',
    'icon.trailblazePower': 'icon.trailblazePower.symbolset/icon.trailblazePower.svg',
    'icon.zzzBattery': 'icon.zzzBattery.symbolset/icon.zzzBattery.svg',
    'icon.dailyTask.gi': 'icon.dailyTask.gi.symbolset/icon.dailyTask.gi.svg',
    'icon.dailyTask.hsr': 'icon.dailyTask.hsr.symbolset/icon.dailyTask.hsr.svg',
    'icon.dailyTask.zzz': 'icon.dailyTask.zzz.symbolset/icon.dailyTask.zzz.svg',
    'icon.expedition.gi': 'icon.expedition.gi.symbolset/icon.expedition.gi.svg',
    'icon.expedition.hsr': 'icon.expedition.hsr.symbolset/icon.expedition.hsr.svg',
    'icon.transformer': 'icon.transformer.symbolset/icon.transformer.svg',
    'icon.homeCoin': 'icon.homeCoin.symbolset/icon.homeCoin.svg',
    'icon.trounceBlossom': 'icon.trounceBlossom.symbolset/icon.trounceBlossom.svg',
    'icon.echoOfWar': 'icon.echoOfWar.symbolset/icon.echoOfWar.svg',
    'icon.simulatedUniverse': 'icon.simulatedUniverse.symbolset/icon.simulatedUniverse.svg',
    'icon.zzzVHSStore': 'icon.zzzVHSStore.symbolset/icon.zzzVHSStore.svg',
    'icon.zzzScratch': 'icon.zzzScratch.symbolset/icon.zzzScratch.svg',
    'icon.zzzBounty': 'icon.zzzBounty.symbolset/icon.zzzBounty.svg',
    'icon.zzzInvestigation': 'icon.zzzInvestigation.symbolset/icon.zzzInvestigation.svg',
}


def check_rsvg_convert() -> bool:
    """Check if rsvg-convert is available."""
    try:
        result = subprocess.run(['rsvg-convert', '--version'], 
                              capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False


def preprocess_svg_for_template(svg_path: Path) -> Path:
    """
    Preprocess an Apple SF Symbol SVG to make it renderable as a black template.
    
    This extracts only the symbol content from the 'Symbols' group and applies
    black fills to make it renderable.
    
    Args:
        svg_path: Path to the input SVG file
    
    Returns:
        Path to the temporary preprocessed SVG file
    """
    with open(svg_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()
    
    # Find the Symbols group start
    symbols_start = svg_content.find('<g id="Symbols">')
    if symbols_start == -1:
        return svg_path
    
    # Find the matching closing tag by counting opening and closing g tags
    pos = symbols_start + len('<g id="Symbols">')
    depth = 1
    while pos < len(svg_content) and depth > 0:
        if svg_content[pos:pos+3] == '<g ' or svg_content[pos:pos+3] == '<g>':
            depth += 1
            pos += 1
        elif svg_content[pos:pos+4] == '</g>':
            depth -= 1
            if depth == 0:
                symbols_end = pos + 4
                break
            pos += 1
        else:
            pos += 1
    else:
        # Couldn't find matching closing tag
        return svg_path
    
    # Extract the entire Symbols group
    symbols_group = svg_content[symbols_start:symbols_end]
    
    # Replace fill="none" with fill="black" and add stroke="black" for stroked paths
    # Also ensure all paths have fill="black"
    def fix_path_fill(match):
        path_tag = match.group(0)
        
        # Replace fill="none" with fill="black"
        path_tag = re.sub(r'fill="none"', 'fill="black"', path_tag)
        
        # If path has a stroke but no fill, or fill is still missing, ensure it has fill="black"
        if 'fill=' not in path_tag:
            path_tag = path_tag.replace('<path ', '<path fill="black" ')
        
        # For stroked paths, also add fill to make them visible
        if 'stroke=' in path_tag and 'fill="black"' not in path_tag:
            # If we just replaced fill="none" it will already have fill="black"
            # but if not, add it
            if 'fill=' not in path_tag:
                path_tag = path_tag.replace('<path ', '<path fill="black" ')
        
        return path_tag
    
    symbols_group = re.sub(r'<path\s+[^>]*>', fix_path_fill, symbols_group)
    
    # Create a new SVG with just the symbols group
    # Use the standard viewBox from Apple SF Symbol templates
    new_svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3300 2200">
{symbols_group}
</svg>
'''
    
    # Write to a temporary file
    temp_file = tempfile.NamedTemporaryFile(mode='w', suffix='.svg', delete=False, encoding='utf-8')
    temp_file.write(new_svg)
    temp_file.close()
    
    return Path(temp_file.name)


def convert_svg_to_png(svg_path: Path, png_path: Path, size: int = 96) -> bool:
    """
    Convert an SVG file to a PNG file using Inkscape, preserving aspect ratio.
    
    Args:
        svg_path: Path to the input SVG file
        png_path: Path to the output PNG file
        size: Output size (width and height in pixels)
    
    Returns:
        True if conversion was successful, False otherwise
    """
    temp_svg = None
    temp_png = None
    try:
        # Preprocess the SVG to extract just the symbol content
        temp_svg = preprocess_svg_for_template(svg_path)
        
        # Convert to absolute paths for Inkscape
        temp_svg_abs = temp_svg.resolve()
        png_path_abs = png_path.resolve()
        
        # Delete existing output file to ensure we can detect if new one is created
        if png_path.exists():
            png_path.unlink()
        
        # Create a temporary PNG path for the initial export
        temp_png = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
        temp_png.close()
        temp_png_path = Path(temp_png.name)
        
        # Try different symbol IDs - some symbols use Regular-M, others use Regular-S
        symbol_ids = ['Regular-M', 'Regular-S', 'Regular-L']
        
        for symbol_id in symbol_ids:
            # First, export to get the natural size to determine aspect ratio
            # Export at a large size to maintain quality
            test_size = 200
            cmd_test = [
                'inkscape',
                str(temp_svg_abs),
                f'--export-id={symbol_id}',
                '--export-id-only',
                f'--export-width={test_size}',
                '--export-type=png',
                f'--export-filename={str(temp_png_path.resolve())}'
            ]
            
            result = subprocess.run(cmd_test, capture_output=True, text=True)
            
            if result.returncode == 0 and temp_png_path.exists() and temp_png_path.stat().st_size > 0:
                # Load the test image to check dimensions
                from PIL import Image
                test_img = Image.open(temp_png_path)
                aspect_ratio = test_img.width / test_img.height
                
                # Export at a size that leaves some padding (use 90% of target size)
                # This ensures symbols don't touch the edges
                export_size = int(size * 0.92)  # Leave ~4px padding on each side
                
                # Now export at the correct size to fit within the target canvas
                # If width > height (landscape), use --export-width
                # If height > width (portrait), use --export-height
                # This ensures the image fits within size x size without being cropped
                if aspect_ratio >= 1.0:
                    # Landscape or square - constrain by width
                    cmd = [
                        'inkscape',
                        str(temp_svg_abs),
                        f'--export-id={symbol_id}',
                        '--export-id-only',
                        f'--export-width={export_size}',
                        '--export-type=png',
                        f'--export-filename={str(temp_png_path.resolve())}'
                    ]
                else:
                    # Portrait - constrain by height to avoid cropping
                    cmd = [
                        'inkscape',
                        str(temp_svg_abs),
                        f'--export-id={symbol_id}',
                        '--export-id-only',
                        f'--export-height={export_size}',
                        '--export-type=png',
                        f'--export-filename={str(temp_png_path.resolve())}'
                    ]
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0 and temp_png_path.exists():
                    # Now pad/center the image to make it exactly size x size
                    img = Image.open(temp_png_path)
                    
                    # Create a new transparent image of the target size
                    final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                    
                    # Calculate position to center the image
                    x_offset = (size - img.width) // 2
                    y_offset = (size - img.height) // 2
                    
                    # Paste the image centered
                    final_img.paste(img, (x_offset, y_offset), img if img.mode == 'RGBA' else None)
                    
                    # Save the final image
                    final_img.save(png_path_abs, 'PNG')
                    
                    # Clean up temp PNG
                    temp_png_path.unlink()
                    
                    return True
        
        # None of the symbol IDs worked
        print(f"Error converting {svg_path.name}: No valid symbol ID found")
        return False
        
    except Exception as e:
        print(f"Exception converting {svg_path.name}: {e}")
        return False
    finally:
        # Clean up temporary files
        if temp_svg and temp_svg != svg_path and temp_svg.exists():
            temp_svg.unlink()
        if temp_png and Path(temp_png.name).exists():
            Path(temp_png.name).unlink()


def verify_png(png_path: Path) -> Tuple[bool, str]:
    """
    Verify that a PNG file is valid and not all-transparent.
    
    Args:
        png_path: Path to the PNG file to verify
    
    Returns:
        Tuple of (is_valid, message)
    """
    if not png_path.exists():
        return False, "File does not exist"
    
    if png_path.stat().st_size == 0:
        return False, "File is empty"
    
    try:
        # Use ImageMagick's identify to check the image has non-transparent pixels
        # Check the alpha channel mean - if it's 0, the image is all-transparent
        cmd = ['identify', '-format', '%[fx:mean.a]', str(png_path)]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        
        if result.returncode != 0:
            return False, f"identify failed: {result.stderr}"
        
        # Get the mean alpha value (0 = fully transparent, 1 = fully opaque)
        try:
            alpha_mean = float(result.stdout.strip())
            # If mean alpha is very low (< 0.01), consider it all-transparent
            if alpha_mean < 0.01:
                return False, "Image is all-transparent"
            
            return True, "Valid"
        except ValueError:
            return False, f"Invalid alpha value: {result.stdout}"
        
    except subprocess.TimeoutExpired:
        return False, "Verification timeout"
    except Exception as e:
        return False, f"Verification error: {e}"


def main():
    """Main conversion process."""
    # Get the project root directory
    project_root = Path(__file__).parent
    resources_dir = project_root / 'Sources' / 'SVGAssetConverter' / 'Resources' / 'Media.xcassets' / 'Icons4EmbeddedWidgets'
    output_dir = project_root / 'VALUEADD'
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Converting SVG icons to 96x96 PNG template images...")
    print(f"Resources directory: {resources_dir}")
    print(f"Output directory: {output_dir}")
    print()
    
    converted_count = 0
    failed_count = 0
    invalid_count = 0
    
    for icon_name, svg_relative_path in sorted(ICON_MAPPINGS.items()):
        svg_path = resources_dir / svg_relative_path
        png_path = output_dir / f"{icon_name}.png"
        
        print(f"Converting {icon_name}...", end=" ")
        
        if not svg_path.exists():
            print(f"FAILED - SVG not found: {svg_path}")
            failed_count += 1
            continue
        
        # Convert SVG to PNG
        if convert_svg_to_png(svg_path, png_path):
            # Verify the generated PNG
            is_valid, message = verify_png(png_path)
            if is_valid:
                print(f"OK ({png_path.stat().st_size} bytes)")
                converted_count += 1
            else:
                print(f"INVALID - {message}")
                invalid_count += 1
        else:
            print("FAILED - Conversion error")
            failed_count += 1
    
    print()
    print("=" * 60)
    print(f"Conversion complete:")
    print(f"  Successfully converted: {converted_count}")
    print(f"  Invalid outputs: {invalid_count}")
    print(f"  Failed conversions: {failed_count}")
    print(f"  Total icons: {len(ICON_MAPPINGS)}")
    print("=" * 60)
    
    if converted_count == len(ICON_MAPPINGS):
        print("\n✓ All icons converted successfully!")
        return 0
    else:
        print(f"\n✗ {failed_count + invalid_count} icon(s) failed to convert properly.")
        return 1


if __name__ == '__main__':
    sys.exit(main())
