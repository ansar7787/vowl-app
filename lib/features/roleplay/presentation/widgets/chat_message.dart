import 'package:flutter/foundation.dart';

/// An immutable, typed representation of a single chat bubble.
///
/// Replaces the previous `Map<String, dynamic>` approach, giving full
/// IDE support, null safety, and refactor safety.
@immutable
class ChatMessage {
  /// Creates a [ChatMessage] instance.
  const ChatMessage({required this.text, required this.isUser});

  /// Creates a message bubble attributed to the player.
  factory ChatMessage.user(String text) =>
      ChatMessage(text: text, isUser: true);

  /// Creates a message bubble attributed to the AI character.
  factory ChatMessage.system(String text) =>
      ChatMessage(text: text, isUser: false);

  /// Text content of the chat message.
  final String text;

  /// Whether this message originated from the user (`true`) or the character (`false`).
  final bool isUser;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isUser == other.isUser;

  @override
  int get hashCode => Object.hash(text, isUser);

  @override
  String toString() => 'ChatMessage(isUser: $isUser, text: $text)';
}
