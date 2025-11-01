import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/folderpage.dart';
import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/fulllscreenImage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page for displaying favorite items
class FavoritesPage extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteItems;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.favoriteItems,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.blue, Colors.purple],
            ),
          ),
        ),
        title: const Text('Favorites'),
      ),
      body: favoriteItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon to add favorites',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  final item = favoriteItems[index];
                  if (item is Map<String, dynamic>) {
                    return _DriveExplorerNode(
                      node: item,
                      isFavorite: true,
                      onFavoriteToggle: onFavoriteToggle,
                      favoriteItems: favoriteItems,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
    );
  }
}

// Widget for individual drive explorer nodes (files/folders) with animation
class _DriveExplorerNode extends StatelessWidget {
  final Map<String, dynamic>? node;
  final bool isFavorite;
  final Function(Map<String, dynamic>) onFavoriteToggle;
  final List<Map<String, dynamic>> favoriteItems;

  const _DriveExplorerNode({
    required this.node,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.favoriteItems,
  });

  /// Check if a file is an image based on MIME type or file extension
  bool isImageFile(String? mimeType, String? fileName) {
    if (mimeType != null && mimeType.startsWith('image/')) {
      return true;
    }
    if (fileName == null) return false;
    final extension = fileName.toLowerCase().split('.').last;
    return [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'svg',
    ].contains(extension);
  }

  /// Count files and folders in a node
  Map<String, int> _countFilesAndFolders(List<dynamic>? nodes) {
    int fileCount = 0;
    int folderCount = 0;

    void countNodes(List<dynamic>? children) {
      if (children == null) return;
      for (var child in children) {
        if (child is Map<String, dynamic>) {
          if (child['type'] == 'file') {
            fileCount++;
          } else if (child['type'] == 'folder') {
            folderCount++;
            final subChildren = child['children'];
            if (subChildren is List) {
              countNodes(subChildren);
            }
          }
        }
      }
    }

    countNodes(nodes);
    return {'files': fileCount, 'folders': folderCount};
  }

  @override
  Widget build(BuildContext context) {
    if (node == null) {
      return const SizedBox.shrink();
    }
    final nodeName = node!['name']?.toString() ?? 'Unnamed';
    final nodeType = node!['type']?.toString();
    final isImage = isImageFile(node!['mimeType']?.toString(), nodeName);

    // common animated wrapper
    Widget animatedWrapper(Widget child) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20), // slide from bottom
              child: child,
            ),
          );
        },
      );
    }

    if (nodeType == 'file') {
      return animatedWrapper(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isImage
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            node!['url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.orange),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : const Icon(Icons.insert_drive_file, color: Colors.grey),
              ],
            ),
            title: Text(
              nodeName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'download') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download from favorites')),
                  );
                } else if (value == 'favorite') {
                  onFavoriteToggle(node!);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Favorite'),
                    ],
                  ),
                ),
              ],
              child: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: null,
              ),
            ),
            onTap: () async {
              final fileUrl = node!['url']?.toString();
              final mimeType = node!['mimeType']?.toString();
              if (fileUrl == null || fileUrl.isEmpty) return;

              if (isImageFile(mimeType, nodeName)) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(url: fileUrl),
                    ),
                  );
                }
              } else if (await canLaunchUrl(Uri.parse(fileUrl))) {
                await launchUrl(
                  Uri.parse(fileUrl),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cannot open file: $nodeName')),
                  );
                }
              }
            },
          ),
        ),
      );
    } else if (nodeType == 'folder') {
      final children = node!['children'];
      final counts = _countFilesAndFolders(children as List<dynamic>?);
      return animatedWrapper(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: Text(
              nodeName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${counts['folders']} folders, ${counts['files']} files',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => onFavoriteToggle(node!),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderPage(
                    folderData: node,
                    favoriteItems: favoriteItems,
                    onFavoriteToggle: onFavoriteToggle,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
