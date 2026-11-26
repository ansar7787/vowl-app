import 'package:flutter/foundation.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Reactive controller managing Learn Phase interactive swaps, related word preview, and Read aloud state.
class SynonymLearnController {
  final HapticService? hapticService;

  SynonymLearnController({this.hapticService});

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  final ValueNotifier<Map<int, Set<int>>> swappedByQuest =
      ValueNotifier<Map<int, Set<int>>>(const {});
  final ValueNotifier<Map<int, Map<int, bool>>> predictionByQuest =
      ValueNotifier<Map<int, Map<int, bool>>>(const {});
  final ValueNotifier<Map<int, int?>> selectedCousinByQuest =
      ValueNotifier<Map<int, int?>>(const {});
  final ValueNotifier<bool> autoSpeak = ValueNotifier<bool>(false);

  List<SynonymLearnItem> _items = const [];

  List<SynonymLearnItem> get items => _items;

  SynonymLearnItem? get currentItem =>
      (_items.isNotEmpty && currentIndex.value < _items.length)
      ? _items[currentIndex.value]
      : null;

  void setItems(List<SynonymLearnItem> items) {
    _items = List<SynonymLearnItem>.unmodifiable(items);
    currentIndex.value = 0;
    swappedByQuest.value = const {};
    predictionByQuest.value = const {};
    selectedCousinByQuest.value = const {};
  }

  bool isMakeoverSwapped(int scenarioIndex) {
    final activeSet = swappedByQuest.value[currentIndex.value];
    return activeSet?.contains(scenarioIndex) ?? false;
  }

  bool? predictionFor(int scenarioIndex) {
    return predictionByQuest.value[currentIndex.value]?[scenarioIndex];
  }

  int testedCountForCurrent() {
    final swapped = swappedByQuest.value[currentIndex.value] ?? const <int>{};
    final predicted =
        predictionByQuest.value[currentIndex.value]?.keys ?? const <int>[];
    return {...swapped, ...predicted}.length;
  }

  int? selectedCousinIndexForCurrent() {
    return selectedCousinByQuest.value[currentIndex.value];
  }

  void toggleMakeoverSwap(int scenarioIndex) {
    hapticService?.selection();
    final updated = Map<int, Set<int>>.from(swappedByQuest.value);
    final currentSet = Set<int>.from(updated[currentIndex.value] ?? const {});
    if (currentSet.contains(scenarioIndex)) {
      currentSet.remove(scenarioIndex);
    } else {
      currentSet.add(scenarioIndex);
    }
    updated[currentIndex.value] = currentSet;
    swappedByQuest.value = updated;
  }

  /// Records the learner's naturalness prediction and flips the sentence swap.
  void predictMakeover(int scenarioIndex, {required bool predictedNatural}) {
    hapticService?.selection();
    final updatedPreds = Map<int, Map<int, bool>>.from(predictionByQuest.value);
    final questPreds = Map<int, bool>.from(
      updatedPreds[currentIndex.value] ?? const {},
    );
    questPreds[scenarioIndex] = predictedNatural;
    updatedPreds[currentIndex.value] = questPreds;
    predictionByQuest.value = updatedPreds;

    final updatedSwaps = Map<int, Set<int>>.from(swappedByQuest.value);
    final currentSet = Set<int>.from(
      updatedSwaps[currentIndex.value] ?? const {},
    );
    currentSet.add(scenarioIndex);
    updatedSwaps[currentIndex.value] = currentSet;
    swappedByQuest.value = updatedSwaps;
  }

  void selectCousin(int cousinIndex) {
    hapticService?.light();
    final updated = Map<int, int?>.from(selectedCousinByQuest.value);
    final current = updated[currentIndex.value];
    updated[currentIndex.value] = current == cousinIndex ? null : cousinIndex;
    selectedCousinByQuest.value = updated;
  }

  /// Advances to the next pair; returns `true` if advanced, `false` if already at end.
  bool nextPair() {
    if (currentIndex.value < _items.length - 1) {
      hapticService?.selection();
      currentIndex.value = currentIndex.value + 1;
      return true;
    }
    return false;
  }

  void previousPair() {
    if (currentIndex.value > 0) {
      hapticService?.selection();
      currentIndex.value = currentIndex.value - 1;
    }
  }

  void toggleAutoSpeak() {
    hapticService?.selection();
    autoSpeak.value = !autoSpeak.value;
  }

  void dispose() {
    currentIndex.dispose();
    swappedByQuest.dispose();
    predictionByQuest.dispose();
    selectedCousinByQuest.dispose();
    autoSpeak.dispose();
  }
}
