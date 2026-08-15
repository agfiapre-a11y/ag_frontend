import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../widgets/responsive_scaffold.dart';

/// 1:1 / group chat thread. Shows the message history for a conversation
/// and lets the current user send new messages.
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Conversation? _convo;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndMarkRead());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAndMarkRead() {
    final user = ref.read(appStateProvider).user!;
    _convo = LocalDb.getConversationById(widget.conversationId);
    _messages = LocalDb.getMessagesForConversation(widget.conversationId);
    if (mounted) setState(() {});
    // Mark messages from the other user as read
    LocalDb.markConversationRead(
            conversationId: widget.conversationId, userId: user.id)
        .then((_) {
      _messages = LocalDb.getMessagesForConversation(widget.conversationId);
      if (mounted) setState(() {});
      // Refresh the conversation list so the unread badge clears
      ref.read(conversationProvider.notifier).refresh();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(appStateProvider).user!;
    _textController.clear();
    await ref.read(messageForConversationProvider(widget.conversationId).notifier)
        .sendMessage(
      senderId: user.id,
      senderName: user.name,
      text: text,
    );
    _messages = LocalDb.getMessagesForConversation(widget.conversationId);
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user!;
    final otherName = _convo?.otherDisplayName(user.id) ?? 'Chat';

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 16)),
          ),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hello!',
                      style: GoogleFonts.poppins(
                          color: AppColors.emeraldTextMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderId == user.id;
                      return _MessageBubble(message: msg, isMe: isMe);
                    },
                  ),
          ),
          // Composer
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              border: Border(
                  top: BorderSide(color: AppColors.emeraldCardBorder)),
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.ivoryLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(14),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.emeraldCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(message.senderName,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            if (!isMe) const SizedBox(height: 2),
            Text(
              message.text,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.emeraldTextPrimary,
                  height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.createdAt.toLocal()),
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.emeraldTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}
