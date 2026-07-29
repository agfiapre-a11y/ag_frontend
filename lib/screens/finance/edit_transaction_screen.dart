import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = TransactionType.income;
  String _category = IncomeCategories.tithe;
  DateTime _date = DateTime.now();
  String? _branchId;
  bool _loading = false;
  bool _isRecurring = false;
  String _recurrenceInterval = RecurrenceInterval.monthly;
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  void _loadTransaction() {
    final tx = LocalDb.getTransactionById(widget.transactionId);
    if (tx != null) {
      setState(() {
        _type = tx.type;
        _category = tx.category;
        _date = tx.date;
        _branchId = tx.branchId;
        _amountCtrl.text = tx.amount.toString();
        _descCtrl.text = tx.description;
        _isRecurring = tx.isRecurring;
        _recurrenceInterval = tx.recurrenceInterval.isNotEmpty ? tx.recurrenceInterval : RecurrenceInterval.monthly;
        _receiptPath = tx.receiptPath;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == TransactionType.income
      ? IncomeCategories.all
      : ExpenseCategories.all;

  void _onTypeChanged(String type) {
    setState(() {
      _type = type;
      _category = _type == TransactionType.income
          ? IncomeCategories.tithe
          : ExpenseCategories.salary;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final isSystemLevel = AppRoles.crossBranchRoles.contains(user.role);

    if (isSystemLevel && (_branchId == null || _branchId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return;
    }

    final amount = double.tryParse(
        _amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final existingTx = LocalDb.getTransactionById(widget.transactionId);
      if (existingTx == null) {
        throw Exception('Transaction not found');
      }

      final updatedTx = FinanceTransaction(
        id: existingTx.id,
        churchId: existingTx.churchId,
        branchId: _branchId ?? existingTx.branchId,
        type: _type,
        category: _category,
        amount: amount,
        description: _descCtrl.text.trim(),
        date: _date,
        recordedById: existingTx.recordedById,
        createdAt: existingTx.createdAt,
        isRecurring: _isRecurring,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : '',
        receiptPath: _receiptPath ?? existingTx.receiptPath,
        lastModifiedById: user.id,
        lastModifiedAt: DateTime.now(),
      );
      await ref.read(financeProvider.notifier).update(updatedTx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated'),
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
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final isSystemLevel = AppRoles.crossBranchRoles.contains(user.role);
    final isIncome = _type == TransactionType.income;
    final typeColor = isIncome ? AppColors.success : AppColors.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income / Expense toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppColors.success
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 16,
                                color: isIncome
                                    ? Colors.white
                                    : Colors.grey),
                            const SizedBox(width: 6),
                            Text('Income',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: isIncome
                                        ? Colors.white
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isIncome
                              ? AppColors.error
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward,
                                size: 16,
                                color: !isIncome
                                    ? Colors.white
                                    : Colors.grey),
                            const SizedBox(width: 6),
                            Text('Expense',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: !isIncome
                                        ? Colors.white
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Transaction Details'),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final n = double.tryParse(v.trim().replaceAll(',', ''));
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Amount (GH₵)',
                  prefixIcon: Icon(Icons.monetization_on_outlined,
                      color: typeColor),
                  prefixIconColor: typeColor,
                ),
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // Date
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_date),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),

              // Recurring transaction
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Recurring Transaction'),
                subtitle: const Text('Enable for recurring income/expenses'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  initialValue: _recurrenceInterval,
                  decoration: const InputDecoration(
                    labelText: 'Recurrence Interval',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: RecurrenceInterval.all
                      .map((r) => DropdownMenuItem(value: r, child: Text(RecurrenceInterval.label(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _recurrenceInterval = v!),
                ),
              ],

              // Branch selector (superAdmin only)
              if (isSystemLevel && branches.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('Branch'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(
                    labelText: 'Branch *',
                    prefixIcon: Icon(Icons.account_tree),
                  ),
                  hint: const Text('Select branch'),
                  items: branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _branchId = v),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isIncome ? 'Update Income' : 'Update Expense',
                      ),
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
}
