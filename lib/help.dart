import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelplinePage extends StatelessWidget {
  const HelplinePage({super.key});

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // Function to launch phone
  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnyHelp Contacts'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 80, color: Colors.blue[600]),
              const SizedBox(height: 20),
              const Text(
                'RUConnect+ এর জন্য কোনো সাহায্য চাইলে যোগাযোগ করুন',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildContactItem(
                icon: Icons.phone,
                title: 'কল করুন',
                subtitle: '01902338808',
                onTap: () => _launchPhone('01902338808'),
              ),
              const SizedBox(height: 20),
              _buildContactItem(
                icon: Icons.facebook,
                title: 'Facebook ভিজিট করুন',
                subtitle: 'Butterfly Devs',
                onTap: () =>
                    _launchUrl('https://www.facebook.com/butterflydevs'),
              ),
              const SizedBox(height: 20),
              _buildContactItem(
                icon: Icons.message,
                title: 'Telegram এ মেসেজ করুন',
                subtitle: '@Sujanprodhan',
                onTap: () => _launchUrl('https://t.me/Sujanprodhan'),
              ),
              const SizedBox(height: 40),
              Text(
                'আমরা সাহায্য করতে প্রস্তুত!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(icon, color: Colors.blue[600]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
