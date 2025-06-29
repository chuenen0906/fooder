import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PlaceDetailsCacheService {
  static Database? _database;
  static const String _databaseName = 'places.db';
  static const String _tableName = 'place_details_cache';
  static const int _databaseVersion = 1;

  /// 獲取資料庫實例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化資料庫
  static Future<Database> _initDatabase() async {
    // 獲取應用程式文件目錄
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // 建立/開啟資料庫
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 建立資料表
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        place_id TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');
    print('🗄️ 建立 Place Details 快取資料表');
  }

  /// 資料庫升級
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // 未來版本升級邏輯
      print('🔄 升級 Place Details 快取資料庫: v$oldVersion -> v$newVersion');
    }
  }

  /// 儲存 Place Details 到快取
  /// [placeId] Google Places API 的 place_id
  /// [jsonData] Place Details 的 JSON 字串
  static Future<void> savePlaceDetails(String placeId, String jsonData) async {
    try {
      final db = await database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        _tableName,
        {
          'place_id': placeId,
          'json_data': jsonData,
          'last_updated': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // 如果已存在則覆蓋
      );
      
      print('💾 快取 Place Details: $placeId');
    } catch (e) {
      print('❌ 儲存 Place Details 快取失敗: $e');
    }
  }

  /// 從快取獲取 Place Details
  /// [placeId] Google Places API 的 place_id
  /// [maxAgeInDays] 快取最大有效天數，預設 7 天
  /// 回傳 null 如果快取不存在或已過期
  static Future<String?> getPlaceDetails(String placeId, {int maxAgeInDays = 7}) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'place_id = ?',
        whereArgs: [placeId],
      );

      if (result.isEmpty) {
        print('❌ 快取未找到: $placeId');
        return null;
      }

      final row = result.first;
      final lastUpdated = row['last_updated'] as int;
      final jsonData = row['json_data'] as String;
      
      // 檢查快取是否過期
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
      final now = DateTime.now();
      final ageInDays = now.difference(cacheTime).inDays;
      
      if (ageInDays > maxAgeInDays) {
        print('⏰ 快取已過期: $placeId (${ageInDays}天前)');
        return null;
      }

      print('✅ 從快取獲取: $placeId (${ageInDays}天前)');
      return jsonData;
    } catch (e) {
      print('❌ 獲取 Place Details 快取失敗: $e');
      return null;
    }
  }

  /// 清除過期的快取資料
  /// [maxAgeInDays] 最大有效天數，預設 7 天
  static Future<void> clearOldCache({int maxAgeInDays = 7}) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now().subtract(Duration(days: maxAgeInDays));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
      
      final deletedCount = await db.delete(
        _tableName,
        where: 'last_updated < ?',
        whereArgs: [cutoffTimestamp],
      );
      
      print('🧹 清除 $deletedCount 筆過期快取資料 (超過 ${maxAgeInDays} 天)');
    } catch (e) {
      print('❌ 清除過期快取失敗: $e');
    }
  }

  /// 清除所有快取資料
  static Future<void> clearAllCache() async {
    try {
      final db = await database;
      final deletedCount = await db.delete(_tableName);
      print('🗑️ 清除所有快取資料: $deletedCount 筆');
    } catch (e) {
      print('❌ 清除所有快取失敗: $e');
    }
  }

  /// 獲取快取統計資訊
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final count = result.first['count'] as int;
      
      final oldestResult = await db.rawQuery('''
        SELECT MIN(last_updated) as oldest FROM $_tableName
      ''');
      final oldestTimestamp = oldestResult.first['oldest'] as int?;
      
      return {
        'total_entries': count,
        'oldest_entry': oldestTimestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(oldestTimestamp)
          : null,
      };
    } catch (e) {
      print('❌ 獲取快取統計失敗: $e');
      return {'total_entries': 0, 'oldest_entry': null};
    }
  }

  /// 關閉資料庫連接
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 關閉 Place Details 快取資料庫');
    }
  }
}

// 使用範例
class PlaceDetailsCacheExample {
  /// 範例：獲取 Place Details（優先使用快取）
  static Future<String?> getPlaceDetailsWithCache(String placeId) async {
    // 1. 先檢查快取
    String? cachedData = await PlaceDetailsCacheService.getPlaceDetails(placeId);
    if (cachedData != null) {
      return cachedData;
    }

    // 2. 快取沒有或已過期，呼叫 API
    print('🌐 呼叫 Google Places API: $placeId');
    // String apiResult = await callGooglePlacesAPI(placeId);
    
    // 3. 儲存到快取
    // await PlaceDetailsCacheService.savePlaceDetails(placeId, apiResult);
    
    // return apiResult;
    return null; // 暫時回傳 null
  }

  /// 範例：定期清理過期快取
  static Future<void> cleanupCache() async {
    await PlaceDetailsCacheService.clearOldCache(maxAgeInDays: 7);
    
    // 顯示統計資訊
    final stats = await PlaceDetailsCacheService.getCacheStats();
    print('📊 快取統計: ${stats['total_entries']} 筆資料');
  }
} 