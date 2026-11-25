import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_grid_builder.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Reactive controller for Synonym Word-Grid Blitz (Mastery Phase).
///
/// Manages deterministic 5x5 (or 6x5) grid state, drag/tap path tracing,
/// mid-drag backtracking undo, forgiving short-slip resets, hint spotlights,
/// combo streaks, and submission race locking.
class SynonymMasteryController {
  final HapticService? hapticService;
  final VoidCallback onCorrectFound;
  final void Function(String? attemptedWord) onWrongAttempt;

  SynonymMasteryController({
    this.hapticService,
    required this.onCorrectFound,
    required this.onWrongAttempt,
  });

  final ValueNotifier<SynonymGridModel?> grid =
      ValueNotifier<SynonymGridModel?>(null);
  final ValueNotifier<List<int>> activePath = ValueNotifier<List<int>>(
    const [],
  );
  final ValueNotifier<int> comboStreak = ValueNotifier<int>(0);
  final ValueNotifier<bool> isHintActive = ValueNotifier<bool>(false);
  final ValueNotifier<int> shakeCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> showSuccessFlash = ValueNotifier<bool>(false);
  final ValueNotifier<String?> subtleStatusMessage = ValueNotifier<String?>(
    null,
  );

  String? _loadedQuestKey;
  bool _isSubmitting = false;
  bool _isDragging = false;
  Timer? _flashTimer;
  Timer? _statusTimer;

  bool get isSubmitting => _isSubmitting;

  String get currentSpelledWord =>
      grid.value?.spellPath(activePath.value) ?? '';

  /// Initializes or refreshes the board for [quest] and [level].
  void loadQuest(
    VocabularyQuest quest, {
    required int level,
    bool forceReset = false,
  }) {
    final key = '${quest.id}_L$level';
    if (!forceReset && _loadedQuestKey == key && grid.value != null) {
      return;
    }
    _loadedQuestKey = key;
    _isSubmitting = false;
    _isDragging = false;
    _flashTimer?.cancel();
    _statusTimer?.cancel();
    showSuccessFlash.value = false;
    subtleStatusMessage.value = null;
    activePath.value = const [];
    if (forceReset) {
      isHintActive.value = false;
    }

    grid.value = SynonymGridBuilder.build(
      questId: quest.id,
      correctAnswer: quest.correctAnswer ?? quest.synonym ?? 'LARGE',
      options: quest.options ?? const [],
    );
  }

  /// Computes fair countdown seconds scaled by CEFR tier + normalized word length.
  int timerDurationFor(VocabularyQuest quest, int level) {
    final len = SynonymGridBuilder.normalizeLetters(
      quest.correctAnswer ?? quest.synonym ?? '',
    ).length;
    return SynonymCefrHelper.masteryTimerSeconds(
      level: level,
      normalizedWordLength: len,
    );
  }

  void resetForRetryOrNext({bool keepComboOnNext = true}) {
    _isSubmitting = false;
    _isDragging = false;
    _flashTimer?.cancel();
    _statusTimer?.cancel();
    activePath.value = const [];
    isHintActive.value = false;
    showSuccessFlash.value = false;
    subtleStatusMessage.value = null;
    if (!keepComboOnNext) {
      comboStreak.value = 0;
    }
  }

  void activateHint() {
    if (isHintActive.value) return;
    isHintActive.value = true;
    hapticService?.selection();
  }

  // ── Drag-Trace Interactions ───────────────────────────────────────────────

  void startDragAt(int cellIndex) {
    final g = grid.value;
    if (g == null ||
        _isSubmitting ||
        cellIndex < 0 ||
        cellIndex >= g.totalCells) {
      return;
    }
    _isDragging = true;
    subtleStatusMessage.value = null;
    activePath.value = [cellIndex];
    hapticService?.light();
  }

  void extendDragTo(int cellIndex) {
    final g = grid.value;
    if (!_isDragging || g == null || _isSubmitting) return;
    if (cellIndex < 0 || cellIndex >= g.totalCells) return;

    final current = activePath.value;
    if (current.isEmpty) {
      startDragAt(cellIndex);
      return;
    }
    if (current.last == cellIndex) return;

    // Live mid-drag backtracking: dragging onto second-to-last tile undoes last step.
    if (current.length >= 2 && cellIndex == current[current.length - 2]) {
      activePath.value = current.sublist(0, current.length - 1);
      hapticService?.selection();
      return;
    }

    if (!current.contains(cellIndex) && g.isAdjacent(current.last, cellIndex)) {
      final updated = [...current, cellIndex];
      activePath.value = updated;
      hapticService?.selection();

      if (g.spellPath(updated) == g.normalizedTarget) {
        _isDragging = false;
        _triggerSuccess();
      }
    }
  }

  void endDrag() {
    if (!_isDragging) return;
    _isDragging = false;
    final g = grid.value;
    if (g == null || _isSubmitting || activePath.value.isEmpty) return;

    final spelled = g.spellPath(activePath.value);
    if (spelled == g.normalizedTarget) {
      _triggerSuccess();
      return;
    }

    if (g.normalizedTraps.contains(spelled)) {
      _triggerTrapFailure(spelled);
      return;
    }

    // Forgiving drag-slip guard: incomplete non-trap traces reset with zero heart loss.
    if (activePath.value.length >= 2) {
      _showSubtleHint('Keep going until the full word is selected.');
    }
    activePath.value = const [];
  }

  // ── Accessible Tap-to-Trace Interactions ──────────────────────────────────

  void tapCell(int cellIndex) {
    final g = grid.value;
    if (g == null ||
        _isSubmitting ||
        cellIndex < 0 ||
        cellIndex >= g.totalCells) {
      return;
    }
    subtleStatusMessage.value = null;
    final current = activePath.value;

    if (current.isEmpty) {
      activePath.value = [cellIndex];
      hapticService?.light();
      return;
    }

    if (current.last == cellIndex) {
      activePath.value = current.sublist(0, current.length - 1);
      hapticService?.selection();
      return;
    }

    if (!current.contains(cellIndex) && g.isAdjacent(current.last, cellIndex)) {
      final updated = [...current, cellIndex];
      activePath.value = updated;
      hapticService?.selection();

      final spelled = g.spellPath(updated);
      if (spelled == g.normalizedTarget) {
        _triggerSuccess();
      } else if (g.normalizedTraps.contains(spelled)) {
        _triggerTrapFailure(spelled);
      }
      return;
    }

    // Tapping a non-adjacent tile starts a fresh selection cleanly.
    activePath.value = [cellIndex];
    hapticService?.light();
  }

  void backspace() {
    if (_isSubmitting || activePath.value.isEmpty) return;
    hapticService?.selection();
    activePath.value = activePath.value.sublist(0, activePath.value.length - 1);
  }

  void clearPath() {
    if (_isSubmitting || activePath.value.isEmpty) return;
    hapticService?.light();
    activePath.value = const [];
  }

  void handleTimerExpired() {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _isDragging = false;
    comboStreak.value = 0;
    shakeCount.value = shakeCount.value + 1;
    onWrongAttempt(null);
  }

  void _triggerSuccess() {
    if (_isSubmitting) return;
    _isSubmitting = true;
    comboStreak.value = comboStreak.value + 1;
    showSuccessFlash.value = true;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 220), () {
      showSuccessFlash.value = false;
    });
    onCorrectFound();
  }

  void _triggerTrapFailure(String trapWord) {
    if (_isSubmitting) return;
    _isSubmitting = true;
    comboStreak.value = 0;
    shakeCount.value = shakeCount.value + 1;
    onWrongAttempt(trapWord);
  }

  void _showSubtleHint(String text) {
    subtleStatusMessage.value = text;
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(milliseconds: 1600), () {
      subtleStatusMessage.value = null;
    });
  }

  void dispose() {
    _flashTimer?.cancel();
    _statusTimer?.cancel();
    grid.dispose();
    activePath.dispose();
    comboStreak.dispose();
    isHintActive.dispose();
    shakeCount.dispose();
    showSuccessFlash.dispose();
    subtleStatusMessage.dispose();
  }
}
