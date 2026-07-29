import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/department.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/local_db.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final String userId;

  const EditUserScreen({super.key, required this.userId});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  String _role = AppRoles.member;
  String? _branchId;
  String? _departmentId;
  bool _loading = false;
  bool _showPasswordField = false;
  bool _obscure = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = LocalDb.getUserById(widget.userId);
    if (_user != null) {
      _nameCtrl.text = _user!.name;
      _phoneCtrl.text = _user!.phone;
      _role = _user!.role;
      _branchId = _user!.branchId.isNotEmpty ? _user!.branchId : null;
      _departmentId =
          _user!.departmentId.isNotEmpty ? _user!.departmentId : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _needsBranch => AppRoles.branchScopedRoles.contains(_role);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _loading = true);
    try {
      final passwordHash =
          (_showPasswordField && _newPasswordCtrl.text.isNotEmpty)
              ? AuthService.hashPassword(_newPasswordCtrl.text)
              : _user!.passwordHash;

      final updated = _user!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _role,
        branchId: _branchId ?? '',
        departmentId: AppRoles.departmentScopedRoles.contains(_role)
            ? (_departmentId ?? '')
            : '',
        passwordHash: passwordHash,
      );
      await ref.read(userProvider.notifier).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
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
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit User')),
        body: const Center(child: Text('User not found')),
      );
    }

    final branches = ref.watch(branchProvider);
    final allDepts = ref.watch(departmentProvider);
    final branchDepts = _branchId != null
        ? allDepts.where((d) => d.branchId == _branchId).toList()
        : <Department>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _user!.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
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
                  // Legacy roles for backward compatibility
                  DropdownMenuItem(
                      value: AppRoles.superAdmin, child: Text('Super Admin (Legacy)')),
                  DropdownMenuItem(
                      value: AppRoles.branchAdmin, child: Text('Branch Admin (Legacy)')),
                  DropdownMenuItem(
                      value: AppRoles.pastor, child: Text('Pastor (Legacy)')),
                  DropdownMenuItem(
                      value: AppRoles.accountant, child: Text('Accountant (Legacy)')),
                  DropdownMenuItem(
                      value: AppRoles.deptLeader, child: Text('Dept. Leader (Legacy)')),
                ],
                onChanged: (v) => setState(() {
                  _role = v!;
                  if (!_needsBranch) {
                    _branchId = null;
                    _departmentId = null;
                  }
                  if (!AppRoles.departmentScopedRoles.contains(_role)) {
                    _departmentId = null;
                  }
                }),
              ),
              if (branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: InputDecoration(
                    labelText:
                        _needsBranch ? 'Branch *' : 'Branch (optional)',
                    prefixIcon: const Icon(Icons.account_tree),
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
                  _branchId != null) ...[
                const SizedBox(height: 12),
                if (branchDepts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'No departments in this branch.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.amber.shade800),
                    ),
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
                        .map((d) => DropdownMenuItem(
                            value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
              ],
              const SizedBox(height: 20),
              _sectionLabel('Security'),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _showPasswordField,
                onChanged: (v) => setState(() {
                  _showPasswordField = v;
                  if (!v) _newPasswordCtrl.clear();
                }),
                title: Text('Reset password',
                    style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text('Set a new password for this user',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_showPasswordField) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscure,
                  validator: _showPasswordField
                      ? (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 characters'
                          : null
                      : null,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 13),
      );
}
