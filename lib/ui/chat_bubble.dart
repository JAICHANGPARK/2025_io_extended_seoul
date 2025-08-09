// Modern chat bubble widget
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  bool get isUserMessage {
    // Check if this is a user message by examining the message content or role
    // ChatMessage.user() creates user messages, others are typically AI responses
    print(message.role.name);
    return message.role.name == "user";
  }

  String get messageContent {
    // Extract the actual message text from the ChatMessage
    final messageStr = message.parts.first.toJson()['content'].toString();
    final contentParts = <String>[];

    // print('messageContent message: ${message.role.name}');

    // 각 파트 타입별로 콘솔 출력
    for (final part in message.parts) {
      if (part is ToolPart) {
        if (part.kind == ToolPartKind.call) {
          print('🔧 Tool Call: ${part.name}');
          print('   Arguments: ${part.argumentsRaw}');
        } else if (part.kind == ToolPartKind.result) {
          print('📊 Tool Result: ${part.name}');
          print('   Result: ${part.result}');
        }
      } else if (part is DataPart) {
        print('📎 Data Part: ${part.name} (${part.mimeType})');
      } else if (part is LinkPart) {
        print('🔗 Link Part: ${part.url}');
      }
    }

    // Try to extract text from common patterns in the string representation
    // final patterns = [
    //   RegExp(r"text:\s*'([^']*)'"),
    //   RegExp(r"message:\s*'([^']*)'"),
    //   RegExp(r":\s*'([^']*)'"),
    // ];
    //
    // for (final pattern in patterns) {
    //   final match = pattern.firstMatch(messageStr);
    //   if (match != null && match.group(1)!.isNotEmpty) {
    //     return match.group(1)!;
    //   }
    // }
    // Tool result가 있으면 우선적으로 표시

    return messageStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = isUserMessage;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onSecondary,
                size: 20,
              ),
            ),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      messageContent,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    )
                  : MarkdownBody(
                      data: messageContent,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        launchUrl(Uri.parse(href ?? ""));
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        code: TextStyle(
                          backgroundColor: theme.colorScheme.surface,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            // User avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
