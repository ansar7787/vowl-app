import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_instruction.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_floating_tile.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_assembly_card.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_check_button.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class WordReorderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordReorderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordReorder,
  });

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

      final ValueNotifier<List<int>> _availableIndices = ValueNotifier([]);
  final ValueNotifier<List<int>> _assembledIndices = ValueNotifier([]);
        final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _availableIndices.dispose();
    _assembledIndices.dispose();
                _pendingTypeSubmit.dispose();
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

  void _onWordTap(int index) {
    if (isAnsweredNotifier.value || _pendingTypeSubmit.value) return;
    hapticService.selection();
    _assembledIndices.value = List.from(_assembledIndices.value)..add(index);
    _availableIndices.value = List.from(_availableIndices.value)..remove(index);
  }

  void _onWordRemove(int index) {
    if (isAnsweredNotifier.value || _pendingTypeSubmit.value) return;
    hapticService.selection();
    _assembledIndices.value = List.from(_assembledIndices.value)..remove(index);
    _availableIndices.value = List.from(_availableIndices.value)
      ..add(index)
      ..sort();
  }

  void _checkSentence(List<int> correctOrder) {
    if (_assembledIndices.value.isEmpty) return;

    bool correct = _assembledIndices.value.length == correctOrder.length;
    if (correct) {
      for (int i = 0; i < correctOrder.length; i++) {
        if (_assembledIndices.value[i] != correctOrder[i]) {
          correct = false;
          break;
        }
      }
    }

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      _pendingTypeSubmit.value = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  double _lastKeyboardHeight = 0;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = keyboardHeight;
      if (keyboardHeight > 0 && _pendingTypeSubmit.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final hintUsed = (state is GrammarLoaded) ? state.hintUsed : false;
        final shuffledWords = quest?.shuffledWords ?? [];
        final correctOrder = quest?.correctOrder ?? [];
        final expectedNextIndex =
            (hintUsed && _assembledIndices.value.length < correctOrder.length)
            ? correctOrder[_assembledIndices.value.length]
            : -1;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingTypeSubmit,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : ListenableBuilder(
                      listenable: Listenable.merge([
                        _availableIndices,
                        _assembledIndices,
                      ]),
                      builder: (context, _) {
                        return LayoutBuilder(
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
                                      SliverPadding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        sliver: SliverList(
                                          delegate: SliverChildListDelegate([
                                            SizedBox(height: 10.h),
                                            Center(
                                              child: WordReorderInstruction(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                            if (quest.structureType != null)
                                              Container(
                                                margin: EdgeInsets.only(
                                                  bottom: 16.h,
                                                  left: 8.w,
                                                  right: 8.w,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 12.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .account_tree_outlined,
                                                      color: theme.primaryColor,
                                                      size: 16.sp,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Text(
                                                      "TARGET STRUCTURE: ${quest.structureType!.toUpperCase()}",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            theme.primaryColor,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            SizedBox(height: 8.h),
                                            WordReorderAssemblyCard(
                                              assembledIndices:
                                                  _assembledIndices.value,
                                              shuffledWords: shuffledWords,
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                              isAnswered:
                                                  isAnsweredNotifier.value ||
                                                  _pendingTypeSubmit.value,
                                              onWordRemove: _onWordRemove,
                                            ),
                                            SizedBox(height: 32.h),
                                            Wrap(
                                              spacing: 12.w,
                                              runSpacing: 16.h,
                                              alignment: WrapAlignment.center,
                                              children: _availableIndices.value
                                                  .map((idx) {
                                                    return WordReorderFloatingTile(
                                                      word: shuffledWords[idx],
                                                      index: idx,
                                                      onTap: () =>
                                                          _onWordTap(idx),
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      isHighlighted:
                                                          idx ==
                                                          expectedNextIndex,
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                            SizedBox(height: 32.h),
                                            if (!isAnsweredNotifier.value &&
                                                !_pendingTypeSubmit.value)
                                              WordReorderCheckButton(
                                                hasWords:
                                                    _assembledIndices
                                                        .value
                                                        .length ==
                                                    correctOrder.length,
                                                isDark: isDark,
                                                primaryColor:
                                                    theme.primaryColor,
                                                onCheck: () => _checkSentence(
                                                  correctOrder,
                                                ),
                                              ),
                                          ]),
                                        ),
                                      ),
                                      if (_pendingTypeSubmit.value &&
                                          !isAnsweredNotifier.value)
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: 16.h,
                                              bottom: 24.h,
                                            ),
                                            child: TypeToConfirmOverlay(
                                              expectedText:
                                                  quest.sentence ??
                                                  correctOrder
                                                      .map(
                                                        (idx) =>
                                                            shuffledWords[idx],
                                                      )
                                                      .join(" "),
                                              primaryColor: theme.primaryColor,
                                              onConfirmed: () =>
                                                  _submitFinalAnswer(true),
                                              onSkipped: () =>
                                                  _submitFinalAnswer(false),
                                              isPositioned: false,
                                            ),
                                          ),
                                        ),
                                      SliverToBoxAdapter(
                                        child: SizedBox(
                                          height:
                                              MediaQuery.viewInsetsOf(
                                                context,
                                              ).bottom +
                                              ((_pendingTypeSubmit.value &&
                                                      !isAnsweredNotifier.value)
                                                  ? 16.h
                                                  : 60.h),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
