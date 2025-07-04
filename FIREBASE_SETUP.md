# Firebase 設置指南

## 1. 創建 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點擊「新增專案」
3. 輸入專案名稱（例如：fooder-app）
4. 選擇是否啟用 Google Analytics（可選）
5. 點擊「建立專案」

## 2. 添加應用程式

### Android 平台
1. 在 Firebase Console 中，點擊 Android 圖標
2. 輸入 Android 套件名稱：`com.example.food_swipe_app`
3. 輸入應用程式暱稱（可選）
4. 點擊「註冊應用程式」
5. 下載 `google-services.json` 文件
6. 將文件放置在 `android/app/` 目錄下

### iOS 平台
1. 在 Firebase Console 中，點擊 iOS 圖標
2. 輸入 iOS Bundle ID：`com.example.foodSwipeApp`
3. 輸入應用程式暱稱（可選）
4. 點擊「註冊應用程式」
5. 下載 `GoogleService-Info.plist` 文件
6. 將文件放置在 `ios/Runner/` 目錄下

## 3. 啟用 Firebase Storage

1. 在 Firebase Console 中，點擊「Storage」
2. 點擊「開始使用」
3. 選擇安全規則（建議選擇「測試模式」用於開發）
4. 選擇儲存位置（建議選擇離用戶最近的區域）

## 4. 配置安全規則

在 Firebase Storage 中，更新安全規則：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 允許匿名用戶上傳餐廳照片
    match /restaurant_photos/{restaurantId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 5. 更新 Firebase 配置

### 更新 `lib/services/firebase_config.dart`

將以下值替換為您的 Firebase 專案實際值：

```dart
static const String _defaultProjectId = 'your-project-id'; // 您的 Firebase 專案 ID
apiKey: "your-api-key", // 您的 API Key
messagingSenderId: "your-sender-id", // 您的 Sender ID
appId: "your-app-id", // 您的 App ID
```

## 6. 安裝依賴項

運行以下命令安裝新的依賴項：

```bash
flutter pub get
```

## 7. 測試功能

1. 運行應用程式：`flutter run`
2. 在餐廳卡片上點擊相機圖標
3. 選擇拍照或從相簿選擇照片
4. 添加描述（可選）
5. 點擊上傳按鈕

## 注意事項

- 確保您的 Firebase 專案已啟用匿名認證
- 在生產環境中，建議配置更嚴格的安全規則
- 定期監控 Firebase Storage 的使用量和成本
- 考慮實施圖片壓縮和大小限制以節省儲存空間

## 故障排除

### 常見問題

1. **Firebase 初始化失敗**
   - 檢查 `google-services.json` 和 `GoogleService-Info.plist` 是否正確放置
   - 確認 Bundle ID 和 Package Name 是否正確

2. **權限被拒絕**
   - 檢查 Android 和 iOS 的權限配置
   - 確認用戶已授予相機和相簿權限

3. **上傳失敗**
   - 檢查網路連接
   - 確認 Firebase Storage 規則是否正確
   - 檢查 Firebase 專案配置

### 支援

如果遇到問題，請檢查：
- Firebase Console 的錯誤日誌
- Flutter 應用程式的控制台輸出
- 網路連接狀態 