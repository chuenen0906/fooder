import json
import re

# 要新增的餐廳資料
new_restaurants = [
  {"name": "醇涎坊鍋燒意麵", "specialty": "鍋燒意麵", "address": "中西區保安路53號", "description": "鍋燒意麵湯頭濃郁，排隊名店"},
  {"name": "阿村第二代牛肉湯", "specialty": "牛肉湯", "address": "中西區西門路一段362巷2號", "description": "比第一代更有年輕人風格的牛肉湯"},
  {"name": "小杜意麵", "specialty": "乾意麵", "address": "北區育德路", "description": "老饕推薦，醬香四溢"},
  {"name": "連得堂煎餅", "specialty": "炭烤煎餅", "address": "中西區忠義路二段", "description": "古法製作，手工煎餅排隊店"},
  {"name": "雙全紅茶", "specialty": "古早味紅茶", "address": "中西區中正路131號", "description": "冰鎮紅茶甜度適中，百年老店"},
  {"name": "阿龍香腸熟肉", "specialty": "香腸熟肉", "address": "中西區國華街三段", "description": "台南傳統黑白切代表"},
  {"name": "王氏魚皮", "specialty": "魚皮湯", "address": "南區健康路一段425號", "description": "在地人愛吃的早餐魚湯店"},
  {"name": "明和菜粽", "specialty": "菜粽", "address": "北區開元路", "description": "軟黏鹹香的古早味粽"},
  {"name": "好地方碗粿", "specialty": "碗粿", "address": "南區大同路二段", "description": "傳統柴魚醬搭配Q彈米漿"},
  {"name": "富成炒飯專家", "specialty": "蛋炒飯", "address": "東區裕農路", "description": "粒粒分明的炒飯霸主"},
  {"name": "赤崁東市場米糕", "specialty": "米糕", "address": "中西區民族路三段", "description": "老市場內的古早米糕"},
  {"name": "下大道米糕", "specialty": "米糕", "address": "北區文賢路", "description": "在地人從小吃到大的傳統味"},
  {"name": "順風號", "specialty": "炸雞排", "address": "東區東寧路", "description": "厚實又多汁的雞排"},
  {"name": "阿婆炒米粉", "specialty": "炒米粉", "address": "南區金華路", "description": "老字號炒米粉配滷蛋、豆腐"},
  {"name": "老家後甲魯麵", "specialty": "魯麵", "address": "東區後甲圓環", "description": "古早味魯麵配大骨湯"},
  {"name": "阿財牛肉湯", "specialty": "牛肉湯", "address": "南區金華路二段", "description": "台南傳統牛肉湯專門店"},
  {"name": "小林煎餃", "specialty": "鍋貼煎餃", "address": "北區育德路", "description": "平價又多汁的銅板美食"},
  {"name": "新都小籠包", "specialty": "小籠湯包", "address": "東區崇德路", "description": "湯汁飽滿，現點現蒸"},
  {"name": "王記鮮魚湯", "specialty": "鮮魚湯", "address": "中西區開山路", "description": "每日新鮮現殺魚片湯"},
  {"name": "廖家香腸", "specialty": "碳烤香腸", "address": "南區水交社", "description": "炭香十足的手工香腸"},
  {"name": "懷舊炒鱔魚麵", "specialty": "炒鱔魚", "address": "北區公園路", "description": "酸甜口感搭配現炒鱔魚"},
  {"name": "裕成水果店", "specialty": "水果切盤", "address": "東區崇學路", "description": "擺盤華麗的台南水果代表"},
  {"name": "小六鍋燒意麵", "specialty": "鍋燒意麵", "address": "北區公園南路", "description": "湯頭帶蝦味，麵條彈牙"},
  {"name": "阿財意麵", "specialty": "乾意麵", "address": "東區勝利路", "description": "簡單調味但超有味道"},
  {"name": "大菜市碗粿", "specialty": "碗粿", "address": "中西區西門路", "description": "菜市場隱藏版古早味"},
  {"name": "南園米糕", "specialty": "米糕", "address": "南區大同路", "description": "配菜豐富、甜辣醬提味"},
  {"name": "開元虱目魚", "specialty": "虱目魚肚湯", "address": "北區開元路", "description": "厚實肥美魚肚"},
  {"name": "延平市場魯肉飯", "specialty": "魯肉飯", "address": "中西區延平市場", "description": "油香入味，不膩口"},
  {"name": "陳家滷味", "specialty": "冷滷味", "address": "東區林森路", "description": "滷味冷吃更入味"},
  {"name": "勝利早點", "specialty": "蛋餅、飯糰", "address": "東區勝利路", "description": "學區人氣早餐店"},
  {"name": "阿來豬腳飯", "specialty": "豬腳飯", "address": "北區北門路", "description": "Q彈不膩豬腳配滷汁"},
  {"name": "水交社豆花", "specialty": "豆花", "address": "南區水交社", "description": "濃濃古早味豆花"},
  {"name": "美華冰菓室", "specialty": "剉冰", "address": "東區崇德路", "description": "傳統配料冰店"},
  {"name": "裕義紅茶", "specialty": "古早味紅茶", "address": "中西區民生路", "description": "微糖超順口"},
  {"name": "金得炸粿", "specialty": "炸粿", "address": "南區新興路", "description": "在地人下午點心愛店"},
  {"name": "和意路米糕", "specialty": "米糕", "address": "東區和意路", "description": "香菜+甜辣醬超加分"},
  {"name": "府城豬油拌飯", "specialty": "豬油飯", "address": "東區長榮路", "description": "香氣逼人，簡單經典"},
  {"name": "三輪車紅豆餅", "specialty": "紅豆餅", "address": "中西區康樂街", "description": "現烤酥脆、餡料飽滿"},
  {"name": "文成滷肉飯", "specialty": "滷肉飯", "address": "南區金華路", "description": "魯汁濃郁，平價飽足"},
  {"name": "國賓市場麵線", "specialty": "麵線羹", "address": "北區公園南路", "description": "台味十足，口感順滑"}
]

def extract_area_from_address(address):
    """從地址中提取區域"""
    if "中西區" in address:
        return "中西區"
    elif "東區" in address:
        return "東區"
    elif "南區" in address:
        return "南區"
    elif "北區" in address:
        return "北區"
    elif "永康" in address:
        return "永康"
    else:
        return "其他"

def check_and_add_restaurants():
    # 讀取現有資料
    with open('tainan_markets.json', 'r', encoding='utf-8') as f:
        existing_data = json.load(f)
    
    # 取得現有餐廳名稱
    existing_names = {restaurant['name'] for restaurant in existing_data}
    
    # 過濾出新餐廳
    restaurants_to_add = []
    skipped_restaurants = []
    
    for restaurant in new_restaurants:
        if restaurant['name'] not in existing_names:
            # 轉換格式以符合現有資料結構
            new_restaurant = {
                "name": restaurant['name'],
                "specialty": restaurant['specialty'],
                "area": extract_area_from_address(restaurant['address']),
                "description": restaurant['description']
            }
            restaurants_to_add.append(new_restaurant)
        else:
            skipped_restaurants.append(restaurant['name'])
    
    # 新增餐廳到資料庫
    existing_data.extend(restaurants_to_add)
    
    # 寫回檔案
    with open('tainan_markets.json', 'w', encoding='utf-8') as f:
        json.dump(existing_data, f, ensure_ascii=False, indent=2)
    
    # 輸出結果
    print(f"✅ 成功新增 {len(restaurants_to_add)} 間餐廳")
    print(f"⏭️  跳過 {len(skipped_restaurants)} 間已存在的餐廳")
    
    if restaurants_to_add:
        print("\n📝 新增的餐廳：")
        for restaurant in restaurants_to_add:
            print(f"  - {restaurant['name']} ({restaurant['area']})")
    
    if skipped_restaurants:
        print("\n⏭️  跳過的餐廳：")
        for name in skipped_restaurants:
            print(f"  - {name}")

if __name__ == "__main__":
    check_and_add_restaurants() 