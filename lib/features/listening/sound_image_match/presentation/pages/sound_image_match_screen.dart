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
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_instruction.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_emitter.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_scanner_field.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class SoundImageMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SoundImageMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.soundImageMatch,
  });

  @override
  State<SoundImageMatchScreen> createState() => _SoundImageMatchScreenState();
}

class _SoundImageMatchScreenState extends State<SoundImageMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Offset> _lensPosition = ValueNotifier(
    const Offset(150, 150),
  );
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
    _lensPosition.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onScan(Offset position) {
    if (_isAnswered.value) return;
    _lensPosition.value = position;
    _hapticService.selection();
  }

  void _submitFinalAnswer(bool nailedSpeaking, int correct) {
    if (_isAnswered.value || _pendingSelectedIndex.value == null) return;
    _timerKey.currentState?.stop();

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Sound Image Match',
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
          question: 'Sound Image Match',
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
            _lensPosition.value = const Offset(150, 150);
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'THEMATIC LINKER!',
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
            _lensPosition,
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
                                      if (!_isAnswered.value)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 16.h,
                                          ),
                                          child: SpeedChallengeTimer(
                                            key: _timerKey,
                                            durationSeconds: 30,
                                            primaryColor: theme.primaryColor,
                                            onTimeUp: () {
                                              final authState = context
                                                  .read<AuthBloc>()
                                                  .state;
                                              if (authState.status ==
                                                      AuthStatus
                                                          .authenticated &&
                                                  authState.user != null) {
                                                ErrorJournalCollector.record(
                                                  userId: authState.user!.id,
                                                  gameType:
                                                      widget.gameType.name,
                                                  question: 'Sound Image Match',
                                                  userAnswer: '[Time Up]',
                                                  correctAnswer:
                                                      quest.correctAnswerIndex
                                                          ?.toString() ??
                                                      '',
                                                  level: widget.level,
                                                );
                                              }
                                              _isAnswered.value = true;
                                              _isCorrect.value = false;
                                              _pendingSelectedIndex.value = -1;
                                              _selectedIndex.value = -1;
                                              context.read<ListeningBloc>().add(
                                                SubmitAnswer(false),
                                              );
                                            },
                                          ),
                                        ),
                                      SoundImageMatchInstruction(
                                        color: theme.primaryColor,
                                        instruction: quest.instruction,
                                      ),
                                      SizedBox(height: 24.h),
                                      SoundImageMatchEmitter(
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
                                      SizedBox(
                                        height: 350.h,
                                        child: SoundImageMatchScannerField(
                                          options: quest.options ?? [],
                                          correctAnswerIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isAnswered: _isAnswered.value,
                                          isCorrectState: _isCorrect.value,
                                          selectedIndex: _selectedIndex.value,
                                          lensPosition: _lensPosition.value,
                                          onScan: _onScan,
                                          onSelect: (index) {
                                            if (_isAnswered.value ||
                                                _pendingSelectedIndex.value !=
                                                    null) {
                                              return;
                                            }
                                            _timerKey.currentState?.pause();
                                            _pendingSelectedIndex.value = index;
                                          },
                                        ),
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
                            onSkipped: () {
                              _timerKey.currentState?.resume();
                              _submitFinalAnswer(
                                false,
                                quest.correctAnswerIndex ?? 0,
                              );
                            },
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
