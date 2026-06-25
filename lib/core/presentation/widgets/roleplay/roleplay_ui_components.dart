import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CharacterAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool isUser;
  final bool isDark;
  final bool isMidnight;
  final String? emotion;

  const CharacterAvatar({
    super.key,
    required this.name,
    required this.color,
    this.isUser = false,
    this.isDark = true,
    this.isMidnight = false,
    this.emotion,
  });

  /// BUG FIX: `name[0]` indexes the first UTF-16 *code unit*, not the
  /// first character. For any name whose first character lies outside the
  /// Basic Multilingual Plane (some emoji, some rarer scripts), that splits
  /// a surrogate pair in half and renders a broken glyph. Reading the
  /// first *rune* (full Unicode code point) via `String.runes` and
  /// rebuilding a String from it is safe for any script without requiring
  /// an extra package dependency.
  String _firstCharacter(String value) {
    if (value.isEmpty) return '?';
    final firstRune = value.runes.first;
    return String.fromCharCode(firstRune).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _firstCharacter(name);

    final aiGradient = isMidnight
        ? [const Color(0xFF000000), const Color(0xFF0F172A)]
        : (isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, Colors.white.withValues(alpha: 0.9)]);

    return Semantics(
      label: emotion != null
          ? context.tr(
              'roleplay.speaker_with_emotion',
              args: [name, emotion!],
              fallback: '$name, feeling $emotion',
            )
          : name,
      image: true,
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUser
                      ? [color.withValues(alpha: 0.8), color]
                      : aiGradient,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.4)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : color.withValues(alpha: 0.1)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isUser
                        ? Colors.white
                        : (isDark ? color : color.withValues(alpha: 0.9)),
                  ),
                ),
              ),
            ),
            if (emotion != null && !isUser)
              PositionedDirectional(
                bottom: -2.r,
                end: -2.r,
                child: EmotionIcon(emotion: emotion!, size: 20.r),
              ),
          ],
        ),
      ),
    );
  }
}

class EmotionIcon extends StatelessWidget {
  final String emotion;
  final double size;

  const EmotionIcon({super.key, required this.emotion, required this.size});

  @override
  Widget build(BuildContext context) {
    String emojiString = '🙂';
    switch (emotion.toLowerCase()) {
      case 'happy':
        emojiString = '🙂';
        break;
      case 'worried':
        emojiString = '😟';
        break;
      case 'angry':
        emojiString = '😠';
        break;
      case 'thinking':
        emojiString = '🤔';
        break;
      case 'surprised':
        emojiString = '😮';
        break;
      default:
        emojiString = '🙂';
    }

    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(emojiString, style: TextStyle(fontSize: size)),
    );
  }
}

class RoleplayStatCard extends StatelessWidget {
  final String label;
  final IconData iconData;
  final Color baseColor;

  const RoleplayStatCard({
    super.key,
    required this.label,
    required this.iconData,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: isDark
                ? baseColor
                : Color.lerp(baseColor, Colors.black, 0.4),
            size: 24.r,
          ),
          SizedBox(width: 8.w),
          // FIX: no Flexible/maxLines previously — a longer translated
          // label (this sits in an Expanded half-width slot when used
          // side-by-side in ConversationEndScreen) could overflow on
          // narrow phones. Caps to one line with ellipsis instead.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationEndScreen extends StatelessWidget {
  final int earnedXp;
  final int earnedCoins;
  final double scorePercent;
  final VoidCallback onNextPressed;
  final Color primaryColor;

  const ConversationEndScreen({
    super.key,
    required this.earnedXp,
    required this.earnedCoins,
    required this.scorePercent,
    required this.onNextPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: const [
                  FadeEffect(),
                  SlideEffect(begin: Offset(0, 0.2), end: Offset.zero),
                ],
                child: Text(
                  context.tr('games.conversation_complete'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              RoleplayStatCard(
                label: context.tr(
                  'games.score',
                  args: ["${(scorePercent * 100).toInt()}%"],
                ),
                iconData: Icons.star_rounded,
                baseColor: Colors.amber,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: RoleplayStatCard(
                      label: context.tr('games.xp_earned', args: ["$earnedXp"]),
                      iconData: Icons.bolt_rounded,
                      baseColor: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: RoleplayStatCard(
                      label: context.tr(
                        'games.coins_earned',
                        args: ["$earnedCoins"],
                      ),
                      iconData: Icons.monetization_on_rounded,
                      baseColor: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48.h),
              Animate(
                effects: [
                  FadeEffect(delay: 600.ms),
                  ScaleEffect(delay: 600.ms, begin: const Offset(0.8, 0.8)),
                ],
                child: Semantics(
                  button: true,
                  label: context.tr('games.next_roleplay'),
                  child: GestureDetector(
                    onTap: onNextPressed,
                    child: ExcludeSemantics(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            context.tr('games.next_roleplay'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  final Color color;
  const TypingIndicator({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('roleplay.typing_indicator', fallback: 'Typing…'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                    width: 6.r,
                    height: 6.r,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 600.ms,
                    delay: (index * 150).ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: 600.ms,
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                  );
            }),
          ),
        ),
      ),
    );
  }
}

class SceneBackdrop extends StatelessWidget {
  final String scene;
  final Color color;

  const SceneBackdrop({super.key, required this.scene, required this.color});

  IconData _getIcon() {
    final s = scene.toLowerCase();
    if (s.contains('meeting') ||
        s.contains('professional') ||
        s.contains('business')) {
      return Icons.work_rounded;
    }
    if (s.contains('medical') || s.contains('doctor') || s.contains('health')) {
      return Icons.medical_services_rounded;
    }
    if (s.contains('customer') || s.contains('shop') || s.contains('store')) {
      return Icons.shopping_bag_rounded;
    }
    if (s.contains('social') || s.contains('dinner') || s.contains('friend')) {
      return Icons.celebration_rounded;
    }
    if (s.contains('technical') ||
        s.contains('support') ||
        s.contains('tech')) {
      return Icons.terminal_rounded;
    }
    if (s.contains('travel') || s.contains('airport') || s.contains('flight')) {
      return Icons.flight_takeoff_rounded;
    }
    if (s.contains('emergency') || s.contains('accident')) {
      return Icons.emergency_rounded;
    }
    if (s.contains('interview')) {
      return Icons.badge_rounded;
    }
    return Icons.forum_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 150.h,
      end: -50.w,
      child: RepaintBoundary(
        child: Icon(
          _getIcon(),
          size: 300.r,
          color: color.withValues(alpha: 0.05),
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class HeartDisplay extends StatelessWidget {
  final int count;
  final int maxHearts;

  const HeartDisplay({super.key, required this.count, this.maxHearts = 3});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'roleplay.hearts_remaining',
        args: [count.toString(), maxHearts.toString()],
        fallback: '$count of $maxHearts lives remaining',
      ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxHearts, (index) {
            final isFilled = index < count;
            return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    isFilled
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFilled ? Colors.redAccent : Colors.white24,
                    size: 20.r,
                  ),
                )
                .animate(target: isFilled ? 1 : 0)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                );
          }),
        ),
      ),
    );
  }
}

class HintButton extends StatelessWidget {
  final bool isUsed;
  final VoidCallback onTap;
  final Color color;

  const HintButton({
    super.key,
    required this.isUsed,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isUsed,
      label: isUsed
          ? context.tr('roleplay.hint_used', fallback: 'Hint already used')
          : context.tr('games.hint', fallback: 'Use hint'),
      child: GestureDetector(
        // BUG FIX: `onTap` was always wired regardless of `isUsed`, so the
        // button stayed visually disabled (greyed out, no shimmer) but
        // remained fully tappable — a tap on an "already used" hint would
        // still invoke the same callback as a fresh hint request. The
        // visual disabled state now matches the actual tap behavior.
        onTap: isUsed ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: Container(
            // Invisible floor guaranteeing the 48dp accessible touch
            // target; the visible badge below keeps its original size.
            constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child:
                  Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? Colors.white10
                              : color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUsed
                                ? Colors.white24
                                : color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: isUsed ? Colors.white24 : Colors.amber,
                          size: 22.r,
                        ),
                      )
                      .animate(target: isUsed ? 0 : 1)
                      .shimmer(
                        duration: 2.seconds,
                        color: Colors.amber.withValues(alpha: 0.2),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
