import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // 初始化 Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // 獲取當前用戶 ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 檢查用戶是否已登入
  bool get isUserLoggedIn => _auth.currentUser != null;

  // 匿名登入
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      print('✅ 匿名登入成功');
    } catch (e) {
      print('❌ 匿名登入失敗: $e');
      rethrow;
    }
  }

  // 請求相機權限
  Future<bool> requestCameraPermission() async {
    try {
      // 先檢查當前狀態
      final currentStatus = await Permission.camera.status;
      print('📷 當前相機權限狀態: $currentStatus');
      
      if (currentStatus.isGranted) {
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        print('⚠️ 相機權限被永久拒絕，需要手動開啟');
        throw Exception('相機權限被拒絕，請到設定中手動開啟');
      }
      
      // 請求權限
      final status = await Permission.camera.request();
      print('📷 權限請求結果: $status');
      
      return status.isGranted;
    } catch (e) {
      print('❌ 請求相機權限失敗: $e');
      rethrow;
    }
  }

  // 請求相簿權限
  Future<bool> requestGalleryPermission() async {
    try {
      // 先檢查當前狀態
      final currentStatus = await Permission.photos.status;
      print('📸 當前相簿權限狀態: $currentStatus');
      
      if (currentStatus.isGranted || currentStatus.isLimited) {
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        print('⚠️ 相簿權限被永久拒絕，需要手動開啟');
        throw Exception('相簿權限被拒絕，請到設定中手動開啟');
      }
      
      // 請求權限
      final status = await Permission.photos.request();
      print('📸 權限請求結果: $status');
      
      return status.isGranted || status.isLimited;
    } catch (e) {
      print('❌ 請求相簿權限失敗: $e');
      rethrow;
    }
  }

  // 從相機拍照
  Future<File?> takePhoto() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('需要相機權限才能拍照');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      print('❌ 拍照失敗: $e');
      rethrow;
    }
  }

  // 從相簿選擇照片
  Future<File?> pickImageFromGallery() async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        throw Exception('需要相簿權限才能選擇照片');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      print('❌ 選擇照片失敗: $e');
      rethrow;
    }
  }

  // 上傳照片到 Firebase Storage
  Future<String> uploadRestaurantPhoto({
    required File imageFile,
    required String restaurantId,
    required String restaurantName,
    String? description,
  }) async {
    try {
      // 確保用戶已登入
      if (!isUserLoggedIn) {
        await signInAnonymously();
      }

      final userId = currentUserId;
      if (userId == null) {
        throw Exception('無法獲取用戶 ID');
      }

      // 生成檔案名稱
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${restaurantId}_${timestamp}.jpg';
      
      // 設定儲存路徑
      final storagePath = 'restaurant_photos/$restaurantId/$fileName';
      final storageRef = _storage.ref().child(storagePath);

      // 上傳檔案
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          customMetadata: {
            'restaurantId': restaurantId,
            'restaurantName': restaurantName,
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'description': description ?? '',
          },
        ),
      );

      // 監聽上傳進度
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 上傳進度: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 等待上傳完成
      final snapshot = await uploadTask;
      
      // 獲取下載 URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ 照片上傳成功: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 照片上傳失敗: $e');
      rethrow;
    }
  }

  // 獲取餐廳的所有照片
  Future<List<String>> getRestaurantPhotos(String restaurantId) async {
    try {
      final storageRef = _storage.ref().child('restaurant_photos/$restaurantId');
      final result = await storageRef.listAll();
      
      List<String> photoUrls = [];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        photoUrls.add(url);
      }
      
      return photoUrls;
    } catch (e) {
      print('❌ 獲取餐廳照片失敗: $e');
      return [];
    }
  }

  // 刪除照片
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      print('✅ 照片刪除成功');
    } catch (e) {
      print('❌ 照片刪除失敗: $e');
      rethrow;
    }
  }

  // 獲取上傳進度
  Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
} 