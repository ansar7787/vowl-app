import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_instruction.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_emitter.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_neural_field.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class EmotionRecognitionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmotionRecognitionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emotionRecognition,
  });

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Offset> _coreOffset = ValueNotifier(Offset.zero);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;
  int? _pendingSelectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _coreOffset.dispose();
    super.dispose();
  }

  void _onCoreMove(Offset delta, BoxConstraints constraints) {
    if (_isAnswered) return;
    double nextX = (_coreOffset.value.dx + delta.dx).clamp(
      -constraints.maxWidth / 2 + 40.r,
      constraints.maxWidth / 2 - 40.r,
    );
    double nextY = (_coreOffset.value.dy + delta.dy).clamp(
      -constraints.maxHeight / 2 + 40.r,
      constraints.maxHeight / 2 - 40.r,
    );
    _coreOffset.value = Offset(nextX, nextY);
  }

  void _submitFinalAnswer(bool nailedSpeaking, int correct) {
    if (_isAnswered || _pendingSelectedIndex == null) return;
    
    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Emotion Recognition',
          userAnswer: '[Failed Speaking]',
          correctAnswer: correct.toString(),
          level: widget.level,
        );
      }
      
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
      return;
    }

    bool isCorrect = _pendingSelectedIndex == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(const ListeningSpeakConfirmed(5));
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Emotion Recognition',
          userAnswer: _pendingSelectedIndex.toString(),
          correctAnswer: correct.toString(),
          level: widget.level,
        );
      }
      
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _pendingSelectedIndex = null;
              _coreOffset.value = Offset.zero;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SENTIMENT PROBER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    CustomScrollView(
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
                              SizedBox(height: 6.h),
                              EmotionRecognitionInstruction(
                                isAnswered: _isAnswered,
                                color: theme.primaryColor,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              EmotionRecognitionEmitter(
                                onTap: () {
                                  _soundService.playTts(
                                    quest.textToSpeak ?? "",
                                  );
                                  _hapticService.selection();
                                },
                                color: theme.primaryColor,
                                emoji: quest.emoji,
                                isCorrectState: _isCorrect,
                              ),
                              SizedBox(height: 32.h),
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
                              SizedBox(
                                height: 350.h,
                                child: EmotionRecognitionNeuralField(
                                  options: quest.options ?? [],
                                  correctAnswerIndex:
                                      quest.correctAnswerIndex ?? 0,
                                  color: theme.primaryColor,
                                  isAnswered: _isAnswered,
                                  isCorrectState: _isCorrect,
                                  selectedIndex: _selectedIndex,
                                  coreOffset: _coreOffset,
                                  onCoreMove: _onCoreMove,
                                  onSubmitAnswer: (index) {
                                    if (_isAnswered || _pendingSelectedIndex != null) return;
                                    setState(() {
                                      _pendingSelectedIndex = index;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pendingSelectedIndex != null && !_isAnswered)
                    SpeakToConfirmOverlay(
                      expectedText: quest.options![_pendingSelectedIndex!],
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(
                        true,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      onSkipped: () => _submitFinalAnswer(
                        false,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      allowSkip: true,
                    ),
                ],
              ),
        );
      },
    );
  }
}
