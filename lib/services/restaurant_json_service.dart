import 'dart:convert';
import 'package:flutter/services.dart';

class RestaurantJsonService {
  static Future<List<Map<String, dynamic>>> loadRestaurants() async {
    final String jsonString = await rootBundle.loadString('lib/data/tainan_restaurants.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> restaurants = jsonData['restaurants'];
    return restaurants.cast<Map<String, dynamic>>();
  }
} 