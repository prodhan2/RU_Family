// // TeacherDetailsPage (teachers_by_somiti.dart এর ভিতরে)
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:RUConnect_plus/Teacher/AddTeacher.dart';
// import 'package:url_launcher/url_launcher.dart';

// class TeacherDetailsPage extends StatelessWidget {
//   final Map<String, dynamic> teacherData;
//   final String docId;
//   final bool isAdmin;

//   const TeacherDetailsPage({
//     Key? key,
//     required this.teacherData,
//     required this.docId,
//     required this.isAdmin,
//   }) : super(key: key);

//   Future<void> _deleteTeacher(BuildContext context) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('ডিলিট করবেন?'),
//         content: const Text('এই শিক্ষকের তথ্য মুছে ফেলা হবে।'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('না'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('হ্যাঁ'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection('teachers')
//           .doc(docId)
//           .delete();
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('শিক্ষক মুছে ফেলা হয়েছে')),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String name = teacherData['name'] ?? 'N/A';
//     final String dept = teacherData['department'] ?? 'N/A';
//     final String mobile = teacherData['mobile'] ?? 'N/A';
//     final String blood = teacherData['bloodGroup'] ?? 'N/A';
//     final String address = teacherData['address'] ?? 'N/A';
//     final String addedBy = teacherData['addedByEmail'] ?? 'N/A';
//     final String somitiName = teacherData['somitiName'] ?? 'N/A';
//     final List<dynamic> social = teacherData['socialMedia'] ?? [];
//     final Timestamp? ts = teacherData['createdAt'];
//     final String date = ts != null
//         ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
//         : 'N/A';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(name),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: isAdmin
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => AddTeacherInfoPage(
//                           existingData: teacherData,
//                           docId: docId,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _deleteTeacher(context),
//                 ),
//               ]
//             : null,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Card(
//           elevation: 6,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundColor: Colors.blue.shade50,
//                       child: Text(
//                         name.isNotEmpty ? name[0].toUpperCase() : '?',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             name,
//                             style: const TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             dept,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (mobile.isNotEmpty)
//                       ElevatedButton.icon(
//                         onPressed: () => _makeCall(mobile),
//                         icon: const Icon(Icons.call),
//                         label: const Text('কল'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const Divider(height: 32, color: Colors.blue),

//                 // Info rows
//                 _infoRow('মোবাইল', mobile),
//                 _infoRow('রক্তের গ্রুপ', blood),
//                 _infoRow('ঠিকানা', address),
//                 _infoRow('যোগ করেছেন', addedBy),
//                 _infoRow('সমিতি', somitiName),
//                 _infoRow('যোগের তারিখ', date),

//                 if (social.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Text(
//                     'সোশ্যাল মিডিয়া:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...social.map(
//                     (link) => Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 4),
//                       child: InkWell(
//                         onTap: () => _openLink(link),
//                         child: Text(
//                           link,
//                           style: const TextStyle(
//                             color: Colors.blue,
//                             decoration: TextDecoration.underline,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 110,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(value, style: const TextStyle(color: Colors.black87)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _makeCall(String mobile) async {
//     final uri = Uri(scheme: 'tel', path: mobile);
//     if (await canLaunchUrl(uri)) await launchUrl(uri);
//   }

//   void _openLink(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
// }
