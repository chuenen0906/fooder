import os
import json
import argparse
import firebase_admin
from firebase_admin import credentials, storage
from datetime import datetime

def parse_arguments():
    parser = argparse.ArgumentParser(description='智慧上傳餐廳照片到 Firebase Storage')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--latest', type=int, metavar='N', 
                      help='只處理最新的 N 間餐廳')
    group.add_argument('--restaurant', type=str, metavar='名稱',
                      help='只處理指定的餐廳')
    group.add_argument('--all', action='store_true',
                      help='處理所有餐廳（預設行為）')
    
    return parser.parse_args()

def init_firebase():
    """初始化 Firebase"""
    try:
        cred = credentials.Certificate('folder-47165-firebase-adminsdk-fbsvc-a63e66e03d.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'folder-47165.firebasestorage.app'
        })
        return storage.bucket()
    except Exception as e:
        print(f"❌ Firebase 初始化失敗: {e}")
        return None

def check_file_exists_in_storage(bucket, storage_path):
    """檢查檔案是否已存在於 Firebase Storage"""
    try:
        blob = bucket.blob(storage_path)
        return blob.exists()
    except Exception:
        return False

def get_restaurants_to_process(restaurants_data, args):
    """根據參數決定要處理哪些餐廳"""
    if args.restaurant:
        # 處理指定餐廳
        filtered = [r for r in restaurants_data if r['name'] == args.restaurant]
        if not filtered:
            print(f"❌ 找不到餐廳: {args.restaurant}")
            return []
        print(f"🎯 只處理指定餐廳: {args.restaurant}")
        return filtered
    
    elif args.latest:
        # 處理最新的 N 間餐廳
        latest_restaurants = restaurants_data[-args.latest:]
        print(f"🎯 只處理最新的 {args.latest} 間餐廳")
        return latest_restaurants
    
    else:
        # 處理所有餐廳
        print(f"🎯 處理所有 {len(restaurants_data)} 間餐廳")
        return restaurants_data

def upload_restaurant_photos(bucket, restaurant, image_root, max_photos=5):
    """上傳單一餐廳的照片（最多 5 張）"""
    restaurant_name = restaurant['name']
    restaurant_path = os.path.join(image_root, restaurant_name)
    
    if not os.path.isdir(restaurant_path):
        print(f"⚠️ 找不到餐廳目錄: {restaurant_name}")
        return None, 0, 0
    
    photo_urls = []
    uploaded_count = 0
    skipped_count = 0
    processed_photos = 0
    
    # 只處理前 5 張照片
    photo_files = [f for f in os.listdir(restaurant_path) 
                   if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif'))]
    photo_files = photo_files[:max_photos]  # 限制最多 5 張
    
    for filename in photo_files:        
        local_path = os.path.join(restaurant_path, filename)
        storage_path = f'restaurant_photos/{restaurant_name}/{filename}'
        
        # 檢查是否已存在
        if check_file_exists_in_storage(bucket, storage_path):
            print(f"⏭️  {restaurant_name}/{filename} 已存在，跳過上傳")
            skipped_count += 1
            
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
            
            uploaded_count += 1
            print(f'✅ 已上傳 {restaurant_name}/{filename} 到 Firebase Storage')
            
        except Exception as e:
            print(f'❌ 上傳失敗 {restaurant_name}/{filename}: {e}')
    
    # 如果有照片 URL，建立餐廳資料
    if photo_urls:
        if len(photo_files) > max_photos:
            print(f"📸 {restaurant_name}: 找到 {len(photo_files)} 張照片，僅處理前 {max_photos} 張")
        
        restaurant_data = {
            'name': restaurant['name'],
            'specialty': restaurant['specialty'],
            'area': restaurant['area'],
            'description': restaurant['description'],
            'photos': photo_urls,
            'uploaded_at': datetime.now().isoformat()
        }
        return restaurant_data, uploaded_count, skipped_count
    
    return None, uploaded_count, skipped_count

def main():
    args = parse_arguments()
    
    # 初始化 Firebase
    bucket = init_firebase()
    if not bucket:
        return
    
    # 讀取餐廳資料
    try:
        with open('tainan_markets.json', 'r', encoding='utf-8') as f:
            restaurants_data = json.load(f)
    except FileNotFoundError:
        print("❌ 找不到 tainan_markets.json 檔案")
        return
    
    # 決定要處理哪些餐廳
    restaurants_to_process = get_restaurants_to_process(restaurants_data, args)
    if not restaurants_to_process:
        return
    
    print(f"🚀 開始上傳餐廳照片到 Firebase Storage...")
    
    uploaded_restaurants = []
    total_uploaded = 0
    total_skipped = 0
    
    for i, restaurant in enumerate(restaurants_to_process, 1):
        print(f"\n[{i}/{len(restaurants_to_process)}] 處理餐廳: {restaurant['name']}")
        
        restaurant_data, uploaded, skipped = upload_restaurant_photos(
            bucket, restaurant, 'downloaded_photos'
        )
        
        if restaurant_data:
            uploaded_restaurants.append(restaurant_data)
        
        total_uploaded += uploaded
        total_skipped += skipped
    
    # 保存結果
    if uploaded_restaurants:
        output_file = 'uploaded_restaurants_smart.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(uploaded_restaurants, f, ensure_ascii=False, indent=2)
        
        print(f"\n🎉 上傳完成!")
        print(f"📊 新上傳: {total_uploaded} 張照片")
        print(f"⏭️  跳過已存在: {total_skipped} 張照片") 
        print(f"📈 總處理: {total_uploaded + total_skipped} 張照片")
        print(f"🏪 有照片的餐廳: {len(uploaded_restaurants)} 家")
        print(f"📄 餐廳資料已保存到: {output_file}")
        
        # 顯示範例 URL
        if uploaded_restaurants:
            print(f"\n📸 部分照片 URL 範例:")
            for restaurant in uploaded_restaurants[:3]:
                if restaurant['photos']:
                    print(f"  {restaurant['name']}: {restaurant['photos'][0]}")
    else:
        print(f"\n⚠️ 沒有餐廳需要上傳照片")
    
    print(f"\n⚠️ 記得執行 BFG Repo-Cleaner 清理 Git 歷史！")

if __name__ == "__main__":
    main() 