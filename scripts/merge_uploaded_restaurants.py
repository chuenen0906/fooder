#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
合併智慧上傳記錄到主要的 uploaded_restaurants.json 檔案
"""

import json
import os
from datetime import datetime

def merge_uploaded_restaurants():
    """合併智慧上傳記錄到主要記錄檔案"""
    
    # 讀取主要記錄檔案
    main_file = 'data/uploaded_restaurants.json'
    smart_file = 'data/uploaded_restaurants_smart.json'
    
    try:
        with open(main_file, 'r', encoding='utf-8') as f:
            main_data = json.load(f)
        print(f"✅ 讀取主要記錄檔案：{len(main_data)} 間餐廳")
    except FileNotFoundError:
        print("❌ 找不到主要記錄檔案")
        return
    
    try:
        with open(smart_file, 'r', encoding='utf-8') as f:
            smart_data = json.load(f)
        print(f"✅ 讀取智慧上傳記錄：{len(smart_data)} 間餐廳")
    except FileNotFoundError:
        print("❌ 找不到智慧上傳記錄檔案")
        return
    
    # 建立主要記錄的索引
    main_index = {restaurant['name']: i for i, restaurant in enumerate(main_data)}
    
    # 合併智慧上傳記錄
    updated_count = 0
    new_count = 0
    
    for smart_restaurant in smart_data:
        name = smart_restaurant['name']
        
        if name in main_index:
            # 更新現有記錄
            main_data[main_index[name]] = smart_restaurant
            updated_count += 1
            print(f"🔄 更新：{name}")
        else:
            # 新增記錄
            main_data.append(smart_restaurant)
            new_count += 1
            print(f"➕ 新增：{name}")
    
    # 儲存合併後的記錄
    with open(main_file, 'w', encoding='utf-8') as f:
        json.dump(main_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n🎉 合併完成！")
    print(f"📝 更新了 {updated_count} 間餐廳")
    print(f"📝 新增了 {new_count} 間餐廳")
    print(f"📊 總共 {len(main_data)} 間餐廳")
    
    # 統計多張照片的店家
    multi_photos = [r for r in main_data if len(r.get('photos', [])) > 1]
    print(f"📸 有多張照片的店家：{len(multi_photos)} 間")
    for restaurant in multi_photos:
        print(f"  - {restaurant['name']}: {len(restaurant['photos'])} 張")

if __name__ == "__main__":
    merge_uploaded_restaurants() 