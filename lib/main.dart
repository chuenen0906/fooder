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
import 'package:collection/collection.dart';

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

class _NearbyFoodSwipePageState extends State<NearbyFoodSwipePage> with TickerProviderStateMixin {
  final String apiKey = 'YOUR_API_KEY_HERE'; // Reverted for easier execution
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
  bool isLoading = true;
  bool isSplash = true;
  bool hasMore = true;
  bool showLocation = false;
  Map<int, int> photoPageIndex = {}; // key: 卡片index, value: 圖片index
  String _loadingText = '';

  // 滑動提示文字動畫相關變數
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeOpacityAnimation;
  late Animation<Offset> _swipePositionAnimation;
  late Animation<double> _swipeScaleAnimation;
  bool _showSwipeHint = false;
  String _swipeHintText = '';
  Color _swipeHintColor = Colors.red;
  bool _isSwipingLeft = false;
  Offset? _dragStartPosition;
  // 新增：判斷是否正在觸碰圖片
  bool isTouchingImage = false;
  
  // 新增：Round 1 隨機標題
  String _round1Title = '';
  final List<String> _round1Titles = [
    '找找你附近有什麼好吃的',
    '先來滑一輪附近的美食',
    '別那麼挑好嗎？等等還能篩選',
    '附近這些店想被你發現',
    '那麼多店家 越滑越餓',
    '探索所有店家',
    '有那麼多選擇'
  ];
  
  // 新增：Round 2 隨機標題
  String _round2Title = '';
  final List<String> _round2Titles = [
    '再滑一次 這次認真點！',
    '精選名單來了 這輪你不能亂滑',
    '右滑過的店都來排隊見你了',
    '想吃的再確認一下',
    '右滑你的右滑',
    '挑剔點~不然你還是不知道吃什麼'
  ];

  // 新增：骰子按鈕相關變數
  bool _isRollingDice = false;
  Map<String, String>? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    loadFavorites();
    fetchAllRestaurants(radiusKm: searchRadius);
    
    // 初始化隨機標題
    _updateRound1Title();
    _updateRound2Title();
    
    // 初始化滑動提示文字動畫控制器
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _swipeOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _swipePositionAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _swipeScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
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
    final prefs = await SharedPreferences.getInstance();
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('請開啟定位服務');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('需要定位權限才能尋找附近餐廳');
        }
      }

      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      // Distance and Radius check logic
      final cachedLat = prefs.getDouble('cache_lat');
      final cachedLng = prefs.getDouble('cache_lng');
      final cachedRadius = prefs.getDouble('cache_radius'); // Read cached radius
      final cachedDataString = prefs.getString('restaurant_cache');

      if (cachedLat != null && cachedLng != null && cachedDataString != null && cachedRadius != null) {
        final distance = Geolocator.distanceBetween(cachedLat, cachedLng, currentPosition.latitude, currentPosition.longitude);
        
        // Use cache ONLY if both location and radius are the same
        if (distance < 500 && (radiusKm - cachedRadius).abs() < 0.1) {
          final List<dynamic> decodedData = jsonDecode(cachedDataString);
          final cachedRestaurants = decodedData.map((item) => Map<String, String>.from(item)).toList();
          if(mounted) {
            setState(() {
              fullRestaurantList = cachedRestaurants;
              currentRoundList = List.from(cachedRestaurants)..shuffle();
              isLoading = false;
              isSplash = false;
              _loadingText = '從附近快取載入';
            });
          }
          return; 
        }
      }
      
      List<Map<String, String>> cachedRestaurants = [];
      final cachedTimestamp = prefs.getInt('cache_timestamp');
      if (cachedDataString != null && cachedTimestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - cachedTimestamp < 2 * 60 * 60 * 1000) {
            final List<dynamic> decodedData = jsonDecode(cachedDataString);
            cachedRestaurants = decodedData.map((item) => Map<String, String>.from(item)).toList();
            if (mounted && cachedRestaurants.isNotEmpty) {
              setState(() {
                _loadingText = '顯示快取資料...';
                fullRestaurantList = List.from(cachedRestaurants);
                currentRoundList = List.from(cachedRestaurants)..shuffle();
                isLoading = false;
                isSplash = false;
              });
            }
          }
      }

      if (mounted && cachedRestaurants.isEmpty) {
        setState(() { isLoading = true; _loadingText = '正在更新餐廳列表...'; });
      }

      final newRestaurants = await _fetchFromApi(
        position: currentPosition,
        radiusKm: radiusKm, 
        onlyShowOpen: onlyShowOpen
      );

      final newIds = newRestaurants.map((r) => r['place_id']).toSet();
      final cachedIds = cachedRestaurants.map((r) => r['place_id']).toSet();

      if (!const SetEquality().equals(newIds, cachedIds)) {
        
        List<Map<String, String>> finalList = List.from(newRestaurants);

        // --- NEW FILTERING LOGIC START ---
        final double searchRadiusMeters = radiusKm * 1000;
        finalList = finalList.where((r) {
          double dist = double.parse(r['distance'] ?? '999999');
          return dist <= searchRadiusMeters;
        }).toList();
        // --- NEW FILTERING LOGIC END ---

        // Sorting logic
        if (radiusKm <= 2) {
          finalList.sort((a, b) {
            double distA = double.parse(a['distance'] ?? '99999');
            double distB = double.parse(b['distance'] ?? '99999');
            return distA.compareTo(distB);
          });
        } else {
          finalList.shuffle();
        }

        if (mounted) {
          setState(() {
            fullRestaurantList = finalList; // Use the processed list
            currentRoundList = finalList; // Use the processed list
            round = 1; 
            liked.clear(); 
            cardSwiperKey++;
            isLoading = false; 
            isSplash = false; 
            _loadingText = '';
          });
          // 更新隨機標題
          _updateRound1Title();
        }
        
        // Update cache with new data AND new radius
        await prefs.setString('restaurant_cache', jsonEncode(finalList)); // Use finalList to save sorted/shuffled
        await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setDouble('cache_lat', currentPosition.latitude);
        await prefs.setDouble('cache_lng', currentPosition.longitude);
        await prefs.setDouble('cache_radius', radiusKm); // Save the new radius
      } else {
        if (mounted) {
          setState(() { isLoading = false; _loadingText = ''; });
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isSplash = false;
          _loadingText = '無法載入餐廳: $e';
        });
      }
    }
  }

  Future<List<Map<String, String>>> _fetchFromApi({
    required Position position,
    double radiusKm = 5,
    bool onlyShowOpen = true
  }) async {
    if (mounted) {
      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
        _currentPosition = position;
      });
    }

    double centerLat = position.latitude;
    double centerLng = position.longitude;

    List<String> placeIds = await _getPlaceIdsFromNearbySearch(centerLat, centerLng, radiusKm * 1000, onlyShowOpen);

    List<Future<Map<String, String>?>> detailFutures = [];
    for (final placeId in placeIds) {
      detailFutures.add(_fetchPlaceDetails(placeId, centerLat, centerLng));
    }

    final List<Map<String, String>?> detailedRestaurants = await Future.wait(detailFutures);

    return detailedRestaurants.where((r) => r != null).cast<Map<String, String>>().toList();
  }

  Future<List<String>> _getPlaceIdsFromNearbySearch(double lat, double lng, double radius, bool onlyShowOpen) async {
    List<String> placeIds = [];
    String? nextPageToken;

    do {
      String url;
      if (nextPageToken == null) {
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'location=$lat,$lng&radius=${min(50000.0, radius)}&keyword=food&language=zh-TW&key=$apiKey${onlyShowOpen ? "&opennow=true" : ""}';
      } else {
        // As per Google's requirement, wait before making the next page request.
        await Future.delayed(const Duration(seconds: 2));
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'pagetoken=$nextPageToken&key=$apiKey';
      }

      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'] ?? [];
          for (var item in results) {
            final placeId = item['place_id'] as String?;
            if (placeId != null && !placeIds.contains(placeId)) {
              placeIds.add(placeId);
            }
          }
          nextPageToken = data['next_page_token'] as String?;
        } else {
          nextPageToken = null;
        }
      } catch (e) {
        nextPageToken = null;
      }
    } while (nextPageToken != null && placeIds.length < 60); // Stop if we have enough or no more pages

    return placeIds;
  }

  Future<Map<String, String>?> _fetchPlaceDetails(String placeId, double centerLat, double centerLng) async {
    try {
      const String fields = 'place_id,name,geometry/location,photos,rating,types,opening_hours/open_now,vicinity,user_ratings_total';
      final String detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=$fields&key=$apiKey&language=zh-TW';

      final response = await http.get(Uri.parse(detailsUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = data['result'];

        if (item == null) return null;

        // --- NEW FILTERING LOGIC START ---
        final List<dynamic> types = item['types'] ?? [];
        // 排除 麵包店, 咖啡廳/飲料店, 酒吧
        const List<String> excludedTypes = ['bakery', 'cafe', 'bar']; 
        final bool isExcluded = types.any((type) => excludedTypes.contains(type.toString()));
        if (isExcluded) {
          // 如果是排除的類型，就直接返回 null，這個地點將不會被顯示
          return null; 
        }
        // --- NEW FILTERING LOGIC END ---

        final photoReferences = item['photos'] != null && item['photos'].isNotEmpty
            ? List<String>.from(item['photos'].map((p) => p['photo_reference']))
            : <String>[];
            
        final photoUrls = photoReferences.take(5).map((ref) => 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=$apiKey').toList();

        final photoUrl = photoUrls.isNotEmpty
            ? photoUrls.first
            : 'https://via.placeholder.com/400x300.png?text=No+Image';

        return {
          'name': item['name'] ?? '',
          'image': photoUrl,
          'lat': item['geometry']?['location']?['lat']?.toString() ?? '',
          'lng': item['geometry']?['location']?['lng']?.toString() ?? '',
          'distance': calculateDistance(centerLat, centerLng, item['geometry']['location']['lat'], item['geometry']['location']['lng']).toStringAsFixed(2),
          'types': json.encode(item['types'] ?? []),
          'rating': item['rating']?.toString() ?? 'N/A',
          'open_now': (item['opening_hours']?['open_now']?.toString()) ?? 'unknown',
          'photo_references': json.encode(photoReferences),
          'place_id': item['place_id'] ?? '',
          'photo_urls': json.encode(photoUrls.isNotEmpty ? photoUrls : [photoUrl]),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void handleSwipe(int? previous, int? current, CardSwiperDirection direction) {
    if (previous == null) return;
    final swipedRestaurant = currentRoundList[previous];

    if (direction == CardSwiperDirection.right) {
      liked.add(json.encode(swipedRestaurant));
    }

    handleSwipeUpdate(direction, 1.0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });

    if (previous == currentRoundList.length - 1) {
      List<Map<String, String>> nextRoundList = liked.map((e) => Map<String, String>.from(json.decode(e))).toList();
      
      nextRoundList = nextRoundList.where((restaurant) {
        double distance = double.parse(restaurant['distance'] ?? '0');
        bool isInRange = distance <= searchRadius * 1000;
        return isInRange;
      }).toList();
      
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
        // 如果進入 Round 2，更新 Round 2 隨機標題
        if (round == 2) {
          _updateRound2Title();
        }
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
      return isInRange;
    }).toList();
    
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
      // 如果進入 Round 2，更新 Round 2 隨機標題
      if (round == 2) {
        _updateRound2Title();
      }
    }
  }

  String classifyRestaurant(List types, Map<String, String> restaurant) {
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
    if (name.contains('越南')) {
      return '越南料理';
    }
    final fastFoodKeywords = [
      '麥當勞', '肯德基', 'KFC', '摩斯', 'MOS', '漢堡王', 'Burger King', '必勝客', 'Pizza Hut',
      '達美樂', 'Domino', '拿坡里', 'Napoli', '頂呱呱', '21世紀', 'Subway', '丹丹', '麥味登', '胖老爹', '德克士', '美式漢堡', '炸雞'
    ];
    if (fastFoodKeywords.any((kw) => name.toLowerCase().contains(kw.toLowerCase()))) {
      return '速食餐廳';
    }
    
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
    if (isSplash) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/loading_pig.png',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      );
    }
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
            onPressed: () {
              // 重置輪次狀態
              setState(() {
                round = 1;
                liked.clear();
                cardSwiperKey++;
                selectedIndex = 0;
              });
              // 更新隨機標題
              _updateRound1Title();
              _updateRound2Title();
              // 重新載入餐廳資料
              fetchAllRestaurants(radiusKm: searchRadius);
            },
          ),
          IconButton(
            icon: const Icon(Icons.fast_forward),
            tooltip: "進入下一輪",
            onPressed: enterNextRound,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                          onChangeEnd: (value) {
                            fetchAllRestaurants(
                              radiusKm: value,
                              onlyShowOpen: onlyShowOpen,
                            );
                          },
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
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                      child: Text(
                        '🌀 $_round1Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (round == 2)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        '🔍 $_round2Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (round == 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        '🎯 抉擇吧',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (round == 1)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => showLocation = !showLocation),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: showLocation ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  showLocation ? Icons.location_on : Icons.location_off,
                                  size: 20,
                                  color: showLocation ? Colors.deepPurple : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      showLocation ? '隱藏定位' : '顯示目前定位',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: showLocation ? Colors.deepPurple : Colors.grey[700],
                                      ),
                                    ),
                                    if (showLocation)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          '目前定位：${currentLat?.toStringAsFixed(6) ?? 'N/A'}, ${currentLng?.toStringAsFixed(6) ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                showLocation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: currentRoundList.isEmpty
                    ? Center(child: isLoading ? CircularProgressIndicator() : Text(_loadingText))
                    : round == 3 
                        ? _buildRound3GridView()
                        : _buildSwipeCardView(),
              ),
            ],
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(),
                  ),
                ),
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

  void handleSwipeUpdate(CardSwiperDirection direction, double progress) {
    final isLeft = direction == CardSwiperDirection.left;
    final text = isLeft ? '沒 fu 啦' : '哇想吃！';
    final color = isLeft ? Colors.red : Colors.green;

    if (!_showSwipeHint || _isSwipingLeft != isLeft) {
      setState(() {
        _showSwipeHint = true;
        _swipeHintText = text;
        _swipeHintColor = color;
        _isSwipingLeft = isLeft;
      });
    }

    _swipeAnimationController.value = progress;
  }

  void handleSwipeEnd() {
    if (_dragStartPosition == null) return;
    _dragStartPosition = null;
    if (_showSwipeHint) {
      _swipeAnimationController.reverse().whenComplete(() {
        if (mounted) {
          setState(() {
            _showSwipeHint = false;
          });
        }
      });
    }
  }

  void _updateRound1Title() {
    final random = Random();
    setState(() {
      _round1Title = _round1Titles[random.nextInt(_round1Titles.length)];
    });
  }

  void _updateRound2Title() {
    final random = Random();
    setState(() {
      _round2Title = _round2Titles[random.nextInt(_round2Titles.length)];
    });
  }

  void _rollDice() async {
    if (currentRoundList.isEmpty) return;
    
    setState(() {
      _isRollingDice = true;
    });
    
    // 模擬骰子滾動動畫
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final random = Random();
    final selectedIndex = random.nextInt(currentRoundList.length);
    final selectedRestaurant = currentRoundList[selectedIndex];
    
    setState(() {
      _isRollingDice = false;
      _selectedRestaurant = selectedRestaurant;
    });
    
    // 顯示結果對話框
    if (mounted) {
      _showDiceResultDialog(selectedRestaurant);
    }
  }

  void _showDiceResultDialog(Map<String, String> restaurant) {
    double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
    final String ratingText = restaurant['rating']?.isNotEmpty == true ? restaurant['rating']! : '無';
    
    // 多圖輪播
    List<String> photoUrls = [];
    if (restaurant['photo_urls'] != null) {
      try {
        photoUrls = List<String>.from(json.decode(restaurant['photo_urls']!));
      } catch (_) {}
    }
    if (photoUrls.isEmpty) {
      photoUrls = ['https://via.placeholder.com/400x300.png?text=No+Image'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題
                Row(
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Text(
                      '骰子選擇結果',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 餐廳圖片
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: photoUrls.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      height: 150,
                      child: const Center(child: Icon(Icons.error, color: Colors.red)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 餐廳名稱
                Text(
                  restaurant['name'] ?? '未知餐廳',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 評分和距離
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      ratingText,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.place, color: Colors.blueGrey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      dist >= 1000
                          ? '${(dist / 1000).toStringAsFixed(1).replaceAll('.0', '')} km'
                          : '${dist.toStringAsFixed(0)} m',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 按鈕
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          openMap(
                            restaurant['lat'] ?? '',
                            restaurant['lng'] ?? '',
                            restaurant['name'] ?? '',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('導航到這裡'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rollDice(); // 重新骰子
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('再骰一次'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRound3GridView() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentRoundList.length,
            itemBuilder: (context, index) {
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
              
              // 多圖輪播
              List<String> photoUrls = [];
              if (restaurant['photo_urls'] != null) {
                try {
                  photoUrls = List<String>.from(json.decode(restaurant['photo_urls']!));
                } catch (_) {}
              }
              if (photoUrls.isEmpty) {
                photoUrls = ['https://via.placeholder.com/400x300.png?text=No+Image'];
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          restaurant: restaurant,
                          favorites: favorites,
                          onToggleFavorite: (String name) {
                            setState(() {
                              if (favorites.contains(name)) {
                                favorites.remove(name);
                              } else {
                                favorites.add(name);
                              }
                              saveFavorites();
                            });
                          },
                          classifyRestaurant: classifyRestaurant,
                          getOpenStatus: getOpenStatus,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 圖片區域
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: photoUrls.first,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: Icon(Icons.error, color: Colors.red)),
                                ),
                              ),
                            ),
                            // 營業狀態
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  openStatus,
                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ),
                            // 收藏按鈕
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    favorites.contains(restaurant['name'] ?? '')
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 資訊區域
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 餐廳名稱
                              Text(
                                restaurant['name'] ?? '未知餐廳',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // 評分和距離
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    ratingText,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.place, color: Colors.blueGrey, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    dist >= 1000
                                        ? '${(dist / 1000).toStringAsFixed(1).replaceAll('.0', '')}km'
                                        : '${dist.toStringAsFixed(0)} m',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // 餐廳類型
                              Text(
                                typeText,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 浮動骰子按鈕
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _isRollingDice ? null : _rollDice,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            child: _isRollingDice
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '🎲',
                    style: TextStyle(fontSize: 24),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCardView() {
    return Stack(
      children: [
        GestureDetector(
          onPanStart: (details) {
             _dragStartPosition = details.localPosition;
          },
          onPanUpdate: (details) {
             if (_dragStartPosition == null) return;
             if (isTouchingImage) return;
             final screenWidth = MediaQuery.of(context).size.width;
             final dx = details.localPosition.dx - _dragStartPosition!.dx;
             final progress = (dx.abs() / (screenWidth / 4)).clamp(0.0, 1.0);
             const threshold = 10.0;
             if (dx < -threshold) {
               handleSwipeUpdate(CardSwiperDirection.left, progress);
             } else if (dx > threshold) {
               handleSwipeUpdate(CardSwiperDirection.right, progress);
             } else {
               if (_showSwipeHint) {
                 _swipeAnimationController.reverse();
               }
             }
          },
          onPanEnd: (_) {
            handleSwipeEnd();
          },
          onPanCancel: () {
            handleSwipeEnd();
          },
          child: CardSwiper(
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
              // 多圖輪播
              List<String> photoUrls = [];
              if (restaurant['photo_urls'] != null) {
                try {
                  photoUrls = List<String>.from(json.decode(restaurant['photo_urls']!));
                } catch (_) {}
              }
              if (photoUrls.isEmpty) {
                photoUrls = ['https://via.placeholder.com/400x300.png?text=No+Image'];
              }
              int currentPhotoIndex = photoPageIndex[index] ?? 0;
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
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            // GestureDetector 包裹圖片區域
                            GestureDetector(
                              onPanDown: (_) {
                                setState(() {
                                  isTouchingImage = true;
                                });
                              },
                              onPanEnd: (_) {
                                setState(() {
                                  isTouchingImage = false;
                                });
                              },
                              onPanCancel: () {
                                setState(() {
                                  isTouchingImage = false;
                                });
                              },
                              child: PageView.builder(
                                itemCount: photoUrls.length,
                                controller: PageController(initialPage: currentPhotoIndex),
                                onPageChanged: (idx) {
                                  setState(() {
                                    photoPageIndex[index] = idx;
                                  });
                                },
                                itemBuilder: (context, idx) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrls[idx],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        height: 200,
                                        child: const Center(child: Icon(Icons.error, color: Colors.red)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 指示條
                            if (photoUrls.length > 1)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(photoUrls.length, (dotIdx) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: currentPhotoIndex == dotIdx ? Colors.white : Colors.white54,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black12),
                                    ),
                                  )),
                                ),
                              ),
                            // 餐廳名稱與營業狀態
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
                                      restaurant['name'] ?? '未知餐廳',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      openStatus,
                                      style: const TextStyle(fontSize: 18, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 新增：卡片下方資訊區包 GestureDetector
                      GestureDetector(
                        onPanStart: (details) {
                          _dragStartPosition = details.localPosition;
                        },
                        onPanUpdate: (details) {
                          if (_dragStartPosition == null) return;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final dx = details.localPosition.dx - _dragStartPosition!.dx;
                          final progress = (dx.abs() / (screenWidth / 4)).clamp(0.0, 1.0);
                          const threshold = 10.0;
                          if (dx < -threshold) {
                            handleSwipeUpdate(CardSwiperDirection.left, progress);
                          } else if (dx > threshold) {
                            handleSwipeUpdate(CardSwiperDirection.right, progress);
                          } else {
                            if (_showSwipeHint) {
                              _swipeAnimationController.reverse();
                            }
                          }
                        },
                        onPanEnd: (_) {
                          handleSwipeEnd();
                        },
                        onPanCancel: () {
                          handleSwipeEnd();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      ? '${(dist / 1000).toStringAsFixed(1).replaceAll('.0', '')} km (直線)'
                                      : '${dist.toStringAsFixed(0)} m (直線)',
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
                                    favorites.contains(restaurant['name'] ?? '')
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    // 這裡需要一個回調來更新收藏狀態
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 滑動提示文字
        if (_showSwipeHint)
          AnimatedBuilder(
            animation: _swipeAnimationController,
            builder: (context, child) {
              return Positioned(
                top: 20,
                left: _isSwipingLeft ? 20 : null,
                right: !_isSwipingLeft ? 20 : null,
                child: SlideTransition(
                  position: _swipePositionAnimation,
                  child: FadeTransition(
                    opacity: _swipeOpacityAnimation,
                    child: ScaleTransition(
                      scale: _swipeScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _swipeHintColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _swipeHintText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

class RestaurantDetailPage extends StatelessWidget {
  final Map<String, String> restaurant;
  final Set<String> favorites;
  final Function(String) onToggleFavorite;
  final Function(List, Map<String, String>) classifyRestaurant;
  final Function(Map<String, String>) getOpenStatus;
  
  const RestaurantDetailPage({
    super.key, 
    required this.restaurant,
    required this.favorites,
    required this.onToggleFavorite,
    required this.classifyRestaurant,
    required this.getOpenStatus,
  });

  @override
  Widget build(BuildContext context) {
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
    
    // 多圖輪播
    List<String> photoUrls = [];
    if (restaurant['photo_urls'] != null) {
      try {
        photoUrls = List<String>.from(json.decode(restaurant['photo_urls']!));
      } catch (_) {}
    }
    if (photoUrls.isEmpty) {
      photoUrls = ['https://via.placeholder.com/400x300.png?text=No+Image'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant['name'] ?? '餐廳詳情'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              favorites.contains(restaurant['name'] ?? '')
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () {
              onToggleFavorite(restaurant['name'] ?? '');
            },
          ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圖片輪播
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: photoUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: photoUrls[index],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      height: 250,
                      child: const Center(child: Icon(Icons.error, color: Colors.red)),
                    ),
                  );
                },
              ),
            ),
            // 餐廳資訊
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'] ?? '未知餐廳',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        openStatus,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                            ? '${(dist / 1000).toStringAsFixed(1).replaceAll('.0', '')} km (直線)'
                            : '${dist.toStringAsFixed(0)} m (直線)',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    typeText,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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