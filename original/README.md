# Fooder - 美食滑卡選擇器

一個基於 Flutter 開發的美食選擇應用程式，幫助你在附近找到想吃的餐廳。

## 功能特色

### 🍽️ 核心功能
- **滑卡選擇**：左右滑動卡片來選擇喜歡的餐廳
- **多輪篩選**：通過多輪滑動逐步縮小選擇範圍
- **智能推薦**：基於你的滑動偏好推薦最終餐廳

### 📍 位置服務
- **GPS 定位**：自動獲取你的當前位置
- **可調範圍**：1-10 公里範圍內搜尋餐廳
- **營業狀態**：可選擇只顯示營業中的餐廳

### 🎨 滑動提示動畫
- **即時反饋**：滑動時顯示「沒 fu 啦」（左滑）或「哇想吃！」（右滑）
- **流暢動畫**：包含透明度、位置和縮放動畫效果
- **視覺提示**：不同顏色和圖標區分滑動方向

### 📸 豐富資訊
- **多張照片**：每家餐廳顯示多張實景照片
- **詳細資訊**：包含評分、距離、類型等資訊
- **一鍵導航**：直接開啟 Google Maps 導航

### ⭐ 個人化功能
- **收藏功能**：收藏喜歡的餐廳
- **歷史記錄**：保存你的選擇偏好

## 技術特色

- **Flutter 3.32.4**：跨平台開發框架
- **Google Places API**：豐富的餐廳資料庫
- **Geolocator**：精確的位置服務
- **flutter_card_swiper**：流暢的滑卡體驗
- **動畫系統**：自定義滑動提示動畫

## 安裝與運行

1. 確保已安裝 Flutter SDK
2. 克隆專案：`git clone [repository-url]`
3. 安裝依賴：`flutter pub get`
4. 運行應用：`flutter run`

## 使用說明

1. **開始搜尋**：應用會自動獲取你的位置並搜尋附近餐廳
2. **調整範圍**：使用滑桿調整搜尋範圍（1-10公里）
3. **滑動選擇**：
   - 左滑：不喜歡這家餐廳
   - 右滑：喜歡這家餐廳
4. **多輪篩選**：系統會根據你的選擇進入下一輪
5. **查看結果**：最終推薦最符合你偏好的餐廳

## 滑動提示動畫

新增的滑動提示動畫功能提供即時的視覺反饋：

- **左滑**：顯示紅色「沒 fu 啦」提示，帶有 X 圖標
- **右滑**：顯示綠色「哇想吃！」提示，帶有心形圖標
- **動畫效果**：包含淡入、位移和縮放動畫
- **智能觸發**：根據滑動距離和方向智能顯示

## 授權

本專案僅供學習和研究使用。
