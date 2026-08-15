import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/member.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EditMemberScreen extends ConsumerStatefulWidget {
  final String memberId;

  const EditMemberScreen({super.key, required this.memberId});

  @override
  ConsumerState<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'male';
  DateTime? _dob;
  String? _selectedDeptId;
  bool _loading = false;
  Member? _member;

  @override
  void initState() {
    super.initState();
    _member = LocalDb.getMemberById(widget.memberId);
    if (_member != null) {
      _nameCtrl.text = _member!.name;
      _emailCtrl.text = _member!.email;
      _phoneCtrl.text = _member!.phone;
      _addressCtrl.text = _member!.address;
      _gender = _member!.gender;
      _dob = _member!.dateOfBirth;
      _selectedDeptId = _member!.departmentId.isNotEmpty ? _member!.departmentId : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_member == null) return;

    setState(() => _loading = true);
    try {
      final updated = _member!.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: _dob,
        branchId: '',
        departmentId: _selectedDeptId ?? '',
      );
      await ref.read(memberProvider.notifier).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Member')),
        body: const Center(child: Text('Member not found')),
      );
    }

    final allDepts = ref.watch(departmentProvider);
    final availableDepts = allDepts.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
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
                    initialDate: _dob ?? DateTime(1990),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dob != null
                            ? DateFormat('MMM d, yyyy').format(_dob!)
                            : 'Tap to select',
                        style: TextStyle(
                          color: _dob != null ? null : AppColors.textSecondary,
                        ),
                      ),
                      if (_dob != null)
                        GestureDetector(
                          onTap: () => setState(() => _dob = null),
                          child: const Icon(Icons.clear,
                              size: 18, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              if (availableDepts.isNotEmpty) ...[
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
                    ...availableDepts.map((d) =>
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
                    : const Text('Save Changes'),
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
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
