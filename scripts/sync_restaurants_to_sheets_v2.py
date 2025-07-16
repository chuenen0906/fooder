#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
將台南餐廳資料同步到 Google Sheets (改良版)
可連接現有工作表，避免儲存空間問題
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

class RestaurantSyncManagerV2:
    def __init__(self, json_file="tainan_markets.json"):
        self.json_file = json_file
        self.sheet = None
        self.client = None
        
    def setup_google_sheets_client(self, credentials_file="credentials.json"):
        """設置 Google Sheets 客戶端"""
        try:
            # 設置認證範圍
            scopes = [
                'https://www.googleapis.com/auth/spreadsheets',
                'https://www.googleapis.com/auth/drive'
            ]
            
            # 載入認證
            creds = Credentials.from_service_account_file(credentials_file, scopes=scopes)
            self.client = gspread.authorize(creds)
            print("✅ Google Sheets 客戶端已設置")
            return True
            
        except FileNotFoundError:
            print(f"❌ 找不到認證檔案：{credentials_file}")
            return False
        except Exception as e:
            print(f"❌ 認證失敗：{e}")
            return False
    
    def connect_to_existing_sheet(self, sheet_url):
        """連接到現有的 Google Sheets"""
        try:
            if not self.client:
                print("❌ 請先設置 Google Sheets 客戶端")
                return False
            
            # 從 URL 中提取工作表
            self.sheet = self.client.open_by_url(sheet_url).sheet1
            print(f"✅ 已連接到現有工作表")
            return True
            
        except Exception as e:
            print(f"❌ 連接失敗：{e}")
            return False
    
    def create_new_sheet(self, sheet_name):
        """創建新工作表（如果有空間）"""
        try:
            if not self.client:
                print("❌ 請先設置 Google Sheets 客戶端")
                return False
            
            spreadsheet = self.client.create(sheet_name)
            self.sheet = spreadsheet.sheet1
            print(f"✅ 已創建新工作表：{sheet_name}")
            print(f"🔗 工作表連結：{spreadsheet.url}")
            return True
            
        except Exception as e:
            print(f"❌ 創建失敗：{e}")
            print("💡 建議：嘗試連接到現有工作表或清理 Google Drive 空間")
            return False
    
    def setup_headers(self):
        """設置工作表標題行"""
        if not self.sheet:
            return False
        
        headers = ["編號", "店家名稱", "區域", "特色料理", "描述", "照片數量", "同步時間", "狀態"]
        
        try:
            # 檢查是否已有資料
            existing_data = self.sheet.get_all_values()
            if not existing_data or existing_data[0] != headers:
                # 清除並設置標題
                self.sheet.clear()
                self.sheet.append_row(headers)
                print("📝 已設置標題行")
            else:
                print("📝 標題行已存在")
            return True
        except Exception as e:
            print(f"❌ 設置標題失敗：{e}")
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
    
    def sync_to_sheets(self, batch_size=50):
        """同步餐廳資料到 Google Sheets"""
        if not self.sheet:
            print("❌ 請先連接到工作表")
            return False
        
        restaurants = self.load_restaurant_data()
        if not restaurants:
            return False
        
        current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 清除現有資料（保留標題行）
        try:
            all_values = self.sheet.get_all_values()
            if len(all_values) > 1:
                self.sheet.delete_rows(2, len(all_values))
                print("🧹 已清除舊資料")
        except Exception as e:
            print(f"⚠️ 清理警告：{e}")
        
        # 準備批次資料
        batch_data = []
        for i, restaurant in enumerate(restaurants, 1):
            photo_count = 0
            if isinstance(restaurant.get("photos"), list):
                photo_count = len(restaurant["photos"])
            row = [
                i,  # 編號
                restaurant.get("name", ""),
                restaurant.get("area", ""),
                restaurant.get("specialty", ""),
                restaurant.get("description", ""),
                photo_count,
                current_time,
                "已同步"
            ]
            batch_data.append(row)
        
        # 分批上傳資料（較小批次避免超時）
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
    import argparse
    
    parser = argparse.ArgumentParser(description="台南餐廳資料同步到 Google Sheets")
    parser.add_argument("--credentials", "-c", default="credentials.json", 
                       help="認證檔案路徑 (預設: credentials.json)")
    parser.add_argument("--url", "-u", help="現有 Google Sheets URL")
    parser.add_argument("--name", "-n", default="台南餐廳資料庫", 
                       help="新工作表名稱 (預設: 台南餐廳資料庫)")
    parser.add_argument("--json-file", "-j", default="tainan_markets.json",
                       help="餐廳 JSON 檔案路徑 (預設: tainan_markets.json)")
    parser.add_argument("--batch-size", "-b", type=int, default=50,
                       help="批次上傳大小 (預設: 50)")
    parser.add_argument("--interactive", "-i", action="store_true",
                       help="使用互動模式")
    parser.add_argument("--view-only", "-v", action="store_true",
                       help="僅檢視本地資料，不同步")
    
    args = parser.parse_args()
    
    print("🍽️ 台南餐廳資料同步工具 (改良版)")
    print("=" * 50)
    
    sync_manager = RestaurantSyncManagerV2(args.json_file)
    
    # 設置客戶端
    if not sync_manager.setup_google_sheets_client(args.credentials):
        return
    
    # 互動模式
    if args.interactive:
        print("\n選擇工作表設置方式：")
        print("1. 連接到現有的 Google Sheets（推薦）")
        print("2. 創建新的 Google Sheets")
        print("3. 檢視本地 JSON 資料")
        
        choice = input("\n請選擇 (1-3)：").strip()
        
        if choice == "1":
            print("\n💡 請先手動在 Google Sheets 創建一個空白工作表")
            print("1. 前往 https://sheets.google.com")
            print("2. 創建新工作表")
            print("3. 複製工作表 URL")
            print("4. 將工作表分享給服務帳戶（在 credentials.json 中的 client_email）")
            
            sheet_url = input("\n請輸入 Google Sheets URL：").strip()
            if sheet_url:
                if sync_manager.connect_to_existing_sheet(sheet_url):
                    sync_manager.setup_headers()
                    print("\n開始同步資料...")
                    if sync_manager.sync_to_sheets(args.batch_size):
                        print(f"\n🔗 Google Sheets 連結：{sheet_url}")
        
        elif choice == "2":
            sheet_name = input("工作表名稱 (預設：台南餐廳資料庫)：").strip()
            sheet_name = sheet_name or "台南餐廳資料庫"
            
            if sync_manager.create_new_sheet(sheet_name):
                sync_manager.setup_headers()
                print("\n開始同步資料...")
                if sync_manager.sync_to_sheets(args.batch_size):
                    url = sync_manager.get_sheet_url()
                    if url:
                        print(f"\n🔗 Google Sheets 連結：{url}")
        
        elif choice == "3":
            show_local_data(sync_manager)
        
        else:
            print("❌ 無效選擇")
    
    # 命令列模式
    else:
        if args.view_only:
            show_local_data(sync_manager)
            return
        
        if args.url:
            # 連接到現有工作表
            if sync_manager.connect_to_existing_sheet(args.url):
                sync_manager.setup_headers()
                print("\n開始同步資料...")
                if sync_manager.sync_to_sheets(args.batch_size):
                    print(f"\n🔗 Google Sheets 連結：{args.url}")
        else:
            # 創建新工作表
            if sync_manager.create_new_sheet(args.name):
                sync_manager.setup_headers()
                print("\n開始同步資料...")
                if sync_manager.sync_to_sheets(args.batch_size):
                    url = sync_manager.get_sheet_url()
                    if url:
                        print(f"\n🔗 Google Sheets 連結：{url}")

def show_local_data(sync_manager):
    """顯示本地資料統計"""
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

if __name__ == "__main__":
    main() 