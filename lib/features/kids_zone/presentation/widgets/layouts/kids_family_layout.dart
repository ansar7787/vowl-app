import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorfef9c3 = Color(0xFFFEF9C3);
  static const Color colorfef08a = Color(0xFFFEF08A);
}

/// Cozy Living Room Theme for Family Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFamilyLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFamilyLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsFamilyLayout> createState() => _KidsFamilyLayoutState();
}

class _KidsFamilyLayoutState extends State<KidsFamilyLayout> {
  String? _selectedOption;
  int _lastAnsweredQuestIndex = -1;

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
      _lastAnsweredQuestIndex = state.currentIndex;
    });

    final quest = state.currentQuest;
    final isCorrect = (option.trim() == quest.correctAnswer?.trim());

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Submitting family option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsFamilyLayout',
      );
    }

    if (!isCorrect) {
      final parts = option.trim().split(' ');
      if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
        parts.removeLast();
      }
      final textToSpeak = parts.join(' ');
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(textToSpeak);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final parts = text.trim().split(' ');
    if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
      parts.removeLast();
    }
    final textToSpeak = parts.join(' ');
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing family option "$textToSpeak"',
        tag: 'KidsFamilyLayout',
      );
    }
    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl<KidsTTSService>().speak(textToSpeak, force: true);
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
  }

  void _replayQuestionAudio(dynamic quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying instruction audio for quest "${quest.id}"',
          tag: 'KidsFamilyLayout',
        );
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(instruction, force: true);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'family',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final options = quest.options?.map((e) => e.toString()).toList() ?? [];

        if (state.currentIndex != _lastAnsweredQuestIndex) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isNarrow = availableWidth < 360;

            final frameWidth = (availableWidth * 0.88).clamp(240.0, 320.0).w;
            final frameHeight = 185.h;

            return Center(
              child: SizedBox(
                width: availableWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: KidsGameBaseScreen.mascotClearanceHeight + 6.h,
                      ),

                      // The Framed Painting on Living Room Wall
                      Center(
                        child: _buildFramedPainting(
                          context,
                          state,
                          quest,
                          width: frameWidth,
                          height: frameHeight,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Prompt banner with dual interaction hint
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 16.r,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : AppColors.amber900,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: KidsFittedText(
                                state.answerStatus == AnswerStatus.correct
                                    ? context.tr(
                                        'games.kids_family_done',
                                        fallback: 'Perfect match! Family photo placed!',
                                      )
                                    : context.tr(
                                        'games.kids_family_drag',
                                        fallback:
                                            'Tap or drag the polaroid photo to the wooden frame!',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isNarrow ? 12.5.sp : 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.75),
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Wooden Mantlepiece and Polaroids
                      _buildMantlepieceAndPolaroids(
                        context,
                        state,
                        quest,
                        options,
                        availableWidth,
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFramedPainting(
    BuildContext context,
    KidsLoaded state,
    dynamic quest, {
    required double width,
    required double height,
  }) {
    return DragTarget<String>(
      key: const Key('kids_family_frame_target'),
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: state.answerStatus.isAnswered
                ? null
                : () => _replayQuestionAudio(quest),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isHovering
                        ? _LocalPalette.colorfef9c3
                        : _LocalPalette.colorfef08a,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isHovering
                          ? AppColors.amber600
                          : KidsColors.warmAmber,
                      width: isHovering ? 14.r : 10.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isHovering ? 0.35 : 0.2,
                        ),
                        blurRadius: isHovering ? 20 : 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quest.emoji != null)
                          state.answerStatus == AnswerStatus.correct
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      quest.emoji!,
                                      style: TextStyle(fontSize: 56.sp),
                                    ),
                                    SizedBox(height: 6.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: KidsFittedText(
                                        quest.correctAnswer
                                            .toString()
                                            .replaceAll(quest.emoji!, '')
                                            .trim(),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF78350F),
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                )
                              : ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color(0xFF78350F)
                                        .withValues(alpha: 0.2),
                                    BlendMode.srcIn,
                                  ),
                                  child: Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 56.sp),
                                  ),
                                ),
                        if (state.answerStatus != AnswerStatus.correct)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: KidsFittedText(
                              quest.question ?? '?',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF78350F)
                                    .withValues(alpha: 0.75),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Audio Replay Button
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('kids_family_replay_audio_button'),
                      onTap: () => _replayQuestionAudio(quest),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KidsColors.warmAmber,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMantlepieceAndPolaroids(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    List<String> options,
    double availableWidth,
  ) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Wooden Mantlepiece Base
        Container(
          height: 24.h,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.amber900,
            borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        // Polaroids Resting on Mantle
        Padding(
          padding: EdgeInsets.only(bottom: 12.h, left: 4.w, right: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isCorrect = (option == quest.correctAnswer);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: _buildPolaroidOption(
                    context,
                    state,
                    option,
                    isCorrect,
                    index,
                    availableWidth / options.length,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPolaroidOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
    double estimatedWidth,
  ) {
    final double rotation = index % 2 == 0 ? -0.04 : 0.04;

    final parts = text.trim().split(' ');
    String word = text;
    String emoji = '';
    if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
      emoji = parts.removeLast();
      word = parts.join(' ');
    }

    final isSelected = (_selectedOption == text);

    final polaroidWidget = Transform.rotate(
      angle: rotation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('kids_family_option_$index'),
          borderRadius: BorderRadius.circular(4.r),
          onTap: state.answerStatus.isAnswered
              ? null
              : () => _handleOptionSubmit(context, state, text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(minHeight: 130.h),
            padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: isSelected ? KidsColors.warmAmber : Colors.white70,
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.35 : 0.18,
                  ),
                  offset: Offset(0, isSelected ? 2 : 4),
                  blurRadius: isSelected ? 8 : 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Area
                    Container(
                      height: 72.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: Center(
                        child: emoji.isNotEmpty
                            ? Text(emoji, style: TextStyle(fontSize: 32.sp))
                            : Icon(
                                Icons.photo_rounded,
                                color: AppColors.slate400,
                                size: 26.r,
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Polaroid Label
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: KidsFittedText(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // TTS Speaker Button
                Positioned(
                  top: 2.h,
                  right: 2.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('kids_family_pronounce_$index'),
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () => _playOptionAudio(text),
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 14.r,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (state.answerStatus.isAnswered) {
      return polaroidWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: estimatedWidth.clamp(70.0, 110.0),
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: polaroidWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: polaroidWidget),
      child: polaroidWidget,
    );
  }
}
