import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Developer',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
    ),
    home: const AppMakerAdmin(),
    debugShowCheckedModeBanner: false,
  );
}

/* ------------------------------------------------- */
/*                     DATA MODEL                    */
/* ------------------------------------------------- */
class DataItem {
  final String name;
  final String image;
  final String department;
  final String description;

  DataItem({
    required this.name,
    required this.image,
    required this.department,
    required this.description,
  });

  factory DataItem.fromJson(Map<String, dynamic> json) => DataItem(
    name: json['Name'] ?? '',
    image: json['Images'] ?? '',
    department: json['Department'] ?? '',
    description: json['Description'] ?? '',
  );
}

/* ------------------------------------------------- */
/*                     MAIN SCREEN                   */
/* ------------------------------------------------- */
class AppMakerAdmin extends StatefulWidget {
  const AppMakerAdmin({super.key});
  @override
  State<AppMakerAdmin> createState() => _AppMakerAdminState();
}

class _AppMakerAdminState extends State<AppMakerAdmin> {
  late final Future<List<DataItem>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<List<DataItem>> _fetchData() async {
    const url =
        'https://opensheet.elk.sh/1uFl4IR4mFtO7rwT8aTnnWzw4EKpiSdb5plUedQZ9P18/2';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load data – ${response.statusCode}');
    }
    final List jsonList = json.decode(response.body);
    return jsonList.map((e) => DataItem.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('developer', style: TextStyle(color: Colors.white)),
        centerTitle: !isWeb,
        elevation: 0,
      ),
      body: FutureBuilder<List<DataItem>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) =>
                isWeb ? _WebCard(item: items[i]) : _MobileCard(item: items[i]),
          );
        },
      ),
    );
  }
}

/* ------------------------------------------------- */
/*                     WEB CARD                      */
/* ------------------------------------------------- */
class _WebCard extends StatelessWidget {
  final DataItem item;
  const _WebCard({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- left side (image + name + dept) ----
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.image,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.department,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // ---- vertical separator ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(width: 1, height: 180, color: Colors.grey.shade400),
        ),
        // ---- right side (rich markdown) ----
        Expanded(child: _RichMarkdown(text: item.description)),
      ],
    ),
  );
}

/* ------------------------------------------------- */
/*                    MOBILE CARD                    */
/* ------------------------------------------------- */
class _MobileCard extends StatelessWidget {
  final DataItem item;
  const _MobileCard({required this.item});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (item.image.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.image,
            height: 140,
            width: 140,
            fit: BoxFit.fitWidth,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
        ),
      const SizedBox(height: 12),
      Text(
        item.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        item.department,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      const SizedBox(height: 12),
      _RichMarkdown(text: item.description),
      const SizedBox(height: 20),
    ],
  );
}

/* ------------------------------------------------- */
/*                RICH MARKDOWN WIDGET               */
/* ------------------------------------------------- */
class _RichMarkdown extends StatelessWidget {
  final String text;
  const _RichMarkdown({required this.text});

  @override
  Widget build(BuildContext context) {
    // Parse Markdown → AST
    final doc = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [md.EmojiSyntax()],
    );
    final nodes = doc.parseLines(text.split('\n'));

    // Build widgets
    final builder = _MarkdownBuilder(context: context);
    for (final n in nodes) n.accept(builder);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: builder.widgets,
      ),
    );
  }
}

/* ------------------------------------------------- */
/*               CUSTOM MARKDOWN BUILDER              */
/* ------------------------------------------------- */
class _MarkdownBuilder implements md.NodeVisitor {
  final List<Widget> widgets = [];
  final BuildContext context;

  // list-type stack (ul/ol) + counters for ordered lists
  final List<bool> _orderedStack = [];
  final List<int> _counterStack = [];

  _MarkdownBuilder({required this.context});

  // ---------- helpers ----------
  String _textFrom(List<md.Node>? children) =>
      children?.map((e) => e is md.Text ? e.text : '').join() ?? '';

  Color? _parseColor(String style) {
    final m = RegExp(
      r'color\s*:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|[a-zA-Z]+)',
    ).firstMatch(style);
    if (m == null) return null;
    final v = m.group(1)!;

    if (v.startsWith('#')) {
      var hex = v.replaceFirst('#', '');
      if (hex.length == 3) hex = hex.split('').map((c) => c + c).join();
      return Color(int.parse('0xFF$hex'));
    }
    final map = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'yellow': Colors.yellow,
      'pink': Colors.pink,
      'cyan': Colors.cyan,
      'brown': Colors.brown,
      'black': Colors.black,
      'white': Colors.white,
      'gray': Colors.grey,
      'lime': Colors.lime,
      'indigo': Colors.indigo,
      'teal': Colors.teal,
      'amber': Colors.amber,
    };
    return map[v.toLowerCase()];
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open $url')));
    }
  }

  // ---------- visitor ----------
  @override
  void visitText(md.Text text) {
    final s = text.text.trim();
    if (s.isEmpty) return;
    widgets.add(Text(s, style: const TextStyle(fontSize: 15)));
  }

  @override
  bool visitElementBefore(md.Element el) {
    final children = el.children;

    switch (el.tag) {
      /* ---------- headings ---------- */
      case 'h1':
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _textFrom(children),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        );
        return false;
      case 'h2':
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _textFrom(children),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        );
        return false;

      /* ---------- paragraph (handled in after) ---------- */
      case 'p':
        return true;

      /* ---------- lists ---------- */
      case 'ul':
        _orderedStack.add(false);
        _counterStack.add(0);
        return true;
      case 'ol':
        _orderedStack.add(true);
        _counterStack.add(1);
        return true;
      case 'li':
        final ordered = _orderedStack.isNotEmpty && _orderedStack.last;
        final counter = _counterStack.isNotEmpty ? _counterStack.last : 1;
        final bullet = ordered ? '$counter. ' : '• ';
        final txt = _textFrom(children);

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bullet, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(txt, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        );

        if (_counterStack.isNotEmpty) {
          _counterStack[_counterStack.length - 1]++;
        }
        return false;

      /* ---------- link ---------- */
      case 'a':
        final href = el.attributes['href'];
        final txt = _textFrom(children);
        if (href != null && href.isNotEmpty) {
          widgets.add(
            InkWell(
              onTap: () => _openUrl(href),
              child: Text(
                txt,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          );
          return false;
        }
        break;

      /* ---------- image ---------- */
      case 'img':
        final src = el.attributes['src'];
        final alt = el.attributes['alt'] ?? '';
        if (src != null && src.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: src,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (alt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        alt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
          return false;
        }
        break;

      /* ---------- span (color) ---------- */
      case 'span':
        final style = el.attributes['style'];
        final txt = _textFrom(children);
        if (style != null && txt.isNotEmpty) {
          final c = _parseColor(style);
          widgets.add(Text(txt, style: TextStyle(color: c, fontSize: 15)));
          return false;
        }
        break;

      /* ---------- strong / em ---------- */
      case 'strong':
        widgets.add(
          Text(
            _textFrom(children),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        );
        return false;
      case 'em':
        widgets.add(
          Text(
            _textFrom(children),
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
          ),
        );
        return false;

      /* ---------- inline code ---------- */
      case 'code':
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _textFrom(children),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        );
        return false;
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element el) {
    // close list stacks
    if (el.tag == 'ul' || el.tag == 'ol') {
      if (_orderedStack.isNotEmpty) _orderedStack.removeLast();
      if (_counterStack.isNotEmpty) _counterStack.removeLast();
    }
  }
}
