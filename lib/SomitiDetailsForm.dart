// New form page for collecting details
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SomitiDetailsForm extends StatefulWidget {
  final String somitiType;
  final String divisionId;
  final String divisionName;
  final String districtId;
  final String districtName;
  final String? upazillaId;
  final String? upazillaName;

  const SomitiDetailsForm({
    super.key,
    required this.somitiType,
    required this.divisionId,
    required this.divisionName,
    required this.districtId,
    required this.districtName,
    this.upazillaId,
    this.upazillaName,
  });

  @override
  State<SomitiDetailsForm> createState() => _SomitiDetailsFormState();
}

class _SomitiDetailsFormState extends State<SomitiDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _presidentNameController =
      TextEditingController();
  final TextEditingController _presidentPhoneController =
      TextEditingController();
  final TextEditingController _secretaryNameController =
      TextEditingController();
  final TextEditingController _secretaryPhoneController =
      TextEditingController();
  final TextEditingController _treasurerNameController =
      TextEditingController();
  final TextEditingController _treasurerPhoneController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _establishmentDateController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set current date as default establishment date
    final now = DateTime.now();
    _establishmentDateController.text = "${now.day}/${now.month}/${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.somitiType == "zilla"
              ? "জেলা সমিতি তথ্য"
              : "উপজেলা সমিতি তথ্য",
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display selected location
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "নির্বাচিত এলাকা:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("বিভাগ: ${widget.divisionName}"),
                      Text("জেলা: ${widget.districtName}"),
                      if (widget.upazillaName != null)
                        Text("উপজেলা: ${widget.upazillaName}"),
                    ],
                  ),
                ),
              ),

              // President Information
              _buildSectionHeader("সভাপতির তথ্য"),
              _buildTextFormField(
                controller: _presidentNameController,
                label: "সভাপতির নাম",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'সভাপতির নাম প্রয়োজন';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _presidentPhoneController,
                label: "সভাপতির ফোন নম্বর",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ফোন নম্বর প্রয়োজন';
                  }
                  if (value.length != 11) {
                    return 'সঠিক ফোন নম্বর লিখুন';
                  }
                  return null;
                },
              ),

              // Secretary Information
              _buildSectionHeader("সাধারণ সম্পাদকের তথ্য"),
              _buildTextFormField(
                controller: _secretaryNameController,
                label: "সাধারণ সম্পাদকের নাম",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'সাধারণ সম্পাদকের নাম প্রয়োজন';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _secretaryPhoneController,
                label: "সাধারণ সম্পাদকের ফোন নম্বর",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ফোন নম্বর প্রয়োজন';
                  }
                  if (value.length != 11) {
                    return 'সঠিক ফোন নম্বর লিখুন';
                  }
                  return null;
                },
              ),

              // Treasurer Information
              _buildSectionHeader("কোষাধ্যক্ষের তথ্য"),
              _buildTextFormField(
                controller: _treasurerNameController,
                label: "কোষাধ্যক্ষের নাম",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'কোষাধ্যক্ষের নাম প্রয়োজন';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _treasurerPhoneController,
                label: "কোষাধ্যক্ষের ফোন নম্বর",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ফোন নম্বর প্রয়োজন';
                  }
                  if (value.length != 11) {
                    return 'সঠিক ফোন নম্বর লিখুন';
                  }
                  return null;
                },
              ),

              // Additional Information
              _buildSectionHeader("অতিরিক্ত তথ্য"),
              _buildTextFormField(
                controller: _addressController,
                label: "সমিতির ঠিকানা",
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ঠিকানা প্রয়োজন';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _emailController,
                label: "ইমেইল (ঐচ্ছিক)",
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                controller: _establishmentDateController,
                label: "স্থাপিত তারিখ",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'স্থাপিত তারিখ প্রয়োজন';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "সমিতি তৈরি করুন",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Create the data structure for Firebase with hierarchy
        final somitiData = {
          'somitiType': widget.somitiType,
          'president': {
            'name': _presidentNameController.text,
            'phone': _presidentPhoneController.text,
          },
          'secretary': {
            'name': _secretaryNameController.text,
            'phone': _secretaryPhoneController.text,
          },
          'treasurer': {
            'name': _treasurerNameController.text,
            'phone': _treasurerPhoneController.text,
          },
          'address': _addressController.text,
          'email': _emailController.text.isNotEmpty
              ? _emailController.text
              : null,
          'establishmentDate': _establishmentDateController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Save to Firebase with hierarchical structure: division -> district -> upazilla
        final CollectionReference divisionsCollection = FirebaseFirestore
            .instance
            .collection('divisions');

        // Create or update division document
        final divisionDoc = divisionsCollection.doc(widget.divisionId);
        await divisionDoc.set({
          'id': widget.divisionId,
          'name': widget.divisionName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create or update district document within division
        final districtsCollection = divisionDoc.collection('districts');
        final districtDoc = districtsCollection.doc(widget.districtId);
        await districtDoc.set({
          'id': widget.districtId,
          'name': widget.districtName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (widget.somitiType == "upazilla" &&
            widget.upazillaId != null &&
            widget.upazillaName != null) {
          // For upazilla somiti, create upazilla document within district
          final upazillasCollection = districtDoc.collection('upazillas');
          final upazillaDoc = upazillasCollection.doc(widget.upazillaId);

          // Save somiti data within upazilla document
          await upazillaDoc.set({
            'id': widget.upazillaId,
            'name': widget.upazillaName,
            'somiti': somitiData,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // For zilla somiti, save somiti data within district document
          await districtDoc.set({
            'somiti': somitiData,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('সমিতি সফলভাবে তৈরি হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _presidentNameController.dispose();
    _presidentPhoneController.dispose();
    _secretaryNameController.dispose();
    _secretaryPhoneController.dispose();
    _treasurerNameController.dispose();
    _treasurerPhoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _establishmentDateController.dispose();
    super.dispose();
  }
}
