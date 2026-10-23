import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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

/// Parsed metadata for an option card in the Routine game.
/// Separates the visual emoji from the pedagogical title string while
/// preserving the raw value for state-level answer verification.
class RoutineOptionData {
  final String raw;
  final String title;
  final String? emoji;

  const RoutineOptionData({
    required this.raw,
    required this.title,
    this.emoji,
  });

  factory RoutineOptionData.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return RoutineOptionData(raw: text, title: text);
    }

    // Match any trailing sequence of emojis, variation selectors (\uFE0F), and joiners (\u200D)
    // RegEx covering all Unicode emojis, variation selectors (\uFE0F), and joiners (\u200D)
    final generalEmojiRegExp = RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2000}-\u{3300}\u{FE00}-\u{FE0F}\u{200D}\u{2600}-\u{27BF}]+',
      unicode: true,
    );
    final trailingEmojiRegExp = RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2000}-\u{3300}\u{FE00}-\u{FE0F}\u{200D}\u{2600}-\u{27BF}]+$',
      unicode: true,
    );

    final match = trailingEmojiRegExp.firstMatch(trimmed);
    if (match != null && match.start > 0) {
      final titleStr = trimmed.substring(0, match.start).trim();
      final emojiStr = trimmed.substring(match.start).trim();
      final cleanTitle = titleStr.replaceAll(generalEmojiRegExp, '').trim();
      return RoutineOptionData(
        raw: text,
        title: cleanTitle.isNotEmpty ? cleanTitle : text,
        emoji: emojiStr.isNotEmpty ? emojiStr : null,
      );
    }

    // General fallback: if trailing regex didn't match, extract any emoji anywhere
    final allMatches = generalEmojiRegExp.allMatches(trimmed).toList();
    if (allMatches.isNotEmpty) {
      final emojiChars = allMatches.map((m) => m.group(0)).join();
      final cleanTitle = trimmed.replaceAll(generalEmojiRegExp, '').trim();
      return RoutineOptionData(
        raw: text,
        title: cleanTitle.isNotEmpty ? cleanTitle : text,
        emoji: emojiChars.isNotEmpty ? emojiChars : null,
      );
    }

    return RoutineOptionData(raw: text, title: trimmed);
  }
}

/// Parsed metadata for the routine clue extracted from [quest.instruction].
/// Analyzes time-of-day context (Morning, Afternoon, Evening, Night) to drive
/// the bedroom window sky palette and contextual badge icons.
class RoutineClueData {
  final String rawInstruction;
  final String timeOfDay;
  final String timeBadgeLabel;
  final String timeIcon;
  final String clueText;

  const RoutineClueData({
    required this.rawInstruction,
    required this.timeOfDay,
    required this.timeBadgeLabel,
    required this.timeIcon,
    required this.clueText,
  });

  factory RoutineClueData.parse(String instruction) {
    String clue = instruction;
    final quoteMatch = RegExp(r'"([^"]+)"').firstMatch(instruction);
    if (quoteMatch != null) {
      clue = quoteMatch.group(1) ?? instruction;
    }

    final lower = clue.toLowerCase();
    String timeOfDay = 'day';
    String badge = 'Daily';
    String icon = '⏰';

    if (lower.contains('morning and night')) {
      timeOfDay = 'day_night';
      badge = 'Day & Night';
      icon = '⏰';
    } else if (lower.contains('morning')) {
      timeOfDay = 'morning';
      badge = 'Morning';
      icon = '🌅';
    } else if (lower.contains('afternoon')) {
      timeOfDay = 'afternoon';
      badge = 'Afternoon';
      icon = '☀️';
    } else if (lower.contains('evening')) {
      timeOfDay = 'evening';
      badge = 'Evening';
      icon = '🌇';
    } else if (lower.contains('night')) {
      timeOfDay = 'night';
      badge = 'Bedtime';
      icon = '🌙';
    }

    // Clean up clue text: e.g. "Morning to wake up fresh..." -> "Wake up fresh..."
    String cleanClue = clue;
    final prefixRegex = RegExp(
      r'^(Morning and Night|Morning|Afternoon|Evening|Night)\s+(to|when|for)?\s*',
      caseSensitive: false,
    );
    if (prefixRegex.hasMatch(clue)) {
      final replaced = clue.replaceFirst(prefixRegex, '').trim();
      if (replaced.isNotEmpty) {
        cleanClue = replaced[0].toUpperCase() + replaced.substring(1);
      }
    }

    return RoutineClueData(
      rawInstruction: instruction,
      timeOfDay: timeOfDay,
      timeBadgeLabel: badge,
      timeIcon: icon,
      clueText: cleanClue,
    );
  }
}

/// Production-grade Cozy Bedroom Theme for the Kids Routine game.
///
/// Features:
/// - Contextual time-of-day sky inside the bedroom window (Morning sunrise, Midday sun,
///   Evening dusk, Night moon & stars).
/// - Prominent, readable Routine Clue Banner with on-demand audio speech replay.
/// - Dual interaction: Seamless Drag-and-Drop AND high-accessibility Tap-to-Answer.
/// - Unspoiled question state: No pre-answer emoji silhouette leak.
/// - Rich visual feedback: Correct pillows glow emerald with celebratory bounce;
///   incorrect choices glow soft rose red.
/// - Audio scaffolding: Independent pronunciation buttons on all routine option pillows.
/// - Never overflows: Fully responsive layout engine adapting from 320dp small screens
///   up to large tablets with safety scroll for large accessibility fonts.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is the number of options (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsRoutineLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsRoutineLayout] widget.
  const KidsRoutineLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsRoutineLayout> createState() => _KidsRoutineLayoutState();
}

class _KidsRoutineLayoutState extends State<KidsRoutineLayout> {
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
    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsRoutineLayout: Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
      );
    }

    if (!isCorrect) {
      final parsed = RoutineOptionData.parse(option);
      di.sl<KidsTTSService>().speak(parsed.title);
      di.sl<HapticService>().error();
    } else {
      di.sl<HapticService>().success();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final parsed = RoutineOptionData.parse(text);
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsRoutineLayout: Pronouncing option "$text" ("${parsed.title}")',
      );
    }
    di.sl<KidsTTSService>().speak(parsed.title, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(dynamic quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsRoutineLayout: Replaying clue audio for quest "${quest.id}"',
        );
      }
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
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
      gameType: 'routine',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final clueData = RoutineClueData.parse(quest.instruction);

        // Reset selected option when question advances
        if (state.currentIndex != _lastAnsweredQuestIndex &&
            state.answerStatus == AnswerStatus.unanswered) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isCompactHeight = maxHeight < 590;
            final topSpacing = isCompactHeight
                ? 52.0.h
                : KidsGameBaseScreen.mascotClearanceHeight;
            final windowHeight = isCompactHeight ? 135.0.h : 160.0.h;
            final windowWidth = math.min(constraints.maxWidth * 0.76, 280.0.w);

            return SingleChildScrollView(
              physics: isCompactHeight
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top clearance for mascot speech bubble
                      SizedBox(height: topSpacing),

                      // Time Badge and Clue Banner
                      _RoutineClueHeader(
                        clueData: clueData,
                        onReplayAudio: () => _replayQuestionAudio(quest),
                      ),

                      SizedBox(height: 10.h),

                      // Bedroom Window Drop Target & Scene Beacon
                      _BedroomWindowTarget(
                        width: windowWidth,
                        height: windowHeight,
                        state: state,
                        quest: quest,
                        clueData: clueData,
                        onReplayAudio: () => _replayQuestionAudio(quest),
                        onAcceptOption: (option) =>
                            _handleOptionSubmit(context, state, option),
                      ),

                      SizedBox(height: 10.h),

                      // Instruction Subtitle
                      _RoutineInstructionPrompt(
                        isAnswered: state.answerStatus.isAnswered,
                      ),

                      SizedBox(height: 8.h),

                      // The Bed with Plush Routine Pillows
                      _BedOptionsArea(
                        options: quest.options ?? const [],
                        correctAnswer: quest.correctAnswer,
                        selectedOption: state.answerStatus.isAnswered
                            ? _selectedOption
                            : null,
                        state: state,
                        onOptionSelected: (option) =>
                            _handleOptionSubmit(context, state, option),
                        onOptionPlayAudio: _playOptionAudio,
                      ),

                      SizedBox(height: 16.h),
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
}

/// Clue header card displaying the time badge, routine clue text,
/// and an interactive audio speaker button.
class _RoutineClueHeader extends StatelessWidget {
  final RoutineClueData clueData;
  final VoidCallback onReplayAudio;

  const _RoutineClueHeader({
    required this.clueData,
    required this.onReplayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeBg;
    Color badgeText;
    switch (clueData.timeOfDay) {
      case 'morning':
        badgeBg = const Color(0xFFFEF3C7); // Amber 100
        badgeText = const Color(0xFFB45309); // Amber 700
        break;
      case 'afternoon':
        badgeBg = const Color(0xFFE0F2FE); // Sky 100
        badgeText = const Color(0xFF0369A1); // Sky 700
        break;
      case 'evening':
        badgeBg = const Color(0xFFFFE4E6); // Rose 100
        badgeText = const Color(0xFFBE123C); // Rose 700
        break;
      case 'night':
        badgeBg = const Color(0xFFE0E7FF); // Indigo 100
        badgeText = const Color(0xFF4338CA); // Indigo 700
        break;
      default:
        badgeBg = const Color(0xFFF1F5F9); // Slate 100
        badgeText = const Color(0xFF334155); // Slate 700
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(clueData.timeIcon, style: TextStyle(fontSize: 16.sp)),
                SizedBox(width: 4.w),
                Text(
                  clueData.timeBadgeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Routine Clue Text
          Expanded(
            child: Semantics(
              label: 'Clue: ${clueData.clueText}',
              child: Text(
                clueData.clueText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate800,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ),

          // Replay Clue Audio Button
          Semantics(
            label: 'Listen to clue',
            button: true,
            child: ScaleButton(
              onTap: onReplayAudio,
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: const Color(0xFFF97316),
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The architectural Bedroom Window.
/// Functions as the primary drop target and central visual scene beacon.
class _BedroomWindowTarget extends StatelessWidget {
  final double width;
  final double height;
  final KidsLoaded state;
  final dynamic quest;
  final RoutineClueData clueData;
  final VoidCallback onReplayAudio;
  final ValueChanged<String> onAcceptOption;

  const _BedroomWindowTarget({
    required this.width,
    required this.height,
    required this.state,
    required this.quest,
    required this.clueData,
    required this.onReplayAudio,
    required this.onAcceptOption,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final isIncorrect = state.answerStatus == AnswerStatus.incorrect;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) {
        if (!isAnswered) {
          onAcceptOption(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Semantics(
          label: isCorrect
              ? 'Routine completed with: ${quest.correctAnswer}'
              : 'Bedroom window drop zone. Drag a routine pillow here or tap below.',
          button: true,
          child: GestureDetector(
            onTap: isAnswered ? null : onReplayAudio,
            child: AnimatedScale(
              scale: isHovering ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Window Frame
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isHovering
                              ? const Color(0xFFF97316)
                              : isCorrect
                                  ? AppColors.emerald500
                                  : isIncorrect
                                      ? AppColors.rose500
                                      : Colors.white,
                          width: isHovering ? 4.r : 3.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isHovering
                                ? const Color(0xFFF97316).withValues(alpha: 0.4)
                                : isCorrect
                                    ? AppColors.emerald500.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.16),
                            blurRadius: isHovering ? 20 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Stack(
                          children: [
                            // Contextual sky background according to time of day
                            Positioned.fill(
                              child: _WindowSkyView(
                                timeOfDay: clueData.timeOfDay,
                              ),
                            ),

                            // White Window Mullions (delicate cross frame)
                            Center(
                              child: Container(
                                width: double.infinity,
                                height: 3.h,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 3.w,
                                height: double.infinity,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),

                            // Center Target Beacon / Answer Display
                            Center(
                              child: _WindowCenterContent(
                                state: state,
                                quest: quest,
                                isHovering: isHovering,
                                isCorrect: isCorrect,
                                isIncorrect: isIncorrect,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Soft Room Curtains on sides (Draped fabric accents)
                    Positioned(
                      left: -8.w,
                      top: 4.h,
                      bottom: 4.h,
                      child: _WindowCurtain(isLeft: true),
                    ),
                    Positioned(
                      right: -8.w,
                      top: 4.h,
                      bottom: 4.h,
                      child: _WindowCurtain(isLeft: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the sky outside the window based on time-of-day.
class _WindowSkyView extends StatelessWidget {
  final String timeOfDay;

  const _WindowSkyView({required this.timeOfDay});

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    Widget skyElement;

    switch (timeOfDay) {
      case 'morning':
        gradientColors = const [
          Color(0xFFFFEDD5), // Amber 100 sunrise
          Color(0xFFBAE6FD), // Sky 200
          Color(0xFF38BDF8), // Sky 400
        ];
        skyElement = Positioned(
          top: 14.h,
          left: 20.w,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFDE047), // Sunrise golden sun
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.6),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
        break;
      case 'afternoon':
        gradientColors = const [
          Color(0xFF7DD3FC), // Bright cyan sky
          Color(0xFF0284C7), // Azure
        ];
        skyElement = Positioned(
          top: 12.h,
          right: 24.w,
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFACC15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
        break;
      case 'evening':
        gradientColors = const [
          Color(0xFFF43F5E), // Rose 500 sunset
          Color(0xFF8B5CF6), // Violet 500
          Color(0xFF312E81), // Indigo 900
        ];
        skyElement = Positioned(
          bottom: 16.h,
          right: 24.w,
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFB923C).withValues(alpha: 0.8), // Dusk sun
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.7),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        );
        break;
      case 'night':
        gradientColors = const [
          Color(0xFF0F172A), // Slate 900 midnight
          Color(0xFF1E1B4B), // Indigo 950
          Color(0xFF312E81), // Indigo 900
        ];
        skyElement = Positioned(
          top: 14.h,
          right: 24.w,
          child: Text(
            '🌙',
            style: TextStyle(
              fontSize: 26.sp,
              shadows: [
                Shadow(
                  color: const Color(0xFFFEF08A).withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
        break;
      default:
        gradientColors = const [
          Color(0xFFBAE6FD),
          Color(0xFF38BDF8),
        ];
        skyElement = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          skyElement,
          if (timeOfDay == 'night') ...[
            Positioned(
              top: 28.h,
              left: 24.w,
              child: Text(
                '✨',
                style: TextStyle(fontSize: 12.sp, color: Colors.white70),
              ),
            ),
            Positioned(
              top: 48.h,
              right: 64.w,
              child: Text(
                '⭐',
                style: TextStyle(fontSize: 10.sp, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Center contents of the bedroom window.
/// Handles the unanswered drop beacon, hover indicator, and triumphant reveal.
class _WindowCenterContent extends StatelessWidget {
  final KidsLoaded state;
  final dynamic quest;
  final bool isHovering;
  final bool isCorrect;
  final bool isIncorrect;

  const _WindowCenterContent({
    required this.state,
    required this.quest,
    required this.isHovering,
    required this.isCorrect,
    required this.isIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isCorrect) {
      final parsed = RoutineOptionData.parse(quest.correctAnswer ?? '');
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parsed.emoji ?? quest.emoji ?? '✨',
              style: TextStyle(fontSize: 32.sp),
            ).animate().scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: 2.h),
            Text(
              parsed.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (isIncorrect) {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤔', style: TextStyle(fontSize: 24.sp)),
            SizedBox(height: 2.h),
            Text(
              'Try again',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.rose500,
              ),
            ),
          ],
        ),
      );
    } else if (isHovering) {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        ),
        child: Text(
          'Drop here',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB45309),
          ),
        ),
      );
    } else {
      // Default Unanswered Target: Cozy Pillow Silhouette outline (No answer emoji spoil!)
      content = Container(
        width: 140.w,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bed_rounded,
              size: 24.sp,
              color: const Color(0xFF6366F1),
            ),
            SizedBox(height: 3.h),
            Text(
              'Match the routine',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: content,
    );
  }
}

/// Decorative draped curtain panel flanking the bedroom window.
class _WindowCurtain extends StatelessWidget {
  final bool isLeft;

  const _WindowCurtain({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFB7185), // Rose 400 velvet curtain
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? Radius.circular(12.r) : Radius.zero,
          right: !isLeft ? Radius.circular(12.r) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: Offset(isLeft ? 2 : -2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Subtitle prompt guiding the player on interaction options.
class _RoutineInstructionPrompt extends StatelessWidget {
  final bool isAnswered;

  const _RoutineInstructionPrompt({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Tap a routine or drag it to the window',
      child: KidsFittedText(
        context.tr(
          'games.kids_routine_drag',
          fallback: 'Tap a routine or drag it to the window',
        ),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white.withValues(alpha: 0.8)
              : AppColors.slate600,
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The Cozy Bed options area displaying the routine pillows.
class _BedOptionsArea extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final KidsLoaded state;
  final ValueChanged<String> onOptionSelected;
  final ValueChanged<String> onOptionPlayAudio;

  const _BedOptionsArea({
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
    required this.state,
    required this.onOptionSelected,
    required this.onOptionPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // The Bed Headboard & Blanket Base
        Container(
          width: double.infinity,
          height: 94.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4338CA), // Indigo 700 duvet
                Color(0xFF312E81), // Indigo 900
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 50.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ),

        // The Pillows Row sitting on the bed
        Padding(
          padding: EdgeInsets.only(
            bottom: 12.h,
            left: 8.w,
            right: 8.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final optionData = RoutineOptionData.parse(option);
              final isCorrect = (option == correctAnswer);
              final isSelected = (option == selectedOption);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _PillowOptionWidget(
                    optionData: optionData,
                    isCorrect: isCorrect,
                    isSelected: isSelected,
                    isAnswered: isAnswered,
                    onTap: isAnswered ? null : () => onOptionSelected(option),
                    onPlayAudio: () => onOptionPlayAudio(option),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// A plush, tactile routine pillow item supporting both dragging and tapping.
class _PillowOptionWidget extends StatelessWidget {
  final RoutineOptionData optionData;
  final bool isCorrect;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback? onTap;
  final VoidCallback onPlayAudio;

  const _PillowOptionWidget({
    required this.optionData,
    required this.isCorrect,
    required this.isSelected,
    required this.isAnswered,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    double borderWidth = 2.0;

    if (isAnswered) {
      if (isSelected && isCorrect) {
        cardBg = const Color(0xFFECFDF5); // Emerald 50
        borderColor = AppColors.emerald500;
        borderWidth = 3.0;
      } else if (isSelected && !isCorrect) {
        cardBg = const Color(0xFFFFF1F2); // Rose 50
        borderColor = AppColors.rose500;
        borderWidth = 3.0;
      } else if (!isSelected && isCorrect) {
        borderColor = AppColors.emerald500.withValues(alpha: 0.6);
        borderWidth = 2.5;
      } else {
        cardBg = Colors.white.withValues(alpha: 0.6);
      }
    }

    final pillowWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        minHeight: 88.h,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Emoji inside card
          Text(
            optionData.emoji ?? '🛏️',
            style: TextStyle(fontSize: 28.sp),
          ),
          SizedBox(height: 4.h),

          // Routine Title Text strictly below emoji on its own separate line
          Text(
            optionData.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: isAnswered && isSelected && isCorrect
                  ? AppColors.emerald600
                  : isAnswered && isSelected && !isCorrect
                      ? AppColors.rose700
                      : AppColors.slate800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),

          SizedBox(height: 4.h),

          // Audio pronounce button with generous touch target
          Semantics(
            label: 'Pronounce ${optionData.title}',
            button: true,
            child: GestureDetector(
              onTap: onPlayAudio,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 28.w,
                height: 28.w,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 14.sp,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isAnswered) {
      return pillowWidget;
    }

    return Draggable<String>(
      data: optionData.raw,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 100.w,
          child: Transform.scale(
            scale: 1.06,
            child: Opacity(
              opacity: 0.95,
              child: pillowWidget,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: pillowWidget,
      ),
      child: ScaleButton(
        onTap: onTap,
        child: Semantics(
          label:
              'Routine option: ${optionData.title}. Double tap or drag to choose.',
          button: true,
          child: pillowWidget,
        ),
      ),
    );
  }
}
