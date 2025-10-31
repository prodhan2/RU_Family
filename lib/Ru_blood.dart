import 'dart:math';
import 'package:flutter/material.dart';

class RUBloodPage extends StatefulWidget {
  const RUBloodPage({super.key});

  @override
  State<RUBloodPage> createState() => _RUBloodPageState();
}

class _RUBloodPageState extends State<RUBloodPage> {
  final Random random = Random();

  // Dropdown filter
  String selectedBlood = 'All';
  final bloodTypes = ['All', 'A+', 'B+', 'O+', 'AB+'];

  // Search
  String searchQuery = '';

  // Generate random donors
  List<Map<String, dynamic>> generateDonors(int count) {
    final List<String> names = [
      'Rahim',
      'Karim',
      'Salma',
      'Anika',
      'Rina',
      'Jahid',
      'Tanvir',
      'Nabila',
      'Sabbir',
      'Mitu',
      'Hasan',
      'Fatema',
      'Rafi',
      'Shirin',
    ];
    final types = ['A+', 'B+', 'O+', 'AB+'];
    return List.generate(count, (index) {
      final type = types[random.nextInt(types.length)];
      final name = names[random.nextInt(names.length)];
      final daysLeft = random.nextInt(30);
      final isAvailable = random.nextBool();
      return {
        'name': name,
        'type': type,
        'available': isAvailable,
        'daysLeft': daysLeft,
      };
    });
  }

  late List<Map<String, dynamic>> donors;

  @override
  void initState() {
    super.initState();
    donors = generateDonors(20);
  }

  @override
  Widget build(BuildContext context) {
    // Filter & search
    final filteredDonors = donors.where((donor) {
      final matchesBlood = selectedBlood == 'All'
          ? true
          : donor['type'] == selectedBlood;
      final matchesSearch = donor['name'].toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchesBlood && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RU Blood'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Row: Search + Dropdown
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      filled: true,
                      fillColor: Colors.red.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedBlood,
                    items: bloodTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.red.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedBlood = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Request Blood Button
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_alert, color: Colors.white),
              label: const Text(
                'Request Blood',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 12),

            // Total Members
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total Donors: ${filteredDonors.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Donor List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: filteredDonors.length,
                itemBuilder: (context, index) {
                  final donor = filteredDonors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          donor['type'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      title: Text('${index + 1}. ${donor['name']}'),
                      subtitle: Text(
                        donor['available']
                            ? 'Available'
                            : 'Next donation in ${donor['daysLeft']} days',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Call',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
