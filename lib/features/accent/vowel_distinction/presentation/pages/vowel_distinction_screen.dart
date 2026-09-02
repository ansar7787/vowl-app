import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_instruction.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_prompt_card.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_pulse_speaker.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_spectral_slider.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_trapezoid_chart.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class VowelDistinctionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VowelDistinctionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.vowelDistinction,
  });

  @override
  State<VowelDistinctionScreen> createState() => _VowelDistinctionScreenState();
}

class _VowelDistinctionScreenState extends State<VowelDistinctionScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  Timer? _mismatchResetTimer;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _mismatchResetTimer?.cancel();
    _autoplayTimer?.cancel();
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _sliderValue.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _sliderValue.value = value;

    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _sliderValue.value = index == 0 ? 0.0 : 1.0;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      // Do NOT submit yet. Wait for Phase 2.
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _sliderValue.value = 0.5;
            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              _autoplayTimer?.cancel();
              _autoplayTimer = Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PHONEME PRO!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _sliderValue,
              _selectedIndex,
              _isFirstStagePassed,
            ]),
            builder: (context, _) {
              return AccentBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
                onContinue: () =>
                    context.read<AccentBloc>().add(NextQuestion()),
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? const SizedBox()
                    : Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxHeight = constraints.maxHeight;
                              final maxWidth = constraints.maxWidth;
                              final bool isCompact = maxHeight < 580;

                              final double estimatedContentHeight =
                                  24.h +
                                  (isCompact ? 90.h : 120.h) +
                                  100.h +
                                  (isCompact ? 130.h : 172.h);
                              final remainingHeight =
                                  maxHeight - estimatedContentHeight;

                              final double gapUnit = remainingHeight > 0
                                  ? remainingHeight / 8
                                  : 0;
                              final double gapTop = remainingHeight > 0
                                  ? (gapUnit * 1).clamp(8.0, 24.0)
                                  : 8.0;
                              final double gapInstruction = remainingHeight > 0
                                  ? (gapUnit * 1).clamp(8.0, 24.0)
                                  : 8.0;
                              final double gapPrompt = remainingHeight > 0
                                  ? (gapUnit * 1.5).clamp(12.0, 32.0)
                                  : 12.0;
                              final double gapSpeaker = remainingHeight > 0
                                  ? (gapUnit * 2).clamp(16.0, 48.0)
                                  : 16.0;

                              final double gapBottom = remainingHeight > 0
                                  ? (gapUnit * 1).clamp(12.0, 40.0)
                                  : 12.0;

                              return RawScrollbar(
                                controller: _scrollController,
                                thumbColor: theme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                                radius: Radius.circular(8.r),
                                thickness: 4.w,
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  physics: (!_isFirstStagePassed.value)
                                        ? const NeverScrollableScrollPhysics()
                                        : const BouncingScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                    child: IgnorePointer(
                                      ignoring: _isFirstStagePassed.value,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 32.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: SizedBox(
                                                                width:
                                                                    maxWidth -
                                                                    48.w,
                                                                child: VowelDistinctionInstruction(
                                                                  color: theme
                                                                      .primaryColor,
                                                                  instruction:
                                                                      _isFirstStagePassed
                                                                          .value
                                                                      ? "Great job! Now confirm by speaking the word."
                                                                      : context.tr(
                                                                          'games.vowel_distinction_instruction',
                                                                          fallback:
                                                                              'Match the vowel sound',
                                                                        ),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : VowelDistinctionInstruction(
                                                            color: theme
                                                                .primaryColor,
                                                            instruction:
                                                                _isFirstStagePassed
                                                                    .value
                                                                ? "Great job! Now confirm by speaking the word."
                                                                : context.tr(
                                                                    'games.vowel_distinction_instruction',
                                                                    fallback:
                                                                        'Match the vowel sound',
                                                                  ),
                                                          ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 90.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: SizedBox(
                                                                width:
                                                                    maxWidth -
                                                                    48.w,
                                                                child: VowelDistinctionPromptCard(
                                                                  word:
                                                                      quest
                                                                          .word ??
                                                                      "",
                                                                  color: theme
                                                                      .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : VowelDistinctionPromptCard(
                                                            word:
                                                                quest.word ??
                                                                "",
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                          ),
                                                    SizedBox(height: gapPrompt),
                                                    if (_isFirstStagePassed
                                                            .value &&
                                                        quest.vowelChart !=
                                                            null)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              bottom: 24.h,
                                                            ),
                                                        child:
                                                            VowelTrapezoidChart(
                                                              vowelChart: quest
                                                                  .vowelChart!,
                                                              color: theme
                                                                  .primaryColor,
                                                              isDark: isDark,
                                                            ),
                                                      )
                                                    else
                                                      VowelDistinctionPulseSpeaker(
                                                        text:
                                                            quest.textToSpeak ??
                                                            "",
                                                        color:
                                                            theme.primaryColor,
                                                        onPlayTts: _playTts,
                                                      ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: gapSpeaker,
                                                    ),
                                                    isCompact
                                                        ? SizedBox(
                                                            height: 110.h,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: SizedBox(
                                                                width:
                                                                    maxWidth -
                                                                    48.w,
                                                                child: VowelDistinctionSpectralSlider(
                                                                  options:
                                                                      options,
                                                                  correctIndex:
                                                                      quest
                                                                          .correctAnswerIndex ??
                                                                      0,
                                                                  color: theme
                                                                      .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  isAnswered:
                                                                      _isAnswered
                                                                          .value ||
                                                                      _isFirstStagePassed
                                                                          .value,
                                                                  selectedIndex:
                                                                      _selectedIndex
                                                                          .value,
                                                                  sliderValue:
                                                                      _sliderValue
                                                                          .value,
                                                                  onSubmitChoice:
                                                                      _submitChoice,
                                                                  onSliderUpdate:
                                                                      _onSliderUpdate,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : VowelDistinctionSpectralSlider(
                                                            options: options,
                                                            correctIndex:
                                                                quest
                                                                    .correctAnswerIndex ??
                                                                0,
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            isAnswered:
                                                                _isAnswered
                                                                    .value ||
                                                                _isFirstStagePassed
                                                                    .value,
                                                            selectedIndex:
                                                                _selectedIndex
                                                                    .value,
                                                            sliderValue:
                                                                _sliderValue
                                                                    .value,
                                                            onSubmitChoice:
                                                                _submitChoice,
                                                            onSliderUpdate:
                                                                _onSliderUpdate,
                                                          ),
                                                    SizedBox(height: gapBottom),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                (_isFirstStagePassed.value &&
                                                    !_isAnswered.value)
                                                ? 380.h
                                                : 160.h,
                                          ),
                                        ],

                                      ),

                                    ),

                                  ),

                                ),

                                if (_isFirstStagePassed.value && !_isAnswered.value)

                                  SliverToBoxAdapter(

                                    child: Column(

                                      children: [
if (_isFirstStagePassed.value && !_isAnswered.value)
                            SpeakToConfirmOverlay(
                              expectedText:
                                  quest.textToSpeak ?? quest.word ?? "",
                              primaryColor: theme.primaryColor,
                              isPositioned: false,
                              onConfirmed: () {
                                context.read<AccentBloc>().add(
                                  const AccentSpeakConfirmed(5),
                                );
                                _submitVerbalEvaluation(true);
                              },
                              onSkipped: () => _submitVerbalEvaluation(false),
                            ),
  

                                        SizedBox(height: 60.h),

                                      ],

                                    ),

                                  ),

                                ],

                              ),
                              );
                            },
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
