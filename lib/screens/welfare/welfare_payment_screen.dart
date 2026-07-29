import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/welfare_finance.dart';
import '../../models/welfare_case.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

const _uuid = Uuid();

class WelfarePaymentScreen extends ConsumerStatefulWidget {
  const WelfarePaymentScreen({super.key});

  @override
  ConsumerState<WelfarePaymentScreen> createState() =>
      _WelfarePaymentScreenState();
}

class _WelfarePaymentScreenState extends ConsumerState<WelfarePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String? _memberId;
  String _paymentType = WelfareTxnType.disbursement;
  String _paymentMethod = WelfarePaymentMethod.cash;
  String? _welfareCaseId;
  String? _departmentId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberProvider);
    final welfareCases = ref.watch(welfareProvider);
    final departments = ref.watch(departmentProvider);
    final user = ref.watch(appStateProvider).user!;

    final memberCases =
        _memberId != null ? welfareCases.where((w) => w.memberId == _memberId).toList() : <WelfareCase>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Make Welfare Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record a payment on behalf of a member',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 20),

              // Payment type selector
              Text('Payment Type',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: WelfareTxnType.disbursement,
                    label: const Text('Disbursement'),
                    icon: const Icon(Icons.volunteer_activism),
                  ),
                  ButtonSegment(
                    value: WelfareTxnType.contribution,
                    label: const Text('Contribution'),
                    icon: const Icon(Icons.savings),
                  ),
                  ButtonSegment(
                    value: WelfareTxnType.expense,
                    label: const Text('Expense'),
                    icon: const Icon(Icons.shopping_cart),
                  ),
                ],
                selected: {_paymentType},
                onSelectionChanged: (s) =>
                    setState(() => _paymentType = s.first),
              ),
              const SizedBox(height: 20),

              // Member selection
              DropdownButtonFormField<String>(
                initialValue: _memberId,
                decoration: const InputDecoration(
                  labelText: 'Member',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                        value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _memberId = v;
                  _welfareCaseId = null;
                }),
                validator: (v) => v == null ? 'Select a member' : null,
              ),
              const SizedBox(height: 12),

              // Link to welfare case (optional)
              if (memberCases.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _welfareCaseId,
                  decoration: const InputDecoration(
                    labelText: 'Link to Welfare Case (optional)',
                    prefixIcon: Icon(Icons.folder_open),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('No specific case')),
                    ...memberCases.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(
                            '${WelfareType.label(w.type)} · ${WelfareStatus.label(w.status)}'))),
                  ],
                  onChanged: (v) => setState(() => _welfareCaseId = v),
                ),
                const SizedBox(height: 12),
              ],

              // Link to department (optional)
              DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: const InputDecoration(
                  labelText: 'Department Welfare Fund (optional)',
                  prefixIcon: Icon(Icons.groups_2_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('No department')),
                  ...departments.map((d) => DropdownMenuItem(
                      value: d.id, child: Text(d.name))),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / Reason',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Payment method
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: WelfarePaymentMethod.all
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(WelfarePaymentMethod.label(m))))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 12),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat('MMM d, y').format(_date)}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 12),

              // Reference number
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference / Cheque Number (optional)',
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _submit(context, user.id),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving...' : 'Record Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final appState = ref.read(appStateProvider);
    final txn = WelfareTransaction(
      id: _uuid.v4(),
      churchId: appState.church?.id ?? '',
      branchId: appState.user?.branchId ?? '',
      type: _paymentType,
      category: _descCtrl.text.isNotEmpty
          ? _descCtrl.text
          : WelfareTxnType.label(_paymentType),
      amount: double.parse(_amountCtrl.text),
      description: _descCtrl.text,
      memberId: _memberId!,
      departmentId: _departmentId,
      welfareCaseId: _welfareCaseId,
      recordedById: userId,
      date: _date,
      paymentMethod: _paymentMethod,
      referenceNumber: _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
      createdAt: DateTime.now(),
    );

    await ref.read(welfareFinanceProvider.notifier).add(txn);

    // Update department welfare fund if linked
    if (_departmentId != null) {
      final dw = LocalDb.getAllDepartmentWelfare(
        churchId: appState.church?.id ?? '',
        branchId: appState.user?.branchId,
      ).where((d) => d.departmentId == _departmentId).firstOrNull;
      if (dw != null) {
        double newContributions = dw.totalContributions;
        double newDisbursements = dw.totalDisbursements;
        double newBalance = dw.fundBalance;

        if (_paymentType == WelfareTxnType.contribution) {
          newContributions += txn.amount;
          newBalance += txn.amount;
        } else {
          newDisbursements += txn.amount;
          newBalance -= txn.amount;
        }
        await ref.read(departmentWelfareProvider.notifier).update(
              dw.copyWith(
                fundBalance: newBalance,
                totalContributions: newContributions,
                totalDisbursements: newDisbursements,
              ),
            );
      }
    }

    if (context.mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
      context.pop();
    }
  }
}
