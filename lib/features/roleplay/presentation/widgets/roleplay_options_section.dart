import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// The "CHOOSE YOUR RESPONSE" section shown while a quest is unanswered.
///
/// Each option is wrapped in [MergeSemantics] so the index badge and the
/// option text are read as a single label by screen readers.
class RoleplayOptionsSection extends StatelessWidget {
  const RoleplayOptionsSection({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.primaryColor,
    required this.isDark,
    required this.onOptionSelected,
  });

  final List<String> options;
  final int correctIndex;
  final Color primaryColor;
  final bool isDark;

  /// Called with (tappedIndex, correctIndex, optionText).
  final void Function(int index, int correctIndex, String text)
  onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            'CHOOSE YOUR RESPONSE',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ...List.generate(options.length, (index) {
          final text = options[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _OptionButton(
              key: ValueKey('option_$index'),
              index: index,
              text: text,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: () => onOptionSelected(index, correctIndex, text),
            ),
          );
        }),
      ],
    );
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.index,
    required this.text,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final String text;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: 'Option ${index + 1}: $text',
        hint: 'Double tap to select',
        child: ScaleButton(
          onTap: onTap,
          child: GlassTile(
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(24.r),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderColor: primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _IndexBadge(index: index, primaryColor: primaryColor),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.primaryColor});

  final int index;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
