import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingTargetPanel extends StatelessWidget {
  final String text;
  final String? shadowingFocus;
  final Set<int> matchedIndices;
  final bool isDark;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int attempts;
  final VoidCallback? onListenTap;

  const AccentShadowingTargetPanel({
    super.key,
    required this.text,
    this.shadowingFocus,
    required this.matchedIndices,
    required this.isDark,
    required this.primaryColor,
    required this.isAnswered,
    this.isCorrect,
    required this.attempts,
    this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    final isErrorState = isCorrect == false && attempts > 0;
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(32.r),
      border: (isAnswered || isErrorState)
          ? Border.all(
              color: isCorrect == true ? Colors.greenAccent : Colors.redAccent,
              width: 2,
            )
          : null,
      child: Column(
        children: [
          if (shadowingFocus != null && shadowingFocus!.isNotEmpty) ...[
            Text(
              shadowingFocus!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white70
                    : const Color(0xFF1E293B).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
          ],
          Semantics(
            button: true,
            label: context.tr(
              'games.semantic_listen_example',
              fallback: 'Listen to Example',
            ),
            excludeSemantics: true,
            // FIX: at reference scale (12.r padding + 32.r icon ≈ 56
            // logical px) this already clears the 48dp minimum touch
            // target, but `.r` scales proportionally with screen size —
            // on the smallest realistic phone widths it can shrink below
            // that minimum. `behavior: HitTestBehavior.opaque` combined
            // with a `minWidth`/`minHeight` floor (in true, unscaled
            // logical pixels) guarantees the full 48dp tappable area on
            // every device regardless of ScreenUtil's scale ratio, while
            // the visible circle itself is completely unchanged.
            child: GestureDetector(
              onTap: onListenTap,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: isDark ? primaryColor : const Color(0xFF0F172A),
                      size: 32.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          _buildTargetWords(context, words),
        ],
      ),
    );
  }

  Widget _buildTargetWords(BuildContext context, List<String> words) {
    // FIX: previously each word was its own bare `Text`, so a screen reader
    // would traverse them one at a time with no indication of overall match
    // progress. A single combined Semantics node (mirroring the pattern
    // already used in EliteFeedbackCard) announces the full sentence plus
    // progress in one pass instead.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: context.tr(
        'games.semantic_target_sentence',
        fallback: 'Target Sentence',
        args: [text, matchedIndices.length.toString(), words.length.toString()],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: List.generate(words.length, (index) {
          final isMatched = matchedIndices.contains(index);
          return Text(
                words[index],
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isMatched
                      ? Colors.greenAccent
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  height: 1.4,
                ),
              )
              .animate(target: isMatched ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
              );
        }),
      ),
    );
  }
}
