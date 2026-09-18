import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_result.dart';

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

class _SentenceOrderReadingScreenState
    extends State<SentenceOrderReadingScreen> with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  final ValueNotifier<List<String>> _currentOrder = ValueNotifier([]);
        final ScrollController _scrollController = ScrollController();

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

    initReadingGame();
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

  void _submitAnswer(List<int> correctOrder, List<String> original) {
    if (isAnsweredNotifier.value) return;

    bool isCorrect = true;
    for (int i = 0; i < _currentOrder.value.length; i++) {
      if (_currentOrder.value[i] != original[correctOrder[i]]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _currentOrder,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
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
                                  SizedBox(height: 16.h),
                                  SentenceOrderReadingInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  ReorderableListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    proxyDecorator: (child, index, animation) =>
                                        _buildProxy(
                                          child,
                                          animation,
                                          theme.primaryColor,
                                        ),
                                    onReorder: _onReorder,
                                    children: List.generate(
                                      _currentOrder.value.length,
                                      (index) => SentenceOrderReadingStoneSlab(
                                        key: ValueKey(
                                          _currentOrder.value[index],
                                        ),
                                        text: _currentOrder.value[index],
                                        index: index,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        transitionWords: quest.transitionWords,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isAnsweredNotifier.value) ...[
                                    SizedBox(height: 24.h),
                                    SentenceOrderReadingCapstone(
                                      color: theme.primaryColor,
                                      onTap: () {
                                        hapticService.heavy();
                                        _submitAnswer(
                                          quest.correctOrder ?? [],
                                          quest.shuffledSentences ?? [],
                                        );
                                      },
                                    ),
                                  ],
                                  if (isAnsweredNotifier.value) ...[
                                    SizedBox(height: 30.h),
                                    SentenceOrderReadingResult(
                                      quest: quest,
                                      isCorrect: isCorrectNotifier.value == true,
                                      isDark: isDark,
                                    ),
                                  ],
                                  SizedBox(height: 50.h),
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
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
