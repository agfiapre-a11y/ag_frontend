import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/branch.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EditBranchScreen extends ConsumerStatefulWidget {
  final String branchId;

  const EditBranchScreen({super.key, required this.branchId});

  @override
  ConsumerState<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends ConsumerState<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _pastorId;
  bool _loading = false;
  Branch? _branch;

  @override
  void initState() {
    super.initState();
    _branch = LocalDb.getBranchById(widget.branchId);
    if (_branch != null) {
      _nameCtrl.text = _branch!.name;
      _locationCtrl.text = _branch!.location;
      _pastorId = _branch!.pastorId.isNotEmpty ? _branch!.pastorId : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branch == null) return;

    setState(() => _loading = true);
    try {
      final updated = _branch!.copyWith(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        pastorId: _pastorId ?? '',
      );
      await ref.read(branchProvider.notifier).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch updated successfully'),
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
    if (_branch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Branch')),
        body: const Center(child: Text('Branch not found')),
      );
    }

    final pastors = LocalDb.getUsersByRoles(AppRoles.branchLeaderRoles);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Branch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Branch Details',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Branch name is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  prefixIcon: Icon(Icons.account_tree),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              if (pastors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Leadership',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _pastorId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Pastor',
                    prefixIcon: Icon(Icons.person),
                  ),
                  hint: const Text('Select pastor (optional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('None')),
                    ...pastors.map((u) =>
                        DropdownMenuItem(value: u.id, child: Text(u.name))),
                  ],
                  onChanged: (v) => setState(() => _pastorId = v),
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
}
