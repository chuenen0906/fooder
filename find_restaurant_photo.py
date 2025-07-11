#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
簡單的餐廳照片搜尋工具
"""

import firebase_admin
from firebase_admin import credentials, storage
import json
import os
import sys
from urllib.parse import unquote

def init_firebase():
    """初始化 Firebase"""
    try:
        cred = credentials.Certificate('folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'folder-47165.firebasestorage.app'
        })
        return storage.bucket()
    except Exception as e:
        print(f"❌ Firebase 初始化失敗: {e}")
        return None

def search_restaurants(query, bucket):
    """搜尋餐廳照片"""
    print(f"🔍 搜尋包含 '{query}' 的餐廳...")
    
    blobs = bucket.list_blobs(prefix='restaurant_photos/')
    matches = []
    
    for blob in blobs:
        if blob.name.endswith('/'):
            continue
            
        path_parts = blob.name.split('/')
        if len(path_parts) >= 3:
            restaurant_name = unquote(path_parts[1])
            if query.lower() in restaurant_name.lower():
                matches.append({
                    'name': restaurant_name,
                    'filename': path_parts[2],
                    'size': blob.size,
                    'updated': blob.updated.strftime('%Y-%m-%d %H:%M:%S') if blob.updated else 'N/A',
                    'url': f"https://storage.googleapis.com/folder-47165.firebasestorage.app/{blob.name}",
                    'blob_name': blob.name
                })
    
    return matches

def list_all_restaurants(bucket):
    """列出所有餐廳"""
    print("📋 所有餐廳列表...")
    
    blobs = bucket.list_blobs(prefix='restaurant_photos/')
    restaurants = {}
    
    for blob in blobs:
        if blob.name.endswith('/'):
            continue
            
        path_parts = blob.name.split('/')
        if len(path_parts) >= 3:
            restaurant_name = unquote(path_parts[1])
            if restaurant_name not in restaurants:
                restaurants[restaurant_name] = []
            
            restaurants[restaurant_name].append({
                'filename': path_parts[2],
                'size': blob.size,
                'updated': blob.updated.strftime('%Y-%m-%d %H:%M:%S') if blob.updated else 'N/A',
                'url': f"https://storage.googleapis.com/folder-47165.firebasestorage.app/{blob.name}",
                'blob_name': blob.name
            })
    
    return restaurants

def upload_photo(restaurant_name, image_path, bucket):
    """上傳照片"""
    if not os.path.exists(image_path):
        print(f"❌ 找不到圖片檔案：{image_path}")
        return False
    
    try:
        filename = os.path.basename(image_path)
        storage_path = f"restaurant_photos/{restaurant_name}/{filename}"
        
        blob = bucket.blob(storage_path)
        blob.upload_from_filename(image_path)
        blob.make_public()
        
        print(f"✅ 照片上傳成功：{filename}")
        print(f"📷 URL：{blob.public_url}")
        return True
    except Exception as e:
        print(f"❌ 上傳失敗：{e}")
        return False

def delete_photo(restaurant_name, filename, bucket):
    """刪除照片"""
    try:
        storage_path = f"restaurant_photos/{restaurant_name}/{filename}"
        blob = bucket.blob(storage_path)
        blob.delete()
        print(f"✅ 照片刪除成功：{filename}")
        return True
    except Exception as e:
        print(f"❌ 刪除失敗：{e}")
        return False

def format_size(size_bytes):
    """格式化檔案大小"""
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024**2:
        return f"{size_bytes/1024:.1f} KB"
    elif size_bytes < 1024**3:
        return f"{size_bytes/(1024**2):.1f} MB"
    else:
        return f"{size_bytes/(1024**3):.1f} GB"

def preview_photo(restaurant_name, filename, bucket):
    """預覽照片"""
    try:
        storage_path = f"restaurant_photos/{restaurant_name}/{filename}"
        blob = bucket.blob(storage_path)
        
        if not blob.exists():
            print(f"❌ 照片不存在：{filename}")
            return False
        
        # 獲取照片 URL
        blob.make_public()
        photo_url = blob.public_url
        
        print(f"📷 預覽照片：{filename}")
        print(f"🔗 URL：{photo_url}")
        
        # 重新載入 blob 資訊
        blob.reload()
        if blob.size:
            print(f"💾 大小：{format_size(blob.size)}")
        else:
            print(f"💾 大小：未知")
        
        # 檢查是否有本地照片可以比較
        local_photo_path = f"downloaded_photos/{restaurant_name}/{filename}"
        if os.path.exists(local_photo_path):
            local_size = os.path.getsize(local_photo_path)
            print(f"📁 本地照片：{local_photo_path} | 💾 {format_size(local_size)}")
            print(f"🔄 比較本地：python3 find_restaurant_photo.py compare \"{restaurant_name}\" \"{filename}\"")
        
        # 在 macOS 中使用瀏覽器打開照片
        import subprocess
        try:
            subprocess.run(['open', photo_url], check=True)
            print("✅ 照片已在瀏覽器中打開")
        except subprocess.CalledProcessError:
            print("⚠️ 無法自動打開瀏覽器，請手動複製 URL 查看")
        
        return True
    except Exception as e:
        print(f"❌ 預覽失敗：{e}")
        return False

def compare_photos(restaurant_name, filename, bucket):
    """比較 Firebase 和本地照片"""
    print(f"🔍 比較照片：{restaurant_name} - {filename}")
    print("=" * 60)
    
    # Firebase 照片
    try:
        storage_path = f"restaurant_photos/{restaurant_name}/{filename}"
        blob = bucket.blob(storage_path)
        
        if blob.exists():
            blob.make_public()
            firebase_url = blob.public_url
            blob.reload()
            print(f"☁️  Firebase 照片：")
            if blob.size:
                print(f"   📷 大小：{format_size(blob.size)}")
            else:
                print(f"   📷 大小：未知")
            print(f"   🕒 更新：{blob.updated.strftime('%Y-%m-%d %H:%M:%S') if blob.updated else 'N/A'}")
            print(f"   🔗 URL：{firebase_url}")
        else:
            print("❌ Firebase 中沒有此照片")
            firebase_url = None
    except Exception as e:
        print(f"❌ 獲取 Firebase 照片失敗：{e}")
        firebase_url = None
    
    # 本地照片
    local_photo_path = f"downloaded_photos/{restaurant_name}/{filename}"
    if os.path.exists(local_photo_path):
        local_size = os.path.getsize(local_photo_path)
        from datetime import datetime
        local_modified = datetime.fromtimestamp(os.path.getmtime(local_photo_path))
        
        print(f"\n📁 本地照片：")
        print(f"   📷 大小：{format_size(local_size)}")
        print(f"   🕒 修改：{local_modified.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   📂 路徑：{local_photo_path}")
        
        # 打開本地照片
        import subprocess
        try:
            subprocess.run(['open', local_photo_path], check=True)
            print("   ✅ 本地照片已打開")
        except subprocess.CalledProcessError:
            print("   ⚠️ 無法打開本地照片")
    else:
        print(f"\n❌ 本地沒有此照片：{local_photo_path}")
    
    # 如果 Firebase 照片存在，也在瀏覽器中打開
    if firebase_url:
        import subprocess
        try:
            subprocess.run(['open', firebase_url], check=True)
            print("   ✅ Firebase 照片已在瀏覽器中打開")
        except subprocess.CalledProcessError:
            pass

def main():
    # 初始化 Firebase
    bucket = init_firebase()
    if not bucket:
        return
    
    if len(sys.argv) < 2:
        print("使用方法：")
        print("  python3 find_restaurant_photo.py search 關鍵字")
        print("  python3 find_restaurant_photo.py list")
        print("  python3 find_restaurant_photo.py preview 餐廳名稱 檔案名稱")
        print("  python3 find_restaurant_photo.py compare 餐廳名稱 檔案名稱")
        print("  python3 find_restaurant_photo.py upload 餐廳名稱 圖片路徑")
        print("  python3 find_restaurant_photo.py delete 餐廳名稱 檔案名稱")
        print("")
        print("範例：")
        print("  python3 find_restaurant_photo.py search 城記")
        print("  python3 find_restaurant_photo.py search 包子")
        print("  python3 find_restaurant_photo.py preview '度小月擔仔麵' '度小月擔仔麵.jpg'")
        print("  python3 find_restaurant_photo.py list")
        return
    
    command = sys.argv[1]
    
    if command == "search":
        if len(sys.argv) < 3:
            print("請提供搜尋關鍵字")
            return
        
        query = sys.argv[2]
        matches = search_restaurants(query, bucket)
        
        if not matches:
            print(f"❌ 沒有找到包含 '{query}' 的餐廳")
            return
        
        print(f"🎯 找到 {len(matches)} 個匹配結果：")
        print("=" * 80)
        
        for i, match in enumerate(matches, 1):
            print(f"{i:2d}. {match['name']}")
            print(f"     📷 {match['filename']} | 💾 {format_size(match['size'])} | 🕒 {match['updated']}")
            print(f"     🔗 {match['url']}")
            print(f"     👁️  預覽：python3 find_restaurant_photo.py preview \"{match['name']}\" \"{match['filename']}\"")
            print()
    
    elif command == "list":
        restaurants = list_all_restaurants(bucket)
        
        print(f"📋 總共有 {len(restaurants)} 間餐廳有照片：")
        print("=" * 80)
        
        for i, (name, photos) in enumerate(restaurants.items(), 1):
            total_size = sum(photo['size'] for photo in photos)
            print(f"{i:3d}. {name}")
            print(f"      📷 {len(photos)} 張照片 | 💾 {format_size(total_size)}")
    
    elif command == "preview":
        if len(sys.argv) < 4:
            print("請提供餐廳名稱和檔案名稱")
            return
        
        restaurant_name = sys.argv[2]
        filename = sys.argv[3]
        
        preview_photo(restaurant_name, filename, bucket)
    
    elif command == "compare":
        if len(sys.argv) < 4:
            print("請提供餐廳名稱和檔案名稱")
            return
        
        restaurant_name = sys.argv[2]
        filename = sys.argv[3]
        
        compare_photos(restaurant_name, filename, bucket)
    
    elif command == "upload":
        if len(sys.argv) < 4:
            print("請提供餐廳名稱和圖片路徑")
            return
        
        restaurant_name = sys.argv[2]
        image_path = sys.argv[3]
        
        if upload_photo(restaurant_name, image_path, bucket):
            print("\n🔄 建議執行更新 Firebase 服務：")
            print("python3 update_firebase_service.py")
    
    elif command == "delete":
        if len(sys.argv) < 4:
            print("請提供餐廳名稱和檔案名稱")
            return
        
        restaurant_name = sys.argv[2]
        filename = sys.argv[3]
        
        if delete_photo(restaurant_name, filename, bucket):
            print("\n🔄 建議執行更新 Firebase 服務：")
            print("python3 update_firebase_service.py")
    
    else:
        print(f"❌ 未知指令：{command}")

if __name__ == "__main__":
    main() 