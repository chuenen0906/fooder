import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoPageViewScreen extends StatelessWidget {
  final List<String> photoReferences;

  const PhotoPageViewScreen({
    Key? key,
    required this.photoReferences,
  }) : super(key: key);

  String getPhotoUrl(String reference) {
    const apiKey = 'AIzaSyC6lBQ-jkslOR2LDkHm0q8KW4Yg9crzcHE'; 
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$reference&key=$apiKey';
  }

  @override
  Widget build(BuildContext context) {
    print('PhotoPageViewScreen 被呼叫，收到 photoReferences: $photoReferences');

    final controller = PageController();
    return Scaffold(
      appBar: AppBar(title: const Text("店家照片 PageView")),
      body: PageView.builder(
        controller: controller,
        itemCount: photoReferences.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: getPhotoUrl(photoReferences[index]),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Text('載入失敗'),
            ),
          );
        },
      ),
    );
  }
}
