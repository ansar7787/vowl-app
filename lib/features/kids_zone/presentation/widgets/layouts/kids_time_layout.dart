import 'dart:math' as math;
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
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Design tokens specifically crafted for the Clock Tower environment.
class _TimePalette {
  _TimePalette._();

  static const Color woodShelf = Color(0xFF532E18);
  static const Color woodBevel = Color(0xFF783E1C);
  static const Color brassGold = Color(0xFFD97706);
  static const Color brassLight = Color(0xFFFBBF24);
  static const Color dialIvory = Color(0xFFFFFBEB);
  static const Color dialBorder = Color(0xFFFDE68A);
  static const Color handsSteel = Color(0xFF1E293B);
  static const Color handsHighlight = Color(0xFF0F172A);
  static const Color secondHand = Color(0xFFEF4444);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color goldGlow = Color(0xFFF59E0B);
  static const Color optionBorder = Color(0xFFE2E8F0);
  static const Color optionActiveBorder = Color(0xFFF59E0B);
}

/// Extracted pedagogical metadata for a Time quest.
/// Analyzes curriculum instruction, options, and metadata to extract
/// pedagogical subtypes, time badges, and exact analog clock hands positions.
class TimeQuestData {
  final String rawInstruction;
  final String subtype;
  final String subtypeBadge;
  final String subtypeIcon;
  final (int hour, int minute) targetTime;
  final String interactionType;
  final String? emoji;

  const TimeQuestData({
    required this.rawInstruction,
    required this.subtype,
    required this.subtypeBadge,
    required this.subtypeIcon,
    required this.interactionType,
    required this.targetTime,
    this.emoji,
  });

  factory TimeQuestData.parse(KidsQuest quest) {
    final rawInstruction = InstructionHelper.getInstruction(quest);
    final subtype =
        (quest.metadata?['subtype'] as String?)?.toLowerCase().trim() ??
        'clock_reading';
    final interactionType =
        quest.metadata?['interactionType'] as String? ?? 'multiple_choice';

    // Map subtype to pedagogical badge title and emoji icon
    final (badgeTitle, badgeIcon) = _resolveSubtypeBadge(
      subtype,
      rawInstruction,
    );

    // Extract exact or contextual clock time for analog hands display
    final extractedTime = _extractTime(
      rawInstruction,
      correctAnswer: quest.correctAnswer ?? '',
      emoji: quest.emoji,
      level: quest.level,
    );

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsTimeLayout: Parsed quest "${quest.id}" (subtype: $subtype, interaction: $interactionType, time: ${extractedTime.$1}:${extractedTime.$2.toString().padLeft(2, '0')})',
      );
    }

    return TimeQuestData(
      rawInstruction: rawInstruction,
      subtype: subtype,
      subtypeBadge: badgeTitle,
      subtypeIcon: badgeIcon,
      interactionType: interactionType,
      targetTime: extractedTime,
      emoji: quest.emoji,
    );
  }

  bool get isMultipleChoice => interactionType == 'multiple_choice';

  static (String, String) _resolveSubtypeBadge(
    String subtype,
    String instruction,
  ) {
    switch (subtype) {
      case 'time_of_day':
        return ('Part of the Day', '🌅');
      case 'o_clock':
        return ("O'Clock Time", '🔔');
      case 'clock_reading':
        return ('Read the Clock', '⏰');
      case 'half_past':
        return ('Half Past', '⏳');
      case 'quarter_hour':
        return ('Quarter Hour', '🍰');
      case 'five_minute_intervals':
        return ('Count by 5s', '🖐️');
      case 'am_pm':
        return ('AM & PM', '☀️');
      case 'duration':
        return ('Time Duration', '⏱️');
      case 'elapsed_time':
        return ('Passed Time', '⏳');
      case 'timetable':
        return ('Schedule Board', '🚎');
      case 'calendar':
        return ('Calendar Riddle', '📅');
      case 'time_word_problems':
        return ('Time Riddle', '🧩');
      case 'compare_times':
        return ('Compare Times', '⚖️');
      case 'sequencing':
        return ('Time Order', '👣');
      case 'time_planning':
        return ('Time Plan', '🌲');
      case 'schedule_reasoning':
        return ('Daily Schedule', '🎓');
      default:
        final lower = instruction.toLowerCase();
        if (lower.contains('morning') ||
            lower.contains('afternoon') ||
            lower.contains('night')) {
          return ('Part of the Day', '🌅');
        }
        if (lower.contains('calendar') ||
            lower.contains('yesterday') ||
            lower.contains('tomorrow')) {
          return ('Calendar Riddle', '📅');
        }
        return ('Time Quest', '⏰');
    }
  }

  static (int, int) _extractTime(
    String instruction, {
    required String correctAnswer,
    String? emoji,
    required int level,
  }) {
    // 1. Clock face emoji lookup
    const clockEmojis = <String, (int, int)>{
      '🕐': (1, 0),
      '🕑': (2, 0),
      '🕒': (3, 0),
      '🕓': (4, 0),
      '🕔': (5, 0),
      '🕕': (6, 0),
      '🕖': (7, 0),
      '🕗': (8, 0),
      '🕘': (9, 0),
      '🕙': (10, 0),
      '🕚': (11, 0),
      '🕛': (12, 0),
      '🕜': (1, 30),
      '🕝': (2, 30),
      '🕞': (3, 30),
      '🕟': (4, 30),
      '🕠': (5, 30),
      '🕡': (6, 30),
      '🕢': (7, 30),
      '🕣': (8, 30),
      '🕤': (9, 30),
      '🕥': (10, 30),
      '🕦': (11, 30),
      '🕧': (12, 30),
    };

    if (emoji != null && clockEmojis.containsKey(emoji)) {
      return clockEmojis[emoji]!;
    }

    final combined = '$instruction $correctAnswer';

    // 2. Digital time format: e.g. 3:40, 8:05, 11:15
    final digitalRegex = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    final dMatch = digitalRegex.firstMatch(combined);
    if (dMatch != null) {
      final h = int.tryParse(dMatch.group(1)!) ?? 12;
      final m = int.tryParse(dMatch.group(2)!) ?? 0;
      return (h % 12 == 0 ? 12 : h % 12, m);
    }

    // 3. "X o'clock" format
    final oclockRegex = RegExp(
      r'\b(\d{1,2})\s*o[\x27\x60\u2019]clock\b',
      caseSensitive: false,
    );
    final oMatch = oclockRegex.firstMatch(combined);
    if (oMatch != null) {
      final h = int.tryParse(oMatch.group(1)!) ?? 12;
      return (h % 12 == 0 ? 12 : h % 12, 0);
    }

    // 4. "half past X" format
    final halfRegex = RegExp(
      r'\bhalf past\s+(\d{1,2})\b',
      caseSensitive: false,
    );
    final hMatch = halfRegex.firstMatch(combined);
    if (hMatch != null) {
      final h = int.tryParse(hMatch.group(1)!) ?? 12;
      return (h % 12 == 0 ? 12 : h % 12, 30);
    }

    // 5. "quarter past X" format
    final qPastRegex = RegExp(
      r'\bquarter past\s+(\d{1,2})\b',
      caseSensitive: false,
    );
    final qpMatch = qPastRegex.firstMatch(combined);
    if (qpMatch != null) {
      final h = int.tryParse(qpMatch.group(1)!) ?? 12;
      return (h % 12 == 0 ? 12 : h % 12, 15);
    }

    // 6. "quarter to X" format
    final qToRegex = RegExp(
      r'\bquarter to\s+(\d{1,2})\b',
      caseSensitive: false,
    );
    final qtMatch = qToRegex.firstMatch(combined);
    if (qtMatch != null) {
      final h = (int.tryParse(qtMatch.group(1)!) ?? 12) - 1;
      final adjustedH = h <= 0 ? 12 : h;
      return (adjustedH, 45);
    }

    // 7. Explicit hands description: "short hand ... points to X ... long hand ... points to Y"
    final handsRegex = RegExp(
      r'short hand (?:points to |is on |is between \d+ and )(\d{1,2}).*?long hand (?:points to |is on )(\d{1,2})',
      caseSensitive: false,
    );
    final handsMatch = handsRegex.firstMatch(combined);
    if (handsMatch != null) {
      final h = int.tryParse(handsMatch.group(1)!) ?? 12;
      final longHandNum = int.tryParse(handsMatch.group(2)!) ?? 12;
      final m = (longHandNum % 12) * 5;
      return (h % 12 == 0 ? 12 : h % 12, m);
    }

    final handsRegex2 = RegExp(
      r'long hand (?:points to |is on )(\d{1,2}).*?short hand (?:points to |is on |is between \d+ and )(\d{1,2})',
      caseSensitive: false,
    );
    final handsMatch2 = handsRegex2.firstMatch(combined);
    if (handsMatch2 != null) {
      final longHandNum = int.tryParse(handsMatch2.group(1)!) ?? 12;
      final h = int.tryParse(handsMatch2.group(2)!) ?? 12;
      final m = (longHandNum % 12) * 5;
      return (h % 12 == 0 ? 12 : h % 12, m);
    }

    // Level-derived default time if no explicit time is extracted
    final levelHour = (level % 12 == 0) ? 12 : (level % 12);
    return (levelHour, 0);
  }
}

/// Production-grade Giant Clock Tower Theme for the Kids Time Game.
///
/// Features:
/// - Subtype badge header with auditory question replay button.
/// - Full question prompt visibility via mascot bubble with zero accidental duplication.
/// - Custom-painted authentic analog clock face with working hour/minute hands and 60-minute tick graduations.
/// - Rotating steampunk clockwork gears and rhythmic swinging pendulum.
/// - Dual interaction: Seamless Tap-to-Answer and Drag-and-Drop.
/// - Adaptive chronometer option cards that accommodate both short terms and long word problem sentences without microscopic scaling.
/// - Zero RenderFlex overflow guarantee across 320dp - 430dp+ screens and short display heights.
class KidsTimeLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsTimeLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsTimeLayout> createState() => _KidsTimeLayoutState();
}

class _KidsTimeLayoutState extends State<KidsTimeLayout> {
  String? _selectedOption;
  bool _isDraggingOverClock = false;
  int _lastHandledQuestIndex = -1;

  void _handleOptionSelection(
    BuildContext context,
    String option,
    dynamic quest,
    KidsLoaded state,
  ) {
    if (state.answerStatus.isAnswered) return;

    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsTimeLayout: Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
      );
    }

    setState(() {
      _selectedOption = option;
    });

    // Provide immediate tactile and audible feedback
    di.sl<HapticService>().selection();

    // Narrate selected option
    di.sl<KidsTTSService>().speak(option);

    // Play immediate game SFX
    final audio = di.sl<KidsAudioService>();
    if (isCorrect) {
      audio.playSuccessSFX();
    } else {
      audio.playFailureSFX();
    }

    // Submit answer to KidsBloc
    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _replayQuestionAudio(TimeQuestData questData) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsTimeLayout: Replaying question audio (subtype: ${questData.subtype})',
      );
    }
    di.sl<HapticService>().selection();
    di.sl<KidsTTSService>().speak(questData.rawInstruction, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'time',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final questData = TimeQuestData.parse(quest);

        if (state.currentIndex != _lastHandledQuestIndex &&
            state.answerStatus == AnswerStatus.unanswered) {
          _selectedOption = null;
          _lastHandledQuestIndex = state.currentIndex;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompactHeight = availableHeight < 620;

            final topClearance = isCompactHeight
                ? 52.h
                : KidsGameBaseScreen.mascotClearanceHeight;

            return SingleChildScrollView(
              physics: isCompactHeight
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. Top Clearance for Mascot Speech Bubble
                      SizedBox(height: topClearance),

                      // 2. Subtype Badge Header with Question Speaker
                      _TimeBadgeHeader(
                        questData: questData,
                        onSpeakerTap: () => _replayQuestionAudio(questData),
                      ),

                      SizedBox(height: isCompactHeight ? 6.h : 8.h),

                      // 3. Central Clock Tower Face (DragTarget & Visual Core)
                      _buildMasterClockTower(
                        context,
                        state,
                        quest,
                        questData,
                        isCompactHeight,
                      ),

                      SizedBox(height: isCompactHeight ? 4.h : 6.h),

                      // 4. Action Prompt Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          context.tr(
                            'games.kids_time_prompt',
                            fallback:
                                'Tap an answer or drag it to the clock! ⏰',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF475569),
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: isCompactHeight ? 4.h : 6.h),

                      // 5. Wooden Shelf with Option Cards & Pendulum
                      _buildOptionShelf(
                        context,
                        state,
                        quest,
                        isCompactHeight,
                      ),

                      SizedBox(height: 6.h),
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

  Widget _buildMasterClockTower(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    TimeQuestData questData,
    bool isCompactHeight,
  ) {
    final clockDiameter = isCompactHeight ? 165.r : 195.r;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (state.answerStatus.isAnswered) return false;
        setState(() => _isDraggingOverClock = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDraggingOverClock = false);
      },
      onAcceptWithDetails: (details) {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().debug(
            'KidsTimeLayout: Option "${details.data}" dropped onto clock target for quest "${quest.id}"',
          );
        }
        setState(() => _isDraggingOverClock = false);
        _handleOptionSelection(context, details.data, quest, state);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = _isDraggingOverClock || candidateData.isNotEmpty;
        final isAnswered = state.answerStatus.isAnswered;
        final isCorrect = state.answerStatus == AnswerStatus.correct;

        Color frameColor = _TimePalette.brassGold;
        if (isHovering) {
          frameColor = _TimePalette.goldGlow;
        } else if (isAnswered) {
          frameColor = isCorrect
              ? _TimePalette.optionActiveBorder
              : _TimePalette.secondHand;
        }

        return Semantics(
          label:
              'Clock showing ${questData.targetTime.$1} hours and ${questData.targetTime.$2} minutes. Drop answer here.',
          child: GestureDetector(
            onTap: () => _replayQuestionAudio(questData),
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOutCubic,
              width: clockDiameter,
              height: clockDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isHovering
                        ? _TimePalette.goldGlow.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.28),
                    blurRadius: isHovering ? 26 : 14,
                    spreadRadius: isHovering ? 4 : 0,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Rotating Cogwheels inside Tower
                  Positioned(
                    top: 20.r,
                    left: 24.r,
                    child: const _ClockGearWidget(size: 54, clockwise: true),
                  ),
                  Positioned(
                    bottom: 20.r,
                    right: 24.r,
                    child: const _ClockGearWidget(size: 64, clockwise: false),
                  ),

                  // Custom Painter Clock Dial with Tick Graduations & Authentic Hands
                  CustomPaint(
                    size: Size(clockDiameter, clockDiameter),
                    painter: _ClockFacePainter(
                      hour: questData.targetTime.$1,
                      minute: questData.targetTime.$2,
                      frameColor: frameColor,
                      isHovering: isHovering,
                    ),
                  ),

                  // Center Medallion Badge (Emoji or Success Star)
                  _buildCenterMedallion(questData, state, clockDiameter),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterMedallion(
    TimeQuestData questData,
    KidsLoaded state,
    double clockDiameter,
  ) {
    final medallionSize = clockDiameter * 0.28;
    final isCorrect = state.answerStatus == AnswerStatus.correct;

    return Container(
      width: medallionSize,
      height: medallionSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCorrect
            ? const Color(0xFFDCFCE7)
            : Colors.white.withValues(alpha: 0.95),
        border: Border.all(
          color: isCorrect ? Colors.green : _TimePalette.brassGold,
          width: 2.2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isCorrect
            ? Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: medallionSize * 0.65,
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
            : Text(
                questData.emoji ?? '⏰',
                style: TextStyle(fontSize: medallionSize * 0.52),
              ),
      ),
    );
  }

  Widget _buildOptionShelf(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    bool isCompactHeight,
  ) {
    final options = quest.options as List<String>? ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Options row on wooden platform
        Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          padding: EdgeInsets.symmetric(
            horizontal: 6.w,
            vertical: isCompactHeight ? 6.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: _TimePalette.woodShelf,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _TimePalette.woodBevel, width: 2.5.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(options.length, (index) {
              final optionText = options[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: _TimeOptionCard(
                    text: optionText,
                    index: index,
                    isSelected: _selectedOption == optionText,
                    isAnswered: state.answerStatus.isAnswered,
                    isCorrect:
                        state.answerStatus == AnswerStatus.correct &&
                        quest.correctAnswer == optionText,
                    isIncorrect:
                        state.answerStatus == AnswerStatus.incorrect &&
                        _selectedOption == optionText,
                    onTap: () => _handleOptionSelection(
                      context,
                      optionText,
                      quest,
                      state,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Swinging Clock Tower Pendulum below shelf
        const _ClockPendulum(),
      ],
    );
  }
}

/// Header banner displaying pedagogical subtype pill and audio speaker button.
class _TimeBadgeHeader extends StatelessWidget {
  final TimeQuestData questData;
  final VoidCallback onSpeakerTap;

  const _TimeBadgeHeader({required this.questData, required this.onSpeakerTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _TimePalette.brassGold.withValues(alpha: 0.6),
          width: 1.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Subtype Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: _TimePalette.brassGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _TimePalette.brassGold.withValues(alpha: 0.35),
                width: 1.r,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(questData.subtypeIcon, style: TextStyle(fontSize: 13.sp)),
                SizedBox(width: 5.w),
                Text(
                  questData.subtypeBadge,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: _TimePalette.brassGold,
                  ),
                ),
              ],
            ),
          ),

          // Speaker Button to replay question
          ScaleButton(
            onTap: onSpeakerTap,
            scaleDown: 0.88,
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: _TimePalette.brassGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: _TimePalette.brassGold,
                size: 19.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An interactive option card that supports dual-mode interaction
/// (Tap-to-Answer and Drag-and-Drop) with multi-line wrapping and balanced typography.
class _TimeOptionCard extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final bool isIncorrect;
  final VoidCallback onTap;

  const _TimeOptionCard({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.isIncorrect,
    required this.onTap,
  });

  String get _optionLabel {
    const labels = ['A', 'B', 'C', 'D'];
    return index < labels.length ? labels[index] : '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    Color cardBg = Colors.white;
    Color borderColor = _TimePalette.optionBorder;
    Color textColor = _TimePalette.textDark;

    if (isCorrect) {
      cardBg = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF16A34A);
      textColor = const Color(0xFF14532D);
    } else if (isIncorrect) {
      cardBg = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFDC2626);
      textColor = const Color(0xFF7F1D1D);
    } else if (isSelected) {
      cardBg = const Color(0xFFFEF3C7);
      borderColor = _TimePalette.brassGold;
    }

    final cardWidget = Container(
      constraints: BoxConstraints(minHeight: 74.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isCorrect || isIncorrect) ? 2.2.r : 1.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Option Label Pill (A, B, C)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _TimePalette.brassGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _optionLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: _TimePalette.brassGold,
                letterSpacing: 0.2,
              ),
            ),
          ),

          SizedBox(height: 5.h),

          // Option Text with clean line wrapping and standard weight
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: text.length > 25 ? 12.sp : 13.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0.1,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ],
      ),
    );

    final tapEnabled = !isAnswered;

    final interactiveWidget = ScaleButton(
      onTap: tapEnabled ? onTap : null,
      scaleDown: 0.94,
      child: cardWidget,
    );

    return Draggable<String>(
      data: text,
      maxSimultaneousDrags: tapEnabled ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 100.w,
          child: Transform.scale(
            scale: 1.08,
            child: Opacity(opacity: 0.92, child: cardWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: cardWidget),
      child: interactiveWidget,
    );
  }
}

/// Rotating steampunk cogwheel in the clock face background.
class _ClockGearWidget extends StatelessWidget {
  final double size;
  final bool clockwise;

  const _ClockGearWidget({required this.size, required this.clockwise});

  @override
  Widget build(BuildContext context) {
    return Icon(
          Icons.settings_rounded,
          color: _TimePalette.brassGold.withValues(alpha: 0.18),
          size: size.r,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(
          duration: 18.seconds,
          begin: clockwise ? 0.0 : 1.0,
          end: clockwise ? 1.0 : 0.0,
        );
  }
}

/// Custom painter for an authentic analog clock face with:
/// - Antique brass bezel with ornamental rivets.
/// - Parchment radial gradient dial.
/// - 60-minute tick graduations (bold major ticks at 5-minute intervals).
/// - Precise Roman / Arabic numerals (1 to 12).
/// - Authentic blued-steel hour and minute hands pointing to exact angles.
/// - Brass center cap.
class _ClockFacePainter extends CustomPainter {
  final int hour;
  final int minute;
  final Color frameColor;
  final bool isHovering;

  _ClockFacePainter({
    required this.hour,
    required this.minute,
    required this.frameColor,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final bezelWidth = isHovering ? 13.0 : 10.0;
    final dialRadius = outerRadius - bezelWidth;

    // 1. Outer Brass Bezel
    final bezelPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bezelWidth;
    canvas.drawCircle(center, outerRadius - (bezelWidth / 2), bezelPaint);

    // 2. Bezel Rivets (12 decorative studs)
    final rivetPaint = Paint()
      ..color = _TimePalette.brassLight
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0) * math.pi / 180.0;
      final rivetOffset = Offset(
        center.dx + (outerRadius - bezelWidth / 2) * math.cos(angle),
        center.dy + (outerRadius - bezelWidth / 2) * math.sin(angle),
      );
      canvas.drawCircle(rivetOffset, 2.0, rivetPaint);
    }

    // 3. Dial Parchment Face with Subtle Radial Gradient
    final dialGradient = RadialGradient(
      colors: [_TimePalette.dialIvory, const Color(0xFFFEF3C7)],
      stops: const [0.65, 1.0],
    );
    final dialPaint = Paint()
      ..shader = dialGradient.createShader(
        Rect.fromCircle(center: center, radius: dialRadius),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dialRadius, dialPaint);

    // 4. Inner Dial Gold Trim Ring
    final innerTrimPaint = Paint()
      ..color = _TimePalette.dialBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, dialRadius - 2, innerTrimPaint);

    // 5. Minute and Hour Tick Marks (60 ticks)
    final majorTickPaint = Paint()
      ..color = _TimePalette.textDark.withValues(alpha: 0.6)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = _TimePalette.textMuted.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6.0) * math.pi / 180.0;
      final isMajor = (i % 5 == 0);
      final tickLength = isMajor ? 7.0 : 3.5;
      final tickStart = Offset(
        center.dx + (dialRadius - 5) * math.cos(angle),
        center.dy + (dialRadius - 5) * math.sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (dialRadius - 5 - tickLength) * math.cos(angle),
        center.dy + (dialRadius - 5 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        isMajor ? majorTickPaint : minorTickPaint,
      );
    }

    // 6. Hour Numerals (1 to 12)
    final numRadius = dialRadius - 18.0;
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30.0 - 90.0) * math.pi / 180.0;
      final numOffset = Offset(
        center.dx + numRadius * math.cos(angle),
        center.dy + numRadius * math.sin(angle),
      );

      final textSpan = TextSpan(
        text: '$i',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: (i % 3 == 0)
              ? _TimePalette.textDark
              : _TimePalette.textDark.withValues(alpha: 0.80),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          numOffset.dx - (textPainter.width / 2),
          numOffset.dy - (textPainter.height / 2),
        ),
      );
    }

    // 7. Calculate Hand Angles
    final effectiveHour = (hour % 12);
    final hourAngle =
        ((effectiveHour + (minute / 60.0)) * 30.0 - 90.0) * math.pi / 180.0;
    final minuteAngle = (minute * 6.0 - 90.0) * math.pi / 180.0;

    // 8. Paint Hour Hand
    final hourHandLength = dialRadius * 0.50;
    final hourHandEnd = Offset(
      center.dx + hourHandLength * math.cos(hourAngle),
      center.dy + hourHandLength * math.sin(hourAngle),
    );
    final hourHandPaint = Paint()
      ..color = _TimePalette.handsSteel
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + const Offset(1.2, 1.8),
      hourHandEnd + const Offset(1.2, 1.8),
      shadowPaint,
    );
    canvas.drawLine(center, hourHandEnd, hourHandPaint);

    // 9. Paint Minute Hand
    final minuteHandLength = dialRadius * 0.72;
    final minuteHandEnd = Offset(
      center.dx + minuteHandLength * math.cos(minuteAngle),
      center.dy + minuteHandLength * math.sin(minuteAngle),
    );
    final minuteHandPaint = Paint()
      ..color = _TimePalette.handsHighlight
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center + const Offset(1.2, 1.8),
      minuteHandEnd + const Offset(1.2, 1.8),
      shadowPaint..strokeWidth = 2.8,
    );
    canvas.drawLine(center, minuteHandEnd, minuteHandPaint);

    // 10. Center Brass Cap Pin
    final capPaint = Paint()
      ..color = _TimePalette.brassGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.5, capPaint);

    final capHighlight = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center - const Offset(1.0, 1.0), 1.4, capHighlight);
  }

  @override
  bool shouldRepaint(covariant _ClockFacePainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.isHovering != isHovering;
  }
}

/// A whimsical swinging brass pendulum beneath the clock shelf.
class _ClockPendulum extends StatelessWidget {
  const _ClockPendulum();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.h,
      child:
          Center(
                child: SizedBox(
                  width: 18.r,
                  height: 20.h,
                  child: Column(
                    children: [
                      // Pendulum rod
                      Container(
                        width: 2.w,
                        height: 10.h,
                        color: _TimePalette.brassGold,
                      ),
                      // Pendulum bob
                      Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _TimePalette.brassLight,
                              _TimePalette.brassGold,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(
                begin: -0.05,
                end: 0.05,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
    );
  }
}
