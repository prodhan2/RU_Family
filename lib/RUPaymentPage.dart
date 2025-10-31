import 'package:flutter/material.dart';

class RUPaymentPage extends StatefulWidget {
  const RUPaymentPage({super.key});

  @override
  State<RUPaymentPage> createState() => _RUPaymentPageState();
}

class _RUPaymentPageState extends State<RUPaymentPage> {
  // Payment Categories
  final List<String> categories = [
    'Hall Fee',
    'Semester Admission',
    'Exam Fee',
  ];
  String selectedCategory = 'Hall Fee';

  // Payment Method
  final List<String> methods = ['Bkash', 'Rocket', 'Nagad', 'Bank'];
  String selectedMethod = 'Bkash';

  // Hall Fee Months
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Hall fee status (randomly assigned)
  Map<String, bool> hallPaid = {};

  // Semester Admission
  final List<String> semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
  ];
  Map<String, bool> semesterPaid = {};

  // Exam Fee (semester.part)
  final List<String> examList = [
    '1.1',
    '1.2',
    '2.1',
    '2.2',
    '3.1',
    '3.2',
    '4.1',
    '4.2',
  ];
  Map<String, bool> examPaid = {};

  @override
  void initState() {
    super.initState();
    // Randomly assign paid/due for demo
    for (var m in months) hallPaid[m] = m.hashCode % 3 == 0;
    for (var s in semesters) semesterPaid[s] = s.hashCode % 2 == 0;
    for (var e in examList) examPaid[e] = e.hashCode % 2 == 0;
  }

  // Fix: return type non-nullable, so always return a Widget
  Widget categoryWidget() {
    if (selectedCategory == 'Hall Fee') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: months.map((month) {
          bool paid = hallPaid[month]!;
          return ListTile(
            title: Text(month),
            trailing: Text(
              paid ? 'Paid' : 'Due (৳100)',
              style: TextStyle(
                color: paid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      );
    } else if (selectedCategory == 'Semester Admission') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: semesters.map((sem) {
          bool paid = semesterPaid[sem]!;
          return ListTile(
            title: Text(sem),
            trailing: Text(
              paid ? 'Payment Success' : 'Due (৳15,000)',
              style: TextStyle(
                color: paid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      );
    } else if (selectedCategory == 'Exam Fee') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: examList.map((exam) {
          bool paid = examPaid[exam]!;
          return ListTile(
            title: Text('Semester $exam'),
            trailing: Text(
              paid ? 'Paid (৳2,000)' : 'Due (৳2,000)',
              style: TextStyle(
                color: paid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      );
    }

    // Fallback
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Page'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white, // text & icons white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Category
            const Text(
              'Choose Your Payment Category',
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
                  selectedColor: Colors.purple.shade300,
                  backgroundColor: Colors.purple.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.purple,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Payment Method
            const Text(
              'Choose Your Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: methods.map((method) {
                final isSelected = method == selectedMethod;
                return ChoiceChip(
                  label: Text(method),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedMethod = method;
                    });
                  },
                  selectedColor: Colors.green.shade400,
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.green,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // List of dues/payments
            Expanded(child: SingleChildScrollView(child: categoryWidget())),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Payment Info'),
                      content: Text(
                        'You have chosen $selectedCategory and will pay via $selectedMethod.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
