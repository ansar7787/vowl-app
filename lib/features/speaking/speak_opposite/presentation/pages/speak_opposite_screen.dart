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
import 'package:vowl/core/presentation/widgets/speaking_self_evaluation_controls.dart';

import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_header.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_positive_pole_panel.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_plasma_conduit_panel.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_negative_pole_panel.dart';

class SpeakOppositeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakOppositeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakOpposite,
  });

  @override
  State<SpeakOppositeScreen> createState() => _SpeakOppositeScreenState();
}

class _SpeakOppositeScreenState extends State<SpeakOppositeScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _pullProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _sparkController;
  double _timeVal = 0.0;

  List<String> _acceptedAntonyms = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _sparkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            setState(() {
              _timeVal = _sparkController.value;
            });
          });
    _sparkController.repeat();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
      _pullProgress = nailedIt ? 1.0 : 0.0;
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
      _pullProgress = 1.0;
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
              _pullProgress = 0.0;
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
            title: 'POLAR ANTIPODE FUSED!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _acceptedAntonyms = quest.acceptedSynonyms ?? [];
        }

        final expectedText = _acceptedAntonyms.isNotEmpty
            ? _acceptedAntonyms.first
            : "";

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
                              SpeakOppositeHeader(
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              SpeakOppositePositivePolePanel(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onPlayTts: () => _soundService.playTts(
                                  (quest.textToSpeak ?? "").replaceAll('*', ''),
                                ),
                              ),
                              SizedBox(height: 32.h),
                              SpeakOppositePlasmaConduitPanel(
                                pullProgress: _pullProgress,
                                primaryColor: theme.primaryColor,
                                isListening: false,
                                timeVal: _timeVal,
                                isDark: isDark,
                              ),
                              SizedBox(height: 32.h),
                              SpeakOppositeNegativePolePanel(
                                pullProgress: _pullProgress,
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
                                  expectedText: expectedText,
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
