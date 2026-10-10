import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_instruction.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_digital_blackboard.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_correction_options.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class FixTheSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FixTheSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fixTheSentence,
  });

  @override
  State<FixTheSentenceScreen> createState() => _FixTheSentenceScreenState();
}

class _FixTheSentenceScreenState extends State<FixTheSentenceScreen>
    with
        GameScreenMixin<FixTheSentenceScreen>,
        WritingGameScreenMixin<FixTheSentenceScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final _ErasePointsNotifier _erasePoints = _ErasePointsNotifier();
  final ValueNotifier<bool> _isWiped = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ValueNotifier<String?> _pendingSelectedOption = ValueNotifier(null);
  final ValueNotifier<int> _erasedAmount = ValueNotifier(0);
  WritingQuest? _lastQuest;
  final ValueNotifier<List<String>?> _shuffledOptions = ValueNotifier(null);
  final _ttsService = di.sl<TtsService>();

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _erasePoints.dispose();
    _isWiped.dispose();
    _selectedOption.dispose();
    _pendingSelectedOption.dispose();
    _erasedAmount.dispose();
    _shuffledOptions.dispose();
    disposeWritingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<WritingBloc>();
        if (bloc.state is WritingLoaded) {
          final state = bloc.state as WritingLoaded;
          _lastQuest = state.currentQuest;
          final opts = state.currentQuest.options?.toList();
          if (opts != null) {
            opts.shuffle();
            _shuffledOptions.value = opts;
          }
        }
      }
    });
  }

  void _onErase(Offset localPosition, bool isAnswered) {
    if (isAnswered || _isWiped.value) {
      return;
    }
    _erasePoints.add(localPosition);
    _erasedAmount.value++;
    if (_erasedAmount.value % 6 == 0) hapticService.selection();

    if (_erasedAmount.value > 35) {
      hapticService.success();
      soundService.playHint();
      _isWiped.value = true;
    }
  }

  void _submitFinalAnswer(bool nailedTyping, WritingQuest quest) {
    if (_pendingSelectedOption.value == null) {
      return;
    }

    if (!nailedTyping) {
      hapticService.error();
      soundService.playWrong();
      _selectedOption.value = _pendingSelectedOption.value;
      submitWrongAnswer(quest: quest, userAnswer: _pendingSelectedOption.value);
      return;
    }

    final selected = _pendingSelectedOption.value!;
    final correct = quest.correctAnswer ?? "";
    final bool isAnsCorrect = selected == correct;

    _selectedOption.value = _pendingSelectedOption.value;

    if (isAnsCorrect) {
      submitCorrectAnswer();
      final fullText = quest.passage ?? "";
      final targetWord = quest.missingWord ?? "";
      final String escapedTarget = RegExp.escape(targetWord);
      final RegExp wordRegExp = RegExp(
        r'(?<![a-zA-Z0-9_])' + escapedTarget + r'(?![a-zA-Z0-9_])',
        caseSensitive: true,
      );
      final correctedText = fullText.contains(wordRegExp)
          ? fullText.replaceFirst(wordRegExp, selected)
          : fullText.replaceFirst(targetWord, selected);
      _ttsService.speak(correctedText);
    } else {
      submitWrongAnswer(quest: quest, userAnswer: selected);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void onQuestionReset() {
    bool isNewQuest = true;
    if (mounted) {
      final bloc = context.read<WritingBloc>();
      if (bloc.state is WritingLoaded) {
        isNewQuest = (bloc.state as WritingLoaded).currentQuest != _lastQuest;
      }
    }

    if (isNewQuest) {
      _isWiped.value = false;
      _erasedAmount.value = 0;
      _erasePoints.clear();
    }

    _selectedOption.value = null;
    _pendingSelectedOption.value = null;

    if (mounted) {
      final bloc = context.read<WritingBloc>();
      if (bloc.state is WritingLoaded) {
        final opts = (bloc.state as WritingLoaded).currentQuest.options
            ?.toList();
        if (opts != null) {
          if (isNewQuest) {
            opts.shuffle();
            _shuffledOptions.value = opts;
          }
        } else {
          _shuffledOptions.value = null;
        }
      } else {
        _shuffledOptions.value = null;
      }
    } else {
      _shuffledOptions.value = null;
    }
  }

  @override
  void onWritingStateChanged(BuildContext context, WritingState state) {
    super.onWritingStateChanged(context, state);
    if (state is WritingLoaded && state.currentQuest != _lastQuest) {
      _lastQuest = state.currentQuest;
      final opts = state.currentQuest.options?.toList();
      if (opts != null) {
        opts.shuffle();
        _shuffledOptions.value = opts;
      } else {
        _shuffledOptions.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && prev is! WritingLoaded) ||
          (curr is WritingLoaded &&
              prev is WritingLoaded &&
              curr.currentQuest != prev.currentQuest) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        return WritingBaseLayout(
          disablePadding: true,
          gameType: widget.gameType,
          isFinalFailure: isLoaded ? state.isFinalFailure : false,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _isWiped,
              _selectedOption,
              _pendingSelectedOption,
              _erasedAmount,
              _shuffledOptions,
            ]),
            builder: (context, _) {
              return quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  FixTheSentenceInstruction(
                                    isWiped: _isWiped.value,
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                    errorType: quest.errorType,
                                  ),
                                  SizedBox(height: 32.h),

                                  FixTheSentenceDigitalBlackboard(
                                    fullText: quest.passage ?? "",
                                    targetWord: quest.missingWord ?? "",
                                    selectedReplacement:
                                        _selectedOption.value ??
                                        _pendingSelectedOption.value,
                                    isWiped: _isWiped.value,
                                    eraseListenable: _erasePoints,
                                    getErasePoints: () => _erasePoints.points,
                                    onErase: (pos) => _onErase(pos, isAnswered),
                                    onTap: () {
                                      if (isAnswered || _isWiped.value) {
                                        return;
                                      }
                                      hapticService.success();
                                      soundService.playHint();
                                      _isWiped.value = true;
                                    },
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 32.h),

                                  if (_isWiped.value)
                                    FixTheSentenceCorrectionOptions(
                                      options:
                                          _shuffledOptions.value ??
                                          quest.options ??
                                          [],
                                      correct: quest.correctAnswer ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onSelect: (selected, correct) {
                                        if (isAnswered) {
                                          return;
                                        }

                                        final isCorrect =
                                            selected
                                                .trim()
                                                .toLowerCase()
                                                .replaceAll(
                                                  RegExp(r'[^\w\s]'),
                                                  '',
                                                ) ==
                                            correct
                                                .trim()
                                                .toLowerCase()
                                                .replaceAll(
                                                  RegExp(r'[^\w\s]'),
                                                  '',
                                                );

                                        if (isCorrect) {
                                          hapticService.success();
                                          _pendingSelectedOption.value =
                                              selected;
                                          _scrollToBottom();
                                        } else {
                                          hapticService.error();
                                          submitWrongAnswer(
                                            quest: quest,
                                            userAnswer: selected,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_pendingSelectedOption.value != null &&
                                    !isAnswered) ...[
                                  SizedBox(height: 32.h),
                                  TypeToConfirmOverlay(
                                    expectedText: _pendingSelectedOption.value!,
                                    primaryColor: theme.primaryColor,
                                    onConfirmed: () =>
                                        _submitFinalAnswer(true, quest),
                                    onSkipped: () =>
                                        _submitFinalAnswer(false, quest),
                                    allowSkip: true,
                                    isPositioned: false,
                                  ),
                                ],
                                SizedBox(
                                  height: !isAnswered
                                      ? (_pendingSelectedOption.value != null
                                            ? MediaQuery.viewInsetsOf(
                                                    context,
                                                  ).bottom +
                                                  40.h
                                            : 60.h)
                                      : 160.h,
                                ),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                        40.h
                                  : 120.h,
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
  }
}

class _ErasePointsNotifier extends ChangeNotifier {
  final List<Offset> points = [];

  void add(Offset offset) {
    points.add(offset);
    notifyListeners();
  }

  void clear() {
    points.clear();
    notifyListeners();
  }
}
