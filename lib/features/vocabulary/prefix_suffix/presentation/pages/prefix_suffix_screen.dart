import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_mission_control.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_synthesizer.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Interactive word synthesis screen where learners attach prefixes and suffixes to base roots.
class PrefixSuffixScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Whether this session is running as a mastery bonus stage.
  final bool isBonusStage;

  /// Creates a [PrefixSuffixScreen] instance.
  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
    this.isBonusStage = false,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen>
    with
        GameScreenMixin<PrefixSuffixScreen>,
        VocabularyGameScreenMixin<PrefixSuffixScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late final PrefixSuffixController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToStage2 = false;
  Timer? _scrollTimer;

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.isFirstStagePassed &&
        !_controller.isAnswered &&
        !_hasScrolledToStage2) {
      _hasScrolledToStage2 = true;
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _scrollToBottom();
      });
    } else if (!_controller.isFirstStagePassed) {
      _hasScrolledToStage2 = false;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = PrefixSuffixController(
      hapticService: di.sl<HapticService>(),
      soundService: di.sl<SoundService>(),
      ttsService: di.sl<TtsService>(),
      isBonusStage: widget.isBonusStage,
      onSubmitAnswer: (bool isCorrect, {quest, userAnswer}) {
        if (mounted) {
          if (isCorrect) {
            submitCorrectAnswer();
          } else {
            final q = quest ?? _controller.lastQuest;
            if (q != null) {
              submitWrongAnswer(quest: q, userAnswer: userAnswer);
            } else {
              submitWrongAnswer(quest: quest!, userAnswer: '');
            }
          }
        }
      },
    );

    _controller.addListener(_onControllerUpdate);

    initVocabularyGame();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _scrollController.dispose();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _hasScrolledToStage2 = false;
    final state = context.read<VocabularyBloc>().state;
    if (state is VocabularyLoaded) {
      _controller.reset(state.currentQuestOrNull, state.currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _controller.lastQuest;

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final baseLayout = VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              isFinalFailure: (state is VocabularyLoaded)
                  ? state.isFinalFailure
                  : false,
              showConfetti: _controller.showConfetti,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              disablePadding: true,
              useScrolling: false,
              onHint: () {
                _controller.onHint(quest);
              },
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;

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
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: _controller.isFirstStagePassed
                                        ? 0
                                        : maxHeight,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 16.h,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PrefixSuffixMissionControl(
                                          primaryColor: theme.primaryColor,
                                          instruction:
                                              quest.hint ??
                                              InstructionHelper.getInstruction(
                                                quest,
                                              ),
                                        ),
                                        SizedBox(height: 24.h),
                                        IgnorePointer(
                                          ignoring:
                                              _controller.isFirstStagePassed,
                                          child: PrefixSuffixSynthesizer(
                                            rootWord: quest.rootWord ?? "???",
                                            options: quest.options ?? [],
                                            correctAnswer:
                                                quest.correctAnswer ?? "",
                                            targetWord: _controller
                                                .getTargetWord(quest),
                                            selectedAffix:
                                                _controller.selectedAffix,
                                            hintedAffix:
                                                _controller.hintedAffix,
                                            isFirstStagePassed:
                                                _controller.isFirstStagePassed,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onAffixSelected:
                                                (affix, isPrefix) =>
                                                    _controller.onAffixSelected(
                                                      affix,
                                                      quest,
                                                      isPrefix,
                                                    ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: _controller.isFirstStagePassed
                                              ? 16.h
                                              : 32.h,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_controller.isFirstStagePassed &&
                                  !_controller.isAnswered)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 20.w,
                                      right: 20.w,
                                      bottom:
                                          24.h +
                                          MediaQuery.viewInsetsOf(
                                            context,
                                          ).bottom,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.isBonusStage) ...[
                                          Container(
                                            margin: EdgeInsets.only(bottom: 12.h),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 10.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(
                                                alpha: isDark ? 0.15 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: Colors.amber
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.stars_rounded,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8.w),
                                                Flexible(
                                                  child: Text(
                                                    '⚡ BONUS XP ARENA: Affix Fusion Successful (+50 XP)! Type to confirm or bank your win.',
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      color: isDark
                                                          ? Colors.amber.shade200
                                                          : Colors.amber.shade900,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        TypeToConfirmOverlay(
                                          isPositioned: false,
                                          expectedText: _controller.getTargetWord(
                                            quest,
                                          ),
                                          displayText: _controller
                                              .getTargetWord(quest)
                                              .toUpperCase(),
                                          displayFontSize: 22.sp,
                                          displayFontWeight: FontWeight.w700,
                                          hintText: 'Type the full word',
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () => _controller
                                              .submitFinalAnswer(true, quest),
                                          onBypassed: () => _controller
                                              .submitFinalAnswer(true, quest),
                                          onSkipped: () => widget.isBonusStage
                                              ? _controller
                                                  .submitFinalBonusVictory(true)
                                              : _controller
                                                  .submitFinalAnswer(false, quest),
                                        ),
                                        if (widget.isBonusStage) ...[
                                          SizedBox(height: 12.h),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44.h,
                                            child: OutlinedButton.icon(
                                              key: const Key(
                                                'prefix_suffix_bonus_bank_button',
                                              ),
                                              onPressed: () => _controller
                                                  .submitFinalBonusVictory(true),
                                              icon: const Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                              label: Text(
                                                'Bank Victory (+50 XP)',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.amber.shade200
                                                      : Colors.amber.shade800,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.amber.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12.r),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            );
            return baseLayout;
          },
        );
      },
    );
  }
}
