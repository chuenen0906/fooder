#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google Sheets 餐廳記錄器
需要先設置 Google Sheets API 認證
"""

import json
import datetime
import csv
import os

# 注意：要使用 Google Sheets API，需要安裝 gspread
# pip install gspread google-auth

# 檢查是否已安裝必要套件
try:
    import gspread
    GSPREAD_AVAILABLE = True
except ImportError:
    GSPREAD_AVAILABLE = False

class GoogleSheetsRestaurantLogger:
    def __init__(self, sheet_url=None, local_backup=True):
        self.local_backup = local_backup
        self.backup_file = "restaurant_input_log.csv"
        self.sheet_url = sheet_url
        
        if local_backup:
            self.init_local_backup()
        
        # Google Sheets 連接（需要認證設置）
        self.sheet = None
        print("📝 Google Sheets 連接器已初始化")
        print("⚠️  要連接 Google Sheets，請按照以下步驟設置：")
        print("1. 前往 Google Cloud Console")
        print("2. 啟用 Google Sheets API")
        print("3. 創建服務帳戶並下載認證 JSON")
        print("4. 安裝：pip install gspread google-auth")
    
    def init_local_backup(self):
        """初始化本地備份檔案"""
        if not os.path.exists(self.backup_file):
            headers = [
                "輸入日期", "店家名稱", "區域", "特色料理", 
                "描述", "資料來源", "狀態", "備註"
            ]
            with open(self.backup_file, 'w', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"✅ 已創建本地備份檔案：{self.backup_file}")
    
    def setup_google_sheets(self, credentials_file="credentials.json", 
                          sheet_name="台南餐廳輸入記錄"):
        """設置 Google Sheets 連接"""
        if not GSPREAD_AVAILABLE:
            print("❌ 缺少必要套件，請執行：pip install gspread google-auth")
            return False
            
        try:
            # 動態導入以避免 linter 錯誤
            gspread = __import__('gspread')
            google_auth = __import__('google.oauth2.service_account', fromlist=['Credentials'])
            Credentials = google_auth.Credentials
            
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
                self.sheet = client.open(sheet_name).sheet1
                print(f"✅ 已連接到現有的 Google Sheets：{sheet_name}")
            except Exception:  # SpreadsheetNotFound
                # 創建新的工作表
                spreadsheet = client.create(sheet_name)
                self.sheet = spreadsheet.sheet1
                
                # 設置標題行
                headers = [
                    "輸入日期", "店家名稱", "區域", "特色料理", 
                    "描述", "資料來源", "狀態", "備註"
                ]
                self.sheet.append_row(headers)
                print(f"✅ 已創建新的 Google Sheets：{sheet_name}")
                print(f"🔗 工作表連結：{spreadsheet.url}")
            
            return True
            
        except FileNotFoundError:
            print(f"❌ 找不到認證檔案：{credentials_file}")
            print("請從 Google Cloud Console 下載服務帳戶 JSON 檔案")
            return False
        except Exception as e:
            print(f"❌ Google Sheets 連接失敗：{e}")
            return False
    
    def add_restaurant_record(self, name: str, area: str = "", 
                            specialty: str = "", description: str = "",
                            source: str = "手動輸入", status: str = "待處理",
                            notes: str = ""):
        """新增餐廳記錄"""
        current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        record = [
            current_time, name, area, specialty, 
            description, source, status, notes
        ]
        
        # 儲存到本地備份
        if self.local_backup:
            with open(self.backup_file, 'a', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerow(record)
            print(f"✅ 已儲存到本地備份：{name}")
        
        # 儲存到 Google Sheets
        if self.sheet:
            try:
                self.sheet.append_row(record)
                print(f"☁️ 已同步到 Google Sheets：{name}")
            except Exception as e:
                print(f"❌ Google Sheets 同步失敗：{e}")
        
        return record
    
    def generate_google_form_template(self):
        """生成 Google 表單設置指南"""
        form_config = {
            "表單標題": "台南餐廳資料輸入表單",
            "描述": "記錄新發現的台南餐廳資訊",
            "問題設置": [
                {
                    "問題": "店家名稱",
                    "類型": "簡答",
                    "必填": True,
                    "說明": "請輸入完整的店家名稱"
                },
                {
                    "問題": "區域",
                    "類型": "下拉式選單",
                    "必填": True,
                    "選項": ["中西區", "東區", "南區", "北區", "安平區", "安南區", "永康區", "其他"]
                },
                {
                    "問題": "特色料理",
                    "類型": "簡答",
                    "必填": False,
                    "說明": "例如：牛肉湯、擔仔麵、冰品等"
                },
                {
                    "問題": "店家描述",
                    "類型": "段落",
                    "必填": False,
                    "說明": "描述店家特色、口味、環境等"
                },
                {
                    "問題": "資料來源",
                    "類型": "下拉式選單",
                    "必填": True,
                    "選項": ["實地探訪", "網路搜尋", "朋友推薦", "社群媒體", "美食部落格", "其他"]
                },
                {
                    "問題": "處理狀態",
                    "類型": "下拉式選單",
                    "必填": False,
                    "選項": ["待處理", "已確認資訊", "已加入資料庫", "已上傳照片", "完成"]
                },
                {
                    "問題": "備註",
                    "類型": "段落",
                    "必填": False,
                    "說明": "其他補充資訊"
                }
            ]
        }
        
        # 儲存配置到檔案
        with open("google_form_config.json", "w", encoding="utf-8") as f:
            json.dump(form_config, f, ensure_ascii=False, indent=2)
        
        print("📋 Google 表單設置指南已儲存到：google_form_config.json")
        print("\n🔗 請按照以下步驟創建 Google 表單：")
        print("1. 前往 https://forms.google.com")
        print("2. 點擊「建立空白表單」")
        print("3. 參考 google_form_config.json 設置問題")
        print("4. 在表單設置中連接到 Google Sheets")
        print("5. 將表單連結分享給需要的人員")
        
        return form_config

def main():
    """主要功能演示"""
    logger = GoogleSheetsRestaurantLogger()
    
    print("\n🍽️ Google Sheets 餐廳資料記錄器")
    print("=" * 50)
    
    while True:
        print(f"\n選擇功能：")
        print("1. 設置 Google Sheets 連接")
        print("2. 新增餐廳記錄")
        print("3. 生成 Google 表單設置指南")
        print("4. 查看本地備份")
        print("5. 退出")
        
        choice = input("\n請選擇 (1-5)：").strip()
        
        if choice == "1":
            creds_file = input("認證檔案路徑 (預設：credentials.json)：").strip()
            creds_file = creds_file or "credentials.json"
            
            sheet_name = input("工作表名稱 (預設：台南餐廳輸入記錄)：").strip()
            sheet_name = sheet_name or "台南餐廳輸入記錄"
            
            logger.setup_google_sheets(creds_file, sheet_name)
        
        elif choice == "2":
            name = input("店家名稱：").strip()
            if name:
                area = input("區域：").strip()
                specialty = input("特色料理：").strip()
                description = input("描述：").strip()
                source = input("資料來源 (預設：手動輸入)：").strip() or "手動輸入"
                
                logger.add_restaurant_record(
                    name=name,
                    area=area,
                    specialty=specialty,
                    description=description,
                    source=source
                )
            else:
                print("❌ 店家名稱不能為空")
        
        elif choice == "3":
            logger.generate_google_form_template()
        
        elif choice == "4":
            if os.path.exists(logger.backup_file):
                print(f"\n📁 本地備份檔案：{logger.backup_file}")
                with open(logger.backup_file, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    print(f"📊 總共 {len(lines)-1} 筆記錄")
                    if len(lines) > 1:
                        print("最近 5 筆記錄：")
                        for line in lines[-5:]:
                            print(f"  {line.strip()}")
            else:
                print("❌ 沒有找到本地備份檔案")
        
        elif choice == "5":
            print("👋 再見！")
            break
        
        else:
            print("❌ 無效選擇，請重新輸入")

if __name__ == "__main__":
    main() 