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
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Design system palette for the Classroom & School Game.
/// Warm wooden schoolhouse trim with rich emerald chalkboard.
class _SchoolPalette {
  _SchoolPalette._();

  // Classroom Chalkboard
  static const Color chalkboardDeep = Color(0xFF0F241A);
  static const Color chalkboardSurface = Color(0xFF1B382B);
  static const Color chalkboardBorder = Color(0xFF285440);
  static const Color chalkboardHeader = Color(0xFF142E23);

  // Oak Wood Schoolhouse Trim
  static const Color woodDark = Color(0xFF5C2C16);
  static const Color woodWarm = Color(0xFF8B4513);
  static const Color woodTrim = Color(0xFFD48B47);

  // Chalk Colors & Accents
  static const Color chalkWhite = Color(0xFFF8FAFC);
  static const Color chalkYellow = Color(0xFFFEF08A);
  static const Color chalkGold = Color(0xFFFBBF24);
  static const Color chalkCyan = Color(0xFF7DD3FC);

  // Chalk Tray Elements
  static const Color trayWood = Color(0xFF4A2411);
  static const Color chalkStickWhite = Color(0xFFE2E8F0);
  static const Color chalkStickYellow = Color(0xFFFDE047);
  static const Color chalkStickBlue = Color(0xFF93C5FD);
  static const Color eraserFelt = Color(0xFF334155);
  static const Color eraserWood = Color(0xFF94A3B8);

  // School Desk Cards
  static const Color deskCardBg = Color(0xFFFFFDF5);
  static const Color deskCardBorder = Color(0xFFE5DAC9);
  static const Color deskShadow = Color(0x2A45260A);
  static const Color hoverTargetGlow = Color(0xFFFBBF24);

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Emerald 100
  static const Color successBorder = Color(0xFF16A34A); // Emerald 600
  static const Color successText = Color(0xFF15803D); // Emerald 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Parsed metadata for an option card in the School Game.
/// Separates the visual emoji from the pedagogical title string while
/// preserving the raw value for state-level answer verification.
class SchoolOptionData {
  final String raw;
  final String title;
  final String? emoji;

  const SchoolOptionData({
    required this.raw,
    required this.title,
    this.emoji,
  });

  factory SchoolOptionData.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return SchoolOptionData(raw: text, title: text);
    }

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
      return SchoolOptionData(
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
      return SchoolOptionData(
        raw: text,
        title: cleanTitle.isNotEmpty ? cleanTitle : text,
        emoji: emojiChars.isNotEmpty ? emojiChars : null,
      );
    }

    return SchoolOptionData(raw: text, title: trimmed);
  }
}

/// Production-grade School & Classroom Game Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop to the Classroom Chalkboard,
///   AND accessible tap-to-answer for younger learners or motor-impaired kids.
/// - Unspoiled clue display: Presents the full riddle and question on the
///   Classroom Chalkboard without prematurely leaking the emoji answer silhouette.
/// - Multimodal audio scaffolding: Dedicated speaker icon on the riddle chalkboard
///   and on every individual school card for clear vocabulary pronunciation.
/// - Adaptive card layout: Dynamically renders compact school desk cards for
///   short titles, and wide horizontal message cards for sentence-length options
///   (safely handles Batches 1 to 20).
/// - Lifeline integration: Automatically dims a distractor option when `hintUsed`
///   is active to scaffold struggling learners.
/// - 2026 Visual Polish: Warm oak wood trim, chalk dust tray with chalks & eraser,
///   tactile shadows, and celebratory status reveals upon correct completion.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees
///   zero RenderFlex overflows across 320dp to tablet dimensions.
///
/// Complexity:
/// - Time Complexity: O(N) where N is options count (typically 3)
/// - Space Complexity: O(1) auxiliary space
class KidsSchoolLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsSchoolLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsSchoolLayout> createState() => _KidsSchoolLayoutState();
}

class _KidsSchoolLayoutState extends State<KidsSchoolLayout> {
  String? _selectedOption;
  String? _lastQuestId;

  void _syncStateWithQuest(KidsQuest currentQuest) {
    if (_lastQuestId != currentQuest.id) {
      _lastQuestId = currentQuest.id;
      _selectedOption = null;
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Syncing state with quest "${currentQuest.id}" (level ${currentQuest.level})',
          tag: 'KidsSchoolLayout',
        );
      }
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
        tag: 'KidsSchoolLayout',
      );
    }

    // Audio reinforcement: Pronounce the clean word clearly for ESL learners
    final parsed = SchoolOptionData.parse(option);
    final speakText = parsed.title.isNotEmpty ? parsed.title : option;
    di.sl<KidsTTSService>().speak(speakText, force: true);

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final parsed = SchoolOptionData.parse(text);
    final speakText = parsed.title.isNotEmpty ? parsed.title : text;
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing option "$speakText"',
        tag: 'KidsSchoolLayout',
      );
    }
    di.sl<KidsTTSService>().speak(speakText, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying clue audio for quest "${quest.id}"',
          tag: 'KidsSchoolLayout',
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
      gameType: 'school',
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
                      SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),

                      // Classroom Chalkboard Target Area
                      _buildClassroomChalkboard(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 14.h),

                      // Interaction Prompt Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // School Supply & Lesson Options
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

  /// Classroom Chalkboard Target Area with Wood Trim and Chalk Tray
  Widget _buildClassroomChalkboard(
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
              ? 'Correct: ${quest.correctAnswer}'
              : 'Classroom Clue: $instruction. Tap an answer or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _SchoolPalette.woodWarm,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isHovering
                    ? _SchoolPalette.hoverTargetGlow
                    : (isCorrect
                        ? _SchoolPalette.successBorder
                        : _SchoolPalette.woodDark),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHovering
                          ? _SchoolPalette.hoverTargetGlow
                          : Colors.black)
                      .withValues(alpha: isHovering ? 0.35 : 0.16),
                  blurRadius: isHovering ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Blackboard Top Header
                _buildChalkboardHeader(quest),

                // Chalkboard Surface
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: const BoxDecoration(
                    color: _SchoolPalette.chalkboardDeep,
                  ),
                  child: isCorrect
                      ? _buildSolvedStateDisplay(quest, isNarrow: isNarrow)
                      : _buildPromptStateDisplay(
                          quest,
                          instruction,
                          isHovering: isHovering,
                          isNarrow: isNarrow,
                        ),
                ),

                // Chalk Dust Tray with Chalk Sticks & Eraser
                _buildChalkTray(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Header Bar with School Bell Icon, Title, and Replay Audio Button
  Widget _buildChalkboardHeader(KidsQuest quest) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: const BoxDecoration(
        color: _SchoolPalette.chalkboardHeader,
        border: Border(
          bottom: BorderSide(
            color: _SchoolPalette.chalkboardBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              color: _SchoolPalette.woodWarm,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _SchoolPalette.woodTrim.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 16.r,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Classroom Clue',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: _SchoolPalette.chalkYellow,
              ),
            ),
          ),
          // Clue Audio Replay Button
          ScaleButton(
            onTap: () => _replayQuestionAudio(quest),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: _SchoolPalette.woodDark,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _SchoolPalette.woodTrim.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: _SchoolPalette.chalkGold,
                    size: 15.r,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Listen',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Solved State inside Blackboard: Celebratory Badge, Emoji & Answer Name
  Widget _buildSolvedStateDisplay(
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final parsed = SchoolOptionData.parse(quest.correctAnswer ?? '');
    final displayEmoji = quest.emoji ?? parsed.emoji ?? '🎓';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _SchoolPalette.chalkboardSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _SchoolPalette.chalkGold,
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: _SchoolPalette.chalkGold,
                  size: 18.r,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Well done!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: _SchoolPalette.chalkYellow,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.star_rounded,
                  color: _SchoolPalette.chalkGold,
                  size: 18.r,
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            displayEmoji,
            style: TextStyle(fontSize: isNarrow ? 54.sp : 64.sp),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
              ),
          SizedBox(height: 8.h),
          KidsFittedText(
            parsed.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Active Question State inside Blackboard: Riddle Clue and Target Drop Zone
  Widget _buildPromptStateDisplay(
    KidsQuest quest,
    String instruction, {
    required bool isHovering,
    required bool isNarrow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Teacher's Chalkboard Riddle Clue
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _SchoolPalette.chalkboardSurface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _SchoolPalette.chalkboardBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    color: _SchoolPalette.chalkGold,
                    size: 15.r,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Teacher asks:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: _SchoolPalette.chalkYellow,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                instruction.isNotEmpty
                    ? instruction
                    : 'Find the matching school item for your lesson!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isNarrow ? 14.sp : 14.5.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: _SchoolPalette.chalkWhite,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Chalkboard Target Desk Drop Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _SchoolPalette.hoverTargetGlow.withValues(alpha: 0.18)
                : _SchoolPalette.chalkboardDeep,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isHovering
                  ? _SchoolPalette.hoverTargetGlow
                  : _SchoolPalette.chalkCyan.withValues(alpha: 0.5),
              width: isHovering ? 2.5.w : 1.5.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHovering ? Icons.check_circle_rounded : Icons.backpack_rounded,
                color: isHovering ? _SchoolPalette.chalkGold : _SchoolPalette.chalkCyan,
                size: 22.r,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  isHovering
                      ? 'Place on the desk'
                      : 'Drag here or tap below',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering ? _SchoolPalette.chalkYellow : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Wooden Chalk Dust Tray with Colored Chalks & Eraser
  Widget _buildChalkTray() {
    return Container(
      height: 16.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: const BoxDecoration(
        color: _SchoolPalette.trayWood,
        border: Border(
          top: BorderSide(
            color: _SchoolPalette.woodDark,
            width: 1.5,
          ),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 260.w,
          child: Row(
            children: [
              // White Chalk Stick
              Container(
                width: 22.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: _SchoolPalette.chalkStickWhite,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(width: 8.w),
              // Yellow Chalk Stick
              Container(
                width: 20.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: _SchoolPalette.chalkStickYellow,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(width: 8.w),
              // Blue Chalk Stick
              Container(
                width: 18.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: _SchoolPalette.chalkStickBlue,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              const Spacer(),
              // Wooden Blackboard Eraser
              Container(
                width: 32.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: _SchoolPalette.eraserWood,
                  borderRadius: BorderRadius.circular(2.r),
                  border: Border.all(
                    color: _SchoolPalette.eraserFelt,
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Instructional prompt banner below the blackboard
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app_rounded,
          color: _SchoolPalette.chalkGold,
          size: 16.r,
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            context.tr(
              'games.kids_school_prompt',
              fallback: 'Tap an answer or drag it to the board',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Options Section: dynamically switches to wide scenario cards for long text,
  /// or compact tactile cards for short items.
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? const [];
    if (options.isEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Quest "${quest.id}" has empty options list',
          tag: 'KidsSchoolLayout',
        );
      }
      return const SizedBox.shrink();
    }

    // Check if any option is long (sentence/scenario, e.g. Batch 20)
    final hasLongOption = options.any((opt) {
      final parsed = SchoolOptionData.parse(opt);
      return parsed.title.length > 25 || parsed.title.split(' ').length > 3;
    });

    // Scaffolding: Dim an incorrect distractor if hintUsed is active
    String? distractorToDim;
    if (state.hintUsed && options.length > 2) {
      final incorrectOptions = options
          .where((opt) => opt != quest.correctAnswer && opt != _selectedOption)
          .toList();
      if (incorrectOptions.isNotEmpty) {
        distractorToDim = incorrectOptions.first;
      }
    }

    if (hasLongOption) {
      return Column(
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isDimmed = (option == distractorToDim);
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _buildWideOptionCard(
              context,
              state,
              quest,
              option,
              index: index,
              isDimmed: isDimmed,
              isNarrow: isNarrow,
            ),
          );
        }),
      );
    }

    // Grid / Row layout for concise school supplies and vocabulary items
    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final crossAxisCount = (options.length == 4) ? 2 : options.length;
        if (crossAxisCount == 3) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isDimmed = (option == distractorToDim);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _buildCompactOptionCard(
                    context,
                    state,
                    quest,
                    option,
                    index: index,
                    isDimmed: isDimmed,
                    isNarrow: isNarrow,
                  ),
                ),
              );
            }),
          );
        }

        // 2x2 grid fallback for 4 options
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isDimmed = (option == distractorToDim);
            final itemWidth = (cardConstraints.maxWidth - 8.w) / 2;
            return SizedBox(
              width: itemWidth,
              child: _buildCompactOptionCard(
                context,
                state,
                quest,
                option,
                index: index,
                isDimmed: isDimmed,
                isNarrow: isNarrow,
              ),
            );
          }),
        );
      },
    );
  }

  /// Compact School Supply / Desk Card (concise items)
  Widget _buildCompactOptionCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String option, {
    required int index,
    required bool isDimmed,
    required bool isNarrow,
  }) {
    final parsed = SchoolOptionData.parse(option);
    final isSelected = (_selectedOption == option);
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrectOption = (option == quest.correctAnswer);

    Color cardBorder = _SchoolPalette.deskCardBorder;
    Color cardBg = _SchoolPalette.deskCardBg;
    Color textColor = AppColors.slate900;

    if (isSelected) {
      if (isCorrectOption) {
        cardBorder = _SchoolPalette.successBorder;
        cardBg = _SchoolPalette.successBg;
        textColor = _SchoolPalette.successText;
      } else {
        cardBorder = _SchoolPalette.errorBorder;
        cardBg = _SchoolPalette.errorBg;
        textColor = _SchoolPalette.errorText;
      }
    } else if (isAnswered && isCorrectOption) {
      cardBorder = _SchoolPalette.successBorder.withValues(alpha: 0.6);
      cardBg = _SchoolPalette.successBg.withValues(alpha: 0.6);
      textColor = _SchoolPalette.successText;
    }

    final cardContent = Container(
      constraints: BoxConstraints(
        minHeight: isNarrow ? 102.h : 112.h,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cardBorder,
          width: isSelected ? 2.5.w : 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _SchoolPalette.deskShadow,
            offset: Offset(0, isSelected ? 2 : 4),
            blurRadius: isSelected ? 4 : 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji Illustration
          if (parsed.emoji != null && parsed.emoji!.isNotEmpty) ...[
            Text(
              parsed.emoji!,
              style: TextStyle(fontSize: isNarrow ? 26.sp : 30.sp),
            ),
            SizedBox(height: 4.h),
          ],

          // Title Label
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: KidsFittedText(
              parsed.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: textColor,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 5.h),

          // Speaker Audio Pronunciation Button
          Semantics(
            label: 'Pronounce ${parsed.title}',
            button: true,
            child: GestureDetector(
              onTap: () => _playOptionAudio(option),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(3.5.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _SchoolPalette.deskCardBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: _SchoolPalette.woodWarm,
                  size: 13.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isAnswered) {
      return Opacity(
        opacity: isDimmed ? 0.35 : 1.0,
        child: cardContent,
      );
    }

    return Opacity(
      opacity: isDimmed ? 0.35 : 1.0,
      child: IgnorePointer(
        ignoring: isDimmed,
        child: Draggable<String>(
          data: option,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 100.w,
              child: Transform.scale(
                scale: 1.05,
                child: cardContent,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: cardContent,
          ),
          child: GestureDetector(
            onTap: () => _handleOptionSubmit(context, state, option),
            behavior: HitTestBehavior.translucent,
            child: cardContent,
          ),
        ),
      ),
    );
  }

  /// Wide Option Card (for sentence / dialogue / message options like Batch 20)
  Widget _buildWideOptionCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String option, {
    required int index,
    required bool isDimmed,
    required bool isNarrow,
  }) {
    final parsed = SchoolOptionData.parse(option);
    final isSelected = (_selectedOption == option);
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrectOption = (option == quest.correctAnswer);

    Color cardBorder = _SchoolPalette.deskCardBorder;
    Color cardBg = _SchoolPalette.deskCardBg;
    Color textColor = AppColors.slate900;

    if (isSelected) {
      if (isCorrectOption) {
        cardBorder = _SchoolPalette.successBorder;
        cardBg = _SchoolPalette.successBg;
        textColor = _SchoolPalette.successText;
      } else {
        cardBorder = _SchoolPalette.errorBorder;
        cardBg = _SchoolPalette.errorBg;
        textColor = _SchoolPalette.errorText;
      }
    } else if (isAnswered && isCorrectOption) {
      cardBorder = _SchoolPalette.successBorder.withValues(alpha: 0.6);
      cardBg = _SchoolPalette.successBg.withValues(alpha: 0.6);
      textColor = _SchoolPalette.successText;
    }

    final cardContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cardBorder,
          width: isSelected ? 2.5.w : 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _SchoolPalette.deskShadow,
            offset: Offset(0, isSelected ? 2 : 4),
            blurRadius: isSelected ? 4 : 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (parsed.emoji != null && parsed.emoji!.isNotEmpty) ...[
            Text(
              parsed.emoji!,
              style: TextStyle(fontSize: 22.sp),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              parsed.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Semantics(
            label: 'Pronounce ${parsed.title}',
            button: true,
            child: GestureDetector(
              onTap: () => _playOptionAudio(option),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _SchoolPalette.deskCardBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: _SchoolPalette.woodWarm,
                  size: 14.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isAnswered) {
      return Opacity(
        opacity: isDimmed ? 0.35 : 1.0,
        child: cardContent,
      );
    }

    return Opacity(
      opacity: isDimmed ? 0.35 : 1.0,
      child: IgnorePointer(
        ignoring: isDimmed,
        child: Draggable<String>(
          data: option,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 280.w,
              child: Transform.scale(
                scale: 1.03,
                child: cardContent,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: cardContent,
          ),
          child: GestureDetector(
            onTap: () => _handleOptionSubmit(context, state, option),
            behavior: HitTestBehavior.translucent,
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
