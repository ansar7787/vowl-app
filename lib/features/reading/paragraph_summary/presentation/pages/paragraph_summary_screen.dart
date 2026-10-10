import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_instruction.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_tube.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_option_rack.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/pinch_hint_animation.dart';

class ParagraphSummaryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ParagraphSummaryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.paragraphSummary,
  });

  @override
  State<ParagraphSummaryScreen> createState() => _ParagraphSummaryScreenState();
}

class _ParagraphSummaryScreenState extends State<ParagraphSummaryScreen>
    with
        GameScreenMixin<ParagraphSummaryScreen>,
        ReadingGameScreenMixin<ParagraphSummaryScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _pinchWidth = ValueNotifier(1.0);
  final ValueNotifier<bool> _isDistilled = ValueNotifier(false);
  final ValueNotifier<bool> _isPinching = ValueNotifier(false);
  final ValueNotifier<bool> _hasPinchedOnce = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  String? _selectedOption;

  @override
  void dispose() {
    _pinchWidth.dispose();
    _isDistilled.dispose();
    _isPinching.dispose();
    _hasPinchedOnce.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isDistilled.addListener(() {
      if (_isDistilled.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
    initReadingGame();
  }

  void _onPinchStart() {
    if (isAnsweredNotifier.value || _isDistilled.value) return;
    _hasPinchedOnce.value = true;
    _isPinching.value = true;
  }

  void _onPinchUpdate(double scale) {
    if (isAnsweredNotifier.value || _isDistilled.value) return;

    final previousWidth = _pinchWidth.value;
    _pinchWidth.value = scale.clamp(0.4, 1.0);

    if (_pinchWidth.value < 0.6 && previousWidth >= 0.6) {
      hapticService.selection();
    }
  }

  void _onPinchEnd() {
    if (isAnsweredNotifier.value || _isDistilled.value) return;
    _isPinching.value = false;
    if (_pinchWidth.value < 0.55) {
      hapticService.heavy();
      _isDistilled.value = true;
      _pinchWidth.value = 1.0;
    } else {
      _pinchWidth.value = 1.0;
    }
  }

  void _submitFinalAnswer(String option, ReadingQuest quest) {
    if (isAnsweredNotifier.value) return;

    setState(() {
      _selectedOption = option;
    });

    final bool isCorrect =
        option.trim().toLowerCase() ==
        (quest.correctAnswer ?? '').trim().toLowerCase();

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: option);
    }
  }

  @override
  void onQuestionReset() {
    _pinchWidth.value = 1.0;
    _isDistilled.value = false;
    _hasPinchedOnce.value = false;
    _selectedOption = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
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
            _isDistilled,
            _pinchWidth,
            _isPinching,
            _hasPinchedOnce,
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
                                  SizedBox(height: 16.h),
                                  ParagraphSummaryInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  GestureDetector(
                                    onScaleStart: (_) => _onPinchStart(),
                                    onScaleUpdate: (details) =>
                                        _onPinchUpdate(details.scale),
                                    onScaleEnd: (details) => _onPinchEnd(),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ParagraphSummaryTube(
                                          passage: quest.passage ?? "",
                                          keywords: quest.keywords ?? [],
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          pinchWidth: _pinchWidth.value,
                                          isDistilled: _isDistilled.value,
                                          isPinching: _isPinching.value,
                                        ),
                                        if (!_hasPinchedOnce.value)
                                          PinchHintAnimation(
                                            color: theme.primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _isDistilled.value
                                        ? "DISTILLATION COMPLETE! CHOOSE THE BEST SUMMARY:"
                                        : "PINCH/SQUEEZE THE TUBE TO DISTILL CORE CONCEPTS",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: _isDistilled.value
                                          ? tokens.gameCorrect
                                          : theme.primaryColor.withValues(
                                              alpha: 0.6,
                                            ),
                                      fontSize: 11.sp,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                ],
                              ),
                            ),
                          ),
                          if (_isDistilled.value)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              sliver: SliverToBoxAdapter(
                                child: ParagraphSummaryOptionRack(
                                  options: quest.options ?? [],
                                  correctAnswer: quest.correctAnswer ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  selectedOption: _selectedOption,
                                  isAnswered: isAnsweredNotifier.value,
                                  onTapOption: (opt) =>
                                      _submitFinalAnswer(opt, quest),
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
