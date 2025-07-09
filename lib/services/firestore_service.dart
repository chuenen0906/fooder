import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String specialty;
  final String area;
  final String description;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.specialty,
    required this.area,
    required this.description,
    required this.photos,
    this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      area: data['area'] ?? '',
      description: data['description'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updated_at'] != null 
          ? (data['updated_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'area': area,
      'description': description,
      'photos': photos,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 獲取所有餐廳
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final QuerySnapshot querySnapshot = 
          await _firestore.collection('restaurants').get();
      
      return querySnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 獲取餐廳資料失敗: $e');
      return [];
    }
  }

  // 根據區域獲取餐廳
  Future<List<Restaurant>> getRestaurantsByArea(String area) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('restaurants')
          .where('area', isEqualTo: area)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 獲取 $area 區域餐廳失敗: $e');
      return [];
    }
  }

  // 根據特色菜獲取餐廳
  Future<List<Restaurant>> getRestaurantsBySpecialty(String specialty) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('restaurants')
          .where('specialty', isEqualTo: specialty)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 獲取 $specialty 餐廳失敗: $e');
      return [];
    }
  }

  // 搜尋餐廳
  Future<List<Restaurant>> searchRestaurants(String searchTerm) async {
    try {
      final QuerySnapshot querySnapshot = 
          await _firestore.collection('restaurants').get();
      
      final restaurants = querySnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .where((restaurant) =>
              restaurant.name.contains(searchTerm) ||
              restaurant.specialty.contains(searchTerm) ||
              restaurant.area.contains(searchTerm) ||
              restaurant.description.contains(searchTerm))
          .toList();
      
      return restaurants;
    } catch (e) {
      print('❌ 搜尋餐廳失敗: $e');
      return [];
    }
  }

  // 獲取單一餐廳
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final DocumentSnapshot doc = 
          await _firestore.collection('restaurants').doc(restaurantId).get();
      
      if (doc.exists) {
        return Restaurant.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ 獲取餐廳詳情失敗: $e');
      return null;
    }
  }

  // 即時監聽餐廳資料變更
  Stream<List<Restaurant>> getRestaurantsStream() {
    return _firestore
        .collection('restaurants')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc))
            .toList());
  }

  // 獲取所有區域
  Future<List<String>> getAllAreas() async {
    try {
      final QuerySnapshot querySnapshot = 
          await _firestore.collection('restaurants').get();
      
      final areas = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['area'] as String)
          .toSet()
          .toList();
      
      areas.sort();
      return areas;
    } catch (e) {
      print('❌ 獲取區域列表失敗: $e');
      return [];
    }
  }

  // 獲取所有特色菜
  Future<List<String>> getAllSpecialties() async {
    try {
      final QuerySnapshot querySnapshot = 
          await _firestore.collection('restaurants').get();
      
      final specialties = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['specialty'] as String)
          .toSet()
          .toList();
      
      specialties.sort();
      return specialties;
    } catch (e) {
      print('❌ 獲取特色菜列表失敗: $e');
      return [];
    }
  }
} 