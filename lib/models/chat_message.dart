import 'recipe.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.recipe,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final Recipe? recipe;

  ChatMessage copyWith({Recipe? recipe}) {
    return ChatMessage(
      text: text,
      isUser: isUser,
      createdAt: createdAt,
      recipe: recipe ?? this.recipe,
    );
  }
}
