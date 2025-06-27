import 'dart:convert';
import 'package:http/http.dart' as http;

class LogService {
  static const String _webhookUrl = 'https://script.google.com/macros/s/AKfycbzGFKUs71yb3IzuBDQm1MD5fBCetDEssnYcFBKsob1lzJHH1XdE0oKZAR_hdNF_qG-7/exec';

  /// 記錄用戶行為到 Google Sheets
  /// [userId] 用戶ID
  /// [apiType] API類型 (如: 'nearby_search', 'place_details', 'place_photos')
  static Future<void> logUserAction(String userId, String apiType) async {
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'api_type': apiType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ 成功記錄用戶行為: userId=$userId, apiType=$apiType');
      } else {
        print('❌ 記錄用戶行為失敗: statusCode=${response.statusCode}, response=${response.body}');
      }
    } catch (e) {
      print('❌ 記錄用戶行為時發生例外: $e');
    }
  }
} 