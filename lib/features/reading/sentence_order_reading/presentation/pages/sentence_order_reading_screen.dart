import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_instruction.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_stone_slab.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_capstone.dart';

class SentenceOrderReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceOrderReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceOrderReading,
  });

  @override
  State<SentenceOrderReadingScreen> createState() =>
      _SentenceOrderReadingScreenState();
}

class _SentenceOrderReadingScreenState extends State<SentenceOrderReadingScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<List<String>> _currentOrder = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();
  RegExp? _transitionRegex;

  @override
  void dispose() {
    _currentOrder.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initReadingGame();
  }

  @override
  void onReadingStateChanged(BuildContext context, ReadingState state) {
    super.onReadingStateChanged(context, state);
    if (state is ReadingLoaded) {
      if (_currentOrder.value.isEmpty) {
        final quest = state.currentQuest;
        if (quest.shuffledSentences != null) {
          final list = List<String>.from(quest.shuffledSentences!);

          if (quest.correctOrder != null && list.length > 1) {
            final correctStrings = quest.correctOrder!
                .map((idx) => quest.shuffledSentences![idx])
                .toList();

            bool isSame = true;
            int attempts = 0;
            // Shuffle until it's NOT the correct order to prevent free wins
            while (isSame && attempts < 10) {
              list.shuffle();
              isSame = false;
              for (int i = 0; i < list.length; i++) {
                if (list[i] != correctStrings[i]) {
                  break;
                }
                if (i == list.length - 1) {
                  isSame = true; // All matched
                }
              }
              attempts++;
            }
          } else {
            list.shuffle();
          }

          _currentOrder.value = list;
        }

        if (quest.transitionWords != null &&
            quest.transitionWords!.isNotEmpty) {
          final sortedWords = List<String>.from(quest.transitionWords!)
            ..sort((a, b) => b.length.compareTo(a.length));
          final pattern = sortedWords
              .map((e) => r'\b' + RegExp.escape(e) + r'(?!\w)')
              .join('|');
          _transitionRegex = RegExp('($pattern)', caseSensitive: false);
        } else {
          _transitionRegex = null;
        }
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (isAnsweredNotifier.value) return;
    final List<String> current = List.from(_currentOrder.value);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    _currentOrder.value = current;
    hapticService.selection();
  }

  void _submitAnswer(ReadingQuest quest) {
    if (isAnsweredNotifier.value) return;

    final correctOrder = quest.correctOrder ?? [];
    final original = quest.shuffledSentences ?? [];

    bool isCorrect = true;
    if (_currentOrder.value.length != correctOrder.length) {
      isCorrect = false;
    } else {
      for (int i = 0; i < _currentOrder.value.length; i++) {
        final expectedIndex = correctOrder[i];
        if (expectedIndex < 0 || expectedIndex >= original.length) {
          isCorrect = false;
          break;
        }
        if (_currentOrder.value[i] != original[expectedIndex]) {
          isCorrect = false;
          break;
        }
      }
    }

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(
        quest: quest,
        userAnswer: _currentOrder.value.join(' | '),
      );
    }
  }

  @override
  void onQuestionReset() {
    _currentOrder.value = [];
    _transitionRegex = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _currentOrder,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
              child: quest == null
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
                                  SizedBox(height: 24.h),
                                  SentenceOrderReadingInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction: quest.instruction,
                                  ),
                                  SizedBox(height: 32.h),
                                ],
                              ),
                            ),
                          ),
                          if (quest.shuffledSentences != null)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              sliver: SliverReorderableList(
                                itemCount: _currentOrder.value.length,
                                proxyDecorator: (child, index, animation) =>
                                    _buildProxy(
                                      child,
                                      animation,
                                      theme.primaryColor,
                                    ),
                                onReorder: _onReorder,
                                itemBuilder: (context, index) {
                                  return ReorderableDelayedDragStartListener(
                                    index: index,
                                    key: ValueKey(_currentOrder.value[index]),
                                    child: SentenceOrderReadingStoneSlab(
                                      key: ValueKey(
                                        'slab_${_currentOrder.value[index]}',
                                      ),
                                      text: _currentOrder.value[index],
                                      index: index,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      transitionRegex: _transitionRegex,
                                    ),
                                  );
                                },
                              ),
                            ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  if (!isAnsweredNotifier.value) ...[
                                    SizedBox(height: 24.h),
                                    SentenceOrderReadingCapstone(
                                      color: theme.primaryColor,
                                      onTap: () {
                                        hapticService.heavy();
                                        _submitAnswer(quest);
                                      },
                                    ),
                                  ],
                                  SizedBox(
                                    height:
                                        MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom >
                                            0
                                        ? MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom +
                                              40.h
                                        : 120.h,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildProxy(Widget child, Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = lerpDouble(1, 1.05, animation.value)!;
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}
