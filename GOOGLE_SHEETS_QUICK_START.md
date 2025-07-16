# Google Sheets 同步功能快速開始指南

## 🚀 快速設置（5分鐘完成）

### 步驟 1：自動設置
```bash
cd /Users/zhuhongen/Desktop/fooder
python3 scripts/setup_google_sheets.py
```

這個腳本會：
- 自動安裝必要套件
- 引導您完成 Google Cloud Console 設置
- 協助您下載和設置認證檔案
- 測試連接是否正常

### 步驟 2：檢查設置
```bash
python3 scripts/check_google_sheets_setup.py
```

### 步驟 3：測試連接
```bash
python3 scripts/test_google_sheets_connection.py
```

## 📊 使用方式

### 方式 1：互動模式（推薦新手）
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --interactive
```

### 方式 2：命令列模式（推薦進階使用者）

#### 創建新工作表並同步
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --name "台南餐廳資料庫_2025"
```

#### 連接到現有工作表
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --url "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID"
```

#### 僅檢視本地資料
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --view-only
```

#### 使用自訂認證檔案
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --credentials "/path/to/your/credentials.json"
```

#### 調整批次大小
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --batch-size 100
```

## 🔧 常用命令

### 檢查設置狀態
```bash
python3 scripts/check_google_sheets_setup.py
```

### 測試 API 連接
```bash
python3 scripts/test_google_sheets_connection.py
```

### 同步所有餐廳資料
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py
```

### 檢視本地資料統計
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --view-only
```

## 📋 命令列參數說明

| 參數 | 簡寫 | 說明 | 預設值 |
|------|------|------|--------|
| `--credentials` | `-c` | 認證檔案路徑 | `credentials.json` |
| `--url` | `-u` | 現有 Google Sheets URL | 無 |
| `--name` | `-n` | 新工作表名稱 | `台南餐廳資料庫` |
| `--json-file` | `-j` | 餐廳 JSON 檔案路徑 | `tainan_markets.json` |
| `--batch-size` | `-b` | 批次上傳大小 | `50` |
| `--interactive` | `-i` | 使用互動模式 | `False` |
| `--view-only` | `-v` | 僅檢視本地資料 | `False` |

## 🎯 使用範例

### 範例 1：快速同步到新工作表
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --name "台南美食清單"
```

### 範例 2：同步到現有工作表
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py \
  --url "https://docs.google.com/spreadsheets/d/1ABC123XYZ/edit" \
  --batch-size 100
```

### 範例 3：檢視資料統計
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py --view-only
```

### 範例 4：使用自訂資料檔案
```bash
python3 scripts/sync_restaurants_to_sheets_v2.py \
  --json-file "data/new_restaurants.json" \
  --name "新餐廳清單"
```

## 🔍 故障排除

### 問題 1：找不到認證檔案
```
❌ 找不到認證檔案：credentials.json
```
**解決方案：**
```bash
python3 scripts/setup_google_sheets.py
```

### 問題 2：權限不足
```
❌ 認證失敗：403 Forbidden
```
**解決方案：**
1. 確認已將服務帳戶電子郵件加入 Google Sheets 分享清單
2. 確認服務帳戶具有「編輯者」權限

### 問題 3：套件未安裝
```
❌ 請先安裝必要套件
```
**解決方案：**
```bash
python3 -m pip install gspread google-auth
```

### 問題 4：API 配額不足
```
❌ 配額超出限制
```
**解決方案：**
1. 等待配額重置（通常是每分鐘/每小時）
2. 減少批次大小：`--batch-size 25`
3. 申請提高配額限制

## 📈 效能優化

### 批次大小建議
- **小資料集（<100家餐廳）**：`--batch-size 50`
- **中等資料集（100-500家餐廳）**：`--batch-size 25`
- **大資料集（>500家餐廳）**：`--batch-size 10`

### 網路優化
- 使用穩定的網路連接
- 避免同時執行多個同步任務
- 在網路較不繁忙時執行

## 🔒 安全注意事項

1. **保護認證檔案**：`credentials.json` 包含敏感資訊，請勿分享
2. **Git 安全**：認證檔案已加入 `.gitignore`，不會被意外上傳
3. **定期更新**：建議定期更新服務帳戶金鑰
4. **權限最小化**：服務帳戶只需要 Google Sheets 編輯權限

## 📞 支援

如果遇到問題：
1. 查看詳細設置指南：`GOOGLE_SHEETS_SETUP.md`
2. 執行診斷腳本：`python3 scripts/check_google_sheets_setup.py`
3. 檢查 Google Cloud Console 錯誤日誌

## 🎉 完成！

設置完成後，您就可以：
- 將餐廳資料同步到 Google Sheets
- 在線上查看和管理餐廳資料
- 與團隊成員分享資料
- 進行資料分析和統計 