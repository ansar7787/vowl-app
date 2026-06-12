import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chat_message.dart';

/// Renders the conversation history as a scrollable list of chat bubbles.
///
/// - New messages animate in from the side.
/// - The list auto-scrolls to the latest message via [scrollController].
/// - The typing indicator (`...`) is excluded from the accessibility tree
///   since it conveys no semantic information.
/// - Each real bubble is announced as a live region so screen readers
///   notify the user when a new response arrives.
class RoleplayChatMessagesList extends StatelessWidget {
  const RoleplayChatMessagesList({
    super.key,
    required this.messages,
    required this.isProcessing,
    required this.hint,
    required this.primaryColor,
    required this.isDark,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool isProcessing;

  /// Non-null when the player has revealed the hint for the current quest.
  final String? hint;

  final Color primaryColor;
  final bool isDark;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final itemCount =
        messages.length + (isProcessing ? 1 : 0) + (hint != null ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          return _ChatBubble(
            key: ValueKey('bubble_${msg.hashCode}_$index'),
            text: msg.text,
            isUser: msg.isUser,
            color: primaryColor,
            isDark: isDark,
          );
        }
        if (isProcessing && index == messages.length) {
          return _TypingIndicator(isDark: isDark);
        }
        return _HintBubble(hint: hint!, isDark: isDark);
      },
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.color,
    required this.isDark,
  });

  final String text;
  final bool isUser;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Announce new messages as they arrive.
      liveRegion: true,
      label: isUser ? 'You: $text' : 'Character: $text',
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            padding: EdgeInsets.all(14.r),
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            decoration: BoxDecoration(
              color: isUser
                  ? color
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20.r).copyWith(
                bottomLeft: isUser ? Radius.circular(20.r) : Radius.zero,
                bottomRight: isUser ? Radius.zero : Radius.circular(20.r),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.05 : -0.05);
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

/// Decorative "..." bubble indicating the character is composing a response.
/// Excluded from the accessibility tree — screen readers skip it.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(
                20.r,
              ).copyWith(bottomLeft: Radius.zero),
            ),
            child: Text(
              '...',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
    );
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.hint, required this.isDark});

  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hint: $hint',
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            padding: EdgeInsets.all(14.r),
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(
                20.r,
              ).copyWith(bottomLeft: Radius.zero),
            ),
            child: Text(
              'HINT: $hint',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
