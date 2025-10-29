import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // <-- for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class MemberDetailsPage extends StatelessWidget {
  final Map<String, dynamic> memberData;

  const MemberDetailsPage({super.key, required this.memberData});

  // ==============================================
  // Generate PDF (Universal)
  // ==============================================
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final name = memberData['name'] ?? 'নাম পাওয়া যায়নি';
    final bloodGroup = memberData['bloodGroup'] ?? 'N/A';
    final email = memberData['email'] ?? 'N/A';
    final hall = memberData['hall'] ?? 'N/A';
    final department = memberData['department'] ?? 'N/A';
    final session = memberData['session'] ?? 'N/A';
    final emergencyContact = memberData['emergencyContact'] ?? 'N/A';
    final mobileNumber = memberData['mobileNumber'] ?? 'N/A';
    final socialMediaId = memberData['socialMediaId'] ?? 'N/A';
    final permanentAddress = memberData['permanentAddress'] ?? 'N/A';
    final presentAddress = memberData['presentAddress'] ?? 'N/A';
    final universityId = memberData['universityId'] ?? 'N/A';
    final somitiName = memberData['somitiName'] ?? 'N/A';

    String createdAt = 'N/A';
    final raw = memberData['createdAt'];
    if (raw != null) {
      DateTime? dt;
      if (raw is Timestamp)
        dt = raw.toDate();
      else if (raw is DateTime)
        dt = raw;
      if (dt != null) createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }

    final now = DateTime.now();
    final currentDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'RU Somiti Manager',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 28,
                      color: PdfColors.teal,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'সদস্য প্রোফাইল',
                    style: pw.TextStyle(font: boldFont, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'তৈরি: $currentDateTime',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.teal),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal100,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 36,
                        color: PdfColors.teal700,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(font: boldFont, fontSize: 22),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Icon(
                            const pw.IconData(0xe800),
                            size: 18,
                            color: PdfColors.red,
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            'রক্তের গ্রুপ: $bloodGroup',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 15,
                              color: PdfColors.red700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 28),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _pdfRow('সমিতি', somitiName, font, boldFont),
                _pdfRow('বিশ্ববিদ্যালয় আইডি', universityId, font, boldFont),
                _pdfRow('সেশন', session, font, boldFont),
                _pdfRow('হল', hall, font, boldFont),
                _pdfRow('বিভাগ', department, font, boldFont),
                _pdfRow('ইমেইল', email, font, boldFont),
                _pdfRow('মোবাইল', mobileNumber, font, boldFont),
                _pdfRow('জরুরি যোগাযোগ', emergencyContact, font, boldFont),
                _pdfRow('সোশ্যাল মিডিয়া', socialMediaId, font, boldFont),
                _pdfRow('বর্তমান ঠিকানা', presentAddress, font, boldFont),
                _pdfRow('স্থায়ী ঠিকানা', permanentAddress, font, boldFont),
                _pdfRow('নিবন্ধনের তারিখ', createdAt, font, boldFont),
              ],
            ),

            pw.Spacer(),

            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Powered by RU Somiti Manager',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.TableRow _pdfRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
        ),
      ],
    );
  }

  // ==============================================
  // Save & Share PDF (Platform Aware)
  // ==============================================
  Future<void> _saveAndSharePdf(BuildContext context) async {
    try {
      final pdfData = await _generatePdf();
      final fileName =
          'Member_${memberData['name']?.replaceAll(' ', '_') ?? 'Profile'}.pdf';

      if (kIsWeb) {
        // Web: Direct download
        await Printing.layoutPdf(
          onLayout: (_) => pdfData,
          name: fileName,
          // Web-এ sharePdf() কাজ করে না, তাই layoutPdf দিয়ে ডাউনলোড
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ডাউনলোড শুরু হয়েছে!')),
        );
      } else {
        // Android/iOS: Save + Share
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfData);

        await Printing.sharePdf(bytes: pdfData, filename: fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF তৈরি করতে সমস্যা: $e')));
    }
  }

  // ==============================================
  // UI Build
  // ==============================================
  @override
  Widget build(BuildContext context) {
    final name = memberData['name'] ?? 'নাম পাওয়া যায়নি';
    final bloodGroup = memberData['bloodGroup'] ?? 'N/A';
    final email = memberData['email'] ?? 'N/A';
    final hall = memberData['hall'] ?? 'N/A';
    final department = memberData['department'] ?? 'N/A';
    final session = memberData['session'] ?? 'N/A';
    final emergencyContact = memberData['emergencyContact'] ?? 'N/A';
    final mobileNumber = memberData['mobileNumber'] ?? 'N/A';
    final socialMediaId = memberData['socialMediaId'] ?? 'N/A';
    final permanentAddress = memberData['permanentAddress'] ?? 'N/A';
    final presentAddress = memberData['presentAddress'] ?? 'N/A';
    final universityId = memberData['universityId'] ?? 'N/A';
    final somitiName = memberData['somitiName'] ?? 'N/A';

    String createdAt = 'N/A';
    final raw = memberData['createdAt'];
    if (raw != null) {
      DateTime? dt;
      if (raw is Timestamp)
        dt = raw.toDate();
      else if (raw is DateTime)
        dt = raw;
      if (dt != null) createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Save PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'PDF ডাউনলোড/শেয়ার করুন',
            onPressed: () => _saveAndSharePdf(context),
          ),
          // Print
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'প্রিন্ট করুন',
            onPressed: () async {
              final pdfData = await _generatePdf();
              await Printing.layoutPdf(
                onLayout: (_) => pdfData,
                name: 'Member_$name.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.teal.shade50,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.bloodtype,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                bloodGroup,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Divider(thickness: 1.8, color: Colors.teal),
                const SizedBox(height: 16),

                _buildInfoRow(Icons.groups, 'সমিতি', somitiName),
                _buildInfoRow(
                  Icons.school,
                  'বিশ্ববিদ্যালয় আইডি',
                  universityId,
                ),
                _buildInfoRow(Icons.calendar_today, 'সেশন', session),
                _buildInfoRow(Icons.home, 'হল', hall),
                _buildInfoRow(Icons.book, 'বিভাগ', department),
                _buildInfoRow(Icons.email, 'ইমেইল', email),
                _buildInfoRow(Icons.phone, 'মোবাইল', mobileNumber),
                _buildInfoRow(
                  Icons.security,
                  'জরুরি যোগাযোগ',
                  emergencyContact,
                ),
                _buildInfoRow(Icons.share, 'সোশ্যাল মিডিয়া', socialMediaId),
                _buildInfoRow(
                  Icons.location_on,
                  'বর্তমান ঠিকানা',
                  presentAddress,
                ),
                _buildInfoRow(
                  Icons.location_city,
                  'স্থায়ী ঠিকানা',
                  permanentAddress,
                ),
                _buildInfoRow(Icons.access_time, 'নিবন্ধনের তারিখ', createdAt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
