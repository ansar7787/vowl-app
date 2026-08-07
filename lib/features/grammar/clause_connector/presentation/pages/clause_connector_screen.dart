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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/widgets/clause_connector_instruction.dart';
import 'package:vowl/core/presentation/widgets/dynamic_jigsaw_wrapper.dart';

class ClauseConnectorScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ClauseConnectorScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clauseConnector,
  });

  @override
  State<ClauseConnectorScreen> createState() => _ClauseConnectorScreenState();
}

class _ClauseConnectorScreenState extends State<ClauseConnectorScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  String? _draggingConnector;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _pendingJigsaw = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSnap(String connector, int correctIndex, List<String> options) {
    if (_isAnswered || _pendingJigsaw) return;

    bool isCorrect = connector == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _draggingConnector = connector;
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _draggingConnector = connector;
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
              _pendingJigsaw = false;
              _draggingConnector = null;
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
            title: 'BRIDGE BUILDER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final parts = (quest?.question ?? "Clause A ____ Clause B").split(
          ' ____ ',
        );
        final clauseA = parts[0];
        final clauseB = parts.length > 1 ? parts[1] : "...";
        final options = quest?.options ?? [];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else {
            // Fallback to assembling it
            final correctConnector =
                options.isNotEmpty && quest.correctAnswerIndex != null
                ? options[quest.correctAnswerIndex!]
                : "";
            cleanTargetSentence = "$clauseA $correctConnector $clauseB";
          }
        }

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling:
              false, // Turn off scrolling because DynamicJigsawWrapper needs Stack layout
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (isCompact ? 50.h : 80.h) * 2 +
                            (isCompact ? 50.h : 80.h) +
                            (isCompact ? 60.h : 100.h) +
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
                                      child: ClauseConnectorInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : ClauseConnectorInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: gapMiddle),

                            // Magnetic Energy Port Container
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildHolographicPlate(
                                      clauseA,
                                      theme.primaryColor,
                                      isDark,
                                      isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 10.h : 16.h),
                                    _buildMagneticPort(
                                      quest,
                                      options,
                                      theme.primaryColor,
                                      isDark,
                                      isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 10.h : 16.h),
                                    _buildHolographicPlate(
                                      clauseB,
                                      theme.primaryColor,
                                      isDark,
                                      isCompact,
                                    ).animate().fadeIn(delay: 300.ms),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: gapMiddle),

                            if (!_isAnswered && !_pendingJigsaw)
                              _buildConnectorPalette(
                                options,
                                theme.primaryColor,
                                isDark,
                                quest.correctAnswerIndex ?? 0,
                                isCompact,
                              ),
                            SizedBox(height: gapBottom),
                          ],
                        );
                      },
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      DynamicJigsawWrapper(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMagneticPort(
    GameQuest? quest,
    List<String> options,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !_isAnswered && !_pendingJigsaw,
      onAcceptWithDetails: (details) =>
          _onSnap(details.data, quest?.correctAnswerIndex ?? 0, options),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final portColor = (_isAnswered || _pendingJigsaw)
            ? (_isCorrect != false ? Colors.greenAccent : Colors.redAccent)
            : (isHighlight
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.3));

        return Container(
          width: isCompact ? 180.w : 220.w,
          height: isCompact ? 50.h : 80.h,
          decoration: BoxDecoration(
            color: portColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: portColor.withValues(alpha: 0.4),
              width: 2,
              style: (_isAnswered || _pendingJigsaw)
                  ? BorderStyle.none
                  : BorderStyle.solid,
            ),
            boxShadow: [
              if (isHighlight || _isAnswered || _pendingJigsaw)
                BoxShadow(
                  color: portColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: (_isAnswered || _pendingJigsaw)
                ? _buildConnector(
                    _draggingConnector ?? "---",
                    primaryColor,
                    isDark,
                    isCompact,
                    isCorrect: _isCorrect != false,
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                : Text(
                    isHighlight ? "RELEASE TO SNAP" : "ENERGY PORT",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 8.sp : 10.sp,
                      fontWeight: FontWeight.w900,
                      color: portColor.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHolographicPlate(
    String text,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12.r : 22.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Text(
        text.trim(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 14.sp : 18.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildConnectorPalette(
    List<String> options,
    Color primaryColor,
    bool isDark,
    int correctIndex,
    bool isCompact,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isCompact ? 10.w : 16.w,
      runSpacing: isCompact ? 10.h : 16.h,
      children: options
          .map(
            (opt) => Draggable<String>(
              data: opt,
              feedback: Material(
                color: Colors.transparent,
                child: _buildConnector(
                  opt,
                  primaryColor,
                  isDark,
                  isCompact,
                  isDragging: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.2,
                child: _buildConnector(opt, primaryColor, isDark, isCompact),
              ),
              child: GestureDetector(
                onTap: () => _onSnap(opt, correctIndex, options),
                child: _buildConnector(opt, primaryColor, isDark, isCompact),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildConnector(
    String text,
    Color primaryColor,
    bool isDark,
    bool isCompact, {
    bool isDragging = false,
    bool? isCorrect,
  }) {
    Color borderColor = primaryColor.withValues(alpha: 0.4);
    if (isCorrect == true) {
      borderColor = Colors.greenAccent;
    } else if (isCorrect == false) {
      borderColor = Colors.redAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.w : 24.w,
        vertical: isCompact ? 8.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isCompact ? 12.r : 16.r),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          if (isDragging || isCorrect != null)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 12.sp : 15.sp,
          fontWeight: FontWeight.w900,
          color: isCorrect == true
              ? Colors.greenAccent
              : (isCorrect == false
                    ? Colors.redAccent
                    : (isDark ? Colors.white : Colors.black87)),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
