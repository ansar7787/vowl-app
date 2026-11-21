import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_cluster_banner.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_tile.dart';

/// Interactive matrix grid displaying fused banners, remaining word tiles,
/// one-away hints, and action buttons.
class TopicMatrixGrid extends StatelessWidget {
  final TopicVocabController controller;
  final Color accentColor;
  final VoidCallback onFuse;
  final bool isAnswered;

  const TopicMatrixGrid({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onFuse,
    this.isAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final fused = controller.fusedClusters;
        final remaining = controller.remainingTiles;
        final selected = controller.selectedTiles;
        final canFuse =
            selected.length == controller.targetClusterSize && !isAnswered;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fused Clusters
              if (fused.isNotEmpty) ...[
                ...fused.map(
                  (c) => TopicClusterBanner(
                    categoryName: c.categoryName,
                    emoji: c.emoji,
                    words: c.words,
                    explanation: c.explanation,
                    accentColor: accentColor,
                  ),
                ),
                SizedBox(height: 6.h),
              ],

              // One-away hint banner
              if (controller.isOneAway)
                Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.amber500,
                            size: 16.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            context.tr(
                              'instructions.topicVocab.one_away',
                              fallback: 'One away... you are so close!',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber500,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: -0.2, end: 0),

              // Word Matrix Grid
              if (remaining.isNotEmpty) ...[
                ShakeableWrapper(
                  shakeCount: controller.failedAttempts,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: remaining.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: remaining.length > 4 ? 3 : 2,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (context, index) {
                      final word = remaining[index];
                      final isTileSelected = selected.contains(word);
                      return TopicFusionTile(
                        word: word,
                        isSelected: isTileSelected,
                        accentColor: accentColor,
                        onTap: isAnswered
                            ? () {}
                            : () => controller.toggleTile(word),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),

                // Controls row
                if (!isAnswered)
                  Row(
                    children: [
                      // Deselect button
                      ScaleButton(
                        onTap: selected.isEmpty ? null : controller.deselectAll,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.clear_rounded,
                            size: 20.r,
                            color: selected.isEmpty
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Shuffle button
                      ScaleButton(
                        onTap: controller.shuffleRemaining,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.shuffle_rounded,
                            size: 20.r,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),

                      // Fuse Action button
                      Expanded(
                        child: ScaleButton(
                          onTap: canFuse ? onFuse : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: canFuse
                                  ? LinearGradient(
                                      colors: [
                                        accentColor,
                                        accentColor.withValues(alpha: 0.8),
                                      ],
                                    )
                                  : null,
                              color: canFuse
                                  ? null
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: canFuse
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 10.r,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AutoSizeText(
                              '${context.tr("instructions.topicVocab.fuse", fallback: "FUSE CLUSTER")} (${selected.length}/${controller.targetClusterSize})',
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: canFuse
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
