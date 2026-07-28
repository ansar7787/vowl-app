import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';

import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_header.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_sentence_panel.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_garden_panel.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_telemetry_card.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_watering_mic_trigger.dart';

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
  final _speechService = di.sl<SpeechService>();

  double _bloomProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  int _attempts = 0;

  // Animation controller for leaf swaying and core particle pulsation
  late AnimationController _swingController;
  Timer? _bloomTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  
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
    _bloomTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _bloomProgress = 0.08;
      _spokenText = "Gathering floral audio signals...";
    });

    _speechService.listen(
      onResult: (candidates) {
          if (candidates.isEmpty) return;
          
          final text = candidates.first;
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );

    _bloomTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_bloomProgress < 0.90) {
          _bloomProgress += 0.012 + (math.Random().nextDouble() * 0.008);
        } else {
          _bloomProgress = 0.90 + (math.Random().nextDouble() * 0.04);
        }
      });
    });
  }

  void _stopSpeechListening() async {
    _bloomTimer?.cancel();
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    await _verifySynonymSpoken();
  }

  Future<void> _verifySynonymSpoken() async {
    if (_spokenText.isEmpty || _spokenText.startsWith("Gathering")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
        _bloomProgress = 0.0;
      });
      _hapticService.error();
      return;
    }
    // Language ID interception
    final languageIdService = di.sl<LanguageIdService>();
    final detectedLang = await languageIdService.identifyLanguage(_spokenText);

    if (detectedLang != 'en' && detectedLang != 'und') {
      _hapticService.error();
      if (!mounted) return;
      GameDialogHelper.showPremiumSnackBar(
        context,
        "Oops! It sounds like you spoke in a different language (\$detectedLang). Try saying it in English!",
        icon: Icons.language_rounded,
        color: Colors.orange,
      );
      setState(() {
        _isAnswered = false;
        _spokenText = "";
      });
      return;
    }


    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final List<String> speechWords = cleanSpeech.split(' ');

    bool matchFound = false;

    for (var word in speechWords) {
      final String cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
      for (var syn in _acceptedSyns) {
        final String cleanSyn = syn.trim().toLowerCase();
        if (cleanWord == cleanSyn ||
            cleanWord.contains(cleanSyn) ||
            cleanSyn.contains(cleanWord) ||
            TextSimilarityHelper.isMatch(
              cleanWord,
              cleanSyn,
              threshold: 0.70,
            )) {
          matchFound = true;
          break;
        }
      }
      if (matchFound) break;
    }

    setState(() {
      _attempts++;
      _isAnswered = true;
      _isCorrect = matchFound;
      _bloomProgress = matchFound ? 1.0 : 0.0;
    });

    if (!mounted) return;

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
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
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _isListening = false;
              _bloomProgress = 0.0;
              _spokenText = "";
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.lastAnswerCorrect == false) {
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
            onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
            onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
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
                          (isCompact ? 60.h : 80.h);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
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
                      final double gapTelemetry = remainingHeight > 0
                          ? (gapUnit * 2).clamp(12.0, 30.0)
                          : 12.0;
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
                                                  isListening: _isListening,
                                                  timeVal: _timeVal,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SpeakSynonymGardenPanel(
                                            bloomProgress: _bloomProgress,
                                            primaryColor: theme.primaryColor,
                                            isListening: _isListening,
                                            timeVal: _timeVal,
                                            isDark: isDark,
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapGarden),
                                    if (_spokenText.isNotEmpty)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width:
                                                      constraints.maxWidth -
                                                      16.w,
                                                  child:
                                                      SpeakSynonymTelemetryCard(
                                                        spokenText: _spokenText,
                                                        isDark: isDark,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : SpeakSynonymTelemetryCard(
                                              spokenText: _spokenText,
                                              isDark: isDark,
                                            ),

                                    SizedBox(height: gapTelemetry),

                                    if (!_isAnswered)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child:
                                                    SpeakSynonymWateringMicTrigger(
                                                      isListening: _isListening,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      timeVal: _timeVal,
                                                      onLongPressStart:
                                                          _startSpeechListening,
                                                      onLongPressEnd:
                                                          _stopSpeechListening,
                                                      attempts: _attempts,
                                                      isAnswered: _isAnswered,
                                                      
                                                    ),
                                              ),
                                            )
                                          : SpeakSynonymWateringMicTrigger(
                                              isListening: _isListening,
                                              primaryColor: theme.primaryColor,
                                              timeVal: _timeVal,
                                              onLongPressStart:
                                                  _startSpeechListening,
                                              onLongPressEnd:
                                                  _stopSpeechListening,
                                              attempts: _attempts,
                                              isAnswered: _isAnswered,
                                              
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

