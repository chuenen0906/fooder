#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試 Firebase Storage 連接和權限
"""

import firebase_admin
from firebase_admin import credentials, storage

def test_firebase_connection():
    """測試 Firebase Storage 連接"""
    
    try:
        # 初始化 Firebase
        cred = credentials.Certificate('folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'folder-47165.firebasestorage.app'
        })
        bucket = storage.bucket()
        print("✅ Firebase 初始化成功")
        print(f"📦 Bucket 名稱: {bucket.name}")
        
        # 測試列出根目錄
        print("\n📁 根目錄內容:")
        try:
            blobs = list(bucket.list_blobs(max_results=10))
            if blobs:
                for blob in blobs:
                    print(f"  📄 {blob.name} ({blob.size} bytes)")
            else:
                print("  (空的)")
        except Exception as e:
            print(f"❌ 列出檔案失敗: {e}")
        
        # 測試列出 restaurant_photos 目錄
        print("\n📁 restaurant_photos/ 目錄內容:")
        try:
            blobs = list(bucket.list_blobs(prefix='restaurant_photos/', max_results=10))
            if blobs:
                for blob in blobs:
                    print(f"  📄 {blob.name} ({blob.size} bytes)")
            else:
                print("  (空的)")
        except Exception as e:
            print(f"❌ 列出 restaurant_photos 失敗: {e}")
        
        # 測試權限 - 嘗試上傳一個測試檔案
        print("\n🧪 測試上傳權限:")
        try:
            test_blob = bucket.blob('test/connection_test.txt')
            test_content = "測試檔案 - 可以刪除"
            test_blob.upload_from_string(test_content)
            print("✅ 上傳權限正常")
            
            # 立即刪除測試檔案
            test_blob.delete()
            print("✅ 刪除權限正常")
        except Exception as e:
            print(f"❌ 權限測試失敗: {e}")
        
    except Exception as e:
        print(f"❌ Firebase 連接失敗: {e}")

if __name__ == "__main__":
    test_firebase_connection() 