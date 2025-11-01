import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Page',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppMakerAdmin(),
    );
  }
}

class AppMakerAdmin extends StatefulWidget {
  const AppMakerAdmin({super.key});

  @override
  State<AppMakerAdmin> createState() => _AppMakerAdminState();
}

class _AppMakerAdminState extends State<AppMakerAdmin> {
  List<dynamic> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// Fetch data from OpenSheet API
  Future<void> fetchData() async {
    final url =
        'https://opensheet.elk.sh/1uFl4IR4mFtO7rwT8aTnnWzw4EKpiSdb5plUedQZ9P18/2';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Open hyperlinks in browser
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Show image in full screen with zoom support
  void _showZoomableImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onDoubleTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            maxScale: 5.0,
            minScale: 1.0,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Page',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: data.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;

                        if (isMobile) {
                          // Mobile layout
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftColumn(item, isMobile: true),
                              const SizedBox(height: 16),
                              _buildMarkdown(item),
                            ],
                          );
                        } else {
                          // Web/Desktop layout
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftColumn(item),
                              const SizedBox(width: 20),
                              // Divider between left/right
                              Container(
                                width: 1,
                                height:
                                    200, // Can adjust or calculate dynamically
                                color: Colors.grey[400],
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              Expanded(child: _buildMarkdown(item)),
                            ],
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  /// Left Column (Image + Name + Department)
  Widget _buildLeftColumn(dynamic item, {bool isMobile = false}) {
    Widget content = Column(
      children: [
        GestureDetector(
          onTap: () => _showZoomableImage(item['Images'] ?? ''),
          child: Image.network(
            item['Images'] ?? '',
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 150,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 50),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['Name'] ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          item['Department'] ?? '',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );

    if (isMobile) {
      return Center(child: content);
    } else {
      return content;
    }
  }

  /// Markdown description with zoomable images and hyperlinks
  Widget _buildMarkdown(dynamic item) {
    return MarkdownBody(
      data: item['Description'] ?? '',
      selectable: true,
      imageBuilder: (uri, title, alt) {
        return GestureDetector(
          onTap: () => _showZoomableImage(uri.toString()),
          child: Image.network(uri.toString(), fit: BoxFit.cover),
        );
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: Colors.black87),
        h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
        code: const TextStyle(
          backgroundColor: Color(0xFFE0E0E0),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        blockSpacing: 10,
        listIndent: 20,
        blockquote: const TextStyle(color: Colors.grey),
        a: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) _launchUrl(href);
      },
    );
  }
}
