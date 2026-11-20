import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Word Chunk Weaver & Collocation Slotter for Guided Practice.
class FlashcardPracticeChunkWeaver extends StatelessWidget {
  final String sentence;
  final String targetWord;
  final List<String> availableChunks;
  final List<String> placedChunks;
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

  const FlashcardPracticeChunkWeaver({
    super.key,
    required this.sentence,
    required this.targetWord,
    required this.availableChunks,
    required this.placedChunks,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence Card with Context Gap
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

        // Stage 1: Word Chunk Assembly Area
        if (!showCollocationStage) ...[
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
                Text(
                  'Assembled Word:',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
                SizedBox(height: 8.h),
                placedChunks.isEmpty
                    ? Text(
                        'Tap phonetic chunks below to assemble',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate500
                              : AppColors.slate400,
                        ),
                      )
                    : Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        alignment: WrapAlignment.center,
                        children: List.generate(placedChunks.length, (idx) {
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
                                    placedChunks[idx],
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

          // Available Chunks Tray
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
            children: availableChunks.map((chunk) {
              return ScaleButton(
                key: ValueKey('avail_$chunk'),
                onTap: () => onAddChunk(chunk),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
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

        // Stage 2: Instant Collocation Snap Challenge
        if (showCollocationStage) ...[
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 18.r,
                      color: Colors.amber.shade700,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        collocationPrompt ?? 'SELECT THE NATURAL WORD PARTNER',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: isDark
                              ? Colors.amberAccent
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                ...List.generate(collocationOptions.length, (idx) {
                  final option = collocationOptions[idx];
                  final isSelected = selectedCollocationIndex == idx;
                  final isCorrect = idx == correctCollocationIndex;

                  Color borderCol = isDark
                      ? AppColors.slate700
                      : AppColors.slate300;
                  Color bgCol = isDark ? AppColors.slate800 : AppColors.slate50;

                  if (hasCheckedCollocation && isSelected) {
                    if (isCorrect) {
                      borderCol = Colors.green;
                      bgCol = Colors.green.withValues(alpha: 0.15);
                    } else {
                      borderCol = Colors.red;
                      bgCol = Colors.red.withValues(alpha: 0.15);
                    }
                  } else if (isSelected) {
                    borderCol = AppColors.indigo500;
                    bgCol = AppColors.indigo500.withValues(alpha: 0.1);
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: ScaleButton(
                      key: ValueKey('collocation_$idx'),
                      onTap: () => onSelectCollocation(idx),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: bgCol,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: borderCol,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
