import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';

class AddEditAreaScreen extends ConsumerStatefulWidget {
  final String? areaId;

  const AddEditAreaScreen({super.key, this.areaId});

  @override
  ConsumerState<AddEditAreaScreen> createState() => _AddEditAreaScreenState();
}

class _AddEditAreaScreenState extends ConsumerState<AddEditAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adminIdCtrl = TextEditingController();
  String? _districtId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.areaId != null) {
      _loadArea();
    }
  }

  void _loadArea() {
    final area = ref.read(areaProvider).firstWhere(
          (a) => a.id == widget.areaId,
          orElse: () => throw Exception('Area not found'),
        );
    _nameCtrl.text = area.name;
    _descriptionCtrl.text = area.description;
    _addressCtrl.text = area.address;
    _phoneCtrl.text = area.phone;
    _emailCtrl.text = area.email;
    _adminIdCtrl.text = area.adminId;
    _districtId = area.districtId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _adminIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final distId = _districtId ?? 'default-district';
      
      if (widget.areaId == null) {
        // Create new area
        await ref.read(areaProvider.notifier).add(
              name: _nameCtrl.text.trim(),
              districtId: distId,
              adminId: _adminIdCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
            );
      } else {
        // Update existing area
        final area = ref.read(areaProvider).firstWhere(
              (a) => a.id == widget.areaId,
              orElse: () => throw Exception('Area not found'),
            );
        await ref.read(areaProvider.notifier).update(
              area.copyWith(
                name: _nameCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
              ),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.areaId == null ? 'Area created' : 'Area updated'),
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(districtProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.areaId == null ? 'Add Area' : 'Edit Area'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Area Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Area Name', Icons.place, required: true),
              const SizedBox(height: 12),
              if (districts.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _districtId,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  hint: const Text('Select district'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...districts.map((d) =>
                        DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _districtId = v),
                ),
                const SizedBox(height: 12),
              ],
              _field(_descriptionCtrl, 'Description', Icons.description, maxLines: 3),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Address', Icons.location_on),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_adminIdCtrl, 'Admin User ID', Icons.person),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(widget.areaId == null ? 'Create Area' : 'Update Area'),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
