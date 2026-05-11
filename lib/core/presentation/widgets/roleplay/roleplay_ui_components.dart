import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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


  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final aiGradient = isMidnight
        ? [const Color(0xFF000000), const Color(0xFF0F172A)]
        : (isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [Colors.white, Colors.white.withValues(alpha: 0.9)]);


    return Stack(
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
          Positioned(
            bottom: -2.r,
            right: -2.r,
            child: EmotionIcon(emotion: emotion!, size: 20.r),
          ),
      ],
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
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
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
                  "Conversation Complete 🎉",
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
                label: "Score: ${(scorePercent * 100).toInt()}%",
                iconData: Icons.star_rounded,
                baseColor: Colors.amber,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: RoleplayStatCard(
                      label: "+$earnedXp XP",
                      iconData: Icons.bolt_rounded,
                      baseColor: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: RoleplayStatCard(
                      label: "+$earnedCoins Coins",
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
                child: GestureDetector(
                  onTap: onNextPressed,
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
                        "Next Roleplay",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
    return Row(
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
    return Positioned(
      top: 150.h,
      right: -50.w,
      child: Icon(
        _getIcon(),
        size: 300.r,
        color: color.withValues(alpha: 0.05),
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
    return Row(
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
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isUsed ? Colors.white10 : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUsed ? Colors.white24 : color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: isUsed ? Colors.white24 : Colors.amber,
              size: 22.r,
            ),
          ),
        )
        .animate(target: isUsed ? 0 : 1)
        .shimmer(
          duration: 2.seconds,
          color: Colors.amber.withValues(alpha: 0.2),
        );
  }
}
