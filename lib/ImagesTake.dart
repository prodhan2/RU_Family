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
  bool _uploading = false;
  final List<String> _previewUrls = [];

  @override
  void initState() {
    super.initState();
    _urlsController.addListener(_updatePreview);
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

    setState(() => _uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final docRef = FirebaseFirestore.instance.collection('images').doc();

      await docRef.set({
        'imageUrls': urls, // Array of strings
        'somitiName': widget.somitiName,
        'uploadedByEmail': user.email ?? '',
        'uploadedByName': user.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${urls.length} image(s) uploaded as array!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Refresh gallery
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
        title: const Text('Add Multiple Images (Array)'),
        backgroundColor: Colors.orange,
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
                      '4. Paste below → All saved in one record',
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

            // Dynamic Text Field
            Expanded(
              child: TextField(
                controller: _urlsController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Paste Image URLs (one per line)',
                  hintText:
                      'https://i.postimg.cc/.../img1.png\n'
                      'https://i.postimg.cc/.../img2.png',
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

            // Live Preview
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
                        'Save ${_previewUrls.length} Images as Array',
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
    super.dispose();
  }
}
