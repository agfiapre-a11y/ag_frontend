import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/welfare_finance.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

final _currencyFmt = NumberFormat('#,##0.00');
const _uuid = Uuid();

class WelfareTransactionsScreen extends ConsumerStatefulWidget {
  const WelfareTransactionsScreen({super.key});

  @override
  ConsumerState<WelfareTransactionsScreen> createState() =>
      _WelfareTransactionsScreenState();
}

class _WelfareTransactionsScreenState
    extends ConsumerState<WelfareTransactionsScreen> {
  String? _typeFilter;
  String? _memberFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(welfareFinanceProvider);
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;

    var filtered = txns;
    if (_typeFilter != null) {
      filtered = filtered.where((t) => t.type == _typeFilter).toList();
    }
    if (_memberFilter != null) {
      filtered = filtered.where((t) => t.memberId == _memberFilter).toList();
    }
    if (_startDate != null) {
      filtered =
          filtered.where((t) => t.date.isAfter(_startDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (_endDate != null) {
      filtered =
          filtered.where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    final totalIn =
        filtered.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final totalOut =
        filtered.where((t) => !t.isContribution).fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context, members, user.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(_typeFilter == null
                        ? 'All Types'
                        : WelfareTxnType.label(_typeFilter!)),
                    selected: _typeFilter != null,
                    onSelected: (_) => _showTypeFilter(context),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(_startDate == null
                        ? 'Start Date'
                        : DateFormat('MMM d').format(_startDate!)),
                    selected: _startDate != null,
                    onSelected: (_) => _pickDate(context, true),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(_endDate == null
                        ? 'End Date'
                        : DateFormat('MMM d').format(_endDate!)),
                    selected: _endDate != null,
                    onSelected: (_) => _pickDate(context, false),
                  ),
                  if (_typeFilter != null || _startDate != null || _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton(
                        onPressed: () => setState(() {
                          _typeFilter = null;
                          _startDate = null;
                          _endDate = null;
                        }),
                        child: const Text('Clear'),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                      label: 'Inflow',
                      value: _currencyFmt.format(totalIn),
                      color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                      label: 'Outflow',
                      value: _currencyFmt.format(totalOut),
                      color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                      label: 'Net',
                      value: _currencyFmt.format(totalIn - totalOut),
                      color: AppColors.emeraldDeep),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No transactions found',
                            style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      final member = members.where((m) => m.id == t.memberId).firstOrNull;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                WelfareTxnType.color(t.type).withValues(alpha: 0.12),
                            child: Icon(WelfareTxnType.icon(t.type),
                                color: WelfareTxnType.color(t.type), size: 20),
                          ),
                          title: Text(
                            member?.name ?? 'Unknown Member',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${WelfareTxnType.label(t.type)} · ${t.category} · ${DateFormat('MMM d, y').format(t.date)}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFmt.format(t.amount),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: t.isContribution ? Colors.green : Colors.red,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () =>
                                    _confirmDelete(context, t),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTypeFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Filter by Type'),
        children: WelfareTxnType.all.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _typeFilter = type);
              Navigator.pop(context);
            },
            child: Text(WelfareTxnType.label(type)),
          );
        }).toList()
          ..add(SimpleDialogOption(
            onPressed: () {
              setState(() => _typeFilter = null);
              Navigator.pop(context);
            },
            child: const Text('All Types'),
          )),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showAddTransactionDialog(
      BuildContext context, List<Member> members, String userId) {
    showDialog(
      context: context,
      builder: (_) => _AddTransactionDialog(
        members: members,
        userId: userId,
        onSave: (txn) async {
          await ref.read(welfareFinanceProvider.notifier).add(txn);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WelfareTransaction txn) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(welfareFinanceProvider.notifier).delete(txn.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  final List<Member> members;
  final String userId;
  final Function(WelfareTransaction) onSave;

  const _AddTransactionDialog({
    required this.members,
    required this.userId,
    required this.onSave,
  });

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _type = WelfareTxnType.contribution;
  String _paymentMethod = WelfarePaymentMethod.cash;
  String? _memberId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Welfare Transaction'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: WelfareTxnType.all
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(WelfareTxnType.label(t))))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _memberId,
                  decoration: const InputDecoration(labelText: 'Member'),
                  items: widget.members
                      .map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _memberId = v),
                  validator: (v) => v == null ? 'Select a member' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Category'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: WelfarePaymentMethod.all
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(WelfarePaymentMethod.label(m))))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('MMM d, y').format(_date)}'),
                  trailing: const Icon(Icons.calendar_today),
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
                TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Reference Number (optional)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final appState =
                ProviderScope.containerOf(context).read(appStateProvider);
            final txn = WelfareTransaction(
              id: _uuid.v4(),
              churchId: appState.church?.id ?? '',
              branchId: appState.user?.branchId ?? '',
              type: _type,
              category: _descCtrl.text.isNotEmpty ? _descCtrl.text : WelfareTxnType.label(_type),
              amount: double.parse(_amountCtrl.text),
              description: _descCtrl.text,
              memberId: _memberId!,
              recordedById: widget.userId,
              date: _date,
              paymentMethod: _paymentMethod,
              referenceNumber: _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
              createdAt: DateTime.now(),
            );
            widget.onSave(txn);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
