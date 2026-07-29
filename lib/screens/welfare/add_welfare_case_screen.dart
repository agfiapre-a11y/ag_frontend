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

class AddWelfareCaseScreen extends ConsumerStatefulWidget {
  const AddWelfareCaseScreen({super.key});

  @override
  ConsumerState<AddWelfareCaseScreen> createState() =>
      _AddWelfareCaseScreenState();
}

class _AddWelfareCaseScreenState extends ConsumerState<AddWelfareCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountRequestedController = TextEditingController();
  final _amountDisbursedController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedMemberId;
  String _selectedType = WelfareType.financial;
  String _selectedStatus = WelfareStatus.open;
  String _selectedPriority = WelfarePriority.medium;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountRequestedController.dispose();
    _amountDisbursedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    setState(() => _saving = true);

    final user = ref.read(appStateProvider).user!;
    final church = ref.read(appStateProvider).church;

    final welfareCase = WelfareCase(
      id: _uuid.v4(),
      churchId: church?.id ?? '',
      branchId: user.branchId,
      memberId: _selectedMemberId!,
      welfareHeadId: user.id,
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      description: _descriptionController.text.trim(),
      amountRequested: double.tryParse(_amountRequestedController.text) ?? 0,
      amountDisbursed: double.tryParse(_amountDisbursedController.text) ?? 0,
      dateRequested: _selectedDate,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      organizationId: user.organizationId,
      regionId: user.regionId,
      districtId: user.districtId,
      areaId: user.areaId,
    );

    await ref.read(welfareProvider.notifier).add(welfareCase);

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Welfare Case'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member selection
              Text('Member *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMemberId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                hint: const Text('Select member'),
                items: members.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
              const SizedBox(height: 16),

              // Type
              Text('Welfare Type *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: WelfareType.all.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(WelfareType.label(t)),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedType = v ?? WelfareType.financial),
              ),
              const SizedBox(height: 16),

              // Priority
              Text('Priority *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: WelfarePriority.all.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(WelfarePriority.label(p)),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedPriority = v ?? WelfarePriority.medium),
              ),
              const SizedBox(height: 16),

              // Status
              Text('Status *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: WelfareStatus.all.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(WelfareStatus.label(s)),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedStatus = v ?? WelfareStatus.open),
              ),
              const SizedBox(height: 16),

              // Date requested
              Text('Date Requested *',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount requested
              TextFormField(
                controller: _amountRequestedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Requested (GH₵)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.request_quote_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Amount disbursed
              TextFormField(
                controller: _amountDisbursedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Disbursed (GH₵)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.volunteer_activism_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Welfare Case'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
