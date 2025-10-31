// 3. PDF_Resources
import 'package:flutter/material.dart';

class PDFResourcesPage extends StatelessWidget {
  const PDFResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Resources'),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 36,
              ),
              title: Text('Lecture ${index + 1} - CSE 101'),
              subtitle: Text('Size: ${(index + 1) * 1.8} MB • 2 days ago'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}

// 4. RU_Payment

void _showPaymentDialog(BuildContext context, Map<String, String> payment) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(payment['title']!),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Amount: ${payment['amount']}'),
          Text('Due: ${payment['due']}'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('Pay Now')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
