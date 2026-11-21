import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Data class representing a fused thematic cluster.
class TopicClusterGroup {
  final String categoryName;
  final String emoji;
  final List<String> words;
  final String? explanation;
  final List<String> collocations;

  const TopicClusterGroup({
    required this.categoryName,
    required this.emoji,
    required this.words,
    this.explanation,
    this.collocations = const [],
  });

  static List<String> _extractCollocations(
    List<String> words,
    VocabularyQuest quest,
  ) {
    final result = <String>[];
    for (final coll in quest.collocations ?? <String>[]) {
      if (words.any((w) => coll.toLowerCase().contains(w.toLowerCase()))) {
        result.add(coll);
      }
    }
    if (result.isEmpty && quest.relatedWords != null) {
      for (final rw in quest.relatedWords!) {
        if (words.any((w) => rw.toLowerCase().contains(w.toLowerCase()))) {
          final clean = rw.contains(':') ? rw.split(':')[0].trim() : rw.trim();
          if (clean.contains(' ')) result.add(clean);
        }
      }
    }
    return result;
  }

  /// Parses thematic cluster groups from curriculum JSON data with zero hardcoded fallbacks.
  static List<TopicClusterGroup> parseClusters(VocabularyQuest quest) {
    final Map<String, List<String>> bucketMap = {};
    if (quest.correctAnswer != null && quest.correctAnswer!.contains(':')) {
      for (final p in quest.correctAnswer!.split(',').map((s) => s.trim())) {
        final parts = p.split(':');
        if (parts.length == 2) {
          bucketMap.putIfAbsent(parts[0].trim(), () => []).add(parts[1].trim());
        }
      }
    }

    final emoji = quest.topicEmoji ?? '';

    if (bucketMap.isNotEmpty) {
      return bucketMap.entries.map((e) {
        return TopicClusterGroup(
          categoryName: e.key,
          emoji: emoji,
          words: e.value,
          explanation: quest.explanation,
          collocations: _extractCollocations(e.value, quest),
        );
      }).toList();
    }

    final buckets = quest.topicBuckets ?? <String>[];
    final options = quest.options ?? <String>[];
    final bucketCount = buckets.isNotEmpty ? buckets.length : 1;
    final perBucket =
        options.isNotEmpty ? (options.length / bucketCount).ceil() : 0;

    final result = <TopicClusterGroup>[];
    for (var i = 0; i < buckets.length; i++) {
      final start = i * perBucket;
      final end = (start + perBucket).clamp(0, options.length);
      final words = (start < options.length)
          ? options.sublist(start, end)
          : <String>[];
      result.add(
        TopicClusterGroup(
          categoryName: buckets[i],
          emoji: emoji,
          words: words,
          explanation: quest.explanation,
          collocations: _extractCollocations(words, quest),
        ),
      );
    }
    return result;
  }
}

/// Controller managing Cluster Fusion matrix interactions, selections,
/// one-away hints, and combo tracking.
class TopicVocabController extends ChangeNotifier {
  final List<TopicClusterGroup> _targetClusters;
  final int targetClusterSize;
  final HapticService _hapticService;

  late List<String> _remainingTiles;
  final Set<String> _selectedTiles = {};
  final List<TopicClusterGroup> _fusedClusters = [];

  bool _isOneAway = false;
  int _consecutiveSuccesses = 0;
  int _failedAttempts = 0;
  bool _isShaking = false;
  bool _isDisposed = false;
  Timer? _shakeTimer;

  TopicVocabController({
    required List<TopicClusterGroup> targetClusters,
    this.targetClusterSize = 3,
    List<String>? initialTiles,
    HapticService? hapticService,
  }) : _targetClusters = targetClusters,
       _hapticService =
           hapticService ??
           (di.sl.isRegistered<HapticService>()
               ? di.sl<HapticService>()
               : HapticService()) {
    if (initialTiles != null && initialTiles.isNotEmpty) {
      _remainingTiles = List.from(initialTiles);
    } else {
      _remainingTiles = _targetClusters.expand((c) => c.words).toList()
        ..shuffle();
    }
  }

  List<String> get remainingTiles => List.unmodifiable(_remainingTiles);
  Set<String> get selectedTiles => Set.unmodifiable(_selectedTiles);
  List<TopicClusterGroup> get targetClusters => List.unmodifiable(_targetClusters);
  List<TopicClusterGroup> get fusedClusters =>
      List.unmodifiable(_fusedClusters);
  bool get isOneAway => _isOneAway;
  int get comboMultiplier =>
      _consecutiveSuccesses > 1 ? _consecutiveSuccesses : 1;
  int get failedAttempts => _failedAttempts;
  bool get isShaking => _isShaking;
  bool get isComplete => _remainingTiles.isEmpty;
  int get remainingClusterCount =>
      _targetClusters.length - _fusedClusters.length;

  /// Toggles selection of a word tile.
  void toggleTile(String word) {
    if (_remainingTiles.contains(word)) {
      _isOneAway = false;
      if (_selectedTiles.contains(word)) {
        _selectedTiles.remove(word);
        _hapticService.selection();
      } else {
        if (_selectedTiles.length < targetClusterSize) {
          _selectedTiles.add(word);
          _hapticService.light();
        } else {
          _hapticService.warning();
        }
      }
      notifyListeners();
    }
  }

  /// Clears active selection.
  void deselectAll() {
    if (_selectedTiles.isNotEmpty) {
      _selectedTiles.clear();
      _isOneAway = false;
      notifyListeners();
    }
  }

  /// Shuffles remaining tiles on the board.
  void shuffleRemaining() {
    _remainingTiles.shuffle();
    _hapticService.selection();
    notifyListeners();
  }

  /// Checks if selected tiles are exactly one tile away from completing any cluster.
  void _checkOneAwayStatus() {
    if (_selectedTiles.length == targetClusterSize) {
      for (final cluster in _targetClusters) {
        if (_fusedClusters.any((f) => f.categoryName == cluster.categoryName)) {
          continue;
        }
        final matchCount = _selectedTiles
            .where((w) => cluster.words.contains(w))
            .length;
        if (matchCount == targetClusterSize - 1) {
          _isOneAway = true;
          return;
        }
      }
    }
    _isOneAway = false;
  }

  /// Submits the current selection for cluster fusion evaluation.
  /// Returns the completed [TopicClusterGroup] on match, or `null` on failure.
  TopicClusterGroup? submitFusion() {
    if (_selectedTiles.length != targetClusterSize) {
      _hapticService.warning();
      return null;
    }

    for (final cluster in _targetClusters) {
      if (_fusedClusters.any((f) => f.categoryName == cluster.categoryName)) {
        continue;
      }

      final isMatch = _selectedTiles.every((w) => cluster.words.contains(w));
      if (isMatch) {
        // Success
        _fusedClusters.add(cluster);
        _remainingTiles.removeWhere((w) => _selectedTiles.contains(w));
        _selectedTiles.clear();
        _isOneAway = false;
        _consecutiveSuccesses++;
        _hapticService.heavy();
        notifyListeners();
        return cluster;
      }
    }

    // Failed fusion
    _failedAttempts++;
    _consecutiveSuccesses = 0;
    _isShaking = true;
    _checkOneAwayStatus();
    _hapticService.error();
    notifyListeners();

    // Reset shake after brief frame
    _shakeTimer?.cancel();
    _shakeTimer = Timer(const Duration(milliseconds: 600), () {
      if (!_isDisposed) {
        _isShaking = false;
        notifyListeners();
      }
    });

    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _shakeTimer?.cancel();
    super.dispose();
  }

  /// Solves the puzzle automatically (e.g. for accessibility or skip hints).
  void autoSolve() {
    _fusedClusters.clear();
    _fusedClusters.addAll(_targetClusters);
    _remainingTiles.clear();
    _selectedTiles.clear();
    _isOneAway = false;
    notifyListeners();
  }
}
