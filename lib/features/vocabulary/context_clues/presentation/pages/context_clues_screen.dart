import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';

// Extracted Optimized Widgets
import '../widgets/context_clues_case_header.dart';
import '../widgets/context_clues_case_file_background.dart';
import '../widgets/context_clues_evidence_sentence.dart';
import '../widgets/context_clues_scanner.dart';
import '../widgets/context_clues_evidence_tags.dart';

/// Interactive detective-style vocabulary game screen where learners scan sentences for context clues.
class ContextCluesScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates a [ContextCluesScreen] instance.
  const ContextCluesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  State<ContextCluesScreen> createState() => _ContextCluesScreenState();
}

class _ContextCluesScreenState extends State<ContextCluesScreen>
    with
        GameScreenMixin<ContextCluesScreen>,
        VocabularyGameScreenMixin<ContextCluesScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Offset> _lensPosition = ValueNotifier(Offset.zero);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _lensPosition.dispose();
    _selectedOption.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onLensMove(
    DragUpdateDetails details,
    BoxConstraints constraints,
    double lensSize,
  ) {
    if (isAnsweredNotifier.value) return;

    final double halfWidth = constraints.maxWidth / 2;
    final double halfHeight = constraints.maxHeight / 2;
    final double padding = (lensSize / 2) + 24.r;

    final double maxX = math.max(0.0, halfWidth - padding);
    final double maxY = math.max(0.0, halfHeight - padding);

    // Keep lens safely inside Paper dossier boundaries
    double newX = (_lensPosition.value.dx + details.delta.dx).clamp(
      -maxX,
      maxX,
    );
    double newY = (_lensPosition.value.dy + details.delta.dy).clamp(
      -maxY,
      maxY,
    );

    _lensPosition.value = Offset(newX, newY);

    // Simulate finding a clue
    if (_lensPosition.value.distance % 40 < 5) {
      hapticService.selection();
    }
  }

  void _submitAnswer(String selected, String correct, GameQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    _selectedOption.value = selected;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      hapticService.selection(); // Subtle feedback for Phase 1
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: selected);
    }
  }

  void _submitFinalAnswer(
    bool nailedIt,
    GameQuest quest, [
    String? misspelledWord,
  ]) {
    if (isAnsweredNotifier.value) return;

    if (misspelledWord != null) {
      _selectedOption.value = misspelledWord;
    }

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: misspelledWord);
    }
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _lensPosition.value = Offset.zero;
    _selectedOption.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: (context, state) {
        if (state is VocabularyLoaded &&
            state.currentIndex != lastProcessedIndex) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
        onVocabularyStateChanged(context, state);
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuestOrNull;
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuestOrNull
            : _lastQuest;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _selectedOption,
          ]),
          builder: (context, _) {
            final bool isBaseAnswered = isAnsweredNotifier.value;
            final bool sceneIsAnswered =
                isAnsweredNotifier.value || isFirstStagePassedNotifier.value;
            final bool? sceneIsCorrect = isFirstStagePassedNotifier.value
                ? true
                : isCorrectNotifier.value;
            final bool isFinalFailure = (state is VocabularyLoaded)
                ? state.isFinalFailure
                : false;

            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              customHintText: quest?.hint,
              isAnswered: isBaseAnswered,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    currentState.livesRemaining > 0 &&
                    isCorrectNotifier.value == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  isFirstStagePassedNotifier.value = false;
                  _selectedOption.value = null;
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                  context.read<VocabularyBloc>().add(NextQuestion());
                }
              },
              onHint: () {},
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    IgnorePointer(
                                      ignoring:
                                          isFirstStagePassedNotifier.value,
                                      child: SizedBox(
                                        height: constraints.maxHeight,
                                        child: _buildForensicScene(
                                          quest,
                                          theme.primaryColor,
                                          isFinalFailure,
                                          sceneIsAnswered,
                                          sceneIsCorrect,
                                          state is VocabularyLoaded
                                              ? state.currentIndex
                                              : 0,
                                        ),
                                      ),
                                    ),
                                    if (isFirstStagePassedNotifier.value &&
                                        !isAnsweredNotifier.value)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.h,
                                        ),
                                        child: EvidenceHighlightWrapper(
                                          passage:
                                              quest.sentence?.replaceAll(
                                                '[TARGET]',
                                                quest.correctAnswer ?? '',
                                              ) ??
                                              "",
                                          evidenceWords:
                                              quest.evidenceWords ?? [],
                                          primaryColor: theme.primaryColor,
                                          instruction:
                                              "Tap the clue words in the sentence that support your answer",
                                          onCorrectHighlight: () =>
                                              _submitFinalAnswer(true, quest),
                                          onWrongHighlight: () => {},
                                          isPositioned: false,
                                        ),
                                      ),
                                    SizedBox(height: 60.h),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildForensicScene(
    VocabularyQuest quest,
    Color color,
    bool isFinalFailure,
    bool sceneIsAnswered,
    bool? sceneIsCorrect,
    int questIndex,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 620;

        final double estimatedContentHeight =
            (isCompact ? 48.h : 56.h) +
            (isCompact ? 28.h : 36.h) +
            (isCompact ? 116.h : 130.h) +
            24.h;
        final remainingHeight =
            math.max(0.0, maxHeight - estimatedContentHeight);

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
        final double gapTop = (gapUnit * 0.8).clamp(4.0, 10.0);
        final double gapMiddle = (gapUnit * 1.0).clamp(6.0, 14.0);
        final double gapBottom = (gapUnit * 1.2).clamp(8.0, 18.0);

        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        return Column(
          children: [
            SizedBox(height: gapTop),
            ContextCluesCaseHeader(
              level: widget.level,
              questIndex: questIndex,
              color: color,
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                "Read the sentence and find the missing word from the clues.",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            SizedBox(height: gapMiddle),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ContextCluesCaseFileBackground(
                          accentColor: color,
                        ),
                      ),
                      // BLURRED BACKGROUND (The mystery)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 5.0,
                          end: sceneIsAnswered ? 0.0 : 5.0,
                        ),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, blurValue, child) {
                          return ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: blurValue,
                              sigmaY: blurValue,
                            ),
                            child: child,
                          );
                        },
                        child: AnimatedOpacity(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 500),
                          opacity: sceneIsAnswered ? 1.0 : 0.4,
                          child: ContextCluesEvidenceSentence(
                            sentence: quest.sentence ?? "",
                            color: color,
                            isCompact: isCompact,
                            isAnswered: sceneIsAnswered,
                            isCorrect: sceneIsCorrect,
                            selectedOption: _selectedOption.value,
                          ),
                        ),
                      ),
                      // LENS SYSTEM (The Flashlight)
                      if (!sceneIsAnswered)
                        ValueListenableBuilder<Offset>(
                          valueListenable: _lensPosition,
                          builder: (context, pos, _) {
                            final lensSize = isCompact ? 110.r : 150.r;
                            final lensRadius = lensSize / 2;
                            final centerPos = Offset(
                              (innerConstraints.maxWidth / 2) + pos.dx,
                              (innerConstraints.maxHeight / 2) + pos.dy,
                            );

                            return Positioned.fill(
                              child: Stack(
                                children: [
                                  // SHARP TEXT (Revealed inside the lens)
                                  Positioned.fill(
                                    child: ClipPath(
                                      clipper: CircleClipper(
                                        centerPos,
                                        lensRadius * 0.85,
                                      ),
                                      child: ContextCluesEvidenceSentence(
                                        sentence: quest.sentence ?? "",
                                        color: color,
                                        isCompact: isCompact,
                                        isAnswered: sceneIsAnswered,
                                        isCorrect: sceneIsCorrect,
                                        selectedOption: _selectedOption.value,
                                      ),
                                    ),
                                  ),
                                  // THE PHYSICAL LENS UI
                                  Positioned(
                                    left: centerPos.dx - lensRadius,
                                    top: centerPos.dy - lensRadius,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: (_) {},
                                      onPanUpdate: (d) => _onLensMove(
                                        d,
                                        innerConstraints,
                                        lensSize,
                                      ),
                                      child: isCompact
                                          ? SizedBox(
                                              width: lensSize,
                                              height: lensSize,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: ContextCluesScanner(
                                                  color: color,
                                                ),
                                              ),
                                            )
                                          : ContextCluesScanner(color: color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: gapMiddle),
            ContextCluesEvidenceTags(
              options: quest.options ?? [],
              correct: quest.correctAnswer ?? "",
              color: color,
              isAnswered: sceneIsAnswered,
              isCorrect: sceneIsCorrect,
              selectedOption: _selectedOption.value,
              isFinalFailure: isFinalFailure,
              onOptionSelected: (o) =>
                  _submitAnswer(o, quest.correctAnswer ?? "", quest),
            ),
            SizedBox(height: gapBottom),
          ],
        );
      },
    );
  }
}

class CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CircleClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}
