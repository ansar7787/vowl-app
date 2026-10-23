import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

/// Persona header console widget displaying character avatar, speech bubble, and audio trigger.
class BranchingDialoguePersonaConsole extends StatelessWidget {
  /// Active roleplay quest data.
  final RoleplayQuest quest;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback to play speech audio for the persona dialogue.
  final VoidCallback onListen;

  /// Creates a [BranchingDialoguePersonaConsole] widget.
  const BranchingDialoguePersonaConsole({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.onListen,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget avatarWidget = Container(
      key: const Key('branching_dialogue_persona_avatar'),
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(
        Icons.person_pin_rounded,
        color: color,
        size: 28.r,
      ),
    );

    if (!reduceMotion) {
      avatarWidget = avatarWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 1.seconds,
          );
    }

    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              avatarWidget,
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.roleName?.toUpperCase() ?? "CONVERSATION PARTNER",
                      key: const Key('branching_dialogue_persona_name'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      "ROLEPLAY SCENARIO",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Semantics(
                label: 'Replay dialogue audio',
                button: true,
                excludeSemantics: true,
                child: ScaleButton(
                  key: const Key('branching_dialogue_replay_btn'),
                  onTap: onListen,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 16.r, color: color),
                        SizedBox(width: 4.w),
                        Text(
                          "Replay",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            quest.scene ?? "",
            key: const Key('branching_dialogue_scene_text'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
    }

    return content;
  }
}
