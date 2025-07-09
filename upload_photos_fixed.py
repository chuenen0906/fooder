import os
import json
import firebase_admin
from firebase_admin import credentials, storage
from datetime import datetime

# 初始化 Firebase
cred = credentials.Certificate('folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json')
firebase_admin.initialize_app(cred, {
    'storageBucket': 'folder-47165.firebasestorage.app'  # 正確的 Storage bucket 名稱
})

bucket = storage.bucket()

# 讀取餐廳資料
with open('tainan_markets.json', 'r', encoding='utf-8') as f:
    restaurants_data = json.load(f)

# 圖片根目錄
IMAGE_ROOT = 'downloaded_photos'

def check_file_exists_in_storage(storage_path):
    """檢查檔案是否已存在於 Firebase Storage"""
    try:
        blob = bucket.blob(storage_path)
        return blob.exists()
    except Exception:
        return False

uploaded_count = 0
skipped_count = 0
total_count = 0

print("🚀 開始上傳餐廳照片到 Firebase Storage...")

# 用來儲存上傳成功的餐廳資料
uploaded_restaurants = []

for restaurant in restaurants_data:
    restaurant_name = restaurant['name']
    restaurant_path = os.path.join(IMAGE_ROOT, restaurant_name)
    
    if not os.path.isdir(restaurant_path):
        print(f"⚠️ 找不到餐廳目錄: {restaurant_name}")
        continue

    photo_urls = []
    
    for filename in os.listdir(restaurant_path):
        if not filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            continue

        local_path = os.path.join(restaurant_path, filename)
        # Storage 路徑
        storage_path = f'restaurant_photos/{restaurant_name}/{filename}'

        # 檢查是否已存在
        if check_file_exists_in_storage(storage_path):
            print(f"⏭️  {restaurant_name}/{filename} 已存在，跳過上傳")
            skipped_count += 1
            total_count += 1
            
            # 獲取已存在檔案的 URL
            try:
                blob = bucket.blob(storage_path)
                blob.make_public()
                download_url = blob.public_url
                photo_urls.append(download_url)
            except Exception as e:
                print(f"⚠️ 獲取已存在檔案 URL 失敗: {e}")
            continue

        try:
            blob = bucket.blob(storage_path)
            blob.upload_from_filename(local_path)
            
            # 設定 metadata
            blob.metadata = {
                'restaurantName': restaurant_name,
                'area': restaurant['area'],
                'specialty': restaurant['specialty'],
                'uploadedBy': 'admin-script',
                'description': restaurant['description'],
                'uploadedAt': datetime.now().isoformat()
            }
            blob.patch()

            # 獲取下載 URL
            blob.make_public()
            download_url = blob.public_url
            photo_urls.append(download_url)

            total_count += 1
            uploaded_count += 1
            print(f'✅ 已上傳 {restaurant_name}/{filename} 到 Firebase Storage')
            
        except Exception as e:
            print(f'❌ 上傳失敗 {restaurant_name}/{filename}: {e}')
            total_count += 1

    # 如果有照片 URL（不論是新上傳或已存在），就記錄這家餐廳
    if photo_urls:
        restaurant_data = {
            'name': restaurant['name'],
            'specialty': restaurant['specialty'],
            'area': restaurant['area'],
            'description': restaurant['description'],
            'photos': photo_urls,
            'uploaded_at': datetime.now().isoformat()
        }
        uploaded_restaurants.append(restaurant_data)

# 將餐廳資料保存到本地 JSON 檔案
with open('uploaded_restaurants.json', 'w', encoding='utf-8') as f:
    json.dump(uploaded_restaurants, f, ensure_ascii=False, indent=2)

print(f"\n🎉 上傳完成!")
print(f"📊 新上傳: {uploaded_count} 張照片")
print(f"⏭️  跳過已存在: {skipped_count} 張照片")
print(f"📈 總處理: {total_count} 張照片")
print(f"🏪 總餐廳數: {len(uploaded_restaurants)} 家")
print(f"📄 餐廳資料已保存到: uploaded_restaurants.json")
print(f"📱 現在可以在 Fooder 應用程式中查看這些照片了!")

# 顯示一些上傳成功的範例 URL
if uploaded_restaurants:
    print(f"\n📸 部分照片 URL 範例:")
    for i, restaurant in enumerate(uploaded_restaurants[:3]):
        print(f"  {restaurant['name']}: {restaurant['photos'][0] if restaurant['photos'] else '無照片'}")

print(f"\n⚠️ 記得執行 BFG Repo-Cleaner 清理 Git 歷史，確保敏感檔案不會殘留在任何 commit！") 