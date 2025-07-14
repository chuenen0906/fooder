#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
檢查 Firebase Storage 使用狀況
"""

import firebase_admin
from firebase_admin import credentials, storage
import json
from datetime import datetime

def check_firebase_storage():
    """檢查 Firebase Storage 使用狀況"""
    
    # 初始化 Firebase
    try:
        cred = credentials.Certificate('folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'folder-47165.firebasestorage.app'
        })
        bucket = storage.bucket()
        print("✅ Firebase Storage 連接成功")
    except Exception as e:
        print(f"❌ Firebase 連接失敗: {e}")
        return

    # 統計 Storage 中的照片
    print("\n📊 Firebase Storage 統計：")
    print("=" * 50)
    
    total_files = 0
    total_size = 0
    restaurant_photos = {}
    
    try:
        # 列出所有照片
        blobs = bucket.list_blobs(prefix='restaurant_photos/')
        
        for blob in blobs:
            if blob.name.endswith(('/', '')):  # 跳過目錄
                continue
                
            total_files += 1
            total_size += blob.size
            
            # 解析餐廳名稱
            path_parts = blob.name.split('/')
            if len(path_parts) >= 3:
                restaurant_name = path_parts[1]
                if restaurant_name not in restaurant_photos:
                    restaurant_photos[restaurant_name] = []
                restaurant_photos[restaurant_name].append({
                    'name': path_parts[2],
                    'size': blob.size,
                    'updated': blob.updated.strftime('%Y-%m-%d %H:%M:%S') if blob.updated else 'N/A'
                })
        
        print(f"📷 總照片數量：{total_files} 張")
        print(f"💾 總儲存空間：{format_size(total_size)}")
        print(f"🏪 有照片餐廳：{len(restaurant_photos)} 間")
        print(f"📱 平均每張照片：{format_size(total_size / total_files) if total_files > 0 else '0 B'}")
        
        # Firebase Storage 免費額度資訊
        print(f"\n☁️ Firebase Storage 免費額度：")
        print(f"📦 儲存空間限制：5 GB")
        print(f"📥 每日下載限制：1 GB")
        print(f"📤 每日上傳限制：20,000 次操作")
        
        # 使用率計算
        free_storage_gb = 5.0
        used_storage_gb = total_size / (1024**3)
        usage_percentage = (used_storage_gb / free_storage_gb) * 100
        
        print(f"\n📊 空間使用率：")
        print(f"已使用：{format_size(total_size)} ({usage_percentage:.3f}%)")
        print(f"剩餘：{format_size((free_storage_gb * 1024**3) - total_size)} ({100-usage_percentage:.3f}%)")
        
        # 顯示前10個最新上傳的餐廳
        if restaurant_photos:
            print(f"\n📸 最近上傳的餐廳照片 (前10個)：")
            sorted_restaurants = sorted(
                restaurant_photos.items(),
                key=lambda x: max(photo['updated'] for photo in x[1]) if x[1] else '',
                reverse=True
            )
            
            for i, (name, photos) in enumerate(sorted_restaurants[:10], 1):
                if photos:
                    latest_photo = max(photos, key=lambda x: x['updated'])
                    print(f"  {i:2d}. {name} - {latest_photo['updated']} ({format_size(latest_photo['size'])})")
        
        # 容量預測
        if total_files > 0:
            avg_size = total_size / total_files
            remaining_restaurants = 246 - len(restaurant_photos)
            estimated_additional_size = remaining_restaurants * avg_size
            total_estimated_size = total_size + estimated_additional_size
            
            print(f"\n🔮 容量預測（假設所有246間餐廳都有照片）：")
            print(f"預估總容量：{format_size(total_estimated_size)}")
            print(f"預估使用率：{(total_estimated_size / (free_storage_gb * 1024**3)) * 100:.2f}%")
            
            if total_estimated_size > (free_storage_gb * 1024**3):
                print("⚠️ 警告：預估會超過免費額度！")
            else:
                print("✅ 預估在免費額度範圍內")
    
    except Exception as e:
        print(f"❌ 統計失敗: {e}")

def format_size(size_bytes):
    """格式化檔案大小"""
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024**2:
        return f"{size_bytes/1024:.1f} KB"
    elif size_bytes < 1024**3:
        return f"{size_bytes/(1024**2):.1f} MB"
    else:
        return f"{size_bytes/(1024**3):.2f} GB"

if __name__ == "__main__":
    print("🔍 Firebase Storage 使用狀況檢查")
    print("=" * 50)
    check_firebase_storage() 