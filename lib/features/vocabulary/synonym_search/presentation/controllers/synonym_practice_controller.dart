import 'package:flutter/foundation.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Reactive controller managing Contrast Swap & Synonym Ladder drills in Practice Phase.
class SynonymPracticeController {
  final HapticService? hapticService;

  SynonymPracticeController({this.hapticService});

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  final ValueNotifier<List<String?>> contrastAssignments =
      ValueNotifier<List<String?>>(const [null, null]);
  final ValueNotifier<int?> focusedSlotIndex = ValueNotifier<int?>(0);
  final ValueNotifier<List<String?>> ladderPlacements =
      ValueNotifier<List<String?>>(const [null, null, null]);
  final ValueNotifier<int?> focusedRungIndex = ValueNotifier<int?>(0);
  final ValueNotifier<bool> hasChecked = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCorrect = ValueNotifier<bool>(false);
  final ValueNotifier<String?> feedbackMessage = ValueNotifier<String?>(null);
  final ValueNotifier<bool> showHint = ValueNotifier<bool>(false);
  final ValueNotifier<int> wrongAttempts = ValueNotifier<int>(0);
  final ValueNotifier<int> shakeCount = ValueNotifier<int>(0);

  List<SynonymPracticeExercise> _exercises = const [];

  List<SynonymPracticeExercise> get exercises => _exercises;

  SynonymPracticeExercise? get currentExercise =>
      (_exercises.isNotEmpty && currentIndex.value < _exercises.length)
      ? _exercises[currentIndex.value]
      : null;

  void setExercises(List<SynonymPracticeExercise> exercises) {
    _exercises = List<SynonymPracticeExercise>.unmodifiable(exercises);
    currentIndex.value = 0;
    _resetExerciseState();
  }

  void _resetExerciseState() {
    final ex = currentExercise;
    final slotLen = ex?.slots.length ?? 2;
    final ladderLen = ex?.orderedWords.length ?? 3;
    contrastAssignments.value = List<String?>.filled(slotLen, null);
    focusedSlotIndex.value = slotLen > 0 ? 0 : null;
    ladderPlacements.value = List<String?>.filled(ladderLen, null);
    focusedRungIndex.value = ladderLen > 0 ? 0 : null;
    hasChecked.value = false;
    isCorrect.value = false;
    feedbackMessage.value = null;
    showHint.value = false;
    wrongAttempts.value = 0;
  }

  bool get canCheck {
    final ex = currentExercise;
    if (ex == null) return false;
    if (ex.type == SynonymPracticeExerciseType.contrastSwap) {
      return contrastAssignments.value.isNotEmpty &&
          contrastAssignments.value.every((w) => w != null && w.isNotEmpty);
    }
    return ladderPlacements.value.isNotEmpty &&
        ladderPlacements.value.every((w) => w != null && w.isNotEmpty);
  }

  // ── Contrast Swap interactions ────────────────────────────────────────────

  void tapContrastSlot(int slotIndex) {
    if (hasChecked.value && isCorrect.value) return;
    hapticService?.selection();
    _clearPendingWrongState();

    final current = List<String?>.from(contrastAssignments.value);
    if (slotIndex < current.length && current[slotIndex] != null) {
      current[slotIndex] = null;
      contrastAssignments.value = current;
      focusedSlotIndex.value = slotIndex;
      return;
    }
    focusedSlotIndex.value = slotIndex;
  }

  void assignContrastWord(String word) {
    if (hasChecked.value && isCorrect.value) return;
    hapticService?.selection();
    _clearPendingWrongState();

    final current = List<String?>.from(contrastAssignments.value);
    final existingIdx = current.indexWhere(
      (w) => w?.toLowerCase() == word.toLowerCase(),
    );

    int targetSlot = focusedSlotIndex.value ?? current.indexOf(null);
    if (targetSlot < 0 || targetSlot >= current.length) {
      targetSlot = current.indexOf(null);
    }
    if (targetSlot < 0) targetSlot = 0;

    if (existingIdx != -1) {
      // Swap existing word seamlessly if already placed in the other slot
      final displaced = current[targetSlot];
      current[targetSlot] = word;
      current[existingIdx] = displaced;
    } else {
      current[targetSlot] = word;
    }

    contrastAssignments.value = current;
    final nextEmpty = current.indexOf(null);
    focusedSlotIndex.value = nextEmpty != -1 ? nextEmpty : null;
  }

  /// Swaps both filled Contrast Swap slots in a single tap.
  void swapContrastSlots() {
    if (hasChecked.value && isCorrect.value) return;
    final current = contrastAssignments.value;
    if (current.length < 2) return;
    hapticService?.selection();
    _clearPendingWrongState();
    contrastAssignments.value = [current[1], current[0], ...current.skip(2)];
    focusedSlotIndex.value = null;
  }

  // ── Synonym Ladder interactions ───────────────────────────────────────────

  void tapLadderRung(int rungIndex) {
    if (hasChecked.value && isCorrect.value) return;
    hapticService?.selection();
    _clearPendingWrongState();

    final current = List<String?>.from(ladderPlacements.value);
    if (rungIndex < current.length && current[rungIndex] != null) {
      current[rungIndex] = null;
      ladderPlacements.value = current;
      focusedRungIndex.value = rungIndex;
      return;
    }
    focusedRungIndex.value = rungIndex;
  }

  void placeLadderWord(String word) {
    if (hasChecked.value && isCorrect.value) return;
    hapticService?.selection();
    _clearPendingWrongState();

    final current = List<String?>.from(ladderPlacements.value);
    final existingIdx = current.indexWhere(
      (w) => w?.toLowerCase() == word.toLowerCase(),
    );

    int targetRung = focusedRungIndex.value ?? current.indexOf(null);
    if (targetRung < 0 || targetRung >= current.length) {
      targetRung = current.indexOf(null);
    }
    if (targetRung < 0) targetRung = 0;

    if (existingIdx != -1) {
      final displaced = current[targetRung];
      current[targetRung] = word;
      current[existingIdx] = displaced;
    } else {
      current[targetRung] = word;
    }

    ladderPlacements.value = current;
    final nextEmpty = current.indexOf(null);
    focusedRungIndex.value = nextEmpty != -1 ? nextEmpty : null;
  }

  void _clearPendingWrongState() {
    if (hasChecked.value && !isCorrect.value) {
      hasChecked.value = false;
      feedbackMessage.value = null;
    }
  }

  void toggleHint() {
    hapticService?.selection();
    final next = !showHint.value;
    showHint.value = next;

    // Scaffolding: when revealing hint before solved, pre-lock the first anchor slot/rung if empty.
    final ex = currentExercise;
    if (!next || ex == null || (hasChecked.value && isCorrect.value)) return;
    if (ex.type == SynonymPracticeExerciseType.contrastSwap &&
        ex.slots.isNotEmpty) {
      final current = List<String?>.from(contrastAssignments.value);
      if (current[0] == null) {
        assignContrastWord(ex.slots[0].correctWord);
      }
    } else if (ex.type == SynonymPracticeExerciseType.synonymLadder &&
        ex.orderedWords.isNotEmpty) {
      final current = List<String?>.from(ladderPlacements.value);
      if (current[0] == null) {
        placeLadderWord(ex.orderedWords[0]);
      }
    }
  }

  /// Validates the active drill, updating feedback, shake counter, and coaching.
  bool checkAnswer() {
    final ex = currentExercise;
    if (ex == null || !canCheck) return false;

    bool passed = false;
    String fb = '';

    if (ex.type == SynonymPracticeExerciseType.contrastSwap) {
      final placed = contrastAssignments.value;
      int mismatchIdx = -1;
      for (int i = 0; i < ex.slots.length; i++) {
        if ((placed[i] ?? '').trim().toLowerCase() !=
            ex.slots[i].correctWord.trim().toLowerCase()) {
          mismatchIdx = i;
          break;
        }
      }
      passed = mismatchIdx == -1;
      fb = passed
          ? ex.slots.map((s) => s.feedback).join(' ')
          : ex.slots[mismatchIdx].feedback;
    } else {
      final placed = ladderPlacements.value;
      passed = true;
      for (int i = 0; i < ex.orderedWords.length; i++) {
        if ((placed[i] ?? '').trim().toLowerCase() !=
            ex.orderedWords[i].trim().toLowerCase()) {
          passed = false;
          break;
        }
      }
      fb = passed
          ? ex.explanation
          : '${ex.hint.isNotEmpty ? ex.hint : ex.explanation} Tap a rung to adjust and try again.';
    }

    hasChecked.value = true;
    isCorrect.value = passed;
    feedbackMessage.value = fb;

    if (passed) {
      hapticService?.success();
    } else {
      wrongAttempts.value = wrongAttempts.value + 1;
      shakeCount.value = shakeCount.value + 1;
      hapticService?.error();
    }
    return passed;
  }

  /// Guided reveal after repeated misses so learners never hit a dead end.
  void revealGuidedSolution() {
    final ex = currentExercise;
    if (ex == null) return;
    hapticService?.selection();

    if (ex.type == SynonymPracticeExerciseType.contrastSwap) {
      contrastAssignments.value = ex.slots.map((s) => s.correctWord).toList();
      focusedSlotIndex.value = null;
      feedbackMessage.value = ex.slots.map((s) => s.feedback).join(' ');
    } else {
      ladderPlacements.value = List<String?>.from(ex.orderedWords);
      focusedRungIndex.value = null;
      feedbackMessage.value = ex.explanation;
    }
    hasChecked.value = true;
    isCorrect.value = true;
  }

  /// Moves to next exercise; returns `false` when already at the final exercise.
  bool nextExercise() {
    if (currentIndex.value < _exercises.length - 1) {
      currentIndex.value = currentIndex.value + 1;
      _resetExerciseState();
      return true;
    }
    return false;
  }

  void dispose() {
    currentIndex.dispose();
    contrastAssignments.dispose();
    focusedSlotIndex.dispose();
    ladderPlacements.dispose();
    focusedRungIndex.dispose();
    hasChecked.dispose();
    isCorrect.dispose();
    feedbackMessage.dispose();
    showHint.dispose();
    wrongAttempts.dispose();
    shakeCount.dispose();
  }
}
