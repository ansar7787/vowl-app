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
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_instruction.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_foggy_mirror.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_result.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/reading_self_evaluation_card.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';

class ReadingInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingInference,
  });

  @override
  State<ReadingInferenceScreen> createState() => _ReadingInferenceScreenState();
}

class _ReadingInferenceScreenState extends State<ReadingInferenceScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<List<Offset>> _rubPoints = ValueNotifier([]);
  final ValueNotifier<double> _clarity = ValueNotifier(0.0);
  final ValueNotifier<bool> _showEvidence = ValueNotifier(false);
  final ValueNotifier<bool> _evidenceFound = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _rubPoints.dispose();
    _clarity.dispose();
    _showEvidence.dispose();
    _evidenceFound.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showEvidence.addListener(() {
      if (_showEvidence.value && mounted && _scrollController.hasClients) {
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

  void _onRub(Offset point) {
    if (isAnsweredNotifier.value) return;
    _rubPoints.value = List.from(_rubPoints.value)..add(point);
    _clarity.value = (_rubPoints.value.length / 100).clamp(0.0, 1.0);
    if (_rubPoints.value.length % 5 == 0) {
      hapticService.selection();
    }
  }

  void _submitSelfEvalAnswer(bool isCorrect, ReadingQuest quest) {
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isCorrect;

    if (isCorrect) {
      if (quest.clueWords != null && quest.clueWords!.isNotEmpty) {
        _showEvidence.value = true;
      } else {
        context.read<ReadingBloc>().add(const SubmitAnswer(true));
      }
    } else {
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onEvidenceFound() {
    hapticService.success();
    _showEvidence.value = false;
    _evidenceFound.value = true;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _rubPoints.value = [];

    _clarity.value = 0.0;

    _showEvidence.value = false;

    _evidenceFound.value = false;
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
            _rubPoints,
            _clarity,
            _showEvidence,
            _evidenceFound,
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
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
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
                                  ReadingInferenceInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 32.h),

                                  ReadingInferenceFoggyMirror(
                                    passage: quest.passage ?? "",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    isAnswered:
                                        isAnsweredNotifier.value ||
                                        _showEvidence.value,
                                    rubPoints: _rubPoints.value,
                                    clarity: _clarity.value,
                                    onRub: _onRub,
                                  ),
                                  SizedBox(height: 32.h),

                                  Text(
                                    quest.question?.toUpperCase() ??
                                        "INFER THE HIDDEN TRUTH",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: theme.primaryColor,
                                      letterSpacing: 1.5,
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
                                  SizedBox(height: 24.h),
                                  if (!_showEvidence.value &&
                                      !_evidenceFound.value)
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      opacity: _clarity.value >= 0.3
                                          ? 1.0
                                          : 0.3,
                                      child: AbsorbPointer(
                                        absorbing:
                                            _clarity.value < 0.3 ||
                                            isAnsweredNotifier.value,
                                        child: ReadingSelfEvaluationCard(
                                          correctAnswer:
                                              quest.correctAnswer ?? "",
                                          explanation: quest.explanation,
                                          primaryColor: theme.primaryColor,
                                          onEvaluated: (isCorrect) =>
                                              _submitSelfEvalAnswer(
                                                isCorrect,
                                                quest,
                                              ),
                                        ),
                                      ),
                                    ),

                                  if (isAnsweredNotifier.value &&
                                      (!_showEvidence.value ||
                                          _evidenceFound.value)) ...[
                                    SizedBox(height: 30.h),
                                    ReadingInferenceResult(
                                      quest: quest,
                                      isCorrect:
                                          isCorrectNotifier.value == true,
                                      isDark: isDark,
                                    ),
                                  ],
                                  SizedBox(
                                    height: (_showEvidence.value)
                                        ? 380.h
                                        : 60.h,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_showEvidence.value)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: EvidenceHighlightWrapper(
                                  passage: quest.passage ?? "",
                                  evidenceWords: quest.clueWords ?? [],
                                  primaryColor: theme.primaryColor,
                                  onCorrectHighlight: _onEvidenceFound,
                                  instruction:
                                      'Highlight the clue words that gave you the answer!',
                                  isPositioned: false,
                                ),
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
                    ),
            );
          },
        );
      },
    );
  }
}
