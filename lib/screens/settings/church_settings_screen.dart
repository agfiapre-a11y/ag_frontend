import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/local_db.dart';
import '../../services/seed_data_service.dart';
import '../../services/seed_multi_church.dart';
import '../../services/seed_role_users.dart';
import '../../services/tenant_context.dart';
import '../../widgets/responsive_scaffold.dart';

class ChurchSettingsScreen extends ConsumerStatefulWidget {
  const ChurchSettingsScreen({super.key});

  @override
  ConsumerState<ChurchSettingsScreen> createState() =>
      _ChurchSettingsScreenState();
}

class _ChurchSettingsScreenState extends ConsumerState<ChurchSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  // Password change fields
  bool _changePassword = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final church = ref.read(appStateProvider).church;
    _nameCtrl = TextEditingController(text: church?.name ?? '');
    _addressCtrl = TextEditingController(text: church?.address ?? '');
    _phoneCtrl = TextEditingController(text: church?.phone ?? '');
    _emailCtrl = TextEditingController(text: church?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_changePassword) {
      if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final appState = ref.read(appStateProvider);
      final church = appState.church;
      final user = appState.user!;

      if (church != null) {
        final updated = church.copyWith(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
        await LocalDb.saveChurch(updated);
        ref.read(appStateProvider.notifier).refresh();
      }

      // Update admin password if requested
      if (_changePassword && _newPasswordCtrl.text.isNotEmpty) {
        final updatedUser = user.copyWith(
          passwordHash: AuthService.hashPassword(_newPasswordCtrl.text),
        );
        await LocalDb.saveUser(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Church settings saved'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(Icons.refresh_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Reset All Data'),
        ]),
        content: const Text(
          'This will ERASE everything (all churches, users, members, branches, finance, etc.) and re-seed the app with fresh demo data.\n\nYou will be logged out and returned to the login screen.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset & Re-seed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      // Clear all SharedPreferences
      await LocalDb.prefs.clear();

      // Re-seed from scratch
      final churches = LocalDb.getAllChurches();
      if (churches.isEmpty) {
        await SeedMultiChurch.seedAllChurches();
      }

      final allChurches = LocalDb.getAllChurches();
      if (allChurches.isNotEmpty) {
        await LocalDb.setActiveChurch(allChurches.first.id);
        TenantContext.setActiveChurch(allChurches.first.id);
        await SeedDataService.seedTrainingData(allChurches.first.id);

        for (final church in allChurches) {
          await LocalDb.setActiveChurch(church.id);
          TenantContext.setActiveChurch(church.id);
          await SeedRoleUsers.seedAllRoleUsers(
              church.id, churchEmail: church.email);
        }

        await LocalDb.setActiveChurch(allChurches.first.id);
        TenantContext.setActiveChurch(allChurches.first.id);
        await SeedRoleUsers.seedAboveChurchRoleUsers();
      }

      await LocalDb.prefs.setBool('has_seeded', true);
      await LocalDb.clearSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data reset and re-seeded successfully'),
          backgroundColor: AppColors.success,
        ));
        ref.read(appStateProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error resetting data: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDeleteTrainingData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Text('Delete Training Data'),
        ]),
        content: const Text(
          'Are you sure you want to delete all training data? This action cannot be undone.\n\nThe following will be deleted:\n• All branches\n• All members\n• All users (except Super Admin)\n• All departments\n• All attendance records\n• All finance transactions\n• All sermons\n• All events\n\nChurch settings and Super Admin account will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        final church = ref.read(appStateProvider).church;
        if (church == null) return;
        await SeedDataService.deleteTrainingData(church.id);
        
        // Refresh all providers
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(userProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(attendanceProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Training data deleted successfully'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error deleting training data: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user;
    final isSuperAdmin = AppRoles.churchSettingsManagerRoles.contains(user?.role);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Church Settings'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Church icon header
            Center(
              child: Column(children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.church, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text('Configure your church details',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
              ]),
            ),

            _SectionLabel('Church Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Church name is required' : null,
              decoration: const InputDecoration(
                labelText: 'Church Name *',
                prefixIcon: Icon(Icons.church_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Church Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            _SectionLabel('Admin Password'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Change admin password'),
              subtitle: const Text('Update the Super Admin login password'),
              value: _changePassword,
              onChanged: (v) => setState(() {
                _changePassword = v;
                if (!v) {
                  _newPasswordCtrl.clear();
                  _confirmPasswordCtrl.clear();
                }
              }),
              contentPadding: EdgeInsets.zero,
            ),
            if (_changePassword) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                validator: _changePassword
                    ? (v) => (v == null || v.length < 6)
                        ? 'Min 6 characters'
                        : null
                    : null,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                validator: _changePassword
                    ? (v) => (v == null || v.isEmpty)
                        ? 'Confirm your password'
                        : null
                    : null,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                'Save Settings',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 24),

            // Training Data Management (Super Admin only)
            if (isSuperAdmin) ...[
              const Divider(),
              const SizedBox(height: 16),
              _SectionLabel('Data Management'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('Training Data',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'This will delete all sample data including branches, members, attendance, finance records, sermons, and events. The church and super admin account will be preserved.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _confirmDeleteTrainingData,
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: Text(
                        'Delete Training Data',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('Reset All Data & Re-seed',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'This will erase ALL data (all churches, users, members, everything) and re-seed the app with fresh demo data. You will be logged out.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _confirmResetAllData,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Reset & Re-seed All Data',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.primary,
        letterSpacing: 0.4,
      ),
    );
  }
}
