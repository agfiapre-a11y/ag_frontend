import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/department.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class AddEditDepartmentScreen extends ConsumerStatefulWidget {
  final String? deptId;

  const AddEditDepartmentScreen({super.key, this.deptId});

  @override
  ConsumerState<AddEditDepartmentScreen> createState() =>
      _AddEditDepartmentScreenState();
}

class _AddEditDepartmentScreenState
    extends ConsumerState<AddEditDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  Department? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.deptId != null) {
      _existing = LocalDb.getDepartmentById(widget.deptId!);
      if (_existing != null) {
        _nameCtrl.text = _existing!.name;
        _descCtrl.text = _existing!.description;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => _existing != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final updated = _existing!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          branchId: '',
        );
        await ref.read(departmentProvider.notifier).update(updated);
      } else {
        await ref.read(departmentProvider.notifier).add(
              branchId: '',
              name: _nameCtrl.text.trim(),
              description: _descCtrl.text.trim(),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Department updated' : 'Department created'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Department' : 'New Department'),
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
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade700.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_2,
                    size: 44, color: Colors.cyan.shade700),
              ),
            ),
            const SizedBox(height: 24),
            _label('Department Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Department name is required'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Department Name *',
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon:
                  Icon(_isEdit ? Icons.save_outlined : Icons.add_circle_outline),
              label: Text(_isEdit ? 'Save Changes' : 'Create Department',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      );
}
