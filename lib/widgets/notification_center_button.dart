import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../models/app_notification.dart';
import '../providers/data_provider.dart';

class NotificationCenterButton extends ConsumerWidget {
  const NotificationCenterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => _openCenter(context, ref),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _openCenter(BuildContext context, WidgetRef ref) {
    // Generate fresh notifications from current data
    generateAutoNotifications(ref);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NotificationCenterSheet(),
    );
  }
}

class _NotificationCenterSheet extends ConsumerWidget {
  const _NotificationCenterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.notifications, size: 22),
                    const SizedBox(width: 8),
                    Text('Notifications',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    if (unread.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${unread.length} new',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ]),
                  if (unread.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No notifications', style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ...unread.map((n) => _NotificationTile(
                              notification: n,
                              isUnread: true,
                              onTap: () => _handleTap(context, ref, n),
                              onDismiss: () => ref.read(notificationProvider.notifier).delete(n.id),
                            )),
                        if (unread.isNotEmpty && read.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                            child: Text('Earlier',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ...read.map((n) => _NotificationTile(
                              notification: n,
                              isUnread: false,
                              onTap: () => _handleTap(context, ref, n),
                              onDismiss: () => ref.read(notificationProvider.notifier).delete(n.id),
                            )),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(notificationProvider.notifier).markRead(n.id);
    if (n.route != null && context.mounted) {
      Navigator.pop(context);
      context.push(n.route!);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isUnread;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.isUnread,
    required this.onTap,
    required this.onDismiss,
  });

  Color _typeColor(String type) {
    switch (type) {
      case AppNotification.typeApproval:
        return Colors.orange;
      case AppNotification.typeEvent:
        return Colors.blue;
      case AppNotification.typeWelfare:
        return Colors.pink;
      case AppNotification.typeFinance:
        return Colors.teal;
      case AppNotification.typeMember:
        return Colors.green;
      case AppNotification.typeAttendance:
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case AppNotification.typeApproval:
        return Icons.approval;
      case AppNotification.typeEvent:
        return Icons.event;
      case AppNotification.typeWelfare:
        return Icons.handshake;
      case AppNotification.typeFinance:
        return Icons.account_balance_wallet;
      case AppNotification.typeMember:
        return Icons.person_add;
      case AppNotification.typeAttendance:
        return Icons.fact_check;
      default:
        return Icons.info;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_typeIcon(notification.type), color: color, size: 20),
        ),
        title: Row(
          children: [
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notification.body, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(_timeAgo(notification.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        trailing: notification.route != null
            ? const Icon(Icons.chevron_right, size: 18, color: Colors.grey)
            : null,
      ),
    );
  }
}
