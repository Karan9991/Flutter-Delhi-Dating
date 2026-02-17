import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.receiptText,
  });

  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String? receiptText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = DateFormat('h:mm a').format(timestamp);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: Radius.circular(isMe ? 16 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMe
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withValues(alpha: 0.56),
              ),
            ),
            if ((receiptText ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                receiptText!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isMe
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withValues(alpha: 0.56),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
