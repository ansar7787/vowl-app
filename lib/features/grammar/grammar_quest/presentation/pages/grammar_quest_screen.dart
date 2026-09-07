import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentence.dart';

class GrammarQuestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GrammarQuestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.grammarQuest,
  });
  @override
  State<GrammarQuestScreen> createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingTypeSubmit.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;
  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitInitialAnswer(bool correct) {
    if (_isAnswered.value) return;
    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      _pendingTypeSubmit.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;
    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);
    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;
          if (isNewQuestion || isRetry || livesRestored) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingTypeSubmit.value = false;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SENTINEL!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        String targetText = "";
        String fullSentence = "";
        if (quest != null) {
          if (quest.options != null &&
              quest.options!.isNotEmpty &&
              quest.correctAnswerIndex != null &&
              quest.correctAnswerIndex! < quest.options!.length) {
            targetText = quest.options![quest.correctAnswerIndex!];
          } else {
            targetText = quest.correctAnswer ?? quest.sentence ?? "";
          }
          fullSentence = (quest.question ?? "").replaceAll('___', targetText);
        }
        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _pendingTypeSubmit,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
              disablePadding: true,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 0,
                          mainAxisMargin: 0,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 24.h),
                                      GrammarQuestInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                      SizedBox(height: 16.h),
                                      if (quest.grammarRule != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 24.h),
                                          padding: EdgeInsets.all(16.r),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.rule,
                                                    color: theme.primaryColor,
                                                    size: 16.sp,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    "GRAMMAR RULE",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme.primaryColor,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                quest.grammarRule!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (quest.ruleExplanation !=
                                                  null) ...[
                                                SizedBox(height: 8.h),
                                                Text(
                                                  quest.ruleExplanation!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 14.sp,
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      if (quest.question != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 24.h,
                                          ),
                                          child: GrammarQuestSentence(
                                            text:
                                                (_isAnswered.value ||
                                                    _pendingTypeSubmit.value)
                                                ? fullSentence
                                                : quest.question!,
                                            isDark:
                                                Theme.of(context).brightness ==
                                                Brightness.dark,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 16.h),
                                      GrammarQuestCompass(
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        primaryColor: theme.primaryColor,
                                        isDark:
                                            Theme.of(context).brightness ==
                                            Brightness.dark,
                                        isAnswered:
                                            _isAnswered.value ||
                                            _pendingTypeSubmit.value,
                                        isCorrect: _isCorrect.value,
                                        onQuadrantSelect: (index) {
                                          bool isCorrect =
                                              index == quest.correctAnswerIndex;
                                          _submitInitialAnswer(isCorrect);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_pendingTypeSubmit.value &&
                                  !_isAnswered.value &&
                                  targetText.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 32.h),
                                    child: TypeToConfirmOverlay(
                                      expectedText: fullSentence,
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _submitFinalAnswer(false),
                                      allowSkip: true,
                                      isPositioned: false,
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (_pendingTypeSubmit.value &&
                                          !_isAnswered.value &&
                                          targetText.isNotEmpty)
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            60.h
                                      : 60.h,
                                ),
                              ),
                            ],
                          ),
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
