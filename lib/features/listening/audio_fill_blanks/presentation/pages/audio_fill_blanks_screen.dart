import 'dart:math' as math;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_instruction.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_jar.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_canvas.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/game_mechanics/blind_dictation_wrapper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Constants
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Height threshold below which the compact layout variant is used.
const double _kCompactHeightThreshold = 580.0;

// =============================================================================
// AudioFillBlanksScreen
// =============================================================================

class AudioFillBlanksScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const AudioFillBlanksScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioFillBlanks,
  });

  @override
  State<AudioFillBlanksScreen> createState() => _AudioFillBlanksScreenState();
}

class _AudioFillBlanksScreenState extends State<AudioFillBlanksScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();

  // â”€â”€ Local UI state (synced from BLoC listener) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final ValueNotifier<double> _revealProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  @override
  void dispose() {
    _controller.dispose();
    _revealProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // â”€â”€ Change-tracking helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int _lastProcessedIndex = -1;
  int? _lastLives;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  // â”€â”€ Gesture handler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  double _lastHapticProgress = 0.0;

  void _onSmear(double delta) {
    if (_isAnswered.value) return;

    final newProgress = (_revealProgress.value + delta).clamp(0.0, 1.0);
    _revealProgress.value = newProgress;

    // Play a haptic tick every 10% of reveal
    if (newProgress - _lastHapticProgress > 0.1) {
      _hapticService.selection();
      _lastHapticProgress = newProgress;
    }
  }

  // â”€â”€ Submit answer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€ TTS playback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _playAudio(String? textToSpeak) {
    final text = textToSpeak?.trim();
    if (text == null || text.isEmpty) return;
    _soundService.playTts(text);
    _hapticService.selection();
  }

  // â”€â”€ Reset local state for the next question â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _resetForNextQuestion(int newIndex) {
    _lastProcessedIndex = newIndex;
    _isAnswered.value = false;
    _isCorrect.value = null;
    _revealProgress.value = 0.0;
    _lastHapticProgress = 0.0;
    _controller.clear();
    _timerKey.currentState?.start();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          // Detect a life-restore (lives increased, e.g. 0 -> 1).
          final isLifeRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || isLifeRestored) {
            _resetForNextQuestion(state.currentIndex);
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            // Bloc already knows the result; sync local state.
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
            title: 'AUDITORY ACE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = state is ListeningLoaded ? state.currentQuest : null;

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
              disablePadding: true,
              onContinue: () =>
                  context.read<ListeningBloc>().add(const NextQuestion()),
              onHint: () => _hapticService.selection(),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : _AudioFillBlanksContent(
                      quest: quest,
                      isAnswered: _isAnswered.value,
                      isCorrect: _isCorrect.value,
                      revealProgressNotifier: _revealProgress,
                      controller: _controller,
                      scrollController: _scrollController,
                      timerKey: _timerKey,
                      theme: theme,
                      isDark: isDark,
                      compactThreshold: _kCompactHeightThreshold,
                      level: widget.level,
                      onSmear: _onSmear,
                      onPlayAudio: () => _playAudio(quest.textToSpeak),
                      onBlindSubmit: (bool correct) {
                        _timerKey.currentState?.stop();
                        if (!correct) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState.status == AuthStatus.authenticated &&
                              authState.user != null) {
                            ErrorJournalCollector.record(
                              userId: authState.user!.id,
                              gameType: widget.gameType.name,
                              question:
                                  quest.textWithBlanks ??
                                  quest.textToSpeak ??
                                  'Audio Fill Blanks',
                              userAnswer: _controller.text.isNotEmpty
                                  ? _controller.text
                                  : '[Failed Dictation]',
                              correctAnswer:
                                  quest.correctAnswer ??
                                  quest.textToSpeak ??
                                  '',
                              level: widget.level,
                            );
                          }
                        }
                        _isAnswered.value = true;
                        _isCorrect.value = correct;
                        context.read<ListeningBloc>().add(
                          SubmitAnswer(correct),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// _AudioFillBlanksContent
//
// Extracted layout widget - handles the adaptive gap / compact-mode logic
// and composes all sub-widgets. Keeping it private (underscore) as it is
// tightly coupled to this feature's UX.
// =============================================================================

class _AudioFillBlanksContent extends StatelessWidget {
  final dynamic quest;
  final bool isAnswered;
  final bool? isCorrect;
  final ValueNotifier<double> revealProgressNotifier;
  final TextEditingController controller;
  final ScrollController scrollController;
  final GlobalKey<SpeedChallengeTimerState> timerKey;
  final dynamic theme;
  final bool isDark;
  final double compactThreshold;
  final int level;
  final void Function(double) onSmear;
  final VoidCallback onPlayAudio;
  final void Function(bool) onBlindSubmit;

  const _AudioFillBlanksContent({
    required this.quest,
    required this.isAnswered,
    required this.isCorrect,
    required this.revealProgressNotifier,
    required this.controller,
    required this.scrollController,
    required this.timerKey,
    required this.theme,
    required this.isDark,
    required this.compactThreshold,
    required this.level,
    required this.onSmear,
    required this.onPlayAudio,
    required this.onBlindSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final showBlindDictation = level >= 8 && !isAnswered;

    return Stack(
      children: [
        RawScrollbar(
          controller: scrollController,
          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
          radius: Radius.circular(8.r),
          thickness: 4.w,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6.h),
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: SpeedChallengeTimer(
                          key: timerKey,
                          durationSeconds: 15,
                          primaryColor: theme.primaryColor,
                          onTimeUp: () {
                            if (isAnswered) return;
                            onBlindSubmit(
                              false,
                            ); // Default to wrong on time out
                          },
                        ),
                      ),
                      AudioFillBlanksInstruction(
                        instruction: InstructionHelper.getInstruction(quest),
                        color: theme.primaryColor,
                      ),
                      SizedBox(height: 24.h),
                      AudioFillBlanksJar(
                        color: theme.primaryColor,
                        onTap: onPlayAudio,
                      ),
                      SizedBox(height: 32.h),
                      ValueListenableBuilder<double>(
                        valueListenable: revealProgressNotifier,
                        builder: (context, progress, _) {
                          return AudioFillBlanksCanvas(
                            text:
                                (isCorrect == true && quest.textToSpeak != null)
                                ? quest.textToSpeak
                                : (quest.textWithBlanks ?? ''),
                            revealProgress: (isAnswered && isCorrect == true)
                                ? 1.0
                                : progress,
                            onSmear: onSmear,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            imageUrl: null,
                            isCorrectState: isCorrect,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24.w,
                    right: 24.w,
                    top: 16.h,
                    bottom:
                        (isAnswered ? 200.h : 40.h) +
                        MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: showBlindDictation
                              ? SizedBox(
                                  key: const ValueKey('spacer'),
                                  height: 380.h,
                                )
                              : _buildOptions(context, quest, theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: showBlindDictation
                ? Align(
                    key: const ValueKey('dictation'),
                    alignment: Alignment.bottomCenter,
                    child: BlindDictationWrapper(
                      expectedText:
                          quest.correctAnswer ?? quest.textToSpeak ?? '',
                      primaryColor: theme.primaryColor,
                      isPositioned: false,
                      onConfirmed: () => onBlindSubmit(true),
                      onSkipped: () => onBlindSubmit(false),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context, dynamic quest, dynamic theme) {
    if (quest == null || isAnswered) {
      return const SizedBox.shrink(key: ValueKey('options_empty'));
    }

    final correctWord = (quest.correctAnswer ?? '').toString().toLowerCase();
    final distractor1 =
        (quest.distractorWords != null && quest.distractorWords.length > 0)
        ? quest.distractorWords[0].toString().toLowerCase()
        : 'distractor1';
    final distractor2 =
        (quest.distractorWords != null && quest.distractorWords.length > 1)
        ? quest.distractorWords[1].toString().toLowerCase()
        : 'distractor2';

    // Build the list and shuffle using quest id as a deterministic seed
    final seed = quest.id != null ? quest.id.hashCode : 0;
    final List<String> options = [correctWord, distractor1, distractor2]
      ..shuffle(math.Random(seed));

    return Column(
      key: const ValueKey('options_list'),
      children: options.map((option) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Semantics(
            button: true,
            child: ScaleButton(
              onTap: () {
                final isCorrect = option == correctWord;
                if (isCorrect) {
                  onBlindSubmit(true);
                } else {
                  controller.text = option; // For ErrorJournalCollector
                  onBlindSubmit(false);
                }
              },
              child: Container(
                width: double.infinity,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: isDark
                      ? theme.primaryColor.withValues(alpha: 0.2)
                      : Colors.white,
                  border: Border.all(color: theme.primaryColor, width: 2.w),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      option.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
