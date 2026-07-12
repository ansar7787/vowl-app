import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_header.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_scenic_radar_map.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_active_prompt_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_explorer_guide_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_telemetry_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_explanation_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_mic_trigger.dart';

class SceneDescriptionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SceneDescriptionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sceneDescriptionSpeaking,
  });

  @override
  State<SceneDescriptionScreen> createState() => _SceneDescriptionScreenState();
}

class _SceneDescriptionScreenState extends State<SceneDescriptionScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  final Set<int> _inspectedHotspots = {};
  int _activeHotspot = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  int _attempts = 0;

  late AnimationController _radarController;
  String _spokenText = "";
  List<String> _hotspotLabels = [];
  List<String> _hotspotPrompts = [];
  List<List<String>> _hotspotKeywords = [];
  String _sceneTitle = "Scene Visualizer";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.sceneText != null) {
      final parts = quest.sceneText!.split('|');
      _soundService.playTts(parts[0]);
    }
  }

  void _onHotspotTap(int index) {
    if (_isAnswered || _inspectedHotspots.contains(index)) return;
    _hapticService.selection();
    _soundService.playTts(_hotspotLabels[index]);
    setState(() {
      _activeHotspot = index;
      _spokenText = "";
    });
  }

  void _startSpeechListening() async {
    if (_isAnswered || _activeHotspot == -1) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Calibrating vocal description synthesizer...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyDescriptionSpoken();
  }

  void _verifyDescriptionSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No acoustic details detected.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final List<String> keywords = _hotspotKeywords[_activeHotspot];

    bool matchFound = false;

    for (var key in keywords) {
      if (cleanSpeech.contains(key.trim().toLowerCase())) {
        matchFound = true;
        break;
      }
    }

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _inspectedHotspots.add(_activeHotspot);
        _spokenText =
            "DECODED SUCCESSFULLY! '${_hotspotLabels[_activeHotspot]}' visual verified.";
        _activeHotspot = -1;
      });

      if (_inspectedHotspots.length >= 3) {
        setState(() {
          _isAnswered = true;
          _isCorrect = true;
        });
        context.read<SpeakingBloc>().add(SubmitAnswer(true));
      }
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _attempts++;
        _spokenText =
            "Detail mismatch. Focus your description and use key terms: ${keywords.join(', ')}.";
      });
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _inspectedHotspots.addAll([0, 1, 2]);
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  void _parseQuestData(SpeakingQuest quest) {
    _hotspotLabels = quest.options ?? ["Object A", "Object B", "Object C"];

    final String text =
        quest.sceneText ??
        "Visual Space Cabin|Describe features.|Describe features.|Describe features.";
    final List<String> parts = text.split('|');
    _sceneTitle = parts[0];

    _hotspotPrompts = [];
    for (int i = 1; i <= 3; i++) {
      _hotspotPrompts.add(
        parts.length > i ? parts[i] : "Describe this scenic component.",
      );
    }

    _hotspotKeywords = [];
    final List<String> list =
        quest.acceptedSynonyms ?? ["feature", "object", "item"];
    for (int i = 0; i < 3; i++) {
      final String keywordsString = list.length > i ? list[i] : "feature,item";
      _hotspotKeywords.add(keywordsString.split(','));
    }
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
              _inspectedHotspots.clear();
              _activeHotspot = -1;
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
            title: 'VISUAL MASTERPIECE!',
            enableDoubleUp: true,
          );
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<SpeakingBloc>().add(const RestoreLife()),
            onTutorPass: _tutorPass,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _parseQuestData(quest);
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
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
                          ? (gapUnit * 1).clamp(8.0, 16.0)
                          : 8.0;
                      final double gapMap = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapPrompt = remainingHeight > 0
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
                                            height: 32.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SceneDescriptionHeader(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                          )
                                        : SceneDescriptionHeader(
                                            primaryColor: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),

                                    isCompact
                                        ? SizedBox(
                                            height: 120.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child:
                                                    SceneDescriptionScenicRadarMap(
                                                      sceneTitle: _sceneTitle,
                                                      inspectedHotspots:
                                                          _inspectedHotspots,
                                                      activeHotspot:
                                                          _activeHotspot,
                                                      hotspotLabels:
                                                          _hotspotLabels,
                                                      radarController:
                                                          _radarController,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      onHotspotTap:
                                                          _onHotspotTap,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : SceneDescriptionScenicRadarMap(
                                            sceneTitle: _sceneTitle,
                                            inspectedHotspots:
                                                _inspectedHotspots,
                                            activeHotspot: _activeHotspot,
                                            hotspotLabels: _hotspotLabels,
                                            radarController: _radarController,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onHotspotTap: _onHotspotTap,
                                          ),
                                    SizedBox(height: gapMap),

                                    isCompact
                                        ? SizedBox(
                                            height: 80.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  child: _activeHotspot != -1
                                                      ? SceneDescriptionActivePromptCard(
                                                          activeHotspot:
                                                              _activeHotspot,
                                                          activePrompt:
                                                              _hotspotPrompts[_activeHotspot],
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                        )
                                                      : SceneDescriptionExplorerGuideCard(
                                                          isDark: isDark,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            child: _activeHotspot != -1
                                                ? SceneDescriptionActivePromptCard(
                                                    activeHotspot:
                                                        _activeHotspot,
                                                    activePrompt:
                                                        _hotspotPrompts[_activeHotspot],
                                                    primaryColor:
                                                        theme.primaryColor,
                                                    isDark: isDark,
                                                  )
                                                : SceneDescriptionExplorerGuideCard(
                                                    isDark: isDark,
                                                  ),
                                          ),
                                    SizedBox(height: gapPrompt),

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
                                                      SceneDescriptionTelemetryCard(
                                                        spokenText: _spokenText,
                                                        isDark: isDark,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : SceneDescriptionTelemetryCard(
                                              spokenText: _spokenText,
                                              isDark: isDark,
                                            ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTelemetry),
                                    AnimatedCrossFade(
                                      firstChild: const SizedBox(),
                                      secondChild: isCompact
                                          ? SizedBox(
                                              height: 100.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width:
                                                      constraints.maxWidth -
                                                      16.w,
                                                  child:
                                                      SceneDescriptionExplanationCard(
                                                        quest: quest,
                                                        isDark: isDark,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : SceneDescriptionExplanationCard(
                                              quest: quest,
                                              isDark: isDark,
                                            ),
                                      crossFadeState: _isAnswered
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                    ),
                                    SizedBox(height: gapBottom),

                                    if (!_isAnswered)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child:
                                                    SceneDescriptionMicTrigger(
                                                      isListening: _isListening,
                                                      activeHotspot:
                                                          _activeHotspot,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      onLongPressStart:
                                                          _startSpeechListening,
                                                      onLongPressEnd:
                                                          _stopSpeechListening,
                                                      attempts: _attempts,
                                                      isAnswered: _isAnswered,
                                                      onTutorPass: _tutorPass,
                                                    ),
                                              ),
                                            )
                                          : SceneDescriptionMicTrigger(
                                              isListening: _isListening,
                                              activeHotspot: _activeHotspot,
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                              onLongPressStart:
                                                  _startSpeechListening,
                                              onLongPressEnd:
                                                  _stopSpeechListening,
                                              attempts: _attempts,
                                              isAnswered: _isAnswered,
                                              onTutorPass: _tutorPass,
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
