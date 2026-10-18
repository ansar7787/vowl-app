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

/// Design system color palette for the Professions / Community Helpers Game.
class _ProfessionsPalette {
  _ProfessionsPalette._();

  // Primary Theme: Community Teal
  static const Color primaryTeal = Color(0xFF0D9488); // Teal 600
  static const Color darkTeal = Color(0xFF0F766E); // Teal 700
  static const Color deepTeal = Color(0xFF115E59); // Teal 800
  static const Color softTeal = Color(0xFFCCFBF1); // Teal 100
  static const Color lightTealBg = Color(0xFFF0FDFA); // Teal 50

  // Storefront & Building Architecture
  static const Color buildingFacade = Color(0xFFFFFBEB); // Amber 50
  static const Color buildingTrim = Color(0xFF78350F); // Amber 900
  static const Color woodWarm = Color(0xFF92400E); // Amber 800
  static const Color woodLight = Color(0xFFB45309); // Amber 700
  static const Color awningStripeLight = Colors.white;
  static const Color noticeParchment = Color(0xFFFEF9C3); // Yellow 100
  static const Color noticeBorder = Color(0xFFFDE047); // Yellow 300

  // Clipboard & ID Badge Textures
  static const Color clipboardWood = Color(0xFFD97706); // Amber 600
  static const Color clipSilver = Color(0xFF94A3B8); // Slate 400
  static const Color clipDark = Color(0xFF475569); // Slate 600
  static const Color badgeBorder = Color(0xFFE2E8F0); // Slate 200

  // Interactive Target States
  static const Color hoverTargetGlow = Color(0xFFFBBF24); // Amber 400

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Production-grade Community Helpers & Professions Game Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop to the Career Center storefront,
///   AND accessible tap-to-answer for younger or motor-impaired learners.
/// - Unspoiled clue display: Presents the full community helper scenario on
///   the Town Dispatch Board without prematurely leaking the emoji answer.
/// - Audio scaffolding: Pronounces target career vocabulary on demand and upon
///   submission, with a dedicated speaker icon on both the scenario and options.
/// - Adaptive card layout: Automatically renders compact career ID clipboards
///   for short titles, and wide horizontal dispatch cards for multi-word or
///   sentence-length options (Batches 1-200 safe).
/// - Lifeline integration: Automatically dims a distractor option when `hintUsed`
///   is active to guide struggling children.
/// - Visual hierarchy & 2026 polish: Rich storefront awning, badge clips,
///   tactile shadows, and celebratory status reveals upon correct completion.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees
///   zero RenderFlex overflows across 320dp to tablet dimensions.
///
/// Complexity:
/// - Time Complexity: O(N) where N is options count (typically 3)
/// - Space Complexity: O(1) auxiliary space
class KidsProfessionsLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsProfessionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsProfessionsLayout> createState() => _KidsProfessionsLayoutState();
}

class _KidsProfessionsLayoutState extends State<KidsProfessionsLayout> {
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
        'KidsProfessionsLayout: Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
      );
    }

    // Audio reinforcement: Always pronounce the career name clearly for ESL learners
    di.sl<KidsTTSService>().speak(option, force: true);

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
        'KidsProfessionsLayout: Pronouncing option "$text"',
      );
    }
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsProfessionsLayout: Replaying clue audio for quest "${quest.id}"',
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
      gameType: 'professions',
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

                      // Storefront Target Area
                      _buildCareerStorefront(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 14.h),

                      // Action Instruction Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // Career Options (Clipboards / ID Badges)
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

  /// Storefront Career Center / Town Dispatch Board
  Widget _buildCareerStorefront(
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
              : 'Clue: $instruction. Tap an answer or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _ProfessionsPalette.buildingFacade,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isHovering
                    ? _ProfessionsPalette.hoverTargetGlow
                    : (isCorrect
                        ? _ProfessionsPalette.successBorder
                        : _ProfessionsPalette.buildingTrim),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHovering
                          ? _ProfessionsPalette.hoverTargetGlow
                          : Colors.black)
                      .withValues(alpha: isHovering ? 0.35 : 0.14),
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
                // Striped Awning at the top of the shop
                _buildShopAwning(isHovering: isHovering),

                // Town Header / Dispatch Bar
                _buildDispatchHeader(quest),

                // Main Storefront Display Window
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Striped Roof Awning with drop shadow
  Widget _buildShopAwning({required bool isHovering}) {
    return Container(
      height: 24.h,
      decoration: BoxDecoration(
        color: _ProfessionsPalette.primaryTeal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: List.generate(10, (index) {
          final isEven = index % 2 == 0;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isEven
                    ? _ProfessionsPalette.primaryTeal
                    : _ProfessionsPalette.awningStripeLight,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(8.r),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Dispatch Bar with Town Center Title and Clue Replay Speaker Button
  Widget _buildDispatchHeader(KidsQuest quest) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _ProfessionsPalette.softTeal.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: _ProfessionsPalette.primaryTeal.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: _ProfessionsPalette.primaryTeal,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.work_rounded,
              color: Colors.white,
              size: 15.r,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Community Helpers',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: _ProfessionsPalette.deepTeal,
              ),
            ),
          ),
          // Audio speaker button to listen to the scenario
          Semantics(
            label: 'Listen to the scenario aloud',
            button: true,
            child: ScaleButton(
              onTap: () => _replayQuestionAudio(quest),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _ProfessionsPalette.primaryTeal.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 1.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: _ProfessionsPalette.primaryTeal,
                      size: 16.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Listen',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: _ProfessionsPalette.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Storefront display when the question is actively in progress
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
        // Scenario Bulletin Parchment
        InkWell(
          onTap: () => _replayQuestionAudio(quest),
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: _ProfessionsPalette.noticeParchment,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _ProfessionsPalette.noticeBorder,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h, right: 10.w),
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: _ProfessionsPalette.woodLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: _ProfessionsPalette.woodWarm,
                      size: 18.r,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isNarrow ? 14.5.sp : 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 10.h),

        // Interactive Drop Target Indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _ProfessionsPalette.hoverTargetGlow.withValues(alpha: 0.25)
                : _ProfessionsPalette.lightTealBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHovering
                  ? _ProfessionsPalette.hoverTargetGlow
                  : _ProfessionsPalette.primaryTeal.withValues(alpha: 0.4),
              width: isHovering ? 2.5 : 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isHovering ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isHovering ? Icons.file_download_done_rounded : Icons.badge_outlined,
                  color: isHovering
                      ? _ProfessionsPalette.woodWarm
                      : _ProfessionsPalette.primaryTeal,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  isHovering
                      ? 'Drop here'
                      : 'Tap an answer, or drag it here',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isNarrow ? 12.sp : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _ProfessionsPalette.buildingTrim
                        : _ProfessionsPalette.darkTeal,
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

  /// Storefront display when the question is solved correctly
  Widget _buildSolvedStateDisplay(
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final emoji = quest.emoji ?? '🎖️';
    final answer = quest.correctAnswer ?? '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _ProfessionsPalette.successBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _ProfessionsPalette.successBorder,
          width: 2.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: isNarrow ? 44.sp : 52.sp),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _ProfessionsPalette.successBorder,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Correct!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    KidsFittedText(
                      answer,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isNarrow ? 19.sp : 22.sp,
                        fontWeight: FontWeight.w700,
                        color: _ProfessionsPalette.successText,
                        height: 1.2,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, duration: 250.ms);
  }

  /// Helpful interaction prompt text
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 15.r,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            context.tr(
              'games.kids_professions_drag',
              fallback: 'Choose who can help',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the options section (clipboards / badges)
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? const [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Check if any option is long (> 18 characters)
    final hasLongOption = options.any((opt) => opt.length > 18);

    // If options are long, use horizontal full-width dispatch cards
    if (hasLongOption) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final option = options[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildWideDispatchCard(
              context,
              state,
              quest,
              option,
              index,
              isNarrow: isNarrow,
            ),
          );
        }),
      );
    }

    // Otherwise use authentic wooden clipboards in an adaptive row/wrap
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isNarrow ? 8.w : 12.w,
      runSpacing: 12.h,
      children: List.generate(options.length, (index) {
        final option = options[index];
        return _buildClipboardBadge(
          context,
          state,
          quest,
          option,
          index,
          isNarrow: isNarrow,
        );
      }),
    );
  }

  /// Authentic Wooden Clipboard Option (Archetype A: Short titles)
  Widget _buildClipboardBadge(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String option,
    int index, {
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == option);
    final isCorrectOption = (option == quest.correctAnswer);

    // Lifeline hint support: Dim distractor when hint is used
    final bool isDistractorDimmed = state.hintUsed &&
        !isCorrectOption &&
        (index == 0 || (index == 1 && _optionsFirstIsCorrect(quest)));

    final cardWidth = isNarrow ? 96.w : 106.w;
    final cardHeight = isNarrow ? 116.h : 124.h;

    final clipboardContent = Opacity(
      opacity: isDistractorDimmed ? 0.35 : 1.0,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: _ProfessionsPalette.clipboardWood,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isAnswered && isCorrectOption
                ? _ProfessionsPalette.successBorder
                : (isAnswered && isSelected
                    ? _ProfessionsPalette.errorBorder
                    : _ProfessionsPalette.woodLight),
            width: isAnswered && (isCorrectOption || isSelected) ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              offset: const Offset(0, 5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // White Paper Pad
            Positioned(
              top: 22.h,
              bottom: 8.h,
              left: 7.w,
              right: 7.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: isAnswered && isCorrectOption
                      ? _ProfessionsPalette.successBg
                      : (isAnswered && isSelected
                          ? _ProfessionsPalette.errorBg
                          : Colors.white),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isAnswered && isCorrectOption
                        ? _ProfessionsPalette.successBorder
                        : _ProfessionsPalette.badgeBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isNarrow ? 13.5.sp : 15.sp,
                            fontWeight: FontWeight.w600,
                            color: isAnswered && isCorrectOption
                                ? _ProfessionsPalette.successText
                                : (isAnswered && isSelected
                                    ? _ProfessionsPalette.errorText
                                    : AppColors.slate900),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    ),
                    // Small circular speaker button for pre-readers
                    Semantics(
                      label: 'Hear $option pronounced',
                      button: true,
                      child: GestureDetector(
                        onTap: () => _playOptionAudio(option),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.all(3.5.r),
                          decoration: BoxDecoration(
                            color: _ProfessionsPalette.lightTealBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ProfessionsPalette.primaryTeal
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 13.r,
                            color: _ProfessionsPalette.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Silver Metallic Clip
            Positioned(
              top: 0,
              child: Container(
                width: 38.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: _ProfessionsPalette.clipSilver,
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: _ProfessionsPalette.clipDark,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 18.w,
                    height: 3.5.h,
                    decoration: BoxDecoration(
                      color: _ProfessionsPalette.clipDark,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Draggable & Tappable wrapper
    return Semantics(
      label: '$option. Tap to choose, or drag to the board.',
      button: true,
      enabled: !isAnswered,
      child: ScaleButton(
        onTap: isAnswered
            ? null
            : () => _handleOptionSubmit(context, state, option),
        child: isAnswered
            ? clipboardContent
            : Draggable<String>(
                data: option,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.08,
                    child: Opacity(opacity: 0.95, child: clipboardContent),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: clipboardContent,
                ),
                child: clipboardContent,
              ),
      ),
    );
  }

  /// Wide Dispatch Card (Archetype B: Multi-word or sentence options)
  Widget _buildWideDispatchCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String option,
    int index, {
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == option);
    final isCorrectOption = (option == quest.correctAnswer);

    // Lifeline hint support
    final bool isDistractorDimmed = state.hintUsed &&
        !isCorrectOption &&
        (index == 0 || (index == 1 && _optionsFirstIsCorrect(quest)));

    final cardContent = Opacity(
      opacity: isDistractorDimmed ? 0.35 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isAnswered && isCorrectOption
              ? _ProfessionsPalette.successBg
              : (isAnswered && isSelected
                  ? _ProfessionsPalette.errorBg
                  : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isAnswered && isCorrectOption
                ? _ProfessionsPalette.successBorder
                : (isAnswered && isSelected
                    ? _ProfessionsPalette.errorBorder
                    : _ProfessionsPalette.badgeBorder),
            width: isAnswered && (isCorrectOption || isSelected) ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Career Badge Icon / Index indicator
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: isAnswered && isCorrectOption
                    ? _ProfessionsPalette.successBorder
                    : _ProfessionsPalette.lightTealBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAnswered && isCorrectOption
                      ? _ProfessionsPalette.successBorder
                      : _ProfessionsPalette.primaryTeal.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isAnswered && isCorrectOption
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 18.r)
                    : (isAnswered && isSelected
                        ? Icon(Icons.close_rounded, color: _ProfessionsPalette.errorText, size: 18.r)
                        : Icon(Icons.badge_outlined, color: _ProfessionsPalette.primaryTeal, size: 16.r)),
              ),
            ),
            SizedBox(width: 12.w),
            // Option text (fully wrapping, no ellipsis)
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isNarrow ? 14.sp : 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isAnswered && isCorrectOption
                      ? _ProfessionsPalette.successText
                      : (isAnswered && isSelected
                          ? _ProfessionsPalette.errorText
                          : AppColors.slate900),
                  height: 1.3,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Speaker pronounce icon
            Semantics(
              label: 'Hear $option',
              button: true,
              child: GestureDetector(
                onTap: () => _playOptionAudio(option),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: _ProfessionsPalette.lightTealBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 16.r,
                    color: _ProfessionsPalette.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: '$option. Tap to choose, or drag to the board.',
      button: true,
      enabled: !isAnswered,
      child: ScaleButton(
        onTap: isAnswered
            ? null
            : () => _handleOptionSubmit(context, state, option),
        child: isAnswered
            ? cardContent
            : Draggable<String>(
                data: option,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 320.w,
                    child: Transform.scale(
                      scale: 1.03,
                      child: Opacity(opacity: 0.95, child: cardContent),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.25, child: cardContent),
                child: cardContent,
              ),
      ),
    );
  }

  /// Helper to safely determine whether the first option is correct for hint dimming
  bool _optionsFirstIsCorrect(KidsQuest quest) {
    final options = quest.options;
    if (options == null || options.isEmpty) return false;
    return options.first == quest.correctAnswer;
  }
}
