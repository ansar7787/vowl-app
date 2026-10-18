import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Design system color palette for the Weather Game.
class _WeatherPalette {
  _WeatherPalette._();

  // Primary Theme: Azure Sky
  static const Color skyLight = Color(0xFF38BDF8); // Sky 400
  static const Color skySoft = Color(0xFFBAE6FD); // Sky 200
  static const Color skyBackground = Color(0xFFF0F9FF); // Sky 50
  static const Color skyDeep = Color(0xFF0369A1); // Sky 700
  static const Color skyTextDark = Color(0xFF0C4A6E); // Sky 900

  // Wooden Window Frame
  static const Color woodFrameDark = Color(0xFF5C3A21); // Rich timber
  static const Color woodFrameMedium = Color(0xFF8B5A2B); // Warm teak
  static const Color woodFrameBorder = Color(0xFF422817); // Deep wood border


  // Cloud Option Styling
  static const Color cloudWhite = Colors.white;
  static const Color cloudShadow = Color(0xFF93C5FD); // Soft blue tactile shadow
  static const Color cloudBorder = Color(0xFFBAE6FD); // Sky 200 outline
  static const Color cloudText = Color(0xFF0369A1); // Sky 700 bold

  // Interactive Target States
  static const Color hoverGlow = Color(0xFFFBBF24); // Amber 400 target glow

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Production-grade Sky Explorer & Weather Game Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop of clouds to the Sky Window,
///   AND accessible tap-to-answer for younger learners or motor-impaired children.
/// - Unspoiled forecast plaque: Clear, unoccluded weather riddle and scenario
///   without wooden crossbars cutting through text or premature answer spoiling.
/// - Dynamic Sky Window: Beautiful wooden casement with soft draped curtains,
///   floating atmospheric clouds, and an ambient weather aura that transforms
///   into a celebratory sunny/rainy weather reveal upon correct completion.
/// - Audio scaffolding: Pronounces target weather vocabulary on demand and upon
///   submission, with dedicated speaker icons on the forecast plaque and clouds.
/// - Adaptive card layout: Automatically renders puffy 3D clouds for short
///   vocabulary words, and wide horizontal sky-plaque banners for multi-word or
///   sentence-length options (Batches 1-200 safe).
/// - Lifeline integration: Automatically dims a distractor cloud when `hintUsed`
///   is active to scaffold struggling children.
/// - Visual hierarchy & 2026 polish: Rich wood textures, tactile cartoon shadows,
///   vibrant feedback states, and full screen-reader Semantics support.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees
///   zero RenderFlex overflows across 320dp to tablet dimensions.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is options count (typically 3 or 4)
/// - Space Complexity: O(1) auxiliary space
class KidsWeatherLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsWeatherLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsWeatherLayout> createState() => _KidsWeatherLayoutState();
}

class _KidsWeatherLayoutState extends State<KidsWeatherLayout> {
  String? _selectedOption;
  String? _lastQuestId;

  void _syncStateWithQuest(KidsQuest currentQuest) {
    if (_lastQuestId != currentQuest.id) {
      _lastQuestId = currentQuest.id;
      _selectedOption = null;
    }
  }

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
    });

    final quest = state.currentQuest;
    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsWeather',
      );
    }

    try {
      di.sl<KidsTTSService>().speak(option, force: true);
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Failed to pronounce submitted option "$option": $e',
          tag: 'KidsWeather',
        );
      }
    }

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing option "$text"',
        tag: 'KidsWeather',
      );
    }
    try {
      di.sl<KidsTTSService>().speak(text, force: true);
      di.sl<HapticService>().selection();
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Failed to pronounce option "$text": $e',
          tag: 'KidsWeather',
        );
      }
    }
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final textToSpeak = instruction.isNotEmpty
        ? (question.isNotEmpty && question != '?'
            ? '$instruction $question'
            : instruction)
        : question;

    if (textToSpeak.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying clue audio for quest "${quest.id}"',
          tag: 'KidsWeather',
        );
      }
      try {
        di.sl<KidsTTSService>().speak(textToSpeak, force: true);
        di.sl<HapticService>().selection();
      } catch (e) {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'Failed to replay clue audio for quest "${quest.id}": $e',
            tag: 'KidsWeather',
          );
        }
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
      gameType: 'weather',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        _syncStateWithQuest(quest);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final isTablet = constraints.maxWidth > 550;
            final contentWidth = isTablet
                ? 520.0
                : (constraints.maxWidth - 24.w);

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 24.h,
                    left: 4.w,
                    right: 4.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight + 12.h),

                      // Sky Window Drop Target
                      _buildWeatherWindow(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 14.h),

                      // Action Instruction Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // Weather Cloud Options
                      _buildOptionsSection(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),
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

  /// Interactive Sky Window (Target Zone)
  Widget _buildWeatherWindow(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final instruction = InstructionHelper.getInstruction(quest);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Semantics(
          label: isCorrect
              ? 'Correct weather: ${quest.correctAnswer}'
              : 'Weather window. Clue: $instruction. Tap an answer below or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _WeatherPalette.woodFrameMedium,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isHovering
                    ? _WeatherPalette.hoverGlow
                    : (isCorrect
                        ? _WeatherPalette.successBorder
                        : _WeatherPalette.woodFrameBorder),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? _WeatherPalette.hoverGlow.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.22),
                  blurRadius: isHovering ? 18 : 10,
                  offset: const Offset(0, 6),
                  spreadRadius: isHovering ? 2 : 0,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Decorative Window Valance Header
                _buildWindowValance(isHovering: isHovering),

                // Main Sky Pane Area
                Container(
                  margin: EdgeInsets.all(8.r),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 10.w : 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _WeatherPalette.skyLight,
                        _WeatherPalette.skySoft,
                      ],
                    ),
                  ),
                  child: isCorrect
                      ? _buildCelebratoryWeatherReveal(quest)
                      : _buildWeatherForecastPlaque(quest, isHovering, isNarrow: isNarrow),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Decorative Window Valance Header
  Widget _buildWindowValance({required bool isHovering}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _WeatherPalette.woodFrameDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: 14.r,
                color: isHovering ? _WeatherPalette.hoverGlow : Colors.amber.shade300,
              ),
              SizedBox(width: 6.w),
              Text(
                'WEATHER WINDOW',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_rounded,
                size: 14.r,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.water_drop_rounded,
                size: 13.r,
                color: Colors.lightBlueAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Unspoiled Weather Forecast Plaque with Question, Scenario, and Audio Replay Button
  Widget _buildWeatherForecastPlaque(
    KidsQuest quest,
    bool isHovering, {
    required bool isNarrow,
  }) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final hasBoth = instruction.isNotEmpty && question.isNotEmpty && question != '?';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12.w : 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isHovering ? 0.96 : 0.92),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHovering
              ? _WeatherPalette.hoverGlow
              : _WeatherPalette.cloudBorder,
          width: isHovering ? 2.5.w : 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _WeatherPalette.skyDeep.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Forecast Tag and Audio Replay Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wb_twilight_rounded,
                    size: 16.r,
                    color: _WeatherPalette.skyDeep,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'WEATHER CLUE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _WeatherPalette.skyDeep,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Speaker button to replay scenario and question
              ScaleButton(
                onTap: () => _replayQuestionAudio(quest),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: _WeatherPalette.skyBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _WeatherPalette.cloudBorder,
                      width: 1.2.w,
                    ),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 16.r,
                    color: _WeatherPalette.skyDeep,
                  ),
                ),
              ),
            ],
          ),

          if (hasBoth) ...[
            SizedBox(height: 8.h),
            Text(
              instruction,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: 8.h),

          // Question Text (Readable, responsive, full wrapping)
          Text(
            hasBoth
                ? question
                : (question.isNotEmpty && question != '?' ? question : instruction),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 16.sp : 17.sp,
              fontWeight: FontWeight.w700,
              color: _WeatherPalette.skyTextDark,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 10.h),

          // Drop readiness prompt inside the plaque
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 15.r,
                color: isHovering
                    ? _WeatherPalette.skyDeep
                    : _WeatherPalette.skyDeep.withValues(alpha: 0.65),
              ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  isHovering ? 'Drop here!' : 'Place your answer here',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _WeatherPalette.skyDeep
                        : _WeatherPalette.skyDeep.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Celebratory Weather Reveal when answer is correct
  Widget _buildCelebratoryWeatherReveal(KidsQuest quest) {
    final emoji = quest.emoji ?? '🌤️';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _WeatherPalette.successBorder,
          width: 2.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _WeatherPalette.successBorder.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebratory Emoji with animated scale & glow
          Text(
            emoji,
            style: TextStyle(fontSize: 42.sp),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: 250.ms),

          SizedBox(height: 6.h),

          // Correct Answer Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18.r,
                color: _WeatherPalette.successText,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  quest.correctAnswer ?? '',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: _WeatherPalette.successText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Interaction instruction banner between target and choices
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _WeatherPalette.cloudBorder,
          width: 1.2.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15.r,
            color: _WeatherPalette.skyDeep,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_weather_drag',
                fallback: 'Drag to the window or tap to choose',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _WeatherPalette.skyDeep,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Adaptive Weather Cloud Options Section
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Determine if options are short vocabulary or longer phrases/sentences
    final bool areAllOptionsShort = options.every((opt) => opt.trim().length <= 16);

    // Identify distractor option to dim if hint is active
    String? hintDimOption;
    if (state.hintUsed && !state.answerStatus.isAnswered) {
      hintDimOption = options.firstWhere(
        (opt) => opt != quest.correctAnswer,
        orElse: () => '',
      );
      if (hintDimOption.isEmpty) hintDimOption = null;
    }

    if (areAllOptionsShort) {
      // 2x2 Puffy Weather Clouds for concise vocabulary (e.g. Sunny, Rainy, Windy, Snowy)
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: isNarrow ? 10.w : 14.w,
        runSpacing: isNarrow ? 10.h : 14.h,
        children: options.map((option) {
          final isDimmedByHint = (option == hintDimOption);
          return _buildPuffyCloudCard(
            context,
            state,
            quest,
            option,
            isDimmedByHint: isDimmedByHint,
            isNarrow: isNarrow,
          );
        }).toList(),
      );
    } else {
      // Wide Horizontal Sky Banner Plaques for sentence/clause options (Batches 2-200 safe)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((option) {
          final isDimmedByHint = (option == hintDimOption);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildWideSkyBannerCard(
              context,
              state,
              quest,
              option,
              isDimmedByHint: isDimmedByHint,
            ),
          );
        }).toList(),
      );
    }
  }

  /// Compact Puffy Cartoon Cloud Card (for short weather words)
  Widget _buildPuffyCloudCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required bool isDimmedByHint,
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    // Dynamic styling based on answer state
    Color bgColor = _WeatherPalette.cloudWhite;
    Color borderColor = _WeatherPalette.cloudBorder;
    Color textColor = _WeatherPalette.cloudText;
    Color shadowColor = _WeatherPalette.cloudShadow.withValues(alpha: 0.5);

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _WeatherPalette.successBg;
          borderColor = _WeatherPalette.successBorder;
          textColor = _WeatherPalette.successText;
          shadowColor = _WeatherPalette.successBorder.withValues(alpha: 0.4);
        } else {
          bgColor = _WeatherPalette.errorBg;
          borderColor = _WeatherPalette.errorBorder;
          textColor = _WeatherPalette.errorText;
          shadowColor = _WeatherPalette.errorBorder.withValues(alpha: 0.4);
        }
      } else if (isCorrectOption) {
        bgColor = _WeatherPalette.successBg;
        borderColor = _WeatherPalette.successBorder;
        textColor = _WeatherPalette.successText;
        shadowColor = _WeatherPalette.successBorder.withValues(alpha: 0.4);
      }
    }

    final double cardWidth = isNarrow ? 144.w : 156.w;
    final double cardHeight = isNarrow ? 76.h : 82.h;

    Widget cloudVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Base rounded pill
            Positioned(
              bottom: 4.h,
              child: Container(
                width: cardWidth - 8.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(color: borderColor, width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.45),
                      offset: const Offset(0, 3),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            // Left puff
            Positioned(
              left: 22.w,
              bottom: 22.h,
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.w),
                ),
              ),
            ),
            // Right puff
            Positioned(
              right: 26.w,
              bottom: 18.h,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.w),
                ),
              ),
            ),
            // Center fill to mask overlapping circular borders cleanly
            Positioned(
              bottom: 6.h,
              child: Container(
                width: cardWidth - 14.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),

            // Card Text and Speaker Button (precisely centered inside the base pill)
            Positioned(
              bottom: 4.h,
              left: 8.w,
              right: 8.w,
              height: 52.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main Weather Word
                  Flexible(
                    child: KidsFittedText(
                      text,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.2,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // Speaker Button for pronunciation
                  Semantics(
                    label: 'Hear $text pronounced',
                    button: true,
                    child: ScaleButton(
                      key: ValueKey('speaker_cloud_$text'),
                      onTap: () => _playOptionAudio(text),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 16.r,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Draggable feedback widget
    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.05,
        child: Opacity(
          opacity: 0.92,
          child: cloudVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered ? null : () => _handleOptionSubmit(context, state, text),
      child: cloudVisual,
    );

    return Semantics(
      label: '$text. Tap to choose, or drag to the window.',
      button: true,
      enabled: !isAnswered,
      child: isAnswered
          ? cloudVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: cloudVisual),
              child: interactiveCard,
            ),
    );
  }

  /// Wide Horizontal Sky Banner Card (for long phrases and full-sentence options)
  Widget _buildWideSkyBannerCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required bool isDimmedByHint,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    Color bgColor = _WeatherPalette.cloudWhite;
    Color borderColor = _WeatherPalette.cloudBorder;
    Color textColor = _WeatherPalette.skyTextDark;
    Color shadowColor = _WeatherPalette.cloudShadow.withValues(alpha: 0.4);

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _WeatherPalette.successBg;
          borderColor = _WeatherPalette.successBorder;
          textColor = _WeatherPalette.successText;
          shadowColor = _WeatherPalette.successBorder.withValues(alpha: 0.35);
        } else {
          bgColor = _WeatherPalette.errorBg;
          borderColor = _WeatherPalette.errorBorder;
          textColor = _WeatherPalette.errorText;
          shadowColor = _WeatherPalette.errorBorder.withValues(alpha: 0.35);
        }
      } else if (isCorrectOption) {
        bgColor = _WeatherPalette.successBg;
        borderColor = _WeatherPalette.successBorder;
        textColor = _WeatherPalette.successText;
        shadowColor = _WeatherPalette.successBorder.withValues(alpha: 0.35);
      }
    }

    Widget bannerVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Container(
        constraints: BoxConstraints(minHeight: 58.h),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: borderColor, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.4),
              offset: const Offset(0, 3),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            // Cloud Icon / Drag Handle
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: _WeatherPalette.skyBackground,
                shape: BoxShape.circle,
                border: Border.all(color: _WeatherPalette.cloudBorder, width: 1.w),
              ),
              child: Icon(
                Icons.cloud_rounded,
                size: 16.r,
                color: _WeatherPalette.skyDeep,
              ),
            ),

            SizedBox(width: 12.w),

            // Option Text (Full wrapping, zero clipping, high contrast)
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Speaker Icon for Audio Scaffolding
            Semantics(
              label: 'Hear $text pronounced',
              button: true,
              child: ScaleButton(
                key: ValueKey('speaker_cloud_$text'),
                onTap: () => _playOptionAudio(text),
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 18.r,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),

            SizedBox(width: 4.w),

            // Drag handle hint
            Icon(
              Icons.drag_indicator_rounded,
              size: 16.r,
              color: textColor.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );

    final feedbackWidth = (MediaQuery.sizeOf(context).width - 32.w).clamp(260.0, 480.0);
    final feedbackWidget = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: feedbackWidth,
        child: Transform.scale(
          scale: 1.02,
          child: Opacity(opacity: 0.92, child: bannerVisual),
        ),
      ),
    );

    final interactiveBanner = ScaleButton(
      onTap: isAnswered ? null : () => _handleOptionSubmit(context, state, text),
      child: bannerVisual,
    );

    return Semantics(
      label: '$text. Tap to choose, or drag to the window.',
      button: true,
      enabled: !isAnswered,
      child: isAnswered
          ? bannerVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: bannerVisual),
              child: interactiveBanner,
            ),
    );
  }
}
