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
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_instruction.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_brick_sheet.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class ConjunctionsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConjunctionsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conjunctions,
  });

  @override
  State<ConjunctionsScreen> createState() => _ConjunctionsScreenState();
}

class _ConjunctionsScreenState extends State<ConjunctionsScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<String?> _placedBrick = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _placedBrick.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingJigsaw.dispose();
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

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onBridge(String conj, int correctIndex, List<String> options) {
    if (_isAnswered.value || _pendingJigsaw.value) return;

    bool isCorrect = conj == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      _placedBrick.value = conj;
      _pendingJigsaw.value = true;
      _scrollToBottom();
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _placedBrick.value = conj;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
      _scrollToBottom();
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
    _isAnswered.value = true;
    _isCorrect.value = correct;

    if (correct) {
      _hapticService.heavy();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
    _scrollToBottom();
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
            _placedBrick.value = null;
            _pendingJigsaw.value = false;
            _scrollToTop();
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
            title: 'SYNAPSE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final options = quest?.options ?? ["AND", "BUT", "OR"];
        final question = quest?.question ?? "I like apples... I like oranges.";
        final parts = question.contains("...")
            ? question.split("...")
            : question.split("___");

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _placedBrick,
            _pendingJigsaw,
          ]),
          builder: (context, _) {
            String cleanTargetSentence = "";
            if (quest != null && _placedBrick.value != null) {
              String fullSentence = question;
              if (question.contains("...")) {
                fullSentence = question.replaceFirst(
                  RegExp(r'\.{3,}'),
                  " ${_placedBrick.value} ",
                );
              } else if (question.contains("___")) {
                fullSentence = question.replaceFirst(
                  RegExp(r'_{3,}'),
                  " ${_placedBrick.value} ",
                );
              }
              cleanTargetSentence = fullSentence
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
            }

            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
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
                                    hasScrollBody: true,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                final maxHeight =
                                                    constraints.maxHeight;
                                                final isCompact =
                                                    maxHeight < 580;

                                                final double
                                                estimatedContentHeight =
                                                    (isCompact ? 30.h : 40.h) +
                                                    (isCompact ? 50.h : 80.h) *
                                                        2 +
                                                    (isCompact ? 50.h : 70.h) +
                                                    (isCompact ? 50.h : 80.h) +
                                                    40.h;
                                                final remainingHeight =
                                                    maxHeight -
                                                    estimatedContentHeight;

                                                final double gapUnit =
                                                    remainingHeight > 0
                                                    ? remainingHeight / 5
                                                    : 0;
                                                final double gapTop =
                                                    remainingHeight > 0
                                                    ? (gapUnit * 1).clamp(
                                                        4.0,
                                                        15.0,
                                                      )
                                                    : 4.0;
                                                final double gapMiddle =
                                                    remainingHeight > 0
                                                    ? (gapUnit * 1.5).clamp(
                                                        6.0,
                                                        20.0,
                                                      )
                                                    : 6.0;
                                                final double gapBottom =
                                                    remainingHeight > 0
                                                    ? (gapUnit * 2.5).clamp(
                                                        10.0,
                                                        30.0,
                                                      )
                                                    : 10.0;

                                                return Column(
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 25.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: ConjunctionsInstruction(
                                                                primaryColor: theme
                                                                    .primaryColor,
                                                                instruction: quest
                                                                    .instruction,
                                                              ),
                                                            ),
                                                          )
                                                        : ConjunctionsInstruction(
                                                            primaryColor: theme
                                                                .primaryColor,
                                                            instruction: quest
                                                                .instruction,
                                                          ),
                                                    SizedBox(height: gapMiddle),

                                                    if (quest.grammarRule !=
                                                            null ||
                                                        quest.conjunctionPurpose !=
                                                            null) ...[
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16.w,
                                                              vertical: 8.h,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16.r,
                                                              ),
                                                          border: Border.all(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              [
                                                                if (quest
                                                                        .grammarRule !=
                                                                    null)
                                                                  quest
                                                                      .grammarRule!
                                                                      .toUpperCase(),
                                                                if (quest
                                                                        .conjunctionPurpose !=
                                                                    null)
                                                                  quest
                                                                      .conjunctionPurpose!
                                                                      .toUpperCase(),
                                                              ].join(" - "),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize: 10.sp,
                                                                color: theme
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                letterSpacing:
                                                                    1.2,
                                                              ),
                                                            ),
                                                            if (quest
                                                                    .grammarRule ==
                                                                "Coordinating Conjunctions") ...[
                                                              SizedBox(
                                                                height: 4.h,
                                                              ),
                                                              Wrap(
                                                                alignment:
                                                                    WrapAlignment
                                                                        .center,
                                                                spacing: 8.w,
                                                                children:
                                                                    [
                                                                          "For",
                                                                          "And",
                                                                          "Nor",
                                                                          "But",
                                                                          "Or",
                                                                          "Yet",
                                                                          "So",
                                                                        ]
                                                                        .map(
                                                                          (
                                                                            word,
                                                                          ) => Text(
                                                                            "${word[0]} = $word",
                                                                            style: TextStyle(
                                                                              fontSize: 10.sp,
                                                                              color: theme.primaryColor.withValues(
                                                                                alpha: 0.6,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                        .toList(),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ).animate().fadeIn(
                                                        duration: 400.ms,
                                                      ),
                                                      SizedBox(
                                                        height: isCompact
                                                            ? 12.h
                                                            : 20.h,
                                                      ),
                                                    ],

                                                    // Magnetic Junction Bridge
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                            ),
                                                        child: LayoutBuilder(
                                                          builder: (context, constraints) {
                                                            return SingleChildScrollView(
                                                              physics:
                                                                  const BouncingScrollPhysics(),
                                                              child: ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                      minHeight:
                                                                          constraints
                                                                              .maxHeight,
                                                                    ),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    if (parts
                                                                        .first
                                                                        .trim()
                                                                        .isNotEmpty) ...[
                                                                      _buildIslandPiece(
                                                                        parts
                                                                            .first,
                                                                        isDark,
                                                                        theme
                                                                            .primaryColor,
                                                                        isCompact,
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            isCompact
                                                                            ? 12.h
                                                                            : 24.h,
                                                                      ),
                                                                    ],
                                                                    _buildMagneticJunction(
                                                                      options,
                                                                      quest.correctAnswerIndex ??
                                                                          0,
                                                                      theme
                                                                          .primaryColor,
                                                                      isDark,
                                                                      isCompact,
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          isCompact
                                                                          ? 12.h
                                                                          : 24.h,
                                                                    ),
                                                                    if (parts.length >
                                                                            1 &&
                                                                        parts
                                                                            .last
                                                                            .trim()
                                                                            .isNotEmpty)
                                                                      _buildIslandPiece(
                                                                        parts
                                                                            .last,
                                                                        isDark,
                                                                        theme
                                                                            .primaryColor,
                                                                        isCompact,
                                                                      ).animate().fadeIn(
                                                                        delay: 400
                                                                            .ms,
                                                                      ),
                                                                    if (_isAnswered
                                                                        .value) ...[
                                                                      SizedBox(
                                                                        height:
                                                                            isCompact
                                                                            ? 10.h
                                                                            : 20.h,
                                                                      ),
                                                                      _buildCorrectResult(
                                                                        quest,
                                                                        theme
                                                                            .primaryColor,
                                                                        isDark,
                                                                        isCompact,
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: gapMiddle),

                                                    ConjunctionsBrickSheet(
                                                      options: options,
                                                      placedBrick:
                                                          _placedBrick.value,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      isCompact: isCompact,
                                                      onBrickTapped: (brickText) {
                                                        final index = options
                                                            .indexOf(brickText);
                                                        if (index != -1) {
                                                          _onBridge(
                                                            brickText,
                                                            quest.correctAnswerIndex ??
                                                                0,
                                                            options,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    SizedBox(height: gapBottom),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 60.h),
                                  ),
                                  if (_pendingJigsaw.value &&
                                      !_isAnswered.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        isPositioned: false,
                                        displayText:
                                            "Type the full sentence to lock it in",
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

  Widget _buildMagneticJunction(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) =>
          _onBridge(details.data, correctIndex, options),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final nodeColor = _placedBrick.value != null
            ? ((_isAnswered.value || _pendingJigsaw.value) &&
                      _isCorrect.value != false
                  ? Colors.greenAccent
                  : Colors.redAccent)
            : (isHighlight
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.3));

        return Container(
          width: isCompact ? 140.w : 180.w,
          height: isCompact ? 48.h : 70.h,
          decoration: BoxDecoration(
            color: nodeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isCompact ? 14.r : 20.r),
            border: Border.all(
              color: nodeColor.withValues(alpha: 0.4),
              width: 2,
              style: _placedBrick.value != null
                  ? BorderStyle.none
                  : BorderStyle.solid,
            ),
            boxShadow: [
              if (isHighlight || _placedBrick.value != null)
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: _placedBrick.value != null
                ? Text(
                    _placedBrick.value!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 14.sp : 20.sp,
                      fontWeight: FontWeight.w900,
                      color: nodeColor,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                : (isHighlight
                      ? Icon(
                          Icons.bolt_rounded,
                          color: primaryColor,
                          size: isCompact ? 20.r : 28.r,
                        ).animate().scale().shimmer()
                      : Text(
                          "JUNCTION",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 8.sp : 10.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryColor.withValues(alpha: 0.4),
                            letterSpacing: 2,
                          ),
                        )),
          ),
        );
      },
    );
  }

  Widget _buildIslandPiece(
    String text,
    bool isDark,
    Color primaryColor,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12.r : 22.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 14.r : 24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
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
    final bool correct = _isCorrect.value == true;
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
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 10.sp : 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
