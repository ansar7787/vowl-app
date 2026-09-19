import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_placement_instruction.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_magnetic_arena.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

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

class _ModifierPlacementScreenState extends State<ModifierPlacementScreen>
    with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int> _targetIndex = ValueNotifier(-1);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ValueNotifier<String?> _assembledSentence = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _targetIndex.dispose();
    _pendingJigsaw.dispose();
    _assembledSentence.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    initGrammarGame();
  }

  void _submitAnswer(
    GrammarQuest quest,
    String modifier,
    List<String> baseWords,
  ) {
    if (isAnsweredNotifier.value ||
        _targetIndex.value == -1 ||
        _pendingJigsaw.value) {
      return;
    }

    final resultingWords = List<String>.from(baseWords);
    resultingWords.insert(_targetIndex.value, modifier);

    final result = resultingWords.join(' ');

    final normResult = result.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final normAnswer = (quest.correctAnswer ?? "").toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    bool isCorrect = normResult == normAnswer;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _assembledSentence.value = quest.correctAnswer;
      _pendingJigsaw.value = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _assembledSentence.value = quest.correctAnswer;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = correct;

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _targetIndex.value = -1;

    _pendingJigsaw.value = false;

    _assembledSentence.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        String modifier = "";
        List<String> words = [];
        if (quest != null) {
          final sentence = quest.sentence ?? "";
          // Match both single and double quotes for safety
          final match = RegExp(
            r'''modifier ['"]([^'"]+)['"]''',
          ).firstMatch(sentence);
          modifier = match?.group(1) ?? "";

          final answer = quest.correctAnswer ?? "";
          if (modifier.isNotEmpty) {
            final modRegex = RegExp(
              RegExp.escape(modifier),
              caseSensitive: false,
            );
            final answerMatch = modRegex.firstMatch(answer);
            if (answerMatch != null) {
              final prefix = answer.substring(0, answerMatch.start);
              final suffix = answer.substring(answerMatch.end);
              final combined = "$prefix $suffix";
              words = combined.split(' ').where((w) {
                final trimmed = w.trim();
                return trimmed.isNotEmpty &&
                    RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed);
              }).toList();
            }
          }

          // ROBUST FALLBACK: If regex fails or modifier not found in correctAnswer,
          // fall back to shuffledWords so the UI never soft-locks
          if (modifier.isEmpty || words.isEmpty) {
            final allWords = quest.shuffledWords ?? [];
            if (allWords.isNotEmpty) {
              modifier = allWords[0];
              words = allWords.skip(1).toList();
            }
          }
        }

        if (modifier.isEmpty || words.isEmpty) return const SizedBox();

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_assembledSentence.value != null) {
            cleanTargetSentence = _assembledSentence.value!;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _targetIndex,
            _pendingJigsaw,
            _assembledSentence,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
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
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final maxHeight =
                                                  constraints.maxHeight;
                                              final isCompact = maxHeight < 580;

                                              final double
                                              estimatedContentHeight =
                                                  (isCompact ? 30.h : 40.h) +
                                                  (isCompact ? 50.h : 80.h) +
                                                  (isCompact ? 100.h : 180.h) +
                                                  (isCompact ? 40.h : 60.h) +
                                                  (isCompact ? 40.h : 65.h) +
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
                                                            child: ModifierPlacementInstruction(
                                                              primaryColor: theme
                                                                  .primaryColor,
                                                              instructionText:
                                                                  quest
                                                                      .instruction,
                                                            ),
                                                          ),
                                                        )
                                                      : ModifierPlacementInstruction(
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          instructionText:
                                                              quest.instruction,
                                                        ),
                                                  SizedBox(height: gapMiddle),

                                                  if (quest.modifierType !=
                                                      null) ...[
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16.w,
                                                            vertical: 6.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "MODIFIER: ${quest.modifierType!.toUpperCase()}",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
                                                          color: theme
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 1.2,
                                                        ),
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

                                                  // Context Card
                                                  Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                            ),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              EdgeInsets.all(
                                                                isCompact
                                                                    ? 14.r
                                                                    : 22.r,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.05,
                                                                      )
                                                                : Colors.black
                                                                      .withValues(
                                                                        alpha:
                                                                            0.03,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  isCompact
                                                                      ? 18.r
                                                                      : 28.r,
                                                                ),
                                                            border: Border.all(
                                                              color: theme
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            quest.sentence ??
                                                                "",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontSize:
                                                                  isCompact
                                                                  ? 14.sp
                                                                  : 18.sp,
                                                              color: isDark
                                                                  ? Colors
                                                                        .white70
                                                                  : Colors
                                                                        .black87,
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 600.ms)
                                                      .slideY(
                                                        begin: 0.2,
                                                        end: 0,
                                                      ),

                                                  // Result Feedback
                                                  if (isAnsweredNotifier
                                                      .value) ...[
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 8.h
                                                          : 24.h,
                                                    ),
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
                                                        targetIndex:
                                                            _targetIndex.value,
                                                        isAnswered:
                                                            isAnsweredNotifier
                                                                .value ||
                                                            _pendingJigsaw
                                                                .value,
                                                        isDark: isDark,
                                                        primaryColor:
                                                            theme.primaryColor,
                                                        onSlotAccepted: (idx) =>
                                                            _targetIndex.value =
                                                                idx,
                                                        onSlotReset: () =>
                                                            _targetIndex.value =
                                                                -1,
                                                        isCompact: isCompact,
                                                      ),
                                                    ),
                                                  ),

                                                  // Draggable Magnet
                                                  if (!isAnsweredNotifier
                                                          .value &&
                                                      !_pendingJigsaw.value &&
                                                      _targetIndex.value == -1)
                                                    Draggable<String>(
                                                      data: modifier,
                                                      feedback:
                                                          _buildTactileMagnet(
                                                            modifier,
                                                            theme.primaryColor,
                                                            isDragging: true,
                                                            isCompact:
                                                                isCompact,
                                                          ),
                                                      childWhenDragging: Opacity(
                                                        opacity: 0.2,
                                                        child:
                                                            _buildTactileMagnet(
                                                              modifier,
                                                              theme
                                                                  .primaryColor,
                                                              isCompact:
                                                                  isCompact,
                                                            ),
                                                      ),
                                                      child:
                                                          _buildTactileMagnet(
                                                            modifier,
                                                            theme.primaryColor,
                                                            isCompact:
                                                                isCompact,
                                                          ),
                                                    ).animate().scale(
                                                      duration: 400.ms,
                                                      curve: Curves.easeOutBack,
                                                    ),

                                                  // Submit Button
                                                  if (!isAnsweredNotifier
                                                          .value &&
                                                      !_pendingJigsaw.value &&
                                                      _targetIndex.value !=
                                                          -1) ...[
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 8.h
                                                          : 16.h,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24.w,
                                                          ),
                                                      child: ScaleButton(
                                                        onTap: () =>
                                                            _submitAnswer(
                                                              quest,
                                                              modifier,
                                                              words,
                                                            ),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: isCompact
                                                              ? 48.h
                                                              : 65.h,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  isCompact
                                                                      ? 14.r
                                                                      : 24.r,
                                                                ),
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                theme
                                                                    .primaryColor,
                                                                theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    ),
                                                              ],
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.4,
                                                                    ),
                                                                blurRadius: 25,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      12,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              "FINALIZE SYNTAX",
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    isCompact
                                                                    ? 13.sp
                                                                    : 16.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    2,
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
                                      ],
                                    ),
                                  ),
                                  if (_pendingJigsaw.value &&
                                      !isAnsweredNotifier.value &&
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
                                            "Type the complete sentence to lock it in",
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
    final bool correct = isCorrectNotifier.value == true;
    final displayColor = correct
        ? AppColors.gameCorrect
        : AppColors.gameIncorrect;

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
