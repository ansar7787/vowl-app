import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import '../widgets/flashcard_cluster_contrast_card.dart';
import '../widgets/flashcard_learn_view.dart';
import 'flashcards_learn_fallback_data.dart';

/// 2026 Interactive Learn Phase screen for Vocabulary Flashcards.
///
/// Features the tactile Discovery Deck with Tap-to-Speak Syllable Chips,
/// stressed syllable highlights, natural collocations, and the Nuance Contrast Matrix.
class FlashcardsLearnScreen extends StatefulWidget {
  final int level;

  const FlashcardsLearnScreen({super.key, required this.level});

  @override
  State<FlashcardsLearnScreen> createState() => _FlashcardsLearnScreenState();
}

class _FlashcardsLearnScreenState extends State<FlashcardsLearnScreen> {
  final ValueNotifier<bool> _isFlippedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSpeakingNotifier = ValueNotifier<bool>(false);
  Timer? _speechTimer;

  List<PhasedQuest> _quests = const [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showContrastMatrix = false;
  double _horizontalDragDelta = 0;

  @override
  void initState() {
    super.initState();
    _loadLearnQuests();
    _warmUpTtsEngine();
  }

  void _warmUpTtsEngine() {
    if (di.sl.isRegistered<TtsService>()) {
      // Pre-warm native audio pipeline asynchronously for older/budget devices
      try {
        final _ = di.sl<TtsService>().engineStatus;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _isFlippedNotifier.dispose();
    _isSpeakingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadLearnQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/flashcards_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests
          .where((q) => q.level == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          _quests = levelQuests.isNotEmpty ? levelQuests : batch.quests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = getFlashcardLearnFallbackQuests(widget.level);
          _isLoading = false;
        });
      }
    }
  }

  void _speakText(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      try {
        _speechTimer?.cancel();
        _isSpeakingNotifier.value = true;
        di.sl<TtsService>().speak(text);
        _speechTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) _isSpeakingNotifier.value = false;
        });
      } catch (_) {
        if (mounted) _isSpeakingNotifier.value = false;
      }
    }
  }

  void _flipCard() {
    _isFlippedNotifier.value = !_isFlippedNotifier.value;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
  }

  void _previousWord() {
    if (_currentIndex > 0) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      setState(() {
        _currentIndex--;
        _isFlippedNotifier.value = false;
      });
    }
  }

  void _nextWord() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().light();
    }
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlippedNotifier.value = false;
      });
    } else if (!_showContrastMatrix && _quests.length > 1) {
      setState(() {
        _showContrastMatrix = true;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'flashcards',
      level: widget.level,
      phase: 'learn',
    );
    final target =
        '/practice?category=vocabulary&gameType=flashcards&level=${widget.level}';
    try {
      context.pushReplacement(target);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const SafeArea(
          child: GameShimmerLoading(primaryColor: AppColors.indigo500),
        ),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (quest == null) {
      return LearnPhaseScaffold(
        title: 'Word Discovery',
        gameType: 'flashcards',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No learning material available.')),
      );
    }

    if (_showContrastMatrix) {
      return LearnPhaseScaffold(
        title: 'Compare Level Words',
        gameType: 'flashcards',
        level: widget.level,
        actionLabel: 'Start Practice',
        onComplete: _finishLearnPhase,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: FlashcardClusterContrastCard(
            quests: _quests,
            isDark: isDark,
            onProceed: _finishLearnPhase,
            onBackToCards: () => setState(() => _showContrastMatrix = false),
          ),
        ),
      );
    }

    final isLast = _currentIndex == _quests.length - 1;
    final actionLabel = isLast
        ? (_quests.length > 1 ? 'Compare Words' : 'Start Practice')
        : 'Next Word';

    return LearnPhaseScaffold(
      title: 'Word ${_currentIndex + 1} of ${_quests.length}',
      gameType: 'flashcards',
      level: widget.level,
      actionLabel: actionLabel,
      onComplete: _nextWord,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_quests.length > 1) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: ScaleButton(
                    onTap: () => setState(() => _showContrastMatrix = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate800
                            : AppColors.indigo500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.slate700
                              : AppColors.indigo500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14.r,
                            color: isDark
                                ? AppColors.indigo400
                                : AppColors.indigo600,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Compare Words',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.indigo400
                                  : AppColors.indigo600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                _horizontalDragDelta += details.primaryDelta ?? 0;
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200 || _horizontalDragDelta < -40) {
                  _nextWord();
                } else if (velocity > 200 || _horizontalDragDelta > 40) {
                  _previousWord();
                }
                _horizontalDragDelta = 0;
              },
              onHorizontalDragCancel: () {
                _horizontalDragDelta = 0;
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey('flashcard_$_currentIndex'),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isFlippedNotifier,
                    builder: (context, isFlipped, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _isSpeakingNotifier,
                        builder: (context, isSpeaking, _) {
                          return FlashcardLearnView(
                            quest: quest,
                            isFlipped: isFlipped,
                            isSpeaking: isSpeaking,
                            isDark: isDark,
                            onFlip: _flipCard,
                            clusterIndex: _currentIndex,
                            clusterTotal: _quests.length,
                            onSpeakSyllable: (syllable) => _speakText(syllable),
                            onSpeakFullWord: () {
                              if (quest.word != null) _speakText(quest.word!);
                            },
                            onSpeakExample: () {
                              if (quest.example != null) {
                                _speakText(quest.example!);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
