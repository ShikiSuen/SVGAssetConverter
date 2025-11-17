#!/usr/bin/env python3
from PIL import Image
import numpy as np
from pathlib import Path

valueadd = Path('VALUEADD')
png_files = sorted(valueadd.glob('*.png'))

print("Checking for cropped/clipped content:\n")

for png_file in png_files:
    img = Image.open(png_file)
    arr = np.array(img)
    
    if img.mode == 'RGBA':
        alpha = arr[:, :, 3]
        
        # Find bounding box of non-transparent pixels
        rows = np.any(alpha > 10, axis=1)
        cols = np.any(alpha > 10, axis=0)
        
        if rows.any() and cols.any():
            ymin, ymax = np.where(rows)[0][[0, -1]]
            xmin, xmax = np.where(cols)[0][[0, -1]]
            
            content_width = xmax - xmin + 1
            content_height = ymax - ymin + 1
            
            # Check if content touches edges (indicating possible cropping)
            is_cropped = (ymin == 0 or ymax == img.height - 1 or 
                         xmin == 0 or xmax == img.width - 1)
            
            status = "⚠" if is_cropped else "✓"
            
            print(f"{status} {png_file.name:35} size={content_width:2}x{content_height:2} padding=(t:{ymin:2},b:{img.height-ymax-1:2},l:{xmin:2},r:{img.width-xmax-1:2})")
