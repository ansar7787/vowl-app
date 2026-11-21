import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_cluster_banner.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_tile.dart';

/// Interactive matrix grid displaying fused banners, remaining word tiles,
/// one-away hints, and bottom-anchored action controls with balanced vertical space.
class TopicMatrixGrid extends StatelessWidget {
  final TopicVocabController controller;
  final Color accentColor;
  final VoidCallback onFuse;
  final bool isAnswered;
  final bool enableTtsOnTap;
  final String? instruction;
  final String? topicEmoji;
  final void Function(String word)? onTileLongPress;

  const TopicMatrixGrid({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onFuse,
    this.isAnswered = false,
    this.enableTtsOnTap = true,
    this.instruction,
    this.topicEmoji,
    this.onTileLongPress,
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

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topical instruction banner at top of game board
                _buildTopicalInstructionBanner(context, isDark),
                SizedBox(height: 12.h),

                // Fused Clusters
                if (fused.isNotEmpty) ...[
                  ...fused.map(
                    (c) => TopicClusterBanner(
                      categoryName: c.categoryName,
                      emoji: c.emoji,
                      words: c.words,
                      explanation: c.explanation,
                      collocations: c.collocations,
                      accentColor: accentColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],

                // One-away hint banner
                if (controller.isOneAway) ...[
                  _buildOneAwayBanner(context),
                  SizedBox(height: 10.h),
                ],

                // Word Matrix Grid
                if (remaining.isNotEmpty) ...[
                  ShakeableWrapper(
                    shakeCount: controller.failedAttempts,
                    child: _buildWordMatrix(context, remaining, selected),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Unified action controls directly paired with the word matrix
                if (!isAnswered && remaining.isNotEmpty)
                  _buildControlsRow(context, isDark, selected, canFuse),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordMatrix(
    BuildContext context,
    List<String> remaining,
    Set<String> selected,
  ) {
    final crossAxisCount =
        (remaining.length == 3 || remaining.length >= 5) ? 3 : 2;
    final rows = <Widget>[];

    for (var i = 0; i < remaining.length; i += crossAxisCount) {
      final end = math.min(i + crossAxisCount, remaining.length);
      final rowWords = remaining.sublist(i, end);

      final rowChildren = <Widget>[];
      for (var j = 0; j < rowWords.length; j++) {
        if (j > 0) rowChildren.add(SizedBox(width: 10.w));
        final word = rowWords[j];
        final isTileSelected = selected.contains(word);
        final isTileError = controller.isShaking && isTileSelected;

        rowChildren.add(
          Expanded(
            child: SizedBox(
              height: 78.h,
              child: TopicFusionTile(
                word: word,
                isSelected: isTileSelected,
                isError: isTileError,
                accentColor: accentColor,
                onTap: isAnswered
                    ? () {}
                    : () {
                        if (enableTtsOnTap &&
                            di.sl.isRegistered<TtsService>()) {
                          try {
                            final tts = di.sl<TtsService>();
                            tts.stop();
                            tts.speak(word);
                          } catch (_) {}
                        }
                        controller.toggleTile(word);
                      },
                onLongPress: onTileLongPress != null
                    ? () => onTileLongPress!(word)
                    : null,
              ),
            ),
          ),
        );
      }

      final missing = crossAxisCount - rowWords.length;
      for (var k = 0; k < missing; k++) {
        rowChildren.add(SizedBox(width: 10.w));
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }

      if (rows.isNotEmpty) rows.add(SizedBox(height: 10.h));
      rows.add(Row(children: rowChildren));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildTopicalInstructionBanner(BuildContext context, bool isDark) {
    final effectiveInstruction = instruction ??
        context.tr(
          'instructions.topicVocab.matrix_hint',
          fallback: 'Fuse the matching topic clusters before time expires!',
        );
    final emoji = topicEmoji?.trim() ?? '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.6)
            : AppColors.slate100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          if (emoji.isNotEmpty)
            Text(emoji, style: TextStyle(fontSize: 15.sp))
          else
            Icon(
              Icons.hub_outlined,
              size: 15.r,
              color: accentColor,
            ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              effectiveInstruction,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.slate300 : AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneAwayBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.amber500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.amber500.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.amber500,
            size: 15.r,
          ),
          SizedBox(width: 6.w),
          Text(
            context.tr(
              'instructions.topicVocab.one_away',
              fallback: 'Almost there! 2 of 3 words match.',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.amber500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.15, end: 0);
  }

  Widget _buildControlsRow(
    BuildContext context,
    bool isDark,
    Set<String> selected,
    bool canFuse,
  ) {
    return Row(
      children: [
        // Deselect button
        ScaleButton(
          onTap: selected.isEmpty ? null : controller.deselectAll,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.clear_rounded,
                  size: 18.r,
                  color: selected.isEmpty
                      ? (isDark ? AppColors.slate600 : AppColors.slate400)
                      : (isDark ? AppColors.slate200 : AppColors.slate700),
                ),
                if (selected.isNotEmpty) ...[
                  SizedBox(width: 4.w),
                  Text(
                    '${selected.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate200 : AppColors.slate700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),

        // Shuffle button
        ScaleButton(
          onTap: controller.shuffleRemaining,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate200,
              ),
            ),
            child: Icon(
              Icons.shuffle_rounded,
              size: 18.r,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ),
        SizedBox(width: 10.w),

        // Group Action button
        Expanded(
          child: ScaleButton(
            onTap: canFuse ? onFuse : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canFuse
                    ? accentColor
                    : (isDark ? AppColors.slate800 : AppColors.slate200),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: AutoSizeText(
                '${context.tr("instructions.topicVocab.fuse", fallback: "Group Words")} (${selected.length}/${controller.targetClusterSize})',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: canFuse
                      ? Colors.white
                      : (isDark ? AppColors.slate500 : AppColors.slate400),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
