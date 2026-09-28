import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return const SizedBox.shrink(); // system prompt not shown in UI
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF10A37F) // user – green
              : const Color(0xFF2D2D2D), // assistant – dark gray
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: Colors.greenAccent.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ollama',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.greenAccent.withOpacity(0.8),
                      ),
                    ),
                    if (message.isStreaming) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.greenAccent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (isUser)
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  height: 1.35,
                ),
              )
            else
              MarkdownBody(
                data: message.content.isEmpty && message.isStreaming
                    ? '…'
                    : message.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Color(0xFFE8E8E8),
                    fontSize: 15.5,
                    height: 1.4,
                  ),
                  code: TextStyle(
                    backgroundColor: Colors.black.withOpacity(0.35),
                    color: const Color(0xFF7EE787),
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                selectable: true,
              ),
          ],
        ),
      ),
    );
  }
}
