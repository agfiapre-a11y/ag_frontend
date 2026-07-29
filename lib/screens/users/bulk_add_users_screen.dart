import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';

class BulkAddUsersScreen extends ConsumerStatefulWidget {
  const BulkAddUsersScreen({super.key});

  @override
  ConsumerState<BulkAddUsersScreen> createState() => _BulkAddUsersScreenState();
}

class _BulkAddUsersScreenState extends ConsumerState<BulkAddUsersScreen> {
  List<Map<String, String>> _parsedRows = [];
  List<String> _headers = [];
  String? _fileName;
  bool _loading = false;
  String _defaultPassword = 'password123';
  final String _defaultRole = AppRoles.member;
  final List<String> _errors = [];
  int _successCount = 0;
  int _failCount = 0;

  static const _expectedHeaders = [
    'name', 'email', 'phone', 'role', 'password',
  ];

  String _csvTemplate() {
    final buf = StringBuffer();
    buf.writeln(_expectedHeaders.join(','));
    buf.writeln('John Doe,john.doe@example.com,0241234567,member,password123');
    buf.writeln('Jane Smith,jane.smith@example.com,0247654321,financeOfficer,password123');
    buf.writeln('Pastor Mensah,pastor.mensah@example.com,0201112222,seniorPastor,password123');
    buf.writeln('Mary Owusu,mary.owusu@example.com,0273334444,churchSecretary,password123');
    buf.writeln('Kwame Asante,kwame.asante@example.com,0245556667,member,password123');
    return buf.toString();
  }

  Future<void> _downloadTemplate() async {
    final csv = _csvTemplate();
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: 'paradise_users_template.csv', mimeType: 'text/csv')],
      text: 'Paradise AG - User Upload Template',
    );
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _showError('Could not read file data');
      return;
    }

    final content = utf8.decode(bytes);
    _parseCsv(content, file.name);
  }

  void _parseCsv(String content, String fileName) {
    setState(() {
      _parsedRows = [];
      _headers = [];
      _errors.clear();
      _fileName = fileName;
      _successCount = 0;
      _failCount = 0;
    });

    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      _showError('CSV file is empty');
      return;
    }

    _headers = _splitCsvLine(lines[0]).map((h) => h.trim().toLowerCase()).toList();

    // Validate headers
    final missing = _expectedHeaders.where((h) => !_headers.contains(h)).toList();
    if (missing.isNotEmpty) {
      _showError('Missing required columns: ${missing.join(', ')}. Expected: ${_expectedHeaders.join(', ')}');
      return;
    }

    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final row = <String, String>{};
      for (int j = 0; j < _headers.length && j < values.length; j++) {
        row[_headers[j]] = values[j].trim();
      }
      if (row['name'] == null || row['name']!.isEmpty) continue;
      _parsedRows.add(row);
    }

    setState(() {});
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  Future<void> _importUsers() async {
    if (_parsedRows.isEmpty) return;

    setState(() {
      _loading = true;
      _errors.clear();
      _successCount = 0;
      _failCount = 0;
    });

    final appState = ref.read(appStateProvider);
    final churchId = appState.church?.id ?? '';
    final existingUsers = ref.read(userProvider);

    for (int i = 0; i < _parsedRows.length; i++) {
      final row = _parsedRows[i];
      try {
        final name = row['name'] ?? '';
        final email = (row['email'] ?? '').toLowerCase().trim();
        final phone = row['phone'] ?? '';
        final role = row['role']?.isNotEmpty == true ? row['role']! : _defaultRole;
        final password = (row['password']?.isNotEmpty == true ? row['password']! : _defaultPassword);

        if (name.isEmpty || email.isEmpty) {
          _errors.add('Row ${i + 1}: Missing name or email');
          _failCount++;
          continue;
        }

        // Check for duplicate email
        if (existingUsers.any((u) => u.email == email)) {
          _errors.add('Row ${i + 1}: Email "$email" already exists');
          _failCount++;
          continue;
        }

        await AuthService.registerUser(
          name: name,
          email: email,
          password: password,
          phone: phone,
          role: role,
          churchId: churchId,
          branchId: '',
        );
        _successCount++;
      } catch (e) {
        _errors.add('Row ${i + 1}: ${e.toString()}');
        _failCount++;
      }
    }

    ref.read(userProvider.notifier).refresh();

    setState(() => _loading = false);

    if (mounted) {
      _showResults();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text('$_successCount user(s) created', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ]),
            if (_failCount > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('$_failCount failed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ]),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Errors:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              ..._errors.take(10).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(e, style: const TextStyle(fontSize: 12, color: Colors.red)),
              )),
              if (_errors.length > 10)
                Text('...and ${_errors.length - 10} more', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_successCount > 0) Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Add Users')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.infoBlue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CSV Bulk Upload', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Download the template, fill in user details, then upload the CSV file to create multiple users at once.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: Download template
            Text('Step 1: Download Template', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text('Download CSV Template'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Required columns: name, email, phone, role, password',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Step 2: Upload CSV
            Text('Step 2: Upload Filled CSV', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickCsvFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select CSV File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Default settings
            if (_parsedRows.isNotEmpty) ...[
              Text('Step 3: Default Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Default password (if empty in CSV)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onChanged: (v) => _defaultPassword = v,
                    controller: TextEditingController(text: _defaultPassword),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // Preview
            if (_parsedRows.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preview (${_parsedRows.length} users)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (_fileName != null)
                    Text(_fileName!, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Name', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Email', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontSize: 12))),
                      DataColumn(label: Text('Role', style: TextStyle(fontSize: 12))),
                    ],
                    rows: _parsedRows.take(20).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(row['name'] ?? '', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(row['email'] ?? '', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(row['phone'] ?? '', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(row['role'] ?? _defaultRole, style: const TextStyle(fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              if (_parsedRows.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Showing 20 of ${_parsedRows.length} rows',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ),
              const SizedBox(height: 20),

              // Import button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _importUsers,
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: Text(_loading ? 'Importing...' : 'Import ${_parsedRows.length} Users'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            // Empty state
            if (_parsedRows.isEmpty && _fileName == null) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No file selected', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Download the template and upload your CSV here',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
