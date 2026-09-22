import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
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
    with SingleTickerProviderStateMixin, SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _heatLevel = ValueNotifier(0.0);

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;

  late AnimationController _tickerController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);

  final ValueNotifier<bool> _showGuide = ValueNotifier(false);
  final ValueNotifier<bool> _isUserRecording = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initSpeakingGame();

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
    _timeVal.dispose();
    _showGuide.dispose();
    _isUserRecording.dispose();
    _scrollController.dispose();
    _ttsFinished.dispose();
    _ttsTimer?.cancel();
    disposeSpeakingGame();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    _heatLevel.value = nailedIt ? 1.0 : 0.0;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        // Find quest from state to log details accurately
        final state = context.read<SpeakingBloc>().state;
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: quest?.textToSpeak ?? widget.gameType.name,
          userAnswer: '[Failed Pronunciation]',
          correctAnswer:
              quest?.targetPhoneme ?? 'Shadow Playback Compare Target',
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _heatLevel.value = 0.0;

    _ttsFinished.value = false;

    _timeVal.value = 0.0;

    _showGuide.value = false;

    _isUserRecording.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listenWhen: speakingListenWhen,
      listener: onSpeakingStateChanged,
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _heatLevel,
              _showGuide,
              _ttsFinished,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () =>
                    context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AbsorbPointer(
                                  absorbing: !_ttsFinished
                                      .value, // BUG FIX: block while playing, unlock after
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PronunciationFocusHeader(
                                        primaryColor: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      PronunciationFocusPhonemeCrucible(
                                        quest: quest,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        heatLevel: _heatLevel.value,
                                        showGuide: _showGuide.value,
                                        onToggleGuide: () {
                                          hapticService.selection();
                                          _showGuide.value = !_showGuide.value;
                                        },
                                      ),
                                      SizedBox(height: 32.h),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isUserRecording,
                                        builder: (context, isRecording, _) {
                                          return ValueListenableBuilder<double>(
                                            valueListenable: _timeVal,
                                            builder: (context, timeVal, _) {
                                              return PronunciationFocusThermalGrid(
                                                heatLevel: _heatLevel.value,
                                                isListening: isRecording,
                                                timeVal: timeVal,
                                                isDark: isDark,
                                              );
                                            },
                                          );
                                        },
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
                            ),
                            if (!isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: AnimatedOpacity(
                                  opacity: _ttsFinished.value ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 300),
                                  child: AbsorbPointer(
                                    absorbing: !_ttsFinished.value,
                                    child: ShadowPlaybackCompare(
                                      expectedText:
                                          quest.textToSpeak ??
                                          "", // BUG FIX: targetWord was null
                                      showExpectedText:
                                          false, // BUG FIX: do not repeat text
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onRecordingStateChanged: (isRecording) {
                                        _isUserRecording.value = isRecording;
                                      },
                                      onConfirmed: () =>
                                          _submitVerbalEvaluation(true),
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false),
                                    ),
                                  ),
                                ),
                              ),
                            SliverSafeArea(
                              sliver: SliverToBoxAdapter(
                                child: SizedBox(height: 120.h),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
