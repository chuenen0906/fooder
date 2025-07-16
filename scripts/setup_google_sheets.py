#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google Sheets 互動式設置腳本
引導使用者完成 Google Sheets API 設置
"""

import os
import json
import sys
import webbrowser
import subprocess

def print_header():
    """印出標題"""
    print("🍽️  Fooder Google Sheets 設置精靈")
    print("=" * 50)
    print("這個腳本將協助您完成 Google Sheets API 設置")
    print("讓您能夠將餐廳資料同步到線上工作表")
    print()

def check_prerequisites():
    """檢查前置需求"""
    print("🔍 檢查前置需求...")
    
    # 檢查 Python 套件
    try:
        import gspread
        import google.auth
        print("✅ 必要套件已安裝")
        return True
    except ImportError:
        print("❌ 缺少必要套件")
        print("💡 正在安裝必要套件...")
        
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "gspread", "google-auth"])
            print("✅ 套件安裝完成")
            return True
        except subprocess.CalledProcessError:
            print("❌ 套件安裝失敗")
            print("💡 請手動執行：python3 -m pip install gspread google-auth")
            return False

def guide_google_cloud_setup():
    """引導 Google Cloud Console 設置"""
    print("\n🌐 Google Cloud Console 設置")
    print("-" * 30)
    
    print("步驟 1：前往 Google Cloud Console")
    print("1. 開啟瀏覽器前往：https://console.cloud.google.com/")
    print("2. 登入您的 Google 帳戶")
    print("3. 選擇或創建一個專案")
    
    open_console = input("\n是否要現在開啟 Google Cloud Console？(y/n): ").strip().lower()
    if open_console == 'y':
        webbrowser.open("https://console.cloud.google.com/")
    
    print("\n步驟 2：啟用 Google Sheets API")
    print("1. 在左側選單點擊「API 和服務」→「程式庫」")
    print("2. 搜尋「Google Sheets API」")
    print("3. 點擊「Google Sheets API」")
    print("4. 點擊「啟用」按鈕")
    
    open_api = input("\n是否要現在開啟 Google Sheets API 頁面？(y/n): ").strip().lower()
    if open_api == 'y':
        webbrowser.open("https://console.cloud.google.com/apis/library/sheets.googleapis.com")
    
    print("\n步驟 3：創建服務帳戶")
    print("1. 在左側選單點擊「API 和服務」→「憑證」")
    print("2. 點擊「建立憑證」→「服務帳戶」")
    print("3. 填寫服務帳戶資訊：")
    print("   - 服務帳戶名稱：fooder-sheets-sync")
    print("   - 描述：Fooder 專案 Google Sheets 同步服務")
    print("4. 點擊「建立並繼續」")
    print("5. 在「授予此服務帳戶存取權」中選擇「編輯者」")
    print("6. 點擊「完成」")
    
    open_credentials = input("\n是否要現在開啟憑證頁面？(y/n): ").strip().lower()
    if open_credentials == 'y':
        webbrowser.open("https://console.cloud.google.com/apis/credentials")
    
    print("\n步驟 4：下載認證檔案")
    print("1. 在服務帳戶列表中點擊剛創建的服務帳戶")
    print("2. 點擊「金鑰」標籤")
    print("3. 點擊「新增金鑰」→「建立新金鑰」")
    print("4. 選擇「JSON」格式")
    print("5. 點擊「建立」")
    print("6. 系統會自動下載 credentials.json 檔案")
    
    input("\n完成上述步驟後，按 Enter 繼續...")

def setup_credentials_file():
    """設置認證檔案"""
    print("\n📁 設置認證檔案")
    print("-" * 20)
    
    # 檢查是否已有認證檔案
    if os.path.exists("credentials.json"):
        print("✅ 發現現有的 credentials.json 檔案")
        overwrite = input("是否要重新設置？(y/n): ").strip().lower()
        if overwrite != 'y':
            return True
    
    print("請將下載的 credentials.json 檔案放到專案根目錄")
    print("當前目錄：", os.getcwd())
    
    while True:
        if os.path.exists("credentials.json"):
            try:
                with open("credentials.json", 'r') as f:
                    creds_data = json.load(f)
                
                # 檢查必要欄位
                required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email', 'client_id']
                missing_fields = [field for field in required_fields if field not in creds_data]
                
                if missing_fields:
                    print(f"❌ 認證檔案格式錯誤，缺少欄位：{missing_fields}")
                    input("請檢查檔案後按 Enter 重試...")
                    continue
                
                print("✅ 認證檔案格式正確")
                print(f"📧 服務帳戶：{creds_data['client_email']}")
                print(f"🏢 專案：{creds_data['project_id']}")
                return True
                
            except json.JSONDecodeError:
                print("❌ 認證檔案 JSON 格式錯誤")
                input("請檢查檔案後按 Enter 重試...")
                continue
            except Exception as e:
                print(f"❌ 讀取認證檔案失敗：{e}")
                input("請檢查檔案後按 Enter 重試...")
                continue
        else:
            print("❌ 找不到 credentials.json 檔案")
            input("請將檔案放到專案根目錄後按 Enter 重試...")

def guide_sheets_setup():
    """引導 Google Sheets 設置"""
    print("\n📊 Google Sheets 設置")
    print("-" * 20)
    
    print("步驟 1：創建工作表")
    print("1. 前往 https://sheets.google.com/")
    print("2. 點擊「建立空白試算表」")
    print("3. 將工作表命名為「台南餐廳資料庫」")
    
    open_sheets = input("\n是否要現在開啟 Google Sheets？(y/n): ").strip().lower()
    if open_sheets == 'y':
        webbrowser.open("https://sheets.google.com/")
    
    print("\n步驟 2：分享權限")
    print("1. 在 Google Sheets 中點擊「分享」按鈕")
    print("2. 在「新增使用者和群組」中輸入服務帳戶的電子郵件地址")
    
    # 讀取服務帳戶電子郵件
    try:
        with open("credentials.json", 'r') as f:
            creds_data = json.load(f)
        service_email = creds_data['client_email']
        print(f"3. 服務帳戶電子郵件：{service_email}")
    except:
        print("3. 服務帳戶電子郵件：請查看 credentials.json 中的 client_email 欄位")
    
    print("4. 權限設為「編輯者」")
    print("5. 點擊「完成」")
    
    input("\n完成上述步驟後，按 Enter 繼續...")

def test_connection():
    """測試連接"""
    print("\n🧪 測試連接")
    print("-" * 15)
    
    try:
        import gspread
        from google.oauth2.service_account import Credentials
        
        # 設置認證
        scopes = [
            'https://www.googleapis.com/auth/spreadsheets',
            'https://www.googleapis.com/auth/drive'
        ]
        creds = Credentials.from_service_account_file("credentials.json", scopes=scopes)
        client = gspread.authorize(creds)
        
        print("✅ Google Sheets API 連接成功")
        
        # 測試創建測試工作表
        test_sheet_name = f"Fooder_Test_{os.getpid()}"
        spreadsheet = client.create(test_sheet_name)
        print(f"✅ 成功創建測試工作表：{test_sheet_name}")
        
        # 清理測試工作表
        client.del_spreadsheet(spreadsheet.id)
        print("🧹 已清理測試工作表")
        
        return True
        
    except Exception as e:
        print(f"❌ 連接測試失敗：{e}")
        return False

def show_next_steps():
    """顯示後續步驟"""
    print("\n🎉 設置完成！")
    print("-" * 20)
    print("您的 Google Sheets API 已設置完成")
    print("\n💡 後續使用：")
    print("1. 檢查設置：python3 scripts/check_google_sheets_setup.py")
    print("2. 測試連接：python3 scripts/test_google_sheets_connection.py")
    print("3. 同步資料：python3 scripts/sync_restaurants_to_sheets_v2.py")
    print("\n📖 詳細文件：GOOGLE_SHEETS_SETUP.md")

def main():
    """主程式"""
    print_header()
    
    # 檢查前置需求
    if not check_prerequisites():
        print("❌ 前置需求檢查失敗，請解決問題後重試")
        return
    
    # 引導 Google Cloud Console 設置
    guide_google_cloud_setup()
    
    # 設置認證檔案
    if not setup_credentials_file():
        print("❌ 認證檔案設置失敗")
        return
    
    # 引導 Google Sheets 設置
    guide_sheets_setup()
    
    # 測試連接
    if not test_connection():
        print("❌ 連接測試失敗，請檢查設置")
        return
    
    # 顯示後續步驟
    show_next_steps()

if __name__ == "__main__":
    main() 