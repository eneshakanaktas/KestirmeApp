import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

/// Chat mesaj balonu widget'ı
/// Kullanıcı ve AI mesajlarını farklı stillerde gösterir
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.support_agent,
                size: 18,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Mesaj balonu
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            code: theme.textTheme.bodySmall?.copyWith(
                              backgroundColor:
                                  colorScheme.surface.withOpacity(0.5),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                // Zaman damgası
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // Kullanıcı Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 18,
                color: colorScheme.onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
