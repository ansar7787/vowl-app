import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/speaking_self_evaluation_controls.dart';

import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_header.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_sentence_panel.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_garden_panel.dart';

class SpeakSynonymScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakSynonymScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakSynonym,
  });

  @override
  State<SpeakSynonymScreen> createState() => _SpeakSynonymScreenState();
}

class _SpeakSynonymScreenState extends State<SpeakSynonymScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _bloomProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _swingController;
  double _timeVal = 0.0;

  List<String> _acceptedSyns = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _swingController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addListener(() {
            setState(() {
              _timeVal = _swingController.value;
            });
          });
    _swingController.repeat();
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
      _bloomProgress = nailedIt ? 1.0 : 0.0;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _bloomProgress = 1.0;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  void _extractTargetWord(String text, List<String> synonyms) {
    _acceptedSyns = synonyms;
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
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _bloomProgress = 0.0;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LEXICAL PIVOT COMPLETE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _extractTargetWord(
            quest.textToSpeak ?? "",
            quest.acceptedSynonyms ?? [],
          );
        }

        final expectedText = _acceptedSyns.isNotEmpty
            ? _acceptedSyns.first
            : "";

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          (isCompact ? 80.h : 110.h) +
                          (isCompact ? 100.h : 140.h) +
                          (isCompact ? 100.h : 160.h);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 5
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(6.0, 16.0)
                          : 6.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 12.0)
                          : 8.0;
                      final double gapSentence = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapGarden = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact
                                        ? SizedBox(
                                            height: 60.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SpeakSynonymHeader(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                          )
                                        : SpeakSynonymHeader(
                                            primaryColor: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),

                                    isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child: SpeakSynonymSentencePanel(
                                                  quest: quest,
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  isDark: isDark,
                                                  onPlayTts: () =>
                                                      _soundService.playTts(
                                                        (quest.textToSpeak ??
                                                                "")
                                                            .replaceAll(
                                                              '*',
                                                              '',
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : SpeakSynonymSentencePanel(
                                            quest: quest,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onPlayTts: () =>
                                                _soundService.playTts(
                                                  (quest.textToSpeak ?? "")
                                                      .replaceAll('*', ''),
                                                ),
                                          ),
                                    SizedBox(height: gapSentence),

                                    isCompact
                                        ? SizedBox(
                                            height: 80.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child: SpeakSynonymGardenPanel(
                                                  bloomProgress: _bloomProgress,
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  isListening: false,
                                                  timeVal: _timeVal,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SpeakSynonymGardenPanel(
                                            bloomProgress: _bloomProgress,
                                            primaryColor: theme.primaryColor,
                                            isListening: false,
                                            timeVal: _timeVal,
                                            isDark: isDark,
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapGarden),

                                    if (!_isAnswered)
                                      SpeakingSelfEvaluationControls(
                                        expectedText: expectedText,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onConfirmed: () =>
                                            _submitVerbalEvaluation(true),
                                        onSkipped: () =>
                                            _submitVerbalEvaluation(false),
                                      ),

                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

