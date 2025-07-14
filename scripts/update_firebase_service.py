import json
import os

def generate_firebase_service():
    """從 uploaded_restaurants.json 生成更新的 firebase_restaurant_service.dart"""
    
    # 讀取 uploaded_restaurants.json
    with open('uploaded_restaurants.json', 'r', encoding='utf-8') as f:
        restaurants = json.load(f)
    
    print(f"📊 讀取到 {len(restaurants)} 家餐廳資料")
    
    # 生成 Dart 映射
    dart_map_entries = []
    
    for restaurant in restaurants:
        name = restaurant['name']
        photos = restaurant['photos']
        
        # 格式化照片 URL 列表
        photo_urls = '[\n      "' + '",\n      "'.join(photos) + '"\n    ]'
        
        dart_entry = f'    "{name}": {photo_urls}'
        dart_map_entries.append(dart_entry)
    
    # 生成完整的 Dart 檔案內容
    upload_date = restaurants[0]['uploaded_at'][:10] if restaurants else 'N/A'
    dart_content = '''import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseRestaurantService {
  static final FirebaseRestaurantService _instance = FirebaseRestaurantService._internal();
  factory FirebaseRestaurantService() => _instance;
  FirebaseRestaurantService._internal();

  // Firebase 上傳的餐廳照片映射 - 自動生成於 ''' + upload_date + '''
  static const Map<String, List<String>> _restaurantPhotoUrls = {
''' + ',\n'.join(dart_map_entries) + '''
  };

  /// 根據餐廳名稱獲取 Firebase 上的照片 URL
  static List<String> getFirebasePhotos(String restaurantName) {
    // 精確匹配
    if (_restaurantPhotoUrls.containsKey(restaurantName)) {
      return _restaurantPhotoUrls[restaurantName]!;
    }
    
    // 模糊匹配 - 處理名稱可能的變化
    for (final entry in _restaurantPhotoUrls.entries) {
      final firebaseName = entry.key;
      
      // 如果 Google API 的名稱包含 Firebase 的名稱，或反之
      if (restaurantName.contains(firebaseName) || firebaseName.contains(restaurantName)) {
        print("🔍 模糊匹配成功: '$restaurantName' -> '$firebaseName'");
        return entry.value;
      }
      
      // 去除常見的店面相關詞語進行比較
      final cleanGoogleName = _cleanRestaurantName(restaurantName);
      final cleanFirebaseName = _cleanRestaurantName(firebaseName);
      
      if (cleanGoogleName == cleanFirebaseName) {
        print("🔍 清理後匹配成功: '$restaurantName' -> '$firebaseName'");
        return entry.value;
      }
    }
    
    print("❌ 未找到匹配的 Firebase 照片: $restaurantName");
    return [];
  }

  /// 清理餐廳名稱，移除常見的後綴詞
  static String _cleanRestaurantName(String name) {
    return name
        .replaceAll('店', '')
        .replaceAll('館', '')
        .replaceAll('屋', '')
        .replaceAll('坊', '')
        .replaceAll('家', '')
        .replaceAll('號', '')
        .replaceAll('記', '')
        .replaceAll('牌', '')
        .replaceAll('老', '')
        .replaceAll(' ', '');
  }

  /// 檢查餐廳是否有 Firebase 照片
  static bool hasFirebasePhotos(String restaurantName) {
    return getFirebasePhotos(restaurantName).isNotEmpty;
  }

  /// 獲取所有有 Firebase 照片的餐廳名稱
  static List<String> getAllFirebaseRestaurantNames() {
    return _restaurantPhotoUrls.keys.toList();
  }

  /// 結合 Google API 餐廳資料和 Firebase 照片
  static Map<String, dynamic> enhanceRestaurantWithFirebasePhotos(Map<String, dynamic> googleRestaurant) {
    final restaurantName = googleRestaurant['name'] ?? '';
    final firebasePhotos = getFirebasePhotos(restaurantName);
    
    if (firebasePhotos.isNotEmpty) {
      // 使用 Firebase 照片取代 Google Photos
      googleRestaurant['photo_urls'] = json.encode(firebasePhotos);
      googleRestaurant['has_firebase_photos'] = true;
      googleRestaurant['photo_source'] = 'firebase';
      
      print("✅ 使用 Firebase 照片: $restaurantName (${firebasePhotos.length} 張)");
    } else {
      googleRestaurant['has_firebase_photos'] = false;
      googleRestaurant['photo_source'] = 'google';
    }
    
    return googleRestaurant;
  }

  /// 批量處理餐廳列表，加入 Firebase 照片
  static List<Map<String, dynamic>> enhanceRestaurantListWithFirebasePhotos(List<Map<String, dynamic>> restaurants) {
    int firebasePhotoCount = 0;
    int totalRestaurants = restaurants.length;
    
    final enhancedRestaurants = restaurants.map((restaurant) {
      final enhanced = enhanceRestaurantWithFirebasePhotos(restaurant);
      if (enhanced['has_firebase_photos'] == true) {
        firebasePhotoCount++;
      }
      return enhanced;
    }).toList();
    
    print("📊 Firebase 照片整合完成: $firebasePhotoCount/$totalRestaurants 家餐廳使用 Firebase 照片");
    
    return enhancedRestaurants;
  }

  /// 取得統計資訊
  static Map<String, dynamic> getPhotoStats() {
    return {
      'total_firebase_restaurants': _restaurantPhotoUrls.length,
      'total_firebase_photos': _restaurantPhotoUrls.values.fold(0, (sum, photos) => sum + photos.length),
      'restaurants_with_photos': _restaurantPhotoUrls.keys.toList(),
    };
  }
}
'''
    
    # 寫入更新的檔案
    output_path = 'lib/services/firebase_restaurant_service.dart'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(dart_content)
    
    total_photos = sum(len(r['photos']) for r in restaurants)
    
    print(f"✅ 已生成更新的 Firebase 服務檔案：{output_path}")
    print(f"📊 統計資料：")
    print(f"   - 餐廳數量：{len(restaurants)} 家")
    print(f"   - 照片總數：{total_photos} 張")
    print(f"   - 平均每家：{total_photos/len(restaurants):.1f} 張照片")

if __name__ == "__main__":
    generate_firebase_service() 