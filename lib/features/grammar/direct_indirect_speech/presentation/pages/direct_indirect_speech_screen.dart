import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_instruction.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_mirror.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';
import 'package:vowl/core/utils/locale_service.dart';

class DirectIndirectSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DirectIndirectSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.directIndirectSpeech,
  });

  @override
  State<DirectIndirectSpeechScreen> createState() =>
      _DirectIndirectSpeechScreenState();
}

class _DirectIndirectSpeechScreenState
    extends State<DirectIndirectSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _rotation = 0.0;
  int _selectedReflection = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onReflectionSelect(int index, int correctIndex) {
    if (_isAnswered || _isFirstStagePassed) return;
    setState(() => _selectedReflection = index);

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
        _rotation = 3.14;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _rotation = 3.14;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });
    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
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
              _isFirstStagePassed = false;
              _selectedReflection = -1;
              _rotation = 0.0;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            // FIX: was `state.lastAnswerCorrect != null` and `state.lastAnswerCorrect`
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
            title: 'SHADOW MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final rawQuestion = quest?.question ?? "DIRECT SPEECH";
        String displayDirect = quest?.sentence ?? "";
        if (displayDirect.isEmpty) {
          if (rawQuestion.contains(':')) {
            displayDirect = rawQuestion
                .split(':')
                .last
                .replaceAll('"', '')
                .trim();
          } else {
            displayDirect = rawQuestion;
          }
        }

        String displayIndirect = quest?.correctAnswer ?? "";
        if (displayIndirect.isEmpty &&
            quest != null &&
            quest.options != null &&
            (quest.correctAnswerIndex ?? 0) < quest.options!.length) {
          displayIndirect = quest.options![quest.correctAnswerIndex!];
        }
        if (displayIndirect.isEmpty) displayIndirect = "INDIRECT SPEECH";

        final options = quest?.options ?? ["REF A", "REF B", "REF C"];

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
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
                                    (isCompact ? 130.h : 180.h) +
                                    (isCompact ? 30.h : 50.h) +
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
                                              child:
                                                  DirectIndirectSpeechInstruction(
                                                    primaryColor:
                                                        theme.primaryColor,
                                                  ),
                                            ),
                                          )
                                        : DirectIndirectSpeechInstruction(
                                            primaryColor: theme.primaryColor,
                                          ),
                                    SizedBox(height: gapMiddle),

                                    // Holographic Mirror
                                    DirectIndirectSpeechMirror(
                                      rotation: _rotation,
                                      directText: displayDirect,
                                      indirectText: displayIndirect,
                                      isCorrect: _isCorrect,
                                      isDark: isDark,
                                      primaryColor: theme.primaryColor,
                                      isCompact: isCompact,
                                    ),

                                    SizedBox(height: isCompact ? 12.h : 30.h),

                                    // Reflection Options
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: [
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: isCompact ? 8.w : 12.w,
                                              runSpacing: isCompact
                                                  ? 8.h
                                                  : 12.h,
                                              children: List.generate(
                                                options.length,
                                                (i) => _buildReflectionChip(
                                                  options[i],
                                                  i,
                                                  quest.correctAnswerIndex ?? 0,
                                                  theme.primaryColor,
                                                  isDark,
                                                  isCompact,
                                                ),
                                              ),
                                            ),
                                            if (_isAnswered) ...[
                                              SizedBox(
                                                height: isCompact ? 12.h : 30.h,
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                ),
                                                child: _buildCorrectResult(
                                                  quest,
                                                  theme.primaryColor,
                                                  isDark,
                                                  isCompact,
                                                ),
                                              ),
                                            ],
                                            SizedBox(height: gapBottom),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (_isFirstStagePassed && !_isAnswered)
                            TypeToConfirmOverlay(
                              expectedText: options[_selectedReflection],
                              primaryColor: theme.primaryColor,
                              onConfirmed: () => _submitVerbalEvaluation(true),
                              onSkipped: () => _submitVerbalEvaluation(false),
                              isPositioned: false,
                            ),
                          SizedBox(
                            height: (_isAnswered || _isFirstStagePassed)
                                ? 160.h
                                : 60.h,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReflectionChip(
    String text,
    int index,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final isSelected = _selectedReflection == index;
    final isCorrect = _isAnswered && index == correctIndex;
    final isWrong = _isAnswered && isSelected && index != correctIndex;

    return ScaleButton(
      onTap: () => _onReflectionSelect(index, correctIndex),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: GlassTile(
          padding: EdgeInsets.all(isCompact ? 12.r : 20.r),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
          color: isCorrect
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : (isWrong
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : (isSelected
                          ? primaryColor.withValues(alpha: 0.2)
                          : null)),
          border: Border.all(
            color: isCorrect
                ? Colors.greenAccent
                : (isWrong
                      ? Colors.redAccent
                      : (isSelected
                            ? primaryColor
                            : Colors.white.withValues(alpha: 0.1))),
            width: 2,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 13.sp : 15.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isCorrect
                  ? Colors.greenAccent
                  : (isWrong
                        ? Colors.redAccent
                        : (isDark ? Colors.white : Colors.black87)),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10.r : 20.r),
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
            size: isCompact ? 24.r : 36.r,
          ),
          SizedBox(height: isCompact ? 4.h : 10.h),
          Text(
            correct
                ? context.tr('games.correct', fallback: 'Correct').toUpperCase()
                : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 12.sp : 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (!isCompact && quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
