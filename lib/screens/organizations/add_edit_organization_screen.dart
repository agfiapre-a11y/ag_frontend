import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';

class AddEditOrganizationScreen extends ConsumerStatefulWidget {
  final String? organizationId;

  const AddEditOrganizationScreen({super.key, this.organizationId});

  @override
  ConsumerState<AddEditOrganizationScreen> createState() =>
      _AddEditOrganizationScreenState();
}

class _AddEditOrganizationScreenState
    extends ConsumerState<AddEditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _adminIdCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.organizationId != null) {
      _loadOrganization();
    }
  }

  void _loadOrganization() {
    final org = ref.read(organizationProvider).firstWhere(
          (o) => o.id == widget.organizationId,
          orElse: () => throw Exception('Organization not found'),
        );
    _nameCtrl.text = org.name;
    _descriptionCtrl.text = org.description;
    _addressCtrl.text = org.address;
    _phoneCtrl.text = org.phone;
    _emailCtrl.text = org.email;
    _websiteCtrl.text = org.website;
    _adminIdCtrl.text = org.adminId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _adminIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (widget.organizationId == null) {
        // Create new organization
        await ref.read(organizationProvider.notifier).add(
              name: _nameCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              adminId: _adminIdCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              website: _websiteCtrl.text.trim(),
            );
      } else {
        // Update existing organization
        final org = ref.read(organizationProvider).firstWhere(
              (o) => o.id == widget.organizationId,
              orElse: () => throw Exception('Organization not found'),
            );
        await ref.read(organizationProvider.notifier).update(
              org.copyWith(
                name: _nameCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                website: _websiteCtrl.text.trim(),
              ),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.organizationId == null ? 'Organization created' : 'Organization updated'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.organizationId == null ? 'Add Organization' : 'Edit Organization'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Organization Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Organization Name', Icons.business, required: true),
              const SizedBox(height: 12),
              _field(_descriptionCtrl, 'Description', Icons.description, maxLines: 3),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Address', Icons.location_on),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_websiteCtrl, 'Website', Icons.language, type: TextInputType.url),
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
                    : Text(widget.organizationId == null ? 'Create Organization' : 'Update Organization'),
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
