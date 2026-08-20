import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking_self_evaluation_controls.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_header.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_phoneme_crucible.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_thermal_grid.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_highlighted_sentence.dart';

class PronunciationFocusScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const PronunciationFocusScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronunciationFocus,
  });

  @override
  State<PronunciationFocusScreen> createState() =>
      _PronunciationFocusScreenState();
}

class _PronunciationFocusScreenState extends State<PronunciationFocusScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _heatLevel = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _tickerController;
  double _timeVal = 0.0;

  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _tickerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            setState(() {
              _timeVal = _tickerController.value;
            });
          });
    _tickerController.repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
      _heatLevel = nailedIt ? 1.0 : 0.0;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _heatLevel = 1.0;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _heatLevel = 0.0;
              _showGuide = false;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('speaking_games.critical_mass_fusion', fallback: 'CRITICAL MASS FUSION!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PronunciationFocusHeader(
                                primaryColor: theme.primaryColor,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              PronunciationFocusPhonemeCrucible(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                heatLevel: _heatLevel,
                                showGuide: _showGuide,
                                onToggleGuide: () {
                                  _hapticService.selection();
                                  setState(() => _showGuide = !_showGuide);
                                },
                              ),
                              SizedBox(height: 32.h),
                              PronunciationFocusThermalGrid(
                                heatLevel: _heatLevel,
                                isListening: false,
                                timeVal: _timeVal,
                                isDark: isDark,
                              ),
                              SizedBox(height: 32.h),
                              PronunciationFocusHighlightedSentence(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered)
                                SpeakingSelfEvaluationControls(
                                  expectedText: quest.textToSpeak ?? "",
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
