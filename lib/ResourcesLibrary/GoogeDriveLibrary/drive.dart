// ---------------------------------------------------------------
//  main.dart  –  RUConnect+ Resource Hub (auto‑reload after JSON)
// ---------------------------------------------------------------
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // <-- for BackdropFilter

import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/downloadProgess.dart';
import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/favourite.dart';
import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/folderpage.dart';
import 'package:RUConnect_plus/ResourcesLibrary/GoogeDriveLibrary/fulllscreenImage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;

// ----------------------------------------------------------------
//  Entry point
// ----------------------------------------------------------------
void main() => runApp(const MyApp1());

class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUConnect+ Resource Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
      home: const DriveExplorerScreen(),
    );
  }
}

// ----------------------------------------------------------------
//  Main screen
// ----------------------------------------------------------------
class DriveExplorerScreen extends StatefulWidget {
  const DriveExplorerScreen({super.key});

  @override
  State<DriveExplorerScreen> createState() => _DriveExplorerScreenState();
}

class _DriveExplorerScreenState extends State<DriveExplorerScreen> {
  // ----------------------------------------------------------------
  //  State
  // ----------------------------------------------------------------
  List<dynamic>? driveData;
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> selectedItems = [];

  bool dataFetchFailed = false;
  bool isOnline = true;
  bool backgroundLoading = false;
  bool isSelectionMode = false;

  final TextEditingController _searchController = TextEditingController();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // NEW: key to allow full‑page replacement
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ----------------------------------------------------------------
  //  Lifecycle
  // ----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initApp();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------
  //  Init
  // ----------------------------------------------------------------
  Future<void> _initApp() async {
    _loadCachedData(); // instant UI
    await _loadFavorites();
    _checkConnectivityAndFetch();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
              _handleConnectivityChange
                  as void Function(List<ConnectivityResult> event)?,
            )
            as StreamSubscription<ConnectivityResult>;
  }

  // ----------------------------------------------------------------
  //  Cache (sync)
  // ----------------------------------------------------------------
  void _loadCachedData() {
    SharedPreferences.getInstance().then((prefs) {
      final cached = prefs.getString('cached_drive_data');
      if (cached != null && mounted) {
        try {
          final decoded = json.decode(cached) as List<dynamic>;
          setState(() => driveData = decoded);
        } catch (e) {
          debugPrint('Cache decode error: $e');
        }
      }
    });
  }

  // ----------------------------------------------------------------
  //  Favorites
  // ----------------------------------------------------------------
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('favorite_items');
    if (jsonStr != null && mounted) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        setState(() {
          favoriteItems = list.cast<Map<String, dynamic>>();
        });
      } catch (e) {
        debugPrint('Favorites decode error: $e');
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_items', json.encode(favoriteItems));
  }

  // ----------------------------------------------------------------
  //  Connectivity & background fetch
  // ----------------------------------------------------------------
  void _checkConnectivityAndFetch() {
    _connectivity.checkConnectivity().then((result) {
      final online = result != ConnectivityResult.none;
      if (mounted) setState(() => isOnline = online);
      if (online) _backgroundReload();
    });
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = isOnline;
    if (mounted) setState(() => isOnline = result != ConnectivityResult.none);
    if (!wasOnline && isOnline) _backgroundReload();
  }

  void _backgroundReload() {
    if (mounted) setState(() => backgroundLoading = true);
    _fetchDriveDataWithCache()
        .then((_) {
          if (mounted) setState(() => backgroundLoading = false);
        })
        .catchError((e) {
          debugPrint('Background fetch error: $e');
          if (mounted) {
            setState(() {
              dataFetchFailed = true;
              backgroundLoading = false;
            });
          }
        });
  }

  // ----------------------------------------------------------------
  //  FETCH + AUTO‑RELOAD
  // ----------------------------------------------------------------
  Future<void> _fetchDriveDataWithCache() async {
    try {
      final resp = await http
          .get(
            Uri.parse(
              'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/drive.json',
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

      final newData = json.decode(resp.body) as List<dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_drive_data', resp.body);

      // ----> PAGE RELOAD <----
      if (mounted) {
        setState(() {
          driveData = newData;
          dataFetchFailed = false;
        });

        // Full screen replacement – exactly like a page refresh
        _scaffoldKey.currentState?.removeCurrentSnackBar();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DriveExplorerScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (mounted) setState(() => dataFetchFailed = true);
    }
  }

  void _retryFetch() {
    setState(() => dataFetchFailed = false);
    _backgroundReload();
  }

  // ----------------------------------------------------------------
  //  Search
  // ----------------------------------------------------------------
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    final List<Map<String, dynamic>> results = [];
    void walk(Map<String, dynamic>? node) {
      if (node == null) return;
      final name = (node['name']?.toString() ?? '').toLowerCase();
      if (name.contains(query)) results.add(node);
      final children = node['children'] as List<dynamic>?;
      if (children != null) {
        for (final c in children) {
          if (c is Map<String, dynamic>) walk(c);
        }
      }
    }

    if (driveData != null) {
      for (final n in driveData!) {
        if (n is Map<String, dynamic>) walk(n);
      }
    }
    setState(() => searchResults = results);
  }

  // ----------------------------------------------------------------
  //  Favorites helpers
  // ----------------------------------------------------------------
  void _toggleFavorite(Map<String, dynamic>? item) {
    if (item == null || !mounted) return;
    final id = item['id']?.toString() ?? item['name']?.toString() ?? '';
    setState(() {
      final exists = favoriteItems.any(
        (f) => (f['id']?.toString() ?? f['name']?.toString() ?? '') == id,
      );
      if (exists) {
        favoriteItems.removeWhere(
          (f) => (f['id']?.toString() ?? f['name']?.toString() ?? '') == id,
        );
      } else {
        favoriteItems.add({...item, 'isFavorite': true});
      }
    });
    _saveFavorites();
  }

  bool _isFavorite(Map<String, dynamic>? item) {
    if (item == null) return false;
    final id = item['id']?.toString() ?? item['name']?.toString() ?? '';
    return favoriteItems.any(
      (f) => (f['id']?.toString() ?? f['name']?.toString() ?? '') == id,
    );
  }

  // ----------------------------------------------------------------
  //  Selection helpers
  // ----------------------------------------------------------------
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) selectedItems.clear();
    });
  }

  void _toggleItemSelection(Map<String, dynamic>? item) {
    if (item == null) return;
    final id = item['id']?.toString() ?? item['name']?.toString() ?? '';
    setState(() {
      final exists = selectedItems.any(
        (s) => (s['id']?.toString() ?? s['name']?.toString() ?? '') == id,
      );
      if (exists) {
        selectedItems.removeWhere(
          (s) => (s['id']?.toString() ?? s['name']?.toString() ?? '') == id,
        );
      } else {
        selectedItems.add(item);
      }
    });
  }

  void _selectAllFiles() {
    setState(() {
      selectedItems.clear();
      final source = _searchController.text.isEmpty
          ? (driveData ?? <dynamic>[])
          : searchResults;
      void collect(List<dynamic> nodes) {
        for (final n in nodes) {
          if (n is Map<String, dynamic>) {
            if (n['type'] == 'file') selectedItems.add(n);
            if (n['type'] == 'folder') {
              final children = n['children'] as List<dynamic>?;
              if (children != null) collect(children);
            }
          }
        }
      }

      collect(source);
    });
  }

  void _clearSelection() => setState(() => selectedItems.clear());

  bool _isItemSelected(Map<String, dynamic>? item) {
    if (item == null) return false;
    final id = item['id']?.toString() ?? item['name']?.toString() ?? '';
    return selectedItems.any(
      (s) => (s['id']?.toString() ?? s['name']?.toString() ?? '') == id,
    );
  }

  // ----------------------------------------------------------------
  //  Permission & download
  // ----------------------------------------------------------------
  Future<bool> _requestStoragePermissionWithDialog() async {
    if (kIsWeb) return true;
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted && context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Storage permission is needed to download files.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Settings'),
              ),
            ],
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _downloadSelectedFiles() async {
    if (selectedItems.isEmpty || !context.mounted) return;
    final ok = await _requestStoragePermissionWithDialog();
    if (!ok && !kIsWeb) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EnhancedDownloadProgressDialog(
        totalFiles: selectedItems.length,
        onCancel: () => Navigator.pop(context),
      ),
    );

    int success = 0, fail = 0;
    final List<String> failed = [];

    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      if (item['type'] == 'file' && item['url'] != null) {
        try {
          _updateEnhancedDownloadProgress(
            context,
            i + 1,
            selectedItems.length,
            item['name']?.toString(),
          );
          await _downloadSingleFileWithProgress(item);
          success++;
        } catch (e) {
          fail++;
          failed.add(item['name']?.toString() ?? 'Unknown');
        }
      }
    }

    if (context.mounted) Navigator.pop(context);
    if (context.mounted) _showDownloadResult(context, success, fail, failed);
    setState(() {
      selectedItems.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _downloadSingleFileWithPermission(
    Map<String, dynamic> item,
  ) async {
    final ok = await _requestStoragePermissionWithDialog();
    if (!ok && !kIsWeb) return;
    try {
      await _downloadSingleFileWithProgress(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${item['name'] ?? 'Unknown'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: _openDownloadsDirectory,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${item['name'] ?? 'Unknown'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadSingleFileWithProgress(
    Map<String, dynamic> item,
  ) async {
    final url = item['url']?.toString();
    final name = item['name']?.toString() ?? 'download';
    if (url == null || url.isEmpty) throw Exception('No URL');

    if (kIsWeb) {
      html.AnchorElement(href: url)
        ..setAttribute('download', name)
        ..click();
      return;
    }

    final dir = await getDownloadsDirectory();
    if (dir == null) throw Exception('Downloads directory unavailable');

    final path = '${dir.path}/$name';
    final file = File(path);
    final finalPath = await file.exists()
        ? '${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}'
        : path;

    await _downloadFileWithProgress(url, finalPath);
  }

  Future<void> _downloadFileWithProgress(String url, String path) async {
    final request = http.Request('GET', Uri.parse(url));
    final streamed = await http.Client().send(request);
    final file = File(path);
    final sink = file.openWrite();
    final total = streamed.contentLength ?? 0;
    var downloaded = 0;

    await streamed.stream
        .listen(
          (chunk) {
            sink.add(chunk);
            downloaded += chunk.length;
            if (total > 0) {
              final progress = downloaded / total;
              final dlg = context
                  .findAncestorStateOfType<
                    EnhancedDownloadProgressDialogState
                  >();
              dlg?.updateSingleFileProgress(progress);
            }
          },
          onDone: () => sink.close(),
          onError: (e) => throw Exception('Download error: $e'),
          cancelOnError: true,
        )
        .asFuture();
  }

  void _updateEnhancedDownloadProgress(
    BuildContext ctx,
    int cur,
    int tot,
    String? name,
  ) {
    final dlg = ctx
        .findAncestorStateOfType<EnhancedDownloadProgressDialogState>();
    dlg?.updateProgress(cur, tot, name ?? 'Unknown', (cur / tot * 100).toInt());
  }

  void _showDownloadResult(
    BuildContext ctx,
    int success,
    int fail,
    List<String> failed,
  ) {
    if (fail == 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Downloaded $success files'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: _openDownloadsDirectory,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Success: $success, Failed: $fail'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'DETAILS',
            textColor: Colors.white,
            onPressed: () => _showFailedDownloadsDialog(ctx, failed),
          ),
        ),
      );
    }
  }

  void _showFailedDownloadsDialog(BuildContext ctx, List<String> failed) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Failed Downloads'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: failed.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(failed[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDownloadsDirectory() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved in browser downloads')),
      );
      return;
    }
    final dir = await getDownloadsDirectory();
    if (dir != null && await canLaunchUrl(Uri.directory(dir.path))) {
      await launchUrl(Uri.directory(dir.path));
    }
  }

  // ----------------------------------------------------------------
  //  Helpers
  // ----------------------------------------------------------------
  Map<String, int> _countFilesAndFolders(List<dynamic>? nodes) {
    int files = 0, folders = 0;
    void walk(List<dynamic>? list) {
      if (list == null) return;
      for (final n in list) {
        if (n is Map<String, dynamic>) {
          if (n['type'] == 'file') files++;
          if (n['type'] == 'folder') {
            folders++;
            walk(n['children'] as List<dynamic>?);
          }
        }
      }
    }

    walk(nodes);
    return {'files': files, 'folders': folders};
  }

  bool isImageFile(String? mime, String? name) {
    if (mime?.startsWith('image/') == true) return true;
    final ext = name?.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
  }

  // ----------------------------------------------------------------
  //  UI – node builder
  // ----------------------------------------------------------------
  Widget buildNode(Map<String, dynamic>? node) {
    if (node == null) return const SizedBox.shrink();

    final name = node['name']?.toString() ?? 'Unknown';
    final type = node['type']?.toString();
    final isSel = _isItemSelected(node);
    final isFav = _isFavorite(node);
    final isImg = isImageFile(node['mimeType']?.toString(), name);
    final width = MediaQuery.sizeOf(context).width;
    final padding = width > 1024 ? 24.0 : 16.0;

    // ---------- FILE ----------
    if (type == 'file') {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSel,
                  onChanged: (_) => _toggleItemSelection(node),
                ),
              if (isImg)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    node['url']?.toString() ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, color: Colors.orange),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const SizedBox(),
                  ),
                )
              else
                const Icon(Icons.insert_drive_file, color: Colors.grey),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              color: isSel ? const Color.fromARGB(255, 0, 93, 253) : null,
            ),
          ),
          trailing: isSelectionMode
              ? null
              : PopupMenuButton<String>(
                  onSelected: (v) => v == 'download'
                      ? _downloadSingleFileWithPermission(node)
                      : _toggleFavorite(node),
                  itemBuilder: (_) => [
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
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(isFav ? 'Remove Favorite' : 'Add Favorite'),
                        ],
                      ),
                    ),
                  ],
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.more_vert,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: null,
                  ),
                ),
          onTap: () =>
              isSelectionMode ? _toggleItemSelection(node) : _openFile(node),
          onLongPress: () {
            if (!isSelectionMode) {
              setState(() => isSelectionMode = true);
              _toggleItemSelection(node);
            }
          },
        ),
      );
    }

    // ---------- FOLDER ----------
    final children = node['children'] as List<dynamic>?;
    final counts = _countFilesAndFolders(children);
    final hasSubFolders =
        children?.any((c) => c is Map && c['type'] == 'folder') == true;

    if (hasSubFolders) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSel,
                  onChanged: (_) => _toggleItemSelection(node),
                ),
              const Icon(Icons.folder, color: Colors.blue),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              color: isSel ? const Color.fromARGB(255, 0, 78, 212) : null,
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
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(node),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
          onTap: () => isSelectionMode
              ? _toggleItemSelection(node)
              : Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderPage(
                      folderData: node,
                      favoriteItems: favoriteItems,
                      onFavoriteToggle: _toggleFavorite,
                    ),
                  ),
                ),
          onLongPress: () {
            if (!isSelectionMode) {
              setState(() => isSelectionMode = true);
              _toggleItemSelection(node);
            }
          },
        ),
      );
    }

    // ---------- EXPANDABLE LEAF FOLDER ----------
    return Card(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.blue),
        title: Text(name),
        subtitle: Text(
          '${counts['folders']} folders, ${counts['files']} files',
        ),
        trailing: IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.grey,
          ),
          onPressed: () => _toggleFavorite(node),
        ),
        children:
            children
                ?.whereType<Map<String, dynamic>>()
                .map(buildNode)
                .toList() ??
            [],
      ),
    );
  }

  // ----------------------------------------------------------------
  //  Open file / image
  // ----------------------------------------------------------------
  void _openFile(Map<String, dynamic>? node) async {
    if (node == null || !context.mounted) return;
    final url = node['url']?.toString();
    final name = node['name']?.toString() ?? 'Unknown';
    if (url == null || url.isEmpty) return;

    final isImg = isImageFile(node['mimeType']?.toString(), name);
    if (isImg) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FullScreenImage(url: url)),
      );
    } else if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open: $name')));
    }
  }

  // ----------------------------------------------------------------
  //  UI – AppBar (blur + white)
  // ----------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    final counts = _countFilesAndFolders(driveData);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC2196F3), Color(0x992196F3)],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: isSelectionMode
                  ? Text('${selectedItems.length} selected')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RUConnect+ Resource Hub'),
                        if (driveData != null)
                          Text(
                            '${counts['folders']} folders • ${counts['files']} files',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
              leading: isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleSelectionMode,
                    )
                  : null,
              actions: _buildAppBarActions(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (isSelectionMode) {
      return [
        if (selectedItems.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.select_all, color: Colors.white),
            onPressed: _selectAllFiles,
            tooltip: 'Select all',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearSelection,
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadSelectedFiles,
            tooltip: 'Download',
          ),
          Text(
            '${selectedItems.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _toggleSelectionMode,
          tooltip: 'Exit',
        ),
      ];
    }

    return [
      if (!isOnline)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.wifi_off, color: Colors.white70),
        ),
      if (backgroundLoading)
        const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.favorite, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FavoritesPage(
              favoriteItems: favoriteItems,
              onFavoriteToggle: _toggleFavorite,
            ),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.select_all, color: Colors.white),
        onPressed: _toggleSelectionMode,
        tooltip: 'Select multiple',
      ),
    ];
  }

  // ----------------------------------------------------------------
  //  UI – Body
  // ----------------------------------------------------------------
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ---- Search ----
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                hintText: 'Search files and folders...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ---- Offline banner ----
          if (!isOnline && driveData != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Offline – using cached data'),
                ],
              ),
            ),

          // ---- Selection banner ----
          if (isSelectionMode && selectedItems.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedItems.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ---- Content ----
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  //  UI – Content list
  // ----------------------------------------------------------------
  Widget _buildContent() {
    final items = _searchController.text.isEmpty
        ? (driveData ?? <dynamic>[])
        : searchResults;

    if (items.isEmpty) {
      if (dataFetchFailed && isOnline) {
        return _emptyState('Failed to load data', 'Tap to retry', _retryFetch);
      }
      if (driveData == null && !isOnline) {
        return _emptyState('No cached data', 'Check connection', _retryFetch);
      }
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No results found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      children: items.whereType<Map<String, dynamic>>().map(buildNode).toList(),
    );
  }

  Widget _emptyState(String title, String btn, VoidCallback onTap) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onTap, child: Text(btn)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  //  UI – FAB (retry)
  // ----------------------------------------------------------------
  Widget? _buildFloatingActionButton() {
    if ((driveData == null && !isOnline) || dataFetchFailed) {
      return FloatingActionButton(
        onPressed: _retryFetch,
        backgroundColor: Colors.blue,
        tooltip: dataFetchFailed ? 'Retry' : 'Refresh',
        child: const Icon(Icons.refresh, color: Colors.white),
      );
    }
    return null;
  }

  // ----------------------------------------------------------------
  //  Build
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // <-- important for page‑replace
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}

extension on ScaffoldState? {
  void removeCurrentSnackBar() {
    this?.removeCurrentSnackBar();
  }
}
