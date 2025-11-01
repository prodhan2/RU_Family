// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:markdown/markdown.dart' as md;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:google_fonts/google_fonts.dart'; // Add this for Bengali font support

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'Developer',
//     theme: ThemeData(
//       primarySwatch: Colors.blue,
//       appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
//       // Add global font support for Bengali
//       textTheme: TextTheme(
//         bodyMedium: GoogleFonts.notoSansBengali(), // Default Bengali font
//       ),
//     ),
//     home:  AppMakerAdmin1(),
//     debugShowCheckedModeBanner: false,
//   );
// }

// /* ------------------------------------------------- */
// /*                     DATA MODEL                    */
// /* ------------------------------------------------- */
// class DataItem {
//   final String name;
//   final String image;
//   final String department;
//   final String description;

//   DataItem({
//     required this.name,
//     required this.image,
//     required this.department,
//     required this.description,
//   });

//   factory DataItem.fromJson(Map<String, dynamic> json) => DataItem(
//     name: json['Name'] ?? '',
//     image: json['Images'] ?? '',
//     department: json['Department'] ?? '',
//     description: json['Description'] ?? '',
//   );
// }

// /* ------------------------------------------------- */
// /*                     MAIN SCREEN                   */
// /* ------------------------------------------------- */
// class AppMakerAdmin extends StatefulWidget {
//   const AppMakerAdmin({super.key});
//   @override
//   State<AppMakerAdmin> createState() => _AppMakerAdminState();
// }

// class _AppMakerAdminState extends State<AppMakerAdmin> {
//   late final Future<List<DataItem>> _dataFuture;

//   @override
//   void initState() {
//     super.initState();
//     _dataFuture = _fetchData();
//   }

//   Future<List<DataItem>> _fetchData() async {
//     const url =
//         'https://opensheet.elk.sh/1uFl4IR4mFtO7rwT8aTnnWzw4EKpiSdb5plUedQZ9P18/2';
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode != 200) {
//       throw Exception('Failed to load data – ${response.statusCode}');
//     }
//     final List jsonList = json.decode(response.body);
//     return jsonList.map((e) => DataItem.fromJson(e)).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isWeb = MediaQuery.of(context).size.width > 768;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         title: const Text('developer', style: TextStyle(color: Colors.white)),
//         centerTitle: !isWeb,
//         elevation: 0,
//       ),
//       body: FutureBuilder<List<DataItem>>(
//         future: _dataFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No data'));
//           }

//           final items = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: items.length,
//             itemBuilder: (_, i) =>
//                 isWeb ? _WebCard(item: items[i]) : _MobileCard(item: items[i]),
//           );
//         },
//       ),
//     );
//   }
// }

// /* ------------------------------------------------- */
// /*                     WEB CARD                      */
// /* ------------------------------------------------- */
// class _WebCard extends StatelessWidget {
//   final DataItem item;
//   const _WebCard({required this.item});

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 12),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ---- left side (image + name + dept) ----
//         SizedBox(
//           width: 200,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (item.image.isNotEmpty)
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(
//                     12,
//                   ), // Slightly larger radius for beauty
//                   child: CachedNetworkImage(
//                     imageUrl: item.image,
//                     height: 200,
//                     width: 200,
//                     fit: BoxFit.cover,
//                     placeholder: (_, __) => const Center(
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     errorWidget: (_, __, ___) =>
//                         const Icon(Icons.image_not_supported),
//                   ),
//                 ),
//               const SizedBox(height: 12), // Increased spacing
//               Text(
//                 item.name,
//                 style: GoogleFonts.notoSansBengali(
//                   // Bengali font
//                   fontSize: 18, // Slightly larger
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 item.department,
//                 style: GoogleFonts.notoSansBengali(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // ---- vertical separator ----
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Container(
//             width: 1,
//             height: 200,
//             color: Colors.grey.shade300,
//           ), // Thinner and lighter
//         ),
//         // ---- right side (rich markdown) ----
//         Expanded(child: _RichMarkdown(text: item.description)),
//       ],
//     ),
//   );
// }

// /* ------------------------------------------------- */
// /*                    MOBILE CARD                    */
// /* ------------------------------------------------- */
// class _MobileCard extends StatelessWidget {
//   final DataItem item;
//   const _MobileCard({required this.item});

//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       if (item.image.isNotEmpty)
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12), // Larger radius
//           child: CachedNetworkImage(
//             imageUrl: item.image,
//             height: 160, // Slightly taller
//             width: 160,
//             fit: BoxFit.fitWidth,
//             placeholder: (_, __) =>
//                 const Center(child: CircularProgressIndicator(strokeWidth: 2)),
//             errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
//           ),
//         ),
//       const SizedBox(height: 16), // Increased
//       Text(
//         item.name,
//         style: GoogleFonts.notoSansBengali(
//           fontSize: 20, // Larger for mobile
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       const SizedBox(height: 6),
//       Text(
//         item.department,
//         style: GoogleFonts.notoSansBengali(
//           fontSize: 15,
//           color: Colors.grey[600],
//         ),
//       ),
//       const SizedBox(height: 16),
//       _RichMarkdown(text: item.description),
//       const SizedBox(height: 24), // More space between cards
//     ],
//   );
// }

// /* ------------------------------------------------- */
// /*                RICH MARKDOWN WIDGET               */
// /* ------------------------------------------------- */
// class _RichMarkdown extends StatelessWidget {
//   final String text;
//   const _RichMarkdown({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     // Parse Markdown → AST
//     final doc = md.Document(
//       extensionSet: md.ExtensionSet.gitHubFlavored,
//       inlineSyntaxes: [md.EmojiSyntax()],
//     );
//     final nodes = doc.parseLines(text.split('\n'));

//     // Build widgets
//     final builder = _MarkdownBuilder(context: context);
//     for (final n in nodes) n.accept(builder);

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8), // More padding
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: builder.widgets,
//       ),
//     );
//   }
// }

// /* ------------------------------------------------- */
// /*               CUSTOM MARKDOWN BUILDER              */
// /* ------------------------------------------------- */
// class _MarkdownBuilder implements md.NodeVisitor {
//   final List<Widget> widgets = [];
//   final BuildContext context;

//   // list-type stack (ul/ol) + counters for ordered lists
//   final List<bool> _orderedStack = [];
//   final List<int> _counterStack = [];

//   // Buffer for paragraph collection
//   final List<Widget> _paragraphBuffer = [];
//   bool _inParagraph = false;

//   _MarkdownBuilder({required this.context});

//   // Base text style with Bengali support and better line height
//   TextStyle _baseTextStyle({
//     FontWeight? fontWeight,
//     FontStyle? fontStyle,
//     Color? color,
//   }) {
//     return GoogleFonts.notoSansBengali(
//       fontSize: 15,
//       height: 1.6, // Better line height for readability
//       fontWeight: fontWeight ?? FontWeight.normal,
//       fontStyle: fontStyle ?? FontStyle.normal,
//       color: color ?? Colors.black87,
//     );
//   }

//   // ---------- helpers ----------
//   String _textFrom(List<md.Node>? children) =>
//       children?.map((e) => e is md.Text ? e.text : '').join() ?? '';

//   Color? _parseColor(String style) {
//     final m = RegExp(
//       r'color\s*:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|[a-zA-Z]+)',
//     ).firstMatch(style);
//     if (m == null) return null;
//     final v = m.group(1)!;

//     if (v.startsWith('#')) {
//       var hex = v.replaceFirst('#', '');
//       if (hex.length == 3) hex = hex.split('').map((c) => c + c).join();
//       return Color(int.parse('0xFF$hex'));
//     }
//     final map = {
//       'red': Colors.red,
//       'green': Colors.green,
//       'blue': Colors.blue,
//       'orange': Colors.orange,
//       'purple': Colors.purple,
//       'yellow': Colors.yellow,
//       'pink': Colors.pink,
//       'cyan': Colors.cyan,
//       'brown': Colors.brown,
//       'black': Colors.black,
//       'white': Colors.white,
//       'gray': Colors.grey,
//       'lime': Colors.lime,
//       'indigo': Colors.indigo,
//       'teal': Colors.teal,
//       'amber': Colors.amber,
//     };
//     return map[v.toLowerCase()];
//   }

//   Future<void> _openUrl(String url) async {
//     final uri = Uri.tryParse(url);
//     if (uri == null) return;
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Cannot open $url')));
//     }
//   }

//   void _flushParagraph() {
//     if (_paragraphBuffer.isNotEmpty && _inParagraph) {
//       widgets.add(
//         Padding(
//           padding: const EdgeInsets.only(
//             bottom: 12,
//           ), // Space between paragraphs
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: _paragraphBuffer,
//           ),
//         ),
//       );
//       _paragraphBuffer.clear();
//       _inParagraph = false;
//     }
//   }

//   // ---------- visitor ----------
//   @override
//   void visitText(md.Text text) {
//     final s = text.text.trim();
//     if (s.isEmpty) return;
//     final textWidget = Text(s, style: _baseTextStyle());
//     if (_inParagraph) {
//       _paragraphBuffer.add(textWidget);
//     } else {
//       widgets.add(textWidget);
//     }
//   }

//   @override
//   bool visitElementBefore(md.Element el) {
//     final children = el.children;

//     switch (el.tag) {
//       /* ---------- headings ---------- */
//       case 'h1':
//         _flushParagraph();
//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16), // More space
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _textFrom(children),
//                   style: GoogleFonts.notoSansBengali(
//                     fontSize: 24, // Larger
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[800],
//                   ),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.only(top: 4),
//                   height: 2,
//                   width: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.blue[300],
//                     borderRadius: BorderRadius.circular(1),
//                   ),
//                 ), // Underline for beauty
//               ],
//             ),
//           ),
//         );
//         return false;
//       case 'h2':
//         _flushParagraph();
//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             child: Text(
//               _textFrom(children),
//               style: GoogleFonts.notoSansBengali(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue[700],
//               ),
//             ),
//           ),
//         );
//         return false;

//       /* ---------- paragraph ---------- */
//       case 'p':
//         _flushParagraph();
//         _inParagraph = true;
//         return true;

//       /* ---------- lists ---------- */
//       case 'ul':
//         _flushParagraph();
//         _orderedStack.add(false);
//         _counterStack.add(0);
//         return true;
//       case 'ol':
//         _flushParagraph();
//         _orderedStack.add(true);
//         _counterStack.add(1);
//         return true;
//       case 'li':
//         final ordered = _orderedStack.isNotEmpty && _orderedStack.last;
//         final counter = _counterStack.isNotEmpty ? _counterStack.last : 1;
//         final bullet = ordered ? '$counter. ' : '• ';
//         final txt = _textFrom(children);

//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 4), // More space
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(right: 8),
//                   child: Text(
//                     bullet,
//                     style: GoogleFonts.notoSansBengali(
//                       fontSize: 15,
//                       color: Colors.blue[600], // Colored bullets
//                     ),
//                   ),
//                 ),
//                 Expanded(child: Text(txt, style: _baseTextStyle())),
//               ],
//             ),
//           ),
//         );

//         if (_counterStack.isNotEmpty) {
//           _counterStack[_counterStack.length - 1]++;
//         }
//         return false;

//       /* ---------- link ---------- */
//       case 'a':
//         final href = el.attributes['href'];
//         final txt = _textFrom(children);
//         if (href != null && href.isNotEmpty) {
//           _flushParagraph();
//           widgets.add(
//             InkWell(
//               onTap: () => _openUrl(href),
//               borderRadius: BorderRadius.circular(4),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                 child: Text(
//                   txt,
//                   style: GoogleFonts.notoSansBengali(
//                     color: Colors.blue[700],
//                     decoration: TextDecoration.underline,
//                     decorationColor: Colors.blue[700],
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//             ),
//           );
//           return false;
//         }
//         break;

//       /* ---------- image ---------- */
//       case 'img':
//         final src = el.attributes['src'];
//         final alt = el.attributes['alt'] ?? '';
//         if (src != null && src.isNotEmpty) {
//           _flushParagraph();
//           widgets.add(
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(12), // Rounded
//                     child: CachedNetworkImage(
//                       imageUrl: src,
//                       placeholder: (_, __) => const Center(
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       errorWidget: (_, __, ___) =>
//                           const Icon(Icons.broken_image),
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       height: 200, // Fixed height for consistency
//                     ),
//                   ),
//                   if (alt.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: Text(
//                         alt,
//                         style: GoogleFonts.notoSansBengali(
//                           fontSize: 13,
//                           color: Colors.grey[600],
//                           fontStyle: FontStyle.italic,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//           return false;
//         }
//         break;

//       /* ---------- span (color) ---------- */
//       case 'span':
//         final style = el.attributes['style'];
//         final txt = _textFrom(children);
//         if (style != null && txt.isNotEmpty) {
//           final c = _parseColor(style);
//           if (_inParagraph) {
//             _paragraphBuffer.add(Text(txt, style: _baseTextStyle(color: c)));
//           } else {
//             widgets.add(Text(txt, style: _baseTextStyle(color: c)));
//           }
//           return false;
//         }
//         break;

//       /* ---------- strong / em ---------- */
//       case 'strong':
//         final txt = _textFrom(children);
//         final styledText = Text(
//           txt,
//           style: _baseTextStyle(fontWeight: FontWeight.bold),
//         );
//         if (_inParagraph) {
//           _paragraphBuffer.add(styledText);
//         } else {
//           widgets.add(styledText);
//         }
//         return false;
//       case 'em':
//         final txt = _textFrom(children);
//         final styledText = Text(
//           txt,
//           style: _baseTextStyle(fontStyle: FontStyle.italic),
//         );
//         if (_inParagraph) {
//           _paragraphBuffer.add(styledText);
//         } else {
//           widgets.add(styledText);
//         }
//         return false;

//       /* ---------- inline code ---------- */
//       case 'code':
//         final txt = _textFrom(children);
//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100], // Lighter background
//                 borderRadius: BorderRadius.circular(6), // Rounded
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: Text(
//                 txt,
//                 style: GoogleFonts.notoSansMono(
//                   // Monospace for code
//                   fontSize: 14,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ),
//         );
//         return false;
//     }
//     return true;
//   }

//   @override
//   void visitElementAfter(md.Element el) {
//     // close list stacks
//     if (el.tag == 'ul' || el.tag == 'ol') {
//       if (_orderedStack.isNotEmpty) _orderedStack.removeLast();
//       if (_counterStack.isNotEmpty) _counterStack.removeLast();
//     }
//     // Close paragraph
//     if (el.tag == 'p') {
//       _flushParagraph();
//     }
//   }
// }
