import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'image_service.dart';

class RestaurantJsonService {
  static Future<List<Map<String, dynamic>>> loadRestaurants() async {
    final String jsonString = await rootBundle.loadString('lib/data/tainan_restaurants.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> restaurants = jsonData['restaurants'];
    
    // 轉換為與 Google API 相容的格式
    return restaurants.map<Map<String, dynamic>>((restaurant) {
      final random = Random();
      
      // 模擬距離計算（假設在台南市中心附近）
      final double centerLat = 22.9971;
      final double centerLng = 120.1968;
      final double distance = _calculateDistance(
        centerLat, 
        centerLng, 
        restaurant['lat'] as double, 
        restaurant['lng'] as double
      );
      
      // 獲取餐廳ID用於圖片路徑
      final String restaurantId = restaurant['id'] ?? '';
      
      // 處理圖片URLs
      List<String> photoUrls = [];
      if (restaurant['photo_urls'] != null) {
        photoUrls = List<String>.from(restaurant['photo_urls']);
      }
      
      // 驗證圖片路徑，移除不存在的圖片
      photoUrls = ImageService.validateImagePaths(photoUrls);
      
      // 如果沒有圖片，嘗試從圖片服務獲取
      if (photoUrls.isEmpty) {
        photoUrls = ImageService.getRestaurantImages(restaurantId);
      }
      
      // 確保至少有一張圖片
      String mainImage = 'assets/loading_pig.png';
      if (photoUrls.isNotEmpty) {
        mainImage = photoUrls.first;
      }
      
      return {
        'name': restaurant['name'] ?? '',
        'image': mainImage,
        'lat': restaurant['lat'].toString(),
        'lng': restaurant['lng'].toString(),
        'distance': distance.toStringAsFixed(0),
        'types': json.encode(restaurant['types'] ?? []),
        'rating': restaurant['rating']?.toString() ?? 'N/A',
        'open_now': restaurant['open_now']?.toString() ?? 'unknown',
        'photo_references': json.encode([]),
        'place_id': 'json_${restaurant['id']}',
        'photo_urls': json.encode(photoUrls),
        'address': restaurant['address'] ?? '',
        'phone': restaurant['phone'] ?? '',
        'website': restaurant['website'] ?? '',
        'price_level': restaurant['price_level']?.toString() ?? 'N/A',
        'image_count': photoUrls.length,
        'has_images': photoUrls.isNotEmpty,
      };
    }).toList();
  }
  
  // 簡化的距離計算（使用 Haversine 公式）
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 地球半徑（公尺）
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
} 