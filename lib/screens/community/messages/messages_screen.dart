import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/app_user.dart';
import '../../../models/conversation.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../widgets/responsive_scaffold.dart';

/// Chat list — shows all 1:1 / group conversations for the current user.
/// Includes a "New chat" button that lets the user pick another member
/// of their church to start a conversation with.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh conversations on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user!;
    final conversations = ref.watch(conversationProvider);

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChatDialog(context, ref, user.id, user.name),
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No conversations yet',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "New Chat" to message someone in your church.',
                    style: GoogleFonts.poppins(
                        color: AppColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final convo = conversations[i];
                final unread = _unreadCount(convo, user.id);
                return _ConversationTile(
                  conversation: convo,
                  currentUserId: user.id,
                  unreadCount: unread,
                  onTap: () {
                    context.push('/community/messages/${convo.id}');
                  },
                );
              },
            ),
    );
  }

  int _unreadCount(Conversation convo, String userId) {
    final messages = LocalDb.getMessagesForConversation(convo.id);
    return messages
        .where((m) => m.senderId != userId && !m.isRead)
        .length;
  }

  Future<void> _showNewChatDialog(
      BuildContext context, WidgetRef ref, String currentUserId, String currentUserName) async {
    final user = ref.read(appStateProvider).user!;
    // Pull all users in this church
    final users = LocalDb.getAllUsers()
        .where((u) => u.churchId == user.churchId && u.id != currentUserId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (users.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other members to chat with yet.')),
        );
      }
      return;
    }

    final selected = await showDialog<AppUser>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start a chat with…'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(u.name[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                title: Text(u.name),
                subtitle: Text(AppRoles.label(u.role),
                    style: GoogleFonts.poppins(fontSize: 11)),
                onTap: () => Navigator.pop(context, u),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );

    if (selected == null) return;
    final convo = await ref.read(conversationProvider.notifier).openDirectMessage(
          otherUserId: selected.id,
          otherUserName: selected.name,
          currentUserName: currentUserName,
        );
    if (context.mounted) context.push('/community/messages/${convo.id}');
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.otherDisplayName(currentUserId);
    final displayName = otherName.isNotEmpty ? otherName : 'Conversation';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
      title: Row(children: [
        Expanded(
          child: Text(displayName,
              style: GoogleFonts.poppins(
                  fontWeight: unreadCount > 0
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 14)),
        ),
        if (conversation.lastMessageAt != null)
          Text(
            _formatTime(conversation.lastMessageAt!),
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.emeraldTextMuted),
          ),
      ]),
      subtitle: Text(
        conversation.lastMessageText.isNotEmpty
            ? conversation.lastMessageText
            : 'Tap to start chatting',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
            fontSize: 12,
            color: unreadCount > 0
                ? AppColors.emeraldTextPrimary
                : AppColors.emeraldTextSecondary,
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal),
      ),
      trailing: unreadCount > 0
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final local = t.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('h:mm a').format(local);
    }
    return DateFormat('MMM d').format(local);
  }
}
