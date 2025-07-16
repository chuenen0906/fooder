#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試 Google Sheets API 連接
用於驗證 credentials.json 設置是否正確
"""

import json
import os
import sys

# 檢查是否已安裝必要套件
try:
    import gspread
    from google.oauth2.service_account import Credentials
    GSPREAD_AVAILABLE = True
except ImportError:
    GSPREAD_AVAILABLE = False
    print("❌ 請先安裝必要套件：python3 -m pip install gspread google-auth")
    sys.exit(1)

def test_credentials_file(credentials_file="credentials.json"):
    """測試認證檔案是否存在且格式正確"""
    print(f"🔍 檢查認證檔案：{credentials_file}")
    
    if not os.path.exists(credentials_file):
        print(f"❌ 找不到認證檔案：{credentials_file}")
        print("💡 請按照 GOOGLE_SHEETS_SETUP.md 的步驟下載 credentials.json")
        return False
    
    try:
        with open(credentials_file, 'r') as f:
            creds_data = json.load(f)
        
        # 檢查必要欄位
        required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email', 'client_id']
        missing_fields = [field for field in required_fields if field not in creds_data]
        
        if missing_fields:
            print(f"❌ 認證檔案格式錯誤，缺少欄位：{missing_fields}")
            return False
        
        print(f"✅ 認證檔案格式正確")
        print(f"📧 服務帳戶電子郵件：{creds_data['client_email']}")
        print(f"🏢 專案 ID：{creds_data['project_id']}")
        return True
        
    except json.JSONDecodeError:
        print(f"❌ 認證檔案 JSON 格式錯誤")
        return False
    except Exception as e:
        print(f"❌ 讀取認證檔案失敗：{e}")
        return False

def test_google_sheets_connection(credentials_file="credentials.json"):
    """測試 Google Sheets API 連接"""
    print("\n🔗 測試 Google Sheets API 連接...")
    
    try:
        # 設置認證範圍
        scopes = [
            'https://www.googleapis.com/auth/spreadsheets',
            'https://www.googleapis.com/auth/drive'
        ]
        
        # 載入認證
        creds = Credentials.from_service_account_file(credentials_file, scopes=scopes)
        client = gspread.authorize(creds)
        
        print("✅ Google Sheets API 連接成功")
        
        # 測試創建測試工作表
        test_sheet_name = f"Fooder_Test_{int(os.getpid())}"
        try:
            spreadsheet = client.create(test_sheet_name)
            print(f"✅ 成功創建測試工作表：{test_sheet_name}")
            
            # 測試寫入資料
            sheet = spreadsheet.sheet1
            test_data = [["測試時間", "狀態"], [f"{os.popen('date').read().strip()}", "連接正常"]]
            sheet.append_rows(test_data)
            print("✅ 成功寫入測試資料")
            
            # 清理測試工作表
            client.del_spreadsheet(spreadsheet.id)
            print("🧹 已清理測試工作表")
            
        except Exception as e:
            print(f"⚠️ 測試工作表操作失敗：{e}")
            print("💡 這可能是權限問題，但基本連接是正常的")
        
        return True
        
    except FileNotFoundError:
        print(f"❌ 找不到認證檔案：{credentials_file}")
        return False
    except Exception as e:
        print(f"❌ Google Sheets API 連接失敗：{e}")
        
        # 提供具體的錯誤建議
        if "403" in str(e):
            print("💡 建議：")
            print("1. 確認已在 Google Cloud Console 中啟用 Google Sheets API")
            print("2. 確認服務帳戶具有適當權限")
        elif "401" in str(e):
            print("💡 建議：")
            print("1. 確認認證檔案未過期")
            print("2. 重新下載 credentials.json 檔案")
        elif "quota" in str(e).lower():
            print("💡 建議：")
            print("1. 檢查 Google Cloud Console 的 API 配額")
            print("2. 等待配額重置或申請提高限制")
        
        return False

def test_existing_sheet_connection(credentials_file="credentials.json", sheet_url=None):
    """測試連接到現有工作表"""
    if not sheet_url:
        print("\n📋 跳過現有工作表連接測試（未提供 URL）")
        return True
    
    print(f"\n🔗 測試連接到現有工作表：{sheet_url}")
    
    try:
        # 設置認證
        scopes = [
            'https://www.googleapis.com/auth/spreadsheets',
            'https://www.googleapis.com/auth/drive'
        ]
        creds = Credentials.from_service_account_file(credentials_file, scopes=scopes)
        client = gspread.authorize(creds)
        
        # 嘗試連接工作表
        spreadsheet = client.open_by_url(sheet_url)
        sheet = spreadsheet.sheet1
        
        # 測試讀取資料
        values = sheet.get_all_values()
        print(f"✅ 成功連接到工作表：{spreadsheet.title}")
        print(f"📊 工作表包含 {len(values)} 行資料")
        
        if values:
            print(f"📝 第一行標題：{values[0]}")
        
        return True
        
    except Exception as e:
        print(f"❌ 連接現有工作表失敗：{e}")
        print("💡 建議：")
        print("1. 確認工作表 URL 正確")
        print("2. 確認已將服務帳戶電子郵件加入工作表分享清單")
        print("3. 確認服務帳戶具有編輯權限")
        return False

def main():
    """主程式"""
    print("🧪 Google Sheets API 連接測試工具")
    print("=" * 50)
    
    # 檢查認證檔案
    credentials_file = input("認證檔案路徑 (預設：credentials.json)：").strip()
    credentials_file = credentials_file or "credentials.json"
    
    if not test_credentials_file(credentials_file):
        return
    
    # 測試基本連接
    if not test_google_sheets_connection(credentials_file):
        return
    
    # 測試現有工作表連接
    sheet_url = input("\n現有工作表 URL (可選，按 Enter 跳過)：").strip()
    if sheet_url:
        test_existing_sheet_connection(credentials_file, sheet_url)
    
    print("\n🎉 測試完成！")
    print("💡 如果所有測試都通過，您可以使用以下腳本同步資料：")
    print("   python3 scripts/sync_restaurants_to_sheets_v2.py")

if __name__ == "__main__":
    main() 