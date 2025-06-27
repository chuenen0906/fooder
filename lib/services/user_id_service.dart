import 'package:shared_preferences/shared_preferences.dart';

class UserIdService {
  static const String _userIdKey = 'user_id';
  static const String _isFirstLaunchKey = 'is_first_launch';

  /// 獲取用戶 ID，如果沒有則返回 null
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// 設定用戶 ID
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// 檢查是否為首次啟動
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  /// 標記已非首次啟動
  static Future<void> markAsNotFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  /// 清除用戶 ID（用於測試或重置）
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
} 