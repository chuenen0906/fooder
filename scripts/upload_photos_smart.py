#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
智慧版本 Firebase Storage 上傳腳本
只處理最新的 N 間餐廳，避免檢查所有餐廳
"""

import firebase_admin
from firebase_admin import credentials, storage
import json
import os
import argparse
from datetime import datetime
import glob

def upload_restaurant_photos(restaurant_name, photo_folder, bucket):
    """上傳單一餐廳的照片到 Firebase Storage"""
    
    print(f"🔄 處理餐廳：{restaurant_name}")
    
    # 檢查照片資料夾是否存在
    if not os.path.exists(photo_folder):
        print(f"❌ 照片資料夾不存在：{photo_folder}")
        return None
    
    # 取得所有照片檔案
    photo_extensions = ['*.jpg', '*.jpeg', '*.png', '*.gif']
    photo_files = []
    for ext in photo_extensions:
        photo_files.extend(glob.glob(os.path.join(photo_folder, ext)))
        photo_files.extend(glob.glob(os.path.join(photo_folder, ext.upper())))
    
    if not photo_files:
        print(f"❌ 在資料夾中找不到照片：{photo_folder}")
        return None
    
    # 排序照片檔案
    photo_files.sort()
    
    # 刪除舊照片（如果存在）
    try:
        blobs = bucket.list_blobs(prefix=f'restaurant_photos/{restaurant_name}/')
        for blob in blobs:
            if not blob.name.endswith('/'):
                print(f"🗑️ 刪除舊照片：{blob.name}")
                blob.delete()
    except Exception as e:
        print(f"⚠️ 刪除舊照片時發生錯誤：{e}")
    
    # 上傳新照片
    uploaded_photos = []
    for i, photo_path in enumerate(photo_files, 1):
        file_ext = os.path.splitext(photo_path)[1]
        firebase_path = f'restaurant_photos/{restaurant_name}/{restaurant_name}_{i}{file_ext}'
        
        try:
            blob = bucket.blob(firebase_path)
            blob.upload_from_filename(photo_path)
            
            # 設定公開讀取權限
            blob.make_public()
            
            photo_url = blob.public_url
            uploaded_photos.append(photo_url)
            print(f"✅ 上傳成功：{os.path.basename(photo_path)}")
            
        except Exception as e:
            print(f"❌ 上傳失敗：{photo_path} - {e}")
    
    if uploaded_photos:
        return {
            'name': restaurant_name,
            'photos': uploaded_photos,
            'uploaded_at': datetime.now().isoformat()
        }
    else:
        return None

def get_latest_restaurants(latest_count):
    """取得最新的 N 間餐廳"""
    
    # 讀取餐廳資料
    try:
        with open('tainan_markets.json', 'r', encoding='utf-8') as f:
            restaurants = json.load(f)
    except FileNotFoundError:
        print("❌ 找不到 tainan_markets.json")
        return []
    
    # 取得最新的 N 間餐廳
    latest_restaurants = restaurants[-latest_count:] if latest_count > 0 else restaurants
    
    print(f"📊 處理最新的 {len(latest_restaurants)} 間餐廳")
    return latest_restaurants

def main():
    parser = argparse.ArgumentParser(description='智慧版本 Firebase Storage 上傳腳本')
    parser.add_argument('--latest', type=int, help='只處理最新的 N 間餐廳')
    parser.add_argument('--name', type=str, help='指定要處理的餐廳名稱')
    parser.add_argument('--firebase-key', default='folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json', 
                       help='Firebase 金鑰檔案路徑')
    
    args = parser.parse_args()
    
    # 初始化 Firebase
    try:
        cred = credentials.Certificate(args.firebase_key)
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'folder-47165.firebasestorage.app'
        })
        bucket = storage.bucket()
        print("✅ Firebase Storage 連接成功")
    except Exception as e:
        print(f"❌ Firebase 連接失敗: {e}")
        return
    
    # 取得要處理的餐廳
    if args.name:
        # 直接指定餐廳名稱
        try:
            with open('tainan_markets.json', 'r', encoding='utf-8') as f:
                restaurants = json.load(f)
            restaurant = next((r for r in restaurants if r['name'] == args.name), None)
            if not restaurant:
                print(f"❌ 找不到指定餐廳：{args.name}")
                return
            restaurants = [restaurant]
            print(f"📊 處理指定餐廳：{args.name}")
        except Exception as e:
            print(f"❌ 讀取餐廳資料失敗: {e}")
            return
    elif args.latest:
        restaurants = get_latest_restaurants(args.latest)
    else:
        # 如果沒有指定 --latest，處理所有餐廳
        try:
            with open('tainan_markets.json', 'r', encoding='utf-8') as f:
                restaurants = json.load(f)
        except FileNotFoundError:
            print("❌ 找不到 tainan_markets.json")
            return
    
    # 上傳照片
    uploaded_restaurants = []
    
    for restaurant in restaurants:
        restaurant_name = restaurant['name']
        photo_folder = f'assets/restaurants_collection/{restaurant_name}'
        
        result = upload_restaurant_photos(restaurant_name, photo_folder, bucket)
        if result:
            uploaded_restaurants.append(result)
    
    # 儲存上傳記錄
    if uploaded_restaurants:
        with open('data/uploaded_restaurants_smart.json', 'w', encoding='utf-8') as f:
            json.dump(uploaded_restaurants, f, ensure_ascii=False, indent=2)
        
        total_photos = sum(len(r['photos']) for r in uploaded_restaurants)
        print(f"\n🎉 上傳完成！")
        print(f"📸 成功上傳 {len(uploaded_restaurants)} 間餐廳")
        print(f"📷 總照片數量：{total_photos} 張")
        print(f"📝 記錄已儲存至：data/uploaded_restaurants_smart.json")
    else:
        print("❌ 沒有成功上傳任何餐廳照片")

if __name__ == "__main__":
    main() 