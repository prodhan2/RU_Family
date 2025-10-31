import 'package:flutter/material.dart';

class RUMedicalPage extends StatefulWidget {
  const RUMedicalPage({super.key});

  @override
  State<RUMedicalPage> createState() => _RUMedicalPageState();
}

class _RUMedicalPageState extends State<RUMedicalPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedCategory;

  final List<String> categories = [
    'Get Medicine',
    'Get Report',
    'Get Appointment',
    'Doctor Contact',
  ];

  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RU Medical'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoggedIn ? _categorySelectionView() : _loginView(),
      ),
    );
  }

  Widget _loginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Your Student ID',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: idController,
          decoration: InputDecoration(
            hintText: 'Student ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter Your Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                setState(() {
                  isLoggedIn = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter ID and Password')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categorySelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Category',
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
              selectedColor: Colors.red.shade400,
              backgroundColor: Colors.red.shade50,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.red,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (selectedCategory != null) ...[
          Text(
            'You selected: $selectedCategory',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(child: _categoryDemoList(selectedCategory!)),
        ],
      ],
    );
  }

  Widget _categoryDemoList(String category) {
    if (category == 'Get Medicine') {
      final medicines = [
        {'name': 'Paracetamol', 'price': '৳50'},
        {'name': 'Vitamin C', 'price': '৳100'},
        {'name': 'Cough Syrup', 'price': '৳150'},
      ];
      return ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (_, index) {
          final m = medicines[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(m['name']!),
              trailing: Text(m['price']!),
              leading: const Icon(Icons.medical_services, color: Colors.red),
            ),
          );
        },
      );
    } else if (category == 'Get Report') {
      final reports = [
        'Blood Test - 15 Oct',
        'X-Ray - 20 Oct',
        'Eye Test - 25 Oct',
      ];
      return ListView.builder(
        itemCount: reports.length,
        itemBuilder: (_, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.article, color: Colors.red),
            title: Text(reports[index]),
          ),
        ),
      );
    } else if (category == 'Get Appointment') {
      final appointments = [
        'Dr. Rahim - General - 10 Nov',
        'Dr. Karim - Dental - 12 Nov',
        'Dr. Anika - Eye - 15 Nov',
      ];
      return ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (_, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.schedule, color: Colors.red),
            title: Text(appointments[index]),
          ),
        ),
      );
    } else if (category == 'Doctor Contact') {
      final doctors = [
        {'name': 'Dr. Rahim', 'contact': '017XXXXXXXX'},
        {'name': 'Dr. Karim', 'contact': '018XXXXXXXX'},
        {'name': 'Dr. Anika', 'contact': '019XXXXXXXX'},
      ];
      return ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (_, index) {
          final doc = doctors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.red),
              title: Text(doc['name']!),
              subtitle: Text('Contact: ${doc['contact']}'),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${doc['name']}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text(
                  'Call',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
