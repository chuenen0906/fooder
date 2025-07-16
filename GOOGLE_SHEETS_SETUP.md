# Google Sheets API 設置指南

## 概述
Fooder 專案的 Google Sheets 同步功能需要 Google Sheets API 認證才能更新線上工作表。本指南將協助您完成完整的設置流程。

## 步驟 1：啟用 Google Sheets API

### 1.1 前往 Google Cloud Console
1. 開啟瀏覽器，前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 登入您的 Google 帳戶
3. 選擇或創建一個專案

### 1.2 啟用 Google Sheets API
1. 在左側選單中點擊「API 和服務」→「程式庫」
2. 搜尋「Google Sheets API」
3. 點擊「Google Sheets API」
4. 點擊「啟用」按鈕

## 步驟 2：創建服務帳戶

### 2.1 創建服務帳戶
1. 在左側選單中點擊「API 和服務」→「憑證」
2. 點擊「建立憑證」→「服務帳戶」
3. 填寫服務帳戶資訊：
   - 服務帳戶名稱：`fooder-sheets-sync`
   - 服務帳戶 ID：自動生成
   - 描述：`Fooder 專案 Google Sheets 同步服務`
4. 點擊「建立並繼續」

### 2.2 授予權限
1. 在「授予此服務帳戶存取權」步驟中：
   - 角色：選擇「編輯者」
   - 點擊「繼續」
2. 在「完成」步驟中點擊「完成」

### 2.3 下載認證檔案
1. 在服務帳戶列表中，點擊剛創建的服務帳戶
2. 點擊「金鑰」標籤
3. 點擊「新增金鑰」→「建立新金鑰」
4. 選擇「JSON」格式
5. 點擊「建立」
6. 系統會自動下載 `credentials.json` 檔案

## 步驟 3：設置認證檔案

### 3.1 放置認證檔案
1. 將下載的 `credentials.json` 檔案放到專案根目錄
2. 確保檔案路徑：`/Users/zhuhongen/Desktop/fooder/credentials.json`

### 3.2 安裝必要套件
```bash
cd /Users/zhuhongen/Desktop/fooder
python3 -m pip install gspread google-auth
```

## 步驟 4：設置 Google Sheets

### 4.1 創建工作表
1. 前往 [Google Sheets](https://sheets.google.com/)
2. 點擊「建立空白試算表」
3. 將工作表命名為「台南餐廳資料庫」
4. 複製工作表 URL

### 4.2 分享權限
1. 在 Google Sheets 中點擊「分享」按鈕
2. 在「新增使用者和群組」中輸入服務帳戶的電子郵件地址
   - 格式：`fooder-sheets-sync@your-project-id.iam.gserviceaccount.com`
   - 您可以在 `credentials.json` 檔案中的 `client_email` 欄位找到
3. 權限設為「編輯者」
4. 點擊「完成」

## 步驟 5：測試連接

### 5.1 執行測試腳本
```bash
cd /Users/zhuhongen/Desktop/fooder
python3 scripts/test_google_sheets_connection.py
```

### 5.2 執行同步腳本
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py
```

## 故障排除

### 常見問題

#### 1. 認證檔案找不到
```
❌ 找不到認證檔案：credentials.json
```
**解決方案：**
- 確認 `credentials.json` 檔案已放在專案根目錄
- 檢查檔案名稱是否正確（區分大小寫）

#### 2. 權限不足
```
❌ 認證失敗：403 Forbidden
```
**解決方案：**
- 確認已將服務帳戶電子郵件加入 Google Sheets 的分享清單
- 確認服務帳戶具有「編輯者」權限

#### 3. API 未啟用
```
❌ 認證失敗：403 Forbidden - API not enabled
```
**解決方案：**
- 確認已在 Google Cloud Console 中啟用 Google Sheets API
- 確認專案選擇正確

#### 4. 套件未安裝
```
❌ 請先安裝必要套件：python3 -m pip install gspread google-auth
```
**解決方案：**
```bash
python3 -m pip install gspread google-auth
```

## 安全注意事項

### 1. 保護認證檔案
- `credentials.json` 包含敏感資訊，請勿上傳到 Git
- 已將 `credentials.json` 加入 `.gitignore`
- 定期更新服務帳戶金鑰

### 2. 權限最小化
- 服務帳戶只需要 Google Sheets 的編輯權限
- 不需要 Google Drive 的完整存取權限

### 3. 監控使用量
- 在 Google Cloud Console 中監控 API 使用量
- 設置使用量限制以避免意外費用

## 自動化腳本

### 快速設置腳本
```bash
# 創建認證檔案檢查腳本
python3 scripts/check_google_sheets_setup.py
```

### 同步腳本使用
```bash
# 同步所有餐廳資料
python3 scripts/sync_restaurants_to_sheets_v2.py

# 使用自訂認證檔案路徑
python3 scripts/sync_restaurants_to_sheets_v2.py --credentials /path/to/credentials.json
```

## 更新記錄

- **2025-01-XX**：初始版本，支援基本的 Google Sheets 同步功能
- 支援批次上傳，避免 API 限制
- 支援連接到現有工作表
- 支援本地備份功能

## 聯絡支援

如果在設置過程中遇到問題，請：
1. 檢查本指南的故障排除部分
2. 確認所有步驟都已正確完成
3. 查看 Google Cloud Console 的錯誤日誌 