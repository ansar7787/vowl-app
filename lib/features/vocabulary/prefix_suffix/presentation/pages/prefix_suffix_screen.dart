import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_combo_hud.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_precision_slicer.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_translation_banner.dart';

/// Interactive Prefix & Suffix Mastery Game Screen: "Morpheme Precision Slicer".
///
/// Features:
/// - 5-second rapid reaction countdown timer with combo multiplier HUD.
/// - Laser seam slicing mechanics across morpheme boundaries.
/// - Integrated with [VocabularyBaseLayout] (single-turn arcade mode: hasStage2: false).
class PrefixSuffixScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Whether this session is running as a mastery bonus stage.
  final bool isBonusStage;

  /// Whether the arcade countdown timer is active.
  final bool enableTimer;

  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
    this.isBonusStage = false,
    this.enableTimer = true,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<PrefixSuffixScreen>,
        VocabularyGameScreenMixin<PrefixSuffixScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'Level Complete!';

  late final PrefixSuffixController _controller;
  VocabularyQuest? _currentQuest;

  @override
  void initState() {
    super.initState();
    _controller = PrefixSuffixController();
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm(locale: 'en-US'));
    }
    initVocabularyGame();
  }

  @override
  void dispose() {
    TtsSpeakerButtonWidget.stopAll();
    _controller.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void onGamePaused() {
    super.onGamePaused();
    TtsSpeakerButtonWidget.stopAll();
  }

  void _startTimer(VocabularyQuest quest) {
    if (!widget.enableTimer) return;
    _controller.startMasteryTimer(
      durationSeconds: 5,
      onExpired: () {
        if (!isAnsweredNotifier.value && mounted) {
          _controller.evaluateSlice(cutIndex: -1, correctCutIndex: 0);
          if (di.sl.isRegistered<SoundService>()) {
            di.sl<SoundService>().playWrong();
          }
          if (di.sl.isRegistered<HapticService>()) {
            di.sl<HapticService>().error();
          }
          submitWrongAnswer(quest: quest, userAnswer: 'timeout');
        }
      },
    );
  }

  void _onQuestLoaded(VocabularyQuest quest) {
    if (_currentQuest?.id == quest.id) return;
    TtsSpeakerButtonWidget.stopAll();
    _currentQuest = quest;
    _controller.resetForNextQuest();
    _startTimer(quest);
  }

  int _calculateCorrectCutIndex(VocabularyQuest quest) {
    if (quest.instruction.toUpperCase().contains('UNBREAKABLE') ||
        quest.instruction.toUpperCase().contains('IMPOSTER') ||
        quest.correctAnswer?.toUpperCase().trim() == 'NONE' ||
        quest.correctAnswer?.toUpperCase().trim() == '0') {
      return 0;
    }

    final word = quest.word ?? '';
    final prefix = quest.prefix?.replaceAll('-', '').trim() ?? '';
    if (prefix.isNotEmpty &&
        word.toUpperCase().startsWith(prefix.toUpperCase())) {
      return prefix.length;
    }

    final suffix = quest.suffix?.replaceAll('-', '').trim() ?? '';
    if (suffix.isNotEmpty &&
        word.toUpperCase().endsWith(suffix.toUpperCase())) {
      return word.length - suffix.length;
    }

    final correctAnswer = quest.correctAnswer?.replaceAll('-', '').trim() ?? '';
    if (correctAnswer.isNotEmpty) {
      if (word.toUpperCase().startsWith(correctAnswer.toUpperCase())) {
        return correctAnswer.length;
      } else if (word.toUpperCase().endsWith(correctAnswer.toUpperCase())) {
        return word.length - correctAnswer.length;
      }
    }

    return (word.length ~/ 2).clamp(1, (word.length - 1).clamp(1, 99));
  }

  int? _calculateSecondaryCutIndex(VocabularyQuest quest) {
    final word = quest.word ?? '';
    final prefix = quest.prefix?.replaceAll('-', '').trim() ?? '';
    final suffix = quest.suffix?.replaceAll('-', '').trim() ?? '';
    if (prefix.isNotEmpty &&
        suffix.isNotEmpty &&
        word.toUpperCase().startsWith(prefix.toUpperCase()) &&
        word.toUpperCase().endsWith(suffix.toUpperCase()) &&
        word.length > prefix.length + suffix.length) {
      return word.length - suffix.length;
    }
    return null;
  }

  void _handleSlice(int severedSeam, VocabularyQuest quest) {
    if (isAnsweredNotifier.value) return;

    final correctSeam = _calculateCorrectCutIndex(quest);
    final secondarySeam = _calculateSecondaryCutIndex(quest);
    final isCorrect = _controller.evaluateSlice(
      cutIndex: severedSeam,
      correctCutIndex: correctSeam,
      secondaryCutIndex: secondarySeam,
    );

    if (isCorrect) {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      submitCorrectAnswer();
    } else {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      submitWrongAnswer(quest: quest, userAnswer: 'seam_$severedSeam');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        if (state is! VocabularyLoaded) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.slate900
                : const Color(0xFFF8FAFC),
            body: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ShimmerLoading.rounded(
                  width: double.infinity,
                  height: 380.h,
                  borderRadius: 20,
                ),
              ),
            ),
          );
        }

        final quest = state.currentQuest;
        _onQuestLoaded(quest);

        final word = quest.word ?? 'PREVIEW';
        final correctCutIndex = _calculateCorrectCutIndex(quest);

        return VocabularyBaseLayout(
          gameType: gameType,
          level: level,
          isAnswered: isAnsweredNotifier.value,
          isCorrect: isCorrectNotifier.value,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                isCorrectNotifier.value == false) {
              isAnsweredNotifier.value = false;
              isCorrectNotifier.value = null;
              _controller.resetForNextQuest();
              if (_currentQuest != null) {
                _startTimer(_currentQuest!);
              }
            } else {
              context.read<VocabularyBloc>().add(const NextQuestion());
            }
          },
          hasStage2: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  children: [
                    // Urgency Combo HUD
                    PrefixSuffixComboHud(
                      timeFraction: _controller.timeFraction,
                      secondsRemaining: _controller.secondsRemaining,
                      comboMultiplier: _controller.comboMultiplier,
                      currentStreak: _controller.streak,
                    ),
                    SizedBox(height: 16.h),

                    // Instruction Prompt
                    Text(
                      quest.instruction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Precision Slicer Board
                    PrefixSuffixPrecisionSlicer(
                      word: word,
                      correctCutIndex: correctCutIndex,
                      secondaryCutIndex: _calculateSecondaryCutIndex(quest),
                      isSliced: _controller.isSliced,
                      isWrongCut: _controller.isWrongCut,
                      isAnswered: isAnsweredNotifier.value,
                      onSlice: (seam) => _handleSlice(seam, quest),
                    ),
                    SizedBox(height: 16.h),

                    // Semantic Context & Definition with 1-Click Translation & Native Audio
                    if (quest.definition != null &&
                        quest.definition!.isNotEmpty) ...[
                      PrefixSuffixTranslationBanner(
                        originalText: quest.definition!,
                        isDark: isDark,
                        accentColor: AppColors.indigo500,
                        label: 'Definition & Meaning',
                      ),
                    ],
                    SizedBox(height: 16.h),
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
