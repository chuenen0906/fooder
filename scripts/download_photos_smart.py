#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
智慧照片下載腳本
可以指定只下載特定餐廳的照片，避免重複檢查所有餐廳
"""

import json
import os
from google_images_search import GoogleImagesSearch
import requests
import sys
from datetime import datetime
from dotenv import load_dotenv
load_dotenv()

# 從環境變數讀取 API Key，避免硬編碼
API_KEY = os.getenv('GOOGLE_API_KEY')
CX = os.getenv('GOOGLE_CX')

if not API_KEY or not CX:
    raise ValueError("請設定環境變數 GOOGLE_API_KEY 和 GOOGLE_CX")

def get_image_ext(url):
    for ext in ['.jpg', '.jpeg', '.png', '.gif']:
        if ext in url.lower():
            return ext
    return '.jpg'  # 預設

def has_existing_photo(shop_dir):
    """檢查店家目錄是否已有照片"""
    if not os.path.exists(shop_dir):
        return False
    
    # 檢查目錄中是否有圖片檔案
    for file in os.listdir(shop_dir):
        if file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            return True
    return False

def download_photos_for_restaurants(restaurant_names=None, skip_existing=True):
    """
    為指定餐廳下載照片
    
    Args:
        restaurant_names: 餐廳名稱列表，如果為 None 則處理所有餐廳
        skip_existing: 是否跳過已有照片的餐廳
    """
    
    # 讀取餐廳資料
    with open('tainan_markets.json', 'r', encoding='utf-8') as f:
        all_restaurants = json.load(f)

    output_dir = 'downloaded_photos'
    os.makedirs(output_dir, exist_ok=True)

    gis = GoogleImagesSearch(API_KEY, CX)
    
    # 篩選要處理的餐廳
    if restaurant_names:
        restaurants_to_process = [r for r in all_restaurants if r['name'] in restaurant_names]
        print(f"🎯 指定處理 {len(restaurants_to_process)} 家餐廳")
    else:
        restaurants_to_process = all_restaurants
        print(f"📋 處理所有 {len(restaurants_to_process)} 家餐廳")

    new_downloads = 0
    skipped_existing = 0
    failed_downloads = 0

    for restaurant in restaurants_to_process:
        name = restaurant['name']
        area = restaurant['area']
        keyword = f"台南 {area} {name} 店面"
        shop_dir = os.path.join(output_dir, name)
        
        # 檢查是否已有照片
        if skip_existing and has_existing_photo(shop_dir):
            print(f"⏭️  {name} 已有照片，跳過下載")
            skipped_existing += 1
            continue
        
        os.makedirs(shop_dir, exist_ok=True)
        print(f"🔍 搜尋並下載：{keyword}")

        _search_params = {
            'q': keyword,
            'num': 1,  # 每家只抓一張主圖
            'safe': 'off',
            'fileType': 'jpg|png',
            'imgType': 'photo',
            'imgSize': 'large',
        }
        
        try:
            gis.search(_search_params)
            download_success = False
            
            for image in gis.results():
                img_url = image.url
                img_data = requests.get(img_url).content
                img_ext = get_image_ext(img_url)
                img_path = os.path.join(shop_dir, f"{name}{img_ext}")
                
                with open(img_path, 'wb') as handler:
                    handler.write(img_data)
                
                print(f"✅ {name} 圖片已下載：{img_path}")
                new_downloads += 1
                download_success = True
                break  # 只抓第一張
            
            if not download_success:
                print(f"⚠️ {name} 沒有找到適合的圖片")
                failed_downloads += 1
                
        except Exception as e:
            print(f"❌ {name} 下載失敗：{e}")
            failed_downloads += 1

    # 統計結果
    print(f"\n📊 下載統計：")
    print(f"✅ 新下載: {new_downloads} 張")
    print(f"⏭️  跳過已存在: {skipped_existing} 張")
    print(f"❌ 下載失敗: {failed_downloads} 張")
    print(f"📈 總處理: {len(restaurants_to_process)} 家餐廳")
    print(f"⏰ 完成時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

def get_latest_restaurants(count=10):
    """取得最新加入的餐廳名稱"""
    with open('tainan_markets.json', 'r', encoding='utf-8') as f:
        all_restaurants = json.load(f)
    
    # 取得最後 N 家餐廳
    latest = all_restaurants[-count:] if count <= len(all_restaurants) else all_restaurants
    return [r['name'] for r in latest]

def main():
    """主程式"""
    print("🍽️ 智慧照片下載工具")
    print("=" * 50)
    
    if len(sys.argv) > 1:
        # 命令列參數模式
        if sys.argv[1] == "--latest":
            count = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            restaurant_names = get_latest_restaurants(count)
            print(f"📋 下載最新 {len(restaurant_names)} 家餐廳的照片：")
            for name in restaurant_names:
                print(f"  - {name}")
            print()
            download_photos_for_restaurants(restaurant_names)
        elif sys.argv[1] == "--all":
            print("📋 下載所有餐廳的照片")
            download_photos_for_restaurants()
        else:
            # 指定餐廳名稱
            restaurant_names = sys.argv[1:]
            print(f"🎯 下載指定餐廳的照片：{restaurant_names}")
            download_photos_for_restaurants(restaurant_names)
    else:
        # 互動模式
        print("選擇下載模式：")
        print("1. 下載最新加入的餐廳照片")
        print("2. 下載指定餐廳照片")
        print("3. 下載所有餐廳照片")
        
        choice = input("\n請選擇 (1-3)：").strip()
        
        if choice == "1":
            count = input("要下載最新幾家餐廳的照片？(預設: 10)：").strip()
            count = int(count) if count else 10
            restaurant_names = get_latest_restaurants(count)
            print(f"\n📋 將下載最新 {len(restaurant_names)} 家餐廳：")
            for name in restaurant_names:
                print(f"  - {name}")
            
            confirm = input(f"\n確定要下載這些餐廳的照片嗎？(y/N)：").strip().lower()
            if confirm == 'y':
                download_photos_for_restaurants(restaurant_names)
            else:
                print("❌ 已取消")
                
        elif choice == "2":
            names_input = input("請輸入餐廳名稱（用逗號分隔）：").strip()
            restaurant_names = [name.strip() for name in names_input.split(',')]
            download_photos_for_restaurants(restaurant_names)
            
        elif choice == "3":
            confirm = input("確定要處理所有餐廳嗎？這可能需要較長時間 (y/N)：").strip().lower()
            if confirm == 'y':
                download_photos_for_restaurants()
            else:
                print("❌ 已取消")
        else:
            print("❌ 無效選擇")

if __name__ == "__main__":
    main() 