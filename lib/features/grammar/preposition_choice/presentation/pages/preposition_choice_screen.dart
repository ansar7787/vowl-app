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
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_choice_instruction.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_path_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class PrepositionChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrepositionChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prepositionChoice,
  });

  @override
  State<PrepositionChoiceScreen> createState() =>
      _PrepositionChoiceScreenState();
}

class _PrepositionChoiceScreenState extends State<PrepositionChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<List<Offset>> _points = ValueNotifier([]);
  final ValueNotifier<int> _targetNode = ValueNotifier(-1);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _points.dispose();
    _targetNode.dispose();
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

  void _onPathEnd(int nodeIndex, int correctIndex) {
    if (_isAnswered.value || _pendingJigsaw.value) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _targetNode.value = nodeIndex;
      _isCorrect.value = true;
      _pendingJigsaw.value = true;

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetNode.value = nodeIndex;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
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

    // Auto-scroll back up so user can read the explanation/feedback
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final parts = template.contains("____")
        ? template.split("____")
        : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8.w : 12.w,
                        vertical: isCompact ? 2.h : 4.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected != null
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        selected ?? "      ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 16.sp : 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    )
                    .animate(target: selected != null ? 1 : 0)
                    .shimmer(duration: 2.seconds),
          ),
        );
      }
    }
    return spans;
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
            _targetNode.value = -1;
            _pendingJigsaw.value = false;
            _points.value = [];

            if (_scrollController.hasClients && _scrollController.offset > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              });
            }
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
            title: 'SPATIAL PRO!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final options = quest?.options ?? ["IN", "ON", "AT", "UNDER"];

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _targetNode,
            _pendingJigsaw,
            _points,
          ]),
          builder: (context, _) {
            String cleanTargetSentence = "";
            if (quest != null) {
              final sentence = quest.sentenceWithBlank ?? quest.question ?? "";
              String fullSentence = sentence;
              if (sentence.contains("___") && _targetNode.value != -1) {
                fullSentence = sentence.replaceFirst(
                  RegExp(r'_{3,}'),
                  options[_targetNode.value],
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
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 580;
                        final double gapTop = isCompact ? 10.h : 20.h;
                        final double gapMiddle = isCompact ? 16.h : 30.h;
                        final double gapBottom = isCompact ? 16.h : 30.h;

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
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        SizedBox(height: gapTop),
                                        PrepositionChoiceInstruction(
                                          primaryColor: theme.primaryColor,
                                        ),
                                        SizedBox(height: gapMiddle),

                                        if (quest.grammarRule != null ||
                                            quest.prepositionCategory !=
                                                null) ...[
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "RULE: ${(quest.grammarRule ?? quest.prepositionCategory!).toUpperCase()}",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    color: theme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                if (state is GrammarLoaded &&
                                                    state.hintUsed &&
                                                    quest.hint != null) ...[
                                                  SizedBox(height: 8.h),
                                                  Text(
                                                    quest.hint!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 13.sp,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.3,
                                                    ),
                                                  ).animate().fadeIn(),
                                                ],
                                              ],
                                            ),
                                          ).animate().fadeIn(duration: 400.ms),
                                          SizedBox(
                                            height: isCompact ? 16.h : 24.h,
                                          ),
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
                                                      ? Colors.white.withValues(
                                                          alpha: 0.05,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.03,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isCompact ? 18.r : 28.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: isCompact
                                                          ? 16.sp
                                                          : 20.sp,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      height: 1.5,
                                                    ),
                                                    children: _buildSentenceWithBlank(
                                                      quest.sentenceWithBlank ??
                                                          quest.question ??
                                                          "____ sentence.",
                                                      (_isAnswered.value ||
                                                                  _pendingJigsaw
                                                                      .value) &&
                                                              _targetNode
                                                                      .value !=
                                                                  -1
                                                          ? options[_targetNode
                                                                .value]
                                                          : null,
                                                      theme.primaryColor,
                                                      isDark,
                                                      isCompact,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(duration: 600.ms)
                                            .slideY(begin: 0.2, end: 0),

                                        // Result Feedback
                                        if (_isAnswered.value) ...[
                                          SizedBox(
                                            height: isCompact ? 16.h : 24.h,
                                          ),
                                          _buildResult(
                                            quest,
                                            theme.primaryColor,
                                            isDark,
                                            isCompact,
                                          ),
                                        ],
                                        SizedBox(height: gapBottom),
                                      ],
                                    ),
                                  ),

                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: isCompact ? 220.h : 300.h,
                                      child: _buildPathCanvas(
                                        options,
                                        quest.correctAnswerIndex ?? 0,
                                        theme.primaryColor,
                                        isDark,
                                        isCompact,
                                      ),
                                    ),
                                  ),

                                  if (_pendingJigsaw.value &&
                                      !_isAnswered.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 16.h),
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

  Widget _buildPathCanvas(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onPanUpdate: (details) {
            if (_isAnswered.value || _pendingJigsaw.value) return;

            final RenderBox box = context.findRenderObject() as RenderBox;
            final size = box.size;
            final nodePoints = PrepositionPathPainter.getNodePoints(
              size,
              options.length,
              isCompact,
            );

            _points.value = List.from(_points.value)
              ..add(details.localPosition);
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  (isCompact ? 30.r : 50.r)) {
                _onPathEnd(i, correctIndex);
                break;
              }
            }
          },
          onPanEnd: (_) => _points.value = [],
          onTapUp: (details) {
            if (_isAnswered.value || _pendingJigsaw.value) return;

            final RenderBox box = context.findRenderObject() as RenderBox;
            final size = box.size;
            final nodePoints = PrepositionPathPainter.getNodePoints(
              size,
              options.length,
              isCompact,
            );

            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  (isCompact ? 40.r : 60.r)) {
                _onPathEnd(i, correctIndex);
                break;
              }
            }
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: PrepositionPathPainter(
              points: _points.value,
              options: options,
              primaryColor: primaryColor,
              isAnswered: _isAnswered.value || _pendingJigsaw.value,
              isCorrect: _isCorrect.value ?? false,
              targetNode: _targetNode.value,
              isDark: isDark,
              isCompact: isCompact,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect.value == true;
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
