import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';

class AddEditRegionScreen extends ConsumerStatefulWidget {
  final String? regionId;

  const AddEditRegionScreen({super.key, this.regionId});

  @override
  ConsumerState<AddEditRegionScreen> createState() =>
      _AddEditRegionScreenState();
}

class _AddEditRegionScreenState extends ConsumerState<AddEditRegionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adminIdCtrl = TextEditingController();
  String? _organizationId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.regionId != null) {
      _loadRegion();
    }
  }

  void _loadRegion() {
    final region = ref.read(regionProvider).firstWhere(
          (r) => r.id == widget.regionId,
          orElse: () => throw Exception('Region not found'),
        );
    _nameCtrl.text = region.name;
    _descriptionCtrl.text = region.description;
    _addressCtrl.text = region.address;
    _phoneCtrl.text = region.phone;
    _emailCtrl.text = region.email;
    _adminIdCtrl.text = region.adminId;
    _organizationId = region.organizationId;
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
      final orgId = _organizationId ?? 'default-org';
      
      if (widget.regionId == null) {
        // Create new region
        await ref.read(regionProvider.notifier).add(
              name: _nameCtrl.text.trim(),
              organizationId: orgId,
              adminId: _adminIdCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
            );
      } else {
        // Update existing region
        final region = ref.read(regionProvider).firstWhere(
              (r) => r.id == widget.regionId,
              orElse: () => throw Exception('Region not found'),
            );
        await ref.read(regionProvider.notifier).update(
              region.copyWith(
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
            content: Text(widget.regionId == null ? 'Region created' : 'Region updated'),
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
    final organizations = ref.watch(organizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regionId == null ? 'Add Region' : 'Edit Region'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Region Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Region Name', Icons.map, required: true),
              const SizedBox(height: 12),
              if (organizations.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _organizationId,
                  decoration: const InputDecoration(
                    labelText: 'Organization',
                    prefixIcon: Icon(Icons.business),
                  ),
                  hint: const Text('Select organization'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...organizations.map((o) =>
                        DropdownMenuItem(value: o.id, child: Text(o.name))),
                  ],
                  onChanged: (v) => setState(() => _organizationId = v),
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
                    : Text(widget.regionId == null ? 'Create Region' : 'Update Region'),
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
