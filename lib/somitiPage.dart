import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ru_family/Authentication/Login.dart';
import 'package:ru_family/MakeSomiti/somitiCreate.dart';
import 'package:ru_family/member/memberRegistrationpage.dart';

class SomitiPage extends StatelessWidget {
  const SomitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // 🟦 নীল রঙ
        title: Text(
          'RUconnect+ App',
          style: GoogleFonts.notoSansBengali(
            // ✅ Google Font ব্যবহার (অন্যান্য টেক্সটের জন্য)
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
              // ================= Logo =================
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const Text(
                'আপনি কি করতে চান?',
                style: TextStyle(
                  fontFamily:
                      'CustomBangla2', // ✅ শুধু এখানে CustomBangla2 ব্যবহার
                  fontSize: 35,
                  // fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // ================= Login Buttons Row =================
              Row(
                children: [
                  Expanded(
                    child: BlueButton(
                      label: 'Login',
                      icon: Icons.login,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ================= Create Somiti Button =================
              BlueButton(
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
              BlueButton(
                label: 'জেলা, উপজেলা সমিতিতে যোগদান করুন ',
                icon: Icons.person_add_outlined,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MemberRegistrationPage(),
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

// ================= Blue Solid Button Widget =================
class BlueButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const BlueButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // 🟦 নীল ব্যাকগ্রাউন্ড
        foregroundColor: Colors.white, // সাদা টেক্সট ও আইকন
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
      ),
      icon: Icon(icon, size: 28),
      label: FittedBox(
        // ✅ অটো-স্কেলিং যোগ করা হয়েছে ছোট স্ক্রিনের জন্য
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            // ✅ Google Font ব্যবহার (বাটন লেবেলের জন্য)
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center, // ✅ ভালো ফিটিংয়ের জন্য
        ),
      ),
      onPressed: onTap,
    );
  }
}
