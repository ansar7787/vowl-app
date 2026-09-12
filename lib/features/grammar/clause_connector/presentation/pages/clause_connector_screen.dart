import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

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

  final ValueNotifier<String?> _draggingConnector = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _draggingConnector.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingTypeSubmit.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSnap(String connector, int correctIndex, List<String> options) {
    if (_isAnswered.value || _pendingTypeSubmit.value) return;

    bool isCorrect = connector == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      _draggingConnector.value = connector;
      _pendingTypeSubmit.value = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _draggingConnector.value = connector;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;
    _isAnswered.value = true;
    _isCorrect.value = correct;

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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingTypeSubmit.value = false;
            _draggingConnector.value = null;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          _showConfetti.value = true;
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
        final clauseB = parts.length > 1
            ? parts.sublist(1).join(' ____ ')
            : "...";
        final options = quest?.options ?? [];

        String cleanTargetSentence = "";
        if (quest != null) {
          final connector =
              quest.correctAnswer ??
              (options.isNotEmpty && quest.correctAnswerIndex != null
                  ? options[quest.correctAnswerIndex!]
                  : "");
          final rawSentence = quest.sentence ?? quest.question ?? "";

          if (rawSentence.contains('____')) {
            cleanTargetSentence = rawSentence
                .replaceAll(RegExp(r'\s*____\s*'), ' $connector ')
                .trim();
          } else {
            cleanTargetSentence = "$clauseA $connector $clauseB".trim();
          }
          cleanTargetSentence = cleanTargetSentence
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('  ', ' ');
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _pendingTypeSubmit,
            _draggingConnector,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling: false, // Stack layout
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24.w,
                                        vertical: 24.h,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ClauseConnectorInstruction(
                                            primaryColor: theme.primaryColor,
                                            instructionText: quest.instruction,
                                          ),
                                          if (quest.connectorCategory !=
                                              null) ...[
                                            SizedBox(height: 12.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 6.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                "TYPE: ${quest.connectorCategory!.toUpperCase()}",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                          SizedBox(height: 32.h),
                                          _buildHolographicPlate(
                                            clauseA,
                                            theme.primaryColor,
                                            isDark,
                                            constraints.maxHeight < 580,
                                          ),
                                          SizedBox(height: 24.h),
                                          _buildMagneticPort(
                                            quest,
                                            options,
                                            theme.primaryColor,
                                            isDark,
                                            constraints.maxHeight < 580,
                                          ),
                                          SizedBox(height: 24.h),
                                          _buildHolographicPlate(
                                            clauseB,
                                            theme.primaryColor,
                                            isDark,
                                            constraints.maxHeight < 580,
                                          ).animate().fadeIn(delay: 300.ms),
                                          SizedBox(height: 48.h),
                                          if (!_isAnswered.value &&
                                              !_pendingTypeSubmit.value)
                                            _buildConnectorPalette(
                                              options,
                                              theme.primaryColor,
                                              isDark,
                                              quest.correctAnswerIndex ?? 0,
                                              constraints.maxHeight < 580,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_pendingTypeSubmit.value &&
                                      !_isAnswered.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        displayText:
                                            "Type the complete sentence to lock in the clause structure",
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        allowSkip: true,
                                        isPositioned: false,
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                40.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            );
          },
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
      onWillAcceptWithDetails: (details) =>
          !_isAnswered.value && !_pendingTypeSubmit.value,
      onAcceptWithDetails: (details) =>
          _onSnap(details.data, quest?.correctAnswerIndex ?? 0, options),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final portColor = (_isAnswered.value || _pendingTypeSubmit.value)
            ? (_isCorrect.value != false
                  ? Colors.greenAccent
                  : Colors.redAccent)
            : (isHighlight
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.3));

        return Container(
          width: isCompact ? 180.w : 220.w,
          height: isCompact ? 50.h : 80.h,
          decoration: BoxDecoration(
            color: portColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: portColor.withValues(alpha: 0.4),
              width: 2,
              style: (_isAnswered.value || _pendingTypeSubmit.value)
                  ? BorderStyle.none
                  : BorderStyle.solid,
            ),
            boxShadow: [
              if (isHighlight || _isAnswered.value || _pendingTypeSubmit.value)
                BoxShadow(
                  color: portColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: (_isAnswered.value || _pendingTypeSubmit.value)
                ? _buildConnector(
                    _draggingConnector.value ?? "---",
                    primaryColor,
                    isDark,
                    isCompact,
                    isCorrect: _isCorrect.value != false,
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_link_rounded,
                        color: portColor.withValues(alpha: 0.5),
                        size: isCompact ? 20.sp : 24.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isHighlight ? "RELEASE" : "TAP OR DRAG",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 10.sp : 12.sp,
                          fontWeight: FontWeight.w800,
                          color: portColor.withValues(alpha: 0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(30.r),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_rounded,
            size: isCompact ? 14.sp : 18.sp,
            color: isCorrect == true
                ? Colors.greenAccent
                : (isCorrect == false
                      ? Colors.redAccent
                      : (isDark ? Colors.white70 : Colors.black54)),
          ),
          SizedBox(width: 8.w),
          Text(
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
        ],
      ),
    );
  }
}
