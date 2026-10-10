import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_option_card.dart';

class OpinionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const OpinionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.opinionWriting,
  });

  @override
  State<OpinionWritingScreen> createState() => _OpinionWritingScreenState();
}

class _OpinionWritingScreenState extends State<OpinionWritingScreen>
    with
        GameScreenMixin<OpinionWritingScreen>,
        WritingGameScreenMixin<OpinionWritingScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  WritingQuest? _lastQuest;
  bool _hasShuffled = false;
  List<String> _currentShuffledOptions = [];
  final ValueNotifier<List<String>> _draftedOptions = ValueNotifier([]);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _draftedOptions.dispose();
    disposeWritingGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _hasShuffled = false;
    _currentShuffledOptions = [];
    _draftedOptions.value = [];
  }

  void _submitAnswer(WritingQuest quest) {
    final requiredCount = quest.correctOrder?.length ?? 1;
    if (_draftedOptions.value.length < requiredCount) return;

    final correctOptions =
        quest.correctOrder?.map((idx) => quest.options![idx]).toSet() ?? {};

    final isCorrect =
        _draftedOptions.value.length == correctOptions.length &&
        _draftedOptions.value.every((opt) => correctOptions.contains(opt));

    if (isCorrect) {
      hapticService.success();
      submitCorrectAnswer();
    } else {
      hapticService.error();
      final userAns = 'Drafted: ${_draftedOptions.value.join(" | ")}';
      submitWrongAnswer(quest: quest, userAnswer: userAns);
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
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
          if (!_hasShuffled && state.currentQuest.options != null) {
            _hasShuffled = true;
            _currentShuffledOptions = List<String>.from(
              state.currentQuest.options!,
            );
            _currentShuffledOptions.shuffle();
          }
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = isLoaded
            ? state.isFinalFailure
            : (state is WritingGameOver);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: quest == null || quest.options == null
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : Builder(
                  builder: (context) {
                    return ValueListenableBuilder<List<String>>(
                      valueListenable: _draftedOptions,
                      builder: (context, draftedOptions, _) {
                        final requiredCount = quest.correctOrder?.length ?? 1;
                        final canSubmit =
                            draftedOptions.length == requiredCount;
                        final availableOptions = _currentShuffledOptions
                            .where((opt) => !draftedOptions.contains(opt))
                            .toList();
                        final correctOptionsSet =
                            quest.correctOrder
                                ?.map((idx) => quest.options![idx])
                                .toSet() ??
                            {};

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    if (quest.prompt != null ||
                                        quest.instruction.isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (quest.prompt != null)
                                              Padding(
                                                padding: EdgeInsets.all(20.w),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (quest.structureGuide !=
                                                        null) ...[
                                                      Text(
                                                        quest.structureGuide!
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 11.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.8,
                                                          color: theme
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8.h),
                                                    ],
                                                    Text(
                                                      quest.prompt!,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  )
                                                            : const Color(
                                                                0xFF334155,
                                                              ),
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (quest.instruction.isNotEmpty)
                                              Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20.w,
                                                  vertical: 16.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.05),
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                              16.r,
                                                            ),
                                                        bottomRight:
                                                            Radius.circular(
                                                              16.r,
                                                            ),
                                                      ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 1.h,
                                                      ),
                                                      child: Icon(
                                                        Icons.task_alt_rounded,
                                                        color:
                                                            theme.primaryColor,
                                                        size: 20.w,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Text(
                                                        quest.instruction,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 15.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F172A,
                                                                ),
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                    ],
                                    DragTarget<String>(
                                      onWillAcceptWithDetails: (details) {
                                        return !isAnswered &&
                                            draftedOptions.length <
                                                requiredCount;
                                      },
                                      onAcceptWithDetails: (details) {
                                        hapticService.selection();
                                        _draftedOptions.value = [
                                          ...draftedOptions,
                                          details.data,
                                        ];
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        return Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(20.w),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: candidateData.isNotEmpty
                                                  ? theme.primaryColor
                                                  : (isDark
                                                        ? Colors.white12
                                                        : Colors.black12),
                                              width: candidateData.isNotEmpty
                                                  ? 2
                                                  : 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_document,
                                                    color: theme.primaryColor,
                                                    size: 20.w,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    "Drafting Pad",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: theme.primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 16.h),
                                              ...List.generate(requiredCount, (
                                                index,
                                              ) {
                                                if (index <
                                                    draftedOptions.length) {
                                                  final option =
                                                      draftedOptions[index];
                                                  return OpinionWritingDraftedCard(
                                                    text: option,
                                                    isDark: isDark,
                                                    primaryColor:
                                                        theme.primaryColor,
                                                    isAnswered: isAnswered,
                                                    isCorrectOption:
                                                        correctOptionsSet
                                                            .contains(option),
                                                    onRemove: () {
                                                      if (isAnswered) return;
                                                      hapticService.selection();
                                                      final current =
                                                          List<String>.from(
                                                            _draftedOptions
                                                                .value,
                                                          );
                                                      current.remove(option);
                                                      _draftedOptions.value =
                                                          current;
                                                    },
                                                  );
                                                } else {
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: 12.h,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 20.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.02,
                                                                  )
                                                            : Colors.black
                                                                  .withValues(
                                                                    alpha: 0.02,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        border: Border.all(
                                                          color: isDark
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Drag option here...",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: 14.sp,
                                                            color: isDark
                                                                ? Colors.white38
                                                                : Colors
                                                                      .black38,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 24.h),
                                    if (availableOptions.isNotEmpty) ...[
                                      Text(
                                        "Idea Board",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      ...availableOptions.map((option) {
                                        if (isAnswered) {
                                          return OpinionWritingIdeaCard(
                                            text: option,
                                            isDark: isDark,
                                            primaryColor: theme.primaryColor,
                                          );
                                        }
                                        return Draggable<String>(
                                          data: option,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  48.w,
                                              child: OpinionWritingIdeaCard(
                                                text: option,
                                                isDark: isDark,
                                                primaryColor:
                                                    theme.primaryColor,
                                                isDragging: true,
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child: OpinionWritingIdeaCard(
                                              text: option,
                                              isDark: isDark,
                                              primaryColor: theme.primaryColor,
                                            ),
                                          ),
                                          child: OpinionWritingIdeaCard(
                                            text: option,
                                            isDark: isDark,
                                            primaryColor: theme.primaryColor,
                                          ),
                                        );
                                      }),
                                    ],
                                    SizedBox(height: 24.h),
                                  ]),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    children: [
                                      if (!isAnswered)
                                        ScaleButton(
                                          onTap: canSubmit
                                              ? () => _submitAnswer(quest)
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: canSubmit
                                                  ? theme.primaryColor
                                                  : Colors.grey.withValues(
                                                      alpha: 0.5,
                                                    ),
                                              boxShadow: canSubmit
                                                  ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 15,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "SUBMIT",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 120.h),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
