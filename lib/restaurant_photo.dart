class RestaurantPhoto {
  final String url;
  final String uploadedBy;
  final DateTime timestamp;
  final bool isApproved;

  RestaurantPhoto({
    required this.url,
    required this.uploadedBy,
    required this.timestamp,
    this.isApproved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'uploadedBy': uploadedBy,
      'timestamp': timestamp.toIso8601String(),
      'isApproved': isApproved,
    };
  }

  factory RestaurantPhoto.fromMap(Map<String, dynamic> map) {
    return RestaurantPhoto(
      url: map['url'],
      uploadedBy: map['uploadedBy'],
      timestamp: DateTime.parse(map['timestamp']),
      isApproved: map['isApproved'] ?? false,
    );
  }
} 