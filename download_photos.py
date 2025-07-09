import json
import os
from google_images_search import GoogleImagesSearch
import requests

# 從環境變數讀取 API Key，避免硬編碼
API_KEY = os.getenv('GOOGLE_API_KEY')
CX = os.getenv('GOOGLE_CX')

if not API_KEY or not CX:
    raise ValueError("請設定環境變數 GOOGLE_API_KEY 和 GOOGLE_CX")

with open('tainan_markets.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

output_dir = 'downloaded_photos'
os.makedirs(output_dir, exist_ok=True)

gis = GoogleImagesSearch(API_KEY, CX)

def get_image_ext(url):
    for ext in ['.jpg', '.jpeg', '.png', '.gif']:
        if ext in url.lower():
            return ext
    return '.jpg'  # 預設

def has_existing_photo(shop_dir):
    """檢查店家目錄是否已有照片"""
    if not os.path.exists(shop_dir):
        return False
    
    # 檢查目錄中是否有圖片檔案
    for file in os.listdir(shop_dir):
        if file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            return True
    return False

new_downloads = 0
skipped_existing = 0

for shop in data:
    name = shop['name']
    area = shop['area']
    keyword = f"台南 {area} {name} 店面"
    shop_dir = os.path.join(output_dir, name)
    
    # 檢查是否已有照片
    if has_existing_photo(shop_dir):
        print(f"⏭️  {name} 已有照片，跳過下載")
        skipped_existing += 1
        continue
    
    os.makedirs(shop_dir, exist_ok=True)
    print(f"🔍 搜尋並下載：{keyword}")

    _search_params = {
        'q': keyword,
        'num': 1,  # 每家只抓一張主圖
        'safe': 'off',
        'fileType': 'jpg|png',
        'imgType': 'photo',
        'imgSize': 'large',
    }
    try:
        gis.search(_search_params)
        for image in gis.results():
            img_url = image.url
            img_data = requests.get(img_url).content
            img_ext = get_image_ext(img_url)
            img_path = os.path.join(shop_dir, f"{name}{img_ext}")
            with open(img_path, 'wb') as handler:
                handler.write(img_data)
            print(f"✅ {name} 圖片已下載：{img_path}")
            new_downloads += 1
            break  # 只抓第一張
    except Exception as e:
        print(f"❌ {name} 下載失敗：{e}")

print(f"\n📊 下載統計：")
print(f"新下載: {new_downloads} 張")
print(f"跳過已存在: {skipped_existing} 張")
print(f"總店家數: {len(data)} 家") 