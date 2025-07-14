#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
為新餐廳產生文字佔位圖
不需要 Google API Key，直接產生本地照片
"""

import json
import os
from PIL import Image, ImageDraw, ImageFont
import argparse

def create_placeholder_photo(restaurant_name, specialty, output_path):
    """為餐廳產生佔位圖"""
    # 建立 400x300 的圖片
    width, height = 400, 300
    img = Image.new('RGB', (width, height), color='#f0f0f0')
    draw = ImageDraw.Draw(img)
    
    # 嘗試使用系統字體，如果沒有則使用預設
    try:
        # 在 macOS 上嘗試使用系統中文字體
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 24)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 16)
    except:
        try:
            # 備用字體
            font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 24)
            font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 16)
        except:
            # 使用預設字體
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    # 繪製餐廳名稱
    text = restaurant_name
    bbox = draw.textbbox((0, 0), text, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (width - text_width) // 2
    text_y = height // 2 - 30
    
    # 繪製背景矩形
    padding = 10
    rect_x1 = text_x - padding
    rect_y1 = text_y - padding
    rect_x2 = text_x + text_width + padding
    rect_y2 = text_y + 30 + padding
    draw.rectangle([rect_x1, rect_y1, rect_x2, rect_y2], fill='#ffffff', outline='#cccccc')
    
    # 繪製文字
    draw.text((text_x, text_y), text, fill='#333333', font=font_large)
    
    # 繪製特色料理
    specialty_text = f"特色：{specialty}"
    bbox = draw.textbbox((0, 0), specialty_text, font=font_small)
    specialty_width = bbox[2] - bbox[0]
    specialty_x = (width - specialty_width) // 2
    specialty_y = text_y + 40
    
    draw.text((specialty_x, specialty_y), specialty_text, fill='#666666', font=font_small)
    
    # 儲存圖片
    img.save(output_path, 'JPEG', quality=85)
    return output_path

def get_latest_restaurants(count=10):
    """取得最新加入的餐廳"""
    with open('tainan_markets.json', 'r', encoding='utf-8') as f:
        all_restaurants = json.load(f)
    
    # 取得最後 N 家餐廳
    latest = all_restaurants[-count:] if count <= len(all_restaurants) else all_restaurants
    return latest

def main():
    parser = argparse.ArgumentParser(description='為新餐廳產生佔位圖')
    parser.add_argument('--latest', type=int, help='處理最新的 N 間餐廳')
    parser.add_argument('--restaurant', type=str, help='處理指定餐廳')
    args = parser.parse_args()
    
    # 建立輸出目錄
    output_dir = 'downloaded_photos'
    os.makedirs(output_dir, exist_ok=True)
    
    # 決定要處理的餐廳
    if args.restaurant:
        # 處理指定餐廳
        with open('tainan_markets.json', 'r', encoding='utf-8') as f:
            all_restaurants = json.load(f)
        restaurants_to_process = [r for r in all_restaurants if r['name'] == args.restaurant]
        if not restaurants_to_process:
            print(f"❌ 找不到餐廳: {args.restaurant}")
            return
        print(f"🎯 處理指定餐廳: {args.restaurant}")
    elif args.latest:
        # 處理最新的 N 間餐廳
        restaurants_to_process = get_latest_restaurants(args.latest)
        print(f"🎯 處理最新的 {args.latest} 間餐廳")
    else:
        print("❌ 請指定 --latest N 或 --restaurant 名稱")
        return
    
    created_count = 0
    skipped_count = 0
    
    for i, restaurant in enumerate(restaurants_to_process, 1):
        restaurant_name = restaurant['name']
        specialty = restaurant.get('specialty', '')
        
        # 檢查是否已有照片
        photo_path = os.path.join(output_dir, f"{restaurant_name}.jpg")
        if os.path.exists(photo_path):
            print(f"[{i}/{len(restaurants_to_process)}] ⏭️  跳過：{restaurant_name} (已有照片)")
            skipped_count += 1
            continue
        
        # 產生佔位圖
        try:
            create_placeholder_photo(restaurant_name, specialty, photo_path)
            print(f"[{i}/{len(restaurants_to_process)}] ✅ 建立：{restaurant_name}")
            created_count += 1
        except Exception as e:
            print(f"[{i}/{len(restaurants_to_process)}] ❌ 失敗：{restaurant_name} - {e}")
    
    print(f"\n🎉 完成！")
    print(f"📊 新建照片：{created_count} 張")
    print(f"⏭️  跳過已有：{skipped_count} 張")
    print(f"📁 照片儲存在：{output_dir}/")

if __name__ == "__main__":
    main() 