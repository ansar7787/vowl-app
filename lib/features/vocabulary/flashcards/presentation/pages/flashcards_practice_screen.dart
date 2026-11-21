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
import '../../data/services/flashcard_curriculum_service.dart';
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
  List<PhasedQuest> _quests = [];
  final Set<String> _remediatedWords = {};
  bool _currentQuestHadError = false;
  bool _isLoading = true;
  int _currentIndex = 0;

  // Active Quest Interaction State (ValueNotifiers for 120 FPS leaf rebuilds)
  late final ValueNotifier<List<String>> _availableChunksNotifier = ValueNotifier([]);
  late final ValueNotifier<List<String>> _placedChunksNotifier = ValueNotifier([]);
  List<String> get _availableChunks => _availableChunksNotifier.value;
  List<String> get _placedChunks => _placedChunksNotifier.value;

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

  @override
  void dispose() {
    _availableChunksNotifier.dispose();
    _placedChunksNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeQuests() async {
    final quests = await FlashcardCurriculumService().getPracticeQuests(
      widget.level,
    );
    if (mounted) {
      setState(() {
        _quests = List<PhasedQuest>.from(quests);
        _isLoading = false;
        _initQuestInteraction(0);
      });
    }
  }

  void _initQuestInteraction(int index) {
    if (_quests.isEmpty || index >= _quests.length) return;
    final quest = _quests[index];

    final rawChunks = quest.rawExtra['scrambledChunks'] as List<dynamic>?;
    List<String> chunks = rawChunks != null
        ? rawChunks.map((e) => e.toString()).toList()
        : (quest.word != null ? [quest.word!] : <String>[]);

    final targetWord = (quest.word ?? '').toUpperCase();
    final combinedUpper = chunks.join('').toUpperCase();
    if (combinedUpper.length == targetWord.length && chunks.length >= 2) {
      final distractor = targetWord.contains('TIC') ? 'TION' : 'ING';
      chunks = [...chunks, distractor]..shuffle();
    }

    _availableChunksNotifier.value = List<String>.from(chunks);
    _placedChunksNotifier.value = [];
    _hasCheckedAssembly = false;
    _isAssemblyCorrect = false;
    _showCollocationStage = false;
    _selectedCollocationIndex = null;
    _hasCheckedCollocation = false;
    _showHint = false;
    _currentQuestHadError = false;
  }

  void _addChunk(String chunk) {
    if (_hasCheckedAssembly) return;
    final nextAvail = List<String>.from(_availableChunksNotifier.value);
    final nextPlaced = List<String>.from(_placedChunksNotifier.value);
    if (nextAvail.remove(chunk)) {
      nextPlaced.add(chunk);
      _availableChunksNotifier.value = nextAvail;
      _placedChunksNotifier.value = nextPlaced;
      _triggerSelectionHaptic();
    }
  }

  void _removeChunk(int index) {
    if (_hasCheckedAssembly || index >= _placedChunksNotifier.value.length) {
      return;
    }
    final nextAvail = List<String>.from(_availableChunksNotifier.value);
    final nextPlaced = List<String>.from(_placedChunksNotifier.value);
    final chunk = nextPlaced.removeAt(index);
    nextAvail.add(chunk);
    _placedChunksNotifier.value = nextPlaced;
    _availableChunksNotifier.value = nextAvail;
    _triggerSelectionHaptic();
  }

  void _triggerSelectionHaptic() {
    HapticFeedback.selectionClick();
    if (di.sl.isRegistered<HapticService>()) di.sl<HapticService>().selection();
  }

  void _triggerFeedbackHaptic({required bool isCorrect}) {
    if (isCorrect) {
      HapticFeedback.heavyImpact();
      if (di.sl.isRegistered<HapticService>()) di.sl<HapticService>().success();
    } else {
      HapticFeedback.mediumImpact();
      if (di.sl.isRegistered<HapticService>()) di.sl<HapticService>().error();
    }
  }

  void _checkAssembly() {
    if (_placedChunks.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please tap the chunks below to assemble the word first.',
        type: CustomSnackBarType.warning,
      );
      HapticFeedback.lightImpact();
      if (di.sl.isRegistered<HapticService>()) di.sl<HapticService>().light();
      return;
    }

    final assembled = _placedChunks.join('').toUpperCase();
    final target = (_quests[_currentIndex].word ?? '').toUpperCase();
    final isCorrect = assembled == target;

    setState(() {
      _hasCheckedAssembly = true;
      _isAssemblyCorrect = isCorrect;
      if (!isCorrect) {
        _currentQuestHadError = true;
        _shakeTrigger++;
        _consecutiveFailures++;
        if (_consecutiveFailures >= 3) {
          FlashcardLearnRefresherSheet.show(
            context,
            level: widget.level,
            onKeepPracticing: () => setState(() {
              _consecutiveFailures = 0;
              _initQuestInteraction(_currentIndex);
            }),
          );
        }
      } else {
        _consecutiveFailures = 0;
        _showCollocationStage = true;
        if (di.sl.isRegistered<TtsService>()) {
          try {
            di.sl<TtsService>().speak(_quests[_currentIndex].word ?? '');
          } catch (_) {}
        }
      }
    });
    _triggerFeedbackHaptic(isCorrect: isCorrect);
  }

  void _selectCollocation(int optionIndex) {
    final quest = _quests[_currentIndex];
    final correctIndex =
        (quest.rawExtra['correctCollocationIndex'] as num?)?.toInt() ?? 0;
    final isCorrect = optionIndex == correctIndex;

    setState(() {
      _selectedCollocationIndex = optionIndex;
      _hasCheckedCollocation = true;
      if (!isCorrect) {
        _currentQuestHadError = true;
        _shakeTrigger++;
      }
    });
    _triggerFeedbackHaptic(isCorrect: isCorrect);
  }

  void _speakSentence(String rawSentence) {
    if (di.sl.isRegistered<TtsService>()) {
      try {
        di.sl<TtsService>().speak(rawSentence.replaceAll('_____', 'blank'));
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

    if (_currentQuestHadError) {
      final currentQuest = _quests[_currentIndex];
      if (currentQuest.word != null) {
        _remediatedWords.add(currentQuest.word!.toUpperCase());
      }
      // Re-queue failed question exactly 2 questions later (or append to end)
      final insertIndex = (_currentIndex + 3).clamp(0, _quests.length);
      _quests.insert(insertIndex, currentQuest);
    }

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
    try {
      context.pushReplacement(
        '/game?category=vocabulary&gameType=flashcards&level=${widget.level}',
      );
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
      } else if (isLast) {
        actionLabel = _currentQuestHadError
            ? 'Reinforce Missed Word 🔄'
            : 'Enter Mastery Phase 🏆';
      } else {
        actionLabel = 'Next Exercise';
      }
    }

    final rawCollocationOptions =
        quest.rawExtra['collocationOptions'] as List<dynamic>?;
    final collocationOptions = rawCollocationOptions
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final correctCollocationIndex =
        (quest.rawExtra['correctCollocationIndex'] as num?)?.toInt() ?? 0;

    final currentWord = (quest.word ?? '').toUpperCase();
    final isRemediating = _remediatedWords.contains(currentWord);
    final phaseTitle = isRemediating
        ? 'Reinforce ${_currentIndex + 1} of ${_quests.length} 🔄'
        : 'Exercise ${_currentIndex + 1} of ${_quests.length}';

    return PracticePhaseScaffold(
      title: phaseTitle,
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
              availableChunksNotifier: _availableChunksNotifier,
              placedChunksNotifier: _placedChunksNotifier,
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
            if (_showHint && quest.hint != null)
              _buildHintBox(quest.hint!, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHintBox(String hint, bool isDark) => Container(
    margin: EdgeInsets.only(top: 16.h),
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.lightbulb_rounded, size: 18.r, color: Colors.amber),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            hint,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
            ),
          ),
        ),
      ],
    ),
  );
}
