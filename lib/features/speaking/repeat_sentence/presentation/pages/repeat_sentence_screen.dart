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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_instruction.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_audition_card.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RepeatSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.repeatSentence,
  });

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  Timer? _autoplayTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (_isAnswered.value) return;
    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
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
          question: quest.instruction,
          userAnswer: '[Pronunciation Error]',
          correctAnswer: quest.textToSpeak ?? '',
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
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

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
            _autoplayTimer?.cancel();
            _autoplayTimer = Timer(const Duration(milliseconds: 300), () {
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
            title: context.tr('speaking_games.sound_wave_transcriber', fallback: 'SOUND WAVE TRANSCRIBER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti]),
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
                              RepeatSentenceInstruction(
                                primaryColor: theme.primaryColor,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              RepeatSentenceAuditionCard(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onPlayTts: () => _soundService.playTts(
                                  quest.textToSpeak ?? "",
                                ),
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
                                      _submitVerbalEvaluation(true, quest),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false, quest),
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
