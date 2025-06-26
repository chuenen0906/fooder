import 'package:flutter/material.dart';
import 'services/restaurant_json_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台南餐廳 JSON Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const RestaurantListPage(),
    );
  }
}

class RestaurantListPage extends StatefulWidget {
  const RestaurantListPage({super.key});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await RestaurantJsonService.loadRestaurants();
    setState(() {
      _restaurants = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(title: const Text('台南餐廳 JSON Demo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _restaurants.length,
            itemBuilder: (context, index) {
                final r = _restaurants[index];
              return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.restaurant, size: 40),
                    title: Text(r['name'] ?? ''),
                    subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(r['address'] ?? ''),
                        Text('評分：${r['rating'] ?? '無'}'),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}