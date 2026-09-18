import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_instruction.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_context_card.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_vortex.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_draggable_word.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const PartsOfSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.partsOfSpeech,
  });
  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;
  @override
  int get level => widget.level;
  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
          
  final ValueNotifier<bool> _isWordSelected = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    _dragOffset.dispose();
                _isSubmitting.dispose();
    _isWordSelected.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  static const List<String> _fallbackOptions = ['Noun', 'Verb', 'Adj', 'Adv'];
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

  void _onFlick(int targetIndex, int correctIndex) {
    if (isAnsweredNotifier.value || _isSubmitting.value) return;
    _isSubmitting.value = true;

    final isCorrect = targetIndex == correctIndex;
    if (isCorrect) {
      _submitFinalAnswer(true);
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
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

  void _checkCollision(int correctIndex, {required bool isCompact}) {
    if (isAnsweredNotifier.value) return;

    final distance = _dragOffset.value.distance;
    final threshold = isCompact ? 60.r : 100.r;
    if (distance <= threshold) return;

    final targetIndex = switch ((
      _dragOffset.value.dx < 0,
      _dragOffset.value.dy < 0,
    )) {
      (true, true) => 0, // Top-Left
      (false, true) => 1, // Top-Right
      (true, false) => 2, // Bottom-Left
      (false, false) => 3, // Bottom-Right
    };
    _onFlick(targetIndex, correctIndex);
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: _onStateChange,
      builder: (context, state) {
        final quest = state is GrammarLoaded ? state.currentQuest : null;
        final options = (quest?.options?.length ?? 0) >= 4
            ? quest!.options!.sublist(0, 4)
            : _fallbackOptions;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _dragOffset,
            _isSubmitting,
            _isWordSelected,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false, // Stack layout constraint
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
                                              final maxHeight = MediaQuery.of(
                                                context,
                                              ).size.height;
                                              final isCompact = maxHeight < 700;
                                              return _PosQuestLayout(
                                                quest: quest,
                                                options: options,
                                                theme: theme,
                                                isDark: isDark,
                                                isCompact: isCompact,
                                                maxHeight:
                                                    constraints.maxHeight,
                                                dragOffset: _dragOffset.value,
                                                isAnswered: isAnsweredNotifier.value,
                                                isWordSelected:
                                                    _isWordSelected.value,
                                                onWordTap: () {
                                                  _isWordSelected.value =
                                                      !_isWordSelected.value;
                                                  hapticService.selection();
                                                },
                                                onVortexTap: (index) {
                                                  if (!_isWordSelected.value) {
                                                    return;
                                                  }
                                                  _onFlick(
                                                    index,
                                                    quest.correctAnswerIndex ??
                                                        0,
                                                  );
                                                },
                                                onPanUpdate: (details) {
                                                  if (isAnsweredNotifier.value) return;
                                                  _dragOffset.value +=
                                                      details.delta;
                                                  _checkCollision(
                                                    quest.correctAnswerIndex ??
                                                        0,
                                                    isCompact: isCompact,
                                                  );
                                                },
                                                onPanEnd: (_) {
                                                  if (isAnsweredNotifier.value) return;
                                                  _dragOffset.value =
                                                      Offset.zero;
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 60.h),
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

  void _onStateChange(BuildContext context, GrammarState state) {
    if (state is GrammarLoaded) {
      final isNewQuestion = state.currentIndex != lastProcessedIndex;
      final isRetry = isAnsweredNotifier.value && !state.answerStatus.isAnswered;
      final livesRestored =
          lastLives != null && state.livesRemaining > lastLives!;

      if (isNewQuestion || isRetry || livesRestored) {
        lastProcessedIndex = state.currentIndex;
        isAnsweredNotifier.value = false;
        isCorrectNotifier.value = null;
        _dragOffset.value = Offset.zero;
        _isSubmitting.value = false;
        _isWordSelected.value = false;
      } else if (state.answerStatus.isAnswered && !isAnsweredNotifier.value) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = state.answerStatus.asBoolOrNull;
      }
      lastLives = state.livesRemaining;
    }

    if (state is GrammarGameComplete) {
      showConfettiNotifier.value = true;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: 'POS PRO!',
        enableDoubleUp: true,
      );
    }
  }
}

class _PosQuestLayout extends StatelessWidget {
  final GrammarQuest quest;
  final List<String> options;
  final dynamic theme;
  final bool isDark;
  final bool isCompact;
  final double maxHeight;
  final Offset dragOffset;
  final bool isAnswered;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final bool isWordSelected;
  final VoidCallback onWordTap;
  final void Function(int index) onVortexTap;

  static const _vortexColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  static const _vortexAlignments = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  const _PosQuestLayout({
    required this.quest,
    required this.options,
    required this.theme,
    required this.isDark,
    required this.isCompact,
    required this.maxHeight,
    required this.dragOffset,
    required this.isAnswered,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isWordSelected,
    required this.onWordTap,
    required this.onVortexTap,
  });

  ({double top, double middle, double bottom}) _computeGaps() {
    final estimated =
        (isCompact ? 30.h : 40.h) +
        (isCompact ? 50.h : 80.h) +
        (isCompact ? 160.h : 260.h) +
        40.h;
    final remaining = (maxHeight - estimated).clamp(0.0, double.infinity);
    final unit = remaining / 5;
    return (
      top: (unit * 1.0).clamp(4.0, 15.0),
      middle: (unit * 1.5).clamp(6.0, 20.0),
      bottom: (unit * 2.5).clamp(10.0, 30.0),
    );
  }
  @override
  Widget build(BuildContext context) {
    final gaps = _computeGaps();

    return Column(
      children: [
        SizedBox(height: gaps.top),
        _buildInstruction(),
        SizedBox(height: gaps.middle),
        SpeechContextCard(
          quest: quest,
          primaryColor: theme.primaryColor as Color,
          isDark: isDark,
          isCompact: isCompact,
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 4; i++)
                SpeechVortex(
                  index: i,
                  label: options[i],
                  color: _vortexColors[i],
                  alignment: _vortexAlignments[i],
                  isCompact: isCompact,
                  onTap: () => onVortexTap(i),
                ),
              if (!isAnswered)
                GestureDetector(
                  onPanUpdate: onPanUpdate,
                  onPanEnd: onPanEnd,
                  onTap: onWordTap,
                  child: Transform.translate(
                    offset: dragOffset,
                    child: Transform.rotate(
                      angle: dragOffset.dx / 100,
                      child: SpeechDraggableWord(
                        word: quest.targetWord ?? quest.word ?? '??',
                        primaryColor: theme.primaryColor as Color,
                        isDark: isDark,
                        isCompact: isCompact,
                        isSelected: isWordSelected,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
        SizedBox(height: gaps.bottom),
      ],
    );
  }

  Widget _buildInstruction() {
    final instruction = SpeechInstruction(
      primaryColor: theme.primaryColor as Color,
    );
    if (!isCompact) return instruction;
    return SizedBox(
      height: 25.h,
      child: FittedBox(fit: BoxFit.scaleDown, child: instruction),
    );
  }
}




