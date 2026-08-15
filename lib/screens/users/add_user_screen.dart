import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/movement_classifier.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = AppRoles.member;
  String? _branchId;
  String? _departmentId;
  bool _loading = false;
  bool _obscure = true;
  String _gender = 'male';
  DateTime? _dob;
  String _maritalStatus = 'single';
  bool _isEmployed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Branch is always optional — local church admin (tenant manager)
  // can onboard users without requiring a branch assignment.

  String get _computedMovement => MovementClassifier.classify(
        dateOfBirth: _dob,
        gender: _gender,
        maritalStatus: _maritalStatus,
        isEmployed: _isEmployed,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (AppRoles.departmentScopedRoles.contains(_role) && _departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign a department')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final appState = ref.read(appStateProvider);
      await AuthService.registerUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim(),
        role: _role,
        churchId: appState.church?.id ?? "",
        branchId: _branchId ?? '',
        departmentId: _departmentId ?? '',
        dateOfBirth: _dob,
        gender: _gender,
        maritalStatus: _maritalStatus,
        isEmployed: _isEmployed,
      );
      ref.read(userProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
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
    final branches = ref.watch(branchProvider);
    final allDepts = ref.watch(departmentProvider);
    final branchDepts = _branchId != null
        ? allDepts.where((d) => d.branchId == _branchId).toList()
        : allDepts;

    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Full Name', Icons.person, required: true),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email Address', Icons.email,
                  required: true, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', Icons.phone,
                  type: TextInputType.phone),
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
                    labelText: 'Date of Birth',
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
              const SizedBox(height: 20),
              _sectionLabel('Account Settings'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  // System Level
                  DropdownMenuItem(
                      value: AppRoles.superSystemAdmin, child: Text('Super System Administrator')),
                  DropdownMenuItem(
                      value: AppRoles.nationalAdmin, child: Text('National Administrator')),
                  DropdownMenuItem(
                      value: AppRoles.nationalExecutive, child: Text('National Executive')),
                  // Regional Level
                  DropdownMenuItem(
                      value: AppRoles.regionalAdmin, child: Text('Regional Administrator')),
                  DropdownMenuItem(
                      value: AppRoles.regionalBishop, child: Text('Regional Bishop')),
                  // District Level
                  DropdownMenuItem(
                      value: AppRoles.districtAdmin, child: Text('District Administrator')),
                  DropdownMenuItem(
                      value: AppRoles.districtPastor, child: Text('District Pastor')),
                  // Area Level
                  DropdownMenuItem(
                      value: AppRoles.areaAdmin, child: Text('Area Administrator')),
                  // Local Church Level
                  DropdownMenuItem(
                      value: AppRoles.localChurchAdmin, child: Text('Local Church Administrator')),
                  DropdownMenuItem(
                      value: AppRoles.seniorPastor, child: Text('Senior Pastor')),
                  DropdownMenuItem(
                      value: AppRoles.associatePastor, child: Text('Associate Pastor')),
                  DropdownMenuItem(
                      value: AppRoles.churchSecretary, child: Text('Church Secretary')),
                  DropdownMenuItem(
                      value: AppRoles.financeOfficer, child: Text('Finance Officer')),
                  DropdownMenuItem(
                      value: AppRoles.ministryHead, child: Text('Ministry Head')),
                  DropdownMenuItem(
                      value: AppRoles.youthMinistryHead, child: Text('Youth Ministry Head')),
                  DropdownMenuItem(
                      value: AppRoles.menFellowshipHead, child: Text("Men's Fellowship Head")),
                  DropdownMenuItem(
                      value: AppRoles.womenFellowshipHead, child: Text("Women's Fellowship Head")),
                  DropdownMenuItem(
                      value: AppRoles.childrenMinistryHead, child: Text("Children's Ministry Head")),
                  DropdownMenuItem(
                      value: AppRoles.welfareHead, child: Text('Welfare Head')),
                  // Member Level
                  DropdownMenuItem(
                      value: AppRoles.cellLeader, child: Text('Cell Leader')),
                  DropdownMenuItem(
                      value: AppRoles.volunteer, child: Text('Volunteer')),
                  DropdownMenuItem(
                      value: AppRoles.member, child: Text('Member')),
                  DropdownMenuItem(
                      value: AppRoles.guest, child: Text('Guest')),
                ],
                onChanged: (v) => setState(() {
                  _role = v!;
                  if (!AppRoles.departmentScopedRoles.contains(_role)) {
                    _departmentId = null;
                  }
                }),
              ),
              if (branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(
                    labelText: 'Branch (optional)',
                    prefixIcon: Icon(Icons.account_tree),
                  ),
                  hint: const Text('Select branch'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...branches.map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (v) => setState(() {
                    _branchId = v;
                    _departmentId = null;
                  }),
                ),
              ],
              if (AppRoles.departmentScopedRoles.contains(_role) &&
                  branchDepts.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (branchDepts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_outlined,
                          size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'No departments in this branch. Create departments first.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.amber.shade800),
                        ),
                      ),
                    ]),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department *',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    hint: const Text('Select department'),
                    items: branchDepts
                        .map((d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _departmentId = v),
                    validator: (v) =>
                        (AppRoles.departmentScopedRoles.contains(_role) &&
                                v == null)
                            ? 'Please select a department'
                            : null,
                  ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 13),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? type,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
