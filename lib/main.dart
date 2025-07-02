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
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/restaurant_json_service.dart';
import 'services/user_id_service.dart';
import 'services/log_service.dart';
import 'services/place_details_cache_service.dart';

void main() async {
  await dotenv.load();
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
  final String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? ''; // 已更新 API key
  
  // 新增：用戶 ID 相關變數
  String? _currentUserId;
  bool _isCheckingUserId = true;
  
  List<Map<String, dynamic>> fullRestaurantList = [];
  List<Map<String, dynamic>> currentRoundList = [];
  final List<String> liked = [];
  final Set<String> favorites = {};
  int round = 1;
  int cardSwiperKey = 0;
  int selectedIndex = 0;
  double? currentLat;
  double? currentLng;
  double searchRadius = 2.0; // 改為預設 2 公里
  bool onlyShowOpen = true;
  Position? _currentPosition;
  bool isLoading = true;
  bool isSplash = true;
  bool hasMore = true;
  Map<int, int> photoPageIndex = {}; // key: 卡片index, value: 圖片index
  String _loadingText = '';

  // API 使用量追蹤變數
  int nearbySearchCount = 0;
  int placeDetailsCount = 0;
  int photoRequestCount = 0;

  // 新增：API 請求防重複機制
  Set<String> _pendingApiRequests = {};
  Map<String, DateTime> _lastApiCallTime = {};
  final Duration _apiCooldown = Duration(seconds: 2); // API 冷卻時間

  // 新增：照片 URL 快取
  Map<String, List<String>> _photoUrlCache = {};
  final String _photoUrlCacheKey = 'photo_url_cache';
  
  // 新增：API 請求限制
  final int _maxApiCallsPerMinute = 50; // 每分鐘最多 50 次 API 呼叫
  int get _maxApiCallsPerDay => _disablePhotosForTesting ? 500 : 150; // 開發者模式500，使用者模式150
  int _apiCallsThisMinute = 0;
  int _apiCallsToday = 0;
  DateTime _lastMinuteReset = DateTime.now();

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
  Map<String, dynamic>? _selectedRestaurant;

  // 快取關鍵字搜尋結果
  Map<String, List<String>> _keywordCache = {};
  String _lastKeywordCacheKey = '';
  
  // 照片快取
  Map<String, dynamic> _photoCache = {};
  
  // Place Details 獨立快取
  Map<String, dynamic> _placeDetailsCache = {};
  final String _placeDetailsCacheKey = 'place_details_cache';
  // 移除重複宣告，使用智慧快取策略中的 _maxCacheSize
  
  // API 成本監控
  int _apiCallCount = 0;
  double _estimatedCost = 0.0;
  
  // 防抖機制
  Timer? _debounceTimer;
  bool _isFetching = false;

  // 新增：API 使用量顯示
  bool showApiUsage = false;
  
  // 新增：快取統計變數
  Map<String, dynamic> _cacheStats = {'total_entries': 0, 'oldest_entry': null};

  // 新增：開發模式開關 - 關閉照片載入以節省 API 用量
  bool _disablePhotosForTesting = false; // 設為 false 為使用者模式（開啟照片載入）
  
  // 新增：可調整的餐廳搜尋數量
  int _targetRestaurantCount = 20; // 使用者模式：每次搜尋 20 家
  // TODO: 給朋友使用時改為 15-20 間餐廳
  
  // 新增：快取優化設定
  final int _cacheExpirationHours = 24; // 延長快取時間到24小時
  final int _locationCacheDistance = 1000; // 位置快取距離增加到1公里

  // 新增：智慧快取策略
  Map<String, int> _restaurantAccessCount = {}; // 記錄餐廳被訪問次數
  final int _maxCacheSize = 100; // 增加快取大小到100筆
  
  // 新增：快取優先級管理
  void _updateRestaurantAccessCount(String placeId) {
    _restaurantAccessCount[placeId] = (_restaurantAccessCount[placeId] ?? 0) + 1;
  }
  
  // 新增：智慧快取清理
  void _smartCacheCleanup() {
    if (_placeDetailsCache.length > _maxCacheSize) {
      // 根據訪問次數排序，保留最受歡迎的餐廳
      final sortedEntries = _placeDetailsCache.entries.toList()
        ..sort((a, b) {
          final aCount = _restaurantAccessCount[a.key] ?? 0;
          final bCount = _restaurantAccessCount[b.key] ?? 0;
          return bCount.compareTo(aCount); // 降序排列
        });
      
      // 移除最不受歡迎的餐廳
      final toRemove = sortedEntries.skip(_maxCacheSize).map((e) => e.key).toList();
      for (final placeId in toRemove) {
        _placeDetailsCache.remove(placeId);
        _restaurantAccessCount.remove(placeId);
      }
      
      print('🧹 Smart cache cleanup: removed ${toRemove.length} unpopular restaurants');
    }
  }

  // 新增：批次處理機制
  final List<String> _batchPlaceDetailsQueue = [];
  Timer? _batchProcessingTimer;
  final Duration _batchProcessingDelay = Duration(milliseconds: 500);
  
  // 新增：批次處理 Place Details
  void _addToBatchQueue(String placeId) {
    // 在 JSON 模式下跳過 Place Details 請求
    if (useJson) {
      print("🚫 Place Details 批次請求已跳過（JSON 模式）: $placeId");
      return;
    }
    
    if (!_batchPlaceDetailsQueue.contains(placeId)) {
      _batchPlaceDetailsQueue.add(placeId);
    }
    
    // 重置計時器
    _batchProcessingTimer?.cancel();
    _batchProcessingTimer = Timer(_batchProcessingDelay, () {
      _processBatchQueue();
    });
  }
  
  Future<void> _processBatchQueue() async {
    // 在 JSON 模式下跳過 Place Details 請求
    if (useJson) {
      print("🚫 Place Details 請求已跳過（JSON 模式）");
      return;
    }
    
    if (_batchPlaceDetailsQueue.isEmpty) return;
    
    final placeIds = List<String>.from(_batchPlaceDetailsQueue);
    _batchPlaceDetailsQueue.clear();
    
    print("🔄 Processing batch of ${placeIds.length} place details requests");
    
    // 批次處理，但每個請求之間有短暫延遲以避免超出限制
    for (int i = 0; i < placeIds.length; i++) {
      final placeId = placeIds[i];
      if (!_placeDetailsCache.containsKey(placeId)) {
        await _fetchPlaceDetails(placeId, currentLat ?? 0, currentLng ?? 0);
        // 每個請求之間等待 100ms
        if (i < placeIds.length - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    }
  }

  bool useJson = false; // 新增：資料來源切換

  // 3. 新增每日 API 請求上限
  final int _maxApiRequestsPerDay = 150;
  int _apiRequestsToday = 0;

  Future<void> _loadApiRequestsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _apiRequestsToday = prefs.getInt('api_requests_today_$today') ?? 0;
  }

  Future<void> _incrementApiRequestsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _apiRequestsToday++;
    await prefs.setInt('api_requests_today_$today', _apiRequestsToday);
  }

  bool _canSearchToday() {
    return _apiRequestsToday < _maxApiRequestsPerDay;
  }

  @override
  void initState() {
    super.initState();
    
    // 新增：檢查用戶 ID
    _checkAndSetupUserId();
    
    _loadApiRequestsToday();
    _loadApiUsageStats();
    
    // 新增：載入快取統計
    _loadCacheStats();
    
    if (useJson) {
      loadJsonData();
    } else {
      fetchAllRestaurants(radiusKm: searchRadius, onlyShowOpen: true);
    }
    loadFavorites();
    
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

    _loadPlaceDetailsCache(); // 讀取 Place Details 快取
    _loadPhotoUrlCache(); // 讀取照片 URL 快取
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _titleTapTimer?.cancel();
    super.dispose();
  }

  // 新增：用戶 ID 相關方法
  Future<void> _checkAndSetupUserId() async {
    final userId = await UserIdService.getUserId();
    final isFirstLaunch = await UserIdService.isFirstLaunch();
    
    if (userId != null) {
      // 已有用戶 ID，直接使用
      setState(() {
        _currentUserId = userId;
        _isCheckingUserId = false;
      });
      print('👤 使用現有用戶 ID: $userId');
    } else if (isFirstLaunch) {
      // 首次啟動，顯示暱稱輸入對話框
      _showNicknameDialog();
    } else {
      // 非首次啟動但沒有用戶 ID，生成預設 ID
      final defaultUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await UserIdService.setUserId(defaultUserId);
      setState(() {
        _currentUserId = defaultUserId;
        _isCheckingUserId = false;
      });
      print('👤 生成預設用戶 ID: $defaultUserId');
    }
  }

  void _showNicknameDialog() {
    final TextEditingController nicknameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, // 不允許點擊外部關閉
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('歡迎使用 Fooder！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('請輸入你的暱稱，方便我們為你提供更好的服務：'),
              const SizedBox(height: 16),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: '暱稱',
                  hintText: '例如：小明、阿傑',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) => _saveNickname(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _saveNickname(nicknameController.text),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNickname(String nickname) async {
    if (nickname.trim().isEmpty) {
      nickname = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    await UserIdService.setUserId(nickname.trim());
    await UserIdService.markAsNotFirstLaunch();
    
    setState(() {
      _currentUserId = nickname.trim();
      _isCheckingUserId = false;
    });
    
    // 關閉對話框
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    print('👤 設定用戶暱稱: ${nickname.trim()}');
  }

  // API 使用量摘要打印函數
  void printApiSummary() {
    print("🔢 API Usage Summary:");
    print("- Nearby Search: $nearbySearchCount times");
    print("- Place Details: $placeDetailsCount times");
    print("- Place Photos: $photoRequestCount times");
    print("- API calls this minute: $_apiCallsThisMinute");
    print("- API calls today: $_apiCallsToday");
  }

  // 新增：API 使用統計管理
  Future<void> _loadApiUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    nearbySearchCount = prefs.getInt('nearbySearchCount_$today') ?? 0;
    placeDetailsCount = prefs.getInt('placeDetailsCount_$today') ?? 0;
    photoRequestCount = prefs.getInt('photoRequestCount_$today') ?? 0;
  }

  // 新增：載入快取統計
  Future<void> _loadCacheStats() async {
    try {
      final stats = await PlaceDetailsCacheService.getCacheStats();
      setState(() {
        _cacheStats = stats;
      });
      print('📊 快取統計: ${stats['total_entries']} 筆資料');
    } catch (e) {
      print('❌ 載入快取統計失敗: $e');
    }
  }

  Future<void> _incrementNearbySearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    nearbySearchCount++;
    await prefs.setInt('nearbySearchCount_$today', nearbySearchCount);
    _updateLastFetchTotal();
    
    // 新增：記錄到 Google Sheets
    if (_currentUserId != null) {
      await LogService.logUserAction(_currentUserId!, 'nearby_search');
    }
  }
  Future<void> _incrementPlaceDetailsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    placeDetailsCount++;
    await prefs.setInt('placeDetailsCount_$today', placeDetailsCount);
    _updateLastFetchTotal();
    
    // 新增：記錄到 Google Sheets
    if (_currentUserId != null) {
      await LogService.logUserAction(_currentUserId!, 'place_details');
    }
  }
  Future<void> _incrementPhotoRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    photoRequestCount++;
    await prefs.setInt('photoRequestCount_$today', photoRequestCount);
    _updateLastFetchTotal();
    
    // 新增：記錄到 Google Sheets
    if (_currentUserId != null) {
      await LogService.logUserAction(_currentUserId!, 'place_photos');
    }
  }

  Future<void> _incrementApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    _apiCallsToday++;
    _apiCallsThisMinute++;
    
    await prefs.setInt('api_calls_$today', _apiCallsToday);
    await prefs.setInt('api_calls_minute_$today', _apiCallsThisMinute);
  }

  // 新增：API 請求限制檢查
  bool _canMakeApiCall() {
    if (_apiCallsThisMinute >= _maxApiCallsPerMinute) {
      print("⚠️ API rate limit exceeded: $_apiCallsThisMinute calls this minute");
      return false;
    }
    if (_apiCallsToday >= _maxApiCallsPerDay) {
      print("⚠️ Daily API limit exceeded: $_apiCallsToday calls today");
      return false;
    }
    return true;
  }

  // 新增：照片 URL 快取管理
  Future<void> _loadPhotoUrlCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_photoUrlCacheKey);
    if (cachedData != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(cachedData);
        _photoUrlCache = decoded.map((key, value) => 
          MapEntry(key, List<String>.from(value)));
      } catch (e) {
        print('Error loading photo URL cache: $e');
      }
    }
  }

  Future<void> _savePhotoUrlCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoUrlCacheKey, json.encode(_photoUrlCache));
  }

  // 新增：防重複 API 請求檢查
  bool _isApiRequestPending(String requestKey) {
    return _pendingApiRequests.contains(requestKey);
  }

  void _addPendingRequest(String requestKey) {
    _pendingApiRequests.add(requestKey);
  }

  void _removePendingRequest(String requestKey) {
    _pendingApiRequests.remove(requestKey);
  }

  // 新增：API 冷卻時間檢查
  bool _canMakeApiCallAfterCooldown(String requestKey) {
    final lastCall = _lastApiCallTime[requestKey];
    if (lastCall == null) return true;
    
    return DateTime.now().difference(lastCall) >= _apiCooldown;
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

  Future<bool> canSearchToday() async {
    return true;
  }

  Future<void> incrementSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'search_count_$today';

    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  Future<int> getTodaySearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'search_count_$today';
    return prefs.getInt(key) ?? 0;
  }

  Future<void> fetchAllRestaurants({double radiusKm = 5, bool onlyShowOpen = true}) async {
    if (!_canSearchToday()) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isSplash = false;
          _loadingText = '今日 API 請求已達上限，請明天再試';
        });
      }
      return;
    }
    await _incrementApiRequestsToday();
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

      Position currentPosition;
      try {
        // 優先嘗試高精度定位，並延長等待時間
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // 如果失敗，自動降級為中等精度，確保能取得位置
        print("⚠️ High accuracy location failed, falling back to medium accuracy. Error: $e");
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      }
      
      // Distance and Radius check logic
      final cachedLat = prefs.getDouble('cache_lat');
      final cachedLng = prefs.getDouble('cache_lng');
      final cachedRadius = prefs.getDouble('cache_radius'); // Read cached radius
      final cachedDataString = prefs.getString('restaurant_cache');

      if (cachedLat != null && cachedLng != null && cachedDataString != null && cachedRadius != null) {
        final distance = Geolocator.distanceBetween(cachedLat, cachedLng, currentPosition.latitude, currentPosition.longitude);
        
        // 使用快取：位置距離 < 1公里 且 搜尋半徑相同
        if (distance < _locationCacheDistance && (radiusKm - cachedRadius).abs() < 0.1) {
          print("📦 Using nearby cache (distance: ${distance.toStringAsFixed(0)}m, radius: $radiusKm km)");
          final List<dynamic> decodedData = jsonDecode(cachedDataString);
          final cachedRestaurants = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
          // 新增：強制重新計算每家餐廳的距離
          for (var r in cachedRestaurants) {
            double reCalculatedDistance = calculateDistance(
              currentPosition.latitude,
              currentPosition.longitude,
              double.tryParse(r['lat'] ?? '0') ?? 0,
              double.tryParse(r['lng'] ?? '0') ?? 0,
            );
            r['distance'] = reCalculatedDistance.toStringAsFixed(0);
          }
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
      
      List<Map<String, dynamic>> cachedRestaurants = [];
      final cachedTimestamp = prefs.getInt('cache_timestamp');
      if (cachedDataString != null && cachedTimestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // 延長快取時間到 24 小時，大幅減少 API 請求
          // 但是搜尋半徑改變時不使用快取
          if (now - cachedTimestamp < _cacheExpirationHours * 60 * 60 * 1000 && 
              (cachedRadius == null || (radiusKm - cachedRadius).abs() < 0.1)) {
            print("📦 Using time cache (${((now - cachedTimestamp) / (60 * 60 * 1000)).toStringAsFixed(1)} hours old)");
            final List<dynamic> decodedData = jsonDecode(cachedDataString);
            cachedRestaurants = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
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

      // 檢查是否需要進行 API 呼叫
      bool needApiCall = cachedRestaurants.isEmpty;
      
      // 如果搜尋半徑改變，檢查快取資料是否足夠
      if (cachedRadius != null && (radiusKm - cachedRadius).abs() >= 0.1) {
        // 如果快取中有足夠的餐廳資料（至少 20 家），只進行過濾
        if (cachedRestaurants.length >= 20) {
          print("🔄 Search radius changed from ${cachedRadius}km to ${radiusKm}km, filtering cached data (${cachedRestaurants.length} restaurants)");
          needApiCall = false;
          
          // 直接過濾快取資料
          final double searchRadiusMeters = radiusKm * 1000;
          final filteredRestaurants = cachedRestaurants.where((r) {
            double reCalculatedDistance = calculateDistance(
              currentPosition.latitude, 
              currentPosition.longitude, 
              double.parse(r['lat'] ?? '0'), 
              double.parse(r['lng'] ?? '0')
            );
            r['distance'] = reCalculatedDistance.toStringAsFixed(0);
            return reCalculatedDistance <= searchRadiusMeters;
          }).toList();
          
          // 排序
          filteredRestaurants.sort((a, b) =>
              (double.parse(a['distance'] ?? '999999'))
                  .compareTo(double.parse(b['distance'] ?? '999999')));
          
          if (mounted) {
            setState(() {
              fullRestaurantList = filteredRestaurants;
              currentRoundList = List.from(filteredRestaurants)..shuffle();
              round = 1;
              liked.clear();
              cardSwiperKey++;
              isLoading = false;
              isSplash = false;
              if (filteredRestaurants.isEmpty) {
                _loadingText = onlyShowOpen
                  ? '這個範圍內找不到營業中的餐廳耶 🥲\n試試看關閉「只顯示營業中」或擴大範圍吧！'
                  : '這個範圍內找不到任何餐廳耶 🥲\n再擴大一點搜尋範圍試試看吧！';
              } else {
                _loadingText = '';
              }
            });
            // 更新隨機標題
            _updateRound1Title();
            
            // 新增：預載入熱門餐廳詳細資料
            _preloadPopularRestaurants();
            
            // 新增：檢查 API 使用量並發出警告
            _checkApiUsageAndWarn();
          }
          
          // 更新快取中的搜尋半徑
          await prefs.setDouble('cache_radius', radiusKm);
          return; // 直接返回，不進行 API 呼叫
        } else {
          print("🔄 Search radius changed from ${cachedRadius}km to ${radiusKm}km, but cached data insufficient (${cachedRestaurants.length} restaurants), making API call");
          needApiCall = true;
        }
      }
      
      // 如果需要進行 API 呼叫，增加搜尋計數
      if (needApiCall) {
        if (mounted) {
          setState(() { isLoading = true; _loadingText = '正在更新餐廳列表...'; });
        }
      }

      final newRestaurants = await _fetchFromApi(
        position: currentPosition,
        radiusKm: radiusKm, 
        onlyShowOpen: onlyShowOpen
      );

      final newIds = newRestaurants.map((r) => r['place_id']).toSet();
      final cachedIds = cachedRestaurants.map((r) => r['place_id']).toSet();

      // 【修正】無論資料來源，都使用完整的列表進行最終處理
      List<Map<String, dynamic>> finalList = List.from(newRestaurants);

      // --- 嚴格的距離過濾 ---
      final double searchRadiusMeters = radiusKm * 1000;
      finalList = finalList.where((r) {
        // 每家餐廳都重新計算距離，確保準確性
        double reCalculatedDistance = calculateDistance(
          currentPosition.latitude, 
          currentPosition.longitude, 
          double.parse(r['lat'] ?? '0'), 
          double.parse(r['lng'] ?? '0')
        );
        r['distance'] = reCalculatedDistance.toStringAsFixed(0);
        
        // 新增除錯資訊
        if (finalList.length <= 3) { // 只顯示前3家的除錯資訊
          print("📍 ${r['name']}: ${reCalculatedDistance.toStringAsFixed(0)}m (${(reCalculatedDistance/1000).toStringAsFixed(2)}km)");
        }
        
        return reCalculatedDistance <= searchRadiusMeters;
      }).toList();

      print("ℹ️ Found ${newRestaurants.length} potential restaurants, ${finalList.length} remaining after strict distance filtering.");

      // Sorting logic
      finalList.sort((a, b) =>
          (double.parse(a['distance'] ?? '999999'))
              .compareTo(double.parse(b['distance'] ?? '999999')));

      if (mounted) {
        setState(() {
          fullRestaurantList = finalList;
          currentRoundList = List.from(finalList)..shuffle();
          round = 1;
          liked.clear();
          cardSwiperKey++;
          isLoading = false;
          isSplash = false;
          if (finalList.isEmpty) {
            _loadingText = onlyShowOpen
              ? '這個範圍內找不到營業中的餐廳耶 🥲\n試試看關閉「只顯示營業中」或擴大範圍吧！'
              : '這個範圍內找不到任何餐廳耶 🥲\n再擴大一點搜尋範圍試試看吧！';
          } else {
            _loadingText = '';
          }
        });
        // 更新隨機標題
        _updateRound1Title();
        
        // 新增：預載入熱門餐廳詳細資料
        _preloadPopularRestaurants();
        
        // 新增：檢查 API 使用量並發出警告
        _checkApiUsageAndWarn();
      }
      
      // 如果是新的搜尋結果，更新快取
      if (!const SetEquality().equals(newIds, cachedIds)) {
        await prefs.setString('restaurant_cache', jsonEncode(finalList));
        await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setDouble('cache_lat', currentPosition.latitude);
        await prefs.setDouble('cache_lng', currentPosition.longitude);
        await prefs.setDouble('cache_radius', radiusKm); // Save the new radius
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

  Future<List<Map<String, dynamic>>> _fetchFromApi({
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

    // 只取 Nearby Search 實際回傳的 placeIds
    List<String> placeIds = await _getPlaceIdsFromNearbySearch(centerLat, centerLng, radiusKm * 1000, onlyShowOpen);

    // 只對實際回傳的 placeIds 發送 Details/Photo 請求
    List<Future<Map<String, dynamic>?>> detailFutures = [];
    for (final placeId in placeIds) {
      if (_placeDetailsCache.containsKey(placeId)) {
        final cachedJson = _placeDetailsCache[placeId]!;
        final Map<String, dynamic> decodedDetails = json.decode(cachedJson);
        detailFutures.add(Future.value(decodedDetails));
      } else {
        detailFutures.add(_fetchPlaceDetails(placeId, centerLat, centerLng));
      }
    }

    final List<Map<String, dynamic>?> detailedRestaurants = await Future.wait(detailFutures);

    // 過濾掉 null
    return detailedRestaurants.where((r) => r != null).cast<Map<String, dynamic>>().toList();
  }

  Future<List<String>> _getPlaceIdsFromNearbySearch(double lat, double lng, double radius, bool onlyShowOpen) async {
    List<String> placeIds = [];
    String? nextPageToken;
    final int targetCount = _targetRestaurantCount; // 使用可調整的目標數量

    do {
      // 檢查 API 限制
      if (!_canMakeApiCall()) {
        print("🚫 API call blocked due to rate limiting");
        break;
      }

      String url;
      if (nextPageToken == null) {
        await _incrementNearbySearchCount();
        print("📡 發送 Nearby Search，座標: $lat,$lng，半徑: $radius");
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'location=$lat,$lng&radius=${min(50000.0, radius)}&keyword=小吃|攤販|夜市|food&language=zh-TW&key=$apiKey${onlyShowOpen ? "&opennow=true" : ""}';
      } else {
        // As per Google's requirement, wait before making the next page request.
        await Future.delayed(const Duration(seconds: 2));
        await _incrementNearbySearchCount();
        print("📡 Nearby Search called: $nearbySearchCount times");
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
            'pagetoken=$nextPageToken&key=$apiKey';
      }

      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'] ?? [];
          if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
            // 如果狀態不是 OK 或 ZERO_RESULTS，則拋出包含伺服器錯誤訊息的異常
            throw Exception('Google API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          }
          for (var item in results) {
            final placeId = item['place_id'] as String?;
            if (placeId != null && !placeIds.contains(placeId)) {
              placeIds.add(placeId);
              // 一旦達到目標數量就停止
              if (placeIds.length >= targetCount) {
                print("✅ Found target count of $targetCount restaurants, stopping search");
                break;
              }
            }
          }
          nextPageToken = data['next_page_token'] as String?;
          
          // 如果已經達到目標數量，不需要繼續搜尋
          if (placeIds.length >= targetCount) {
            nextPageToken = null;
          }
        } else {
          // 如果 HTTP 狀態碼不是 200，拋出異常
          throw Exception('Failed to load places, status code: ${response.statusCode}');
        }
      } catch (e) {
        // 捕獲異常後，直接重新拋出，讓上層處理
        rethrow;
      }
    } while (nextPageToken != null && placeIds.length < targetCount); // 修改條件：只搜尋到目標數量

    print("📊 Nearby Search completed: found ${placeIds.length} restaurants");
    return placeIds;
  }

  Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeId, double centerLat, double centerLng) async {
    // 在 JSON 模式下跳過 Place Details 請求
    if (useJson) {
      print("🚫 Place Details API 請求已跳過（JSON 模式）: $placeId");
      return null;
    }
    
    // 檢查 API 限制
    if (!_canMakeApiCall()) {
      print("🚫 Place Details API call blocked due to rate limiting for $placeId");
      return null;
    }

    // 1. 優先從 SQLite 快取讀取
    try {
      final cachedData = await PlaceDetailsCacheService.getPlaceDetails(placeId);
      if (cachedData != null) {
        print('✅ 從 SQLite 快取獲取: $placeId');
        final Map<String, dynamic> decodedDetails = json.decode(cachedData);
        return decodedDetails;
      }
    } catch (e) {
      print('❌ SQLite 快取讀取失敗: $e');
    }

    // 2. 從記憶體快取讀取
    if (_placeDetailsCache.containsKey(placeId)) {
      print('✅ 從記憶體快取獲取: $placeId');
      _updateRestaurantAccessCount(placeId); // 更新訪問次數
      final cachedJson = _placeDetailsCache[placeId]!;
      final Map<String, dynamic> decodedDetails = json.decode(cachedJson);
      return decodedDetails;
    }

    // 3. 檢查是否正在請求中
    if (_isApiRequestPending(placeId)) {
      print('⏳ Place details request already pending for $placeId');
      return null;
    }

    // 4. 檢查冷卻時間
    if (!_canMakeApiCallAfterCooldown(placeId)) {
      print('⏰ Place details request in cooldown for $placeId');
      return null;
    }

    // 5. 如果快取沒有，才從 API 獲取
    try {
      _addPendingRequest(placeId);
      _lastApiCallTime[placeId] = DateTime.now();
      
      await _incrementPlaceDetailsCount();
      print("📍 發送 Place Details，placeId: $placeId");
      
      const String fields = 'place_id,name,geometry/location,photos,rating,types,opening_hours/open_now,vicinity,formatted_address';
      final String detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=$fields&key=$apiKey&language=zh-TW';

      final response = await http.get(Uri.parse(detailsUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = data['result'];

        if (item == null) return null;

        final photoReferences = item['photos'] != null && item['photos'].isNotEmpty
            ? List<String>.from(item['photos'].map((p) => p['photo_reference']))
            : <String>[];

        // 新增：開發模式下跳過照片請求以節省 API 用量
        List<String> photoUrls = [];
        if (photoReferences.isNotEmpty && !_disablePhotosForTesting) {
          final ref = photoReferences.first;
          await _incrementPhotoRequestCount();
          print("🖼️ 發送 Place Photo，placeId: $placeId");
          print("🖼️ Photo mode: ${_disablePhotosForTesting ? 'DISABLED' : 'ENABLED'}");
          photoUrls = ['https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=$apiKey'];
        } else if (_disablePhotosForTesting) {
          print("🖼️ Photo request skipped (development mode) for $placeId");
        } else if (photoReferences.isEmpty) {
          print("🖼️ No photo references available for $placeId");
        }

        final photoUrl = photoUrls.isNotEmpty
            ? photoUrls.first
            : 'https://via.placeholder.com/400x300.png?text=No+Image';

        final detailsMapDynamic = {
          'name': item['name'] ?? '',
          'image': photoUrl,
          'lat': item['geometry']?['location']?['lat']?.toString() ?? '',
          'lng': item['geometry']?['location']?['lng']?.toString() ?? '',
          'distance': calculateDistance(centerLat, centerLng, item['geometry']['location']['lat'], item['geometry']['location']['lng']).toStringAsFixed(0),
          'types': json.encode(item['types'] ?? []),
          'rating': item['rating']?.toString() ?? 'N/A',
          'open_now': (item['opening_hours']?['open_now']?.toString()) ?? 'unknown',
          'photo_references': json.encode(photoReferences),
          'place_id': item['place_id'] ?? '',
          'photo_urls': json.encode(photoUrls), // 只存一張
          // 新增：補上地址欄位
          'vicinity': item['vicinity'] ?? '',
          'address': item['formatted_address'] ?? '',
        };

        // 6. 存入 SQLite 快取
        try {
          await PlaceDetailsCacheService.savePlaceDetails(placeId, json.encode(detailsMapDynamic));
          // 更新快取統計
          await _loadCacheStats();
        } catch (e) {
          print('❌ SQLite 快取儲存失敗: $e');
        }

        // 7. 存入記憶體快取
        _savePlaceDetailsToCache(placeId, detailsMapDynamic);

        // 8. 回傳 Map<String, String>
        return detailsMapDynamic;
      }
      return null;
    } catch (e) {
      print('Error fetching details for $placeId: $e');
      return null;
    } finally {
      _removePendingRequest(placeId);
    }
  }

  FutureOr<bool> handleSwipe(int previous, int? current, CardSwiperDirection direction) {
    final swipedRestaurant = currentRoundList[previous];

    if (direction == CardSwiperDirection.right) {
      liked.add(json.encode(swipedRestaurant));
      
      // 新增：根據使用者行為進行智慧預載入
      _smartPreloadBasedOnUserBehavior();
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
    return true;
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

  String classifyRestaurant(List types, Map<String, dynamic> restaurant) {
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
    // 新增：檢查用戶 ID 狀態
    if (_isCheckingUserId) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/loading_pig.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                '正在初始化...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
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
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: const Text('這餐想來點？'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.deepPurple.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enterNextRound,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '下一輪',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: "更多選項",
            onSelected: (value) async {
              switch (value) {
                case 'dev_mode':
                  _toggleDevelopmentMode();
                  break;
                case 'refresh':
                  setState(() {
                    round = 1;
                    liked.clear();
                    cardSwiperKey++;
                    selectedIndex = 0;
                    if (fullRestaurantList.isNotEmpty) {
                      currentRoundList = List.from(fullRestaurantList)..shuffle();
                    }
                  });
                  _updateRound1Title();
                  _updateRound2Title();
                  _resetApiFetchCounter();
                  break;
                case 'clear_cache':
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('restaurant_cache');
                  await prefs.remove('cache_lat');
                  await prefs.remove('cache_lng');
                  await prefs.remove('cache_radius');
                  await prefs.remove('cache_timestamp');
                  await prefs.remove(_placeDetailsCacheKey);
                  await prefs.remove(_photoUrlCacheKey);
                  _placeDetailsCache.clear();
                  _photoUrlCache.clear();
                  print("🧹 All caches cleared!");
                  _resetApiFetchCounter();
                  fetchAllRestaurants(radiusKm: searchRadius, onlyShowOpen: true);
                  break;
                case 'api_usage':
                  setState(() => showApiUsage = !showApiUsage);
                  break;
                case 'reset_api':
                  _resetApiCounters();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API 計數器已重置'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  break;
                case 'toggle_json':
                  setState(() {
                    useJson = !useJson;
                    isLoading = true;
                    _loadingText = useJson ? '載入本地 JSON 資料...' : '載入 Google API 資料...';
                  });
                  if (useJson) {
                    loadJsonData();
                  } else {
                    fetchAllRestaurants(radiusKm: searchRadius, onlyShowOpen: true);
                  }
                  break;
                case 'refresh_cache_stats':
                  await _loadCacheStats();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('快取統計已更新: ${_cacheStats['total_entries']} 筆資料'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              // 新增：API 使用量（所有模式都顯示）
              PopupMenuItem<String>(
                value: 'api_usage',
                child: Row(
                  children: [
                    const Icon(Icons.analytics),
                    const SizedBox(width: 8),
                    const Text('API 使用量'),
                  ],
                ),
              ),
              // 開發者模式選項（只有啟用時才顯示）
              if (_showDeveloperOptions) ...[
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'dev_mode',
                  child: Row(
                    children: [
                      Icon(_disablePhotosForTesting ? Icons.developer_mode : Icons.photo_library),
                      const SizedBox(width: 8),
                      const Text('切換開發模式'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh),
                      const SizedBox(width: 8),
                      const Text('重新整理'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear_cache',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined),
                      const SizedBox(width: 8),
                      const Text('清除快取'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'reset_api',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('重置 API 計數器'),
                    ],
                  ),
                ),
                // 新增：重新整理快取統計
                PopupMenuItem<String>(
                  value: 'refresh_cache_stats',
                  child: Row(
                    children: [
                      const Icon(Icons.storage, color: Colors.cyan),
                      const SizedBox(width: 8),
                      const Text('重新整理快取統計'),
                    ],
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'toggle_json',
                child: Row(
                  children: [
                    Icon(useJson ? Icons.api : Icons.storage, color: useJson ? Colors.purple : Colors.grey),
                    const SizedBox(width: 8),
                    Text(useJson ? '切換到 Google API' : '切換到 JSON'),
                  ],
                ),
              ),
            ],
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
                              onlyShowOpen: true,
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
                      child: const Text(
                        '🎯 抉擇吧',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          letterSpacing: 0.5,
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
          // 新增：API 使用量顯示
          if (showApiUsage)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // 右上角打叉
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => showApiUsage = false),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                    // 內容
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          _buildApiUsageRow('Nearby Search', nearbySearchCount, Colors.blue, fontSize: 10, numberFontSize: 10),
                          _buildApiUsageRow('Place Details', placeDetailsCount, Colors.green, fontSize: 10, numberFontSize: 10),
                          _buildApiUsageRow('Place Photos', photoRequestCount, Colors.orange, fontSize: 10, numberFontSize: 10),
                          const Divider(color: Colors.white54, height: 2),
                          _buildApiUsageRow('今日總計', nearbySearchCount + placeDetailsCount + photoRequestCount, Colors.purple, fontSize: 10, fontWeight: FontWeight.bold, numberFontSize: 10),
                          const Divider(color: Colors.white54, height: 2),
                          _buildApiUsageRow('預估成本', _calculateEstimatedCost().toStringAsFixed(3), Colors.yellow, isCost: false, fontSize: 10, fontWeight: FontWeight.bold, numberFontSize: 10),
                          const SizedBox(height: 2),
                          // 新增：快取統計顯示
                          _buildApiUsageRow('SQLite 快取', _cacheStats['total_entries'] ?? 0, Colors.cyan, fontSize: 10, numberFontSize: 10),
                          if (_cacheStats['oldest_entry'] != null) ...[
                            Text(
                              '最舊資料: ${DateFormat('MM/dd').format(_cacheStats['oldest_entry'])}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            '限制：每分鐘 $_maxApiCallsPerMinute 次，每日 $_maxApiCallsPerDay 次',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String getOpenStatus(Map<String, dynamic> restaurant) {
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

  void _showDiceResultDialog(Map<String, dynamic> restaurant) {
    double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
    final rating = restaurant['rating'];
    final String ratingText = (rating != null && rating.toString().isNotEmpty) ? rating.toString() : '無';
    
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
        final address = (restaurant['vicinity'] ?? restaurant['address'] ?? '').toString();
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
                  child: _buildImageWidget(
                    photoUrls.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                const SizedBox(height: 4),
                // 地址（vicinity/address）
                if (address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                          ? '${(dist / 1000).toStringAsFixed(1)} km'
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
              String distanceText = dist >= 1000
                  ? '${(dist / 1000).toStringAsFixed(1)} km'
                  : '${dist.toStringAsFixed(0)} m';

              List typesList = [];
              if (restaurant['types'] != null) {
                try {
                  typesList = json.decode(restaurant['types']!);
                } catch (_) {}
              }
              final String typeText = classifyRestaurant(typesList, restaurant);
              final rating = restaurant['rating'];
              final String ratingText = (rating != null && rating.toString().isNotEmpty) ? rating.toString() : '無';
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
                              child: _buildImageWidget(
                                photoUrls.first,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
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
                                    distanceText,
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
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final restaurant = currentRoundList[index];
              print(restaurant); // debug 資料內容
              double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
              String distanceText = dist >= 1000
                  ? '${(dist / 1000).toStringAsFixed(1)} km'
                  : '${dist.toStringAsFixed(0)} m';

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
              final address = (restaurant['vicinity'] ?? restaurant['address'] ?? '').toString();

              return SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 圖片區
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: PageView.builder(
                                    itemCount: photoUrls.length,
                                    itemBuilder: (context, pageIndex) {
                                      return _buildImageWidget(
                                        photoUrls[pageIndex],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (restaurant['name'] ?? '未知餐廳') + ' ' + openStatus,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 資訊區
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      ratingText,
                                      style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.place, color: Colors.blue, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      distanceText,
                                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  typeText,
                                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32), // 給下方icon區留空間
                        ],
                      ),
                      // 右下角icon區
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                favorites.contains(restaurant['name'] ?? '') ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
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
                              icon: const Icon(Icons.navigation, color: Colors.deepPurple, size: 32),
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

  // --- Place Details 獨立快取機制 ---
  Future<void> _loadPlaceDetailsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_placeDetailsCacheKey);
    if (cachedJson != null) {
      setState(() {
        _placeDetailsCache = Map<String, dynamic>.from(json.decode(cachedJson));
      });
    }
  }

  Future<void> _savePlaceDetailsToCache(String placeId, Map<String, dynamic> details) async {
    _placeDetailsCache[placeId] = json.encode(details);
    _updateRestaurantAccessCount(placeId); // 更新訪問次數
    
    // 智慧快取清理
    _smartCacheCleanup();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_placeDetailsCacheKey, json.encode(_placeDetailsCache));
    print('ℹ️ Saved details for $placeId to cache. Cache size: ${_placeDetailsCache.length}');
  }
  // --- END ---

  Widget _buildApiUsageRow(String title, dynamic count, Color color, {bool isCost = false, double fontSize = 16, FontWeight fontWeight = FontWeight.bold, double? numberFontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: numberFontSize ?? 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isCost)
          Text(
            '\$$count',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: numberFontSize ?? 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // 新增：重置 API 計數器功能
  Future<void> _resetApiCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    _apiCallsThisMinute = 0;
    _apiCallsToday = 0;
    _lastMinuteReset = DateTime.now();
    
    await prefs.setInt('api_calls_$today', 0);
    await prefs.setInt('api_calls_minute_$today', 0);
    await prefs.setInt('last_minute_reset_$today', _lastMinuteReset.millisecondsSinceEpoch);
    
    print("🔄 API counters reset successfully");
  }

  // 新增：一鍵切換開發/正常模式
  void _toggleDevelopmentMode() {
    setState(() {
      _disablePhotosForTesting = !_disablePhotosForTesting;
    });
    
    // 顯示切換結果
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _disablePhotosForTesting ? Icons.developer_mode : Icons.photo,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(_disablePhotosForTesting 
              ? "已切換到開發模式 (關閉照片載入)" 
              : "已切換到正常模式 (開啟照片載入)"),
          ],
        ),
        backgroundColor: _disablePhotosForTesting ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '清除快取',
          textColor: Colors.white,
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('restaurant_cache');
            await prefs.remove('cache_lat');
            await prefs.remove('cache_lng');
            await prefs.remove('cache_radius');
            await prefs.remove('cache_timestamp');
            await prefs.remove(_placeDetailsCacheKey);
            await prefs.remove(_photoUrlCacheKey);
            _placeDetailsCache.clear();
            _photoUrlCache.clear();
            print("🧹 All caches cleared after mode switch!");
            fetchAllRestaurants(radiusKm: searchRadius, onlyShowOpen: true);
          },
        ),
      ),
    );
  }

  // 新增：預載入策略
  Future<void> _preloadPopularRestaurants() async {
    if (fullRestaurantList.isEmpty) return;
    // 預載入前 5 家餐廳的詳細資料
    final restaurantsToPreload = fullRestaurantList.take(5).toList();
    for (final restaurant in restaurantsToPreload) {
      final placeId = restaurant['place_id'];
      // 僅對主流程未請求過、且快取沒有的 placeId 預載入，且不重複
      if (placeId != null && !_fetchedPlaceIds.contains(placeId) && !_placeDetailsCache.containsKey(placeId) && !_batchPlaceDetailsQueue.contains(placeId)) {
        _addToBatchQueue(placeId);
      }
    }
    print("🚀 Preloading details for "+restaurantsToPreload.length.toString()+" popular restaurants");
  }
  // 新增：智慧預載入 - 根據使用者行為預測
  void _smartPreloadBasedOnUserBehavior() {
    if (liked.isEmpty) return;
    // 如果使用者右滑了某些餐廳，預載入相似類型的餐廳
    final likedRestaurants = liked.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
    final likedTypes = <String>{};
    for (final restaurant in likedRestaurants) {
      final types = restaurant['types'];
      if (types != null) {
        try {
          final List<dynamic> typeList = json.decode(types);
          likedTypes.addAll(typeList.cast<String>());
        } catch (e) {
          // 忽略解析錯誤
        }
      }
    }
    // 預載入相似類型的餐廳
    for (final restaurant in fullRestaurantList) {
      if (likedTypes.isNotEmpty) {
        final types = restaurant['types'];
        if (types != null) {
          try {
            final List<dynamic> typeList = json.decode(types);
            final hasCommonType = typeList.any((type) => likedTypes.contains(type));
            if (hasCommonType) {
              final placeId = restaurant['place_id'];
              // 僅對主流程未請求過、且快取沒有的 placeId 預載入
              if (placeId != null && !_fetchedPlaceIds.contains(placeId) && !_placeDetailsCache.containsKey(placeId)) {
                _addToBatchQueue(placeId);
              }
            }
          } catch (e) {
            // 忽略解析錯誤
          }
        }
      }
    }
  }

  // 新增：API 成本監控和警告
  void _checkApiUsageAndWarn() {
    final currentMinute = DateTime.now().minute;
    if (currentMinute != _lastMinuteReset.minute) {
      _apiCallsThisMinute = 0;
      _lastMinuteReset = DateTime.now();
    }
    
    // 當 API 使用量接近限制時發出警告
    if (_apiCallsThisMinute >= _maxApiCallsPerMinute * 0.8) {
      print("⚠️ WARNING: API calls this minute: $_apiCallsThisMinute/$_maxApiCallsPerMinute");
      _showApiUsageWarning();
    }
    
    if (_apiCallsToday >= _maxApiCallsPerDay * 0.8) {
      print("⚠️ WARNING: API calls today: $_apiCallsToday/$_maxApiCallsPerDay");
      _showApiUsageWarning();
    }
  }
  
  void _showApiUsageWarning() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ API 使用量接近限制\n本分鐘: $_apiCallsThisMinute/$_maxApiCallsPerMinute | 今日: $_apiCallsToday/$_maxApiCallsPerDay',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: '關閉',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  // 新增：API 成本估算
  double _calculateEstimatedCost() {
    // Google Places API 價格（2024年）：
    // Nearby Search: $0.017 per request
    // Place Details: $0.017 per request  
    // Place Photos: $0.007 per request
    final nearbySearchCost = nearbySearchCount * 0.017;
    final placeDetailsCost = placeDetailsCount * 0.017;
    final photoCost = photoRequestCount * 0.007;
    
    return nearbySearchCost + placeDetailsCost + photoCost;
  }

  Future<void> loadJsonData() async {
    setState(() {
      isLoading = true;
      _loadingText = '載入本地 JSON 資料...';
    });
    
    try {
      final data = await RestaurantJsonService.loadRestaurants();
      setState(() {
        fullRestaurantList = List<Map<String, dynamic>>.from(data);
        currentRoundList = List.from(fullRestaurantList)..shuffle();
        isLoading = false;
        isSplash = false;
        _loadingText = '已載入本地 JSON 資料';
      });
      
      // 更新隨機標題
      _updateRound1Title();
    } catch (e) {
      setState(() {
        isLoading = false;
        isSplash = false;
        _loadingText = '載入 JSON 資料失敗: $e';
      });
    }
  }

  Set<String> _fetchedPlaceIds = {};
  int _lastFetchTotal = 0;
  int _startNearby = 0;
  int _startDetails = 0;
  int _startPhotos = 0;
  // 1. 新增基準點變數
  int _baseNearby = 0;
  int _baseDetails = 0;
  int _basePhotos = 0;
  // 2. 清除快取或重新抓資料時重設基準點與 _lastFetchTotal
  void _resetApiFetchCounter() {
    _baseNearby = nearbySearchCount;
    _baseDetails = placeDetailsCount;
    _basePhotos = photoRequestCount;
    _lastFetchTotal = 0;
    setState(() {});
  }
  // 4. 每次 API 請求後，更新 _lastFetchTotal
  void _updateLastFetchTotal() {
    _lastFetchTotal = (nearbySearchCount - _baseNearby) +
                    (placeDetailsCount - _baseDetails) +
                    (photoRequestCount - _basePhotos);
    setState(() {});
  }

  // 新增：開發者模式觸發機制
  int _titleTapCount = 0;
  bool _showDeveloperOptions = false;
  Timer? _titleTapTimer;
  
  // 新增：開發者模式觸發方法
  void _handleTitleTap() {
    _titleTapCount++;
    _titleTapTimer?.cancel();
    
    if (_titleTapCount >= 5) {
      setState(() {
        _showDeveloperOptions = !_showDeveloperOptions; // 切換顯示/隱藏狀態
        _titleTapCount = 0;
      });
      
      // 根據狀態顯示不同的提示
      if (_showDeveloperOptions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 開發者模式已啟用'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👤 已切回使用者模式'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _titleTapTimer = Timer(const Duration(seconds: 2), () {
        _titleTapCount = 0;
      });
    }
  }

  // 新增：通用圖片載入 Widget
  Widget _buildImageWidget(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    print("🖼️ 載入圖片: $imagePath"); // 新增除錯輸出
    
    if (imagePath.startsWith('assets/')) {
      // 本地圖片
      print("📁 使用本地圖片: $imagePath"); // 新增除錯輸出
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print("❌ 本地圖片載入失敗: $imagePath, 錯誤: $error"); // 新增除錯輸出
          return Container(
            color: Colors.grey[200],
            width: width,
            height: height,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    } else {
      // 網路圖片
      print("🌐 使用網路圖片: $imagePath"); // 新增除錯輸出
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
      );
    }
  }
}

class RestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final Set<String> favorites;
  final Function(String) onToggleFavorite;
  final Function(List, Map<String, dynamic>) classifyRestaurant;
  final Function(Map<String, dynamic>) getOpenStatus;
  
  const RestaurantDetailPage({
    super.key, 
    required this.restaurant,
    required this.favorites,
    required this.onToggleFavorite,
    required this.classifyRestaurant,
    required this.getOpenStatus,
  });

  // 新增：通用圖片載入 Widget
  Widget _buildImageWidget(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imagePath.startsWith('assets/')) {
      // 本地圖片
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
      );
    } else {
      // 網路圖片
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double dist = double.tryParse(restaurant['distance'] ?? '') ?? 0;
    String distanceText = dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(1)} km'
        : '${dist.toStringAsFixed(0)} m';

    List typesList = [];
    if (restaurant['types'] != null) {
      try {
        typesList = json.decode(restaurant['types']!);
      } catch (_) {}
    }
    final String typeText = classifyRestaurant(typesList, restaurant);
    final rating = restaurant['rating'];
    final String ratingText = (rating != null && rating.toString().isNotEmpty) ? rating.toString() : '無';
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
                  return _buildImageWidget(
                    photoUrls[index],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                        distanceText,
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