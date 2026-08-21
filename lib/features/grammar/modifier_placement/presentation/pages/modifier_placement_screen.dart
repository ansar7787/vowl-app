import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_placement_instruction.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_magnetic_arena.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class ModifierPlacementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModifierPlacementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modifierPlacement,
  });

  @override
  State<ModifierPlacementScreen> createState() =>
      _ModifierPlacementScreenState();
}

class _ModifierPlacementScreenState extends State<ModifierPlacementScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _targetIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _pendingJigsaw = false;
  String? _assembledSentence;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(GrammarQuest quest) {
    if (_isAnswered || _targetIndex == -1 || _pendingJigsaw) return;

    final allWords = quest.shuffledWords ?? [];
    if (allWords.isEmpty) return;

    final modifier = allWords[0];
    final words = allWords.skip(1).toList();

    final resultingWords = List<String>.from(words);
    resultingWords.insert(_targetIndex, modifier);

    final result = resultingWords
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    bool isCorrect =
        result.toLowerCase() == (quest.correctAnswer ?? "").toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _assembledSentence = result;
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _assembledSentence = result;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    setState(() => _pendingJigsaw = false);
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _targetIndex = -1;
              _pendingJigsaw = false;
              _assembledSentence = null;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTAX SHAPER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest as GrammarQuest? : null;
        final allWords = quest?.shuffledWords ?? [];
        if (allWords.isEmpty) return const SizedBox();

        final modifier = allWords[0];
        final words = allWords.skip(1).toList();

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_assembledSentence != null) {
            cleanTargetSentence = _assembledSentence!;
          }
        }

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false, // Stack needs finite space to anchor to bottom
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (isCompact ? 50.h : 80.h) +
                            (isCompact ? 100.h : 180.h) +
                            (isCompact ? 40.h : 60.h) +
                            (isCompact ? 40.h : 65.h) +
                            40.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 5
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(4.0, 15.0)
                            : 4.0;
                        final double gapMiddle = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(6.0, 20.0)
                            : 6.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2.5).clamp(10.0, 30.0)
                            : 10.0;

                        return Column(
                          children: [
                            SizedBox(height: gapTop),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ModifierPlacementInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : ModifierPlacementInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: gapMiddle),

                            if (quest.modifierType != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  "MODIFIER: ${quest.modifierType!.toUpperCase()}",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms),
                              SizedBox(height: isCompact ? 12.h : 20.h),
                            ],

                            // Context Card
                            Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      isCompact ? 14.r : 22.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 18.r : 28.r,
                                      ),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      "Insert the modifier '$modifier' into the correct position.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: isCompact ? 14.sp : 18.sp,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0),

                            // Result Feedback
                            if (_isAnswered) ...[
                              SizedBox(height: isCompact ? 8.h : 24.h),
                              _buildResult(
                                quest,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ],

                            // Magnetic Arena
                            Expanded(
                              child: Center(
                                child: ModifierMagneticArena(
                                  words: words,
                                  modifier: modifier,
                                  targetIndex: _targetIndex,
                                  isAnswered: _isAnswered || _pendingJigsaw,
                                  isDark: isDark,
                                  primaryColor: theme.primaryColor,
                                  onSlotAccepted: (idx) =>
                                      setState(() => _targetIndex = idx),
                                  onSlotReset: () =>
                                      setState(() => _targetIndex = -1),
                                  isCompact: isCompact,
                                ),
                              ),
                            ),

                            // Draggable Magnet
                            if (!_isAnswered &&
                                !_pendingJigsaw &&
                                _targetIndex == -1)
                              Draggable<String>(
                                data: modifier,
                                feedback: _buildTactileMagnet(
                                  modifier,
                                  theme.primaryColor,
                                  isDragging: true,
                                  isCompact: isCompact,
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.2,
                                  child: _buildTactileMagnet(
                                    modifier,
                                    theme.primaryColor,
                                    isCompact: isCompact,
                                  ),
                                ),
                                child: _buildTactileMagnet(
                                  modifier,
                                  theme.primaryColor,
                                  isCompact: isCompact,
                                ),
                              ).animate().scale(
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                              ),

                            // Submit Button
                            if (!_isAnswered &&
                                !_pendingJigsaw &&
                                _targetIndex != -1) ...[
                              SizedBox(height: isCompact ? 8.h : 16.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: ScaleButton(
                                  onTap: () => _submitAnswer(quest),
                                  child: Container(
                                    width: double.infinity,
                                    height: isCompact ? 48.h : 65.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 14.r : 24.r,
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primaryColor,
                                          theme.primaryColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 25,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        "FINALIZE SYNTAX",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: isCompact ? 13.sp : 16.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            SizedBox(height: gapBottom),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                        displayText: "Type the complete sentence to lock it in",
                      ),
                    SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                  ],
                ),
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _buildTactileMagnet(
    String modifier,
    Color primaryColor, {
    bool isDragging = false,
    bool isCompact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: isCompact
            ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h)
            : EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(isCompact ? 14.r : 20.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: isDragging ? 25 : 12,
              offset: isDragging ? const Offset(0, 10) : const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          modifier,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompact ? 15.sp : 20.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12.r : 24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: displayColor,
              size: isCompact ? 24.r : 40.r,
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              "CORRECT SYNTAX:",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 10.sp : 12.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: isCompact ? 2.h : 6.h),
            Text(
              quest.correctAnswer ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 15.sp : 20.sp,
                fontWeight: FontWeight.w600,
                color: displayColor,
              ),
            ),
            if (!isCompact && quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
