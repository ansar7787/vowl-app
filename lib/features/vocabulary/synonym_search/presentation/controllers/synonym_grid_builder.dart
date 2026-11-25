import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Immutable generated letter matrix for Synonym Word-Grid Blitz.
@immutable
class SynonymGridModel {
  final int columns;
  final int rows;
  final List<String> letters;
  final String normalizedTarget;
  final Set<String> normalizedTraps;
  final List<int> targetPathIndices;

  const SynonymGridModel({
    required this.columns,
    required this.rows,
    required this.letters,
    required this.normalizedTarget,
    required this.normalizedTraps,
    required this.targetPathIndices,
  });

  int get totalCells => columns * rows;

  /// Checks whether two grid indices are 8-directional neighbors in O(1) time.
  bool isAdjacent(int a, int b) {
    if (a == b || a < 0 || b < 0 || a >= totalCells || b >= totalCells) {
      return false;
    }
    final ra = a ~/ columns;
    final ca = a % columns;
    final rb = b ~/ columns;
    final cb = b % columns;
    return math.max((ra - rb).abs(), (ca - cb).abs()) == 1;
  }

  /// Spells the uppercase letter sequence for the ordered cell [indices].
  String spellPath(List<int> indices) {
    if (indices.isEmpty) return '';
    final buffer = StringBuffer();
    for (final idx in indices) {
      if (idx >= 0 && idx < letters.length) {
        buffer.write(letters[idx]);
      }
    }
    return buffer.toString();
  }
}

/// Deterministic, zero-cost O(1) bounded connected word-search generator.
///
/// Embeds [correctAnswer] as an 8-directional connected path inside a 5x5 matrix
/// (or 6x5 matrix for unusually long >20-letter inputs), optionally weaves up to
/// 2 decoy trap words from [options], and fills remaining cells with frequency-balanced
/// letters.
class SynonymGridBuilder {
  const SynonymGridBuilder._();

  static const _fallbackFillerPool = 'ETAOINSHRDLCUMWFGYPBVKJXQZ';
  static const _maxDfsTries = 40;

  /// Normalizes any candidate string into A-Z uppercase characters for grid play.
  static String normalizeLetters(String raw) {
    return raw.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
  }

  /// Deterministic FNV-1a 32-bit hash so grids are identical across isolates and restarts.
  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static SynonymGridModel build({
    required String questId,
    required String correctAnswer,
    required List<String> options,
  }) {
    var target = normalizeLetters(correctAnswer);
    if (target.isEmpty) target = 'SYNONYM';

    final int columns = target.length > 20 ? 6 : 5;
    const int rows = 5;
    final int total = columns * rows;

    if (target.length > total) {
      target = target.substring(0, total);
    }

    final traps = <String>{};
    for (final opt in options) {
      final norm = normalizeLetters(opt);
      if (norm.length >= 2 && norm != target) {
        traps.add(norm);
      }
    }

    final rng = math.Random(_fnv1a('${questId}_$target'));
    final grid = List<String?>.filled(total, null);

    // 1. Place target word using compact corner-biased Warnsdorff pathing.
    final targetPath = _placeWord(
      grid: grid,
      word: target,
      columns: columns,
      rows: rows,
      rng: rng,
      preferCorners: true,
    );

    // 2. Weave up to 2 short decoy trap words into remaining free space.
    final sortedTraps = traps.where((t) => t.length <= 8).toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    int placedTraps = 0;
    for (final trap in sortedTraps) {
      if (placedTraps >= 2) break;
      final path = _placeWord(
        grid: grid,
        word: trap,
        columns: columns,
        rows: rows,
        rng: rng,
        preferCorners: false,
      );
      if (path.isNotEmpty) {
        placedTraps++;
      }
    }

    // 3. Fill empty cells with realistic letters weighted toward candidate pools.
    final weightedBuffer = StringBuffer(_fallbackFillerPool);
    weightedBuffer.write(target);
    for (final trap in sortedTraps.take(2)) {
      weightedBuffer.write(trap);
    }
    final pool = weightedBuffer.toString();

    for (int i = 0; i < total; i++) {
      grid[i] ??= pool[rng.nextInt(pool.length)];
    }

    return SynonymGridModel(
      columns: columns,
      rows: rows,
      letters: grid.cast<String>(),
      normalizedTarget: target,
      normalizedTraps: traps,
      targetPathIndices: targetPath,
    );
  }

  static List<int> _placeWord({
    required List<String?> grid,
    required String word,
    required int columns,
    required int rows,
    required math.Random rng,
    required bool preferCorners,
  }) {
    final total = columns * rows;
    final emptyIndices = <int>[
      for (int i = 0; i < total; i++)
        if (grid[i] == null) i,
    ];
    if (emptyIndices.length < word.length) return const [];

    emptyIndices.shuffle(rng);
    if (preferCorners) {
      // Bias slightly toward perimeter starts so inner tiles stay open for decoys.
      emptyIndices.sort((a, b) {
        final aScore = _edgeScore(a, columns, rows);
        final bScore = _edgeScore(b, columns, rows);
        return bScore.compareTo(aScore);
      });
    }

    int tries = 0;
    for (final start in emptyIndices) {
      if (tries >= _maxDfsTries) break;
      tries++;
      final path = <int>[start];
      final visited = <int>{start};
      final stepBudget = <int>[0];
      if (_dfsPlace(
        grid: grid,
        word: word,
        depth: 1,
        current: start,
        columns: columns,
        rows: rows,
        visited: visited,
        path: path,
        rng: rng,
        stepBudget: stepBudget,
      )) {
        for (int i = 0; i < word.length; i++) {
          grid[path[i]] = word[i];
        }
        return List<int>.unmodifiable(path);
      }
    }

    // Linear deterministic fallback for edge cases when preferCorners misses.
    if (preferCorners) {
      final path = emptyIndices.take(word.length).toList();
      if (path.length == word.length) {
        // Fallback: simple snake over entire empty board
        final snake = _buildSnakePath(columns, rows, word.length);
        if (snake.length == word.length) {
          for (int i = 0; i < word.length; i++) {
            grid[snake[i]] = word[i];
          }
          return List<int>.unmodifiable(snake);
        }
      }
    }
    return const [];
  }

  static const _maxDfsStepsPerTry = 400;

  static bool _dfsPlace({
    required List<String?> grid,
    required String word,
    required int depth,
    required int current,
    required int columns,
    required int rows,
    required Set<int> visited,
    required List<int> path,
    required math.Random rng,
    required List<int> stepBudget,
  }) {
    if (depth >= word.length) return true;
    if (++stepBudget[0] > _maxDfsStepsPerTry) return false;

    final neighbors = _freeNeighbors(
      index: current,
      grid: grid,
      visited: visited,
      columns: columns,
      rows: rows,
    );
    if (neighbors.isEmpty) return false;

    neighbors.shuffle(rng);
    // Warnsdorff heuristic: sort by precomputed onward free-neighbor count (0 allocations).
    final degrees = <int, int>{
      for (final n in neighbors)
        n: _freeNeighborCount(
          index: n,
          grid: grid,
          visited: visited,
          columns: columns,
          rows: rows,
        ),
    };
    neighbors.sort((a, b) => degrees[a]!.compareTo(degrees[b]!));

    for (final next in neighbors) {
      visited.add(next);
      path.add(next);
      if (_dfsPlace(
        grid: grid,
        word: word,
        depth: depth + 1,
        current: next,
        columns: columns,
        rows: rows,
        visited: visited,
        path: path,
        rng: rng,
        stepBudget: stepBudget,
      )) {
        return true;
      }
      path.removeLast();
      visited.remove(next);
    }
    return false;
  }

  static int _freeNeighborCount({
    required int index,
    required List<String?> grid,
    required Set<int> visited,
    required int columns,
    required int rows,
  }) {
    final r = index ~/ columns;
    final c = index % columns;
    int count = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= columns) continue;
        final nIdx = nr * columns + nc;
        if (grid[nIdx] == null && !visited.contains(nIdx)) {
          count++;
        }
      }
    }
    return count;
  }

  static List<int> _freeNeighbors({
    required int index,
    required List<String?> grid,
    required Set<int> visited,
    required int columns,
    required int rows,
  }) {
    final r = index ~/ columns;
    final c = index % columns;
    final result = <int>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= columns) continue;
        final nIdx = nr * columns + nc;
        if (grid[nIdx] == null && !visited.contains(nIdx)) {
          result.add(nIdx);
        }
      }
    }
    return result;
  }

  static int _edgeScore(int index, int columns, int rows) {
    final r = index ~/ columns;
    final c = index % columns;
    int score = 0;
    if (r == 0 || r == rows - 1) score++;
    if (c == 0 || c == columns - 1) score++;
    return score;
  }

  static List<int> _buildSnakePath(int columns, int rows, int length) {
    final path = <int>[];
    for (int r = 0; r < rows && path.length < length; r++) {
      if (r.isEven) {
        for (int c = 0; c < columns && path.length < length; c++) {
          path.add(r * columns + c);
        }
      } else {
        for (int c = columns - 1; c >= 0 && path.length < length; c--) {
          path.add(r * columns + c);
        }
      }
    }
    return path;
  }
}
