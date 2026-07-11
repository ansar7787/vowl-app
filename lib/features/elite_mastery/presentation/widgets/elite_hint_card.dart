import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/hint_utility.dart';
import 'package:vowl/core/utils/locale_service.dart';

class EliteHintCard extends StatelessWidget {
  final String? hintText;
  final bool isVisible;
  final VoidCallback onShowHint;
  final Color primaryColor;

  const EliteHintCard({
    super.key,
    required this.hintText,
    required this.isVisible,
    required this.onShowHint,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isVisible) {
      return Semantics(
        button: true,
        label: context.tr('games.need_a_hint'),
        excludeSemantics: true,
        child: ScaleButton(
          onTap: onShowHint,
          // FIX: at 12.h vertical padding plus icon/text content, this
          // button's natural height runs under the 48dp minimum
          // touch-target recommendation. Constraining the *outer* box to a
          // 48dp floor (and centering the original, visually-unchanged
          // content inside it) grows only the tappable area.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: primaryColor,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      context.tr('games.need_a_hint'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // FIX: Idiom Match's curriculum hint is always an empty string ("")
    // rather than null (verified across all sample batches) — every hint
    // there comes from the ad-earned 50/50 lifeline instead. Checking for a
    // blank string here (not just null) guarantees this card never renders
    // visibly empty text, regardless of what HintUtility.isGenericHint does
    // with an empty string internally. The two fallback messages are kept
    // distinct: "lifeline activated" specifically implies the dynamic
    // 50/50/letter-reveal mechanism fired; the generic fallback is for any
    // other case with no real hint text to show.
    final hasRealHint = hintText != null && hintText!.trim().isNotEmpty;
    final resolvedHint = HintUtility.isGenericHint(hintText)
        ? context.tr('games.lifeline_activated')
        : (hasRealHint ? hintText! : context.tr('games.hint_fallback_default'));

    return Semantics(
      // `liveRegion`: announce automatically the moment the hint reveals,
      // since this card can appear without the player re-focusing it.
      liveRegion: true,
      label: '${context.tr('games.expert_hint')}. $resolvedHint',
      excludeSemantics: true,
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.r),
        color: primaryColor.withValues(alpha: 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: primaryColor, size: 24.r),
                SizedBox(width: 12.w),
                Text(
                  context.tr('games.expert_hint'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              resolvedHint,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
              // FIX: previously capped at `maxLines: 4` with an ellipsis,
              // which could silently truncate the hint — pedagogically the
              // most important text on screen — under long backend hints or
              // large accessibility text-scale factors. The card lives
              // inside the screen's scrollable body (see EliteBaseLayout's
              // SingleChildScrollView), so letting it wrap freely is safe
              // and never causes a RenderFlex overflow.
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
