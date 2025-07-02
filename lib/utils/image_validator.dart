import 'dart:io';
import 'package:flutter/services.dart';

class ImageValidator {
  /// 檢查圖片檔案是否存在且有效
  static Future<bool> isValidImage(String imagePath) async {
    try {
      // 嘗試載入圖片
      await rootBundle.load(imagePath);
      return true;
    } catch (e) {
      print('❌ 圖片無效: $imagePath - $e');
      return false;
    }
  }
  
  /// 檢查餐廳的所有圖片
  static Future<List<String>> validateRestaurantImages(String restaurantId) async {
    final List<String> validImages = [];
    final String basePath = 'assets/restaurants_collection/$restaurantId';
    
    for (int i = 1; i <= 10; i++) {
      final String imagePath = '$basePath/${restaurantId}_$i.jpg';
      if (await isValidImage(imagePath)) {
        validImages.add(imagePath);
        print('✅ 圖片有效: $imagePath');
      }
    }
    
    return validImages;
  }
  
  /// 生成圖片清單報告
  static Future<void> generateImageReport() async {
    print('📸 開始檢查所有餐廳圖片...');
    
    final List<String> restaurantIds = [
      'aming', 'atang', 'chous', 'douhsiao', 'fusheng', 'tongji', 'asong',
      'ahan', 'shengli', 'achuan', 'huaijiu', 'izuminami', 'caijia',
      'shijingjiu', 'jinde', 'weijia', 'lanji', 'xiezhanggui', 'shanghaochi',
      'acun', 'ajuan', 'yifeng', 'yejia', 'yongle'
    ];
    
    final Map<String, List<String>> validImages = {};
    
    for (final restaurantId in restaurantIds) {
      final images = await validateRestaurantImages(restaurantId);
      if (images.isNotEmpty) {
        validImages[restaurantId] = images;
      }
    }
    
    print('\n📊 圖片檢查報告:');
    print('總共檢查了 ${restaurantIds.length} 家餐廳');
    print('有圖片的餐廳: ${validImages.length} 家');
    
    for (final entry in validImages.entries) {
      print('${entry.key}: ${entry.value.length} 張圖片');
    }
  }
} 