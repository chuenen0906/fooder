#!/usr/bin/env python3
"""
店家資料刪除腳本
刪除指定店家的本地相關資料，包括：
1. 本地 JSON 資料庫記錄
2. Firebase 服務映射
3. 本地 assets 照片檔案
4. 上傳記錄檔案
5. 提供 Firebase Storage 手動刪除指引
"""

import json
import os
import shutil
import argparse
from pathlib import Path
from datetime import datetime
import re

class RestaurantDeleter:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.data_file = self.project_root / "data" / "tainan_markets.json"
        self.uploaded_file = self.project_root / "data" / "uploaded_restaurants.json"
        self.assets_dir = self.project_root / "assets" / "restaurants_collection"
        self.firebase_service_file = self.project_root / "lib" / "services" / "firebase_restaurant_service.dart"
        
    def backup_data(self, restaurant_name):
        """備份原始資料"""
        backup_dir = self.project_root / "data" / "backups"
        backup_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 備份主要資料檔案
        backup_file = backup_dir / f"backup_{restaurant_name}_{timestamp}.json"
        with open(self.data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ 已備份主要資料到: {backup_file}")
        
        # 備份上傳記錄檔案
        if self.uploaded_file.exists():
            backup_uploaded_file = backup_dir / f"backup_uploaded_{restaurant_name}_{timestamp}.json"
            with open(self.uploaded_file, 'r', encoding='utf-8') as f:
                uploaded_data = json.load(f)
            with open(backup_uploaded_file, 'w', encoding='utf-8') as f:
                json.dump(uploaded_data, f, ensure_ascii=False, indent=2)
            print(f"✅ 已備份上傳記錄到: {backup_uploaded_file}")
        
        return backup_file
    
    def delete_from_json(self, restaurant_name):
        """從 JSON 資料庫中刪除店家記錄"""
        print(f"🗑️  正在從 JSON 資料庫中刪除 '{restaurant_name}'...")
        
        with open(self.data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        original_count = len(data)
        data = [restaurant for restaurant in data if restaurant['name'] != restaurant_name]
        new_count = len(data)
        
        if new_count == original_count:
            print(f"⚠️  警告：在 JSON 資料庫中找不到 '{restaurant_name}'")
            return False
        
        with open(self.data_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 已從 JSON 資料庫中刪除 '{restaurant_name}' (刪除了 {original_count - new_count} 筆記錄)")
        return True
    
    def delete_from_uploaded_json(self, restaurant_name):
        """從上傳記錄 JSON 中刪除店家記錄"""
        if not self.uploaded_file.exists():
            print(f"ℹ️  上傳記錄檔案不存在，跳過此步驟")
            return True
        
        print(f"🗑️  正在從上傳記錄中刪除 '{restaurant_name}'...")
        
        with open(self.uploaded_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        original_count = len(data)
        data = [restaurant for restaurant in data if restaurant['name'] != restaurant_name]
        new_count = len(data)
        
        if new_count == original_count:
            print(f"⚠️  警告：在上傳記錄中找不到 '{restaurant_name}'")
            return False
        
        with open(self.uploaded_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 已從上傳記錄中刪除 '{restaurant_name}' (刪除了 {original_count - new_count} 筆記錄)")
        return True
    
    def get_restaurant_photo_urls(self, restaurant_name):
        """從 Firebase 服務檔案中獲取店家的照片 URL"""
        try:
            with open(self.firebase_service_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 尋找店家名稱對應的照片 URL 列表
            pattern = rf'"{re.escape(restaurant_name)}":\s*\[(.*?)\]'
            match = re.search(pattern, content, re.DOTALL)
            
            if match:
                urls_text = match.group(1)
                # 提取 URL
                url_pattern = r'"https://[^"]*"'
                urls = re.findall(url_pattern, urls_text)
                return [url.strip('"') for url in urls]
            
            return []
            
        except Exception as e:
            print(f"❌ 讀取 Firebase 服務檔案失敗: {str(e)}")
            return []
    
    def get_uploaded_photo_urls(self, restaurant_name):
        """從上傳記錄中獲取店家的照片 URL"""
        if not self.uploaded_file.exists():
            return []
        
        try:
            with open(self.uploaded_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for restaurant in data:
                if restaurant['name'] == restaurant_name and 'photos' in restaurant:
                    return restaurant['photos']
            
            return []
            
        except Exception as e:
            print(f"❌ 讀取上傳記錄失敗: {str(e)}")
            return []
    
    def update_firebase_mapping(self, restaurant_name):
        """更新 Firebase 服務檔案中的照片映射"""
        print(f"🗑️  正在更新 Firebase 映射，移除 '{restaurant_name}'...")
        
        try:
            with open(self.firebase_service_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 移除店家名稱對應的整個映射項目
            pattern = rf'"{re.escape(restaurant_name)}":\s*\[[^\]]*\],?\s*'
            new_content = re.sub(pattern, '', content)
            
            # 清理多餘的逗號
            new_content = re.sub(r',\s*}', '}', new_content)
            new_content = re.sub(r',\s*]', ']', new_content)
            
            with open(self.firebase_service_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"✅ 已更新 Firebase 服務檔案")
            return True
            
        except Exception as e:
            print(f"❌ 更新 Firebase 映射失敗: {str(e)}")
            return False
    
    def delete_local_assets(self, restaurant_name):
        """刪除本地 assets 中的照片檔案"""
        print(f"🗑️  正在刪除本地 assets 中的 '{restaurant_name}' 照片...")
        
        # 尋找店家的照片目錄
        restaurant_dir = None
        for item in self.assets_dir.iterdir():
            if item.is_dir() and restaurant_name in item.name:
                restaurant_dir = item
                break
        
        if not restaurant_dir:
            print(f"⚠️  在本地 assets 中找不到 '{restaurant_name}' 的照片目錄")
            return False
        
        try:
            # 刪除整個目錄
            shutil.rmtree(restaurant_dir)
            print(f"✅ 已刪除本地照片目錄: {restaurant_dir}")
            return True
            
        except Exception as e:
            print(f"❌ 刪除本地照片失敗: {str(e)}")
            return False
    
    def get_firebase_deletion_guide(self, restaurant_name):
        """提供 Firebase Storage 手動刪除指引"""
        # 從多個來源獲取照片 URL
        service_urls = self.get_restaurant_photo_urls(restaurant_name)
        uploaded_urls = self.get_uploaded_photo_urls(restaurant_name)
        
        # 合併並去重
        all_urls = list(set(service_urls + uploaded_urls))
        
        if not all_urls:
            print(f"ℹ️  '{restaurant_name}' 沒有找到任何照片記錄")
            return
        
        print(f"\n📋 Firebase Storage 手動刪除指引:")
        print(f"店家: {restaurant_name}")
        print(f"需要刪除的照片數量: {len(all_urls)} 張")
        print("\n照片 URL 列表:")
        for i, url in enumerate(all_urls, 1):
            print(f"  {i}. {url}")
        
        print(f"\n🔧 手動刪除步驟:")
        print(f"1. 前往 Firebase Console: https://console.firebase.google.com/")
        print(f"2. 選擇專案: folder-47165")
        print(f"3. 點擊 Storage")
        print(f"4. 找到 restaurant_photos/{restaurant_name}/ 目錄")
        print(f"5. 刪除該目錄下的所有照片檔案")
        print(f"6. 或者使用 Firebase CLI 命令:")
        print(f"   firebase storage:delete restaurant_photos/{restaurant_name}/")
    
    def delete_restaurant(self, restaurant_name, backup=True):
        """完整刪除店家資料"""
        print(f"🚀 開始刪除店家: {restaurant_name}")
        print("=" * 50)
        
        # 備份資料
        if backup:
            self.backup_data(restaurant_name)
        
        # 執行刪除操作
        results = {
            'json': self.delete_from_json(restaurant_name),
            'uploaded_json': self.delete_from_uploaded_json(restaurant_name),
            'firebase_mapping': self.update_firebase_mapping(restaurant_name),
            'local_assets': self.delete_local_assets(restaurant_name)
        }
        
        # 顯示結果摘要
        print("\n" + "=" * 50)
        print("📊 刪除結果摘要:")
        print(f"  JSON 資料庫: {'✅' if results['json'] else '❌'}")
        print(f"  上傳記錄: {'✅' if results['uploaded_json'] else '❌'}")
        print(f"  Firebase 映射: {'✅' if results['firebase_mapping'] else '❌'}")
        print(f"  本地 Assets: {'✅' if results['local_assets'] else '❌'}")
        
        success_count = sum(results.values())
        total_count = len(results)
        
        print(f"\n🎯 完成度: {success_count}/{total_count} ({success_count/total_count*100:.1f}%)")
        
        if success_count == total_count:
            print("🎉 本地店家資料刪除完成！")
        else:
            print("⚠️  部分操作失敗，請檢查上述錯誤訊息")
        
        # 提供 Firebase Storage 刪除指引
        self.get_firebase_deletion_guide(restaurant_name)
        
        return results

def main():
    parser = argparse.ArgumentParser(description='刪除指定店家的所有資料')
    parser.add_argument('restaurant_name', help='要刪除的店家名稱')
    parser.add_argument('--no-backup', action='store_true', help='不進行備份')
    
    args = parser.parse_args()
    
    # 確認刪除
    print(f"⚠️  警告：即將刪除店家 '{args.restaurant_name}' 的所有本地資料！")
    print("這包括：")
    print("  - JSON 資料庫中的記錄")
    print("  - 上傳記錄檔案")
    print("  - Firebase 服務映射")
    print("  - 本地 assets 中的照片檔案")
    print("\n注意：Firebase Storage 中的照片需要手動刪除")
    
    confirm = input("\n請輸入店家名稱以確認刪除（輸入 'cancel' 取消）: ")
    
    if confirm != args.restaurant_name:
        if confirm.lower() == 'cancel':
            print("❌ 操作已取消")
        else:
            print("❌ 店家名稱不匹配，操作已取消")
        return
    
    # 執行刪除
    deleter = RestaurantDeleter()
    deleter.delete_restaurant(args.restaurant_name, backup=not args.no_backup)

if __name__ == "__main__":
    main() 