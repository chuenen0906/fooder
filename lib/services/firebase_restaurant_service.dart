import 'dart:convert';

class FirebaseRestaurantService {
  static final FirebaseRestaurantService _instance = FirebaseRestaurantService._internal();
  factory FirebaseRestaurantService() => _instance;
  FirebaseRestaurantService._internal();

  // Firebase 上傳的餐廳照片映射 - 自動生成於 2025-07-11
  static const Map<String, List<String>> _restaurantPhotoUrls = {
    "金得春捲": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2/%E9%87%91%E5%BE%97%E6%98%A5%E6%8D%B2_2.jpg"
    ],
    "石精臼蚵仔煎": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%9F%B3%E7%B2%BE%E8%87%BC%E8%9A%B5%E4%BB%94%E7%85%8E/%E7%9F%B3%E7%B2%BE%E8%87%BC%E8%9A%B5%E4%BB%94%E7%85%8E.jpg"
    ],
    "富盛號碗粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%AF%8C%E7%9B%9B%E8%99%9F%E7%A2%97%E7%B2%BF/%E5%AF%8C%E7%9B%9B%E8%99%9F%E7%A2%97%E7%B2%BF.jpg"
    ],
    "阿堂鹹粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A0%82%E9%B9%B9%E7%B2%A5/atang_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A0%82%E9%B9%B9%E7%B2%A5/atang_2.jpg"
    ],
    "邱家小卷米粉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89/%E9%82%B1%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89_2.jpg"
    ],
    "炸雞洋行": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C/%E7%82%B8%E9%9B%9E%E6%B4%8B%E8%A1%8C_2.jpg"
    ],
    "阿伯炭烤黑輪甜不辣": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E4%BC%AF%E7%82%AD%E7%83%A4%E9%BB%91%E8%BC%AA%E7%94%9C%E4%B8%8D%E8%BE%A3/%E9%98%BF%E4%BC%AF%E7%82%AD%E7%83%A4%E9%BB%91%E8%BC%AA%E7%94%9C%E4%B8%8D%E8%BE%A3.jpg"
    ],
    "阿明豬心": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83/%E9%98%BF%E6%98%8E%E8%B1%AC%E5%BF%83.jpg"
    ],
    "阿松割包": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85/%E9%98%BF%E6%9D%BE%E5%89%B2%E5%8C%85_2.jpg"
    ],
    "修安扁擔豆花": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1/%E4%BF%AE%E5%AE%89%E6%89%81%E6%93%94%E8%B1%86%E8%8A%B1_2.jpg"
    ],
    "蜷尾家甘味處": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95/%E8%9C%B7%E5%B0%BE%E5%AE%B6%E7%94%98%E5%91%B3%E8%99%95_2.jpg"
    ],
    "江水號": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B1%9F%E6%B0%B4%E8%99%9F/%E6%B1%9F%E6%B0%B4%E8%99%9F_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B1%9F%E6%B0%B4%E8%99%9F/%E6%B1%9F%E6%B0%B4%E8%99%9F_2.jpg"
    ],
    "鴨米脆皮薯條": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%B4%A8%E7%B1%B3%E8%84%86%E7%9A%AE%E8%96%AF%E6%A2%9D/%E9%B4%A8%E7%B1%B3%E8%84%86%E7%9A%AE%E8%96%AF%E6%A2%9D_1.jpg"
    ],
    "林家白糖粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9E%97%E5%AE%B6%E7%99%BD%E7%B3%96%E7%B2%BF/%E6%9E%97%E5%AE%B6%E7%99%BD%E7%B3%96%E7%B2%BF_1.jpg"
    ],
    "阿婆魯麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5/%E9%98%BF%E5%A9%86%E9%AD%AF%E9%BA%B5_2.jpg"
    ],
    "勝利早點": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E_2.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E/%E5%8B%9D%E5%88%A9%E6%97%A9%E9%BB%9E_3.jpg"
    ],
    "廖記老牌鱔魚麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%BB%96%E8%A8%98%E8%80%81%E7%89%8C%E9%B1%94%E9%AD%9A%E9%BA%B5/%E5%BB%96%E8%A8%98%E8%80%81%E7%89%8C%E9%B1%94%E9%AD%9A%E9%BA%B5.jpg"
    ],
    "圓環牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF_1.JPG",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF/%E5%9C%93%E7%92%B0%E7%89%9B%E8%82%89%E6%B9%AF_2.jpg"
    ],
    "阿村牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF/%E9%98%BF%E6%9D%91%E7%89%9B%E8%82%89%E6%B9%AF_2.jpg"
    ],
    "文章牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%96%87%E7%AB%A0%E7%89%9B%E8%82%89%E6%B9%AF/%E6%96%87%E7%AB%A0%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "永樂牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF/%E6%B0%B8%E6%A8%82%E7%89%9B%E8%82%89%E6%B9%AF_2.jpg"
    ],
    "一味品碗粿": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF/%E4%B8%80%E5%91%B3%E5%93%81%E7%A2%97%E7%B2%BF_2.jpg"
    ],
    "阿裕牛肉涮涮鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E8%A3%95%E7%89%9B%E8%82%89%E6%B6%AE%E6%B6%AE%E9%8D%8B/%E9%98%BF%E8%A3%95%E7%89%9B%E8%82%89%E6%B6%AE%E6%B6%AE%E9%8D%8B.jpg"
    ],
    "牛苑火鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%89%9B%E8%8B%91%E7%81%AB%E9%8D%8B/%E7%89%9B%E8%8B%91%E7%81%AB%E9%8D%8B.jpg"
    ],
    "六月三十義式手工冰淇淋": [
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
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%87%B7%E8%88%8A%E5%B0%8F%E6%A3%A7%E6%9D%8F%E4%BB%81%E8%B1%86%E8%85%90%E5%86%B0/%E6%87%B7%E8%88%8A%E5%B0%8F%E6%A3%A7%E6%9D%8F%E4%BB%81%E8%B1%86%E8%85%90%E5%86%B0_1.jpg"
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
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF/%E5%B0%9A%E5%A5%BD%E5%90%83%E7%89%9B%E8%82%89%E6%B9%AF_2.jpg"
    ],
    "西羅殿牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF_1.jpg",
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF/%E8%A5%BF%E7%BE%85%E6%AE%BF%E7%89%9B%E8%82%89%E6%B9%AF_2.jpg"
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
    ],
    "生魚片丼": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%94%9F%E9%AD%9A%E7%89%87%E4%B8%BC/%E7%94%9F%E9%AD%9A%E7%89%87%E4%B8%BC.jpg"
    ],
    "度小月擔仔麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%BA%A6%E5%B0%8F%E6%9C%88%E6%93%94%E4%BB%94%E9%BA%B5/%E5%BA%A6%E5%B0%8F%E6%9C%88%E6%93%94%E4%BB%94%E9%BA%B5.jpg"
    ],
    "博仁堂藥膳湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8D%9A%E4%BB%81%E5%A0%82%E8%97%A5%E8%86%B3%E6%B9%AF/%E5%8D%9A%E4%BB%81%E5%A0%82%E8%97%A5%E8%86%B3%E6%B9%AF.jpg"
    ],
    "八筒甜室": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%85%AB%E7%AD%92%E7%94%9C%E5%AE%A4/%E5%85%AB%E7%AD%92%E7%94%9C%E5%AE%A4.jpg"
    ],
    "韓金婆婆豆腐酪": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%9F%93%E9%87%91%E5%A9%86%E5%A9%86%E8%B1%86%E8%85%90%E9%85%AA/%E9%9F%93%E9%87%91%E5%A9%86%E5%A9%86%E8%B1%86%E8%85%90%E9%85%AA.jpg"
    ],
    "永樂燒肉飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%B8%E6%A8%82%E7%87%92%E8%82%89%E9%A3%AF/%E6%B0%B8%E6%A8%82%E7%87%92%E8%82%89%E9%A3%AF.jpg"
    ],
    "華味香（新營鴨肉羹）": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%8F%AF%E5%91%B3%E9%A6%99%EF%BC%88%E6%96%B0%E7%87%9F%E9%B4%A8%E8%82%89%E7%BE%B9%EF%BC%89/%E8%8F%AF%E5%91%B3%E9%A6%99%EF%BC%88%E6%96%B0%E7%87%9F%E9%B4%A8%E8%82%89%E7%BE%B9%EF%BC%89.jpg"
    ],
    "小哲食堂": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E5%93%B2%E9%A3%9F%E5%A0%82/%E5%B0%8F%E5%93%B2%E9%A3%9F%E5%A0%82.jpg"
    ],
    "Here Kyoto": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Here%20Kyoto/Here%20Kyoto.jpg"
    ],
    "L'Amour鐵板燒": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/L%27Amour%E9%90%B5%E6%9D%BF%E7%87%92/L%27Amour%E9%90%B5%E6%9D%BF%E7%87%92.jpg"
    ],
    "AMA LABO": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/AMA%20LABO/AMA%20LABO.jpg"
    ],
    "Bonheur Cookie": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Bonheur%20Cookie/Bonheur%20Cookie.jpg"
    ],
    "樂慕鐵板燒": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%A8%82%E6%85%95%E9%90%B5%E6%9D%BF%E7%87%92/%E6%A8%82%E6%85%95%E9%90%B5%E6%9D%BF%E7%87%92.jpg"
    ],
    "一番地壽喜燒": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%80%E7%95%AA%E5%9C%B0%E5%A3%BD%E5%96%9C%E7%87%92/%E4%B8%80%E7%95%AA%E5%9C%B0%E5%A3%BD%E5%96%9C%E7%87%92.jpg"
    ],
    "遠東Cafe": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%81%A0%E6%9D%B1Cafe/%E9%81%A0%E6%9D%B1Cafe.jpg"
    ],
    "莘全素料理": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%8E%98%E5%85%A8%E7%B4%A0%E6%96%99%E7%90%86/%E8%8E%98%E5%85%A8%E7%B4%A0%E6%96%99%E7%90%86.jpg"
    ],
    "漢來海港餐廳": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%BC%A2%E4%BE%86%E6%B5%B7%E6%B8%AF%E9%A4%90%E5%BB%B3/%E6%BC%A2%E4%BE%86%E6%B5%B7%E6%B8%AF%E9%A4%90%E5%BB%B3.jpg"
    ],
    "潘家牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%BD%98%E5%AE%B6%E7%89%9B%E8%82%89%E6%B9%AF/%E6%BD%98%E5%AE%B6%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "阿村第二代牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%91%E7%AC%AC%E4%BA%8C%E4%BB%A3%E7%89%9B%E8%82%89%E6%B9%AF/%E9%98%BF%E6%9D%91%E7%AC%AC%E4%BA%8C%E4%BB%A3%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "無名羊肉湯（大菜市）": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%84%A1%E5%90%8D%E7%BE%8A%E8%82%89%E6%B9%AF%EF%BC%88%E5%A4%A7%E8%8F%9C%E5%B8%82%EF%BC%89/%E7%84%A1%E5%90%8D%E7%BE%8A%E8%82%89%E6%B9%AF%EF%BC%88%E5%A4%A7%E8%8F%9C%E5%B8%82%EF%BC%89.jpg"
    ],
    "六千牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%85%AD%E5%8D%83%E7%89%9B%E8%82%89%E6%B9%AF/%E5%85%AD%E5%8D%83%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "VTCC烤雞": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/VTCC%E7%83%A4%E9%9B%9E/VTCC%E7%83%A4%E9%9B%9E.jpg"
    ],
    "清水堂": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B8%85%E6%B0%B4%E5%A0%82/%E6%B8%85%E6%B0%B4%E5%A0%82.jpg"
    ],
    "葉家小卷米粉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%91%89%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89/%E8%91%89%E5%AE%B6%E5%B0%8F%E5%8D%B7%E7%B1%B3%E7%B2%89.jpg"
    ],
    "阿卿杏仁茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%8D%BF%E6%9D%8F%E4%BB%81%E8%8C%B6/%E9%98%BF%E5%8D%BF%E6%9D%8F%E4%BB%81%E8%8C%B6.jpg"
    ],
    "福生小食": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%A6%8F%E7%94%9F%E5%B0%8F%E9%A3%9F/%E7%A6%8F%E7%94%9F%E5%B0%8F%E9%A3%9F.jpg"
    ],
    "協進國小2元黑輪攤": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8D%94%E9%80%B2%E5%9C%8B%E5%B0%8F2%E5%85%83%E9%BB%91%E8%BC%AA%E6%94%A4/%E5%8D%94%E9%80%B2%E5%9C%8B%E5%B0%8F2%E5%85%83%E9%BB%91%E8%BC%AA%E6%94%A4.jpg"
    ],
    "韋家乾麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%9F%8B%E5%AE%B6%E4%B9%BE%E9%BA%B5/%E9%9F%8B%E5%AE%B6%E4%B9%BE%E9%BA%B5.jpg"
    ],
    "小赤佬干鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E8%B5%A4%E4%BD%AC%E5%B9%B2%E9%8D%8B/%E5%B0%8F%E8%B5%A4%E4%BD%AC%E5%B9%B2%E9%8D%8B.jpg"
    ],
    "感性滷味": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%84%9F%E6%80%A7%E6%BB%B7%E5%91%B3/%E6%84%9F%E6%80%A7%E6%BB%B7%E5%91%B3.jpg"
    ],
    "阿杰溫體牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%9D%B0%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E6%B9%AF/%E9%98%BF%E6%9D%B0%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "豪牛溫體牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%B1%AA%E7%89%9B%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E6%B9%AF/%E8%B1%AA%E7%89%9B%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
    "Chun純薏仁": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Chun%E7%B4%94%E8%96%8F%E4%BB%81/Chun%E7%B4%94%E8%96%8F%E4%BB%81.jpg"
    ],
    "民德虱目魚粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B0%91%E5%BE%B7%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5/%E6%B0%91%E5%BE%B7%E8%99%B1%E7%9B%AE%E9%AD%9A%E7%B2%A5.jpg"
    ],
    "双生綠豆沙牛奶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8F%8C%E7%94%9F%E7%B6%A0%E8%B1%86%E6%B2%99%E7%89%9B%E5%A5%B6/%E5%8F%8C%E7%94%9F%E7%B6%A0%E8%B1%86%E6%B2%99%E7%89%9B%E5%A5%B6.jpg"
    ],
    "鼎富發豬油拌飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%BC%8E%E5%AF%8C%E7%99%BC%E8%B1%AC%E6%B2%B9%E6%8B%8C%E9%A3%AF/%E9%BC%8E%E5%AF%8C%E7%99%BC%E8%B1%AC%E6%B2%B9%E6%8B%8C%E9%A3%AF.jpg"
    ],
    "國華街豆腐洋行": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%8B%E8%8F%AF%E8%A1%97%E8%B1%86%E8%85%90%E6%B4%8B%E8%A1%8C/%E5%9C%8B%E8%8F%AF%E8%A1%97%E8%B1%86%E8%85%90%E6%B4%8B%E8%A1%8C.jpg"
    ],
    "鹽水意麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%B9%BD%E6%B0%B4%E6%84%8F%E9%BA%B5/%E9%B9%BD%E6%B0%B4%E6%84%8F%E9%BA%B5.jpg"
    ],
    "東山咖啡": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9D%B1%E5%B1%B1%E5%92%96%E5%95%A1/%E6%9D%B1%E5%B1%B1%E5%92%96%E5%95%A1.jpg"
    ],
    "鬍鬚忠牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%AC%8D%E9%AC%9A%E5%BF%A0%E7%89%9B%E8%82%89%E6%B9%AF/%E9%AC%8D%E9%AC%9A%E5%BF%A0%E7%89%9B%E8%82%89%E6%B9%AF.png"
    ],
    "再發號百年肉粽": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%86%8D%E7%99%BC%E8%99%9F%E7%99%BE%E5%B9%B4%E8%82%89%E7%B2%BD/%E5%86%8D%E7%99%BC%E8%99%9F%E7%99%BE%E5%B9%B4%E8%82%89%E7%B2%BD.jpg"
    ],
    "上好烤魯味": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%8A%E5%A5%BD%E7%83%A4%E9%AD%AF%E5%91%B3/%E4%B8%8A%E5%A5%BD%E7%83%A4%E9%AD%AF%E5%91%B3.jpg"
    ],
    "百年油條": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%99%BE%E5%B9%B4%E6%B2%B9%E6%A2%9D/%E7%99%BE%E5%B9%B4%E6%B2%B9%E6%A2%9D.jpg"
    ],
    "四季溫體牛肉鍋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9B%9B%E5%AD%A3%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E9%8D%8B/%E5%9B%9B%E5%AD%A3%E6%BA%AB%E9%AB%94%E7%89%9B%E8%82%89%E9%8D%8B.jpg"
    ],
    "麵條王海產麵": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%BA%B5%E6%A2%9D%E7%8E%8B%E6%B5%B7%E7%94%A2%E9%BA%B5/%E9%BA%B5%E6%A2%9D%E7%8E%8B%E6%B5%B7%E7%94%A2%E9%BA%B5.jpg"
    ],
    "下大道旗魚羹": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%8B%E5%A4%A7%E9%81%93%E6%97%97%E9%AD%9A%E7%BE%B9/%E4%B8%8B%E5%A4%A7%E9%81%93%E6%97%97%E9%AD%9A%E7%BE%B9.jpg"
    ],
    "上海味香小吃店": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%8A%E6%B5%B7%E5%91%B3%E9%A6%99%E5%B0%8F%E5%90%83%E5%BA%97/%E4%B8%8A%E6%B5%B7%E5%91%B3%E9%A6%99%E5%B0%8F%E5%90%83%E5%BA%97.jpg"
    ],
    "清珍鴨肉羹": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B8%85%E7%8F%8D%E9%B4%A8%E8%82%89%E7%BE%B9/%E6%B8%85%E7%8F%8D%E9%B4%A8%E8%82%89%E7%BE%B9.jpg"
    ],
    "AIC 冰淇淋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/AIC%20%E5%86%B0%E6%B7%87%E6%B7%8B/AIC%20%E5%86%B0%E6%B7%87%E6%B7%8B.jpg"
    ],
    "小兵砂鍋菜": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E5%85%B5%E7%A0%82%E9%8D%8B%E8%8F%9C/%E5%B0%8F%E5%85%B5%E7%A0%82%E9%8D%8B%E8%8F%9C.png"
    ],
    "Oganna黑瓶子燒肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Oganna%E9%BB%91%E7%93%B6%E5%AD%90%E7%87%92%E8%82%89/Oganna%E9%BB%91%E7%93%B6%E5%AD%90%E7%87%92%E8%82%89.jpg"
    ],
    "隼次燒鳥居食處": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%9A%BC%E6%AC%A1%E7%87%92%E9%B3%A5%E5%B1%85%E9%A3%9F%E8%99%95/%E9%9A%BC%E6%AC%A1%E7%87%92%E9%B3%A5%E5%B1%85%E9%A3%9F%E8%99%95.jpg"
    ],
    "布拉格烘焙": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B8%83%E6%8B%89%E6%A0%BC%E7%83%98%E7%84%99/%E5%B8%83%E6%8B%89%E6%A0%BC%E7%83%98%E7%84%99.jpg"
    ],
    "BKSK鬆餅": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/BKSK%E9%AC%86%E9%A4%85/BKSK%E9%AC%86%E9%A4%85.jpg"
    ],
    "植形力": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%A4%8D%E5%BD%A2%E5%8A%9B/%E6%A4%8D%E5%BD%A2%E5%8A%9B.jpg"
    ],
    "小卒砂鍋雞米飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%B0%8F%E5%8D%92%E7%A0%82%E9%8D%8B%E9%9B%9E%E7%B1%B3%E9%A3%AF/%E5%B0%8F%E5%8D%92%E7%A0%82%E9%8D%8B%E9%9B%9E%E7%B1%B3%E9%A3%AF.jpg"
    ],
    "阿澎海產粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E6%BE%8E%E6%B5%B7%E7%94%A2%E7%B2%A5/%E9%98%BF%E6%BE%8E%E6%B5%B7%E7%94%A2%E7%B2%A5.jpg"
    ],
    "包工坊": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8C%85%E5%B7%A5%E5%9D%8A/%E5%8C%85%E5%B7%A5%E5%9D%8A.jpg"
    ],
    "叔炸甜不辣媽": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%8F%94%E7%82%B8%E7%94%9C%E4%B8%8D%E8%BE%A3%E5%AA%BD/%E5%8F%94%E7%82%B8%E7%94%9C%E4%B8%8D%E8%BE%A3%E5%AA%BD.jpg"
    ],
    "日便當": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%97%A5%E4%BE%BF%E7%95%B6/%E6%97%A5%E4%BE%BF%E7%95%B6.png"
    ],
    "綠豆皮": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%B6%A0%E8%B1%86%E7%9A%AE/%E7%B6%A0%E8%B1%86%E7%9A%AE.jpg"
    ],
    "沙白電台": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B2%99%E7%99%BD%E9%9B%BB%E5%8F%B0/%E6%B2%99%E7%99%BD%E9%9B%BB%E5%8F%B0.jpg"
    ],
    "一坪壽司小賣所": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%80%E5%9D%AA%E5%A3%BD%E5%8F%B8%E5%B0%8F%E8%B3%A3%E6%89%80/%E4%B8%80%E5%9D%AA%E5%A3%BD%E5%8F%B8%E5%B0%8F%E8%B3%A3%E6%89%80.jpg"
    ],
    "李記血藤爐": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9D%8E%E8%A8%98%E8%A1%80%E8%97%A4%E7%88%90/%E6%9D%8E%E8%A8%98%E8%A1%80%E8%97%A4%E7%88%90.jpg"
    ],
    "泰式幽靈串燒": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%B3%B0%E5%BC%8F%E5%B9%BD%E9%9D%88%E4%B8%B2%E7%87%92/%E6%B3%B0%E5%BC%8F%E5%B9%BD%E9%9D%88%E4%B8%B2%E7%87%92.jpg"
    ],
    "國華街肉燥飯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%8B%E8%8F%AF%E8%A1%97%E8%82%89%E7%87%A5%E9%A3%AF/%E5%9C%8B%E8%8F%AF%E8%A1%97%E8%82%89%E7%87%A5%E9%A3%AF.jpg"
    ],
    "Little b 小波露": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/Little%20b%20%E5%B0%8F%E6%B3%A2%E9%9C%B2/Little%20b%20%E5%B0%8F%E6%B3%A2%E9%9C%B2.jpg"
    ],
    "初幸居食屋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%88%9D%E5%B9%B8%E5%B1%85%E9%A3%9F%E5%B1%8B/%E5%88%9D%E5%B9%B8%E5%B1%85%E9%A3%9F%E5%B1%8B.jpg"
    ],
    "品馨冰菓室": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%93%81%E9%A6%A8%E5%86%B0%E8%8F%93%E5%AE%A4/%E5%93%81%E9%A6%A8%E5%86%B0%E8%8F%93%E5%AE%A4.png"
    ],
    "樂浮茶飲": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%A8%82%E6%B5%AE%E8%8C%B6%E9%A3%B2/%E6%A8%82%E6%B5%AE%E8%8C%B6%E9%A3%B2.jpg"
    ],
    "熊記Bear's Casa": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%86%8A%E8%A8%98Bear%27s%20Casa/%E7%86%8A%E8%A8%98Bear%27s%20Casa.jpg"
    ],
    "咕嚕叫土司": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%92%95%E5%9A%95%E5%8F%AB%E5%9C%9F%E5%8F%B8/%E5%92%95%E5%9A%95%E5%8F%AB%E5%9C%9F%E5%8F%B8.jpg"
    ],
    "林紅茶": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%9E%97%E7%B4%85%E8%8C%B6/%E6%9E%97%E7%B4%85%E8%8C%B6.jpg"
    ],
    "富鴻魚肚小吃": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%AF%8C%E9%B4%BB%E9%AD%9A%E8%82%9A%E5%B0%8F%E5%90%83/%E5%AF%8C%E9%B4%BB%E9%AD%9A%E8%82%9A%E5%B0%8F%E5%90%83.jpg"
    ],
    "三鮮蒸餃": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%89%E9%AE%AE%E8%92%B8%E9%A4%83/%E4%B8%89%E9%AE%AE%E8%92%B8%E9%A4%83.jpg"
    ],
    "碳饅堡": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%A2%B3%E9%A5%85%E5%A0%A1/%E7%A2%B3%E9%A5%85%E5%A0%A1.jpg"
    ],
    "阿忠魚粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%BF%A0%E9%AD%9A%E7%B2%A5/%E9%98%BF%E5%BF%A0%E9%AD%9A%E7%B2%A5.jpg"
    ],
    "捲捲米Sushi Bar": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%8D%B2%E6%8D%B2%E7%B1%B3Sushi%20Bar/%E6%8D%B2%E6%8D%B2%E7%B1%B3Sushi%20Bar.jpg"
    ],
    "和喫鬆餅": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%92%8C%E5%96%AB%E9%AC%86%E9%A4%85/%E5%92%8C%E5%96%AB%E9%AC%86%E9%A4%85.jpg"
    ],
    "玉婆壽司屋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%8E%89%E5%A9%86%E5%A3%BD%E5%8F%B8%E5%B1%8B/%E7%8E%89%E5%A9%86%E5%A3%BD%E5%8F%B8%E5%B1%8B.jpg"
    ],
    "AIC冰淇淋": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/AIC%E5%86%B0%E6%B7%87%E6%B7%8B/AIC%E5%86%B0%E6%B7%87%E6%B7%8B.jpg"
    ],
    "葉家豬血湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%91%89%E5%AE%B6%E8%B1%AC%E8%A1%80%E6%B9%AF/%E8%91%89%E5%AE%B6%E8%B1%AC%E8%A1%80%E6%B9%AF.jpg"
    ],
    "老街紅燒肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E8%80%81%E8%A1%97%E7%B4%85%E7%87%92%E8%82%89/%E8%80%81%E8%A1%97%E7%B4%85%E7%87%92%E8%82%89.jpg"
    ],
    "甄品豬腳": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%94%84%E5%93%81%E8%B1%AC%E8%85%B3/%E7%94%84%E5%93%81%E8%B1%AC%E8%85%B3.jpg"
    ],
    "王家香腸熟肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%8E%8B%E5%AE%B6%E9%A6%99%E8%85%B8%E7%86%9F%E8%82%89/%E7%8E%8B%E5%AE%B6%E9%A6%99%E8%85%B8%E7%86%9F%E8%82%89.jpg"
    ],
    "吳媽媽肉圓": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%90%B3%E5%AA%BD%E5%AA%BD%E8%82%89%E5%9C%93/%E5%90%B3%E5%AA%BD%E5%AA%BD%E8%82%89%E5%9C%93.jpg"
    ],
    "手工水晶餃": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E6%89%8B%E5%B7%A5%E6%B0%B4%E6%99%B6%E9%A4%83/%E6%89%8B%E5%B7%A5%E6%B0%B4%E6%99%B6%E9%A4%83.jpg"
    ],
    "鴨母寮市場無名剉冰": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%B4%A8%E6%AF%8D%E5%AF%AE%E5%B8%82%E5%A0%B4%E7%84%A1%E5%90%8D%E5%89%89%E5%86%B0/%E9%B4%A8%E6%AF%8D%E5%AF%AE%E5%B8%82%E5%A0%B4%E7%84%A1%E5%90%8D%E5%89%89%E5%86%B0.jpg"
    ],
    "香味麵食館": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%A6%99%E5%91%B3%E9%BA%B5%E9%A3%9F%E9%A4%A8/%E9%A6%99%E5%91%B3%E9%BA%B5%E9%A3%9F%E9%A4%A8.jpg"
    ],
    "阿婆肉粽": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%98%BF%E5%A9%86%E8%82%89%E7%B2%BD/%E9%98%BF%E5%A9%86%E8%82%89%E7%B2%BD.jpg"
    ],
    "下大道滷味": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E4%B8%8B%E5%A4%A7%E9%81%93%E6%BB%B7%E5%91%B3/%E4%B8%8B%E5%A4%A7%E9%81%93%E6%BB%B7%E5%91%B3.jpg"
    ],
    "圓仔伯豆花": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9C%93%E4%BB%94%E4%BC%AF%E8%B1%86%E8%8A%B1/%E5%9C%93%E4%BB%94%E4%BC%AF%E8%B1%86%E8%8A%B1.jpg"
    ],
    "大億鵝肉": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%A4%A7%E5%84%84%E9%B5%9D%E8%82%89/%E5%A4%A7%E5%84%84%E9%B5%9D%E8%82%89.jpg"
    ],
    "金福氣魯味": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%87%91%E7%A6%8F%E6%B0%A3%E9%AD%AF%E5%91%B3/%E9%87%91%E7%A6%8F%E6%B0%A3%E9%AD%AF%E5%91%B3.jpg"
    ],
    "城隍街鹹粥": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E5%9F%8E%E9%9A%8D%E8%A1%97%E9%B9%B9%E7%B2%A5/%E5%9F%8E%E9%9A%8D%E8%A1%97%E9%B9%B9%E7%B2%A5.jpg"
    ],
    "米街雞蛋糕": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E7%B1%B3%E8%A1%97%E9%9B%9E%E8%9B%8B%E7%B3%95/%E7%B1%B3%E8%A1%97%E9%9B%9E%E8%9B%8B%E7%B3%95.jpg"
    ],
    "鴻品牛肉湯": [
      "https://storage.googleapis.com/folder-47165.firebasestorage.app/restaurant_photos/%E9%B4%BB%E5%93%81%E7%89%9B%E8%82%89%E6%B9%AF/%E9%B4%BB%E5%93%81%E7%89%9B%E8%82%89%E6%B9%AF.jpg"
    ],
  };

  // 獲取餐廳照片 URL 列表
  static List<String> getRestaurantPhotoUrls(String restaurantName) {
    return _restaurantPhotoUrls[restaurantName] ?? [];
  }

  // 檢查餐廳是否有照片
  static bool hasRestaurantPhotos(String restaurantName) {
    return _restaurantPhotoUrls.containsKey(restaurantName) && _restaurantPhotoUrls[restaurantName]!.isNotEmpty;
  }

  // 獲取所有有照片的餐廳名稱
  static List<String> getRestaurantsWithPhotos() {
    return _restaurantPhotoUrls.keys.toList();
  }

  // 為餐廳列表添加 Firebase 照片
  static List<Map<String, dynamic>> enhanceRestaurantListWithFirebasePhotos(List<Map<String, dynamic>> restaurants) {
    return restaurants.map((restaurant) {
      final restaurantName = restaurant['name']?.toString() ?? '';
      final photoUrls = getRestaurantPhotoUrls(restaurantName);
      
      if (photoUrls.isNotEmpty) {
        restaurant['has_firebase_photos'] = true;
        restaurant['photo_urls'] = jsonEncode(photoUrls);
        // 如果有 Firebase 照片，優先使用第一張作為主要圖片
        if (restaurant['image'] == null || restaurant['image'].toString().isEmpty) {
          restaurant['image'] = photoUrls.first;
        }
      } else {
        restaurant['has_firebase_photos'] = false;
        restaurant['photo_urls'] = jsonEncode([]);
      }
      
      return restaurant;
    }).toList();
  }

  // 為單一餐廳添加 Firebase 照片
  static Map<String, dynamic> enhanceRestaurantWithFirebasePhotos(Map<String, dynamic> restaurant) {
    final restaurantName = restaurant['name']?.toString() ?? '';
    final photoUrls = getRestaurantPhotoUrls(restaurantName);
    
    if (photoUrls.isNotEmpty) {
      restaurant['has_firebase_photos'] = true;
      restaurant['photo_urls'] = jsonEncode(photoUrls);
      // 如果有 Firebase 照片，優先使用第一張作為主要圖片
      if (restaurant['image'] == null || restaurant['image'].toString().isEmpty) {
        restaurant['image'] = photoUrls.first;
      }
    } else {
      restaurant['has_firebase_photos'] = false;
      restaurant['photo_urls'] = jsonEncode([]);
    }
    
    return restaurant;
  }

  // 檢查餐廳是否有 Firebase 照片
  static bool hasFirebasePhotos(String restaurantName) {
    return hasRestaurantPhotos(restaurantName);
  }

  // 獲取照片統計資訊
  static Map<String, dynamic> getPhotoStats() {
    final totalRestaurants = _restaurantPhotoUrls.length;
    int totalPhotos = 0;
    for (final photos in _restaurantPhotoUrls.values) {
      totalPhotos += photos.length;
    }
    
    return {
      'total_restaurants': totalRestaurants,
      'total_photos': totalPhotos,
      'average_photos_per_restaurant': (totalRestaurants > 0 ? totalPhotos / totalRestaurants : 0).toStringAsFixed(1),
    };
  }

  // 獲取所有有 Firebase 照片的餐廳名稱
  static List<String> getAllFirebaseRestaurantNames() {
    return getRestaurantsWithPhotos();
  }

  // 獲取指定餐廳的所有 Firebase 照片
  static List<String> getFirebasePhotos(String restaurantName, {int? maxPhotos}) {
    final photos = getRestaurantPhotoUrls(restaurantName);
    if (maxPhotos != null) {
      return photos.take(maxPhotos).toList();
    }
    return photos;
  }
}

