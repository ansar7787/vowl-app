import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
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
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_option.dart';
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
    with
        GameScreenMixin<ReadingInferenceScreen>,
        ReadingGameScreenMixin<ReadingInferenceScreen> {
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
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _rubPoints.dispose();
    _clarity.dispose();
    _showEvidence.dispose();
    _evidenceFound.dispose();
    _selectedIndex.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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

  void _submitAnswer(int index, ReadingQuest quest) {
    if (isAnsweredNotifier.value || quest.options == null || _clarity.value < 0.3) return;

    _selectedIndex.value = index;
    final String selectedText = quest.options![index];
    final bool isCorrect =
        selectedText.trim().toLowerCase() == quest.correctAnswer?.trim().toLowerCase();

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;

      if (quest.clueWords != null && quest.clueWords!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showEvidence.value = true;
        });
      } else {
        context.read<ReadingBloc>().add(const SubmitAnswer(true));
      }
    } else {
      submitWrongAnswer(quest: quest, userAnswer: selectedText);
    }
  }

  void _onEvidenceFound() {
    hapticService.success();
    soundService.playCorrect();
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
    _selectedIndex.value = null;
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
            _showEvidence,
            _evidenceFound,
            _selectedIndex,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value &&
                  (!(quest?.clueWords?.isNotEmpty ?? false) || 
                   _evidenceFound.value || 
                   isCorrectNotifier.value == false),
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

                                  ListenableBuilder(
                                    listenable: Listenable.merge([_rubPoints, _clarity, _showEvidence, _evidenceFound]),
                                    builder: (context, _) {
                                      return Column(
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 500),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            child: (_showEvidence.value || _evidenceFound.value)
                                                ? EvidenceHighlightWrapper(
                                                    key: const ValueKey('evidence'),
                                                    passage: quest.passage ?? "",
                                                    evidenceWords: quest.clueWords ?? [],
                                                    primaryColor: theme.primaryColor,
                                                    onCorrectHighlight: _onEvidenceFound,
                                                    instruction:
                                                        'Highlight the clue words that gave you the answer!',
                                                    isPositioned: false,
                                                  )
                                                : ReadingInferenceFoggyMirror(
                                                    key: const ValueKey('mirror'),
                                                    passage: quest.passage ?? "",
                                                    color: theme.primaryColor,
                                                    isDark: isDark,
                                                    isAnswered: isAnsweredNotifier.value,
                                                    rubPoints: _rubPoints.value,
                                                    clarity: _clarity.value,
                                                    onRub: _onRub,
                                                  ),
                                          ),
                                          if (!_showEvidence.value &&
                                              !_evidenceFound.value &&
                                              _clarity.value < 1.0)
                                            Padding(
                                              padding: EdgeInsets.only(top: 8.h),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    hapticService.selection();
                                                    _clarity.value = 1.0;
                                                  },
                                                  icon: Icon(
                                                    Icons.accessibility_new_rounded,
                                                    size: 14.sp,
                                                    color: theme.primaryColor.withValues(alpha: 0.7),
                                                  ),
                                                  label: Text(
                                                    'Auto-Clear Fog',
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 12.sp,
                                                      fontWeight: FontWeight.w700,
                                                      color: theme.primaryColor.withValues(alpha: 0.7),
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: 24.h),

                                  ListenableBuilder(
                                    listenable: Listenable.merge([_showEvidence, _evidenceFound]),
                                    builder: (context, _) {
                                      if (_showEvidence.value || _evidenceFound.value) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        quest.question ?? "Infer the hidden truth:",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      );
                                    }
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
                                  ListenableBuilder(
                                    listenable: Listenable.merge([_showEvidence, _evidenceFound]),
                                    builder: (context, _) {
                                      if (quest.options != null) {
                                        return ValueListenableBuilder<double>(
                                          valueListenable: _clarity,
                                          builder: (context, clarityVal, _) {
                                            return Column(
                                              children: quest.options!.asMap().entries.map((entry) {
                                                return ReadingInferenceOption(
                                                  index: entry.key,
                                                  text: entry.value,
                                                  correct: quest.correctAnswer ?? "",
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  selectedIndex: _selectedIndex.value,
                                                  isAnswered: isAnsweredNotifier.value,
                                                  clarity: clarityVal,
                                                  onTap: () => _submitAnswer(entry.key, quest),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom + 40.h
                                  : 240.h,
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

