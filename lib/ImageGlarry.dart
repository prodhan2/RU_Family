import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:ru_family/ImagesTake.dart'; // AddImageGalleryPage
import 'package:share_plus/share_plus.dart';

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
  String? currentUserEmail;

  List<ImageItem> allImages = []; // All images in this somiti
  Map<String, List<ImageItem>> folderImages = {};
  List<String> folders = [];

  String viewMode = 'all'; // 'all' or 'folders'
  bool isLoading = true;

  // Selection Mode
  bool isSelectionMode = false;
  Set<String> selectedDocIds = {};

  // Filters
  String searchQuery = '';
  String selectedFolder = 'All';
  DateTimeRange? filterRange;

  late List<ImageItem> _filteredImages;
  late List<String> _filteredFolders;

  late FocusNode _searchFocusNode;
  bool isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    currentUserUid = currentUser?.uid;
    currentUserEmail = currentUser?.email;

    _filteredImages = [];
    _filteredFolders = [];

    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && searchQuery.isEmpty) {
        setState(() => isSearchExpanded = false);
        _updateFilteredData();
      }
    });

    _loadImages();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ==================== LOAD ALL IMAGES FOR THIS SOMITI ====================
  Future<void> _loadImages() async {
    if (currentUserUid == null || currentUserEmail == null) {
      setState(() => isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('images')
        .where('somitiName', isEqualTo: widget.somitiName)
        .get();

    Map<String, List<ImageItem>> tempFolders = {};
    List<ImageItem> tempAll = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['uploadedByEmail'] as String?;
      final isOwn = email == currentUserEmail; // Only for edit/delete

      final urls = (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
      final folder = data['folder'] as String? ?? 'Uncategorized';
      final name = data['uploadedByName'] as String? ?? 'Unknown';
      final createdAt = (data['createdAt'] as Timestamp?) ?? Timestamp.now();
      final docId = doc.id;

      final List<ImageItem> items = urls
          .map(
            (url) => ImageItem(
              url: url,
              uploadedByName: name,
              createdAt: createdAt,
              docId: docId,
              folder: folder,
              isOwn: isOwn,
            ),
          )
          .toList();

      tempAll.addAll(items);
      tempFolders.putIfAbsent(folder, () => []).addAll(items);
    }

    // Sort newest first
    tempAll.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final entry in tempFolders.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final sortedFolders = tempFolders.keys.toList()..sort();

    setState(() {
      allImages = tempAll;
      folderImages = tempFolders;
      folders = sortedFolders;
      _updateFilteredData();
      isLoading = false;
    });
  }

  // ==================== SELECTION MODE ====================
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) selectedDocIds.clear();
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (selectedDocIds.contains(docId)) {
        selectedDocIds.remove(docId);
      } else {
        selectedDocIds.add(docId);
      }
      if (selectedDocIds.isEmpty) isSelectionMode = false;
    });
  }

  // ==================== DELETE SELECTED ====================
  Future<void> _deleteSelected() async {
    if (selectedDocIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Images?'),
        content: Text(
          'Delete ${selectedDocIds.length} record(s)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final docId in selectedDocIds) {
        batch.delete(
          FirebaseFirestore.instance.collection('images').doc(docId),
        );
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedDocIds.length} item(s) deleted'),
          backgroundColor: Colors.green,
        ),
      );

      selectedDocIds.clear();
      await _loadImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ==================== FILTER DATA ====================
  void _updateFilteredData() {
    List<ImageItem> tempImages = List.from(allImages);

    // Folder filter
    if (selectedFolder != 'All') {
      tempImages = tempImages.where((i) => i.folder == selectedFolder).toList();
    }

    // Search filter
    if (searchQuery.isNotEmpty) {
      tempImages = tempImages
          .where(
            (i) =>
                i.uploadedByName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                i.url.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Date filter
    if (filterRange != null) {
      final start = DateTime(
        filterRange!.start.year,
        filterRange!.start.month,
        filterRange!.start.day,
      );
      final end = DateTime(
        filterRange!.end.year,
        filterRange!.end.month,
        filterRange!.end.day,
      ).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      tempImages = tempImages.where((i) {
        final d = i.createdAt.toDate();
        return d.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            d.isBefore(end.add(const Duration(milliseconds: 1)));
      }).toList();
    }

    tempImages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _filteredImages = tempImages;

    // Folder filtering for search in folder mode
    List<String> tempFolders = List.from(folders);
    if (searchQuery.isNotEmpty && viewMode == 'folders') {
      tempFolders = tempFolders.where((f) {
        final imgs = folderImages[f]!;
        return imgs.any(
          (img) =>
              img.uploadedByName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              f.toLowerCase().contains(searchQuery.toLowerCase()),
        );
      }).toList();
    }
    _filteredFolders = tempFolders;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view gallery')),
      );
    }

    final hasOwnContent = allImages.any((i) => i.isOwn);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${selectedDocIds.length} selected'
              : (viewMode == 'all'
                    ? widget.somitiName
                    : '${widget.somitiName} Folders'),
        ),
        backgroundColor: isSelectionMode ? Colors.red : Colors.teal,
        actions: [
          if (hasOwnContent && !isSelectionMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleSelectionMode,
              tooltip: 'Edit / Delete',
            ),
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel',
            ),
          ],
          IconButton(
            icon: Icon(viewMode == 'all' ? Icons.folder : Icons.apps),
            onPressed: () {
              setState(() {
                viewMode = viewMode == 'all' ? 'folders' : 'all';
                if (viewMode == 'all') selectedFolder = 'All';
              });
              _updateFilteredData();
            },
            tooltip: viewMode == 'all' ? 'View Folders' : 'View All Images',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddImageGalleryPage(somitiName: widget.somitiName),
            ),
          ).then((_) => _loadImages());
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add_link, color: Colors.white),
        tooltip: 'Add images',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Row
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            onTap: () =>
                                setState(() => isSearchExpanded = true),
                            onChanged: (v) {
                              setState(() => searchQuery = v);
                              _updateFilteredData();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name or URL',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: isSearchExpanded
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          searchQuery = '';
                                          isSearchExpanded = false;
                                        });
                                        _searchFocusNode.unfocus();
                                        _updateFilteredData();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (!isSearchExpanded) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 160,
                          child: InkWell(
                            onTap: viewMode == 'folders'
                                ? null
                                : () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
                                      initialDateRange: filterRange,
                                    );
                                    if (picked != null && mounted) {
                                      setState(() => filterRange = picked);
                                      _updateFilteredData();
                                    }
                                  },
                            child: IgnorePointer(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  filterRange == null
                                      ? 'All'
                                      : '${DateFormat('MMM dd').format(filterRange!.start)} - ${DateFormat('MMM dd').format(filterRange!.end)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: selectedFolder,
                            decoration: InputDecoration(
                              labelText: 'Folder',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(fontSize: 11),
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: Text(
                                  'All Folders',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              ...folders.map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    f,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: viewMode == 'folders'
                                ? null
                                : (v) {
                                    setState(() => selectedFolder = v!);
                                    _updateFilteredData();
                                  },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: viewMode == 'all'
                      ? _buildImageGrid(_filteredImages) // ALL images
                      : _buildFolderGrid(_filteredFolders),
                ),
              ],
            ),
    );
  }

  // ==================== IMAGE GRID (ALL IMAGES) ====================
  Widget _buildImageGrid(List<ImageItem> images) {
    if (images.isEmpty) return const Center(child: Text('No images found'));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final item = images[index];
        final isSelected = selectedDocIds.contains(item.docId);

        return GestureDetector(
          onLongPress: item.isOwn
              ? () {
                  _toggleSelectionMode();
                  _toggleSelection(item.docId);
                }
              : null,
          onTap: isSelectionMode && item.isOwn
              ? () => _toggleSelection(item.docId)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageCarousel(
                        images: images,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
          child: Stack(
            children: [
              Hero(
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
                          child: Text(
                            item.uploadedByName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelectionMode && item.isOwn)
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withOpacity(0.6)
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== FOLDER GRID (ONLY OWN FOLDERS) ====================
  Widget _buildFolderGrid(List<String> filteredFolders) {
    if (filteredFolders.isEmpty)
      return const Center(child: Text('No folders found'));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = filteredFolders[index];
        final imgs = folderImages[folder]!;
        final ownImgs = imgs.where((i) => i.isOwn).toList();

        if (ownImgs.isEmpty) return const SizedBox.shrink();

        final docId = ownImgs.first.docId;
        final isSelected = selectedDocIds.contains(docId);

        return GestureDetector(
          onLongPress: () {
            _toggleSelectionMode();
            _toggleSelection(docId);
          },
          onTap: isSelectionMode
              ? () => _toggleSelection(docId)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderDetailPage(
                        somitiName: widget.somitiName,
                        folderName: folder,
                        images: ownImgs,
                      ),
                    ),
                  );
                },
          child: Stack(
            children: [
              Card(
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: ownImgs.first.url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                folder,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${ownImgs.length} images',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
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
              if (isSelectionMode)
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withOpacity(0.6)
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== IMAGE ITEM MODEL ====================
class ImageItem {
  final String url;
  final String uploadedByName;
  final Timestamp createdAt;
  final String docId;
  final String? folder;
  final bool isOwn;

  ImageItem({
    required this.url,
    required this.uploadedByName,
    required this.createdAt,
    required this.docId,
    this.folder,
    required this.isOwn,
  });
}

// ==================== FOLDER DETAIL PAGE ====================
class FolderDetailPage extends StatelessWidget {
  final String somitiName;
  final String folderName;
  final List<ImageItem> images;

  const FolderDetailPage({
    Key? key,
    required this.somitiName,
    required this.folderName,
    required this.images,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$somitiName - $folderName'),
        backgroundColor: Colors.teal,
      ),
      body: images.isEmpty
          ? const Center(child: Text('No images'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final item = images[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageCarousel(
                          images: images,
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
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== FULL SCREEN CAROUSEL ====================
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
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final item = widget.images[_currentIndex];
              Share.share(
                item.url,
                subject: 'Shared by ${item.uploadedByName}',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
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
                  loadingBuilder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
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
          // Page indicator
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
        if (item.folder != null)
          Text(
            'Folder: ${item.folder}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }
}
