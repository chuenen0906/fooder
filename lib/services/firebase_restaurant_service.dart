import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseRestaurantService {
  static final FirebaseRestaurantService _instance = FirebaseRestaurantService._internal();
  factory FirebaseRestaurantService() => _instance;
  FirebaseRestaurantService._internal();

  // Firebase 上傳的餐廳照片映射 - 自動生成於 2025-07-09
  static const Map<String, List<String>> _restaurantPhotoUrls = {
    "金得春捲": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2.jpg"
    ],
    "石精臼蚵仔煎": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%9F%B3%E7%B2%BE%E8%87%BC%E8%9A%B5%E4%BB%94%E7%85%8E/%E7%9F%B3%E7%B2%BE%E8%87%BC%E8%9A%B5%E4%BB%94%E7%85%8E.jpg"
    ],
    "富盛號碗粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%AF%8C%E7%9B%9B%E8%99%9F%E7%A2%97%E7%B2%BF/%E5%AF%8C%E7%9B%9B%E8%99%9F%E7%A2%97%E7%B2%BF.jpg"
    ],
    "阿堂鹹粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A0%82%E9%B9%B9%E7%B2%A5/%E9%98%BF%E5%A0%82%E9%B9%B9%E7%B2%A5.jpg"
    ],
    "邱家小卷米粉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89.jpg"
    ],
    "炸雞洋行": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C.jpg"
    ],
    "阿伯炭烤黑輪甜不辣": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E4%BC%AF%E7%82%AD%E7%83%A4%E9%BB%91%E8%BC%AA%E7%94%9C%E4%B8%8D%E8%BE%A3/%E9%98%BF%E4%BC%AF%E7%82%AD%E7%83%A4%E9%BB%91%E8%BC%AA%E7%94%9C%E4%B8%8D%E8%BE%A3.jpg"
    ],
    "阿明豬心": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83.jpg"
    ],
    "阿松割包": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85.jpg"
    ],
    "修安扁擔豆花": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1.jpg"
    ],
    "蜷尾家甘味處": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95.png"
    ],
    "江水號": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B1%9F%E6%B0%B4%E8%99%9F/%E6%B1%9F%E6%B0%B4%E8%99%9F.jpg"
    ],
    "鴨米脆皮薯條": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%B4%A8%E7%B1%B3%E8%84%86%E7%9A%AE%E8%96%AF%E6%A2%9D/%E9%B4%A8%E7%B1%B3%E8%84%86%E7%9A%AE%E8%96%AF%E6%A2%9D.jpg"
    ],
    "林家白糖粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9E%97%E5%AE%B6%E7%99%BD%E7%B3%96%E7%B2%BF/%E6%9E%97%E5%AE%B6%E7%99%BD%E7%B3%96%E7%B2%BF.jpg"
    ],
    "阿婆魯麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5.jpg"
    ],
    "勝利早點": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E.jpg"
    ],
    "廖記老牌鱔魚麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%BB%96%E8%A8%98%E8%80%81%E7%89%8C%E9%B1%94%E9%AD%9A%E9%BA%B5/%E5%BB%96%E8%A8%98%E8%80%81%E7%89%8C%E9%B1%94%E9%AD%9A%E9%BA%B5.jpg"
    ],
    "圓環牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF.JPG"
    ],
    "阿村牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "文章牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%96%87%E7%AB%A0%E7%89%9B%E8%82%89%E6%B9%AF/%E6%96%87%E7%AB%A0%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "永樂牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "南光大飯店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8D%97%E5%85%89%E5%A4%A7%E9%A3%AF%E5%BA%97/%E5%8D%97%E5%85%89%E5%A4%A7%E9%A3%AF%E5%BA%97.jpg"
    ],
    "一味品碗粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF.jpg"
    ],
    "阿裕牛肉涮涮鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E8%A3%95%E7%89%9B%E8%82%89%E6%B6%AE%E6%B6%AE%E9%8D%8B/%E9%98%BF%E8%A3%95%E7%89%9B%E8%82%89%E6%B6%AE%E6%B6%AE%E9%8D%8B.jpg"
    ],
    "牛苑火鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%89%9B%E8%8B%91%E7%81%AB%E9%8D%8B/%E7%89%9B%E8%8B%91%E7%81%AB%E9%8D%8B.jpg"
    ],
    "六月三十冰淇淋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%85%AD%E6%9C%88%E4%B8%89%E5%8D%81%E5%86%B0%E6%B7%87%E6%B7%8B/%E5%85%AD%E6%9C%88%E4%B8%89%E5%8D%81%E5%86%B0%E6%B7%87%E6%B7%8B.jpg"
    ],
    "林家番薯椪": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9E%97%E5%AE%B6%E7%95%AA%E8%96%AF%E6%A4%AA/%E6%9E%97%E5%AE%B6%E7%95%AA%E8%96%AF%E6%A4%AA.jpg"
    ],
    "蔡家蚵嗲": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%94%A1%E5%AE%B6%E8%9A%B5%E5%97%B2/%E8%94%A1%E5%AE%B6%E8%9A%B5%E5%97%B2.jpg"
    ],
    "籃記東山鴨頭": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%B1%83%E8%A8%98%E6%9D%B1%E5%B1%B1%E9%B4%A8%E9%A0%AD/%E7%B1%83%E8%A8%98%E6%9D%B1%E5%B1%B1%E9%B4%A8%E9%A0%AD.jpg"
    ],
    "無名鴨肉麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%84%A1%E5%90%8D%E9%B4%A8%E8%82%89%E9%BA%B5/%E7%84%A1%E5%90%8D%E9%B4%A8%E8%82%89%E9%BA%B5.jpg"
    ],
    "開元路無名虱目魚": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%96%8B%E5%85%83%E8%B7%AF%E7%84%A1%E5%90%8D%E8%99%B1%E7%9B%AE%E9%AD%9A/%E9%96%8B%E5%85%83%E8%B7%AF%E7%84%A1%E5%90%8D%E8%99%B1%E7%9B%AE%E9%AD%9A.jpg"
    ],
    "赤崁棺材板": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%B5%A4%E5%B4%81%E6%A3%BA%E6%9D%90%E6%9D%BF/%E8%B5%A4%E5%B4%81%E6%A3%BA%E6%9D%90%E6%9D%BF.jpg"
    ],
    "寶來香餅舖": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%AF%B6%E4%BE%86%E9%A6%99%E9%A4%85%E8%88%96/%E5%AF%B6%E4%BE%86%E9%A6%99%E9%A4%85%E8%88%96.jpg"
    ],
    "太陽牌紅豆牛奶霜": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%A4%AA%E9%99%BD%E7%89%8C%E7%B4%85%E8%B1%86%E7%89%9B%E5%A5%B6%E9%9C%9C/%E5%A4%AA%E9%99%BD%E7%89%8C%E7%B4%85%E8%B1%86%E7%89%9B%E5%A5%B6%E9%9C%9C.jpeg"
    ],
    "雙全紅茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%9B%99%E5%85%A8%E7%B4%85%E8%8C%B6/%E9%9B%99%E5%85%A8%E7%B4%85%E8%8C%B6.jpg"
    ],
    "福泰飯桌": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%A6%8F%E6%B3%B0%E9%A3%AF%E6%A1%8C/%E7%A6%8F%E6%B3%B0%E9%A3%AF%E6%A1%8C.JPG"
    ],
    "新加坡冰城": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%96%B0%E5%8A%A0%E5%9D%A1%E5%86%B0%E5%9F%8E/%E6%96%B0%E5%8A%A0%E5%9D%A1%E5%86%B0%E5%9F%8E.jpg"
    ],
    "阿川粉圓冰": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%B7%9D%E7%B2%89%E5%9C%93%E5%86%B0/%E9%98%BF%E5%B7%9D%E7%B2%89%E5%9C%93%E5%86%B0.jpg"
    ],
    "懷舊小棧杏仁豆腐冰": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%87%B7%E8%88%8A%E5%B0%8F%E6%A3%A7%E6%9D%8F%E4%BB%81%E8%B1%86%E8%85%90%E5%86%B0/%E6%87%B7%E8%88%8A%E5%B0%8F%E6%A3%A7%E6%9D%8F%E4%BB%81%E8%B1%86%E8%85%90%E5%86%B0.jpg"
    ],
    "街貓咖啡店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%A1%97%E8%B2%93%E5%92%96%E5%95%A1%E5%BA%97/%E8%A1%97%E8%B2%93%E5%92%96%E5%95%A1%E5%BA%97.jpg"
    ],
    "澄峰冰舖": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%BE%84%E5%B3%B0%E5%86%B0%E8%88%96/%E6%BE%84%E5%B3%B0%E5%86%B0%E8%88%96.jpg"
    ],
    "醇涎坊鍋燒意麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%86%87%E6%B6%8E%E5%9D%8A%E9%8D%8B%E7%87%92%E6%84%8F%E9%BA%B5/%E9%86%87%E6%B6%8E%E5%9D%8A%E9%8D%8B%E7%87%92%E6%84%8F%E9%BA%B5.jpg"
    ],
    "阿鳳浮水虱目魚羹": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E9%B3%B3%E6%B5%AE%E6%B0%B4%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%BE%B9/%E9%98%BF%E9%B3%B3%E6%B5%AE%E6%B0%B4%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%BE%B9.JPG"
    ],
    "Kokoni水果茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Kokoni%E6%B0%B4%E6%9E%9C%E8%8C%B6/Kokoni%E6%B0%B4%E6%9E%9C%E8%8C%B6.jpg"
    ],
    "石頭鄉燜烤香味玉米": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%9F%B3%E9%A0%AD%E9%84%89%E7%87%9C%E7%83%A4%E9%A6%99%E5%91%B3%E7%8E%89%E7%B1%B3/%E7%9F%B3%E9%A0%AD%E9%84%89%E7%87%9C%E7%83%A4%E9%A6%99%E5%91%B3%E7%8E%89%E7%B1%B3.JPG"
    ],
    "包成羊肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8C%85%E6%88%90%E7%BE%8A%E8%82%89/%E5%8C%85%E6%88%90%E7%BE%8A%E8%82%89.jpg"
    ],
    "小西門青草茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E8%A5%BF%E9%96%80%E9%9D%92%E8%8D%89%E8%8C%B6/%E5%B0%8F%E8%A5%BF%E9%96%80%E9%9D%92%E8%8D%89%E8%8C%B6.jpg"
    ],
    "無名脆肉攤": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%84%A1%E5%90%8D%E8%84%86%E8%82%89%E6%94%A4/%E7%84%A1%E5%90%8D%E8%84%86%E8%82%89%E6%94%A4.jpg"
    ],
    "小公園擔仔麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E5%85%AC%E5%9C%92%E6%93%94%E4%BB%94%E9%BA%B5/%E5%B0%8F%E5%85%AC%E5%9C%92%E6%93%94%E4%BB%94%E9%BA%B5.jpg"
    ],
    "阿龍香腸熟肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E9%BE%8D%E9%A6%99%E8%85%B8%E7%86%9F%E8%82%89/%E9%98%BF%E9%BE%8D%E9%A6%99%E8%85%B8%E7%86%9F%E8%82%89.jpg"
    ],
    "民族鍋燒老店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%91%E6%97%8F%E9%8D%8B%E7%87%92%E8%80%81%E5%BA%97/%E6%B0%91%E6%97%8F%E9%8D%8B%E7%87%92%E8%80%81%E5%BA%97.jpg"
    ],
    "海龍肉粽": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B5%B7%E9%BE%8D%E8%82%89%E7%B2%BD/%E6%B5%B7%E9%BE%8D%E8%82%89%E7%B2%BD.jpg"
    ],
    "林聰明沙鍋魚頭": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9E%97%E8%81%B0%E6%98%8E%E6%B2%99%E9%8D%8B%E9%AD%9A%E9%A0%AD/%E6%9E%97%E8%81%B0%E6%98%8E%E6%B2%99%E9%8D%8B%E9%AD%9A%E9%A0%AD.jpg"
    ],
    "春囍打邊爐": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%98%A5%E5%9B%8D%E6%89%93%E9%82%8A%E7%88%90/%E6%98%A5%E5%9B%8D%E6%89%93%E9%82%8A%E7%88%90.jpg"
    ],
    "老張串門": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%80%81%E5%BC%B5%E4%B8%B2%E9%96%80/%E8%80%81%E5%BC%B5%E4%B8%B2%E9%96%80.jpg"
    ],
    "東悅坊港式飲茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9D%B1%E6%82%85%E5%9D%8A%E6%B8%AF%E5%BC%8F%E9%A3%B2%E8%8C%B6/%E6%9D%B1%E6%82%85%E5%9D%8A%E6%B8%AF%E5%BC%8F%E9%A3%B2%E8%8C%B6.jpg"
    ],
    "水瀨閣水上木屋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B4%E7%80%A8%E9%96%A3%E6%B0%B4%E4%B8%8A%E6%9C%A8%E5%B1%8B/%E6%B0%B4%E7%80%A8%E9%96%A3%E6%B0%B4%E4%B8%8A%E6%9C%A8%E5%B1%8B.jpg"
    ],
    "IMOMENT CAFE享當下": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/IMOMENT%20CAFE%E4%BA%AB%E7%95%B6%E4%B8%8B/IMOMENT%20CAFE%E4%BA%AB%E7%95%B6%E4%B8%8B.jpg"
    ],
    "LA時尚川菜": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/LA%E6%99%82%E5%B0%9A%E5%B7%9D%E8%8F%9C/LA%E6%99%82%E5%B0%9A%E5%B7%9D%E8%8F%9C.jpg"
    ],
    "箱舟燒肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%AE%B1%E8%88%9F%E7%87%92%E8%82%89/%E7%AE%B1%E8%88%9F%E7%87%92%E8%82%89.jpg"
    ],
    "小花雞蛋糕": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E8%8A%B1%E9%9B%9E%E8%9B%8B%E7%B3%95/%E5%B0%8F%E8%8A%B1%E9%9B%9E%E8%9B%8B%E7%B3%95.jpg"
    ],
    "冰鄉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%86%B0%E9%84%89/%E5%86%B0%E9%84%89.jpg"
    ],
    "王氏魚皮店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%8E%8B%E6%B0%8F%E9%AD%9A%E7%9A%AE%E5%BA%97/%E7%8E%8B%E6%B0%8F%E9%AD%9A%E7%9A%AE%E5%BA%97.jpg"
    ],
    "阿和肉燥飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%92%8C%E8%82%89%E7%87%A5%E9%A3%AF/%E9%98%BF%E5%92%8C%E8%82%89%E7%87%A5%E9%A3%AF.jpg"
    ],
    "松大沙茶爐": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9D%BE%E5%A4%A7%E6%B2%99%E8%8C%B6%E7%88%90/%E6%9D%BE%E5%A4%A7%E6%B2%99%E8%8C%B6%E7%88%90.jpg"
    ],
    "傳家鹹粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%82%B3%E5%AE%B6%E9%B9%B9%E7%B2%A5/%E5%82%B3%E5%AE%B6%E9%B9%B9%E7%B2%A5.jpg"
    ],
    "進福炒鱔魚": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%80%B2%E7%A6%8F%E7%82%92%E9%B1%94%E9%AD%9A/%E9%80%B2%E7%A6%8F%E7%82%92%E9%B1%94%E9%AD%9A.jpg"
    ],
    "小貓巴克里": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E8%B2%93%E5%B7%B4%E5%85%8B%E9%87%8C/%E5%B0%8F%E8%B2%93%E5%B7%B4%E5%85%8B%E9%87%8C.jpg"
    ],
    "魚夫手繪美食地圖推薦店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%AD%9A%E5%A4%AB%E6%89%8B%E7%B9%AA%E7%BE%8E%E9%A3%9F%E5%9C%B0%E5%9C%96%E6%8E%A8%E8%96%A6%E5%BA%97/%E9%AD%9A%E5%A4%AB%E6%89%8B%E7%B9%AA%E7%BE%8E%E9%A3%9F%E5%9C%B0%E5%9C%96%E6%8E%A8%E8%96%A6%E5%BA%97.jpg"
    ],
    "Principe 原則": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Principe%20%E5%8E%9F%E5%89%87/Principe%20%E5%8E%9F%E5%89%87.jpg"
    ],
    "㕩肉舖": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E3%95%A9%E8%82%89%E8%88%96/%E3%95%A9%E8%82%89%E8%88%96.jpg"
    ],
    "有你真好 湘菜沙龍": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9C%89%E4%BD%A0%E7%9C%9F%E5%A5%BD%20%E6%B9%98%E8%8F%9C%E6%B2%99%E9%BE%8D/%E6%9C%89%E4%BD%A0%E7%9C%9F%E5%A5%BD%20%E6%B9%98%E8%8F%9C%E6%B2%99%E9%BE%8D.jpg"
    ],
    "欣欣餐廳": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%AC%A3%E6%AC%A3%E9%A4%90%E5%BB%B3/%E6%AC%A3%E6%AC%A3%E9%A4%90%E5%BB%B3.jpg"
    ],
    "老曾羊肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%80%81%E6%9B%BE%E7%BE%8A%E8%82%89/%E8%80%81%E6%9B%BE%E7%BE%8A%E8%82%89.jpg"
    ],
    "誠實鍋燒意麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%AA%A0%E5%AF%A6%E9%8D%8B%E7%87%92%E6%84%8F%E9%BA%B5/%E8%AA%A0%E5%AF%A6%E9%8D%8B%E7%87%92%E6%84%8F%E9%BA%B5.jpg"
    ],
    "阿興虱目魚": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E8%88%88%E8%99%B1%E7%9B%AE%E9%AD%9A/%E9%98%BF%E8%88%88%E8%99%B1%E7%9B%AE%E9%AD%9A.jpg"
    ],
    "博仁堂": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8D%9A%E4%BB%81%E5%A0%82/%E5%8D%9A%E4%BB%81%E5%A0%82.jpg"
    ],
    "阿美飯店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E7%BE%8E%E9%A3%AF%E5%BA%97/%E9%98%BF%E7%BE%8E%E9%A3%AF%E5%BA%97.jpg"
    ],
    "筑馨居": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%AD%91%E9%A6%A8%E5%B1%85/%E7%AD%91%E9%A6%A8%E5%B1%85.jpg"
    ],
    "大勇街無名鹹粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%A4%A7%E5%8B%87%E8%A1%97%E7%84%A1%E5%90%8D%E9%B9%B9%E7%B2%A5/%E5%A4%A7%E5%8B%87%E8%A1%97%E7%84%A1%E5%90%8D%E9%B9%B9%E7%B2%A5.jpg"
    ],
    "阿明豬心冬粉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83%E5%86%AC%E7%B2%89/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83%E5%86%AC%E7%B2%89.jpg"
    ],
    "落成米糕": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%90%BD%E6%88%90%E7%B1%B3%E7%B3%95/%E8%90%BD%E6%88%90%E7%B1%B3%E7%B3%95.jpg"
    ],
    "八寶彬圓仔惠": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%85%AB%E5%AF%B6%E5%BD%AC%E5%9C%93%E4%BB%94%E6%83%A0/%E5%85%AB%E5%AF%B6%E5%BD%AC%E5%9C%93%E4%BB%94%E6%83%A0.jpg"
    ],
    "鮮蒸蝦仁肉圓": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%AE%AE%E8%92%B8%E8%9D%A6%E4%BB%81%E8%82%89%E5%9C%93/%E9%AE%AE%E8%92%B8%E8%9D%A6%E4%BB%81%E8%82%89%E5%9C%93.png"
    ],
    "好農家米糕": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%A5%BD%E8%BE%B2%E5%AE%B6%E7%B1%B3%E7%B3%95/%E5%A5%BD%E8%BE%B2%E5%AE%B6%E7%B1%B3%E7%B3%95.jpg"
    ],
    "尚好吃牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "西羅殿牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "謝掌櫃虱目魚粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%AC%9D%E6%8E%8C%E6%AB%83%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5/%E8%AC%9D%E6%8E%8C%E6%AB%83%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5.jpg"
    ],
    "東香臺菜海味料理": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9D%B1%E9%A6%99%E8%87%BA%E8%8F%9C%E6%B5%B7%E5%91%B3%E6%96%99%E7%90%86/%E6%9D%B1%E9%A6%99%E8%87%BA%E8%8F%9C%E6%B5%B7%E5%91%B3%E6%96%99%E7%90%86.jpg"
    ],
    "黑琵食堂": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%BB%91%E7%90%B5%E9%A3%9F%E5%A0%82/%E9%BB%91%E7%90%B5%E9%A3%9F%E5%A0%82.jpg"
    ],
    "永通虱目魚粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B8%E9%80%9A%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5/%E6%B0%B8%E9%80%9A%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5.jpg"
    ],
    "田媽媽長盈海味屋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%94%B0%E5%AA%BD%E5%AA%BD%E9%95%B7%E7%9B%88%E6%B5%B7%E5%91%B3%E5%B1%8B/%E7%94%B0%E5%AA%BD%E5%AA%BD%E9%95%B7%E7%9B%88%E6%B5%B7%E5%91%B3%E5%B1%8B.jpeg"
    ],
    "城邊真味炒鱔魚": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9F%8E%E9%82%8A%E7%9C%9F%E5%91%B3%E7%82%92%E9%B1%94%E9%AD%9A/%E5%9F%8E%E9%82%8A%E7%9C%9F%E5%91%B3%E7%82%92%E9%B1%94%E9%AD%9A.jpg"
    ],
    "沙淘宮廟海產": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B2%99%E6%B7%98%E5%AE%AE%E5%BB%9F%E6%B5%B7%E7%94%A2/%E6%B2%99%E6%B7%98%E5%AE%AE%E5%BB%9F%E6%B5%B7%E7%94%A2.jpeg"
    ],
    "牛五蔵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%89%9B%E4%BA%94%E8%94%B5/%E7%89%9B%E4%BA%94%E8%94%B5.jpg"
    ],
    "豐之海鮮漁府": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%B1%90%E4%B9%8B%E6%B5%B7%E9%AE%AE%E6%BC%81%E5%BA%9C/%E8%B1%90%E4%B9%8B%E6%B5%B7%E9%AE%AE%E6%BC%81%E5%BA%9C.jpg"
    ],
    "揚梅吐氣": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%8F%9A%E6%A2%85%E5%90%90%E6%B0%A3/%E6%8F%9A%E6%A2%85%E5%90%90%E6%B0%A3.jpg"
    ],
    "狂一鍋酸菜魚": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%8B%82%E4%B8%80%E9%8D%8B%E9%85%B8%E8%8F%9C%E9%AD%9A/%E7%8B%82%E4%B8%80%E9%8D%8B%E9%85%B8%E8%8F%9C%E9%AD%9A.jpg"
    ],
    "明水然・樂": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%98%8E%E6%B0%B4%E7%84%B6%E3%83%BB%E6%A8%82/%E6%98%8E%E6%B0%B4%E7%84%B6%E3%83%BB%E6%A8%82.jpeg"
    ],
    "Mao Don": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Mao%20Don/Mao%20Don.jpg"
    ],
    "毛房葱柚锅": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%AF%9B%E6%88%BF%E8%91%B1%E6%9F%9A%E9%94%85/%E6%AF%9B%E6%88%BF%E8%91%B1%E6%9F%9A%E9%94%85.jpg"
    ],
    "轉角西餐廳": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%BD%89%E8%A7%92%E8%A5%BF%E9%A4%90%E5%BB%B3/%E8%BD%89%E8%A7%92%E8%A5%BF%E9%A4%90%E5%BB%B3.jpg"
    ],
    "Noah's Ark Yakitori": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Noah%27s%20Ark%20Yakitori/Noah%27s%20Ark%20Yakitori.jpg"
    ],
    "Jade Buffet": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Jade%20Buffet/Jade%20Buffet.jpg"
    ],
    "矮仔成蝦仁飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%9F%AE%E4%BB%94%E6%88%90%E8%9D%A6%E4%BB%81%E9%A3%AF/%E7%9F%AE%E4%BB%94%E6%88%90%E8%9D%A6%E4%BB%81%E9%A3%AF.jpg"
    ],
    "阿霞飯店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E9%9C%9E%E9%A3%AF%E5%BA%97/%E9%98%BF%E9%9C%9E%E9%A3%AF%E5%BA%97.jpg"
    ],
    "周氏蝦捲": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%91%A8%E6%B0%8F%E8%9D%A6%E6%8D%B2/%E5%91%A8%E6%B0%8F%E8%9D%A6%E6%8D%B2.jpg"
    ],
    "白河鴨肉麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%99%BD%E6%B2%B3%E9%B4%A8%E8%82%89%E9%BA%B5/%E7%99%BD%E6%B2%B3%E9%B4%A8%E8%82%89%E9%BA%B5.jpg"
    ],
    "所長茶葉蛋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%89%80%E9%95%B7%E8%8C%B6%E8%91%89%E8%9B%8B/%E6%89%80%E9%95%B7%E8%8C%B6%E8%91%89%E8%9B%8B.jpg"
    ],
    "牛肉丼飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%89%9B%E8%82%89%E4%B8%BC%E9%A3%AF/%E7%89%9B%E8%82%89%E4%B8%BC%E9%A3%AF.jpg"
    ]
  };

  /// 根據餐廳名稱獲取 Firebase 上的照片 URL
  static List<String> getFirebasePhotos(String restaurantName) {
    // 精確匹配
    if (_restaurantPhotoUrls.containsKey(restaurantName)) {
      return _restaurantPhotoUrls[restaurantName]!;
    }
    
    // 模糊匹配 - 處理名稱可能的變化
    for (final entry in _restaurantPhotoUrls.entries) {
      final firebaseName = entry.key;
      
      // 如果 Google API 的名稱包含 Firebase 的名稱，或反之
      if (restaurantName.contains(firebaseName) || firebaseName.contains(restaurantName)) {
        print("🔍 模糊匹配成功: '$restaurantName' -> '$firebaseName'");
        return entry.value;
      }
      
      // 去除常見的店面相關詞語進行比較
      final cleanGoogleName = _cleanRestaurantName(restaurantName);
      final cleanFirebaseName = _cleanRestaurantName(firebaseName);
      
      if (cleanGoogleName == cleanFirebaseName) {
        print("🔍 清理後匹配成功: '$restaurantName' -> '$firebaseName'");
        return entry.value;
      }
    }
    
    print("❌ 未找到匹配的 Firebase 照片: $restaurantName");
    return [];
  }

  /// 清理餐廳名稱，移除常見的後綴詞
  static String _cleanRestaurantName(String name) {
    return name
        .replaceAll('店', '')
        .replaceAll('館', '')
        .replaceAll('屋', '')
        .replaceAll('坊', '')
        .replaceAll('家', '')
        .replaceAll('號', '')
        .replaceAll('記', '')
        .replaceAll('牌', '')
        .replaceAll('老', '')
        .replaceAll(' ', '');
  }

  /// 檢查餐廳是否有 Firebase 照片
  static bool hasFirebasePhotos(String restaurantName) {
    return getFirebasePhotos(restaurantName).isNotEmpty;
  }

  /// 獲取所有有 Firebase 照片的餐廳名稱
  static List<String> getAllFirebaseRestaurantNames() {
    return _restaurantPhotoUrls.keys.toList();
  }

  /// 結合 Google API 餐廳資料和 Firebase 照片
  static Map<String, dynamic> enhanceRestaurantWithFirebasePhotos(Map<String, dynamic> googleRestaurant) {
    final restaurantName = googleRestaurant['name'] ?? '';
    final firebasePhotos = getFirebasePhotos(restaurantName);
    
    if (firebasePhotos.isNotEmpty) {
      // 使用 Firebase 照片取代 Google Photos
      googleRestaurant['photo_urls'] = json.encode(firebasePhotos);
      googleRestaurant['has_firebase_photos'] = true;
      googleRestaurant['photo_source'] = 'firebase';
      
      print("✅ 使用 Firebase 照片: $restaurantName (${firebasePhotos.length} 張)");
    } else {
      googleRestaurant['has_firebase_photos'] = false;
      googleRestaurant['photo_source'] = 'google';
    }
    
    return googleRestaurant;
  }

  /// 批量處理餐廳列表，加入 Firebase 照片
  static List<Map<String, dynamic>> enhanceRestaurantListWithFirebasePhotos(List<Map<String, dynamic>> restaurants) {
    int firebasePhotoCount = 0;
    int totalRestaurants = restaurants.length;
    
    final enhancedRestaurants = restaurants.map((restaurant) {
      final enhanced = enhanceRestaurantWithFirebasePhotos(restaurant);
      if (enhanced['has_firebase_photos'] == true) {
        firebasePhotoCount++;
      }
      return enhanced;
    }).toList();
    
    print("📊 Firebase 照片整合完成: $firebasePhotoCount/$totalRestaurants 家餐廳使用 Firebase 照片");
    
    return enhancedRestaurants;
  }

  /// 取得統計資訊
  static Map<String, dynamic> getPhotoStats() {
    return {
      'total_firebase_restaurants': _restaurantPhotoUrls.length,
      'total_firebase_photos': _restaurantPhotoUrls.values.fold(0, (sum, photos) => sum + photos.length),
      'restaurants_with_photos': _restaurantPhotoUrls.keys.toList(),
    };
  }
}
