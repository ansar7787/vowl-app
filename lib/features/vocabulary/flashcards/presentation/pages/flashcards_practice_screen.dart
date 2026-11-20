import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import '../widgets/flashcard_learn_refresher_sheet.dart';
import '../widgets/flashcard_practice_chunk_weaver.dart';

/// 2026 Interactive Practice Phase screen for Vocabulary Flashcards.
///
/// Features the Word Chunk Weaver and instant Collocation Snap challenge.
class FlashcardsPracticeScreen extends StatefulWidget {
  final int level;

  const FlashcardsPracticeScreen({super.key, required this.level});

  @override
  State<FlashcardsPracticeScreen> createState() =>
      _FlashcardsPracticeScreenState();
}

class _FlashcardsPracticeScreenState extends State<FlashcardsPracticeScreen> {
  List<PhasedQuest> _quests = const [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Active Quest Interaction State
  List<String> _availableChunks = [];
  final List<String> _placedChunks = [];
  bool _hasCheckedAssembly = false;
  bool _isAssemblyCorrect = false;

  bool _showCollocationStage = false;
  int? _selectedCollocationIndex;
  bool _hasCheckedCollocation = false;

  int _shakeTrigger = 0;
  bool _showHint = false;
  int _consecutiveFailures = 0;

  @override
  void initState() {
    super.initState();
    _loadPracticeQuests();
  }

  Future<void> _loadPracticeQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/flashcards_practice_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests
          .where((q) => q.level == widget.level)
          .toList();
      final loaded = levelQuests.isNotEmpty ? levelQuests : batch.quests;

      if (mounted) {
        setState(() {
          _quests = loaded;
          _isLoading = false;
          _initQuestInteraction(0);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = [
            PhasedQuest(
              id: 'FALLBACK_P1',
              level: widget.level,
              word: 'AUTHENTIC',
              example:
                  'The chef insisted on using only _____ Italian ingredients for the pasta.',
              rawExtra: const {
                'hint': 'Think of a 3-syllable word meaning genuine.',
                'scrambledChunks': ['AU', 'THEN', 'TIC', 'TION', 'IC'],
                'collocationOptions': [
                  'authentic cuisine',
                  'authentic weather',
                  'authentic price',
                ],
                'correctCollocationIndex': 0,
              },
            ),
          ];
          _isLoading = false;
          _initQuestInteraction(0);
        });
      }
    }
  }

  void _initQuestInteraction(int index) {
    if (_quests.isEmpty || index >= _quests.length) return;
    final quest = _quests[index];

    final rawChunks = quest.rawExtra['scrambledChunks'] as List<dynamic>?;
    final chunks = rawChunks != null
        ? rawChunks.map((e) => e.toString()).toList()
        : (quest.word != null ? [quest.word!] : <String>[]);

    _availableChunks = List<String>.from(chunks);
    _placedChunks.clear();
    _hasCheckedAssembly = false;
    _isAssemblyCorrect = false;
    _showCollocationStage = false;
    _selectedCollocationIndex = null;
    _hasCheckedCollocation = false;
    _showHint = false;
  }

  void _addChunk(String chunk) {
    if (_hasCheckedAssembly) return;
    setState(() {
      _availableChunks.remove(chunk);
      _placedChunks.add(chunk);
    });
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
  }

  void _removeChunk(int index) {
    if (_hasCheckedAssembly || index >= _placedChunks.length) return;
    setState(() {
      final chunk = _placedChunks.removeAt(index);
      _availableChunks.add(chunk);
    });
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
  }

  void _checkAssembly() {
    if (_placedChunks.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please tap the chunks below to assemble the word first.',
        type: CustomSnackBarType.warning,
      );
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      return;
    }

    final assembled = _placedChunks.join('').toUpperCase();
    final target = (_quests[_currentIndex].word ?? '').toUpperCase();

    final isCorrect = assembled == target;
    setState(() {
      _hasCheckedAssembly = true;
      _isAssemblyCorrect = isCorrect;
      if (!isCorrect) {
        _shakeTrigger++;
        _consecutiveFailures++;
        if (_consecutiveFailures >= 3) {
          FlashcardLearnRefresherSheet.show(
            context,
            level: widget.level,
            onKeepPracticing: () {
              setState(() {
                _consecutiveFailures = 0;
                _initQuestInteraction(_currentIndex);
              });
            },
          );
        }
      } else {
        _consecutiveFailures = 0;
        _showCollocationStage = true;
      }
    });

    if (di.sl.isRegistered<HapticService>()) {
      if (isCorrect) {
        di.sl<HapticService>().success();
      } else {
        di.sl<HapticService>().error();
      }
    }
  }

  void _selectCollocation(int optionIndex) {
    final quest = _quests[_currentIndex];
    final correctIndex =
        (quest.rawExtra['correctCollocationIndex'] as num?)?.toInt() ?? 0;
    final isCorrect = optionIndex == correctIndex;

    setState(() {
      _selectedCollocationIndex = optionIndex;
      _hasCheckedCollocation = true;
      if (!isCorrect) _shakeTrigger++;
    });

    if (di.sl.isRegistered<HapticService>()) {
      if (isCorrect) {
        di.sl<HapticService>().success();
      } else {
        di.sl<HapticService>().error();
      }
    }
  }

  void _speakSentence(String rawSentence) {
    if (di.sl.isRegistered<TtsService>()) {
      try {
        final textToSpeak = rawSentence.replaceAll('_____', 'blank');
        di.sl<TtsService>().speak(textToSpeak);
      } catch (_) {}
    }
  }

  void _advanceOrFinish() {
    if (!_hasCheckedAssembly) {
      _checkAssembly();
      return;
    }

    if (!_isAssemblyCorrect) {
      setState(() => _initQuestInteraction(_currentIndex));
      return;
    }

    if (_showCollocationStage && !_hasCheckedCollocation) return;

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _consecutiveFailures = 0;
        _initQuestInteraction(_currentIndex);
      });
    } else {
      _finishPracticePhase();
    }
  }

  void _finishPracticePhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'flashcards',
      level: widget.level,
      phase: 'practice',
    );
    final target =
        '/game?category=vocabulary&gameType=flashcards&level=${widget.level}';
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
          child: GameShimmerLoading(primaryColor: Colors.amber),
        ),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (quest == null) {
      return PracticePhaseScaffold(
        title: 'Practice Studio',
        gameType: 'flashcards',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: _finishPracticePhase,
        child: const Center(child: Text('No practice exercises available.')),
      );
    }

    final isLast = _currentIndex == _quests.length - 1;
    String actionLabel = 'Check Word';
    if (_hasCheckedAssembly) {
      if (!_isAssemblyCorrect) {
        actionLabel = 'Try Again';
      } else if (_showCollocationStage && !_hasCheckedCollocation) {
        actionLabel = 'Select Partner';
      } else {
        actionLabel = isLast ? 'Enter Mastery Phase 🏆' : 'Next Exercise';
      }
    }

    final rawCollocationOptions =
        quest.rawExtra['collocationOptions'] as List<dynamic>?;
    final collocationOptions = rawCollocationOptions != null
        ? rawCollocationOptions.map((e) => e.toString()).toList()
        : const <String>[];
    final correctCollocationIndex =
        (quest.rawExtra['correctCollocationIndex'] as num?)?.toInt() ?? 0;

    return PracticePhaseScaffold(
      title: 'Exercise ${_currentIndex + 1} of ${_quests.length}',
      gameType: 'flashcards',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: actionLabel,
      isHintAvailable: quest.hint != null && !_showHint,
      onHint: () => setState(() => _showHint = true),
      onComplete: _advanceOrFinish,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FlashcardPracticeChunkWeaver(
              sentence: quest.example ?? '',
              targetWord: quest.word ?? '',
              availableChunks: _availableChunks,
              placedChunks: _placedChunks,
              hasCheckedAssembly: _hasCheckedAssembly,
              isAssemblyCorrect: _isAssemblyCorrect,
              showCollocationStage: _showCollocationStage,
              collocationPrompt: quest.rawExtra['collocationPrompt'] as String?,
              collocationOptions: collocationOptions,
              selectedCollocationIndex: _selectedCollocationIndex,
              correctCollocationIndex: correctCollocationIndex,
              hasCheckedCollocation: _hasCheckedCollocation,
              shakeTrigger: _shakeTrigger,
              isDark: isDark,
              onAddChunk: _addChunk,
              onRemoveChunk: _removeChunk,
              onCheckAssembly: _checkAssembly,
              onSelectCollocation: _selectCollocation,
              onSpeakSentence: () => _speakSentence(quest.example ?? ''),
              onClearChunks: () =>
                  setState(() => _initQuestInteraction(_currentIndex)),
            ),
            if (_showHint && quest.hint != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 18.r,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
