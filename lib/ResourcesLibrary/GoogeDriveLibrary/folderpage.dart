import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/fulllscreenImage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page for displaying folder contents with selection and download
class FolderPage extends StatefulWidget {
  final Map<String, dynamic>? folderData;
  final List<Map<String, dynamic>> favoriteItems;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  const FolderPage({
    super.key,
    required this.folderData,
    required this.favoriteItems,
    required this.onFavoriteToggle,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Map<String, dynamic>> selectedItems = [];
  bool isSelectionMode = false;

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedItems.clear();
      }
    });
  }

  /// Select/deselect an item for download
  void _toggleItemSelection(Map<String, dynamic>? item) {
    if (item == null) return;
    setState(() {
      final itemId = item['id']?.toString() ?? item['name']?.toString() ?? '';
      if (selectedItems.any(
        (selected) =>
            (selected['id']?.toString() ??
                selected['name']?.toString() ??
                '') ==
            itemId,
      )) {
        selectedItems.removeWhere(
          (selected) =>
              (selected['id']?.toString() ??
                  selected['name']?.toString() ??
                  '') ==
              itemId,
        );
      } else {
        selectedItems.add(item);
      }
    });
  }

  /// Check if an item is selected
  bool _isItemSelected(Map<String, dynamic>? item) {
    if (item == null) return false;
    final itemId = item['id']?.toString() ?? item['name']?.toString() ?? '';
    return selectedItems.any(
      (selected) =>
          (selected['id']?.toString() ?? selected['name']?.toString() ?? '') ==
          itemId,
    );
  }

  /// Download selected in folder (simplified - can be expanded)
  Future<void> _downloadSelectedInFolder() async {
    // Implement similar to main screen
    if (selectedItems.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download selected in folder')),
    );
    // Add full implementation here
  }

  /// Count files and folders in the current folder
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

  /// Check if an item is in favorites
  bool _isFavorite(Map<String, dynamic>? item) {
    if (item == null) return false;
    final itemId = item['id']?.toString() ?? item['name']?.toString() ?? '';
    return widget.favoriteItems.any(
      (fav) =>
          (fav['id']?.toString() ?? fav['name']?.toString() ?? '') == itemId,
    );
  }

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

  /// Build a node widget for folder page
  Widget buildNode(Map<String, dynamic>? node) {
    if (node == null) {
      return const SizedBox.shrink();
    }
    final nodeName = node['name']?.toString() ?? 'Unnamed';
    final nodeType = node['type']?.toString();
    final isSelected = _isItemSelected(node);
    final isFavorite = _isFavorite(node);
    final isImage = isImageFile(node['mimeType']?.toString(), nodeName);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final padding = isDesktop ? 24.0 : 16.0;

    if (nodeType == 'file') {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleItemSelection(node),
                ),
              if (isImage)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      node['url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.orange),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                const Icon(Icons.insert_drive_file, color: Colors.grey),
            ],
          ),
          title: Text(
            nodeName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
          trailing: isSelectionMode
              ? null
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'download') {
                      // Download single file
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download from folder')),
                      );
                      // Implement _downloadSingleFileWithPermission here
                    } else if (value == 'favorite') {
                      widget.onFavoriteToggle(node);
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
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(isFavorite ? 'Remove Favorite' : 'Add Favorite'),
                        ],
                      ),
                    ),
                  ],
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.more_vert,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: null,
                  ),
                ),
          onTap: () async {
            if (isSelectionMode) {
              _toggleItemSelection(node);
            } else {
              final fileUrl = node['url']?.toString();
              final mimeType = node['mimeType']?.toString();
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
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              _toggleSelectionMode();
              _toggleItemSelection(node);
            }
          },
        ),
      );
    } else if (nodeType == 'folder') {
      final children = node['children'];
      final counts = _countFilesAndFolders(children as List<dynamic>?);
      return Card(
        margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleItemSelection(node),
                ),
              const Icon(Icons.folder, color: Colors.blue),
            ],
          ),
          title: Text(
            nodeName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${counts['folders']} folders, ${counts['files']} files',
          ),
          trailing: isSelectionMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => widget.onFavoriteToggle(node),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
          onTap: () {
            if (isSelectionMode) {
              _toggleItemSelection(node);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderPage(
                    folderData: node,
                    favoriteItems: widget.favoriteItems,
                    onFavoriteToggle: widget.onFavoriteToggle,
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              _toggleSelectionMode();
              _toggleItemSelection(node);
            }
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.folderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Folder')),
        body: const Center(child: Text('Folder data not available')),
      );
    }
    List<dynamic> children = widget.folderData!['children'] ?? [];
    final counts = _countFilesAndFolders(children);

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
        title: isSelectionMode
            ? Text('${selectedItems.length} selected')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folderData!['name']?.toString() ?? 'Unnamed Folder',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${counts['folders']} folders • ${counts['files']} files',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: isSelectionMode
            ? [
                if (selectedItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _downloadSelectedInFolder,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectionMode,
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: children.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Folder is empty',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                children: children.map<Widget>((node) {
                  if (node is Map<String, dynamic>) {
                    return buildNode(node);
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
      ),
    );
  }
}
