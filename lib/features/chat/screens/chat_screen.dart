import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../data/models/message_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller  = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();

    await ref
        .read(chatProvider(widget.roomId).notifier)
        .sendMessage(message);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final userId      = ref.watch(authProvider).user?.id ?? 0;
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.roomId),
    );
    final isSending   = ref.watch(chatProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (e, _) => const Center(
                child: Text(
                  'Failed to load chat',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size:  48,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello!',
                          style:     AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll on new messages
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:    const EdgeInsets.all(16),
                  itemCount:  messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe    = message.userId == userId;

                    // Show date separator if needed
                    final showDate = index == 0 ||
                        !_isSameDay(
                          messages[index - 1].dateTime,
                          message.dateTime,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          _DateSeparator(date: message.dateTime),
                        _MessageBubble(
                          message: message,
                          isMe:    isMe,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left:   12,
              right:  12,
              top:    8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:  _controller,
                    style:       AppTextStyles.body,
                    maxLines:    null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:    'Type a message...',
                      hintStyle:   AppTextStyles.bodySecondary,
                      filled:      true,
                      fillColor:   AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical:   10,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width:  46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:  isSending
                          ? AppColors.textHint
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size:  20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius:          16,
              backgroundColor: AppColors.card,
              child: Text(
                message.name[0].toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical:   10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: AppTextStyles.body.copyWith(
                      color: isMe
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    Formatters.timeAgo(message.dateTime),
                    style: AppTextStyles.caption.copyWith(
                      color:    AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.card)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              Formatters.date(date),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.card)),
        ],
      ),
    );
  }
}