import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen image viewer page
class FullScreenImage extends StatelessWidget {
  final String? url;
  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Image View',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'Image not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Image View', style: TextStyle(color: Colors.white)),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url!),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        enableRotation: true,
      ),
    );
  }
}
