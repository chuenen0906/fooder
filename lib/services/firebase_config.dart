import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String _defaultProjectId = 'fooder-app-12345'; // 請替換為您的 Firebase 專案 ID
  
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web 平台配置
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "your-api-key", // 請替換為您的 API Key
            authDomain: "$_defaultProjectId.firebaseapp.com",
            projectId: _defaultProjectId,
            storageBucket: "$_defaultProjectId.appspot.com",
            messagingSenderId: "123456789", // 請替換為您的 Sender ID
            appId: "your-app-id", // 請替換為您的 App ID
          ),
        );
      } else {
        // 移動平台配置（Android/iOS）
        // 這些平台會自動從 google-services.json 和 GoogleService-Info.plist 讀取配置
        await Firebase.initializeApp();
      }
      
      print('✅ Firebase 初始化成功');
    } catch (e) {
      print('❌ Firebase 初始化失敗: $e');
      rethrow;
    }
  }
} 