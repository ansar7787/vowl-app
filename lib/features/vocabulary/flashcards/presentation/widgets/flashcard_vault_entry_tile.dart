import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import '../../data/services/flashcard_vault_service.dart';

/// Single word tile in the Lexicon Memory Vault with retention progress indicator.
class FlashcardVaultEntryTile extends StatelessWidget {
  final FlashcardVaultEntry entry;
  final bool isDark;
  final VoidCallback? onTap;

  const FlashcardVaultEntryTile({
    super.key,
    required this.entry,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = entry.retentionPercentage;
    final cefr = entry.level <= 50
        ? 'B1'
        : (entry.level <= 100
            ? 'B2'
            : (entry.level <= 150 ? 'C1' : 'C2'));
    final healthColor = r >= 80
        ? AppColors.emerald500
        : (r >= 50 ? Colors.amber : AppColors.rose500);
    final healthLabel = r >= 80
        ? 'Strong'
        : (r >= 50 ? 'Fading' : 'Review Now');

    final card = Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: r < 50
              ? AppColors.rose500.withValues(alpha: 0.5)
              : (isDark ? AppColors.slate700 : AppColors.slate200),
          width: r < 50 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Lvl ${entry.level} • $cefr',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (di.sl.isRegistered<TtsService>()) {
                    di.sl<TtsService>().speak(entry.word);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate700 : AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 15.r,
                    color: AppColors.indigo500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: entry.retention,
              minHeight: 5.h,
              backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Practiced ${entry.repetitionCount}x',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '$r% $healthLabel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: healthColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return ScaleButton(onTap: onTap!, child: card);
    }
    return card;
  }
}
