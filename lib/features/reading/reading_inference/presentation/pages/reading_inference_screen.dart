import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_instruction.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_foggy_mirror.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_result.dart';
import 'package:vowl/core/presentation/game_mechanics/reading_self_evaluation_card.dart';
import 'package:vowl/core/presentation/game_mechanics/evidence_highlight_wrapper.dart';

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

class _ReadingInferenceScreenState extends State<ReadingInferenceScreen> {
  final _hapticService = di.sl<HapticService>();

  final ValueNotifier<List<Offset>> _rubPoints = ValueNotifier([]);
  final ValueNotifier<double> _clarity = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _showEvidence = ValueNotifier(false);
  final ValueNotifier<bool> _evidenceFound = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _rubPoints.dispose();
    _clarity.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _showEvidence.dispose();
    _evidenceFound.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onRub(Offset point) {
    if (_isAnswered.value) return;
    _rubPoints.value = List.from(_rubPoints.value)..add(point);
    _clarity.value = (_rubPoints.value.length / 100).clamp(0.0, 1.0);
    if (_rubPoints.value.length % 5 == 0) {
      _hapticService.selection();
    }
  }

  void _submitSelfEvalAnswer(bool isCorrect, ReadingQuest quest) {
    _isAnswered.value = true;
    _isCorrect.value = isCorrect;

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
    _hapticService.success();
    _showEvidence.value = false;
    _evidenceFound.value = true;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _rubPoints.value = [];
            _clarity.value = 0.0;
            _showEvidence.value = false;
            _evidenceFound.value = false;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'reading_games.hidden_layer_synced',
              fallback: 'HIDDEN LAYER SYNCED!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _rubPoints,
            _clarity,
            _showEvidence,
            _evidenceFound,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? const SizedBox()
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
                                      ReadingInferenceInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction: InstructionHelper.getInstruction(quest),
                                      ),
                                      SizedBox(height: 32.h),

                                      ReadingInferenceFoggyMirror(
                                        passage: quest.passage ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isAnswered:
                                            _isAnswered.value ||
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
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
                                                _isAnswered.value,
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

                                      if (_isAnswered.value &&
                                          (!_showEvidence.value ||
                                              _evidenceFound.value)) ...[
                                        SizedBox(height: 30.h),
                                        ReadingInferenceResult(
                                          quest: quest,
                                          isCorrect: _isCorrect.value == true,
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
                            ],
                          ),
                        ),
                        if (_showEvidence.value)
                          EvidenceHighlightWrapper(
                            passage: quest.passage ?? "",
                            evidenceWords: quest.clueWords ?? [],
                            primaryColor: theme.primaryColor,
                            onCorrectHighlight: _onEvidenceFound,
                            instruction:
                                'Highlight the clue words that gave you the answer!',
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
