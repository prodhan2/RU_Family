import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:RUConnect_plus/member/Images/ImagesTake.dart'; // AddImageGalleryPage
import 'package:share_plus/share_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageGalleryPageview extends StatefulWidget {
  final String somitiName;

  const ImageGalleryPageview({Key? key, required this.somitiName})
    : super(key: key);

  @override
  State<ImageGalleryPageview> createState() => _ImageGalleryPageviewState();
}

// Custom cache manager for images (7-day stale, validate on use)
class GalleryCacheManager extends CacheManager {
  static const key = 'galleryCacheKey';
  static final GalleryCacheManager _instance = GalleryCacheManager._();

  factory GalleryCacheManager() => _instance;

  GalleryCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200, // Adjust based on gallery size
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}

class _ImageGalleryPageviewState extends State<ImageGalleryPageview> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? currentUserUid;
  String? currentUserEmail;

  List<ImageItem> allImages = [];
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

  // ==================== SAFE FIRST CHAR ====================
  String getFirstChar(dynamic input) {
    final str = input?.toString().trim() ?? '';
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

  // ==================== RESPONSIVE GRID DELEGATE ====================
  SliverGridDelegate _getImageGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 6
        : screenWidth > 1000
        ? 5
        : screenWidth > 600
        ? 4
        : screenWidth > 400
        ? 3
        : 2;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
    );
  }

  SliverGridDelegate _getFolderGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
        ? 3
        : screenWidth > 400
        ? 2
        : 1;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
    );
  }

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

  // ==================== LOAD ALL IMAGES FOR THIS SOMITI (CLIENT-SIDE SORT) ====================
  Future<void> _loadImages() async {
    if (currentUserUid == null || currentUserEmail == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // No orderBy - avoids index. Limit to prevent huge loads (adjust as needed)
      final snapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('somitiName', isEqualTo: widget.somitiName)
          .limit(200) // Safety limit; remove if you want all
          .get();

      Map<String, List<ImageItem>> tempFolders = {};
      List<ImageItem> tempAll = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final email = data['uploadedByEmail'] as String?;
        final isOwn = email == currentUserEmail;

        final urls =
            (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
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

      // Client-side sort: Newest first
      tempAll.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final entry in tempFolders.entries) {
        entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      final sortedFolders = tempFolders.keys.toList()..sort();

      if (mounted) {
        setState(() {
          allImages = tempAll;
          folderImages = tempFolders;
          folders = sortedFolders;
          _updateFilteredData();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
      }
    }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedDocIds.length} item(s) deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }

      selectedDocIds.clear();
      await _loadImages(); // Reload after delete
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==================== FILTER DATA ====================
  void _updateFilteredData() {
    List<ImageItem> tempImages = List.from(allImages); // Use allImages now

    if (selectedFolder != 'All') {
      tempImages = tempImages.where((i) => i.folder == selectedFolder).toList();
    }

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

    // Ensure sorted after filter
    tempImages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _filteredImages = tempImages;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${selectedDocIds.length} selected'
              : (viewMode == 'all'
                    ? widget.somitiName
                    : '${widget.somitiName} Folders'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isSelectionMode ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
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
      floatingActionButton: isWideScreen
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddImageGalleryPage(somitiName: widget.somitiName),
                  ),
                ).then((_) {
                  // Silent refresh
                  Future.microtask(() => _loadImages());
                });
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_link),
              tooltip: 'Add images',
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (isWideScreen) {
                  // Web/Desktop: Sidebar for filters, main content for grid
                  return Row(
                    children: [
                      // Sidebar for Filters
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Add Images Button in Sidebar
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddImageGalleryPage(
                                        somitiName: widget.somitiName,
                                      ),
                                    ),
                                  ).then((_) {
                                    // Silent refresh
                                    Future.microtask(() => _loadImages());
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_link,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Add Images',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Filters',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Search
                                    TextField(
                                      focusNode: _searchFocusNode,
                                      onChanged: (v) {
                                        setState(() => searchQuery = v);
                                        _updateFilteredData();
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Search by name or URL',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    searchQuery = '';
                                                  });
                                                  _searchFocusNode.unfocus();
                                                  _updateFilteredData();
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blue,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Date Range
                                    InkWell(
                                      onTap: viewMode == 'folders'
                                          ? null
                                          : () async {
                                              final picked =
                                                  await showDateRangePicker(
                                                    context: context,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime.now()
                                                        .add(
                                                          const Duration(
                                                            days: 1,
                                                          ),
                                                        ),
                                                    initialDateRange:
                                                        filterRange,
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: Theme.of(context)
                                                            .copyWith(
                                                              colorScheme:
                                                                  const ColorScheme.light(
                                                                    primary:
                                                                        Colors
                                                                            .blue,
                                                                  ),
                                                            ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                              if (picked != null && mounted) {
                                                setState(
                                                  () => filterRange = picked,
                                                );
                                                _updateFilteredData();
                                              }
                                            },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Date Range',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          suffixIcon: const Icon(
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        child: Text(
                                          filterRange == null
                                              ? 'All Dates'
                                              : '${DateFormat('MMM dd').format(filterRange!.start)} - ${DateFormat('MMM dd').format(filterRange!.end)}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Folder Dropdown
                                    DropdownButtonFormField<String>(
                                      value: selectedFolder,
                                      decoration: InputDecoration(
                                        labelText: 'Folder',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: 'All',
                                          child: Text('All Folders'),
                                        ),
                                        ...folders.map(
                                          (f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(f),
                                          ),
                                        ),
                                      ],
                                      onChanged: viewMode == 'folders'
                                          ? null
                                          : (v) {
                                              setState(
                                                () => selectedFolder = v!,
                                              );
                                              _updateFilteredData();
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Main Content
                      Expanded(
                        child: viewMode == 'all'
                            ? _buildImageGrid(_filteredImages)
                            : _buildFolderGrid(_filteredFolders),
                      ),
                    ],
                  );
                } else {
                  // Mobile: Compact filter row
                  return Column(
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
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                      ),
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
                                width: 120,
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
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                        primary: Colors.blue,
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null && mounted) {
                                            setState(
                                              () => filterRange = picked,
                                            );
                                            _updateFilteredData();
                                          }
                                        },
                                  child: IgnorePointer(
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Date',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blue,
                                          ),
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
                                width: 120,
                                child: DropdownButtonFormField<String>(
                                  value: selectedFolder,
                                  decoration: InputDecoration(
                                    labelText: 'Folder',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'All',
                                      child: Text(
                                        'All',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ...folders.map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(
                                          f,
                                          style: const TextStyle(fontSize: 11),
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
                            ? _buildImageGrid(_filteredImages)
                            : _buildFolderGrid(_filteredFolders),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }

  // ==================== IMAGE GRID (ALL IMAGES) ====================
  Widget _buildImageGrid(List<ImageItem> images) {
    if (images.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No images found. Start by adding some!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: _getImageGridDelegate(context),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
              ),
              child: Stack(
                children: [
                  // Hero animation for full-screen transition
                  Hero(
                    tag: 'image_${item.docId}_$index',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.url,
                        cacheManager: GalleryCacheManager(),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                  ),

                  // Selection overlay
                  if (isSelectionMode && item.isOwn)
                    Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withOpacity(0.4)
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                            )
                          : const SizedBox(),
                    ),

                  // Bottom gradient info overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.blue.withOpacity(0.8),
                            child: Text(
                              getFirstChar(item.uploadedByName),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.uploadedByName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }

  // ==================== FOLDER GRID ====================
  Widget _buildFolderGrid(List<String> filteredFolders) {
    if (filteredFolders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No folders found. Create some by adding images!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: _getFolderGridDelegate(context),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.blue.withOpacity(0.2),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: ownImgs.first.url,
                            cacheManager: GalleryCacheManager(),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.folder,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ),

                          if (isSelectionMode)
                            Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.2),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            folder,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${ownImgs.length} images',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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

  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 6
        : screenWidth > 1000
        ? 5
        : screenWidth > 600
        ? 4
        : screenWidth > 400
        ? 3
        : 2;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('$somitiName - $folderName'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: images.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No images in this folder',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: _getGridDelegate(context),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              item.url,
                              cacheManager: GalleryCacheManager(),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
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
                  imageProvider: CachedNetworkImageProvider(
                    item.url,
                    cacheManager: GalleryCacheManager(),
                  ),
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
              padding: const EdgeInsets.all(20),
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
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                getFirstChar(item.uploadedByName),
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.uploadedByName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (item.folder != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Folder: ${item.folder}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  String getFirstChar(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}
