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
  static const Color colorfef3c7 = Color(0xFFFEF3C7);
  static const Color color92400e = Color(0xFF92400E);
  static const Color color451a03 = Color(0xFF451A03);
}

/// Farmer's market pedagogical layout for the Kids Fruits vocabulary game.
class KidsFruitsLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsFruitsLayout] widget.
  const KidsFruitsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsFruitsLayout> createState() => _KidsFruitsLayoutState();
}

class _KidsFruitsLayoutState extends State<KidsFruitsLayout> {
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
        'Submitting fruits option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsFruitsLayout',
      );
    }

    if (!isCorrect) {
      final parts = option.trim().split(' ');
      if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
        parts.removeLast();
      }
      final cleanText = parts.join(' ');
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(cleanText);
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
        'Pronouncing fruit option "$textToSpeak"',
        tag: 'KidsFruitsLayout',
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
          tag: 'KidsFruitsLayout',
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
  void dispose() {
    try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'fruits',
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

            final boardWidth = (availableWidth * 0.88).clamp(240.0, 320.0).w;
            final boardHeight = 185.h;

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
                        height: KidsGameBaseScreen.mascotClearanceHeight + 14.h,
                      ),

                      // The Fruit Stand Awning & Wooden Signboard
                      Center(
                        child: _buildAwningFrame(
                          context,
                          state,
                          quest,
                          width: boardWidth,
                          height: boardHeight,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      // Prompt banner with dual interaction hint
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 16.r,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : _LocalPalette.color92400e,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: KidsFittedText(
                                state.answerStatus == AnswerStatus.correct
                                    ? context.tr(
                                        'games.kids_fruits_done',
                                        fallback: 'Fresh pick! Correct fruit chosen!',
                                      )
                                    : context.tr(
                                        'games.kids_fruits_drag',
                                        fallback:
                                            'Tap or drag the fresh fruit basket to the stand!',
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

                      SizedBox(height: 18.h),

                      // Wicker Baskets for Options
                      _buildBasketsRow(
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

  Widget _buildAwningFrame(
    BuildContext context,
    KidsLoaded state,
    dynamic quest, {
    required double width,
    required double height,
  }) {
    return DragTarget<String>(
      key: const Key('kids_fruits_awning_target'),
      onWillAcceptWithDetails: (details) => !state.answerStatus.isAnswered,
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
              clipBehavior: Clip.none,
              children: [
                // Main wooden signboard
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isHovering
                        ? _LocalPalette.colorfef9c3
                        : _LocalPalette.colorfef3c7,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isHovering
                          ? KidsColors.warmAmber
                          : _LocalPalette.color92400e,
                      width: isHovering ? 8.r : 5.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isHovering ? 0.35 : 0.15,
                        ),
                        blurRadius: isHovering ? 20 : 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quest.emoji != null &&
                              state.answerStatus == AnswerStatus.correct) ...[
                            Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 64.sp),
                            ),
                            SizedBox(height: 6.h),
                            KidsFittedText(
                              quest.correctAnswer ?? '',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: _LocalPalette.color451a03,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ] else ...[
                            if (quest.emoji != null &&
                                (quest.question == '?' ||
                                    quest.question == null))
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color(0xFF78350F)
                                      .withValues(alpha: 0.18),
                                  BlendMode.srcIn,
                                ),
                                child: Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 64.sp),
                                ),
                              ),
                            if (quest.question != '?' &&
                                quest.question != null)
                              KidsFittedText(
                                quest.question!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.amber900,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                              )
                            else if (quest.question == '?' ||
                                quest.question == null)
                              KidsFittedText(
                                '?',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 48.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.amber900
                                      .withValues(alpha: 0.75),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Red and white striped market awning on top
                Positioned(
                  top: -16.h,
                  child: Container(
                    width: width * 0.96,
                    height: 32.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Row(
                        children: List.generate(
                          8,
                          (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0
                                  ? Colors.red[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
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
                      key: const Key('kids_fruits_replay_audio_button'),
                      onTap: () => _replayQuestionAudio(quest),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _LocalPalette.color92400e
                                .withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: _LocalPalette.color92400e,
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

  Widget _buildBasketsRow(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    List<String> options,
    double availableWidth,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isCorrect = (option == quest.correctAnswer);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: _buildBasketOption(
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
    );
  }

  Widget _buildBasketOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
    double estimatedWidth,
  ) {
    final parts = text.trim().split(' ');
    String namePart = text;
    String emojiPart = '';
    if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
      emojiPart = parts.removeLast();
      namePart = parts.join(' ');
    }

    final isSelected = (_selectedOption == text);
    final isAnswered = state.answerStatus.isAnswered;
    final basketColor = AppColors.amber600;

    final basketWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('kids_fruits_option_$index'),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(8.r),
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        onTap: isAnswered
            ? null
            : () => _handleOptionSubmit(context, state, text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minHeight: 110.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              topRight: Radius.circular(8.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            border: Border.all(
              color: isSelected
                  ? KidsColors.warmAmber
                  : (isAnswered && isCorrect)
                      ? Colors.green.shade600
                      : Colors.transparent,
              width: (isSelected || (isAnswered && isCorrect)) ? 3.0 : 0.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The white fruit label on top of basket
              Container(
                constraints: BoxConstraints(minHeight: 34.h),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: _LocalPalette.color92400e,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: KidsFittedText(
                          namePart,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: _LocalPalette.color451a03,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),

                    // Pronunciation speaker button
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('kids_fruits_pronounce_$index'),
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: () => _playOptionAudio(text),
                          child: Padding(
                            padding: EdgeInsets.all(2.r),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 13.r,
                              color: AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // The Wicker Basket Container
              Container(
                height: 72.h,
                decoration: BoxDecoration(
                  color: basketColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                  border: Border.all(
                    color: (isAnswered && isCorrect)
                        ? Colors.green.shade600
                        : AppColors.amber900,
                    width: (isAnswered && isCorrect) ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.35 : 0.2,
                      ),
                      offset: Offset(0, isSelected ? 2 : 4),
                      blurRadius: isSelected ? 6 : 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _WickerPainter()),
                    ),
                    if (emojiPart.isNotEmpty)
                      Center(
                        child: Text(
                          emojiPart,
                          style: TextStyle(fontSize: 26.sp),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isAnswered) {
      return basketWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: estimatedWidth.clamp(70.0, 110.0),
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: basketWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: basketWidget),
      child: basketWidget,
    );
  }
}

class _WickerPainter extends CustomPainter {
  const _WickerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (double y = 8; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 8; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
