import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/welfare_case.dart';
import '../../providers/data_provider.dart';

class MyWelfareCases extends ConsumerWidget {
  final AppUser user;
  final List members;
  const MyWelfareCases({super.key, required this.user, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = ref.watch(welfareProvider);
    final m = members
        .where((x) => x.email.toLowerCase() == user.email.toLowerCase())
        .firstOrNull;
    if (m == null) return const SizedBox.shrink();
    final mine = wc
        .where((w) => w.memberId == m.id)
        .toList()
      ..sort((a, b) => b.dateRequested.compareTo(a.dateRequested));
    if (mine.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Column(
        children: mine.take(3).map((w) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(WelfareType.icon(w.type),
                  color: WelfareStatus.color(w.status)),
              title: Text(WelfareType.label(w.type),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${WelfareStatus.label(w.status)} - ${DateFormat('MMM d').format(w.dateRequested)}',
                  style: GoogleFonts.poppins(fontSize: 11)),
              trailing: Chip(
                label: Text(WelfarePriority.label(w.priority)),
                padding: EdgeInsets.zero,
              ),
              onTap: () => context.push('/welfare/detail/${w.id}'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
