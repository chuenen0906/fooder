#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
主控一鍵自動化腳本：批次新增餐廳、抓圖、上傳、合併映射、同步 Sheets
"""
import subprocess
import argparse
import sys
import json


def determine_area(address):
    """根據地址推斷區域"""
    if not address:
        return "中西區"  # 預設
        
    if "北門路" in address or "公園路" in address or "北區" in address:
        return "北區"
    elif "中華北路" in address:
        return "北區" 
    elif "西門路" in address:
        return "中西區"
    elif "開元路" in address:
        return "北區"
    elif "成功路" in address or "成功大學" in address:
        return "東區"
    elif "鴨母寮" in address:
        return "中西區"
    elif "文賢路" in address:
        return "東區"
    else:
        return "中西區"  # 預設


def add_new_restaurants(json_file_path):
    """新增餐廳到資料庫（自動檢查重複）"""
    print(f"\n{'='*40}")
    print("▶️ 新增餐廳（自動檢查重複）")
    
    # 讀取新餐廳資料
    try:
        print(f"🔍 讀取新餐廳資料：{json_file_path}")
        with open(json_file_path, 'r', encoding='utf-8') as f:
            new_restaurants = json.load(f)
        print(f"📊 新餐廳數量：{len(new_restaurants)} 間")
    except FileNotFoundError:
        print(f"❌ 找不到檔案：{json_file_path}")
        return 0
    except json.JSONDecodeError:
        print(f"❌ JSON格式錯誤：{json_file_path}")
        return 0
    
    # 讀取現有資料
    print("🔍 讀取現有餐廳資料...")
    try:
        with open('tainan_markets.json', 'r', encoding='utf-8') as f:
            existing_restaurants = json.load(f)
    except FileNotFoundError:
        print("❌ 找不到 tainan_markets.json")
        return 0
    
    # 建立現有餐廳名稱的集合
    existing_names = {restaurant['name'] for restaurant in existing_restaurants}
    print(f"📊 現有餐廳數量：{len(existing_restaurants)} 間")
    
    # 檢查重複
    print("🔍 檢查重複餐廳...")
    duplicates = []
    new_to_add = []
    
    for restaurant in new_restaurants:
        restaurant_name = restaurant.get('name', '')
        if restaurant_name in existing_names:
            duplicates.append(restaurant_name)
            print(f"❌ 重複：{restaurant_name}")
        else:
            # 補充缺少的欄位並推斷區域
            address = restaurant.get('address', '')
            # 支援新格式的 district 欄位，如果沒有則從地址推斷
            area = restaurant.get('district', restaurant.get('area', determine_area(address)))
            formatted_restaurant = {
                "name": restaurant_name,
                "specialty": restaurant.get('specialty', ''),
                "area": area,
                "description": restaurant.get('description', '')
            }
            new_to_add.append(formatted_restaurant)
            print(f"✅ 新增：{restaurant_name} ({area})")
    
    print(f"\n📊 統計結果：")
    print(f"重複餐廳：{len(duplicates)} 間")
    print(f"新增餐廳：{len(new_to_add)} 間")
    
    if new_to_add:
        # 新增到現有資料
        existing_restaurants.extend(new_to_add)
        
        # 儲存更新後的資料
        with open('tainan_markets.json', 'w', encoding='utf-8') as f:
            json.dump(existing_restaurants, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ 已將 {len(new_to_add)} 間新餐廳加入到 tainan_markets.json")
        print(f"📊 更新後總餐廳數量：{len(existing_restaurants)} 間")
        
        # 顯示新增的餐廳
        print("\n🆕 新增的餐廳：")
        for restaurant in new_to_add:
            print(f"  - {restaurant['name']} ({restaurant['specialty']}) - {restaurant['area']}")
            
        return len(new_to_add)  # 返回新增數量
    else:
        print("\n⚠️ 沒有新餐廳需要新增")
        return 0


def run_cmd(cmd, desc=None):
    print(f"\n{'='*40}")
    if desc:
        print(f"▶️ {desc}")
    print(f"$ {' '.join(cmd)}")
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(f"❌ 指令失敗: {' '.join(cmd)}")
        sys.exit(1)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description='一鍵自動化：新增餐廳、抓圖、上傳、合併映射、同步 Sheets')
    parser.add_argument('--json', required=True, help='新餐廳 JSON 檔案路徑')
    parser.add_argument('--latest', type=int, required=True, help='本批新餐廳數量')
    args = parser.parse_args()

    # 1. 新增餐廳（自動檢查重複）- 整合功能
    new_count = add_new_restaurants(args.json)
    
    if new_count == 0:
        print("\n⚠️ 沒有新餐廳，跳過後續步驟")
        return

    # 2. 抓取新餐廳照片
    run_cmd(['python3', 'download_photos_smart.py', '--latest', str(args.latest)], desc='抓取新餐廳照片')

    # 3. 上傳新餐廳照片到 Firebase
    run_cmd(['python3', 'upload_photos_smart.py', '--latest', str(args.latest)], desc='上傳新餐廳照片到 Firebase')

    # 4. 合併 Dart 映射
    run_cmd(['python3', 'update_firebase_mapping.py'], desc='合併 Dart 端照片映射')

    # 5. 同步 Google Sheets
    run_cmd(['python3', 'sync_restaurants_to_sheets_v2.py'], desc='同步 Google Sheets')

    print("\n🎉 一鍵自動化流程完成！所有資料、照片、映射、Sheets 都已同步！")

if __name__ == "__main__":
    main() 