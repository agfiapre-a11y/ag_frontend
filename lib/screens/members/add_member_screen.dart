import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/movement_classifier.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'male';
  DateTime? _dob;
  String _maritalStatus = 'single';
  bool _isEmployed = false;
  String? _selectedBranchId;
  String? _selectedDeptId;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String get _computedMovement => MovementClassifier.classify(
        dateOfBirth: _dob,
        gender: _gender,
        maritalStatus: _maritalStatus,
        isEmployed: _isEmployed,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);
    final branchId = isSuperAdmin ? (_selectedBranchId ?? '') : user.branchId;

    if (branchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(memberProvider.notifier).add(
            branchId: branchId,
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            gender: _gender,
            dateOfBirth: _dob,
            maritalStatus: _maritalStatus,
            isEmployed: _isEmployed,
            departmentId: _selectedDeptId ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final user = appState.user!;
    final branches = ref.watch(branchProvider);
    final allDepts = ref.watch(departmentProvider);
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);
    final effectiveBranchId = isSuperAdmin ? _selectedBranchId : user.branchId;
    final branchDepts =
        (effectiveBranchId != null && effectiveBranchId.isNotEmpty)
            ? allDepts
                .where((d) => d.branchId == effectiveBranchId)
                .toList()
            : <Department>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Information',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13)),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Full Name', Icons.person, required: true),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', Icons.phone,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email Address', Icons.email,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Home Address', Icons.location_on, lines: 2),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _dob = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (optional)',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    _dob != null
                        ? DateFormat('MMM d, yyyy').format(_dob!)
                        : 'Tap to select',
                    style: TextStyle(
                      color: _dob != null ? null : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _maritalStatus,
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  prefixIcon: Icon(Icons.favorite),
                ),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'married', child: Text('Married')),
                  DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                  DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                ],
                onChanged: (v) => setState(() => _maritalStatus = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isEmployed,
                onChanged: (v) => setState(() => _isEmployed = v),
                title: Text('Employed',
                    style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text('Employed members are assigned to Church Welfare',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_computedMovement.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.groups, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Auto-assigned to: $_computedMovement',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                  ]),
                ),
              ],
              if (isSuperAdmin && branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Branch Assignment',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Select Branch',
                    prefixIcon: Icon(Icons.account_tree),
                  ),
                  hint: const Text('Choose a branch'),
                  items: branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedBranchId = v;
                    _selectedDeptId = null;
                  }),
                  validator: isSuperAdmin
                      ? (v) => v == null ? 'Please select a branch' : null
                      : null,
                ),
              ],
              if (branchDepts.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeptId,
                  decoration: const InputDecoration(
                    labelText: 'Department (optional)',
                    prefixIcon: Icon(Icons.groups_2_outlined),
                  ),
                  hint: const Text('No department'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...branchDepts.map((d) =>
                        DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedDeptId = v),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Add Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? type,
    int lines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: lines,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
