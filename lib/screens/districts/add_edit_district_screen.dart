import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';

class AddEditDistrictScreen extends ConsumerStatefulWidget {
  final String? districtId;

  const AddEditDistrictScreen({super.key, this.districtId});

  @override
  ConsumerState<AddEditDistrictScreen> createState() =>
      _AddEditDistrictScreenState();
}

class _AddEditDistrictScreenState extends ConsumerState<AddEditDistrictScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adminIdCtrl = TextEditingController();
  String? _regionId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.districtId != null) {
      _loadDistrict();
    }
  }

  void _loadDistrict() {
    final district = ref.read(districtProvider).firstWhere(
          (d) => d.id == widget.districtId,
          orElse: () => throw Exception('District not found'),
        );
    _nameCtrl.text = district.name;
    _descriptionCtrl.text = district.description;
    _addressCtrl.text = district.address;
    _phoneCtrl.text = district.phone;
    _emailCtrl.text = district.email;
    _adminIdCtrl.text = district.adminId;
    _regionId = district.regionId;
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
      final regId = _regionId ?? 'default-region';
      
      if (widget.districtId == null) {
        // Create new district
        await ref.read(districtProvider.notifier).add(
              name: _nameCtrl.text.trim(),
              regionId: regId,
              adminId: _adminIdCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
            );
      } else {
        // Update existing district
        final district = ref.read(districtProvider).firstWhere(
              (d) => d.id == widget.districtId,
              orElse: () => throw Exception('District not found'),
            );
        await ref.read(districtProvider.notifier).update(
              district.copyWith(
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
            content: Text(widget.districtId == null ? 'District created' : 'District updated'),
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
    final regions = ref.watch(regionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.districtId == null ? 'Add District' : 'Edit District'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('District Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'District Name', Icons.location_city, required: true),
              const SizedBox(height: 12),
              if (regions.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _regionId,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    prefixIcon: Icon(Icons.map),
                  ),
                  hint: const Text('Select region'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...regions.map((r) =>
                        DropdownMenuItem(value: r.id, child: Text(r.name))),
                  ],
                  onChanged: (v) => setState(() => _regionId = v),
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
                    : Text(widget.districtId == null ? 'Create District' : 'Update District'),
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
