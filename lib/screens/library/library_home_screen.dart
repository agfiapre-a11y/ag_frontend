import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/responsive_scaffold.dart';

/// Library hub — available to every authenticated user regardless of role.
/// Links out to Digital Books, Recorded Sermons, Daily Devotion & Prayer
/// Guide, and Bible Study.
class LibraryHomeScreen extends ConsumerWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Grow in faith through free resources',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldTextPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Books, sermons, devotions, and Bible studies for everyone.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.emeraldTextSecondary),
          ),
          const SizedBox(height: 20),
          _LibrarySectionCard(
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Digital Books',
            subtitle:
                'Free Christian classics, devotionals & Pentecostal faith resources',
            onTap: () => context.push('/library/books'),
          ),
          const SizedBox(height: 12),
          _LibrarySectionCard(
            icon: Icons.video_library_outlined,
            iconColor: AppColors.primary,
            title: 'Recorded Sermons',
            subtitle: 'Listen to and watch past sermons from your church',
            onTap: () => context.push('/sermons'),
          ),
          const SizedBox(height: 12),
          _LibrarySectionCard(
            icon: Icons.self_improvement_outlined,
            iconColor: const Color(0xFFD97706),
            title: 'Daily Devotion & Prayer Guide',
            subtitle: 'Daily scripture, devotionals, and prayer points',
            onTap: () => context.push('/library/devotion'),
          ),
          const SizedBox(height: 12),
          _LibrarySectionCard(
            icon: Icons.import_contacts_outlined,
            iconColor: const Color(0xFF0891B2),
            title: 'Bible Study',
            subtitle: 'Guided studies and discussion questions',
            onTap: () => context.push('/library/bible-study'),
          ),
          const SizedBox(height: 12),
          _LibrarySectionCard(
            icon: Icons.church_outlined,
            iconColor: const Color(0xFFDC2626),
            title: 'Sunday School',
            subtitle:
                'Books mapped to a yearly Sunday timeline with chapter discussions',
            onTap: () => context.push('/library/sunday-school'),
          ),
        ],
      ),
    );
  }
}

class _LibrarySectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LibrarySectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.emeraldCardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.emeraldTextSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
