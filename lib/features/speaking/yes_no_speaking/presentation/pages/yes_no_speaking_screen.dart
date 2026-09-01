import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_header_instruction.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_audition_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tilt_arena.dart';

class YesNoSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const YesNoSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.yesNoSpeaking,
  });

  @override
  State<YesNoSpeakingScreen> createState() => _YesNoSpeakingScreenState();
}

class _YesNoSpeakingScreenState extends State<YesNoSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;

  final ValueNotifier<double> _tiltValue = ValueNotifier(0.0);
  final ValueNotifier<bool> _isSnapped = ValueNotifier(false);

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  Timer? _autoplayTimer;

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
    _tiltValue.dispose();
    _isSnapped.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.prompt != null) {
      _soundService.playTts(quest.prompt!);
    }
  }

  void _onTiltDragged(DragUpdateDetails details, double trackWidth) {
    if (_isAnswered.value || _isSnapped.value) return;

    final double deltaNormalized = details.delta.dx / (trackWidth / 2);
    _hapticService.selection();

    _tiltValue.value = (_tiltValue.value + deltaNormalized).clamp(-1.0, 1.0);

    if (_tiltValue.value <= -0.85) {
      _tiltValue.value = -1.0;
      _isSnapped.value = true;
      _soundService.playClick();
      _hapticService.selection();
    } else if (_tiltValue.value >= 0.85) {
      _tiltValue.value = 1.0;
      _isSnapped.value = true;
      _soundService.playClick();
      _hapticService.selection();
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, bool expectedMatch) {
    if (_isAnswered.value || !_isSnapped.value) return;

    final bool chosenMatch = _tiltValue.value > 0;
    final bool binaryIsCorrect = chosenMatch == expectedMatch;
    final bool isOverallCorrect = binaryIsCorrect && nailedIt;

    _isAnswered.value = true;
    _isCorrect.value = isOverallCorrect;

    if (isOverallCorrect) {
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
          question: 'Explain why (Yes/No)',
          userAnswer: '[Failed Self-Evaluation]',
          correctAnswer: 'Expected match',
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
            _isSnapped.value = false;
            _tiltValue.value = 0.0;
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
            title: context.tr('speaking_games.binary_responder', fallback: 'BINARY RESPONDER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        final String rawPrompt = quest?.prompt ?? "";
        final String rawSample = quest?.sampleAnswer ?? "";
        final bool doTheyMatch =
            rawPrompt.trim().toLowerCase() == rawSample.trim().toLowerCase();

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isSnapped, _tiltValue]),
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
                              YesNoSpeakingHeaderInstruction(
                                primaryColor: theme.primaryColor,
                                isSnapped: _isSnapped.value,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              YesNoSpeakingAuditionCard(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onPlayTts: () => _soundService.playTts(
                                  quest.prompt ?? "",
                                ),
                              ),
                              SizedBox(height: 32.h),
                              YesNoSpeakingTiltArena(
                                tiltValue: _tiltValue.value,
                                isSnapped: _isSnapped.value,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onTiltDragged: _onTiltDragged,
                                onTiltDragEnd: () {
                                  if (!_isSnapped.value) {
                                    _tiltValue.value = 0.0;
                                  }
                                },
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
                              if (_isSnapped.value && !_isAnswered.value)
                                TypeToConfirmOverlay(
                                  expectedText: quest.sampleAnswer ?? "",
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        doTheyMatch,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        doTheyMatch,
                                      ),
                                ),
                            ],
                          ),
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
