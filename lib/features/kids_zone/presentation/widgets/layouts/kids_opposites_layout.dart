import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Palette constants for the Opposites Game.
class _OppositesPalette {
  _OppositesPalette._();

  // Warm Chamber (Given Word / Clue)
  static const Color warmBgStart = Color(0xFFFFF7ED); // Orange 50
  static const Color warmBgEnd = Color(0xFFFFEDD5); // Orange 100
  static const Color warmBorder = Color(0xFFFDBA74); // Orange 300
  static const Color warmAccent = Color(0xFFEA580C); // Orange 600
  static const Color warmChipBg = Color(0xFFFFEDD5); // Orange 100
  static const Color warmChipText = Color(0xFF9A3412); // Orange 800

  // Cool Chamber (Opposite Target)
  static const Color coolBgStart = Color(0xFFEFF6FF); // Blue 50
  static const Color coolBgEnd = Color(0xFFDBEAFE); // Blue 100
  static const Color coolBorder = Color(0xFF93C5FD); // Blue 300
  static const Color coolAccent = Color(0xFF2563EB); // Blue 600
  static const Color coolChipBg = Color(0xFFDBEAFE); // Blue 100
  static const Color coolChipText = Color(0xFF1E40AF); // Blue 800

  // Portal Frame & Meridian
  static const Color portalBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color portalDivider = Color(0xFFF1F5F9); // Slate 100
  static const Color meridianGlow = Color(0xFFFDE047); // Yellow 300

  // Card Colors
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFCBD5E1); // Slate 300
  static const Color cardShadow = Color(0xFF94A3B8); // Slate 400

  // Feedback Colors
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Helper for extracting premise antonym clues and story context from curriculum quests.
class OppositesQuestHelper {
  OppositesQuestHelper._();

  static final RegExp _quotedWordRegExp = RegExp(
    '[\u201C\u201D"\'\u2018\u2019]([^\u201C\u201D"\'\u2018\u2019]{1,20})[\u201C\u201D"\'\u2018\u2019]',
  );

  static final RegExp _oppositePatternRegExp = RegExp(
    r"""(?:opposite\s+of|flipping)\s+[\u201C\u201D"'\u2018\u2019]?([A-Za-z]+)[\u201C\u201D"'\u2018\u2019]?""",
    caseSensitive: false,
  );

  static final RegExp _comparisonClauseRegExp = RegExp(
    r'(?:is|was|are|were|felt|looks|looked|sounds|turns|became|says)\s+(?:so\s+)?([A-Za-z]+)(?:,|\.|\s+so|\s+and|\s+that|\s+with)',
    caseSensitive: false,
  );

  static final RegExp _actionVerbLeadRegExp = RegExp(
    r'^(?:The\s+|A\s+|An\s+)?(?:To\s+)?([A-Za-z]+(?:\s+(?:up|in|off|out|away|down))?)\s+(?:means|is|makes|leaves|pulls|lets|starts|ends|puts|takes|carries|slows|has|gives|shows|sit|stand)',
    caseSensitive: false,
  );

  static final RegExp _nounLeadRegExp = RegExp(
    r'^(?:The\s+|A\s+|An\s+)?([A-Za-z]+)\s+(?:water|days|food|light|air|marks|places|slopes|surfaces|sounds|colors|things|seasons|information|times)',
    caseSensitive: false,
  );

  /// Extracts the focal premise word (e.g. "HOT", "BIG", "UP", "IN", "OPEN", "FAST", "PUSH").
  static String extractPremiseWord(KidsQuest quest) {
    final instruction = quest.instruction;

    // 1. Quoted premise word in instruction: e.g. opposite of “hot” -> HOT
    final quoteMatch = _quotedWordRegExp.firstMatch(instruction);
    if (quoteMatch != null) {
      final word = quoteMatch.group(1)?.trim();
      if (word != null && word.isNotEmpty) {
        return word.toUpperCase();
      }
    }

    // 2. Opposite pattern: e.g. "opposite of shallow" -> SHALLOW
    final oppMatch = _oppositePatternRegExp.firstMatch(instruction);
    if (oppMatch != null) {
      final word = oppMatch.group(1)?.trim();
      if (word != null && word.isNotEmpty) {
        return word.toUpperCase();
      }
    }

    // 3. Comparison clause: e.g. "felt gloomy", "looked dim", "was so clear"
    final compMatch = _comparisonClauseRegExp.firstMatch(instruction);
    if (compMatch != null) {
      final word = compMatch.group(1)?.trim();
      if (word != null && word.length >= 2) {
        const stopWords = {'THE', 'A', 'AN', 'NOT', 'VERY', 'MUCH', 'SO'};
        final upper = word.toUpperCase();
        if (!stopWords.contains(upper)) {
          return upper;
        }
      }
    }

    // 4. Action verb lead in explanation: e.g. "To succeed is...", "Parking leaves..."
    final explanation = quest.explanation;
    if (explanation != null && explanation.isNotEmpty) {
      final actMatch = _actionVerbLeadRegExp.firstMatch(explanation);
      if (actMatch != null) {
        final word = actMatch.group(1)?.trim();
        if (word != null && word.length >= 3) {
          const stopWords = {'THE', 'THIS', 'THAT', 'WHEN', 'WITH', 'WHAT'};
          final upper = word.toUpperCase();
          if (!stopWords.contains(upper)) {
            return upper;
          }
        }
      }

      // 5. Noun lead in explanation: e.g. "Clear water...", "Gloomy places..."
      final nounMatch = _nounLeadRegExp.firstMatch(explanation);
      if (nounMatch != null) {
        final word = nounMatch.group(1)?.trim();
        if (word != null && word.length >= 2) {
          const stopWords = {'THE', 'THIS', 'THAT'};
          final upper = word.toUpperCase();
          if (!stopWords.contains(upper)) {
            return upper;
          }
        }
      }
    }

    // 6. Fallback: prompt headline
    return 'CLUE';
  }
}

/// Production-grade Split World Layout for Kids Zone Opposites Game.
///
/// Features:
/// - Split World Dual-Chamber Portal: Premise Realm (Left) + Opposite Realm (Right)
///   connected by an animated Meridian Balance Nexus.
/// - Prominent Premise Clue & Context: Extracts and highlights the target premise word
///   (e.g. "HOT", "BIG", "UP", "IN", "OPEN", "FAST") alongside clean scenario text.
/// - Unspoiled Unanswered State: Answer emoji is hidden until the correct pair is formed,
///   preventing early shape-spoilers or awkward black-silhouette question mark stacks.
/// - Triumphant Harmonic Fusion: Upon correct answer, the portal illuminates with golden
///   aura, the matched plaque snaps in, and the celebratory emoji blooms triumphantly.
/// - Dual Interaction: Full accessible Tap-to-Answer AND smooth Drag-and-Drop support.
/// - Individual Audio Pronunciation: Each option plaque features a speaker button allowing
///   learners to hear how words sound before submitting.
/// - Audio Question Replay: Tapping the Premise realm replays prompt audio via TTS.
/// - Lifeline 50/50 Support: Safely dissolves excess distractor when hint is used.
/// - Responsive & Anti-Clipping: Adapts from 320dp small phones to large tablets without
///   shrinking words to illegible fonts or overflowing.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is number of options (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsOppositesLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsOppositesLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsOppositesLayout> createState() => _KidsOppositesLayoutState();
}

class _KidsOppositesLayoutState extends State<KidsOppositesLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final ValueNotifier<bool> _isHoveringTarget = ValueNotifier<bool>(false);
  String? _selectedOption;
  String? _lastQuestId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isHoveringTarget.dispose();
    super.dispose();
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

    // Audio pronunciation reinforcement
    di.sl<KidsTTSService>().speak(option, force: true);

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'opposites',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        // Reset selection state on quest transition or when unanswered
        if (_lastQuestId != quest.id || !state.answerStatus.isAnswered) {
          _lastQuestId = quest.id;
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 680;

            return Column(
              children: [
                SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),

                // Main Interactive Split World Portal
                Expanded(
                  flex: isCompactHeight ? 6 : 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Center(
                      child: _buildSplitWorldPortal(
                        context,
                        state,
                        quest,
                        isCompactHeight,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isCompactHeight ? 6.h : 12.h),

                // Interactive Action Hint
                _buildActionPrompt(context, state),

                SizedBox(height: isCompactHeight ? 6.h : 10.h),

                // Options Shelf with Dual-Tone Plaques
                Flexible(
                  flex: isCompactHeight ? 4 : 5,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isCompactHeight ? 10.h : 20.h,
                      left: 12.w,
                      right: 12.w,
                    ),
                    child: _buildPlaquesShelf(
                      context,
                      state,
                      quest,
                      isCompactHeight,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds the Split World Dual-Realm Portal.
  Widget _buildSplitWorldPortal(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isCompact,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final premiseWord = OppositesQuestHelper.extractPremiseWord(quest);

    return ValueListenableBuilder<bool>(
      valueListenable: _isHoveringTarget,
      builder: (context, isHovering, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxWidth: 360.w,
            maxHeight: isCompact ? 210.h : 250.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isCorrect
                  ? _OppositesPalette.successBorder
                  : isHovering
                  ? AppColors.indigo500
                  : _OppositesPalette.portalBorder,
              width: isHovering || isCorrect ? 2.5.r : 2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCorrect
                        ? _OppositesPalette.successBorder
                        : isHovering
                        ? AppColors.indigo500
                        : Colors.black)
                    .withValues(alpha: isHovering || isCorrect ? 0.22 : 0.08),
                blurRadius: isHovering || isCorrect ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Realm: The Premise Realm (Given Clue)
                Expanded(
                  child: _buildPremiseRealm(
                    context,
                    quest,
                    premiseWord,
                    isCompact,
                  ),
                ),

                // Center Equilibrium Meridian
                _buildMeridianNexus(isCorrect, isHovering),

                // Right Realm: The Opposite Realm (Drop Target)
                Expanded(
                  child: _buildOppositeRealm(
                    context,
                    state,
                    quest,
                    isHovering,
                    isAnswered,
                    isCorrect,
                    isCompact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds Left Chamber: The Premise Realm (Warm Sun / Clue Realm).
  Widget _buildPremiseRealm(
    BuildContext context,
    KidsQuest quest,
    String premiseWord,
    bool isCompact,
  ) {
    return Semantics(
      label: 'Premise clue: $premiseWord. Double tap to hear instruction.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _replayQuestionAudio(quest),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: isCompact ? 8.h : 12.h,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _OppositesPalette.warmBgStart,
                  _OppositesPalette.warmBgEnd,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top Realm Header Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: _OppositesPalette.warmChipBg,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _OppositesPalette.warmBorder.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    context.tr('games.clue', fallback: 'CLUE'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: _OppositesPalette.warmChipText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Center Premise Word Highlight Card
                Flexible(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _OppositesPalette.warmBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _OppositesPalette.warmAccent.withValues(
                                alpha: 0.1,
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          premiseWord,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 18.sp : 20.sp,
                            fontWeight: FontWeight.w700,
                            color: _OppositesPalette.warmAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Contextual Story / Prompt Subtitle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr(
                        'games.opposite_of',
                        fallback: premiseWord == 'CLUE'
                            ? 'Find the opposite'
                            : 'Opposite of “$premiseWord”',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isCompact ? 11.sp : 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ),

                // Replay Audio Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _OppositesPalette.warmBorder.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 13.r,
                        color: _OppositesPalette.warmAccent,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        context.tr('games.listen', fallback: 'Listen'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: _OppositesPalette.warmChipText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds Center Meridian Nexus connecting the two realms.
  Widget _buildMeridianNexus(bool isCorrect, bool isHovering) {
    return Container(
      width: 24.w,
      decoration: const BoxDecoration(
        color: _OppositesPalette.portalDivider,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical divider line
          Container(
            width: 1.5.w,
            height: double.infinity,
            color: isCorrect
                ? _OppositesPalette.successBorder
                : isHovering
                ? AppColors.indigo400
                : AppColors.slate200,
          ),

          // Central Equilibrium Orb
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: isCorrect ? 1.15 : scale,
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect
                        ? _OppositesPalette.successBorder
                        : isHovering
                        ? AppColors.indigo600
                        : Colors.white,
                    border: Border.all(
                      color: isCorrect
                          ? _OppositesPalette.meridianGlow
                          : _OppositesPalette.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect
                                ? _OppositesPalette.successBorder
                                : Colors.black)
                            .withValues(alpha: isCorrect ? 0.3 : 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isCorrect
                        ? Icon(
                            Icons.check_rounded,
                            size: 14.r,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.swap_horiz_rounded,
                            size: 16.r,
                            color: isHovering
                                ? Colors.white
                                : AppColors.slate500,
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds Right Chamber: The Opposite Realm (Cool Sky / Drop Target).
  Widget _buildOppositeRealm(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isHovering,
    bool isAnswered,
    bool isCorrect,
    bool isCompact,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (isAnswered) return false;
        _isHoveringTarget.value = true;
        di.sl<HapticService>().selection();
        return true;
      },
      onLeave: (data) {
        _isHoveringTarget.value = false;
      },
      onAcceptWithDetails: (details) {
        _isHoveringTarget.value = false;
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: isCompact ? 8.h : 12.h,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _OppositesPalette.coolBgStart,
                _OppositesPalette.coolBgEnd,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Top Realm Header Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: _OppositesPalette.coolChipBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _OppositesPalette.coolBorder.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                child: Text(
                  context.tr('games.opposite', fallback: 'OPPOSITE'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _OppositesPalette.coolChipText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Center Drop Target Slot / Triumphant Reveal
              Flexible(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isCorrect
                        ? _buildTriumphantOppositeSlot(quest, isCompact)
                        : _buildAwaitingOppositeSlot(
                            context,
                            isHovering,
                            isCompact,
                          ),
                  ),
                ),
              ),

              // Bottom Target Guidance Subtitle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? _OppositesPalette.successBg
                      : isHovering
                      ? _OppositesPalette.coolAccent
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isCorrect
                        ? _OppositesPalette.successBorder.withValues(alpha: 0.5)
                        : isHovering
                        ? Colors.white
                        : _OppositesPalette.coolBorder.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Text(
                  isCorrect
                      ? context.tr('games.matched', fallback: 'Matched')
                      : isHovering
                      ? context.tr('games.drop_now', fallback: 'Drop here')
                      : context.tr(
                          'games.drop_target',
                          fallback: 'Drop opposite here',
                        ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isCorrect
                        ? _OppositesPalette.successText
                        : isHovering
                        ? Colors.white
                        : _OppositesPalette.coolChipText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the slot awaiting player input (unanswered state).
  Widget _buildAwaitingOppositeSlot(
    BuildContext context,
    bool isHovering,
    bool isCompact,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: isCompact ? 10.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: isHovering
            ? _OppositesPalette.coolChipBg
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isHovering
              ? _OppositesPalette.coolAccent
              : _OppositesPalette.coolBorder,
          width: isHovering ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isHovering ? _OppositesPalette.coolAccent : Colors.black)
                .withValues(alpha: isHovering ? 0.15 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final dy = math.sin(_pulseController.value * math.pi) * 2;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 26.sp : 30.sp,
                fontWeight: FontWeight.w700,
                color: isHovering
                    ? _OppositesPalette.coolAccent
                    : AppColors.slate400,
                height: 1.0,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the slot upon correct answer completion (triumphant reveal).
  Widget _buildTriumphantOppositeSlot(KidsQuest quest, bool isCompact) {
    final emoji = quest.emoji;
    final answer = quest.correctAnswer ?? '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: isCompact ? 6.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: _OppositesPalette.successBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _OppositesPalette.successBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _OppositesPalette.successBorder.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null && emoji.isNotEmpty)
            Text(
              emoji,
              style: TextStyle(fontSize: isCompact ? 28.sp : 32.sp),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          SizedBox(height: 2.h),
          Text(
            answer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 18.sp : 20.sp,
              fontWeight: FontWeight.w700,
              color: _OppositesPalette.successText,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Action Prompt beneath the Split World Portal.
  Widget _buildActionPrompt(BuildContext context, KidsLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: KidsFittedText(
        context.tr(
          'games.kids_opposites_prompt',
          fallback: 'Tap or drag the matching opposite',
        ),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.9)
              : AppColors.slate700,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Shelf holding the Antonym Option Cards.
  Widget _buildPlaquesShelf(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isCompact,
  ) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    final isAnswered = state.answerStatus.isAnswered;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isCorrect = (option == quest.correctAnswer);

          // 50/50 Lifeline removal: if hint is used and this is a distractor, dissolve it
          bool isRemovedByLifeline = false;
          if (state.hintUsed && !isCorrect && options.length > 2) {
            final distractors = options
                .where((o) => o != quest.correctAnswer)
                .toList();
            if (distractors.isNotEmpty && option == distractors.first) {
              isRemovedByLifeline = true;
            }
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildOptionPlaque(
                context,
                state,
                option,
                isCorrect,
                isAnswered,
                isRemovedByLifeline,
                index,
                isCompact,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Builds an individual Antonym Option Card with Tap, Drag, and Audio.
  Widget _buildOptionPlaque(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    bool isAnswered,
    bool isRemovedByLifeline,
    int index,
    bool isCompact,
  ) {
    final isSelected = (_selectedOption == text);
    final isSuccessState = isAnswered && isCorrect;
    final isErrorState = isAnswered && isSelected && !isCorrect;

    final cardWidget = Container(
      height: isCompact ? 64.h : 72.h,
      decoration: BoxDecoration(
        color: isSuccessState
            ? _OppositesPalette.successBg
            : isErrorState
            ? _OppositesPalette.errorBg
            : _OppositesPalette.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isSuccessState
              ? _OppositesPalette.successBorder
              : isErrorState
              ? _OppositesPalette.errorBorder
              : _OppositesPalette.cardBorder,
          width: isSuccessState || isErrorState ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSuccessState
                    ? _OppositesPalette.successBorder
                    : isErrorState
                    ? _OppositesPalette.errorBorder
                    : _OppositesPalette.cardShadow)
                .withValues(alpha: isSuccessState || isErrorState ? 0.25 : 0.35),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            // Speaker button at top-right to preview audio without submitting
            Positioned(
              top: 4.h,
              right: 4.w,
              child: Semantics(
                label: 'Listen to $text',
                button: true,
                child: InkWell(
                  onTap: isAnswered ? null : () => _playOptionAudio(text),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 14.r,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ),
            ),

            // Success Checkmark Badge at top-left
            if (isSuccessState)
              Positioned(
                top: 6.h,
                left: 6.w,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _OppositesPalette.successBorder,
                  size: 16.r,
                ),
              ),

            // Content: Option Word Text
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 15.sp : 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isSuccessState
                          ? _OppositesPalette.successText
                          : isErrorState
                          ? _OppositesPalette.errorText
                          : AppColors.slate800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // If eliminated by 50/50 lifeline, dissolve smoothly
    if (isRemovedByLifeline) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 0.0,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 500),
          scale: 0.6,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(child: cardWidget),
        ),
      );
    }

    // Draggable & Tappable Card
    return Semantics(
      label: 'Option: $text. Tap to choose or drag to opposite target.',
      button: true,
      enabled: !isAnswered,
      child: Draggable<String>(
        data: text,
        maxSimultaneousDrags: isAnswered ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 100.w,
            child: Transform.scale(
              scale: 1.05,
              child: Opacity(
                opacity: 0.95,
                child: cardWidget,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
        child: ScaleButton(
          onTap: isAnswered
              ? null
              : () => _handleOptionSubmit(context, state, text),
          child: cardWidget,
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (index * 80).ms,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
