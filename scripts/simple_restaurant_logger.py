#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
簡化版台南餐廳資料記錄器
不需要額外套件，可直接使用
"""

import json
import datetime
import csv
import os

class SimpleRestaurantLogger:
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
    
    def view_recent_records(self, limit: int = 10):
        """查看最近的記錄"""
        try:
            with open(self.log_file, 'r', encoding='utf-8') as file:
                reader = csv.reader(file)
                rows = list(reader)
                
            if len(rows) <= 1:
                print("📊 目前沒有記錄")
                return
                
            print(f"\n📋 最近 {limit} 筆記錄：")
            print("-" * 100)
            
            # 顯示標題
            headers = rows[0]
            print(" | ".join(f"{h:15}" for h in headers[:5]))
            print("-" * 100)
            
            # 顯示最近的記錄（倒序）
            recent_rows = rows[-limit:] if len(rows) > limit else rows[1:]
            for row in reversed(recent_rows):
                if len(row) >= 5:
                    display_row = [str(cell)[:15] for cell in row[:5]]
                    print(" | ".join(f"{cell:15}" for cell in display_row))
            
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
    
    def export_to_json(self, output_file="exported_restaurants.json"):
        """匯出為 JSON 格式"""
        try:
            with open(self.log_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                data = list(reader)
            
            with open(output_file, 'w', encoding='utf-8') as file:
                json.dump(data, file, ensure_ascii=False, indent=2)
            
            print(f"✅ 已匯出到：{output_file}")
            
        except Exception as e:
            print(f"❌ 匯出失敗：{e}")
    
    def generate_google_form_guide(self):
        """生成 Google 表單設置指南"""
        guide = """
🔗 Google 表單設置指南

1. 前往 https://forms.google.com
2. 點擊「建立空白表單」
3. 設置表單標題：「台南餐廳資料輸入表單」
4. 添加以下問題：

問題 1：店家名稱 (簡答，必填)
問題 2：區域 (下拉選單，必填)
   選項：中西區、東區、南區、北區、安平區、安南區、永康區、其他
問題 3：特色料理 (簡答)
問題 4：店家描述 (段落)
問題 5：資料來源 (下拉選單，必填)
   選項：實地探訪、網路搜尋、朋友推薦、社群媒體、美食部落格、其他
問題 6：處理狀態 (下拉選單)
   選項：待處理、已確認資訊、已加入資料庫、已上傳照片、完成
問題 7：備註 (段落)

5. 在「回應」標籤中點擊 Google Sheets 圖示
6. 選擇「建立新試算表」
7. 完成後即可開始收集資料！

表單將自動將回應儲存到 Google Sheets，方便您管理和分析資料。
        """
        
        with open("google_form_setup_guide.txt", "w", encoding="utf-8") as f:
            f.write(guide)
        
        print("📋 Google 表單設置指南已儲存到：google_form_setup_guide.txt")
        print(guide)

def main():
    """主要功能演示"""
    logger = SimpleRestaurantLogger()
    
    print("🍽️ 台南餐廳資料記錄器（簡化版）")
    print("=" * 60)
    
    while True:
        print(f"\n選擇功能：")
        print("1. 新增餐廳記錄")
        print("2. 查看最近記錄")
        print("3. 查看統計資訊")
        print("4. 匯出為 JSON")
        print("5. 生成 Google 表單設置指南")
        print("6. 退出")
        
        choice = input("\n請選擇 (1-6)：").strip()
        
        if choice == "1":
            print("\n📝 新增餐廳記錄：")
            name = input("店家名稱：").strip()
            if name:
                area = input("區域 (可選)：").strip()
                specialty = input("特色料理 (可選)：").strip()
                description = input("描述 (可選)：").strip()
                source = input("資料來源 (預設：手動輸入)：").strip() or "手動輸入"
                status = input("狀態 (預設：待處理)：").strip() or "待處理"
                notes = input("備註 (可選)：").strip()
                
                logger.add_restaurant_record(
                    name=name,
                    area=area,
                    specialty=specialty,
                    description=description,
                    source=source,
                    status=status,
                    notes=notes
                )
            else:
                print("❌ 店家名稱不能為空")
        
        elif choice == "2":
            limit = input("顯示幾筆記錄 (預設 10)：").strip()
            try:
                limit = int(limit) if limit else 10
                logger.view_recent_records(limit)
            except ValueError:
                logger.view_recent_records(10)
        
        elif choice == "3":
            logger.get_statistics()
        
        elif choice == "4":
            output_file = input("匯出檔名 (預設：exported_restaurants.json)：").strip()
            output_file = output_file or "exported_restaurants.json"
            logger.export_to_json(output_file)
        
        elif choice == "5":
            logger.generate_google_form_guide()
        
        elif choice == "6":
            print("👋 再見！")
            break
        
        else:
            print("❌ 無效選擇，請重新輸入")

if __name__ == "__main__":
    main() 