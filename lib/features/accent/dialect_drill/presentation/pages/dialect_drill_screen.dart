import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_feedback_panel.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_instruction.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_hologram_console.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_region_map.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';

class DialectDrillScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialectDrillScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialectDrill,
  });

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  AccentQuest? _lastQuest;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  List<String>? _shuffledOptions;
  int? _shuffledCorrectIndex;

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }


  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _shuffleOptions(AccentQuest? quest) {
    if (quest == null || quest.options == null) return;
    List<MapEntry<int, String>> indexedOptions = quest.options!
        .asMap()
        .entries
        .toList();
    indexedOptions.shuffle();
    _shuffledOptions = indexedOptions.map((e) => e.value).toList();
    _shuffledCorrectIndex = indexedOptions.indexWhere(
      (e) => e.key == (quest.correctAnswerIndex ?? 0),
    );
  }

  void _triggerAutoPlay(AccentQuest quest) {
    final instruction = quest.instruction.toLowerCase();
    final String targetLocale = instruction.contains('british')
        ? "en-GB"
        : "en-US";
    _soundService.playTts(quest.word ?? "", locale: targetLocale);
  }

  void _submitAnswer(int index, int correct, double maxWidth) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
              _lastLives != null && (state.livesRemaining > _lastLives!);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _shuffleOptions(state.currentQuest as AccentQuest?);
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
          _lastLives = state.livesRemaining;
          _lastQuest = state.currentQuest;
        }
        if (state is AccentGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALECT EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? originalQuest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;

        if (originalQuest != null &&
            _shuffledOptions == null &&
            !_isAnswered.value) {
          _shuffleOptions(originalQuest);
        }

        final AccentQuest? quest = originalQuest?.copyWith(
          options: _shuffledOptions,
          correctAnswerIndex: _shuffledCorrectIndex,
        );

        final bool isHintUnlocked = (state is AccentLoaded) && state.hintUsed;

        String instructionText = quest?.instruction ?? "";
        if (instructionText.toLowerCase().contains('british')) {
          instructionText = context.tr(
            'games.dialect_drill_instruction_uk',
            fallback: 'Identify the British pronunciation.',
          );
        } else if (instructionText.toLowerCase().contains('american')) {
          instructionText = context.tr(
            'games.dialect_drill_instruction_us',
            fallback: 'Identify the American pronunciation.',
          );
        }

        String brPr = "";
        String amPr = "";
        if (quest != null && quest.options != null) {
          for (var opt in quest.options!) {
            if (opt.contains('(British)')) {
              brPr = opt.replaceAll(' (British)', '');
            } else if (opt.contains('(American)')) {
              amPr = opt.replaceAll(' (American)', '');
            }
          }
        }
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
                                              horizontal: 16.w,
                                              vertical: 24.h,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DialectDrillInstruction(
                                                      instruction:
                                                          _isFirstStagePassed
                                                              .value
                                                          ? "Great job! Now record yourself saying the word."
                                                          : instructionText,
                                                      accentColor:
                                                          theme.primaryColor,
                                                    ),
                                                    if (quest.dialectRegion !=
                                                        null) ...[
                                                      SizedBox(height: 16.h),
                                                      DialectDrillRegionMap(
                                                        region: quest
                                                            .dialectRegion!,
                                                        color:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                      ),
                                                    ],
                                                    SizedBox(height: 24.h),
                                                    DialectDrillHologramConsole(
                                                      quest: quest,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered.value ||
                                                          _isFirstStagePassed
                                                              .value,
                                                      isCorrect:
                                                          _isFirstStagePassed
                                                              .value
                                                          ? true
                                                          : _isCorrect.value,
                                                      onPlayTargetAudio: () =>
                                                          _triggerAutoPlay(
                                                            quest,
                                                          ),
                                                      onSubmitAnswer:
                                                          _submitAnswer,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.easeOut,
                                            child:
                                                (_isAnswered.value ||
                                                    _isFirstStagePassed.value)
                                                ? Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 16.w,
                                                        ).copyWith(
                                                          bottom: 24.h,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Builder(
                                                          builder: (context) {
                                                            final bool
                                                            isSuccess =
                                                                _isCorrect
                                                                        .value ==
                                                                    true ||
                                                                _isFirstStagePassed
                                                                    .value;
                                                            final bool
                                                            isFinalFailure =
                                                                state
                                                                    is AccentGameOver;
                                                            final bool
                                                            showExplanation =
                                                                isSuccess ||
                                                                isFinalFailure;
                                                            return DialectFeedbackPanel(
                                                              isCorrect:
                                                                  _isCorrect
                                                                      .value ??
                                                                  _isFirstStagePassed
                                                                      .value,
                                                              word:
                                                                  quest.word ??
                                                                  "",
                                                              britishPronunciation:
                                                                  brPr.isEmpty
                                                                  ? (quest.word ??
                                                                        "")
                                                                  : brPr,
                                                              americanPronunciation:
                                                                  amPr.isEmpty
                                                                  ? (quest.word ??
                                                                        "")
                                                                  : amPr,
                                                              hint:
                                                                  isHintUnlocked
                                                                  ? quest.hint
                                                                  : null,
                                                              explanation:
                                                                  showExplanation
                                                                  ? quest
                                                                        .explanation
                                                                  : null,
                                                              dialectNote:
                                                                  showExplanation
                                                                  ? quest
                                                                        .dialectNote
                                                                  : null,
                                                              isDark: isDark,
                                                              isMidnight: false,
                                                              onPlayAudio:
                                                                  (
                                                                    text,
                                                                    locale,
                                                                  ) {
                                                                    _soundService
                                                                        .playTts(
                                                                          text,
                                                                          locale:
                                                                              locale,
                                                                        );
                                                                  },
                                                            );
                                                          },
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              (_isFirstStagePassed
                                                                      .value &&
                                                                  !_isAnswered
                                                                      .value)
                                                              ? 380.h
                                                              : 160.h,
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : SizedBox(
                                                    width: double.infinity,
                                                    height:
                                                        (_isFirstStagePassed
                                                                .value &&
                                                            !_isAnswered.value)
                                                        ? 380.h
                                                        : 160.h,
                                                  ),
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
                            ShadowPlaybackCompare(
                              expectedText: quest.word ?? "",
                              primaryColor: theme.primaryColor,
                              isPositioned: false,
                              onConfirmed: () {
                                _submitVerbalEvaluation(true);
                              },
                              onSkipped: () {
                                _submitVerbalEvaluation(false);
                              },
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
