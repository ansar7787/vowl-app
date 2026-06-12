import 'package:flutter/foundation.dart';

/// An immutable, typed representation of a single chat bubble.
///
/// Replaces the previous `Map<String, dynamic>` approach, giving full
/// IDE support, null safety, and refactor safety.
@immutable
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  /// Creates a message bubble attributed to the player.
  factory ChatMessage.user(String text) =>
      ChatMessage(text: text, isUser: true);

  /// Creates a message bubble attributed to the AI character.
  factory ChatMessage.system(String text) =>
      ChatMessage(text: text, isUser: false);

  final String text;

  /// `true` → player bubble (right-aligned).
  /// `false` → character bubble (left-aligned).
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
