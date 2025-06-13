import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'photo_page_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 收藏資料結構
class SimpleFavorite {
  final String id;
  final String name;
  final String imageUrl;

  SimpleFavorite({required this.id, required this.name, required this.imageUrl});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
  };

  factory SimpleFavorite.fromJson(Map<String, dynamic> json) => SimpleFavorite(
    id: json['id'],
    name: json['name'],
    imageUrl: json['imageUrl'],
  );
}

// 收藏資料存/取工具
class FavoriteManager {
  static const key = 'favorites';

  static Future<List<SimpleFavorite>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];
    return data.map((str) => SimpleFavorite.fromJson(json.decode(str))).toList();
  }

  static Future<void> saveFavorites(List<SimpleFavorite> favs) async {
    final prefs = await SharedPreferences.getInstance();
    final data = favs.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(key, data);
  }
}


void main() {
  runApp(const FoodSwipeApp());
}

class FoodSwipeApp extends StatelessWidget {
  const FoodSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodER',
      theme: ThemeData(primarySwatch: Colors.orange),
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
  final String apiKey = 'YOUR_API_KEY_HERE';
  List<Map<String, String>> fullRestaurantList = [];
  List<Map<String, String>> currentRoundList = [];
  final List<String> liked = [];
  final Set<String> favorites = {};
  int round = 1;
  double? currentLat;
  double? currentLng;
  double searchRadius = 5;
  bool onlyShowOpen = false;

  int cardSwiperKey = 0;
  int selectedIndex = 0; // 決賽用

  @override
  void initState() {
    super.initState();
    fetchAllRestaurants(radiusKm: searchRadius);
    loadFavorites();
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('favorites') ?? [];
    setState(() {
      favorites.clear();
      favorites.addAll(savedList);
    });
  }

  void toggleFavorite(Map<String, String> restaurant) async {
    String id = restaurant['name']! + restaurant['lat']! + restaurant['lng']!;
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await saveFavorites();
    setState(() {});
  }

  bool isFavorite(Map<String, String> restaurant) {
    String id = restaurant['name']! + restaurant['lat']! + restaurant['lng']!;
    return favorites.contains(id);
  }

  Future<void> openMap(String lat, String lng, String name) async {
    final Uri googleMapUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    }
  }

  String getOpenStatus(Map<String, String> restaurant) {
    if (restaurant['open_now'] == null) return '無營業資訊';
    if (restaurant['open_now'] == 'true') return '營業中';
    if (restaurant['open_now'] == 'false') return '休息中';
    return '無營業資訊';
  }

  Future<void> fetchAllRestaurants({double radiusKm = 5, bool onlyShowOpen = true}) async {
    setState(() {
      fullRestaurantList = [];
      currentRoundList = [];
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    final position = await Geolocator.getCurrentPosition();
    double centerLat = position.latitude;
    double centerLng = position.longitude;
    double radius = radiusKm * 1000;
    int points = 8;
    double earthRadius = 6378137;
    Set<String> seen = {};
    List<Map<String, String>> allRestaurants = [];

    for (int i = 0; i < points; i++) {
      double angle = 2 * pi * i / points;
      double dx = radius * cos(angle);
      double dy = radius * sin(angle);
      double deltaLat = dy / earthRadius * (180 / pi);
      double deltaLng = dx / (earthRadius * cos(pi * centerLat / 180)) * (180 / pi);
      double newLat = centerLat + deltaLat;
      double newLng = centerLng + deltaLng;

      String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=$newLat,$newLng&radius=1500&type=restaurant&language=zh-TW&key=$apiKey';

      final response = await http.get(Uri.parse(url));
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

          final name = item['name'] ?? '';
          final lat = item['geometry']?['location']?['lat']?.toString() ?? '';
          final lng = item['geometry']?['location']?['lng']?.toString() ?? '';
          String uniqueId = '$name-$lat-$lng';
          if (!seen.contains(uniqueId)) {
            seen.add(uniqueId);

         // 取出所有 photo_reference
          final photoReferences = item['photos'] != null && item['photos'].isNotEmpty
              ? List<String>.from(item['photos'].map((p) => p['photo_reference']))
              : <String>[];

          // 第一張照片（舊 photoUrl 用於卡片顯示）
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

            allRestaurants.add({
              'name': name,
              'image': photoUrl,
              'lat': lat,
              'lng': lng,
              'distance': distance.toStringAsFixed(0),
              'types': item['types'] != null ? json.encode(item['types']) : json.encode([]),
              'rating': item['rating']?.toString() ?? '',
              'open_now': openNow,
              'photo_references': json.encode(photoReferences),
            });
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }

    setState(() {
      currentLat = centerLat;
      currentLng = centerLng;
      fullRestaurantList = allRestaurants;
      currentRoundList = List.from(allRestaurants);
      currentRoundList.shuffle();
      round = 1;
      liked.clear();
      cardSwiperKey++;
      selectedIndex = 0;
    });
  }

  void handleSwipe(int? previous, int? current, CardSwiperDirection direction) {
    if (previous == null) return;
    final swipedRestaurant = currentRoundList[previous];

    if (direction == CardSwiperDirection.right) {
      liked.add(json.encode(swipedRestaurant));
    }

    if (previous == currentRoundList.length - 1) {
      List<Map<String, String>> nextRoundList = liked.map((e) => Map<String, String>.from(json.decode(e))).toList();
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

  // === 決賽單卡展示元件 ===
  Widget buildFinalistCard() {
    if (currentRoundList.isEmpty) {
      return const Center(child: Text('沒有店家了'));
    }
    final restaurant = currentRoundList[selectedIndex];
    double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
    String distanceText = dist >= 1000
        ? '距離你約 ${(dist / 1000).toStringAsFixed(1)} 公里'
        : '距離你約 ${dist.toStringAsFixed(0)} 公尺';

    List typesList = [];
    if (restaurant['types'] != null) {
      try {
        typesList = json.decode(restaurant['types']!);
      } catch (_) {}
    }
    final String typeText = classifyRestaurant(typesList);
    final String ratingText = restaurant['rating']?.isNotEmpty == true ? restaurant['rating']! : '無';
    final String openStatus = getOpenStatus(restaurant);

    // **修正：這裡外層用 SingleChildScrollView 防爆**
    return SingleChildScrollView(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  restaurant['image']!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  List<String> photoRefs = [];
                  try {
                    photoRefs = restaurant['photo_references'] != null
                        ? List<String>.from(json.decode(restaurant['photo_references']!))
                        : [];
                  } catch (e) {}
                  print('解析 photo_references 發生錯誤: $e');
                  print('photoRefs: $photoRefs');
                  if (photoRefs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("這間店沒有照片")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoPageViewScreen(photoReferences: photoRefs),
                    ),
                  );
                },
                child: const Text("看所有照片"),
              ),
              const SizedBox(height: 8), // 與下方文字留一點間隔

              Text(
                restaurant['name']!,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                restaurant['name']!,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('評分：$ratingText 顆星', style: const TextStyle(fontSize: 16, color: Colors.green)),
              Text(distanceText, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              Text('類型：$typeText', style: const TextStyle(fontSize: 16, color: Colors.orange)),
              Text('目前狀態：$openStatus', style: const TextStyle(fontSize: 16, color: Colors.blue)),
              IconButton(
                icon: Icon(
                  favorites.contains(restaurant['name'])
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    String name = restaurant['name']!;
                    if (favorites.contains(name)) {
                      favorites.remove(name);
                    } else {
                      favorites.add(name);
                    }
                    saveFavorites();
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  openMap(restaurant['lat']!, restaurant['lng']!, restaurant['name']!);
                },
                child: const Text("導航"),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedIndex--;
                        });
                      },
                      child: const Text("上一間"),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("決定結果"),
                          content: Text("你決定吃：\n${restaurant['name']}"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("關閉"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("就吃這間！"),
                  ),
                  const SizedBox(width: 12),
                  if (selectedIndex < currentRoundList.length - 1)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedIndex++;
                        });
                      },
                      child: const Text("下一間"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(round == 1
            ? '可接受 vs 不接受'
            : round == 2
                ? '感興趣 vs 沒興趣'
                : '吃這間決賽模式'),
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
                    ),
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
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text("搜尋範圍："),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: "${searchRadius.toStringAsFixed(1)} 公里",
                    value: searchRadius,
                    onChanged: (value) => setState(() => searchRadius = value),
                    onChangeEnd: (value) => fetchAllRestaurants(
                      radiusKm: value, 
                      onlyShowOpen: onlyShowOpen
                    ),
                  ),
                ),
                Text("${searchRadius.toStringAsFixed(1)} 公里"),
              ],
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
              child: Text(
                '目前定位：$currentLat, $currentLng',
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
            ),
          Expanded(
            child: currentRoundList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : (round < 3
                    ? CardSwiper(
                        key: ValueKey(cardSwiperKey),
                        cardsCount: currentRoundList.length,
                        onSwipe: handleSwipe,
                        cardBuilder: (context, index) {
                          final restaurant = currentRoundList[index];
                          double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
                          String distanceText = dist >= 1000
                              ? '距離你約 ${(dist / 1000).toStringAsFixed(1)} 公里'
                              : '距離你約 ${dist.toStringAsFixed(0)} 公尺';

                          List typesList = [];
                          if (restaurant['types'] != null) {
                            try {
                              typesList = json.decode(restaurant['types']!);
                            } catch (_) {}
                          }
                          final String typeText = classifyRestaurant(typesList);
                          final String ratingText = restaurant['rating']?.isNotEmpty == true ? restaurant['rating']! : '無';
                          final String openStatus = getOpenStatus(restaurant);

                          // 這裡也要包 SingleChildScrollView
                          return SingleChildScrollView(
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        restaurant['image'] ?? '',
                                        height: 220,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      restaurant['name'] ?? '未知餐廳',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '評分：$ratingText 顆星',
                                      style: const TextStyle(fontSize: 16, color: Colors.green),
                                    ),
                                    Text(
                                      distanceText,
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    Text(
                                      '類型：$typeText',
                                      style: const TextStyle(fontSize: 16, color: Colors.orange),
                                    ),
                                    Text(
                                      '目前狀態：$openStatus',
                                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                                    ),
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
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        openMap(
                                          restaurant['lat'] ?? '',
                                          restaurant['lng'] ?? '',
                                          restaurant['name'] ?? '',
                                        );
                                      },
                                      child: const Text("導航"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : buildFinalistCard()
                  ),
          ),
        ],
      ),
    );
  }
}

// ======= 下面是工具 function（class 外面）=======

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * 1000 * asin(sqrt(a));
}

String classifyRestaurant(List types) {
  if (types.contains("cafe")) return "咖啡廳";
  if (types.contains("bar")) return "酒吧";
  if (types.contains("meal_takeaway")) return "外帶";
  if (types.contains("restaurant")) return "餐廳";
  if (types.contains("fast_food")) return "速食店";
  if (types.contains("bakery")) return "早餐店";
  return "未知";
}
