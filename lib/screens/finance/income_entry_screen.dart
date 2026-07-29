import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/finance_approval.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _dateFmt = DateFormat('MMM d, yyyy');

class IncomeEntryScreen extends ConsumerStatefulWidget {
  const IncomeEntryScreen({super.key});

  @override
  ConsumerState<IncomeEntryScreen> createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends ConsumerState<IncomeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: _dateFmt.format(DateTime.now()));
  bool _sendForApproval = false;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', ''));
      final date = _dateCtrl.text.isNotEmpty ? DateFormat('MMM d, yyyy').parse(_dateCtrl.text) : DateTime.now();

      if (_sendForApproval) {
        final request = FinanceApprovalRequest(
          id: const Uuid().v4(),
          churchId: appState.church?.id ?? '',
          branchId: user.branchId,
          type: 'income',
          category: _categoryCtrl.text.trim(),
          amount: amount,
          description: _descriptionCtrl.text.trim(),
          date: date,
          requestedById: user.id,
          requestedByName: user.name,
          status: FinanceApprovalStatus.pending,
          createdAt: DateTime.now(),
        );
        await ref.read(financeApprovalProvider.notifier).add(request);
      } else {
        final txn = FinanceTransaction(
          id: const Uuid().v4(),
          churchId: appState.church?.id ?? '',
          branchId: user.branchId,
          type: TransactionType.income,
          category: _categoryCtrl.text.trim(),
          amount: amount,
          description: _descriptionCtrl.text.trim(),
          date: date,
          recordedById: user.id,
          createdAt: DateTime.now(),
        );
        await ref.read(financeProvider.notifier).add(txn);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sendForApproval ? 'Sent for approval' : 'Income recorded'),
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
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Income Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record Income', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (GH₵)',
                  prefixText: 'GH₵ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amt = double.tryParse(v.trim().replaceAll(',', ''));
                  if (amt == null || amt <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    _dateCtrl.text = _dateFmt.format(picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Send for approval'),
                subtitle: const Text('Requires approval from higher hierarchy'),
                value: _sendForApproval,
                onChanged: (v) => setState(() => _sendForApproval = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_sendForApproval ? 'Submit for Approval' : 'Record Income'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
