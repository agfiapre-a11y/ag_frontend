import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/contribution.dart';
import '../../models/department.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/emerald_welcome_section.dart';

final _fmt = NumberFormat('#,##0.00');

/// Maps a member-facing [ContributionType] (tithe/offering/donation) to the
/// Finance Officer's [IncomeCategories] so contributions made by members are
/// reflected directly in the church's official finance records/reports.
/// Welfare contributions are intentionally excluded — they are tracked
/// separately in the Welfare finance module.
String? _financeCategoryFor(String contributionType) {
  switch (contributionType) {
    case ContributionType.tithe:
      return IncomeCategories.tithe;
    case ContributionType.offering:
      return IncomeCategories.offering;
    case ContributionType.donation:
      return IncomeCategories.donation;
    default:
      return null;
  }
}

class MemberFinanceScreen extends ConsumerStatefulWidget {
  const MemberFinanceScreen({super.key});

  @override
  ConsumerState<MemberFinanceScreen> createState() => _MemberFinanceScreenState();
}

class _MemberFinanceScreenState extends ConsumerState<MemberFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user!;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('My Finances'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldWarm,
          labelColor: AppColors.emeraldTextPrimary,
          unselectedLabelColor: AppColors.emeraldTextSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Welfare'),
            Tab(text: 'Tithe'),
            Tab(text: 'Offering'),
            Tab(text: 'Donations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(userId: user.id),
          _WelfareTab(userId: user.id, userName: user.name),
          _ContributionTab(type: ContributionType.tithe, userId: user.id, userName: user.name),
          _ContributionTab(type: ContributionType.offering, userId: user.id, userName: user.name),
          _DonationsTab(userId: user.id, userName: user.name),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String userId;
  const _OverviewTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(myContributionProvider);
    final benefitRequests = ref.watch(myBenefitRequestProvider);
    final user = ref.watch(appStateProvider).user!;

    final welfareTotal = contributions
        .where((c) => c.type == ContributionType.welfare)
        .fold(0.0, (s, c) => s + c.amount);
    final titheTotal = contributions
        .where((c) => c.type == ContributionType.tithe)
        .fold(0.0, (s, c) => s + c.amount);
    final offeringTotal = contributions
        .where((c) => c.type == ContributionType.offering)
        .fold(0.0, (s, c) => s + c.amount);
    final donationTotal = contributions
        .where((c) => c.type == ContributionType.donation)
        .fold(0.0, (s, c) => s + c.amount);
    final grandTotal = welfareTotal + titheTotal + offeringTotal + donationTotal;

    final pendingBenefits = benefitRequests
        .where((r) => r.status == BenefitStatus.pending)
        .toList();
    final approvedBenefits = benefitRequests
        .where((r) => r.status == BenefitStatus.approved || r.status == BenefitStatus.disbursed)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmeraldWelcomeSection(userName: user.name, role: 'Member'),
          const SizedBox(height: 16),

          // Grand total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: EmeraldTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Contributions',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.emeraldTextSecondary)),
                const SizedBox(height: 4),
                Text('GH₵ ${_fmt.format(grandTotal)}',
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldTextPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown cards
          _BreakdownCard(
            label: 'Welfare', amount: welfareTotal,
            icon: Icons.volunteer_activism, color: AppColors.success),
          const SizedBox(height: 10),
          _BreakdownCard(
            label: 'Tithe', amount: titheTotal,
            icon: Icons.church, color: AppColors.goldWarm),
          const SizedBox(height: 10),
          _BreakdownCard(
            label: 'Offering', amount: offeringTotal,
            icon: Icons.savings, color: AppColors.primary),
          const SizedBox(height: 10),
          _BreakdownCard(
            label: 'Donations', amount: donationTotal,
            icon: Icons.favorite, color: AppColors.error),
          const SizedBox(height: 20),

          // Benefit requests summary
          Text('Welfare Benefits',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (pendingBenefits.isNotEmpty)
            _BenefitReminderCard(
              title: 'Pending Requests',
              count: pendingBenefits.length,
              icon: Icons.hourglass_top,
              color: AppColors.warning,
              subtitle: '${pendingBenefits.length} request(s) awaiting review',
            ),
          if (approvedBenefits.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BenefitReminderCard(
              title: 'Approved Benefits',
              count: approvedBenefits.length,
              icon: Icons.check_circle,
              color: AppColors.success,
              subtitle: '${approvedBenefits.length} request(s) approved',
            ),
          ],
          if (pendingBenefits.isEmpty && approvedBenefits.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: EmeraldTheme.cardDecoration,
              child: Row(children: [
                Icon(Icons.info_outline, color: AppColors.emeraldTextMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No welfare benefit requests yet',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.emeraldTextSecondary)),
                ),
              ]),
            ),
          const SizedBox(height: 20),

          // Recent transactions
          Text('Recent Activity',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (contributions.isEmpty)
            _EmptyBox(icon: Icons.receipt_long_outlined, message: 'No contributions yet')
          else
            ...contributions.take(5).map((c) => _ContributionTile(c: c)),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  const _BreakdownCard({required this.label, required this.amount,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EmeraldTheme.cardDecoration,
      child: Row(children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: AppColors.emeraldTextPrimary)),
        ),
        Text('GH₵ ${_fmt.format(amount)}',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _BenefitReminderCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _BenefitReminderCard({required this.title, required this.count,
      required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EmeraldTheme.cardDecoration.copyWith(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.emeraldTextPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.emeraldTextSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Welfare Tab ───────────────────────────────────────────────────────────────

class _WelfareTab extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  const _WelfareTab({required this.userId, required this.userName});

  @override
  ConsumerState<_WelfareTab> createState() => _WelfareTabState();
}

class _WelfareTabState extends ConsumerState<_WelfareTab> {
  bool _showPayForm = false;
  bool _showBenefitForm = false;

  @override
  Widget build(BuildContext context) {
    final contributions = ref.watch(myContributionProvider);
    final benefitRequests = ref.watch(myBenefitRequestProvider);
    final welfareContributions = contributions
        .where((c) => c.type == ContributionType.welfare)
        .toList();
    final welfareTotal = welfareContributions.fold(0.0, (s, c) => s + c.amount);
    final pendingBenefits = benefitRequests
        .where((r) => r.status == BenefitStatus.pending)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: EmeraldTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.volunteer_activism, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Welfare Contributions',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary)),
                ]),
                const SizedBox(height: 8),
                Text('GH₵ ${_fmt.format(welfareTotal)}',
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                const SizedBox(height: 4),
                Text('${welfareContributions.length} contribution(s) total',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.emeraldTextSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _showPayForm = !_showPayForm;
                  _showBenefitForm = false;
                }),
                icon: const Icon(Icons.payments, size: 18),
                label: const Text('Contribute'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _showBenefitForm = !_showBenefitForm;
                  _showPayForm = false;
                }),
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Request Benefit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ]),

          // Pay form
          if (_showPayForm) ...[
            const SizedBox(height: 16),
            _PayContributionForm(
              type: ContributionType.welfare,
              userId: widget.userId,
              userName: widget.userName,
              showWelfareScope: true,
              showMonthPicker: true,
              onDone: () => setState(() => _showPayForm = false),
            ),
          ],

          // Benefit request form
          if (_showBenefitForm) ...[
            const SizedBox(height: 16),
            _BenefitRequestForm(
              userId: widget.userId,
              userName: widget.userName,
              onDone: () => setState(() => _showBenefitForm = false),
            ),
          ],

          const SizedBox(height: 20),

          // Pending reminders
          if (pendingBenefits.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: EmeraldTheme.cardDecoration.copyWith(
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(Icons.notifications_active, color: AppColors.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outstanding Benefit Requests',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.emeraldTextPrimary)),
                      Text('${pendingBenefits.length} request(s) pending review',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.emeraldTextSecondary)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Contribution history
          Text('Contribution History',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (welfareContributions.isEmpty)
            _EmptyBox(icon: Icons.volunteer_activism_outlined, message: 'No welfare contributions yet')
          else
            ...welfareContributions.map((c) => _ContributionTile(c: c)),

          const SizedBox(height: 20),

          // Benefit requests history
          Text('Benefit Requests',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (benefitRequests.isEmpty)
            _EmptyBox(icon: Icons.handshake_outlined, message: 'No benefit requests yet')
          else
            ...benefitRequests.map((r) => _BenefitRequestTile(r: r)),
        ],
      ),
    );
  }
}

// ── Pay Contribution Form ─────────────────────────────────────────────────────

class _PayContributionForm extends ConsumerStatefulWidget {
  final String type;
  final String userId;
  final String userName;
  final VoidCallback onDone;
  final bool showWelfareScope;
  final bool showMonthPicker;
  const _PayContributionForm({required this.type, required this.userId,
      required this.userName, required this.onDone,
      this.showWelfareScope = false, this.showMonthPicker = false});

  @override
  ConsumerState<_PayContributionForm> createState() => _PayContributionFormState();
}

class _PayContributionFormState extends ConsumerState<_PayContributionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String _welfareScope = WelfareScope.church;
  String? _selectedDeptId;
  DateTime? _selectedMonth;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Select contribution month',
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  String? get _monthLabel {
    if (_selectedMonth == null) return null;
    return DateFormat('MMMM yyyy').format(_selectedMonth!);
  }

  String? get _monthKey {
    if (_selectedMonth == null) return null;
    return '${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    if (widget.showWelfareScope && _welfareScope == WelfareScope.department && _selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (widget.showMonthPicker && _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contribution month'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final departments = ref.read(departmentProvider);
      final dept = departments.where((d) => d.id == _selectedDeptId).firstOrNull;
      final c = MemberContribution(
        id: const Uuid().v4(),
        churchId: appState.church?.id ?? "",
        branchId: user.branchId,
        memberId: widget.userId,
        memberName: widget.userName,
        type: widget.type,
        amount: amount,
        description: _descCtrl.text.trim(),
        departmentId: _welfareScope == WelfareScope.department ? _selectedDeptId : null,
        departmentName: dept?.name ?? '',
        welfareScope: _welfareScope,
        contributionMonth: _monthKey,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await ref.read(myContributionProvider.notifier).add(c);

      // Sync tithe/offering contributions into the Finance Officer's
      // official records so they appear in finance totals and reports.
      final financeCategory = _financeCategoryFor(widget.type);
      if (financeCategory != null) {
        await ref.read(financeProvider.notifier).add(FinanceTransaction(
              id: const Uuid().v4(),
              churchId: c.churchId,
              branchId: c.branchId,
              type: TransactionType.income,
              category: financeCategory,
              amount: amount,
              description: c.description.isNotEmpty
                  ? c.description
                  : '${_typeLabel(widget.type)} from ${c.memberName}',
              date: c.date,
              recordedById: c.memberId,
              createdAt: c.createdAt,
            ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_typeLabel(widget.type)} contribution recorded'),
              backgroundColor: Colors.green),
        );
        widget.onDone();
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
    final departments = ref.watch(departmentProvider);
    final userDeptId = ref.watch(appStateProvider).user?.departmentId ?? '';
    // Show all departments in the branch, but highlight the member's own department
    final memberDepartments = departments.where((d) =>
        d.id == userDeptId || true).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EmeraldTheme.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Make a ${_typeLabel(widget.type)} Contribution',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary)),
            const SizedBox(height: 12),

            // Welfare scope selector
            if (widget.showWelfareScope) ...[
              Text('Welfare Type',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.emeraldTextSecondary)),
              const SizedBox(height: 6),
              RadioGroup<String>(
                groupValue: _welfareScope,
                onChanged: (v) => setState(() {
                  _welfareScope = v ?? WelfareScope.church;
                  if (_welfareScope == WelfareScope.church) _selectedDeptId = null;
                }),
                child: Row(children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Church Welfare'),
                    value: WelfareScope.church,
                    activeColor: AppColors.success,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Department Welfare'),
                    value: WelfareScope.department,
                    activeColor: AppColors.success,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ]),
              ),
              if (_welfareScope == WelfareScope.department) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeptId,
                  decoration: InputDecoration(
                    labelText: 'Select Department',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
                  ),
                  items: memberDepartments.map((d) =>
                      DropdownMenuItem(
                        value: d.id,
                        child: Row(children: [
                          if (d.id == userDeptId)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.star, size: 14, color: AppColors.goldWarm),
                            ),
                          Text(d.name),
                        ]),
                      )).toList(),
                  onChanged: (v) => setState(() => _selectedDeptId = v),
                ),
              ],
              const SizedBox(height: 10),
            ],

            // Month picker
            if (widget.showMonthPicker) ...[
              GestureDetector(
                onTap: _pickMonth,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _monthLabel ?? ''),
                    decoration: InputDecoration(
                      labelText: 'Contribution Month',
                      suffixIcon: const Icon(Icons.calendar_month),
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (GH₵)',
                prefixText: 'GH₵ ',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amt = double.tryParse(v.trim().replaceAll(',', ''));
                if (amt == null || amt <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Contribution'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Benefit Request Form ──────────────────────────────────────────────────────

class _BenefitRequestForm extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback onDone;
  const _BenefitRequestForm({required this.userId, required this.userName,
      required this.onDone});

  @override
  ConsumerState<_BenefitRequestForm> createState() => _BenefitRequestFormState();
}

class _BenefitRequestFormState extends ConsumerState<_BenefitRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _benefitType = BenefitType.medical;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final r = BenefitRequest(
        id: const Uuid().v4(),
        churchId: appState.church?.id ?? "",
        branchId: user.branchId,
        memberId: widget.userId,
        memberName: widget.userName,
        type: _benefitType,
        description: _descCtrl.text.trim(),
        status: BenefitStatus.pending,
        amountRequested: amount,
        requestDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await ref.read(myBenefitRequestProvider.notifier).add(r);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Benefit request submitted'),
              backgroundColor: Colors.green),
        );
        widget.onDone();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EmeraldTheme.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Welfare Benefit',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _benefitType,
              decoration: InputDecoration(
                labelText: 'Benefit Type',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              items: BenefitType.all.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _benefitType = v ?? BenefitType.medical),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Requested (GH₵)',
                prefixText: 'GH₵ ',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amt = double.tryParse(v.trim().replaceAll(',', ''));
                if (amt == null || amt <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe your need',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please describe your need' : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generic Contribution Tab (Tithe / Offering) ───────────────────────────────

class _ContributionTab extends ConsumerStatefulWidget {
  final String type;
  final String userId;
  final String userName;
  const _ContributionTab({required this.type, required this.userId,
      required this.userName});

  @override
  ConsumerState<_ContributionTab> createState() => _ContributionTabState();
}

class _ContributionTabState extends ConsumerState<_ContributionTab> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final contributions = ref.watch(myContributionProvider);
    final filtered = contributions.where((c) => c.type == widget.type).toList();
    final total = filtered.fold(0.0, (s, c) => s + c.amount);
    final label = _typeLabel(widget.type);
    final color = widget.type == ContributionType.tithe ? AppColors.goldWarm : AppColors.primary;
    final icon = widget.type == ContributionType.tithe ? Icons.church : Icons.savings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: EmeraldTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('$label Contributions',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary)),
                ]),
                const SizedBox(height: 8),
                Text('GH₵ ${_fmt.format(total)}',
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text('${filtered.length} contribution(s) total',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.emeraldTextSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Make $label Contribution'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_showForm) ...[
            const SizedBox(height: 16),
            _PayContributionForm(
              type: widget.type, userId: widget.userId, userName: widget.userName,
              showMonthPicker: widget.type == ContributionType.tithe,
              onDone: () => setState(() => _showForm = false),
            ),
          ],
          const SizedBox(height: 20),
          Text('History',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            _EmptyBox(icon: Icons.receipt_long_outlined, message: 'No $label contributions yet')
          else
            ...filtered.map((c) => _ContributionTile(c: c)),
        ],
      ),
    );
  }
}

// ── Donations Tab ─────────────────────────────────────────────────────────────

class _DonationsTab extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  const _DonationsTab({required this.userId, required this.userName});

  @override
  ConsumerState<_DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends ConsumerState<_DonationsTab> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final contributions = ref.watch(myContributionProvider);
    final departments = ref.watch(departmentProvider);
    final donations = contributions
        .where((c) => c.type == ContributionType.donation)
        .toList();
    final total = donations.fold(0.0, (s, c) => s + c.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: EmeraldTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.favorite, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text('Voluntary Donations',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary)),
                ]),
                const SizedBox(height: 8),
                Text('GH₵ ${_fmt.format(total)}',
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: AppColors.error)),
                const SizedBox(height: 4),
                Text('${donations.length} donation(s) total',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.emeraldTextSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: const Icon(Icons.favorite, size: 18),
              label: const Text('Make a Donation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_showForm) ...[
            const SizedBox(height: 16),
            _DonationForm(
              userId: widget.userId, userName: widget.userName,
              departments: departments,
              onDone: () => setState(() => _showForm = false),
            ),
          ],
          const SizedBox(height: 20),
          Text('Donation History',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (donations.isEmpty)
            _EmptyBox(icon: Icons.favorite_outline, message: 'No donations yet')
          else
            ...donations.map((c) => _ContributionTile(c: c)),
        ],
      ),
    );
  }
}

// ── Donation Form (with department selection) ─────────────────────────────────

class _DonationForm extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final List<Department> departments;
  final VoidCallback onDone;
  const _DonationForm({required this.userId, required this.userName,
      required this.departments, required this.onDone});

  @override
  ConsumerState<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends ConsumerState<_DonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedDeptId;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final dept = widget.departments.where((d) => d.id == _selectedDeptId).firstOrNull;
      final c = MemberContribution(
        id: const Uuid().v4(),
        churchId: appState.church?.id ?? "",
        branchId: user.branchId,
        memberId: widget.userId,
        memberName: widget.userName,
        type: ContributionType.donation,
        amount: amount,
        description: _descCtrl.text.trim(),
        departmentId: _selectedDeptId,
        departmentName: dept?.name ?? '',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await ref.read(myContributionProvider.notifier).add(c);

      // Sync donation to the Finance Officer's official records.
      await ref.read(financeProvider.notifier).add(FinanceTransaction(
            id: const Uuid().v4(),
            churchId: c.churchId,
            branchId: c.branchId,
            type: TransactionType.income,
            category: IncomeCategories.donation,
            amount: amount,
            description: c.description.isNotEmpty
                ? c.description
                : 'Donation from ${c.memberName}',
            date: c.date,
            recordedById: c.memberId,
            createdAt: c.createdAt,
          ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation recorded'),
              backgroundColor: Colors.green),
        );
        widget.onDone();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EmeraldTheme.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Make a Voluntary Donation',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary)),
            const SizedBox(height: 12),
            if (widget.departments.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedDeptId,
                decoration: InputDecoration(
                  labelText: 'Department (optional)',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('General / No specific department')),
                  ...widget.departments.map((d) =>
                      DropdownMenuItem(value: d.id, child: Text(d.name))),
                ],
                onChanged: (v) => setState(() => _selectedDeptId = v),
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (GH₵)',
                prefixText: 'GH₵ ',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amt = double.tryParse(v.trim().replaceAll(',', ''));
                if (amt == null || amt <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error, foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Donation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tiles & Helpers ───────────────────────────────────────────────────────────

class _ContributionTile extends StatelessWidget {
  final MemberContribution c;
  const _ContributionTile({required this.c});

  Color get _color {
    switch (c.type) {
      case ContributionType.welfare: return AppColors.success;
      case ContributionType.tithe: return AppColors.goldWarm;
      case ContributionType.offering: return AppColors.primary;
      case ContributionType.donation: return AppColors.error;
      default: return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (c.type) {
      case ContributionType.welfare: return Icons.volunteer_activism;
      case ContributionType.tithe: return Icons.church;
      case ContributionType.offering: return Icons.savings;
      case ContributionType.donation: return Icons.favorite;
      default: return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: EmeraldTheme.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.12),
          child: Icon(_icon, color: _color, size: 20),
        ),
        title: Row(children: [
          Expanded(
            child: Text(
              c.type == ContributionType.welfare
                  ? '${_typeLabel(c.type)} (${c.welfareScope == WelfareScope.department ? "Dept" : "Church"})'
                  : _typeLabel(c.type),
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary)),
          ),
          Text('GH₵ ${_fmt.format(c.amount)}',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _color)),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.description.isNotEmpty)
              Text(c.description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.emeraldTextSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (c.departmentName.isNotEmpty)
              Text('Dept: ${c.departmentName}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.emeraldTextMuted)),
            if (c.contributionMonth != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.calendar_month, size: 12, color: AppColors.emeraldTextMuted),
                const SizedBox(width: 4),
                Text(_formatMonthKey(c.contributionMonth!),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.emeraldTextSecondary,
                        fontWeight: FontWeight.w500)),
              ]),
            ],
            const SizedBox(height: 2),
            Text(DateFormat('MMM d, yyyy').format(c.date),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.emeraldTextSecondary)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _BenefitRequestTile extends StatelessWidget {
  final BenefitRequest r;
  const _BenefitRequestTile({required this.r});

  Color get _statusColor {
    switch (r.status) {
      case BenefitStatus.pending: return AppColors.warning;
      case BenefitStatus.approved: return AppColors.success;
      case BenefitStatus.rejected: return AppColors.error;
      case BenefitStatus.disbursed: return AppColors.primary;
      default: return AppColors.emeraldTextMuted;
    }
  }

  IconData get _statusIcon {
    switch (r.status) {
      case BenefitStatus.pending: return Icons.hourglass_top;
      case BenefitStatus.approved: return Icons.check_circle;
      case BenefitStatus.rejected: return Icons.cancel;
      case BenefitStatus.disbursed: return Icons.paid;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: EmeraldTheme.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _statusColor.withValues(alpha: 0.12),
          child: Icon(_statusIcon, color: _statusColor, size: 20),
        ),
        title: Row(children: [
          Expanded(
            child: Text(r.type,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(r.status.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor)),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.description.isNotEmpty)
              Text(r.description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.emeraldTextSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text('Requested: GH₵ ${_fmt.format(r.amountRequested)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.emeraldTextSecondary)),
              if (r.amountApproved != null) ...[
                const SizedBox(width: 8),
                Text('Approved: GH₵ ${_fmt.format(r.amountApproved)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ]),
            const SizedBox(height: 2),
            Text(DateFormat('MMM d, yyyy').format(r.requestDate),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.emeraldTextMuted)),
            if (r.adminNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${r.adminNotes}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.emeraldTextSecondary, fontStyle: FontStyle.italic),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: EmeraldTheme.cardDecoration,
      child: Column(children: [
        Icon(icon, size: 40, color: AppColors.emeraldTextMuted),
        const SizedBox(height: 8),
        Text(message,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.emeraldTextSecondary)),
      ]),
    );
  }
}

String _typeLabel(String type) {
  switch (type) {
    case ContributionType.welfare: return 'Welfare';
    case ContributionType.tithe: return 'Tithe';
    case ContributionType.offering: return 'Offering';
    case ContributionType.donation: return 'Donation';
    default: return 'Contribution';
  }
}

String _formatMonthKey(String key) {
  final parts = key.split('-');
  if (parts.length != 2) return key;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return key;
  final date = DateTime(year, month);
  return DateFormat('MMMM yyyy').format(date);
}
