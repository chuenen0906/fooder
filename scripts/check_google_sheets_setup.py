#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
快速檢查 Google Sheets 設置狀態
"""

import os
import json
import sys

def check_python_packages():
    """檢查必要的 Python 套件"""
    print("📦 檢查 Python 套件...")
    
    required_packages = ['gspread', 'google-auth']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✅ {package}")
        except ImportError:
            print(f"❌ {package} (未安裝)")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n💡 請安裝缺少的套件：")
        print(f"   python3 -m pip install {' '.join(missing_packages)}")
        return False
    
    return True

def check_credentials_file(credentials_file="credentials.json"):
    """檢查認證檔案"""
    print(f"\n🔐 檢查認證檔案：{credentials_file}")
    
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
        print(f"📧 服務帳戶：{creds_data['client_email']}")
        print(f"🏢 專案：{creds_data['project_id']}")
        return True
        
    except json.JSONDecodeError:
        print(f"❌ 認證檔案 JSON 格式錯誤")
        return False
    except Exception as e:
        print(f"❌ 讀取認證檔案失敗：{e}")
        return False

def check_data_files():
    """檢查資料檔案"""
    print(f"\n📁 檢查資料檔案...")
    
    data_files = [
        "tainan_markets.json",
        "data/tainan_markets.json"
    ]
    
    found_files = []
    for file_path in data_files:
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                print(f"✅ {file_path} ({len(data)} 家餐廳)")
                found_files.append((file_path, len(data)))
            except Exception as e:
                print(f"⚠️ {file_path} (讀取失敗：{e})")
        else:
            print(f"❌ {file_path} (不存在)")
    
    return found_files

def check_gitignore():
    """檢查 .gitignore 是否包含 credentials.json"""
    print(f"\n🔒 檢查 Git 安全性...")
    
    gitignore_file = ".gitignore"
    if os.path.exists(gitignore_file):
        with open(gitignore_file, 'r') as f:
            content = f.read()
        
        if "credentials.json" in content:
            print("✅ credentials.json 已在 .gitignore 中")
            return True
        else:
            print("⚠️ credentials.json 未在 .gitignore 中")
            return False
    else:
        print("⚠️ 找不到 .gitignore 檔案")
        return False

def generate_setup_summary():
    """生成設置摘要"""
    print(f"\n📋 Google Sheets 設置摘要")
    print("=" * 50)
    
    # 檢查套件
    packages_ok = check_python_packages()
    
    # 檢查認證檔案
    credentials_ok = check_credentials_file()
    
    # 檢查資料檔案
    data_files = check_data_files()
    
    # 檢查 Git 安全性
    git_secure = check_gitignore()
    
    # 總結
    print(f"\n🎯 設置狀態總結：")
    
    if packages_ok and credentials_ok and data_files:
        print("✅ 基本設置完成！")
        print("💡 下一步：")
        print("1. 執行測試：python3 scripts/test_google_sheets_connection.py")
        print("2. 同步資料：python3 scripts/sync_restaurants_to_sheets_v2.py")
    else:
        print("❌ 設置不完整")
        print("💡 請按照 GOOGLE_SHEETS_SETUP.md 完成設置")
    
    if not git_secure:
        print("⚠️ 安全提醒：請將 credentials.json 加入 .gitignore")
    
    return packages_ok and credentials_ok and bool(data_files)

def main():
    """主程式"""
    print("🔍 Google Sheets 設置檢查工具")
    print("=" * 50)
    
    success = generate_setup_summary()
    
    if success:
        print(f"\n🎉 檢查完成！您的 Google Sheets 設置看起來沒問題。")
    else:
        print(f"\n⚠️ 檢查完成！請解決上述問題後再試。")
        print("📖 詳細設置指南：GOOGLE_SHEETS_SETUP.md")

if __name__ == "__main__":
    main() 