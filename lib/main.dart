import 'package:flutter/material.dart';
import 'package:ru_family/ViewAllSomitiINfo.dart';
import 'package:ru_family/somitiCreate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'সমিতি অ্যাপ',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white, // White background
        useMaterial3: true,
      ),
      home: const SomitiPage(),
    );
  }
}

class SomitiPage extends StatelessWidget {
  const SomitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // Solid Green
        title: const Text(
          'সমিতি',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'আপনি কি করতে চান?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // ================= Create Somiti Button =================
              GreenButton(
                label: 'সমিতি তৈরি করুন',
                icon: Icons.add_box_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SomitiChoicePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ================= Join Somiti Button =================
              GreenButton(
                label: 'সমিতিতে যোগদান করুন',
                icon: Icons.person_add_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewAllSomitiPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ================= Enter Somiti Button =================
              GreenButton(
                label: 'সমিতিতে ঢুকুন',
                icon: Icons.login,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnterSomitiPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Green Solid Button Widget =================
class GreenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const GreenButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Solid Green
        foregroundColor: Colors.white, // White text & icon
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
      ),
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
    );
  }
}

// ==================== Demo Pages ====================
class EnterSomitiPage extends StatelessWidget {
  const EnterSomitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সমিতিতে ঢুকুন'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'এখানে সমিতির ড্যাশবোর্ড/লিস্ট দেখানো হবে।',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
