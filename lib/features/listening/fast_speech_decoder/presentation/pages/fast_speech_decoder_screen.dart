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
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_instruction.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_gauges.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_core.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_steam_vents.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class FastSpeechDecoderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FastSpeechDecoderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fastSpeechDecoder,
  });

  @override
  State<FastSpeechDecoderScreen> createState() =>
      _FastSpeechDecoderScreenState();
}

class _FastSpeechDecoderScreenState extends State<FastSpeechDecoderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _dialRotation = ValueNotifier(
    0.33,
  ); // 0.0 to 1.0 mapping to 0.5x - 2.0x
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _dialRotation.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onRotate(double delta) {
    if (_isAnswered.value) return;
    double oldVal = _dialRotation.value;
    _dialRotation.value = (_dialRotation.value + delta / 300).clamp(0.0, 1.0);

    // Haptic tick for every 0.1x change
    if ((oldVal * 10).floor() != (_dialRotation.value * 10).floor()) {
      _hapticService.light();
    }
  }

  void _submitFinalAnswer(bool nailedSpeaking, int correct) {
    if (_isAnswered.value || _pendingSelectedIndex.value == null) return;

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Fast Speech Decoder',
          userAnswer: '[Failed Speaking]',
          correctAnswer: correct.toString(),
          level: widget.level,
        );
      }

      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedIndex.value = _pendingSelectedIndex.value;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
      return;
    }

    bool isCorrect = _pendingSelectedIndex.value == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      _selectedIndex.value = _pendingSelectedIndex.value;
      context.read<ListeningBloc>().add(const ListeningSpeakConfirmed(5));
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Fast Speech Decoder',
          userAnswer: _pendingSelectedIndex.value.toString(),
          correctAnswer: correct.toString(),
          level: widget.level,
        );
      }

      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedIndex.value = _pendingSelectedIndex.value;
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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _pendingSelectedIndex.value = null;
            _dialRotation.value = 0.33;
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
            title: 'NUANCE DECODER!',
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
            _selectedIndex,
            _pendingSelectedIndex,
            _dialRotation,
          ]),
          builder: (context, _) {
            double rotation = _dialRotation.value;
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
                                      SizedBox(height: 6.h),
                                      FastSpeechDecoderInstruction(
                                        color: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      (() {
                                        double speed = 0.3 + (rotation * 0.6);
                                        return Column(
                                          children: [
                                            FastSpeechDecoderGauges(
                                              speed: speed * 2,
                                              color: theme.primaryColor,
                                            ),
                                            SizedBox(height: 20.h),
                                            FastSpeechDecoderCore(
                                              textToSpeak:
                                                  quest.textToSpeak ?? "",
                                              speed: speed,
                                              color: theme.primaryColor,
                                              rotation: rotation,
                                              onRotate: _onRotate,
                                              onTapTts: () {
                                                _soundService.playTts(
                                                  quest.textToSpeak ?? "",
                                                  speed: speed,
                                                );
                                                _hapticService.selection();
                                              },
                                              emoji: quest.emoji,
                                              isCorrectState: _isCorrect.value,
                                            ),
                                          ],
                                        );
                                      })(),
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
                                      FastSpeechDecoderSteamVents(
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isAnswered: _isAnswered.value,
                                        isCorrectState: _isCorrect.value,
                                        selectedIndex: _selectedIndex.value,
                                        onSubmitAnswer: (index) {
                                          if (_isAnswered.value ||
                                              _pendingSelectedIndex.value !=
                                                  null) {
                                            return;
                                          }
                                          _pendingSelectedIndex.value = index;
                                        },
                                      ),
                                      SizedBox(
                                        height:
                                            (_pendingSelectedIndex.value !=
                                                    null &&
                                                !_isAnswered.value)
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
                        if (_pendingSelectedIndex.value != null &&
                            !_isAnswered.value)
                          SpeakToConfirmOverlay(
                            expectedText:
                                quest.options![_pendingSelectedIndex.value!],
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
