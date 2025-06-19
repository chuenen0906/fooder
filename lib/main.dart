import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fooder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NearbyFoodSwipePage(),
    );
  }
}

class NearbyFoodSwipePage extends StatefulWidget {
  const NearbyFoodSwipePage({super.key});

  @override
  State<NearbyFoodSwipePage> createState() => _NearbyFoodSwipePageState();
}

class _NearbyFoodSwipePageState extends State<NearbyFoodSwipePage> {
  final String apiKey = 'AIzaSyC6lBQ-jkslOR2LDkHm0q8KW4Yg9crzcHE';
  List<Map<String, String>> fullRestaurantList = [];
  List<Map<String, String>> currentRoundList = [];
  final List<String> liked = [];
  final Set<String> favorites = {};
  int round = 1;
  int cardSwiperKey = 0;
  int selectedIndex = 0;
  double? currentLat;
  double? currentLng;
  double searchRadius = 5.0;
  bool onlyShowOpen = true;
  Position? _currentPosition;
  bool isLoading = false;
  bool hasMore = true;
  bool showLocation = false;

  @override
  void initState() {
    super.initState();
    loadFavorites();
    fetchAllRestaurants(radiusKm: searchRadius);
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites.addAll(prefs.getStringList('favorites') ?? []);
    });
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> fetchAllRestaurants({double radiusKm = 5, bool onlyShowOpen = true}) async {
    print("開始抓餐廳");
    setState(() {
      fullRestaurantList = [];
      currentRoundList = [];
    });

    try {
      print("1️⃣ 檢查定位服務");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ 定位服務沒開");
        return;
      }

      print("2️⃣ 檢查定位權限");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("❌ 使用者永久拒絕定位權限");
          return;
    }
      }

      print("3️⃣ 開始抓位置");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      print("📍 現在位置：${position.latitude}, ${position.longitude}");
    double centerLat = position.latitude;
    double centerLng = position.longitude;
    double radius = radiusKm * 1000;
      int points = (radiusKm * 8).ceil();
      print("🔍 搜尋點數：$points 個點");
    double earthRadius = 6378137;
    Set<String> seen = {};
    List<Map<String, String>> allRestaurants = [];

      // 使用 Future.wait 並行處理多個請求
      List<Future<void>> searchFutures = [];

      // 中心點搜尋
      String centerUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=$centerLat,$centerLng&radius=1000&type=restaurant&language=zh-TW&key=$apiKey';
      
      searchFutures.add(_searchRestaurants(centerUrl, centerLat, centerLng, seen, allRestaurants));

      // 圓周點搜尋
    for (int i = 0; i < points; i++) {
      double angle = 2 * pi * i / points;
      double dx = radius * cos(angle);
      double dy = radius * sin(angle);
      double deltaLat = dy / earthRadius * (180 / pi);
      double deltaLng = dx / (earthRadius * cos(pi * centerLat / 180)) * (180 / pi);
      double newLat = centerLat + deltaLat;
      double newLng = centerLng + deltaLng;

        double searchRadius = min(1500.0, radius / 2);
        String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'location=$newLat,$newLng&radius=$searchRadius&type=restaurant&language=zh-TW&key=$apiKey';

        searchFutures.add(_searchRestaurants(url, centerLat, centerLng, seen, allRestaurants));
      }

      // 等待所有搜尋完成
      await Future.wait(searchFutures);

      // 處理結果
      print("for 迴圈結束，allRestaurants 總數: ${allRestaurants.length}");
      print("開始排序餐廳...");
      
      allRestaurants = allRestaurants.where((restaurant) {
        double distance = double.parse(restaurant['distance'] ?? '0');
        bool isInRange = distance <= radiusKm * 1000;
        if (!isInRange) {
          print("過濾掉超出範圍的餐廳: ${restaurant['name']} - ${distance.toStringAsFixed(2)} 公尺");
        }
        return isInRange;
      }).toList();

      print("過濾後餐廳數量: ${allRestaurants.length}");
      
      if (allRestaurants.isEmpty) {
        print("在指定範圍內沒有找到餐廳");
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("搜尋結果"),
            content: Text("在 ${radiusKm} 公里範圍內沒有找到餐廳 😢"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("關閉"),
              ),
            ],
          ),
        );
        return;
      }
      
      if (radiusKm <= 2) {
        allRestaurants.sort((a, b) {
          double distA = double.parse(a['distance'] ?? '0');
          double distB = double.parse(b['distance'] ?? '0');
          return distA.compareTo(distB);
        });
      } else {
        allRestaurants.shuffle();
        print("搜尋範圍超過2公里，使用隨機排序");
      }

      setState(() {
        currentLat = centerLat;
        currentLng = centerLng;
        fullRestaurantList = allRestaurants;
        currentRoundList = List.from(allRestaurants);
        round = 1;
        liked.clear();
        cardSwiperKey++;
        selectedIndex = 0;
        _currentPosition = position;
      });
    } catch (e) {
      print("發生錯誤: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("錯誤"),
          content: Text("搜尋餐廳時發生錯誤：$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("關閉"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _searchRestaurants(
    String url,
    double centerLat,
    double centerLng,
    Set<String> seen,
    List<Map<String, String>> allRestaurants,
  ) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('請求超時');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        for (var item in results) {
          if (onlyShowOpen) {
            if (item['opening_hours'] != null && item['opening_hours']['open_now'] != null) {
              if (item['opening_hours']['open_now'] != true) {
                continue;
              }
            } else {
              continue;
            }
          }

          final types = item['types'] as List<dynamic>? ?? [];
          if (types.contains('lodging') || types.contains('hotel')) {
            print("跳過飯店類型: ${item['name']}");
            continue;
          }

          final name = item['name'] ?? '';
          final lat = item['geometry']?['location']?['lat']?.toString() ?? '';
          final lng = item['geometry']?['location']?['lng']?.toString() ?? '';
          String uniqueId = '$name-$lat-$lng';
          
          if (!seen.contains(uniqueId)) {
            seen.add(uniqueId);

          final photoReferences = item['photos'] != null && item['photos'].isNotEmpty
              ? List<String>.from(item['photos'].map((p) => p['photo_reference']))
              : <String>[];

          final photoUrl = photoReferences.isNotEmpty
              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photoReferences[0]}&key=$apiKey'
              : 'https://via.placeholder.com/400x300.png?text=No+Image';

            double distance = 0;
            if (lat.isNotEmpty && lng.isNotEmpty) {
              distance = calculateDistance(
                centerLat,
                centerLng,
                double.parse(lat),
                double.parse(lng),
              );
            }

            String openNow = '無';
            if (item['opening_hours'] != null && item['opening_hours']['open_now'] != null) {
              openNow = item['opening_hours']['open_now'].toString();
            }

            // 將 types 轉換為 List<String>
            List<String> restaurantTypes = types.map((type) => type.toString()).toList();
            
            // 檢查是否為速食餐廳
            bool isFastFood = false;
            String lowerName = name.toLowerCase();
            
            if (lowerName.contains('mcdonalds') || 
                lowerName.contains('kfc') ||
                lowerName.contains('burger king') ||
                lowerName.contains('subway') ||
                lowerName.contains('mos') ||
                lowerName.contains('lotteria') ||
                lowerName.contains('pizza hut') ||
                lowerName.contains('domino') ||
                lowerName.contains('papa john') ||
                lowerName.contains('wendy') ||
                lowerName.contains('a&w')) {
              isFastFood = true;
              restaurantTypes.add('fast_food');
              print("檢測到速食餐廳: $name");
            }

            // 確保包含 restaurant 類型
            if (!restaurantTypes.contains('restaurant')) {
              restaurantTypes.add('restaurant');
            }

            print("餐廳名稱: $name");
            print("原始類型: $types");
            print("處理後類型: $restaurantTypes");
            print("是否為速食餐廳: $isFastFood");

            allRestaurants.add({
              'name': name,
              'image': photoUrl,
              'lat': lat,
              'lng': lng,
              'distance': distance.toStringAsFixed(2),
              'types': json.encode(restaurantTypes),
              'rating': item['rating']?.toString() ?? '',
              'open_now': openNow,
              'photo_references': json.encode(photoReferences),
              'is_fast_food': isFastFood.toString(), // 添加速食標記
            });
          }
        }
      }
    } catch (e) {
      print("搜尋餐廳時發生錯誤: $e");
    }
  }

  void handleSwipe(int? previous, int? current, CardSwiperDirection direction) {
    if (previous == null) return;
    final swipedRestaurant = currentRoundList[previous];

    if (direction == CardSwiperDirection.right) {
      liked.add(json.encode(swipedRestaurant));
    }

    if (previous == currentRoundList.length - 1) {
      List<Map<String, String>> nextRoundList = liked.map((e) => Map<String, String>.from(json.decode(e))).toList();
      
      nextRoundList = nextRoundList.where((restaurant) {
        double distance = double.parse(restaurant['distance'] ?? '0');
        bool isInRange = distance <= searchRadius * 1000;
        if (!isInRange) {
          print("過濾掉超出範圍的餐廳: ${restaurant['name']} - ${distance.toStringAsFixed(2)} 公尺");
        }
        return isInRange;
      }).toList();
      
      print("下一輪餐廳數量: ${nextRoundList.length}");
      
      if (nextRoundList.length <= 1) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("結果出爐 🎉"),
            content: nextRoundList.isEmpty
                ? const Text("你沒有右滑任何店家 😢")
                : Text("你最想吃的是：\n${nextRoundList.first['name']}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("關閉"),
              )
            ],
          ),
        );
      } else {
        setState(() {
          currentRoundList = nextRoundList;
          liked.clear();
          round++;
          cardSwiperKey++;
          selectedIndex = 0;
        });
      }
    }
  }

  void enterNextRound() {
    if (liked.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("結果出爐 🎉"),
          content: const Text("你沒有右滑任何店家 😢"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("關閉"),
            )
          ],
        ),
      );
      return;
    }
    List<Map<String, String>> nextRoundList = liked.map((e) => Map<String, String>.from(json.decode(e))).toList();
    
    nextRoundList = nextRoundList.where((restaurant) {
      double distance = double.parse(restaurant['distance'] ?? '0');
      bool isInRange = distance <= searchRadius * 1000;
      if (!isInRange) {
        print("過濾掉超出範圍的餐廳: ${restaurant['name']} - ${distance.toStringAsFixed(2)} 公尺");
      }
      return isInRange;
    }).toList();
    
    print("下一輪餐廳數量: ${nextRoundList.length}");
    
    if (nextRoundList.length <= 1) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("結果出爐 🎉"),
          content: nextRoundList.isEmpty
              ? const Text("你沒有右滑任何店家 😢")
              : Text("你最想吃的是：\n${nextRoundList.first['name']}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("關閉"),
            )
          ],
        ),
      );
    } else {
      setState(() {
        currentRoundList = nextRoundList;
        liked.clear();
        round++;
        cardSwiperKey++;
        selectedIndex = 0;
      });
    }
  }

  String classifyRestaurant(List types, Map<String, String> restaurant) {
    // 台灣常見連鎖早餐店關鍵字
    final breakfastKeywords = [
      '美而美', '弘爺', '拉亞', '麥味登', '早安美芝城', 'Q Burger', '晨間廚房', '元氣', '早安', '晨間', '早餐', '早點',
      '福來早餐', '樂活早餐', '晨間廚坊', '晨間廚房', '晨間食堂', '晨間食坊', '晨間小棧', '晨間小館', '晨間坊',
      '晨間樂', '晨間美食', '晨間美味', '晨間美', '晨間', '晨食', '晨食坊', '晨食館', '晨食屋',
      '早安山丘', '早安美', '早安樂', '早安屋', '早安坊', '早安廚房', '早安食堂', '早安小棧', '早安小館',
      '早安美食', '早安美味', '早安美', '早食', '早食坊', '早食館', '早食屋',
      '四海豆漿', '永和豆漿', '世界豆漿大王', '豆漿大王', '豆漿店', '豆漿', '蛋餅', '吐司', '漢堡', '三明治'
    ];
    final name = (restaurant['name'] ?? '').toString();
    if (breakfastKeywords.any((kw) => name.contains(kw))) {
      return '早餐店';
    }
    // 新增：店名包含「越南」就分類為越南料理
    if (name.contains('越南')) {
      return '越南料理';
    }
    // 新增：速食品牌關鍵字判斷
    final fastFoodKeywords = [
      '麥當勞', '肯德基', 'KFC', '摩斯', 'MOS', '漢堡王', 'Burger King', '必勝客', 'Pizza Hut',
      '達美樂', 'Domino', '拿坡里', 'Napoli', '頂呱呱', '21世紀', 'Subway', '丹丹', '麥味登', '胖老爹', '德克士', '美式漢堡', '炸雞'
    ];
    if (fastFoodKeywords.any((kw) => name.toLowerCase().contains(kw.toLowerCase()))) {
      return '速食餐廳';
    }
    print("正在分類餐廳類型: $types"); // 添加調試輸出
    
    // 首先檢查是否為速食餐廳
    if (types.contains('fast_food') || 
        types.contains('hamburger') || 
        types.contains('sandwich') ||
        types.contains('restaurant') && (
          types.contains('american') || 
          types.contains('burger') ||
          types.contains('mcdonalds') ||
          types.contains('kfc') ||
          types.contains('subway') ||
          types.contains('fast_food')
        )) {
      return '速食餐廳';
                  }
    
    // 咖啡廳
    if (types.contains('cafe') || 
        types.contains('coffee_shop') || 
        types.contains('bakery') ||
        types.contains('restaurant') && (
          types.contains('coffee') || 
          types.contains('cafe') ||
          types.contains('bakery')
        )) {
      return '咖啡廳';
    }
    
    // 其他分類
    if (types.contains('restaurant')) {
      if (types.contains('chinese') || types.contains('taiwanese')) return '中式料理';
      if (types.contains('japanese') || types.contains('sushi') || types.contains('ramen')) return '日式料理';
      if (types.contains('korean')) return '韓式料理';
      if (types.contains('hotpot')) return '火鍋';
      if (types.contains('barbecue') || types.contains('bbq')) return '燒烤';
      if (types.contains('noodle')) return '麵食類';
      if (types.contains('dessert')) return '甜點店';
      if (types.contains('breakfast')) return '早餐店';
      if (types.contains('drink') || types.contains('beverage') || types.contains('bubble_tea')) return '飲料店';
      if (types.contains('seafood')) return '海鮮料理';
      if (types.contains('vegetarian')) return '素食／蔬食';
      if (types.contains('steak') || types.contains('western') || types.contains('european')) return '西式料理';
      if (types.contains('american')) return '美式料理';
      if (types.contains('italian') || types.contains('pizza') || types.contains('pasta')) return '義式料理';
      if (types.contains('thai')) return '泰式料理';
      if (types.contains('vietnamese')) return '越式料理';
      if (types.contains('indian')) return '印度料理';
      if (types.contains('mexican')) return '墨西哥料理';
      return '其他料理';
    }
    return '其他類型';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('這餐想來點？'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: "查看收藏",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("已收藏的店家"),
                  content: favorites.isEmpty
                      ? const Text("目前沒有收藏的店家 ⭐")
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: favorites.map((name) => Text("⭐ $name")).toList(),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("關閉"),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "重新整理餐廳資料",
            onPressed: () => fetchAllRestaurants(radiusKm: searchRadius),
          ),
          IconButton(
            icon: const Icon(Icons.fast_forward),
            tooltip: "進入下一輪",
            onPressed: enterNextRound,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepPurple, size: 14),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.deepPurple,
                      inactiveTrackColor: Colors.deepPurple.shade100,
                      thumbColor: Colors.deepPurple,
                      overlayColor: Colors.deepPurple.withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    ),
                  child: Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: searchRadius,
                    onChanged: (value) => setState(() => searchRadius = value),
                    onChangeEnd: (value) => fetchAllRestaurants(
                      radiusKm: value, 
                        onlyShowOpen: onlyShowOpen,
                      ),
                    ),
                  ),
                ),
                Text(
                  "${searchRadius.toStringAsFixed(1).replaceAll('.0', '')} km",
                  style: const TextStyle(fontSize: 11, color: Colors.deepPurple, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x11000000)),
          if (round == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Text(
                  '不接受  vs  可接受',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          if (round == 2)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Text(
                  '沒興趣  vs  有興趣',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                    letterSpacing: 1.5,
                  ),
                ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Text("只顯示營業中"),
                Switch(
                  value: onlyShowOpen,
                  onChanged: (value) {
                    setState(() {
                      onlyShowOpen = value;
                    });
                    fetchAllRestaurants(
                      radiusKm: searchRadius,
                      onlyShowOpen: onlyShowOpen,
                    );
                  },
                ),
              ],
            ),
          ),
          if (currentLat != null && currentLng != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(showLocation ? '隱藏定位' : '顯示目前定位', style: const TextStyle(fontSize: 13)),
                    onPressed: () => setState(() => showLocation = !showLocation),
                  ),
                  if (showLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 4.0),
              child: Text(
                '目前定位：$currentLat, $currentLng',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: currentRoundList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CardSwiper(
                        key: ValueKey(cardSwiperKey),
                        cardsCount: currentRoundList.length,
                        onSwipe: handleSwipe,
                        cardBuilder: (context, index) {
                          final restaurant = currentRoundList[index];
                          double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
                          List typesList = [];
                          if (restaurant['types'] != null) {
                            try {
                              typesList = json.decode(restaurant['types']!);
                            } catch (_) {}
                          }
                      final String typeText = classifyRestaurant(typesList, restaurant);
                          final String ratingText = restaurant['rating']?.isNotEmpty == true ? restaurant['rating']! : '無';
                          final String openStatus = getOpenStatus(restaurant);
                      // 多圖 IG 限動式圖片
                      List photoRefsRaw = json.decode(restaurant['photo_references']!);
                      List<String> photoRefs = photoRefsRaw.map((e) => e.toString()).toList();
                      List<String> photoUrls = photoRefs.isNotEmpty
                          ? photoRefs.map((ref) => 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=$apiKey').toList()
                          : ['https://via.placeholder.com/400x300.png?text=No+Image'];
                      return Card(
                        elevation: 10,
                              shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                          padding: const EdgeInsets.all(18),
                                child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                              _RestaurantPhotoStoryView(
                                photoUrls: photoUrls,
                                restaurantName: restaurant['name'] ?? '未知餐廳',
                                openStatus: openStatus,
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    ratingText,
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  const SizedBox(width: 18),
                                  const Icon(Icons.place, color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 4),
                                    Text(
                                    dist >= 1000
                                        ? '${(dist / 1000).toStringAsFixed(1).replaceAll('.0', '')} km'
                                        : '${dist.toStringAsFixed(0)} 公尺',
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                      ),
                                ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                typeText,
                                style: const TextStyle(fontSize: 15, color: Colors.grey),
                                    ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    IconButton(
                                      icon: Icon(
                                        favorites.contains(restaurant['name'])
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          String name = restaurant['name'] ?? '';
                                          if (favorites.contains(name)) {
                                            favorites.remove(name);
                                          } else {
                                            favorites.add(name);
                                          }
                                          saveFavorites();
                                        });
                                      },
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.navigation, color: Colors.deepPurple),
                                      onPressed: () {
                                        openMap(
                                          restaurant['lat'] ?? '',
                                          restaurant['lng'] ?? '',
                                          restaurant['name'] ?? '',
                                        );
                                      },
                                  ),
                                ],
                                    ),
                                  ],
                              ),
                            ),
                          );
                        },
                  ),
          ),
        ],
      ),
    );
  }

  String getOpenStatus(Map<String, String> restaurant) {
    if (restaurant['open_now'] == 'true') {
      return '🟢';
    } else if (restaurant['open_now'] == 'false') {
      return '🔴';
    } else {
      return '⚪';
    }
  }

  Future<void> openMap(String lat, String lng, String label) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&destination_place_id=$label';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
}

// IG 限動式多圖圖片元件
class _RestaurantPhotoStoryView extends StatefulWidget {
  final List<String> photoUrls;
  final String restaurantName;
  final String openStatus;

  const _RestaurantPhotoStoryView({
    required this.photoUrls,
    required this.restaurantName,
    required this.openStatus,
    Key? key,
  }) : super(key: key);

  @override
  State<_RestaurantPhotoStoryView> createState() => _RestaurantPhotoStoryViewState();
}

class _RestaurantPhotoStoryViewState extends State<_RestaurantPhotoStoryView> {
  late PageController _controller;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          child: GestureDetector(
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              setState(() {
                if (local.dx < width / 2 && _currentPhotoIndex > 0) {
                  _currentPhotoIndex--;
                  _controller.animateToPage(_currentPhotoIndex, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
                } else if (local.dx >= width / 2 && _currentPhotoIndex < widget.photoUrls.length - 1) {
                  _currentPhotoIndex++;
                  _controller.animateToPage(_currentPhotoIndex, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
                }
              });
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: widget.photoUrls.length,
                  onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                  itemBuilder: (context, idx) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        widget.photoUrls[idx],
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
                // 進度條
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: List.generate(widget.photoUrls.length, (idx) =>
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: idx <= _currentPhotoIndex ? Colors.white : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 餐廳名稱與狀態燈
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.restaurantName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.openStatus,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
