// lib/Student/ProfilePage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Read-only
  String? _name, _email, _mobile, _universityId, _session, _hall, _somiti, _uid;
  String? _currentImageUrl;

  // Editable (local copies)
  String _emergency = '';
  String _present = '';
  String _permanent = '';
  String _social = '';
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // -----------------------------------------------------------------
  // Load profile (cache-first)
  // -----------------------------------------------------------------
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get(const GetOptions(source: Source.cache));

      if (snap.docs.isEmpty) {
        final server = await FirebaseFirestore.instance
            .collection('members')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get(const GetOptions(source: Source.server));
        if (server.docs.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }
        _fill(server.docs.first);
      } else {
        _fill(snap.docs.first);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _fill(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    _name = data['name'] ?? 'N/A';
    _email = data['email'] ?? 'N/A';
    _mobile = data['mobileNumber'] ?? 'N/A';
    _universityId = data['universityId'] ?? 'N/A';
    _session = data['session'] ?? 'N/A';
    _hall = data['hall'] ?? 'N/A';
    _somiti = data['somitiName'] ?? 'N/A';
    _uid = data['uid'] ?? 'N/A';

    _emergency = data['emergencyContact'] ?? '';
    _present = data['presentAddress'] ?? '';
    _permanent = data['permanentAddress'] ?? '';
    _social = data['socialMediaId'] ?? '';
    _currentImageUrl = data['profileImageUrl'] ?? '';
    _imageUrl = _currentImageUrl ?? '';

    setState(() => _isLoading = false);
  }

  // -----------------------------------------------------------------
  // Save all changes
  // -----------------------------------------------------------------
  Future<void> _save() async {
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final ref = query.docs.first.reference;

      await ref.update({
        'emergencyContact': _emergency.trim(),
        'presentAddress': _present.trim(),
        'permanentAddress': _permanent.trim(),
        'socialMediaId': _social.trim(),
        'profileImageUrl': _imageUrl.trim(),
      });

      setState(() => _currentImageUrl = _imageUrl.trim());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Save failed')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageUrlDialog,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: _currentImageUrl?.isNotEmpty == true
                          ? NetworkImage(_currentImageUrl!)
                          : null,
                      child: _currentImageUrl?.isEmpty != false
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to change photo',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),

            const Divider(height: 40),

            // Read-only
            _buildRow('Name', _name!, null),
            _buildRow('Email', _email!, null),
            _buildRow('Mobile', _mobile!, null),
            _buildRow('University ID', _universityId!, null),
            _buildRow('Session', _session!, null),
            _buildRow('Hall', _hall!, null),
            _buildRow('Somiti', _somiti!, null),
            _buildRow('UID', _uid!, null),

            const Divider(height: 32, color: Colors.blue),
            const Text(
              'Editable Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            // Editable with edit icon
            _buildRow(
              'Emergency Contact',
              _emergency.isEmpty ? 'Not set' : _emergency,
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDialog(
                  'Emergency Contact',
                  _emergency,
                  (v) => _emergency = v,
                ),
              ),
            ),
            _buildRow(
              'Present Address',
              _present.isEmpty ? 'Not set' : _present,
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDialog(
                  'Present Address',
                  _present,
                  (v) => _present = v,
                ),
              ),
            ),
            _buildRow(
              'Permanent Address',
              _permanent.isEmpty ? 'Not set' : _permanent,
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDialog(
                  'Permanent Address',
                  _permanent,
                  (v) => _permanent = v,
                ),
              ),
            ),
            _buildRow(
              'Social Media ID',
              _social.isEmpty ? 'Not set' : _social,
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDialog(
                  'Social Media ID',
                  _social,
                  (v) => _social = v,
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Reusable Row
  // -----------------------------------------------------------------
  Widget _buildRow(String label, String value, Widget? trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(child: Text(value)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Edit Dialog (for text fields)
  // -----------------------------------------------------------------
  void _showEditDialog(String title, String current, Function(String) onSave) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Image URL Dialog
  // -----------------------------------------------------------------
  void _showImageUrlDialog() {
    final controller = TextEditingController(text: _imageUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profile Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://i.postimg.cc/.../image.jpg',
              ),
            ),
            const SizedBox(height: 12),
            _buildImageHelpCard(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isEmpty || _isValidImageUrl(url)) {
                setState(() => _imageUrl = url);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invalid image URL. Must end with .jpg, .png, .gif',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  Widget _buildImageHelpCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to get image URL?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Go to postimages.org\n2. Upload photo\n3. Copy "Direct Link"',
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://postimages.org')),
              child: const Text('Open postimages.org'),
            ),
          ],
        ),
      ),
    );
  }
}
