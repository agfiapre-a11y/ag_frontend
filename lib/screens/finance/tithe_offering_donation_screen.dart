import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/contribution.dart';
import '../../models/member.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _fmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');
final _monthFmt = DateFormat('MMMM yyyy');

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

String _typeLabel(String type) {
  switch (type) {
    case ContributionType.tithe:
      return 'Tithe';
    case ContributionType.offering:
      return 'Offering';
    case ContributionType.donation:
      return 'Donation';
    case ContributionType.welfare:
      return 'Welfare';
    default:
      return 'Contribution';
  }
}

class TitheOfferingDonationScreen extends ConsumerStatefulWidget {
  const TitheOfferingDonationScreen({super.key});

  @override
  ConsumerState<TitheOfferingDonationScreen> createState() =>
      _TitheOfferingDonationScreenState();
}

class _TitheOfferingDonationScreenState
    extends ConsumerState<TitheOfferingDonationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _inMonth(List<FinanceTransaction> all) =>
      all.where((t) => t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month).toList();

  List<FinanceTransaction> _byCategory(List<FinanceTransaction> all, String category) =>
      all.where((t) => t.isIncome && t.category == category).toList();

  void _prevMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final allTx = ref.watch(financeProvider);
    final contributions = ref.watch(contributionProvider);
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.financeManagerRoles.contains(user.role);

    final monthTx = _inMonth(allTx);
    final titheTx = _byCategory(monthTx, IncomeCategories.tithe);
    final offeringTx = _byCategory(monthTx, IncomeCategories.offering);
    final donationTx = _byCategory(monthTx, IncomeCategories.donation);
    final titheTotal = titheTx.fold(0.0, (s, t) => s + t.amount);
    final offeringTotal = offeringTx.fold(0.0, (s, t) => s + t.amount);
    final donationTotal = donationTx.fold(0.0, (s, t) => s + t.amount);
    final grandTotal = titheTotal + offeringTotal + donationTotal;

    final monthContributions = contributions.where((c) {
      return c.date.year == _selectedMonth.year && c.date.month == _selectedMonth.month &&
          (c.type == ContributionType.tithe || c.type == ContributionType.offering || c.type == ContributionType.donation);
    }).toList();

    final titheContribs = monthContributions.where((c) => c.type == ContributionType.tithe).toList();
    final offeringContribs = monthContributions.where((c) => c.type == ContributionType.offering).toList();
    final donationContribs = monthContributions.where((c) => c.type == ContributionType.donation).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Tithes, Offerings & Donations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(financeProvider.notifier).refresh();
              ref.read(contributionProvider.notifier).refresh();
              ref.read(memberProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Tithe', icon: Icon(Icons.favorite)),
            Tab(text: 'Offering', icon: Icon(Icons.volunteer_activism)),
            Tab(text: 'Donation', icon: Icon(Icons.card_giftcard)),
          ],
        ),
      ),
      body: Column(
        children: [
          _MonthSelector(
            month: _selectedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  titheTotal: titheTotal,
                  offeringTotal: offeringTotal,
                  donationTotal: donationTotal,
                  grandTotal: grandTotal,
                  titheContributions: titheContribs,
                  offeringContributions: offeringContribs,
                  donationContributions: donationContribs,
                  contributionCount: monthContributions.length,
                  canManage: canManage,
                  onRecord: canManage ? _openIncomeEntry : null,
                  members: members,
                  churchId: user.churchId,
                  branchId: user.branchId,
                  recordedById: user.id,
                ),
                _CategoryTab(
                  type: ContributionType.tithe,
                  transactions: titheTx,
                  contributions: titheContribs,
                  canManage: canManage,
                  members: members,
                  churchId: user.churchId,
                  branchId: user.branchId,
                  recordedById: user.id,
                ),
                _CategoryTab(
                  type: ContributionType.offering,
                  transactions: offeringTx,
                  contributions: offeringContribs,
                  canManage: canManage,
                  members: members,
                  churchId: user.churchId,
                  branchId: user.branchId,
                  recordedById: user.id,
                ),
                _CategoryTab(
                  type: ContributionType.donation,
                  transactions: donationTx,
                  contributions: donationContribs,
                  canManage: canManage,
                  members: members,
                  churchId: user.churchId,
                  branchId: user.branchId,
                  recordedById: user.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openIncomeEntry() {
    context.push('/finance/income-entry');
  }
}

class _OverviewTab extends ConsumerStatefulWidget {
  final double titheTotal;
  final double offeringTotal;
  final double donationTotal;
  final double grandTotal;
  final List<MemberContribution> titheContributions;
  final List<MemberContribution> offeringContributions;
  final List<MemberContribution> donationContributions;
  final int contributionCount;
  final bool canManage;
  final VoidCallback? onRecord;
  final List<Member> members;
  final String churchId;
  final String branchId;
  final String recordedById;

  const _OverviewTab({
    required this.titheTotal,
    required this.offeringTotal,
    required this.donationTotal,
    required this.grandTotal,
    required this.titheContributions,
    required this.offeringContributions,
    required this.donationContributions,
    required this.contributionCount,
    required this.canManage,
    this.onRecord,
    required this.members,
    required this.churchId,
    required this.branchId,
    required this.recordedById,
  });

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  String _selectedType = ContributionType.tithe;

  void _openRecordForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _RecordContributionForm(
            type: _selectedType,
            members: widget.members,
            churchId: widget.churchId,
            branchId: widget.branchId,
            recordedById: widget.recordedById,
            onTypeChanged: (t) => setState(() => _selectedType = t),
            onDone: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.canManage) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openRecordForm,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Record Member Contribution'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Monthly Summary',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _SummaryCard(title: 'Total Income', amount: widget.grandTotal, icon: Icons.account_balance_wallet, color: AppColors.primary),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SummaryCard(title: 'Tithe', amount: widget.titheTotal, icon: Icons.favorite, color: Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(title: 'Offering', amount: widget.offeringTotal, icon: Icons.volunteer_activism, color: Colors.orange)),
          ]),
          const SizedBox(height: 12),
          _SummaryCard(title: 'Donation', amount: widget.donationTotal, icon: Icons.card_giftcard, color: Colors.purple),
          const SizedBox(height: 20),
          Text('Member Contributions This Month',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          if (widget.titheContributions.isNotEmpty)
            _ContributionSummaryRow(label: 'Tithe', count: widget.titheContributions.length, total: widget.titheContributions.fold(0.0, (s, c) => s + c.amount), color: Colors.red, icon: Icons.favorite),
          if (widget.offeringContributions.isNotEmpty)
            _ContributionSummaryRow(label: 'Offering', count: widget.offeringContributions.length, total: widget.offeringContributions.fold(0.0, (s, c) => s + c.amount), color: Colors.orange, icon: Icons.volunteer_activism),
          if (widget.donationContributions.isNotEmpty)
            _ContributionSummaryRow(label: 'Donation', count: widget.donationContributions.length, total: widget.donationContributions.fold(0.0, (s, c) => s + c.amount), color: Colors.purple, icon: Icons.card_giftcard),
          if (widget.contributionCount == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: EmeraldTheme.cardDecoration,
              child: Row(children: [
                Icon(Icons.info_outline, color: AppColors.emeraldTextMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('No member contributions recorded this month', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.emeraldTextSecondary))),
              ]),
            ),
          const SizedBox(height: 20),
          Text('Recent Member Contributions',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
          const SizedBox(height: 8),
          ...(() {
            final all = [...widget.titheContributions, ...widget.offeringContributions, ...widget.donationContributions];
            all.sort((a, b) => b.date.compareTo(a.date));
            return all.take(10).map((c) => _MemberContributionTile(c: c, canManage: widget.canManage));
          })(),
        ],
      ),
    );
  }
}

class _ContributionSummaryRow extends StatelessWidget {
  final String label;
  final int count;
  final double total;
  final Color color;
  final IconData icon;

  const _ContributionSummaryRow({
    required this.label, required this.count, required this.total,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: EmeraldTheme.cardDecoration,
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
          Text('$count contribution(s)', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.emeraldTextSecondary)),
        ])),
        Text('GH₵ ${_fmt.format(total)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: EmeraldTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            _monthFmt.format(month),
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EmeraldTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 10),
          Text('GH₵ ${_fmt.format(amount)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _CategoryTab extends ConsumerStatefulWidget {
  final String type;
  final List<FinanceTransaction> transactions;
  final List<MemberContribution> contributions;
  final bool canManage;
  final List<Member> members;
  final String churchId;
  final String branchId;
  final String recordedById;

  const _CategoryTab({
    required this.type,
    required this.transactions,
    required this.contributions,
    required this.canManage,
    required this.members,
    required this.churchId,
    required this.branchId,
    required this.recordedById,
  });

  @override
  ConsumerState<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends ConsumerState<_CategoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _openChurchTotalForm() {
    final label = _typeLabel(widget.type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Text('Record Church $label Total',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
              const SizedBox(height: 4),
              Text('For bulk/group contributions not tied to individual members',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.emeraldTextSecondary)),
              const SizedBox(height: 16),
              _ChurchTotalForm(
                type: widget.type,
                churchId: widget.churchId,
                branchId: widget.branchId,
                recordedById: widget.recordedById,
                onDone: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecordForm() {
    final label = _typeLabel(widget.type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Text('Record $label from Member',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
              const SizedBox(height: 16),
              _RecordContributionForm(
                type: widget.type,
                members: widget.members,
                churchId: widget.churchId,
                branchId: widget.branchId,
                recordedById: widget.recordedById,
                onDone: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _typeLabel(widget.type);
    final txTotal = widget.transactions.fold(0.0, (s, t) => s + t.amount);
    final contribTotal = widget.contributions.fold(0.0, (s, c) => s + c.amount);
    final color = widget.type == ContributionType.tithe
        ? Colors.red
        : widget.type == ContributionType.offering
            ? Colors.orange
            : Colors.purple;
    final icon = widget.type == ContributionType.tithe
        ? Icons.favorite
        : widget.type == ContributionType.offering
            ? Icons.volunteer_activism
            : Icons.card_giftcard;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: EmeraldTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text('$label Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatBlock(label: 'Finance Records', value: 'GH₵ ${_fmt.format(txTotal)}', sub: '${widget.transactions.length} record(s)', color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _StatBlock(label: 'Member Contributions', value: 'GH₵ ${_fmt.format(contribTotal)}', sub: '${widget.contributions.length} member(s)', color: color)),
              ]),
            ],
          ),
        ),
        if (widget.canManage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openRecordForm,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: Text('From Member', style: GoogleFonts.poppins(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openChurchTotalForm,
                    icon: const Icon(Icons.groups, size: 18),
                    label: Text('Church Total', style: GoogleFonts.poppins(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _subTabController,
          indicatorColor: AppColors.goldWarm,
          labelColor: AppColors.emeraldTextPrimary,
          unselectedLabelColor: AppColors.emeraldTextSecondary,
          tabs: const [
            Tab(text: 'Member Contributions'),
            Tab(text: 'Finance Records'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _MemberContributionList(contributions: widget.contributions, canManage: widget.canManage),
              _TransactionList(transactions: widget.transactions, label: label, canManage: widget.canManage),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatBlock({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.emeraldTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.emeraldTextMuted)),
      ]),
    );
  }
}

class _MemberContributionList extends StatelessWidget {
  final List<MemberContribution> contributions;
  final bool canManage;

  const _MemberContributionList({required this.contributions, required this.canManage});

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: AppColors.emeraldTextMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No member contributions this month', style: GoogleFonts.poppins(color: AppColors.emeraldTextSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        return _MemberContributionTile(c: contributions[index], canManage: canManage);
      },
    );
  }
}

class _MemberContributionTile extends ConsumerWidget {
  final MemberContribution c;
  final bool canManage;

  const _MemberContributionTile({required this.c, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = c.type == ContributionType.tithe
        ? Colors.red
        : c.type == ContributionType.offering
            ? Colors.orange
            : Colors.purple;
    final typeIcon = c.type == ContributionType.tithe
        ? Icons.favorite
        : c.type == ContributionType.offering
            ? Icons.volunteer_activism
            : Icons.card_giftcard;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.memberName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
                const SizedBox(height: 2),
                Text(_typeLabel(c.type), style: GoogleFonts.poppins(fontSize: 11, color: typeColor, fontWeight: FontWeight.w500)),
                if (c.description.isNotEmpty)
                  Text(c.description, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.emeraldTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_dateFmt.format(c.date), style: GoogleFonts.poppins(fontSize: 10, color: AppColors.emeraldTextMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('GH₵ ${_fmt.format(c.amount)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: typeColor)),
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete contribution?'),
                        content: Text('Remove ${c.memberName}\'s ${_typeLabel(c.type)} contribution?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(contributionProvider.notifier).delete(c.id);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordContributionForm extends ConsumerStatefulWidget {
  final String type;
  final List<Member> members;
  final String churchId;
  final String branchId;
  final String recordedById;
  final ValueChanged<String>? onTypeChanged;
  final VoidCallback onDone;

  const _RecordContributionForm({
    required this.type,
    required this.members,
    required this.churchId,
    required this.branchId,
    required this.recordedById,
    this.onTypeChanged,
    required this.onDone,
  });

  @override
  ConsumerState<_RecordContributionForm> createState() => _RecordContributionFormState();
}

class _RecordContributionFormState extends ConsumerState<_RecordContributionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedMemberId;
  String _selectedType = ContributionType.tithe;
  DateTime? _selectedMonth;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type;
  }

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
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member'), backgroundColor: Colors.orange),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      final member = widget.members.where((m) => m.id == _selectedMemberId).firstOrNull;
      final memberName = member?.name ?? 'Unknown Member';

      final c = MemberContribution(
        id: const Uuid().v4(),
        churchId: widget.churchId,
        branchId: widget.branchId,
        memberId: _selectedMemberId!,
        memberName: memberName,
        type: _selectedType,
        amount: amount,
        description: _descCtrl.text.trim(),
        contributionMonth: _monthKey,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await ref.read(contributionProvider.notifier).add(c);

      final financeCategory = _financeCategoryFor(_selectedType);
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
              : '${_typeLabel(_selectedType)} from ${c.memberName}',
          date: c.date,
          recordedById: widget.recordedById,
          createdAt: c.createdAt,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_typeLabel(_selectedType)} recorded for $memberName'), backgroundColor: Colors.green),
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
            Text('Record Member Contribution',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
            const SizedBox(height: 12),

            if (widget.onTypeChanged != null) ...[
              Text('Contribution Type',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.emeraldTextSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem(value: ContributionType.tithe, child: Row(children: [Icon(Icons.favorite, size: 16, color: Colors.red), SizedBox(width: 8), Text('Tithe')])),
                  DropdownMenuItem(value: ContributionType.offering, child: Row(children: [Icon(Icons.volunteer_activism, size: 16, color: Colors.orange), SizedBox(width: 8), Text('Offering')])),
                  DropdownMenuItem(value: ContributionType.donation, child: Row(children: [Icon(Icons.card_giftcard, size: 16, color: Colors.purple), SizedBox(width: 8), Text('Donation')])),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedType = v);
                    widget.onTypeChanged!(v);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            DropdownButtonFormField<String>(
              initialValue: _selectedMemberId,
              decoration: InputDecoration(
                labelText: 'Select Member',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
              ),
              items: widget.members.map((m) => DropdownMenuItem(
                value: m.id,
                child: Text(m.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedMemberId = v),
              validator: (v) => v == null || v.isEmpty ? 'Select a member' : null,
            ),
            const SizedBox(height: 10),

            if (_selectedType == ContributionType.tithe) ...[
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Record Contribution'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final String label;
  final bool canManage;

  const _TransactionList({
    required this.transactions,
    required this.label,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.emeraldTextMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No $label entries for this month', style: GoogleFonts.poppins(color: AppColors.emeraldTextSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return _TransactionTile(t: t, canManage: canManage, label: label);
      },
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final FinanceTransaction t;
  final bool canManage;
  final String label;

  const _TransactionTile({
    required this.t,
    required this.canManage,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: EmeraldTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_dateFmt.format(t.date), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('GH₵ ${_fmt.format(t.amount)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/finance/edit/${t.id}');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete entry?'),
                          content: Text('Remove this $label record?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) await ref.read(financeProvider.notifier).delete(t.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChurchTotalForm extends ConsumerStatefulWidget {
  final String type;
  final String churchId;
  final String branchId;
  final String recordedById;
  final VoidCallback onDone;

  const _ChurchTotalForm({
    required this.type,
    required this.churchId,
    required this.branchId,
    required this.recordedById,
    required this.onDone,
  });

  @override
  ConsumerState<_ChurchTotalForm> createState() => _ChurchTotalFormState();
}

class _ChurchTotalFormState extends ConsumerState<_ChurchTotalForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      final financeCategory = _financeCategoryFor(widget.type);
      if (financeCategory != null) {
        final label = _typeLabel(widget.type);
        final source = _sourceCtrl.text.trim();
        final desc = _descCtrl.text.trim();
        final description = desc.isNotEmpty
            ? desc
            : source.isNotEmpty
                ? 'Church $label - $source'
                : 'Church $label total';

        await ref.read(financeProvider.notifier).add(FinanceTransaction(
          id: const Uuid().v4(),
          churchId: widget.churchId,
          branchId: widget.branchId,
          type: TransactionType.income,
          category: financeCategory,
          amount: amount,
          description: description,
          date: DateTime.now(),
          recordedById: widget.recordedById,
          createdAt: DateTime.now(),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Church ${_typeLabel(widget.type)} total recorded'),
            backgroundColor: Colors.green,
          ),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Total Amount (GH₵)',
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
            controller: _sourceCtrl,
            decoration: InputDecoration(
              labelText: 'Source / Group (optional)',
              hintText: 'e.g. Sunday Service, Youth Group',
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: AppColors.emeraldTextSecondary),
            ),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Church Total'),
            ),
          ),
        ],
      ),
    );
  }
}
