#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
台南餐廳資料記錄器
連接 Google Sheets 記錄新增的店家資料
"""

import json
import datetime
from typing import List, Dict
import csv
import os

class RestaurantLogger:
    def __init__(self, log_file="restaurant_input_log.csv"):
        self.log_file = log_file
        self.init_log_file()
    
    def init_log_file(self):
        """初始化 CSV 記錄檔案"""
        if not os.path.exists(self.log_file):
            headers = [
                "輸入日期", "店家名稱", "區域", "特色料理", 
                "描述", "資料來源", "狀態", "備註"
            ]
            with open(self.log_file, 'w', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"✅ 已創建記錄檔案：{self.log_file}")
    
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
        
        with open(self.log_file, 'a', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            writer.writerow(record)
        
        print(f"✅ 已記錄店家：{name}")
        return record
    
    def batch_add_from_json(self, json_file: str, source: str = "JSON匯入"):
        """從 JSON 檔案批量匯入餐廳記錄"""
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                restaurants = json.load(f)
            
            added_count = 0
            for restaurant in restaurants:
                name = restaurant.get('name', '')
                area = restaurant.get('area', '')
                specialty = restaurant.get('specialty', '')
                description = restaurant.get('description', '')
                
                self.add_restaurant_record(
                    name=name,
                    area=area,
                    specialty=specialty,
                    description=description,
                    source=source,
                    status="已在資料庫"
                )
                added_count += 1
            
            print(f"✅ 批量匯入完成：{added_count} 家餐廳")
            
        except Exception as e:
            print(f"❌ 批量匯入失敗：{e}")
    
    def view_recent_records(self, limit: int = 10):
        """查看最近的記錄"""
        try:
            with open(self.log_file, 'r', encoding='utf-8') as file:
                reader = csv.reader(file)
                rows = list(reader)
                
            print(f"\n📋 最近 {limit} 筆記錄：")
            print("-" * 80)
            
            # 顯示標題
            if rows:
                headers = rows[0]
                print(" | ".join(f"{h:12}" for h in headers[:4]))
                print("-" * 80)
                
                # 顯示最近的記錄（倒序）
                recent_rows = rows[-limit:] if len(rows) > limit else rows[1:]
                for row in reversed(recent_rows):
                    if len(row) >= 4:
                        display_row = [str(cell)[:12] for cell in row[:4]]
                        print(" | ".join(f"{cell:12}" for cell in display_row))
            
        except Exception as e:
            print(f"❌ 讀取記錄失敗：{e}")
    
    def get_statistics(self):
        """獲取統計資訊"""
        try:
            with open(self.log_file, 'r', encoding='utf-8') as file:
                reader = csv.reader(file)
                rows = list(reader)
            
            if len(rows) <= 1:
                print("📊 目前沒有記錄")
                return
            
            data_rows = rows[1:]  # 跳過標題行
            total_count = len(data_rows)
            
            # 統計區域分布
            areas = {}
            statuses = {}
            sources = {}
            
            for row in data_rows:
                if len(row) >= 7:
                    area = row[2] or "未分類"
                    status = row[6] or "未知"
                    source = row[5] or "未知"
                    
                    areas[area] = areas.get(area, 0) + 1
                    statuses[status] = statuses.get(status, 0) + 1
                    sources[source] = sources.get(source, 0) + 1
            
            print(f"\n📊 統計資訊：")
            print(f"總記錄數：{total_count}")
            print(f"\n🏛️ 區域分布：")
            for area, count in sorted(areas.items()):
                print(f"  {area}：{count} 家")
            
            print(f"\n📋 狀態分布：")
            for status, count in sorted(statuses.items()):
                print(f"  {status}：{count} 家")
            
            print(f"\n📝 資料來源：")
            for source, count in sorted(sources.items()):
                print(f"  {source}：{count} 家")
                
        except Exception as e:
            print(f"❌ 統計失敗：{e}")

def main():
    """主要功能演示"""
    logger = RestaurantLogger()
    
    print("🍽️ 台南餐廳資料記錄器")
    print("=" * 50)
    
    while True:
        print(f"\n選擇功能：")
        print("1. 新增單筆餐廳記錄")
        print("2. 從現有資料庫匯入記錄")
        print("3. 查看最近記錄")
        print("4. 查看統計資訊")
        print("5. 退出")
        
        choice = input("\n請選擇 (1-5)：").strip()
        
        if choice == "1":
            name = input("店家名稱：").strip()
            if name:
                area = input("區域 (可選)：").strip()
                specialty = input("特色料理 (可選)：").strip()
                description = input("描述 (可選)：").strip()
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
        
        elif choice == "2":
            json_file = "tainan_markets.json"
            if os.path.exists(json_file):
                confirm = input(f"確定要從 {json_file} 匯入資料嗎？(y/N)：").strip().lower()
                if confirm == 'y':
                    logger.batch_add_from_json(json_file)
            else:
                print(f"❌ 找不到檔案：{json_file}")
        
        elif choice == "3":
            limit = input("顯示幾筆記錄 (預設 10)：").strip()
            try:
                limit = int(limit) if limit else 10
                logger.view_recent_records(limit)
            except ValueError:
                logger.view_recent_records(10)
        
        elif choice == "4":
            logger.get_statistics()
        
        elif choice == "5":
            print("👋 再見！")
            break
        
        else:
            print("❌ 無效選擇，請重新輸入")

if __name__ == "__main__":
    main() 