import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'dart:math' as math;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_instruction.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_jar.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_canvas.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/blind_dictation_wrapper.dart';
import 'package:vowl/core/utils/locale_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

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

class _AudioFillBlanksScreenState extends State<AudioFillBlanksScreen>
    with
        GameScreenMixin<AudioFillBlanksScreen>,
        ListeningGameScreenMixin<AudioFillBlanksScreen> {
  @override
  GameSubtype get gameType => widget.gameType;
  @override
  int get level => widget.level;
  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.audio_fill_blanks_title',
    fallback: 'AUDITORY ACE!',
  );

  final _controller = TextEditingController();
  final ValueNotifier<double> _revealProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  @override
  void dispose() {
    _controller.dispose();
    _revealProgress.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _revealProgress.value = 0.0;
    _controller.clear();
  }

  double _lastHapticProgress = 0.0;

  void _onSmear(double delta) {
    if (isAnsweredNotifier.value) return;

    final newProgress = (_revealProgress.value + delta).clamp(0.0, 1.0);
    _revealProgress.value = newProgress;

    // Play a haptic tick every 10% of reveal
    if (newProgress - _lastHapticProgress > 0.1) {
      hapticService.selection();
      _lastHapticProgress = newProgress;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Submit answer
  // ─────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // TTS playback
  // ─────────────────────────────────────────────────────────────────────────────

  void _playAudio(String? textToSpeak) {
    final text = textToSpeak?.trim();
    if (text == null || text.isEmpty) return;
    soundService.playTts(text);
    hapticService.selection();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded || current is ListeningGameOver,
      builder: (context, state) {
        final quest = state is ListeningLoaded ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: () => dispatchNextQuestion(),
              onHint: () => hapticService.selection(),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : _AudioFillBlanksContent(
                      quest: quest,
                      isAnswered: isAnsweredNotifier.value,
                      isCorrect: isCorrectNotifier.value,
                      revealProgressNotifier: _revealProgress,
                      controller: _controller,
                      scrollController: _scrollController,
                      timerKey: timerKey!,
                      theme: theme,
                      isDark: isDark,
                      compactThreshold: _kCompactHeightThreshold,
                      level: widget.level,
                      onSmear: _onSmear,
                      onPlayAudio: () => _playAudio(quest.textToSpeak),
                      onBlindSubmit: (bool correct) {
                        if (correct) {
                          submitCorrectAnswer();
                        } else {
                          submitWrongAnswer(
                            quest: quest,
                            userAnswer: _controller.text.isNotEmpty
                                ? _controller.text
                                : context.tr(
                                    'listening.games.failed_dictation',
                                    fallback: '[Failed Dictation]',
                                  ),
                          );
                        }
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
  final ListeningQuest quest;
  final bool isAnswered;
  final bool? isCorrect;
  final ValueNotifier<double> revealProgressNotifier;
  final TextEditingController controller;
  final ScrollController scrollController;
  final GlobalKey<SpeedChallengeTimerState> timerKey;
  final ThemeResult theme;
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
                                ? quest.textToSpeak!
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
                      onReplayAudio: onPlayAudio,
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
