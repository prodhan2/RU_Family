// ---------------------------------------------------------------------
// PDF Settings Page with REAL-TIME PREVIEW (Web + Mobile) + Field Editing + Mobile Dropdown for Fields + PDF Footer + Mobile Fields Popup + Sort by Session + Asc/Desc + Responsive Mobile
// ---------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfSettingsPage extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final String somitiName;

  const PdfSettingsPage({
    super.key,
    required this.members,
    required this.somitiName,
  });

  @override
  State<PdfSettingsPage> createState() => _PdfSettingsPageState();
}

class _PdfSettingsPageState extends State<PdfSettingsPage> {
  static const List<String> _allFields = [
    'name',
    'bloodGroup',
    'mobileNumber',
    'department',
    'session',
    'email',
    'emergencyContact',
    'hall',
    'permanentAddress',
    'presentAddress',
    'socialMediaId',
    'universityId',
    'somitiName',
    'createdAt',
  ];

  Set<String> _selectedFields = {
    'name',
    'bloodGroup',
    'mobileNumber',
    'department',
    'session',
  };

  final Set<int> _selectedMemberIndices = {};
  String _sortBy = 'name';
  bool _isAscending = true;

  late List<Map<String, dynamic>> _localMembers;
  late List<Map<String, dynamic>> _selectedMembers;
  late List<int> _displayIndices;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _localMembers = widget.members
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    _displayIndices = List.generate(_localMembers.length, (index) => index);
    for (int i = 0; i < _localMembers.length; i++) {
      _selectedMemberIndices.add(i);
    }
    _updateSelectedMembers();
    _sortDisplayIndices();
    _regeneratePdf();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';
    if (ts is Timestamp) {
      return DateFormat('MMM d, y – h:mm a').format(ts.toDate());
    }
    return ts.toString();
  }

  void _editMember(int index) {
    final member = _localMembers[index];
    final fieldDisplayNames = {
      'name': 'Name',
      'bloodGroup': 'Blood Group',
      'mobileNumber': 'Mobile Number',
      'department': 'Department',
      'session': 'Session',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'hall': 'Hall',
      'permanentAddress': 'Permanent Address',
      'presentAddress': 'Present Address',
      'socialMediaId': 'Social Media ID',
      'universityId': 'University ID',
      'somitiName': 'Somiti Name',
      'createdAt': 'Registration Date',
    };

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${member['name'] ?? 'Member'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allFields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      initialValue: member[field]?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: fieldDisplayNames[field] ?? field,
                        border: const OutlineInputBorder(),
                      ),
                      onSaved: (val) {
                        member[field] = val?.isNotEmpty == true ? val : null;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              formKey.currentState?.save();
              Navigator.pop(ctx);
              _sortDisplayIndices();
              _regeneratePdf();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateSelectedMembers() {
    _selectedMembers = _selectedMemberIndices
        .map((i) => _localMembers[i])
        .toList();
  }

  void _sortDisplayIndices() {
    _displayIndices.sort((a, b) {
      final key = _sortBy;
      final aVal = _localMembers[a][key]?.toString().toLowerCase() ?? '';
      final bVal = _localMembers[b][key]?.toString().toLowerCase() ?? '';
      var comparison = aVal.compareTo(bVal);
      if (!_isAscending) comparison = -comparison;
      return comparison;
    });
  }

  void _showFieldsBottomSheet() {
    final fieldDisplayNamesLocal = {
      'name': 'Name',
      'bloodGroup': 'Blood Group',
      'mobileNumber': 'Mobile Number',
      'department': 'Department',
      'session': 'Session',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'hall': 'Hall',
      'permanentAddress': 'Permanent Address',
      'presentAddress': 'Present Address',
      'socialMediaId': 'Social Media ID',
      'universityId': 'University ID',
      'somitiName': 'Somiti Name',
      'createdAt': 'Registration Date',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Fields',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFields.clear();
                        });
                        _regeneratePdf();
                      },
                      child: const Text('Deselect All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFields = Set<String>.from(_allFields);
                        });
                        _regeneratePdf();
                      },
                      child: const Text('Select All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _allFields.map((field) {
                    return CheckboxListTile(
                      title: Text(
                        fieldDisplayNamesLocal[field] ?? field,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _selectedFields.contains(field),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedFields.add(field);
                          } else {
                            _selectedFields.remove(field);
                          }
                        });
                        _regeneratePdf();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _regeneratePdf() async {
    if (_selectedFields.isEmpty || _selectedMembers.isEmpty) {
      setState(() => _pdfBytes = null);
      return;
    }

    final pdf = pw.Document();
    final fieldLabels = {
      'name': 'Name',
      'bloodGroup': 'Blood Group',
      'mobileNumber': 'Mobile',
      'department': 'Department',
      'session': 'Session',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'hall': 'Hall',
      'permanentAddress': 'Permanent Address',
      'presentAddress': 'Present Address',
      'socialMediaId': 'Social Media',
      'universityId': 'University ID',
      'somitiName': 'Somiti',
      'createdAt': 'Registered At',
    };

    final sortedSelected = List<Map<String, dynamic>>.from(_selectedMembers);
    sortedSelected.sort((a, b) {
      final key = _sortBy;
      final aVal = a[key]?.toString().toLowerCase() ?? '';
      final bVal = b[key]?.toString().toLowerCase() ?? '';
      var comparison = aVal.compareTo(bVal);
      if (!_isAscending) comparison = -comparison;
      return comparison;
    });

    // Build table rows
    List<pw.TableRow> tableRows = [
      // Header row
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Sl No',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          ..._selectedFields.map(
            (f) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                fieldLabels[f] ?? f,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ];

    // Data rows
    for (int i = 0; i < sortedSelected.length; i++) {
      final member = sortedSelected[i];
      List<pw.Widget> rowChildren = [
        // Serial number
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 10)),
        ),
      ];

      for (String field in _selectedFields) {
        String value = field == 'createdAt'
            ? _formatTimestamp(member['createdAt'])
            : (member[field]?.toString() ?? 'N/A');

        pw.Widget cell;
        if (field == 'email' &&
            member['email'] != null &&
            member['email'].toString().isNotEmpty) {
          cell = pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Link(
              destination: 'mailto:${member['email']}',
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue400,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Open',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                ),
              ),
            ),
          );
        } else if (field == 'socialMediaId' &&
            member['socialMediaId'] != null &&
            member['socialMediaId'].toString().isNotEmpty) {
          String socialUrl =
              'https://www.facebook.com/${member['socialMediaId']}';
          cell = pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Link(
              destination: socialUrl,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue400,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Open',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                ),
              ),
            ),
          );
        } else {
          cell = pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          );
        }

        rowChildren.add(cell);
      }

      tableRows.add(pw.TableRow(children: rowChildren));
    }

    // Column widths: Serial fixed narrow, others flex
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(40),
      for (int i = 0; i < _selectedFields.length; i++)
        i + 1: const pw.FlexColumnWidth(1),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Powered by RUConnect+ App',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50, // soft modern blue
            borderRadius: pw.BorderRadius.circular(8), // rounded corners
            border: pw.Border.all(
              width: 0.5,
              color: PdfColors.blue200,
            ), // subtle border
          ),
          child: pw.Align(
            alignment: pw.Alignment.center, // center horizontally
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center, // center text
              children: [
                pw.Text(
                  '${widget.somitiName} Members List',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Generated: ${DateFormat('y-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Powered by RUConnect+ App',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            tableWidth: pw.TableWidth.max,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: columnWidths,
            children: tableRows,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total Members: ${_selectedMembers.length}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (mounted) setState(() => _pdfBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final fieldDisplayNames = {
      'name': 'Name',
      'bloodGroup': 'Blood Group',
      'mobileNumber': 'Mobile Number',
      'department': 'Department',
      'session': 'Session',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'hall': 'Hall',
      'permanentAddress': 'Permanent Address',
      'presentAddress': 'Present Address',
      'socialMediaId': 'Social Media ID',
      'universityId': 'University ID',
      'somitiName': 'Somiti Name',
      'createdAt': 'Registration Date',
    };

    final isWeb = kIsWeb;
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;
    final useChips = isWeb && isLargeScreen;
    final screenHeight = MediaQuery.of(context).size.height;
    final settingsHeight = isWeb ? 300.0 : screenHeight * 0.4;

    // Settings Panel
    final settingsPanel = LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Select Fields:',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (useChips) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allFields.map((field) {
                        return FilterChip(
                          label: Text(fieldDisplayNames[field] ?? field),
                          selected: _selectedFields.contains(field),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFields.add(field);
                              } else {
                                _selectedFields.remove(field);
                              }
                            });
                            _regeneratePdf();
                          },
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showFieldsBottomSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Fields: ${_selectedFields.length}/${_allFields.length}',
                              style: TextStyle(
                                fontSize: isLargeScreen ? 14 : 12,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: isLargeScreen ? 24 : 16),
                  Text(
                    '👥 Select Members:',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 12 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedMemberIndices.clear();
                            for (int i = 0; i < _localMembers.length; i++) {
                              _selectedMemberIndices.add(i);
                            }
                          });
                          _updateSelectedMembers();
                          _regeneratePdf();
                        },
                        child: Text(
                          'Select All',
                          style: TextStyle(fontSize: isLargeScreen ? 14 : 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedMemberIndices.clear();
                          });
                          _updateSelectedMembers();
                          _regeneratePdf();
                        },
                        child: Text(
                          'Deselect All',
                          style: TextStyle(fontSize: isLargeScreen ? 14 : 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isLargeScreen ? 8 : 4),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Sort by:',
                          style: TextStyle(fontSize: isLargeScreen ? 14 : 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Name'),
                            ),
                            DropdownMenuItem(
                              value: 'session',
                              child: Text('Session'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                              _sortDisplayIndices();
                              _regeneratePdf();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isLargeScreen ? 8 : 4),
                  SwitchListTile(
                    title: Text(
                      _isAscending ? 'Ascending' : 'Descending',
                      style: TextStyle(fontSize: isLargeScreen ? 14 : 12),
                    ),
                    value: _isAscending,
                    onChanged: (value) {
                      setState(() {
                        _isAscending = value;
                      });
                      _sortDisplayIndices();
                      _regeneratePdf();
                    },
                  ),
                  SizedBox(height: isLargeScreen ? 8 : 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _displayIndices.length,
                      itemBuilder: (context, displayIndex) {
                        final originalIndex = _displayIndices[displayIndex];
                        final name =
                            _localMembers[originalIndex]['name'] ?? 'Unknown';
                        return CheckboxListTile(
                          title: Text(
                            name,
                            style: TextStyle(fontSize: isLargeScreen ? 14 : 12),
                          ),
                          secondary: IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: isLargeScreen ? 20 : 18,
                            ),
                            onPressed: () => _editMember(originalIndex),
                          ),
                          value: _selectedMemberIndices.contains(originalIndex),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMemberIndices.add(originalIndex);
                              } else {
                                _selectedMemberIndices.remove(originalIndex);
                              }
                            });
                            _updateSelectedMembers();
                            _regeneratePdf();
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pdfBytes != null
                          ? () async {
                              await Printing.layoutPdf(
                                onLayout: (format) async => _pdfBytes!,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.download),
                      label: Text(
                        'Download PDF',
                        style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isLargeScreen ? 16 : 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Preview Panel
    final previewPanel = Expanded(
      child: _pdfBytes != null
          ? PdfPreview(build: (format) async => _pdfBytes!)
          : const Center(
              child: Text('Select fields and members to preview PDF'),
            ),
    );

    // Responsive Layout
    if (isWeb && isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Export – Live Preview'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Row(
          children: [
            SizedBox(width: 400, child: settingsPanel),
            const VerticalDivider(width: 1),
            previewPanel,
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Export'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            SizedBox(height: settingsHeight, child: settingsPanel),
            const Divider(),
            Expanded(child: previewPanel),
          ],
        ),
      );
    }
  }
}
