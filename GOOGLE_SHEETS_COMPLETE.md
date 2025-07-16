# Google Sheets 同步功能完整指南

## 📋 已完成的工作

我們已經為 Fooder 專案建立了完整的 Google Sheets 同步功能，包含以下組件：

### 🔧 核心腳本
1. **`scripts/sync_restaurants_to_sheets_v2.py`** - 主要同步腳本
   - 支援互動模式和命令列模式
   - 支援連接到現有工作表或創建新工作表
   - 批次上傳功能，避免 API 限制
   - 完整的錯誤處理和進度顯示

2. **`scripts/setup_google_sheets.py`** - 互動式設置精靈
   - 自動安裝必要套件
   - 引導完成 Google Cloud Console 設置
   - 協助下載和設置認證檔案
   - 自動測試連接

3. **`scripts/test_google_sheets_connection.py`** - 連接測試工具
   - 驗證認證檔案格式
   - 測試 Google Sheets API 連接
   - 測試現有工作表連接
   - 詳細的錯誤診斷

4. **`scripts/check_google_sheets_setup.py`** - 設置狀態檢查
   - 檢查 Python 套件安裝狀態
   - 驗證認證檔案
   - 檢查資料檔案
   - 驗證 Git 安全性設置

### 📚 文件指南
1. **`GOOGLE_SHEETS_SETUP.md`** - 詳細設置指南
   - 完整的 Google Cloud Console 設置步驟
   - 服務帳戶創建和權限設置
   - 故障排除和常見問題解決

2. **`GOOGLE_SHEETS_QUICK_START.md`** - 快速開始指南
   - 5分鐘快速設置流程
   - 常用命令和參數說明
   - 使用範例和效能優化建議

3. **`GOOGLE_SHEETS_COMPLETE.md`** - 本文件，完整總結

### 🔒 安全設置
- **`.gitignore`** 已更新，包含 `credentials.json`
- 認證檔案不會被意外上傳到 Git
- 權限最小化原則，只授予必要權限

## 🚀 快速開始

### 方法 1：自動設置（推薦）
```bash
cd /Users/zhuhongen/Desktop/fooder
python3 scripts/setup_google_sheets.py
```

### 方法 2：手動設置
1. 安裝套件：`python3 -m pip install gspread google-auth`
2. 按照 `GOOGLE_SHEETS_SETUP.md` 設置 Google Cloud Console
3. 下載 `credentials.json` 到專案根目錄
4. 測試連接：`python3 scripts/test_google_sheets_connection.py`

## 📊 使用方式

### 基本同步
```bash
# 創建新工作表並同步
python3 scripts/sync_restaurants_to_sheets_v2.py

# 連接到現有工作表
python3 scripts/sync_restaurants_to_sheets_v2.py --url "YOUR_SHEET_URL"

# 互動模式
python3 scripts/sync_restaurants_to_sheets_v2.py --interactive
```

### 進階功能
```bash
# 檢視本地資料統計
python3 scripts/sync_restaurants_to_sheets_v2.py --view-only

# 使用自訂批次大小
python3 scripts/sync_restaurants_to_sheets_v2.py --batch-size 25

# 使用自訂資料檔案
python3 scripts/sync_restaurants_to_sheets_v2.py --json-file "data/custom_restaurants.json"
```

## 🔍 診斷和維護

### 檢查設置狀態
```bash
python3 scripts/check_google_sheets_setup.py
```

### 測試連接
```bash
python3 scripts/test_google_sheets_connection.py
```

### 常見問題解決
1. **認證檔案問題**：重新執行設置腳本
2. **權限問題**：確認服務帳戶已加入工作表分享清單
3. **API 配額問題**：減少批次大小或等待配額重置
4. **套件問題**：重新安裝必要套件

## 📈 效能和限制

### API 配額
- Google Sheets API 有每分鐘和每小時的請求限制
- 建議使用批次上傳（預設 50 筆/批次）
- 大資料集建議使用較小批次大小

### 網路優化
- 使用穩定網路連接
- 避免同時執行多個同步任務
- 在網路較不繁忙時執行

### 資料大小
- 單次同步建議不超過 1000 家餐廳
- 大資料集建議分批同步
- 定期清理舊資料以維持效能

## 🔒 安全最佳實踐

### 認證檔案管理
1. **保護認證檔案**：`credentials.json` 包含敏感資訊
2. **定期更新**：建議每 90 天更新服務帳戶金鑰
3. **備份安全**：將認證檔案備份到安全位置
4. **權限最小化**：只授予必要的 Google Sheets 編輯權限

### Git 安全
1. **`.gitignore`** 已設置，防止認證檔案上傳
2. **定期檢查**：確認敏感檔案未被意外提交
3. **歷史清理**：如有敏感檔案被提交，使用 BFG Repo-Cleaner 清理

## 📞 支援和維護

### 文件資源
- **詳細設置**：`GOOGLE_SHEETS_SETUP.md`
- **快速開始**：`GOOGLE_SHEETS_QUICK_START.md`
- **故障排除**：各腳本內建的錯誤診斷

### 監控和日誌
- 腳本提供詳細的進度顯示和錯誤訊息
- Google Cloud Console 提供 API 使用量監控
- 建議定期檢查 API 配額使用情況

### 更新和維護
- 定期更新 Python 套件：`pip install --upgrade gspread google-auth`
- 監控 Google Sheets API 的變更和更新
- 根據使用情況調整批次大小和同步策略

## 🎯 整合到工作流程

### 標準餐廳新增流程
1. 新增餐廳到 `tainan_markets.json`
2. 執行智慧抓圖片腳本：`python3 scripts/download_photos_smart.py --latest N`
3. 執行智慧 Firebase 上傳：`python3 scripts/upload_photos_smart.py --latest N`
4. 更新 Firebase 照片映射
5. **同步到 Google Sheets**：`python3 scripts/sync_restaurants_to_sheets_v2.py`

### 自動化建議
- 可以設置定期同步（例如每週一次）
- 考慮使用 GitHub Actions 自動化同步流程
- 建立資料變更通知機制

## 🎉 總結

Google Sheets 同步功能現在已經完全設置完成，提供：

✅ **完整的設置流程** - 從零開始的詳細指南  
✅ **多種使用方式** - 互動模式和命令列模式  
✅ **強大的診斷工具** - 連接測試和設置檢查  
✅ **安全保護** - 認證檔案保護和權限最小化  
✅ **效能優化** - 批次上傳和錯誤處理  
✅ **完整文件** - 詳細指南和快速開始手冊  

您現在可以輕鬆地將餐廳資料同步到 Google Sheets，實現線上資料管理和團隊協作！ 