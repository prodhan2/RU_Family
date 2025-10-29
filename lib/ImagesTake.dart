// AddImageGalleryPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AddImageGalleryPage extends StatefulWidget {
  final String somitiName;
  const AddImageGalleryPage({Key? key, required this.somitiName})
    : super(key: key);

  @override
  State<AddImageGalleryPage> createState() => _AddImageGalleryPageState();
}

class _AddImageGalleryPageState extends State<AddImageGalleryPage> {
  final TextEditingController _urlsController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  bool _uploading = false;
  final List<String> _previewUrls = [];
  List<String> _existingFolders = [];
  String? _selectedFolder;

  // User info from members collection
  String _uploadedByName = 'Loading...';
  String _uploadedByEmail = '';

  @override
  void initState() {
    super.initState();
    _urlsController.addListener(_updatePreview);
    _loadExistingFolders();
    _loadCurrentUserName(); // NEW: Load name from members
  }

  // ==================== LOAD USER NAME FROM members ====================
  Future<void> _loadCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final name = data['name']?.toString() ?? 'Unknown User';
        final email = data['email']?.toString() ?? user.email ?? '';

        if (mounted) {
          setState(() {
            _uploadedByName = name;
            _uploadedByEmail = email;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _uploadedByName = user.displayName ?? 'User';
            _uploadedByEmail = user.email ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadedByName = user.displayName ?? 'User';
          _uploadedByEmail = user.email ?? '';
        });
      }
    }
  }

  // ==================== LOAD EXISTING FOLDERS ====================
  Future<void> _loadExistingFolders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('somitiName', isEqualTo: widget.somitiName)
          .get();

      final Set<String> folders = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['folder'] != null && data['folder'] is String) {
          folders.add(data['folder'] as String);
        }
      }

      if (mounted) {
        setState(() {
          _existingFolders = folders.toList()..sort();
          if (_existingFolders.isNotEmpty && _selectedFolder == null) {
            _selectedFolder = _existingFolders.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _existingFolders = [];
        });
      }
    }
  }

  void _updatePreview() {
    final text = _urlsController.text;
    final urls = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.startsWith('http'))
        .toList();

    setState(() {
      _previewUrls.clear();
      _previewUrls.addAll(urls);
    });
  }

  void _showCreateFolderDialog() {
    _folderController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: _folderController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _folderController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _selectedFolder = name;
                  if (!_existingFolders.contains(name)) {
                    _existingFolders.add(name);
                    _existingFolders.sort();
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ==================== UPLOAD WITH CORRECT NAME ====================
  Future<void> _uploadAsArray() async {
    final rawText = _urlsController.text;
    final urls = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.startsWith('http'))
        .toList();

    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one valid image URL'),
        ),
      );
      return;
    }

    if (_selectedFolder == null || _selectedFolder!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a folder')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('images').doc();

      await docRef.set({
        'imageUrls': urls,
        'somitiName': widget.somitiName,
        'folder': _selectedFolder,
        'uploadedByEmail': _uploadedByEmail,
        'uploadedByName': _uploadedByName, // CORRECT NAME FROM members
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${urls.length} image(s) uploaded by $_uploadedByName!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _openPostImages() async {
    final uri = Uri.parse('https://postimages.org');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Multiple Images'),
        backgroundColor: Colors.orange,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'By: $_uploadedByName',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction Card
            Card(
              color: Colors.blue.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Upload:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Go to postimages.org\n'
                      '2. Upload all images\n'
                      '3. Copy Direct Links (one per line)\n'
                      '4. Paste below → Saved in one record',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openPostImages,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open postimages.org'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Folder Selection
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select or Create Folder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFolder,
                      decoration: InputDecoration(
                        labelText: 'Folder',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        ..._existingFolders.map(
                          (folder) => DropdownMenuItem(
                            value: folder,
                            child: Text(folder),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'new',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Create New Folder'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'new') {
                          _showCreateFolderDialog();
                        } else {
                          setState(() => _selectedFolder = value);
                        }
                      },
                    ),
                    if (_existingFolders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No folders yet. Create one!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // URL Input
            Expanded(
              child: TextField(
                controller: _urlsController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Paste Image URLs (one per line)',
                  hintText:
                      'https://i.postimg.cc/.../img1.png\nhttps://i.postimg.cc/.../img2.png',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.link),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            if (_previewUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview (${_previewUrls.length} images)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _previewUrls.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _previewUrls[i],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.red.shade100,
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _uploading ? null : _uploadAsArray,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _uploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        'Save ${_previewUrls.length} Images',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlsController.removeListener(_updatePreview);
    _urlsController.dispose();
    _folderController.dispose();
    super.dispose();
  }
}
