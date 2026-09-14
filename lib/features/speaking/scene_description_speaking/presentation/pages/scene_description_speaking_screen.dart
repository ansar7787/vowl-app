import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_header.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_scenic_radar_map.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_active_prompt_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_explorer_guide_card.dart';

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

  final ValueNotifier<Set<int>> _inspectedHotspots = ValueNotifier({});
  final ValueNotifier<int> _activeHotspot = ValueNotifier(-1);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _radarController;

  List<String> _hotspotLabels = [];
  List<String> _hotspotPrompts = [];
  List<List<String>> _hotspotKeywords = [];
  String _sceneTitle = "Scene Visualizer";
  final ScrollController _scrollController = ScrollController();

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
    _inspectedHotspots.dispose();
    _activeHotspot.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.sceneText != null) {
      final parts = quest.sceneText!.split('|');
      _soundService.playTts(parts[0]);
    }
  }

  void _onHotspotTap(int index) {
    if (_isAnswered.value || _inspectedHotspots.value.contains(index)) return;
    _hapticService.selection();
    if (!di.sl<AudioRecordingService>().isRecording) {
      _soundService.playTts(_hotspotLabels[index]);
    }
    _activeHotspot.value = index;
    _scrollToBottom();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value || _activeHotspot.value == -1) return;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      _inspectedHotspots.value = Set.from(_inspectedHotspots.value)
        ..add(_activeHotspot.value);
      _activeHotspot.value = -1;

      if (_inspectedHotspots.value.length >= _hotspotLabels.length) {
        _isAnswered.value = true;
        _isCorrect.value = true;
        context.read<SpeakingBloc>().add(const SubmitAnswer(true));
      }
    } else {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: _hotspotPrompts[_activeHotspot.value],
          userAnswer: '[Failed Self-Evaluation]',
          correctAnswer: _hotspotLabels[_activeHotspot.value],
          level: widget.level,
        );
      }

      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _parseQuestData(SpeakingQuest quest) {
    _hotspotLabels = quest.options ?? ["Object A", "Object B", "Object C"];
    final int count = _hotspotLabels.length;

    final String text =
        quest.sceneText ??
        "Visual Space Cabin|Describe features.|Describe features.|Describe features.";
    final List<String> parts = text.split('|');
    _sceneTitle = parts[0];

    _hotspotPrompts = [];
    for (int i = 1; i <= count; i++) {
      _hotspotPrompts.add(
        parts.length > i ? parts[i] : "Describe this scenic component.",
      );
    }

    _hotspotKeywords = [];
    final List<String> list =
        quest.acceptedSynonyms ?? List.filled(count, "feature,object,item");
    for (int i = 0; i < count; i++) {
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
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _inspectedHotspots.value = {};
            _activeHotspot.value = -1;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            _isAnswered.value = true; // Always show feedback card on incorrect
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'speaking_games.visual_masterpiece',
              fallback: 'VISUAL MASTERPIECE!',
            ),
            enableDoubleUp: true,
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
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _activeHotspot,
              _inspectedHotspots,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SceneDescriptionHeader(
                                      primaryColor: theme.primaryColor,
                                      instruction:
                                          InstructionHelper.getInstruction(
                                            quest,
                                          ),
                                    ),
                                    SizedBox(height: 24.h),
                                    SceneDescriptionScenicRadarMap(
                                      sceneTitle: _sceneTitle,
                                      inspectedHotspots:
                                          _inspectedHotspots.value,
                                      activeHotspot: _activeHotspot.value,
                                      hotspotLabels: _hotspotLabels,
                                      radarController: _radarController,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      onHotspotTap: _onHotspotTap,
                                    ),
                                    SizedBox(height: 32.h),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: _activeHotspot.value != -1
                                          ? SceneDescriptionActivePromptCard(
                                              activeHotspot:
                                                  _activeHotspot.value,
                                              activePrompt:
                                                  _hotspotPrompts[_activeHotspot
                                                      .value],
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                            )
                                          : SceneDescriptionExplorerGuideCard(
                                              isDark: isDark,
                                            ),
                                    ),
                                    if (quest.keyVocabulary != null &&
                                        quest.keyVocabulary!.isNotEmpty) ...[
                                      SizedBox(height: 24.h),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Target Vocabulary",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        alignment: WrapAlignment.start,
                                        children: quest.keyVocabulary!.map((
                                          word,
                                        ) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              word,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: theme.primaryColor,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (!_isAnswered.value &&
                                _activeHotspot.value != -1)
                              SliverToBoxAdapter(
                                child: SpeakToConfirmOverlay(
                                  key: ValueKey(_activeHotspot.value),
                                  expectedText:
                                      _hotspotKeywords[_activeHotspot.value]
                                          .join(" "),
                                  ttsText:
                                      _hotspotKeywords[_activeHotspot.value]
                                          .join(" "),
                                  acceptedSynonyms: [
                                    _hotspotKeywords[_activeHotspot.value].join(
                                      " ",
                                    ),
                                    _hotspotLabels[_activeHotspot.value],
                                  ],
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  hideExpectedText: true,
                                  allowSkip: false,
                                  title: 'DESCRIBE THE SCENE',
                                  subtitle: 'Speak your description aloud',
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                              ),
                            if (_isAnswered.value &&
                                _isCorrect.value == true &&
                                quest.sampleAnswer != null)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Container(
                                    padding: EdgeInsets.all(20.r),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.auto_awesome_rounded,
                                              color: theme.primaryColor,
                                              size: 18.r,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              "FULL SCENE DESCRIPTION",
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          quest.sampleAnswer!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            height: 1.4,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                        GestureDetector(
                                          onTap: () {
                                            di.sl<HapticService>().selection();
                                            di.sl<SoundService>().playTts(
                                              quest.sampleAnswer!,
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 8.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.volume_up_rounded,
                                                  color: theme.primaryColor,
                                                  size: 16.r,
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  "LISTEN",
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
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
