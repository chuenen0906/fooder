import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static const String _baseImagePath = 'assets/restaurants_collection';
  
  // 已知存在的圖片清單（可以根據實際情況更新）
  static final Set<String> _existingImages = {
    'assets/restaurants_collection/aming/aming_1.jpg',
    'assets/restaurants_collection/aming/aming_2.jpg',
    'assets/restaurants_collection/aming/aming_3.jpg',
    'assets/restaurants_collection/atang/atang_1.jpg',
    'assets/restaurants_collection/atang/atang_2.jpg',
    'assets/restaurants_collection/atang/atang_3.jpg',
    'assets/restaurants_collection/atang/atang_4.jpg',
    'assets/restaurants_collection/chous/chous_1.jpg',
    'assets/restaurants_collection/chous/chous_2.jpg',
    'assets/restaurants_collection/douhsiao/douhsiao_1.jpg',
    'assets/restaurants_collection/douhsiao/douhsiao_4.jpg',
    'assets/restaurants_collection/fusheng/fusheng_1.jpg',
    'assets/restaurants_collection/fusheng/fusheng_2.jpg',
    'assets/restaurants_collection/fusheng/fusheng_3.jpg',
    'assets/restaurants_collection/tongji/tongji_2.jpg',
    'assets/restaurants_collection/asong/asong_1.jpg',
    'assets/restaurants_collection/ahan/ahan_2.jpg',
    'assets/restaurants_collection/shengli/shengli_1.jpg',
    'assets/restaurants_collection/shengli/shengli_2.jpg',
    'assets/restaurants_collection/shengli/shengli_3.jpg',
    'assets/restaurants_collection/shengli/shengli_4.jpg',
    'assets/restaurants_collection/shengli/shengli_5.jpg',
    'assets/restaurants_collection/achuan/achuan_1.jpg',
    'assets/restaurants_collection/achuan/achuan_2.jpg',
    'assets/restaurants_collection/huaijiu/huaijiu_1.jpg',
    'assets/restaurants_collection/huaijiu/huaijiu_2.jpg',
    'assets/restaurants_collection/izuminami/izuminami_1.jpg',
    'assets/restaurants_collection/izuminami/izuminami_2.jpg',
    'assets/restaurants_collection/caijia/caijia_1.jpg',
    'assets/restaurants_collection/caijia/caijia_2.jpg',
    'assets/restaurants_collection/shijingjiu/shijingjiu_1.jpg',
    'assets/restaurants_collection/shijingjiu/shijingjiu_2.jpg',
    'assets/restaurants_collection/jinde/jinde_1.jpg',
    'assets/restaurants_collection/jinde/jinde_2.jpg',
    'assets/restaurants_collection/weijia/weijia_1.jpg',
    'assets/restaurants_collection/weijia/weijia_2.jpg',
    'assets/restaurants_collection/lanji/lanji_1.jpg',
    'assets/restaurants_collection/lanji/lanji_2.jpg',
    'assets/restaurants_collection/xiezhanggui/xiezhanggui_1.jpg',
    'assets/restaurants_collection/xiezhanggui/xiezhanggui_2.jpg',
    'assets/restaurants_collection/shanghaochi/shanghaochi_1.jpg',
    'assets/restaurants_collection/shanghaochi/shanghaochi_2.jpg',
    'assets/restaurants_collection/acun/acun_1.png',
    'assets/restaurants_collection/acun/acun_2.jpg',
    'assets/restaurants_collection/ajuan/ajuan_1.jpg',
    'assets/restaurants_collection/chengjiang/chengjiang_1.jpg',
    'assets/restaurants_collection/chengjiang/chengjiang_2.jpg',
    'assets/restaurants_collection/yifeng/yifeng_1.jpg',
    'assets/restaurants_collection/yifeng/yifeng_2.jpg',
    'assets/restaurants_collection/qiujia/qiujia_1.jpg',
    'assets/restaurants_collection/qiujia/qiujia_2.jpg',
    'assets/restaurants_collection/axing/axing_1.jpg',
    'assets/restaurants_collection/axing/axing_2.jpg',
    'assets/restaurants_collection/ajiang/ajiang_1.jpg',
    'assets/restaurants_collection/ajiang/ajiang_2.jpg',
    'assets/restaurants_collection/ajiang/ajiang_1.jpg',
    'assets/restaurants_collection/ajiang/ajiang_2.jpg',
    'assets/restaurants_collection/ajiang/ajiang_3.jpg',
    'assets/restaurants_collection/ajiang/ajiang_4.jpg',
    'assets/restaurants_collection/ajiang/ajiang_5.jpg',
  };
  
  /// 獲取餐廳的所有圖片
  static List<String> getRestaurantImages(String restaurantId) {
    final List<String> images = [];
    final String restaurantPath = '$_baseImagePath/$restaurantId';
    
    // 檢查圖片是否存在
    for (int i = 1; i <= 10; i++) { // 假設最多10張圖片
      final String imagePath = '$restaurantPath/${restaurantId}_$i.jpg';
      if (_imageExists(imagePath)) {
        images.add(imagePath);
      }
    }
    
    return images;
  }
  
  /// 檢查圖片是否存在
  static bool _imageExists(String imagePath) {
    // 使用預定義的清單來檢查圖片是否存在
    return _existingImages.contains(imagePath);
  }
  
  /// 獲取餐廳的主圖片（第一張）
  static String getMainImage(String restaurantId) {
    final images = getRestaurantImages(restaurantId);
    if (images.isNotEmpty) {
      return images.first;
    }
    return 'assets/loading_pig.png'; // 預設圖片
  }
  
  /// 獲取餐廳的圖片數量
  static int getImageCount(String restaurantId) {
    return getRestaurantImages(restaurantId).length;
  }
  
  /// 檢查餐廳是否有圖片
  static bool hasImages(String restaurantId) {
    return getImageCount(restaurantId) > 0;
  }
  
  /// 驗證圖片路徑列表，移除不存在的圖片
  static List<String> validateImagePaths(List<String> imagePaths) {
    return imagePaths.where((path) => _imageExists(path)).toList();
  }
  
  /// 添加新的圖片到已知清單中
  static void addImageToKnownList(String imagePath) {
    _existingImages.add(imagePath);
  }
} 