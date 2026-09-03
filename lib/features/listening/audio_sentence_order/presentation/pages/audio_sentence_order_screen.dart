import 'package:vowl/core/utils/instruction_helper.dart';
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

import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_instruction.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_oscilloscope.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_jigsaw_wrapper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class AudioSentenceOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioSentenceOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioSentenceOrder,
  });

  @override
  State<AudioSentenceOrderScreen> createState() =>
      _AudioSentenceOrderScreenState();
}

class _AudioSentenceOrderScreenState extends State<AudioSentenceOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(String correctFull) {
    if (_isAnswered.value) return;

    _hapticService.success();
    _soundService.playCorrect();
    _isAnswered.value = true;
    _isCorrect.value = true;
    context.read<ListeningBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SEQUENCE MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<ListeningBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<ListeningBloc>().add(ListeningHintUsed()),
              child: quest == null
                  ? const SizedBox()
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 6.h),
                                  AudioSentenceOrderInstruction(
                                    color: theme.primaryColor,
                                    instruction: InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 24.h),
                                  AudioSentenceOrderOscilloscope(
                                    onTap: () {
                                      _soundService.playTts(
                                        quest.textToSpeak ?? "",
                                      );
                                      _hapticService.selection();
                                    },
                                    color: theme.primaryColor,
                                    emoji: quest.emoji,
                                    isCorrectState: _isCorrect.value,
                                  ),
                                  SizedBox(height: 32.h),
                                  if (!_isAnswered.value)
                                    DynamicJigsawWrapper(
                                      expectedText: quest.textToSpeak ?? "",
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onConfirmed: () => _submitAnswer(
                                        quest.textToSpeak ?? "",
                                      ),
                                      onSkipped: () {
                                        final authState = context
                                            .read<AuthBloc>()
                                            .state;
                                        if (authState.status ==
                                                AuthStatus.authenticated &&
                                            authState.user != null) {
                                          ErrorJournalCollector.record(
                                            userId: authState.user!.id,
                                            gameType: widget.gameType.name,
                                            question: 'Sentence Order',
                                            userAnswer: '[Skipped]',
                                            correctAnswer:
                                                quest.textToSpeak ?? "",
                                            level: widget.level,
                                          );
                                        }
                                        _isAnswered.value = true;
                                        _isCorrect.value = false;
                                        context.read<ListeningBloc>().add(
                                          SubmitAnswer(false),
                                        );
                                      },
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
      },
    );
  }
}
