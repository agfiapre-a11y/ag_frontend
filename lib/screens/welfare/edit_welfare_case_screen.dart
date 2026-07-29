import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/welfare_case.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EditWelfareCaseScreen extends ConsumerStatefulWidget {
  final String welfareCaseId;

  const EditWelfareCaseScreen({super.key, required this.welfareCaseId});

  @override
  ConsumerState<EditWelfareCaseScreen> createState() =>
      _EditWelfareCaseScreenState();
}

class _EditWelfareCaseScreenState extends ConsumerState<EditWelfareCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountRequestedController = TextEditingController();
  final _amountDisbursedController = TextEditingController();
  final _notesController = TextEditingController();

  WelfareCase? _welfareCase;
  String? _selectedMemberId;
  String _selectedType = WelfareType.financial;
  String _selectedStatus = WelfareStatus.open;
  String _selectedPriority = WelfarePriority.medium;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  void _loadCase() {
    final wc = LocalDb.getWelfareCaseById(widget.welfareCaseId);
    if (wc == null) {
      if (mounted) context.pop();
      return;
    }
    _welfareCase = wc;
    _selectedMemberId = wc.memberId;
    _selectedType = wc.type;
    _selectedStatus = wc.status;
    _selectedPriority = wc.priority;
    _selectedDate = wc.dateRequested;
    _descriptionController.text = wc.description;
    _amountRequestedController.text =
        wc.amountRequested > 0 ? wc.amountRequested.toString() : '';
    _amountDisbursedController.text =
        wc.amountDisbursed > 0 ? wc.amountDisbursed.toString() : '';
    _notesController.text = wc.notes;
    setState(() => _loading = false);
  }

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
    if (_welfareCase == null) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = _welfareCase!.copyWith(
      memberId: _selectedMemberId,
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      description: _descriptionController.text.trim(),
      amountRequested: double.tryParse(_amountRequestedController.text) ?? 0,
      amountDisbursed: double.tryParse(_amountDisbursedController.text) ?? 0,
      dateRequested: _selectedDate,
      notes: _notesController.text.trim(),
      dateClosed: _selectedStatus == WelfareStatus.closed
          ? _welfareCase!.dateClosed ?? DateTime.now()
          : null,
    );

    await ref.read(welfareProvider.notifier).update(updated);

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Welfare Case')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Welfare Case'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      : const Text('Update Welfare Case'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
