import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';
import '../../widgets/responsive_scaffold.dart';

/// Community hub — the social networking home for every authenticated user.
///
/// Links to the public Feed (posts, photos, videos, status updates) and to
/// private Messages (1:1 chats with other members of your church).
class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final unreadCount = LocalDb.getUnreadMessageCount(
        churchId: user.churchId, userId: user.id);

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Connect, share, and grow together',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldTextPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Share updates, photos, and videos. Chat with members of your church.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.emeraldTextSecondary),
          ),
          const SizedBox(height: 20),
          _CommunitySectionCard(
            icon: Icons.dynamic_feed_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: 'Feed',
            subtitle: 'See posts, photos, and videos from your church family',
            badge: ref.watch(communityPostProvider).length,
            onTap: () => context.push('/community/feed'),
          ),
          const SizedBox(height: 12),
          _CommunitySectionCard(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF10B981),
            title: 'Messages',
            subtitle: 'Private chats with other members',
            badge: unreadCount > 0 ? unreadCount : null,
            onTap: () => context.push('/community/messages'),
          ),
        ],
      ),
    );
  }
}

class _CommunitySectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int? badge;
  final VoidCallback onTap;

  const _CommunitySectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
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
                    Row(children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$badge',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: iconColor),
                          ),
                        ),
                      ],
                    ]),
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
