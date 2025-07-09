import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/firebase_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  
  const PhotoUploadScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedImage;
  String? _description;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 從相機拍照
  Future<void> _takePhoto() async {
    try {
      final image = await _firebaseService.takePhoto();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (e.toString().contains('請到設定中手動開啟')) {
        _showPermissionDialog('相機');
      } else {
        _showErrorSnackBar('拍照失敗: $e');
      }
    }
  }

  // 從相簿選擇照片
  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _firebaseService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (e.toString().contains('請到設定中手動開啟')) {
        _showPermissionDialog('相簿');
      } else {
        _showErrorSnackBar('選擇照片失敗: $e');
      }
    }
  }

  // 顯示照片選擇選項
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('從相簿選擇'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 上傳照片
  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('請先選擇照片');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final restaurantId = widget.restaurant['place_id'] ?? 'unknown';
      final restaurantName = widget.restaurant['name'] ?? '未知餐廳';
      
      final downloadUrl = await _firebaseService.uploadRestaurantPhoto(
        imageFile: _selectedImage!,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        description: _descriptionController.text.trim(),
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      _showSuccessSnackBar('照片上傳成功！');
      
      // 延遲一下再返回，讓用戶看到成功訊息
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('上傳失敗: $e');
    }
  }

  // 顯示錯誤訊息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 顯示成功訊息
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 顯示權限設定對話框
  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('需要${permissionType}權限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('要使用${permissionType}功能，請允許 Fooder 存取您的${permissionType}。'),
              const SizedBox(height: 16),
              const Text('請按照以下步驟操作：'),
              const SizedBox(height: 8),
              const Text('1. 點擊「前往設定」'),
              const Text('2. 找到「Fooder」應用程式'),
              Text('3. 開啟${permissionType}權限'),
              const Text('4. 返回應用程式重試'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('前往設定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上傳餐廳照片'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 餐廳資訊卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant['name'] ?? '未知餐廳',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.restaurant['vicinity'] != null)
                      Text(
                        widget.restaurant['vicinity'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 照片選擇區域
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選擇照片',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 照片預覽
                    if (_selectedImage != null) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // 選擇照片按鈕
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _showImageSourceDialog,
                            icon: const Icon(Icons.add_a_photo),
                            label: Text(_selectedImage == null ? '選擇照片' : '重新選擇'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _isUploading ? null : () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: '刪除照片',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 描述輸入區域
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '照片描述（選填）',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        hintText: '描述這張照片的內容，例如：招牌菜、店內環境等',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 上傳進度條
            if (_isUploading) ...[
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '上傳中... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // 上傳按鈕
            ElevatedButton(
              onPressed: (_selectedImage == null || _isUploading) ? null : _uploadPhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('上傳中...'),
                      ],
                    )
                  : const Text(
                      '上傳照片',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 