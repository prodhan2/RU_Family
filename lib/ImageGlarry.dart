import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:ru_family/ImagesTake.dart'; // Your AddImageGalleryPage

class ImageGalleryPageview extends StatefulWidget {
  final String somitiName;

  const ImageGalleryPageview({Key? key, required this.somitiName})
    : super(key: key);

  @override
  State<ImageGalleryPageview> createState() => _ImageGalleryPageviewState();
}

class _ImageGalleryPageviewState extends State<ImageGalleryPageview> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? currentUserUid;
  List<ImageItem> imageItems = []; // Flattened list of images
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUserUid = currentUser?.uid;
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (currentUserUid == null) {
      setState(() => isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('images')
        .where('somitiName', isEqualTo: widget.somitiName)
        .get();

    final flattened = await _flattenAndFilterImages(snapshot.docs);

    // Sort by createdAt (newest first)
    flattened.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      imageItems = flattened;
      isLoading = false;
    });
  }

  Future<List<ImageItem>> _flattenAndFilterImages(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<ImageItem> result = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['uploadedByEmail'] as String?;
      if (email == null) continue;

      // Verify uploader is current user via members collection
      final memberSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: email)
          .where('uid', isEqualTo: currentUserUid)
          .limit(1)
          .get();

      if (memberSnap.docs.isNotEmpty) {
        final urls =
            (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
        final name = data['uploadedByName'] as String? ?? 'Unknown';
        final createdAt = (data['createdAt'] as Timestamp?) ?? Timestamp.now();

        for (var url in urls) {
          result.add(
            ImageItem(
              url: url,
              uploadedByName: name,
              createdAt: createdAt,
              docId: doc.id,
            ),
          );
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserUid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view gallery")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.somitiName),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddImageGalleryPage(somitiName: widget.somitiName),
            ),
          ).then((refresh) {
            if (refresh == true) _loadImages();
          });
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add_link, color: Colors.white),
        tooltip: 'Add multiple images (URLs)',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : imageItems.isEmpty
          ? const Center(child: Text("No images found"))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: imageItems.length,
              itemBuilder: (context, index) {
                final item = imageItems[index];
                final dateStr = DateFormat(
                  'MMM dd, yyyy - h:mm a',
                ).format(item.createdAt.toDate());

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageCarousel(
                          images: imageItems,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'image_${item.docId}_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(item.url),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.uploadedByName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Helper class to hold flattened image data
class ImageItem {
  final String url;
  final String uploadedByName;
  final Timestamp createdAt;
  final String docId;

  ImageItem({
    required this.url,
    required this.uploadedByName,
    required this.createdAt,
    required this.docId,
  });
}

// ────────────────────────────────────────────────────────────────
// Full-Screen Carousel (Supports Array Images)
// ────────────────────────────────────────────────────────────────
class FullScreenImageCarousel extends StatefulWidget {
  final List<ImageItem> images;
  final int initialIndex;

  const FullScreenImageCarousel({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageCarousel> createState() =>
      _FullScreenImageCarouselState();
}

class _FullScreenImageCarouselState extends State<FullScreenImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final item = widget.images[index];
              return Hero(
                tag: 'image_${item.docId}_$index',
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(item.url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: (context, obj, stack) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 60,
                  ),
                ),
              );
            },
          ),
          // Caption
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: _buildCaption(widget.images[_currentIndex]),
            ),
          ),
          // Page Indicator
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption(ImageItem item) {
    final date = DateFormat(
      'dd MMM yyyy, h:mm a',
    ).format(item.createdAt.toDate());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.uploadedByName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
