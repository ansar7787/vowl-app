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
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_result.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

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
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _pinchWidth = ValueNotifier(1.0);
  final ValueNotifier<bool> _isDistilled = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _pinchWidth.dispose();
    _isDistilled.dispose();
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

  void _onPinchUpdate(double scale) {
    if (isAnsweredNotifier.value || _isDistilled.value) return;
    _pinchWidth.value = scale.clamp(0.4, 1.0);
    if (_pinchWidth.value < 0.6) {
      hapticService.selection();
    }
  }

  void _onPinchEnd() {
    if (isAnsweredNotifier.value || _isDistilled.value) return;
    if (_pinchWidth.value < 0.55) {
      hapticService.heavy();
      _isDistilled.value = true;
      _pinchWidth.value = 0.45;
    } else {
      _pinchWidth.value = 1.0;
    }
  }

  void _submitFinalAnswer(bool isCorrect, ReadingQuest quest) {
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isCorrect;

    if (isCorrect) {
      hapticService.success();
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _pinchWidth.value = 1.0;

    _isDistilled.value = false;
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
                  : Stack(
                      children: [
                        RawScrollbar(
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
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      GestureDetector(
                                        onScaleUpdate: (details) =>
                                            _onPinchUpdate(details.scale),
                                        onScaleEnd: (details) => _onPinchEnd(),
                                        child: ParagraphSummaryTube(
                                          passage: quest.passage ?? "",
                                          keywords: quest.keywords ?? [],
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          pinchWidth: _pinchWidth.value,
                                          isDistilled: _isDistilled.value,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        _isDistilled.value
                                            ? "DISTILLATION COMPLETE! THINK OF THE CORE SUMMARY AND REVEAL:"
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
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isAnsweredNotifier.value) ...[
                                        SizedBox(height: 30.h),
                                        ParagraphSummaryResult(
                                          quest: quest,
                                          isCorrect:
                                              isCorrectNotifier.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                      SizedBox(
                                        height:
                                            (_isDistilled.value &&
                                                !isAnsweredNotifier.value)
                                            ? 380.h
                                            : 60.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isDistilled.value && !isAnsweredNotifier.value)
                          TypeToConfirmOverlay(
                            expectedText: quest.correctAnswer ?? "",
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true, quest),
                            onSkipped: () => _submitFinalAnswer(false, quest),
                            allowSkip: true,
                            isPositioned: true,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
