#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
合併 Firebase 服務映射：保留舊有所有照片，僅用新資料覆蓋同名餐廳
"""

import json
import re

def parse_old_mapping(content, start_marker, end_marker):
    """解析舊 Dart 檔案中的照片映射，回傳 dict"""
    start_pos = content.find(start_marker)
    end_pos = content.find(end_marker, start_pos)
    mapping_str = content[start_pos + len(start_marker):end_pos]
    # 用正則解析 key-value
    pattern = r'\s*"([^"]+)": \[(.*?)\],?\n'
    matches = re.findall(pattern, mapping_str, re.DOTALL)
    mapping = {}
    for name, urls_block in matches:
        urls = re.findall(r'"(https?://[^"]+)"', urls_block)
        mapping[name] = urls
    return mapping, start_pos, end_pos

def main():
    service_file = 'lib/services/firebase_restaurant_service.dart'
    uploaded_file = 'uploaded_restaurants_smart.json'
    start_marker = '  static const Map<String, List<String>> _restaurantPhotoUrls = {'
    end_marker = '  };'

    # 讀取 Dart 檔案
    with open(service_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 解析舊有映射
    old_mapping, start_pos, end_pos = parse_old_mapping(content, start_marker, end_marker)
    
    # 讀取新上傳資料
    with open(uploaded_file, 'r', encoding='utf-8') as f:
        uploaded_restaurants = json.load(f)
    
    # 用新資料覆蓋同名餐廳
    for restaurant in uploaded_restaurants:
        name = restaurant['name']
        photos = restaurant.get('photos', [])
        if photos:
            old_mapping[name] = photos
    
    # 產生 Dart 映射內容
    new_mappings = []
    for name, urls in old_mapping.items():
        photo_urls = ['      "' + url + '"' for url in urls]
        new_mappings.append('    "' + name + '": [\n' + ',\n'.join(photo_urls) + '\n    ],')
    
    # 合成新內容
    new_content = (
        content[:start_pos + len(start_marker)] +
        "\n" + "\n".join(new_mappings) + "\n" +
        content[end_pos:]
    )
    
    # 寫回 Dart 檔案
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✅ 合併完成，總餐廳數：{len(old_mapping)}")
    print(f"🆕 新增/覆蓋：{len(uploaded_restaurants)} 間餐廳")
    print("🎉 請重新編譯 App 以套用完整照片映射")

if __name__ == "__main__":
    main() 