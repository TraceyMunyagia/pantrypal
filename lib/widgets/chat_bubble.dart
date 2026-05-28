import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'recipe_card.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.onFavorite,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: message.recipe == null ? const EdgeInsets.all(14) : null,
          decoration: BoxDecoration(
            color: isUser ? colorScheme.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: isUser
                ? null
                : Border.all(color: colorScheme.outlineVariant),
          ),
          child: message.recipe == null
              ? Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : colorScheme.onSurface,
                    height: 1.35,
                    fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                  ),
                )
              : RecipeCard(recipe: message.recipe!, onFavorite: onFavorite),
        ),
      ),
    );
  }
}
