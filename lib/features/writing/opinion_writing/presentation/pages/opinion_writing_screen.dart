import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
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
      submitCorrectAnswer();
    } else {
      final userAns = 'Drafted: ${_draftedOptions.value.join(" | ")}';
      submitWrongAnswer(quest: quest, userAnswer: userAns);
    }
  }

  Widget _buildInstructionBanner({
    required String instruction,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: primaryColor,
            size: 20.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.task_alt_rounded,
            color: Colors.transparent,
            size: 20.r,
          ),
        ],
      ),
    );
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
          onHint: () {},
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

                        final rawInstruction = InstructionHelper.getInstruction(quest);
                        final displayInstruction = rawInstruction.isNotEmpty
                            ? rawInstruction
                            : quest.instruction;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            key: const Key('opinion_writing_scroll_view'),
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1. Centered balanced instruction banner
                                      if (displayInstruction.isNotEmpty) ...[
                                        _buildInstructionBanner(
                                          instruction: displayInstruction,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                        ),
                                        SizedBox(height: 14.h),
                                      ],

                                      // 2. Scenario / Context Prompt Card
                                      if (quest.prompt != null) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(18.w),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16.r),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white12
                                                  : const Color(0xFFE2E8F0),
                                              width: 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.03,
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
                                              if (quest.structureGuide !=
                                                      null &&
                                                  quest.structureGuide!
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    quest.structureGuide!
                                                        .toUpperCase(),
                                                    softWrap: true,
                                                    maxLines: null,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 11.5.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.6,
                                                      color:
                                                          theme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                              ],
                                              Text(
                                                quest.prompt!,
                                                softWrap: true,
                                                maxLines: null,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 15.5.sp,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.9,
                                                        )
                                                      : const Color(
                                                          0xFF1E293B,
                                                        ),
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 18.h),
                                      ],

                                      // 3. Selection Drop Target ("Your Selection" / "Your Answer")
                                      DragTarget<String>(
                                        onWillAcceptWithDetails: (details) {
                                          return !isAnswered &&
                                              draftedOptions.length <
                                                  requiredCount &&
                                              !draftedOptions.contains(
                                                details.data,
                                              );
                                        },
                                        onAcceptWithDetails: (details) {
                                          hapticService.selection();
                                          _draftedOptions.value = [
                                            ...draftedOptions,
                                            details.data,
                                          ];
                                        },
                                        builder: (
                                          context,
                                          candidateData,
                                          rejectedData,
                                        ) {
                                          final isHovering =
                                              candidateData.isNotEmpty;
                                          return Container(
                                            key: const Key(
                                              'opinion_drafting_pad_target',
                                            ),
                                            width: double.infinity,
                                            padding: EdgeInsets.all(16.w),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: isHovering
                                                    ? theme.primaryColor
                                                    : (isDark
                                                        ? Colors.white12
                                                        : const Color(
                                                            0xFFE2E8F0,
                                                          )),
                                                width: isHovering ? 2.0 : 1.0,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .assignment_turned_in_rounded,
                                                      color:
                                                          theme.primaryColor,
                                                      size: 18.r,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Expanded(
                                                      child: Text(
                                                        requiredCount > 1
                                                            ? "Your Selection"
                                                            : "Your Answer",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              theme.primaryColor,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8.w,
                                                            vertical: 3.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.r,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "${draftedOptions.length}/$requiredCount",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: theme
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 14.h),
                                                ...List.generate(
                                                  requiredCount,
                                                  (index) {
                                                    if (index <
                                                        draftedOptions.length) {
                                                      final option =
                                                          draftedOptions[index];
                                                      return OpinionWritingDraftedCard(
                                                        key: Key(
                                                          'opinion_drafted_card_$option',
                                                        ),
                                                        text: option,
                                                        isDark: isDark,
                                                        primaryColor:
                                                            theme.primaryColor,
                                                        isAnswered: isAnswered,
                                                        isCorrectOption:
                                                            correctOptionsSet
                                                                .contains(
                                                                  option,
                                                                ),
                                                        onRemove: isAnswered
                                                            ? null
                                                            : () {
                                                                hapticService
                                                                    .selection();
                                                                final current =
                                                                    List<
                                                                      String
                                                                    >.from(
                                                                      _draftedOptions
                                                                          .value,
                                                                    );
                                                                current.remove(
                                                                  option,
                                                                );
                                                                _draftedOptions
                                                                        .value =
                                                                    current;
                                                              },
                                                      );
                                                    } else {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              bottom: 12.h,
                                                            ),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    16.w,
                                                                vertical: 16.h,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: isDark
                                                                    ? Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.03,
                                                                          )
                                                                    : Colors
                                                                          .black
                                                                          .withValues(
                                                                            alpha:
                                                                                0.02,
                                                                          ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      14.r,
                                                                    ),
                                                                border:
                                                                    Border.all(
                                                                      color: isDark
                                                                          ? Colors
                                                                                .white12
                                                                          : theme
                                                                                .primaryColor
                                                                                .withValues(
                                                                                  alpha:
                                                                                      0.2,
                                                                                ),
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                          child: Center(
                                                            child: Text(
                                                              "Tap or drag an option here",
                                                              softWrap: true,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    14.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: isDark
                                                                    ? Colors
                                                                          .white38
                                                                    : const Color(
                                                                        0xFF94A3B8,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 20.h),

                                      // 4. Options List
                                      if (availableOptions.isNotEmpty) ...[
                                        Text(
                                          "Options",
                                          softWrap: true,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF64748B),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        ...availableOptions.map((option) {
                                          if (isAnswered) {
                                            return OpinionWritingIdeaCard(
                                              key: Key(
                                                'opinion_idea_card_$option',
                                              ),
                                              text: option,
                                              isDark: isDark,
                                              primaryColor: theme.primaryColor,
                                            );
                                          }

                                          void handleTap() {
                                            if (draftedOptions.length <
                                                    requiredCount &&
                                                !draftedOptions.contains(
                                                  option,
                                                )) {
                                              hapticService.selection();
                                              _draftedOptions.value = [
                                                ...draftedOptions,
                                                option,
                                              ];
                                            }
                                          }

                                          return Draggable<String>(
                                            key: Key(
                                              'opinion_draggable_$option',
                                            ),
                                            data: option,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                          context,
                                                        ).size.width -
                                                    40.w,
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
                                              opacity: 0.35,
                                              child: OpinionWritingIdeaCard(
                                                text: option,
                                                isDark: isDark,
                                                primaryColor:
                                                    theme.primaryColor,
                                              ),
                                            ),
                                            child: OpinionWritingIdeaCard(
                                              key: Key(
                                                'opinion_idea_card_$option',
                                              ),
                                              text: option,
                                              isDark: isDark,
                                              primaryColor: theme.primaryColor,
                                              onTap: handleTap,
                                            ),
                                          );
                                        }),
                                      ],
                                      SizedBox(height: 24.h),

                                      // 5. Submit Button ("Check Answer")
                                      if (!isAnswered)
                                        ScaleButton(
                                          key: const Key(
                                            'opinion_writing_submit_button',
                                          ),
                                          onTap: canSubmit
                                              ? () => _submitAnswer(quest)
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: double.infinity,
                                            height: 54.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              color: canSubmit
                                                  ? theme.primaryColor
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08,
                                                        )
                                                      : const Color(
                                                          0xFFE2E8F0,
                                                        )),
                                              boxShadow: canSubmit
                                                  ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.28,
                                                            ),
                                                        blurRadius: 14,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : const [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Check Answer",
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: canSubmit
                                                      ? Colors.white
                                                      : (isDark
                                                          ? Colors.white38
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            )),
                                                  letterSpacing: 0.4,
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
