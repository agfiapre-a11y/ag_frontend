import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/welfare_finance.dart';
import '../../providers/data_provider.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class WelfareContributionsScreen extends ConsumerStatefulWidget {
  const WelfareContributionsScreen({super.key});

  @override
  ConsumerState<WelfareContributionsScreen> createState() =>
      _WelfareContributionsScreenState();
}

class _WelfareContributionsScreenState
    extends ConsumerState<WelfareContributionsScreen> {
  String? _selectedMemberId;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(welfareFinanceProvider);
    final members = ref.watch(memberProvider);
    final contributions =
        txns.where((t) => t.isContribution).toList();

    // Filter by member if selected
    var memberContributions = contributions;
    if (_selectedMemberId != null) {
      memberContributions =
          memberContributions.where((t) => t.memberId == _selectedMemberId).toList();
    }

    // Build monthly breakdown
    final monthlyData = <int, double>{};
    for (int m = 1; m <= 12; m++) {
      final monthTotal = memberContributions
          .where((t) => t.date.year == _selectedYear && t.date.month == m)
          .fold<double>(0, (s, t) => s + t.amount);
      monthlyData[m] = monthTotal;
    }

    final yearTotal = monthlyData.values.fold<double>(0, (s, v) => s + v);
    final avgMonthly = yearTotal / 12;

    // Member summary list
    final memberSummaries = <MapEntry<String, double>>[];
    for (final m in members) {
      final total = contributions
          .where((t) =>
              t.memberId == m.id && t.date.year == _selectedYear)
          .fold<double>(0, (s, t) => s + t.amount);
      if (total > 0) memberSummaries.add(MapEntry(m.name, total));
    }
    memberSummaries.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Contributions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Member',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Members')),
                      ...members.map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedMemberId = v),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      for (int y = DateTime.now().year;
                          y >= 2020;
                          y--)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Year summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.emeraldDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.emeraldDeep.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBlock(
                      label: 'Total ($_selectedYear)',
                      value: _currencyFmt.format(yearTotal)),
                  _StatBlock(
                      label: 'Avg/Month',
                      value: _currencyFmt.format(avgMonthly)),
                  _StatBlock(
                      label: 'Contributions',
                      value: '${memberContributions.length}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monthly bar chart
            Text('Monthly Breakdown',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...monthlyData.entries.map((e) {
              final maxVal = monthlyData.values.fold<double>(0, (s, v) => v > s ? v : s);
              final pct = maxVal > 0 ? e.value / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60,
                        child: Text(DateFormat('MMM').format(DateTime(2024, e.key)),
                            style: GoogleFonts.poppins(fontSize: 13))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.02, 1.0),
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: e.value > 0
                                    ? AppColors.emeraldDeep
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 4,
                            child: Text(
                              _currencyFmt.format(e.value),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: e.value > 0
                                      ? Colors.white
                                      : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Member contributions ranking
            if (_selectedMemberId == null) ...[
              Text('Member Contributions Ranking',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (memberSummaries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No contributions in $_selectedYear',
                        style: GoogleFonts.poppins(color: Colors.grey)),
                  ),
                )
              else
                ...memberSummaries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ms = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: i == 0
                            ? Colors.amber
                            : i == 1
                                ? Colors.grey[300]
                                : i == 2
                                    ? Colors.brown[300]
                                    : AppColors.emeraldDeep.withValues(alpha: 0.1),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: i < 3 ? Colors.white : AppColors.emeraldDeep)),
                      ),
                      title: Text(ms.key,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      trailing: Text(_currencyFmt.format(ms.value),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ),
                  );
                }),
            ],

            // Individual member detail
            if (_selectedMemberId != null) ...[
              Text('Contribution History',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (memberContributions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No contributions in $_selectedYear',
                        style: GoogleFonts.poppins(color: Colors.grey)),
                  ),
                )
              else
                ...memberContributions.map((t) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: const Icon(Icons.savings, color: Colors.green),
                        title: Text(_currencyFmt.format(t.amount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${DateFormat('MMM d, y').format(t.date)} · ${WelfarePaymentMethod.label(t.paymentMethod)}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Text(t.category,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[500])),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
