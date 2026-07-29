import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class AddBranchScreen extends ConsumerStatefulWidget {
  const AddBranchScreen({super.key});

  @override
  ConsumerState<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends ConsumerState<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _pastorId;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(branchProvider.notifier).add(
            name: _nameCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            pastorId: _pastorId ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch created successfully'),
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
    final pastors =
        LocalDb.getUsersByRoles(AppRoles.branchLeaderRoles);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Branch')),
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
                Text('Leadership (optional)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _pastorId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Pastor',
                    prefixIcon: Icon(Icons.person),
                  ),
                  hint: const Text('Select pastor (optional)'),
                  items: pastors
                      .map((u) =>
                          DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
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
                    : const Text('Create Branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
