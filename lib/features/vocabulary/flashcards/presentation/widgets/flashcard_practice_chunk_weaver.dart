import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'flashcard_collocation_snap_card.dart';

/// 2026 Interactive Word Chunk Weaver & Collocation Slotter for Guided Practice.
class FlashcardPracticeChunkWeaver extends StatelessWidget {
  final String sentence;
  final String targetWord;
  final List<String> availableChunks;
  final List<String> placedChunks;
  final ValueNotifier<List<String>>? availableChunksNotifier;
  final ValueNotifier<List<String>>? placedChunksNotifier;
  final bool hasCheckedAssembly;
  final bool isAssemblyCorrect;
  final bool showCollocationStage;
  final String? collocationPrompt;
  final List<String> collocationOptions;
  final int? selectedCollocationIndex;
  final int correctCollocationIndex;
  final bool hasCheckedCollocation;
  final int shakeTrigger;
  final bool isDark;
  final void Function(String chunk) onAddChunk;
  final void Function(int index) onRemoveChunk;
  final VoidCallback onCheckAssembly;
  final void Function(int optionIndex) onSelectCollocation;
  final VoidCallback? onSpeakSentence;
  final VoidCallback? onClearChunks;

  const FlashcardPracticeChunkWeaver({
    super.key,
    required this.sentence,
    required this.targetWord,
    required this.availableChunks,
    required this.placedChunks,
    this.availableChunksNotifier,
    this.placedChunksNotifier,
    required this.hasCheckedAssembly,
    required this.isAssemblyCorrect,
    required this.showCollocationStage,
    this.collocationPrompt,
    this.collocationOptions = const [],
    this.selectedCollocationIndex,
    this.correctCollocationIndex = 0,
    required this.hasCheckedCollocation,
    required this.shakeTrigger,
    required this.isDark,
    required this.onAddChunk,
    required this.onRemoveChunk,
    required this.onCheckAssembly,
    required this.onSelectCollocation,
    this.onSpeakSentence,
    this.onClearChunks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence Card with Context Gap and Audio Listen Button
        ShakeableWrapper(
          shakeCount: shakeTrigger,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 16.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'COMPLETE THE CONTEXT SENTENCE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                        ),
                      ),
                    ),
                    if (onSpeakSentence != null) ...[
                      SizedBox(width: 8.w),
                      ScaleButton(
                        onTap: onSpeakSentence!,
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : AppColors.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 16.r,
                            color: isDark
                                ? AppColors.indigo400
                                : AppColors.indigo600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  sentence,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Stage 1: Word Chunk Assembly Area (60-120 FPS isolated repaint)
        if (!showCollocationStage)
          availableChunksNotifier != null && placedChunksNotifier != null
              ? AnimatedBuilder(
                  animation: Listenable.merge([
                    availableChunksNotifier!,
                    placedChunksNotifier!,
                  ]),
                  builder: (context, _) => _buildStage1AssemblyArea(
                    currentPlaced: placedChunksNotifier!.value,
                    currentAvailable: availableChunksNotifier!.value,
                  ),
                )
              : _buildStage1AssemblyArea(
                  currentPlaced: placedChunks,
                  currentAvailable: availableChunks,
                ),

        // Stage 2: Instant Collocation Snap Challenge
        if (showCollocationStage)
          FlashcardCollocationSnapCard(
            collocationPrompt: collocationPrompt,
            collocationOptions: collocationOptions,
            selectedCollocationIndex: selectedCollocationIndex,
            correctCollocationIndex: correctCollocationIndex,
            hasCheckedCollocation: hasCheckedCollocation,
            isDark: isDark,
            onSelectCollocation: onSelectCollocation,
          ),
      ],
    );
  }

  Widget _buildStage1AssemblyArea({
    required List<String> currentPlaced,
    required List<String> currentAvailable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Assembled Slot
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.slate900
                : (hasCheckedAssembly && isAssemblyCorrect
                      ? Colors.green.withValues(alpha: 0.08)
                      : AppColors.slate100),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasCheckedAssembly
                  ? (isAssemblyCorrect ? Colors.green : Colors.red)
                  : (isDark ? AppColors.slate800 : AppColors.slate300),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assembled Word:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  if (currentPlaced.isNotEmpty &&
                      !hasCheckedAssembly &&
                      onClearChunks != null)
                    ScaleButton(
                      onTap: onClearChunks!,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.undo_rounded,
                            size: 12.r,
                            color: isDark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.red.shade300
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              currentPlaced.isEmpty
                  ? _buildEmptySlots(isDark)
                  : Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      alignment: WrapAlignment.center,
                      children: List.generate(currentPlaced.length, (idx) {
                        return ScaleButton(
                          onTap: () => onRemoveChunk(idx),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: hasCheckedAssembly && isAssemblyCorrect
                                  ? Colors.green
                                  : AppColors.indigo500,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentPlaced[idx],
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.close_rounded,
                                  size: 14.r,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'AVAILABLE CHUNKS',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppColors.slate400 : AppColors.slate600,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: currentAvailable.map((chunk) {
            return ScaleButton(
              key: ValueKey('avail_$chunk'),
              onTap: () => onAddChunk(chunk),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate700 : AppColors.slate300,
                  ),
                ),
                child: Text(
                  chunk,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptySlots(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => Container(
              width: 44.w,
              height: 32.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: isDark ? AppColors.slate600 : AppColors.slate400,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Tap phonetic chunks below to assemble',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.slate500 : AppColors.slate400,
          ),
        ),
      ],
    );
  }
}
