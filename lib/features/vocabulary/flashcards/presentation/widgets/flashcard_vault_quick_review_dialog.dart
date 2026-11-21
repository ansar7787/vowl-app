import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import '../../data/services/flashcard_vault_service.dart';

/// Interactive modal sheet to actively practice fading words and refresh retention to 100%.
class FlashcardVaultQuickReviewDialog extends StatefulWidget {
  final List<FlashcardVaultEntry> entriesToReview;
  final Future<void> Function(String word, int level, {bool struggled})
  onWordMastered;

  const FlashcardVaultQuickReviewDialog({
    super.key,
    required this.entriesToReview,
    required this.onWordMastered,
  });

  static Future<void> show(
    BuildContext context, {
    required List<FlashcardVaultEntry> entriesToReview,
    required Future<void> Function(String word, int level, {bool struggled})
    onWordMastered,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlashcardVaultQuickReviewDialog(
        entriesToReview: entriesToReview,
        onWordMastered: onWordMastered,
      ),
    );
  }

  @override
  State<FlashcardVaultQuickReviewDialog> createState() =>
      _FlashcardVaultQuickReviewDialogState();
}

class _FlashcardVaultQuickReviewDialogState
    extends State<FlashcardVaultQuickReviewDialog> {
  int _currentIndex = 0;
  bool _isRefreshed = false;
  bool _lastReviewStruggled = false;
  bool _isFinished = false;

  void _speakCurrentWord(String word) {
    if (di.sl.isRegistered<TtsService>()) {
      try {
        di.sl<TtsService>().speak(word);
      } catch (_) {}
    }
  }

  Future<void> _recordReview({required bool struggled}) async {
    final entry = widget.entriesToReview[_currentIndex];
    if (struggled) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _speakCurrentWord(entry.word);

    setState(() {
      _isRefreshed = true;
      _lastReviewStruggled = struggled;
    });
    await widget.onWordMastered(entry.word, entry.level, struggled: struggled);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    if (_currentIndex < widget.entriesToReview.length - 1) {
      setState(() {
        _currentIndex++;
        _isRefreshed = false;
        _lastReviewStruggled = false;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      height: isLandscape ? 0.95.sh : 0.85.sh,
      padding: EdgeInsets.fromLTRB(
        20.w,
        isLandscape ? 6.h : 12.h,
        20.w,
        isLandscape ? 12.h : 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : AppColors.slate300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: isLandscape ? 6.h : 12.h),
            if (_isFinished)
              Expanded(child: _buildCompletionView(isDark))
            else
              Expanded(child: _buildReviewCard(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(bool isDark) {
    final entry = widget.entriesToReview[_currentIndex];
    final total = widget.entriesToReview.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Word ${_currentIndex + 1} of $total',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate50,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: _isRefreshed
                    ? AppColors.emerald500
                    : (isDark ? AppColors.slate700 : AppColors.slate200),
                width: _isRefreshed ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        entry.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ScaleButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _speakCurrentWord(entry.word);
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate700
                              : AppColors.slate200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18.r,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Level ${entry.level} • Practiced ${entry.repetitionCount}x',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isRefreshed
                        ? AppColors.emerald500.withValues(alpha: 0.15)
                        : AppColors.rose500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _isRefreshed
                        ? (_lastReviewStruggled
                              ? '🟡 Hard: Review in 24h (70%)'
                              : '✨ Mastered! Next in 4 Days (100%)')
                        : '⚠️ Retention: ${entry.retentionPercentage}% (Fading)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: _isRefreshed
                          ? (_lastReviewStruggled
                                ? Colors.amber
                                : AppColors.emerald500)
                          : AppColors.rose500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  key: const ValueKey('btn_struggled'),
                  onTap: () => _recordReview(struggled: true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Struggled (24h) 🤔',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ScaleButton(
                  key: const ValueKey('btn_refresh_memory'),
                  onTap: () => _recordReview(struggled: false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.indigo500.withValues(alpha: 0.25),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Remembered! ⚡',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 48.r,
              color: AppColors.emerald500,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Quick Review Complete! 🎉',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Reviewed words have refreshed retention scores.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
          ),
          SizedBox(height: 24.h),
          ScaleButton(
            key: const ValueKey('btn_review_done'),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                'Back to Word Bank',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
