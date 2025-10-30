// lib/member_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  // Generate PDF
  // ==============================================
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final name = memberData['name'] ?? 'Name not found';
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
                    'RUConnect+ app',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 28,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Member Profile',
                    style: pw.TextStyle(font: boldFont, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: $currentDateTime',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.blue),
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
                    color: PdfColors.blue100,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 36,
                        color: PdfColors.blue700,
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
                            'Blood Group: $bloodGroup',
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
                _pdfRow('Somiti', somitiName, font, boldFont),
                _pdfRow('University ID', universityId, font, boldFont),
                _pdfRow('Session', session, font, boldFont),
                _pdfRow('Hall', hall, font, boldFont),
                _pdfRow('Department', department, font, boldFont),
                _pdfRow('Email', email, font, boldFont),
                _pdfRow('Mobile', mobileNumber, font, boldFont),
                _pdfRow('Emergency Contact', emergencyContact, font, boldFont),
                _pdfRow('Social Media', socialMediaId, font, boldFont),
                _pdfRow('Present Address', presentAddress, font, boldFont),
                _pdfRow('Permanent Address', permanentAddress, font, boldFont),
                _pdfRow('Registration Date', createdAt, font, boldFont),
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

  Future<void> _saveAndSharePdf(BuildContext context) async {
    try {
      final pdfData = await _generatePdf();
      final fileName =
          'Member_${memberData['name']?.replaceAll(' ', '_') ?? 'Profile'}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) => pdfData, name: fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ডাউনলোড শুরু হয়েছে!')),
        );
      } else {
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

  @override
  Widget build(BuildContext context) {
    final name = memberData['name'] ?? 'Name not found';
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
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // PDF Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'PDF ডাউনলোড/শেয়ার',
              onPressed: () => _saveAndSharePdf(context),
            ),
          ),
          // Print Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.print, color: Colors.white, size: 20),
              tooltip: 'প্রিন্ট',
              onPressed: () async {
                final pdfData = await _generatePdf();
                await Printing.layoutPdf(
                  onLayout: (_) => pdfData,
                  name: 'Member_${name.replaceAll(' ', '_')}.pdf',
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.bloodtype,
                              color: Colors.red,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              bloodGroup,
                              style: const TextStyle(
                                fontSize: 18,
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
              const SizedBox(height: 30),

              // Info List – Full Width, No Card
              _buildInfoTile(Icons.groups, 'সমিতি', somitiName),
              _buildInfoTile(Icons.school, 'ইউনিভার্সিটি আইডি', universityId),
              _buildInfoTile(Icons.calendar_today, 'সেশন', session),
              _buildInfoTile(Icons.home, 'হল', hall),
              _buildInfoTile(Icons.book, 'বিভাগ', department),
              _buildInfoTile(Icons.email, 'ইমেইল', email),
              _buildInfoTile(Icons.phone, 'মোবাইল', mobileNumber),
              _buildInfoTile(
                Icons.security,
                'ইমার্জেন্সি কন্টাক্ট',
                emergencyContact,
              ),
              _buildInfoTile(Icons.share, 'সোশ্যাল মিডিয়া', socialMediaId),
              _buildInfoTile(
                Icons.location_on,
                'বর্তমান ঠিকানা',
                presentAddress,
              ),
              _buildInfoTile(
                Icons.location_city,
                'স্থায়ী ঠিকানা',
                permanentAddress,
              ),
              _buildInfoTile(Icons.access_time, 'যোগের তারিখ', createdAt),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Powered by RU Somiti Manager',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
