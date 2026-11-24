import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Vault Clue Banner for the Prefix & Suffix Practice Phase ("Vault Combination Cracker").
///
/// Displays:
/// - Target Root Word anchor with its base meaning.
/// - Mission prompt and context sentence with an animated `{{gap}}` placeholder.
/// - Vault latch lock status with mechanical horizontal rattle animation on jam.
class PrefixSuffixClueBanner extends StatefulWidget {
  /// The root word being cracked (e.g. "VIEW").
  final String rootWord;

  /// The dictionary meaning of the root word.
  final String rootMeaning;

  /// The contextual sentence containing `{{gap}}` or target usage.
  final String contextSentence;

  /// The currently slotted affix, or null if empty.
  final String? slottedAffix;

  /// Whether the vault lock is currently jammed due to an invalid combination.
  final bool isJammed;

  /// Whether the vault has successfully unlatched.
  final bool isUnlocked;

  const PrefixSuffixClueBanner({
    super.key,
    required this.rootWord,
    required this.rootMeaning,
    required this.contextSentence,
    this.slottedAffix,
    this.isJammed = false,
    this.isUnlocked = false,
  });

  @override
  State<PrefixSuffixClueBanner> createState() => _PrefixSuffixClueBannerState();
}

class _PrefixSuffixClueBannerState extends State<PrefixSuffixClueBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant PrefixSuffixClueBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isJammed && !oldWidget.isJammed) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Widget _buildSentenceWithGap() {
    final rawSentence = widget.contextSentence;
    const gapPlaceholder = '{{gap}}';

    if (!rawSentence.contains(gapPlaceholder)) {
      return Text(
        rawSentence,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15.sp,
          height: 1.45,
          color: AppColors.slate50,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final parts = rawSentence.split(gapPlaceholder);
    final hasSlotted = widget.slottedAffix != null;
    final slotText = widget.slottedAffix ?? ' _ _ _ ';

    Color slotColor;
    if (widget.isUnlocked) {
      slotColor = AppColors.emerald500;
    } else if (widget.isJammed) {
      slotColor = AppColors.red500;
    } else if (hasSlotted) {
      slotColor = AppColors.indigo500;
    } else {
      slotColor = AppColors.slate500;
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15.sp,
          height: 1.45,
          color: AppColors.slate50,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: parts[0]),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: slotColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: slotColor, width: 1.5),
              ),
              child: Text(
                slotText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: slotColor,
                ),
              ),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color statusBg;
    IconData lockIcon;
    String statusLabel;

    if (widget.isUnlocked) {
      borderColor = AppColors.emerald500;
      statusBg = AppColors.emerald500.withValues(alpha: 0.15);
      lockIcon = Icons.lock_open_rounded;
      statusLabel = 'Unlocked!';
    } else if (widget.isJammed) {
      borderColor = AppColors.red500;
      statusBg = AppColors.red500.withValues(alpha: 0.15);
      lockIcon = Icons.lock_clock_rounded;
      statusLabel = 'Not quite — try again';
    } else {
      borderColor = AppColors.slate700;
      statusBg = AppColors.slate800;
      lockIcon = Icons.lock_outline_rounded;
      statusLabel = 'Find the missing affix';
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Header
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Lock Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(lockIcon, size: 14.sp, color: borderColor),
                      SizedBox(width: 4.w),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Root Word Indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Root: ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate400,
                        ),
                      ),
                      Text(
                        widget.rootWord,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.indigo400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Sentence Clue
            _buildSentenceWithGap(),
            SizedBox(height: 8.h),

            // Root Meaning Hint
            if (widget.rootMeaning.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Root meaning: "${widget.rootMeaning}"',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
