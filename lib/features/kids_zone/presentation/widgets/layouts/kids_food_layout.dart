import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  static const Color colorfef2f2 = Color(0xFFFEF2F2);
  static const Color colord4d4d8 = Color(0xFFD4D4D8);
  static const Color colore4e4e7 = Color(0xFFE4E4E7);
}

/// Chef's kitchen pedagogical layout for the Kids Food vocabulary game.
class KidsFoodLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsFoodLayout] widget.
  const KidsFoodLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsFoodLayout> createState() => _KidsFoodLayoutState();
}

class _KidsFoodLayoutState extends State<KidsFoodLayout> {
  String? _selectedOption;
  int _lastAnsweredQuestIndex = -1;

  void _handleAnswer(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    String text,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = text;
      _lastAnsweredQuestIndex = state.currentIndex;
    });

    final isCorrect = (text.trim() == quest.correctAnswer?.trim());

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Submitting food option "$text" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsFoodLayout',
      );
    }

    if (!isCorrect) {
      final parts = text.trim().split(' ');
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
        'Pronouncing food option "$textToSpeak"',
        tag: 'KidsFoodLayout',
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
          tag: 'KidsFoodLayout',
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
      gameType: 'food',
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

                      // The Chef's Kitchen Tile Board
                      Center(
                        child: _buildKitchenBoard(
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
                              Icons.restaurant_rounded,
                              size: 16.r,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : AppColors.rose700,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: KidsFittedText(
                                state.answerStatus == AnswerStatus.correct
                                    ? context.tr(
                                        'games.kids_food_done',
                                        fallback: 'Delicious! Order served correctly!',
                                      )
                                    : context.tr(
                                        'games.kids_food_drag',
                                        fallback:
                                            'Tap or drag the right food platter to the kitchen board!',
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

                      // Checkered Tablecloth & Serving Platters
                      _buildTableclothAndPlatters(
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

  Widget _buildKitchenBoard(
    BuildContext context,
    KidsLoaded state,
    dynamic quest, {
    required double width,
    required double height,
  }) {
    return DragTarget<String>(
      key: const Key('kids_food_board_target'),
      onWillAcceptWithDetails: (details) => !state.answerStatus.isAnswered,
      onAcceptWithDetails: (details) {
        _handleAnswer(context, state, quest, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: state.answerStatus.isAnswered
                ? null
                : () => _replayQuestionAudio(quest),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // The White Kitchen Tile Board
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isHovering ? _LocalPalette.colorfef2f2 : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isHovering
                          ? AppColors.rose700
                          : _LocalPalette.colord4d4d8,
                      width: isHovering ? 5.r : 3.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isHovering
                            ? AppColors.rose700.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
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
                              (quest.question == '?' ||
                                  quest.question == null))
                            state.answerStatus == AnswerStatus.correct
                                ? Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 60.sp),
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.slate300,
                                      BlendMode.srcIn,
                                    ),
                                    child: Text(
                                      quest.emoji!,
                                      style: TextStyle(fontSize: 60.sp),
                                    ),
                                  ),
                          if (state.answerStatus != AnswerStatus.correct ||
                              (quest.question != '?' &&
                                  quest.question != null))
                            KidsFittedText(
                              quest.question ?? '?',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    (quest.question == '?' ||
                                            quest.question == null)
                                        ? 48.sp
                                        : 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.rose700.withValues(
                                  alpha: (quest.question == '?' ||
                                          quest.question == null)
                                      ? 0.7
                                      : 1.0,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Chef Hat on top
                Positioned(
                  top: -24.h,
                  child: Container(
                    width: 72.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30.r),
                      ),
                      border: Border.all(
                        color: _LocalPalette.colore4e4e7,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 2.w,
                          height: 16.h,
                          color: _LocalPalette.colore4e4e7,
                        ),
                        Container(
                          width: 2.w,
                          height: 20.h,
                          color: _LocalPalette.colore4e4e7,
                        ),
                        Container(
                          width: 2.w,
                          height: 16.h,
                          color: _LocalPalette.colore4e4e7,
                        ),
                      ],
                    ),
                  ),
                ),

                // Replay Audio Button
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('kids_food_replay_audio_button'),
                      onTap: () => _replayQuestionAudio(quest),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.rose700.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.rose700,
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

  Widget _buildTableclothAndPlatters(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    List<String> options,
    double availableWidth,
  ) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Checkered Tablecloth Base
        Container(
          height: 48.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red[600],
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
          clipBehavior: Clip.hardEdge,
          child: SvgPicture.string(
            _checkeredTableclothSvg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // Serving Platters
        Padding(
          padding: EdgeInsets.only(bottom: 12.h, left: 6.w, right: 6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isCorrect = (option == quest.correctAnswer);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: _buildServingPlatterOption(
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

  Widget _buildServingPlatterOption(
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

    final platterWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('kids_food_option_$index'),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30.r),
          bottom: Radius.circular(14.r),
        ),
        onTap: state.answerStatus.isAnswered
            ? null
            : () => _handleAnswer(context, state, state.currentQuest, text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30.r),
              bottom: Radius.circular(14.r),
            ),
            border: Border.all(
              color: isSelected ? KidsColors.warmAmber : Colors.transparent,
              width: isSelected ? 3.0 : 0.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The Cloche (Silver Dome)
              Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30.r)),
                  border: Border.all(color: AppColors.slate400, width: 1.5),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, AppColors.slate300],
                  ),
                ),
                child: Stack(
                  children: [
                    // Dome handle
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(top: 3.h),
                        width: 14.w,
                        height: 7.h,
                        decoration: BoxDecoration(
                          color: AppColors.slate400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),

                    // Pronunciation Speaker Button
                    Positioned(
                      top: 2.h,
                      right: 4.w,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('kids_food_pronounce_$index'),
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () => _playOptionAudio(text),
                          child: Padding(
                            padding: EdgeInsets.all(2.r),
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

              // The Platter Base
              Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14.r)),
                  border: Border.all(color: AppColors.slate400, width: 1.5),
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
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 4.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (emojiPart.isNotEmpty)
                          Text(emojiPart, style: TextStyle(fontSize: 18.sp)),
                        Flexible(
                          child: KidsFittedText(
                            namePart,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (state.answerStatus.isAnswered) {
      return platterWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: estimatedWidth.clamp(70.0, 110.0),
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: platterWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: platterWidget),
      child: platterWidget,
    );
  }
}

const String _checkeredTableclothSvg = '''
<svg width="2000" height="200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <pattern id="checker" width="40" height="40" patternUnits="userSpaceOnUse">
      <rect width="40" height="40" fill="#E53935" />
      <rect x="0" y="0" width="20" height="20" fill="#FFFFFF" opacity="0.9" />
      <rect x="20" y="20" width="20" height="20" fill="#FFFFFF" opacity="0.9" />
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#checker)" />
</svg>
''';
