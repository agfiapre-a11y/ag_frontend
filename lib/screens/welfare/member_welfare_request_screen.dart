import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/welfare_case.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

const _uuid = Uuid();

class MemberWelfareRequestScreen extends ConsumerStatefulWidget {
  const MemberWelfareRequestScreen({super.key});
  @override
  ConsumerState<MemberWelfareRequestScreen> createState() =>
      _MemberWelfareRequestScreenState();
}

class _MemberWelfareRequestScreenState
    extends ConsumerState<MemberWelfareRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  String _type = WelfareType.financial;
  String _priority = WelfarePriority.medium;
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = ref.read(appStateProvider).user!;
    final church = ref.read(appStateProvider).church;
    final members = ref.read(memberProvider);
    final m = members
        .where((x) => x.email.toLowerCase() == user.email.toLowerCase())
        .firstOrNull;
    if (m == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member profile not found.')),
        );
        setState(() => _saving = false);
      }
      return;
    }
    final wc = WelfareCase(
      id: _uuid.v4(),
      churchId: church?.id ?? '',
      branchId: m.branchId,
      memberId: m.id,
      welfareHeadId: '',
      type: _type,
      status: WelfareStatus.open,
      priority: _priority,
      description: _descCtrl.text.trim(),
      amountRequested: double.tryParse(_amtCtrl.text) ?? 0,
      dateRequested: DateTime.now(),
      createdAt: DateTime.now(),
      organizationId: user.organizationId,
      regionId: user.regionId,
      districtId: user.districtId,
      areaId: user.areaId,
    );
    await ref.read(welfareProvider.notifier).add(wc);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Welfare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit a welfare request to your church welfare team.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              _typeField(),
              const SizedBox(height: 16),
              _priorityField(),
              const SizedBox(height: 16),
              _amountField(),
              const SizedBox(height: 16),
              _descField(),
              const SizedBox(height: 24),
              _submitBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welfare Type *',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: WelfareType.all
              .map((t) => DropdownMenuItem(value: t, child: Text(WelfareType.label(t))))
              .toList(),
          onChanged: (v) => setState(() => _type = v ?? WelfareType.financial),
        ),
      ],
    );
  }

  Widget _priorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority *',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _priority,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          items: WelfarePriority.all
              .map((p) => DropdownMenuItem(value: p, child: Text(WelfarePriority.label(p))))
              .toList(),
          onChanged: (v) => setState(() => _priority = v ?? WelfarePriority.medium),
        ),
      ],
    );
  }

  Widget _amountField() {
    return TextFormField(
      controller: _amtCtrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount Needed (GH₵)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.request_quote_outlined),
      ),
    );
  }

  Widget _descField() {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 4,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe your request' : null,
      decoration: const InputDecoration(
        labelText: 'Describe your need *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description_outlined),
      ),
    );
  }

  Widget _submitBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _saving ? null : _submit,
        child: _saving
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Submit Request'),
      ),
    );
  }
}
