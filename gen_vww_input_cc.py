#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import glob
import numpy as np
from PIL import Image

# ================= 設定區 =================
INPUT_DIR = './graph'
OUTPUT_DIR = './graph'


MODEL_INPUT_W = 96
MODEL_INPUT_H = 96
QUANT_SCALE = 0.003921568859368563  
QUANT_ZERO_POINT = -128
# =========================================

def main():
    if not os.path.exists(INPUT_DIR):
        print(f"Error: Directory '{INPUT_DIR}' not found.")
        return

    exts = ['*.jpg', '*.jpeg', '*.png', '*.bmp']
    image_files = []
    for ext in exts:
        image_files.extend(glob.glob(os.path.join(INPUT_DIR, ext)))
        image_files.extend(glob.glob(os.path.join(INPUT_DIR, ext.upper())))
    
    image_files = sorted(list(set(image_files)))

    if not image_files:
        print(f"No images found in {INPUT_DIR}")
        return

    print(f"Found {len(image_files)} images. Converting using hardcoded params...")

    for img_path in image_files:
        try:
            img = Image.open(img_path).convert('RGB')
            
            w, h = img.size
            min_dim = min(w, h)
            left = (w - min_dim) // 2
            top = (h - min_dim) // 2
            img = img.crop((left, top, left + min_dim, top + min_dim))
            
            img = img.resize((MODEL_INPUT_W, MODEL_INPUT_H), Image.BILINEAR)
            
            img_array = np.array(img, dtype=np.float32) / 255.0
            
            q_img = (img_array / QUANT_SCALE) + QUANT_ZERO_POINT
            
            q_img = np.clip(q_img, -128, 127).astype(np.int8)
            
            filename = os.path.splitext(os.path.basename(img_path))[0]
            safe_name = "".join([c if c.isalnum() else "_" for c in filename])
            
            c_code = f"// Auto-generated from {os.path.basename(img_path)}\n"
            c_code += f"// Fixed Params: {MODEL_INPUT_W}x{MODEL_INPUT_H}, Scale={QUANT_SCALE:.6f}, ZP={QUANT_ZERO_POINT}\n"
            c_code += f"#include <stdint.h>\n\n"
            c_code += f"const int8_t g_image_{safe_name}_data[] = {{\n"
            c_code += "  " + ", ".join(map(str, q_img.flatten()))
            c_code += "\n};\n"
            
            output_path = os.path.join(OUTPUT_DIR, f"{filename}.cc")
            with open(output_path, 'w') as f:
                f.write(c_code)
                
            print(f"Generated: {filename}.cc")

        except Exception as e:
            print(f"Error processing {img_path}: {e}")

if __name__ == '__main__':
    main()