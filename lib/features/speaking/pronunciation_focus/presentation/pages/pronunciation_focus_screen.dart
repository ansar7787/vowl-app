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
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

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

  final ValueNotifier<double> _heatLevel = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _tickerController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);

  final ValueNotifier<bool> _showGuide = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _tickerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _timeVal.value = _tickerController.value;
          });
    _tickerController.repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _heatLevel.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    _showGuide.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    _heatLevel.value = nailedIt ? 1.0 : 0.0;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: widget.gameType.name,
          userAnswer: '[Failed Pronunciation]',
          correctAnswer: 'Shadow Playback Compare Target',
          level: widget.level,
        );
      }
      
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    _isAnswered.value = true;
    _isCorrect.value = true;
    _heatLevel.value = 1.0;
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
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _heatLevel.value = 0.0;
            _showGuide.value = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            } else {
              _isAnswered.value = false;
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
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
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _heatLevel, _timeVal, _showGuide]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
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
                                heatLevel: _heatLevel.value,
                                showGuide: _showGuide.value,
                                onToggleGuide: () {
                                  _hapticService.selection();
                                  _showGuide.value = !_showGuide.value;
                                },
                              ),
                              SizedBox(height: 32.h),
                              PronunciationFocusThermalGrid(
                                heatLevel: _heatLevel.value,
                                isListening: false,
                                timeVal: _timeVal.value,
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered.value)
                                ShadowPlaybackCompare(
                                  expectedText: quest.textToSpeak ?? "",
                                  primaryColor: theme.primaryColor,
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
