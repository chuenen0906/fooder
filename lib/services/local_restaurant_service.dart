import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocalRestaurantService {
  static List<Map<String, dynamic>>? _cachedRestaurants;
  
  /// 載入本地餐廳資料
  static Future<List<Map<String, dynamic>>> loadLocalRestaurants() async {
    if (_cachedRestaurants != null) {
      return _cachedRestaurants!;
    }
    
    try {
      final String jsonString = await rootBundle.loadString('tainan_markets.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _cachedRestaurants = jsonData.map((item) => {
        'name': item['name'] ?? '',
        'specialty': item['specialty'] ?? '',
        'area': item['area'] ?? '',
        'description': item['description'] ?? '',
        'source': 'local_database',
        'photo_source': 'pending', // 待檢查
        'has_firebase_photos': false, // 待檢查
      }).cast<Map<String, dynamic>>().toList();
      
      print('📚 載入本地餐廳資料: ${_cachedRestaurants!.length} 間餐廳');
      return _cachedRestaurants!;
    } catch (e) {
      print('❌ 載入本地餐廳資料失敗: $e');
      return [];
    }
  }
  
  /// 根據位置和半徑篩選餐廳
  static List<Map<String, dynamic>> filterByLocation({
    required List<Map<String, dynamic>> restaurants,
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    // 台南市中心大概位置：22.9999, 120.2269
    // 這裡我們假設所有在 tainan_markets.json 中的餐廳都在台南市區內
    // 實際應用中可以加入更精確的經緯度資料
    
    final tainanCenterLat = 22.9999;
    final tainanCenterLng = 120.2269;
    
    return restaurants.where((restaurant) {
      // 簡化版：如果用戶搜尋範圍包含台南市中心，就顯示所有本地餐廳
      final distanceToTainan = Geolocator.distanceBetween(
        lat, lng, tainanCenterLat, tainanCenterLng
      );
      
      // 如果用戶在台南附近 50 公里內，顯示本地餐廳
      if (distanceToTainan <= 50000) {
        // 為本地餐廳分配隨機但合理的距離（在搜尋半徑內）
        final randomDistance = (radiusKm * 1000 * 0.3) + 
                              (radiusKm * 1000 * 0.7 * (restaurant['name'].hashCode % 100) / 100);
        restaurant['distance'] = randomDistance.toStringAsFixed(0);
        restaurant['lat'] = (tainanCenterLat + (restaurant['name'].hashCode % 200 - 100) * 0.001).toString();
        restaurant['lng'] = (tainanCenterLng + (restaurant['name'].hashCode % 200 - 100) * 0.001).toString();
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// 搜尋本地餐廳
  static Future<List<Map<String, dynamic>>> searchLocalRestaurants({
    required double lat,
    required double lng,
    required double radiusKm,
    String? keyword,
  }) async {
    final allRestaurants = await loadLocalRestaurants();
    
    // 先按位置篩選
    var filteredRestaurants = filterByLocation(
      restaurants: allRestaurants,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
    
    // 如果有關鍵字，進一步篩選
    if (keyword != null && keyword.isNotEmpty) {
      filteredRestaurants = filteredRestaurants.where((restaurant) {
        final name = restaurant['name']?.toString().toLowerCase() ?? '';
        final specialty = restaurant['specialty']?.toString().toLowerCase() ?? '';
        final area = restaurant['area']?.toString().toLowerCase() ?? '';
        final description = restaurant['description']?.toString().toLowerCase() ?? '';
        final searchKeyword = keyword.toLowerCase();
        
        return name.contains(searchKeyword) ||
               specialty.contains(searchKeyword) ||
               area.contains(searchKeyword) ||
               description.contains(searchKeyword);
      }).toList();
    }
    
    print('🔍 本地餐廳搜尋結果: ${filteredRestaurants.length} 間餐廳');
    return filteredRestaurants;
  }
  
  /// 模擬 Google API 格式的餐廳資料
  static Map<String, dynamic> convertToGoogleFormat(Map<String, dynamic> localRestaurant) {
    return {
      'name': localRestaurant['name'] ?? '',
      'image': 'https://via.placeholder.com/400x300.png?text=${Uri.encodeComponent(localRestaurant['name'] ?? 'Restaurant')}',
      'lat': localRestaurant['lat'] ?? '22.9999',
      'lng': localRestaurant['lng'] ?? '120.2269',
      'distance': localRestaurant['distance'] ?? '1000',
      'types': json.encode(['restaurant', 'food', 'establishment']),
      'rating': '4.0', // 預設評分
      'open_now': 'unknown',
      'photo_references': json.encode([]),
      'place_id': 'local_${localRestaurant['name']?.hashCode ?? 0}',
      'photo_urls': json.encode([]),
      'vicinity': '${localRestaurant['area'] ?? '台南市'} - ${localRestaurant['specialty'] ?? ''}',
      'address': '台南市${localRestaurant['area'] ?? ''} - ${localRestaurant['description'] ?? ''}',
      'source': 'local_database',
      'specialty': localRestaurant['specialty'] ?? '',
      'area': localRestaurant['area'] ?? '',
      'description': localRestaurant['description'] ?? '',
    };
  }
  
  /// 清除快取
  static void clearCache() {
    _cachedRestaurants = null;
  }
} 