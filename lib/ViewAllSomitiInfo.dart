// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class ViewAllSomitiPage extends StatefulWidget {
//   const ViewAllSomitiPage({super.key});

//   @override
//   State<ViewAllSomitiPage> createState() => _ViewAllSomitiPageState();
// }

// class _ViewAllSomitiPageState extends State<ViewAllSomitiPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _allSomitiData = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchAllSomitiData();
//   }

//   Future<void> _fetchAllSomitiData() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       // Fetch all divisions
//       final divisionsSnapshot = await _firestore.collection('divisions').get();

//       List<Map<String, dynamic>> allData = [];

//       for (var divisionDoc in divisionsSnapshot.docs) {
//         final divisionData = divisionDoc.data();
//         divisionData['id'] = divisionDoc.id;

//         // Fetch districts for this division
//         final districtsSnapshot = await divisionDoc.reference
//             .collection('districts')
//             .get();

//         for (var districtDoc in districtsSnapshot.docs) {
//           final districtData = districtDoc.data();
//           districtData['id'] = districtDoc.id;
//           districtData['division'] = divisionData;

//           // Check if this district has a somiti (zilla somiti)
//           if (districtData.containsKey('somiti')) {
//             final somitiData = districtData['somiti'] as Map<String, dynamic>;
//             allData.add({
//               'type': 'zilla',
//               'division': divisionData,
//               'district': districtData,
//               'somiti': somitiData,
//             });
//           }

//           // Fetch upazillas for this district
//           final upazillasSnapshot = await districtDoc.reference
//               .collection('upazillas')
//               .get();

//           for (var upazillaDoc in upazillasSnapshot.docs) {
//             final upazillaData = upazillaDoc.data();
//             upazillaData['id'] = upazillaDoc.id;

//             // Check if this upazilla has a somiti
//             if (upazillaData.containsKey('somiti')) {
//               final somitiData = upazillaData['somiti'] as Map<String, dynamic>;
//               allData.add({
//                 'type': 'upazilla',
//                 'division': divisionData,
//                 'district': districtData,
//                 'upazilla': upazillaData,
//                 'somiti': somitiData,
//               });
//             }
//           }
//         }
//       }

//       setState(() {
//         _allSomitiData = allData;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching data: $e');
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('ডেটা লোড করতে সমস্যা: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _buildSomitiCard(Map<String, dynamic> somitiData) {
//     final somitiType = somitiData['type'];
//     final division = somitiData['division'] as Map<String, dynamic>;
//     final district = somitiData['district'] as Map<String, dynamic>;
//     final somitiInfo = somitiData['somiti'] as Map<String, dynamic>;

//     final president = somitiInfo['president'] as Map<String, dynamic>;
//     final secretary = somitiInfo['secretary'] as Map<String, dynamic>;
//     final treasurer = somitiInfo['treasurer'] as Map<String, dynamic>;

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   somitiType == 'zilla' ? 'জেলা সমিতি' : 'উপজেলা সমিতি',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 Chip(
//                   label: Text(
//                     somitiType == 'zilla' ? 'জেলা' : 'উপজেলা',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   backgroundColor: somitiType == 'zilla'
//                       ? Colors.blue
//                       : Colors.orange,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text('বিভাগ: ${division['name']}'),
//             Text('জেলা: ${district['name']}'),
//             if (somitiType == 'upazilla')
//               Text('উপজেলা: ${somitiData['upazilla']['name']}'),

//             const Divider(height: 24),

//             _buildPersonInfo('সভাপতি', president),
//             _buildPersonInfo('সাধারণ সম্পাদক', secretary),
//             _buildPersonInfo('কোষাধ্যক্ষ', treasurer),

//             const Divider(height: 24),

//             if (somitiInfo['address'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text('ঠিকানা: ${somitiInfo['address']}'),
//               ),

//             if (somitiInfo['email'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text('ইমেইল: ${somitiInfo['email']}'),
//               ),

//             if (somitiInfo['establishmentDate'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text(
//                   'স্থাপিত তারিখ: ${somitiInfo['establishmentDate']}',
//                 ),
//               ),

//             if (somitiInfo['createdAt'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text(
//                   'তৈরির তারিখ: ${_formatTimestamp(somitiInfo['createdAt'])}',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPersonInfo(String title, Map<String, dynamic> person) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$title: ${person['name']}',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Text('ফোন: ${person['phone']}'),
//         ],
//       ),
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       return '${date.day}/${date.month}/${date.year}';
//     }
//     return 'তারিখ পাওয়া যায়নি';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('সমস্ত সমিতির তালিকা'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchAllSomitiData,
//             tooltip: 'রিফ্রেশ করুন',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _allSomitiData.isEmpty
//           ? const Center(
//               child: Text(
//                 'কোন সমিতি পাওয়া যায়নি',
//                 style: TextStyle(fontSize: 18),
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: _fetchAllSomitiData,
//               child: ListView.builder(
//                 itemCount: _allSomitiData.length,
//                 itemBuilder: (context, index) {
//                   return _buildSomitiCard(_allSomitiData[index]);
//                 },
//               ),
//             ),
//     );
//   }
// }
