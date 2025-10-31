import 'package:flutter/material.dart';

class RUInfoPage extends StatefulWidget {
  const RUInfoPage({super.key});

  @override
  State<RUInfoPage> createState() => _RUInfoPageState();
}

class _RUInfoPageState extends State<RUInfoPage> {
  String? selectedCategory;

  final List<String> categories = [
    'Department',
    'Hall',
    'Prosashon',
    'Police',
    'Doctor',
    'Ambulance',
    'Research',
    'IEEE',
    'Science Club',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RU Info'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  selectedColor: Colors.blue.shade400,
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (selectedCategory != null) ...[
              Text(
                'You selected: $selectedCategory',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _categoryInfoList(selectedCategory!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryInfoList(String category) {
    // 20 demo items
    List<Map<String, String>> items = List.generate(20, (index) {
      return {
        'name': '$category Item ${index + 1}',
        'info': 'Detailed info for $category item ${index + 1}',
      };
    });

    // Customize some categories if needed
    if (category == 'Department') {
      items = List.generate(20, (index) {
        return {
          'name': 'Department ${index + 1}',
          'info': 'Department info and details ${index + 1}',
        };
      });
    } else if (category == 'Hall') {
      items = List.generate(20, (index) {
        return {
          'name': 'Hall ${index + 1}',
          'info': 'Hall info, male/female, room details ${index + 1}',
        };
      });
    } else if (category == 'Doctor') {
      items = List.generate(20, (index) {
        return {
          'name': 'Dr. Name ${index + 1}',
          'info': 'Specialty and contact info ${index + 1}',
        };
      });
    } else if (category == 'Ambulance') {
      items = List.generate(20, (index) {
        return {
          'name': 'Ambulance ${index + 1}',
          'info': 'Call number: 017XXXXXXXX${index + 1}',
        };
      });
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(item['name']!),
            subtitle: Text(item['info']!),
            trailing: category == 'Doctor' || category == 'Ambulance'
                ? ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${item['name']}...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text(
                      'Call',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
