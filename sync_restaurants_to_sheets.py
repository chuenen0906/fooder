#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
將台南餐廳資料同步到 Google Sheets
"""

import json
import datetime
import os

# 檢查是否已安裝必要套件
try:
    import gspread
    from google.oauth2.service_account import Credentials
    GSPREAD_AVAILABLE = True
except ImportError:
    GSPREAD_AVAILABLE = False
    print("❌ 請先安裝必要套件：python3 -m pip install gspread google-auth")
    exit(1)

class RestaurantSyncManager:
    def __init__(self, json_file="tainan_markets.json"):
        self.json_file = json_file
        self.sheet = None
        
    def setup_google_sheets(self, credentials_file="credentials.json", 
                          sheet_name="台南餐廳資料庫"):
        """設置 Google Sheets 連接"""
        try:
            # 設置認證範圍
            scopes = [
                'https://www.googleapis.com/auth/spreadsheets',
                'https://www.googleapis.com/auth/drive'
            ]
            
            # 載入認證
            creds = Credentials.from_service_account_file(credentials_file, scopes=scopes)
            client = gspread.authorize(creds)
            
            # 打開或創建工作表
            try:
                spreadsheet = client.open(sheet_name)
                self.sheet = spreadsheet.sheet1
                print(f"✅ 已連接到現有的 Google Sheets：{sheet_name}")
            except gspread.SpreadsheetNotFound:
                # 創建新的工作表
                spreadsheet = client.create(sheet_name)
                self.sheet = spreadsheet.sheet1
                print(f"✅ 已創建新的 Google Sheets：{sheet_name}")
                print(f"🔗 工作表連結：{spreadsheet.url}")
            
            # 設置標題行
            headers = ["編號", "店家名稱", "區域", "特色料理", "描述", "同步時間", "狀態"]
            
            # 檢查是否已有標題行
            try:
                existing_headers = self.sheet.row_values(1)
                if not existing_headers or existing_headers != headers:
                    self.sheet.clear()
                    self.sheet.append_row(headers)
                    print("📝 已設置標題行")
            except:
                self.sheet.append_row(headers)
                print("📝 已設置標題行")
            
            return True
            
        except FileNotFoundError:
            print(f"❌ 找不到認證檔案：{credentials_file}")
            print("\n📋 請按照以下步驟設置 Google Cloud Console 認證：")
            print("1. 前往 https://console.cloud.google.com/")
            print("2. 建立新專案或選擇現有專案")
            print("3. 啟用 Google Sheets API 和 Google Drive API")
            print("4. 建立服務帳戶憑證")
            print("5. 下載 JSON 認證檔案並重新命名為 credentials.json")
            print("6. 將檔案放在此專案根目錄")
            return False
        except Exception as e:
            print(f"❌ Google Sheets 連接失敗：{e}")
            return False
    
    def load_restaurant_data(self):
        """載入餐廳 JSON 資料"""
        try:
            with open(self.json_file, 'r', encoding='utf-8') as file:
                data = json.load(file)
            print(f"✅ 已載入 {len(data)} 家餐廳資料")
            return data
        except FileNotFoundError:
            print(f"❌ 找不到檔案：{self.json_file}")
            return []
        except json.JSONDecodeError:
            print(f"❌ JSON 格式錯誤：{self.json_file}")
            return []
    
    def sync_to_sheets(self, batch_size=100):
        """同步餐廳資料到 Google Sheets"""
        if not self.sheet:
            print("❌ 請先設置 Google Sheets 連接")
            return False
        
        restaurants = self.load_restaurant_data()
        if not restaurants:
            return False
        
        current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 清除現有資料（保留標題行）
        try:
            self.sheet.delete_rows(2, self.sheet.row_count)
            print("🧹 已清除舊資料")
        except:
            pass
        
        # 準備批次資料
        batch_data = []
        for i, restaurant in enumerate(restaurants, 1):
            row = [
                i,  # 編號
                restaurant.get("name", ""),
                restaurant.get("area", ""),
                restaurant.get("specialty", ""),
                restaurant.get("description", ""),
                current_time,
                "已同步"
            ]
            batch_data.append(row)
        
        # 分批上傳資料
        total_uploaded = 0
        for i in range(0, len(batch_data), batch_size):
            batch = batch_data[i:i + batch_size]
            try:
                self.sheet.append_rows(batch)
                total_uploaded += len(batch)
                print(f"📤 已上傳 {total_uploaded}/{len(restaurants)} 筆資料")
            except Exception as e:
                print(f"❌ 批次上傳失敗：{e}")
                return False
        
        print(f"🎉 同步完成！共 {total_uploaded} 家餐廳")
        return True
    
    def get_sheet_url(self):
        """取得工作表網址"""
        if self.sheet:
            return self.sheet.spreadsheet.url
        return None

def main():
    """主程式"""
    print("🍽️ 台南餐廳資料同步工具")
    print("=" * 50)
    
    sync_manager = RestaurantSyncManager()
    
    print("\n選擇功能：")
    print("1. 設置 Google Sheets 連接並同步資料")
    print("2. 僅同步資料（需已設置連接）")
    print("3. 檢視本地 JSON 資料")
    
    choice = input("\n請選擇 (1-3)：").strip()
    
    if choice == "1":
        creds_file = input("認證檔案路徑 (預設：credentials.json)：").strip()
        creds_file = creds_file or "credentials.json"
        
        sheet_name = input("工作表名稱 (預設：台南餐廳資料庫)：").strip()
        sheet_name = sheet_name or "台南餐廳資料庫"
        
        if sync_manager.setup_google_sheets(creds_file, sheet_name):
            print("\n開始同步資料...")
            if sync_manager.sync_to_sheets():
                url = sync_manager.get_sheet_url()
                if url:
                    print(f"\n🔗 Google Sheets 連結：{url}")
    
    elif choice == "2":
        if sync_manager.setup_google_sheets():
            sync_manager.sync_to_sheets()
        else:
            print("❌ 請先設置 Google Sheets 連接")
    
    elif choice == "3":
        restaurants = sync_manager.load_restaurant_data()
        if restaurants:
            print(f"\n📊 本地資料統計：")
            print(f"總餐廳數：{len(restaurants)}")
            
            # 統計區域分布
            areas = {}
            for restaurant in restaurants:
                area = restaurant.get("area", "未知")
                areas[area] = areas.get(area, 0) + 1
            
            print("\n📍 區域分布：")
            for area, count in sorted(areas.items(), key=lambda x: x[1], reverse=True):
                print(f"  {area}：{count} 家")
            
            print(f"\n🔍 最近 5 家餐廳：")
            for restaurant in restaurants[-5:]:
                print(f"  • {restaurant.get('name')} ({restaurant.get('area')}) - {restaurant.get('specialty')}")
    
    else:
        print("❌ 無效選擇")

if __name__ == "__main__":
    main() 