// ignore_for_file: avoid_print
/// Build-time script: Scans `assets/curriculum/` and generates a const Dart
/// map of level counts per game type.
///
/// Usage:
///   dart run scripts/generate_curriculum_manifest.dart
///
/// Run this after adding/removing curriculum JSON files.
///
/// Supports TWO naming conventions:
/// 1. Main games: `gameType_startLevel_endLevel.json` (e.g., `repeatSentence_1_10.json`)
/// 2. Kids games: `gameType_batch_N.json` (e.g., `alphabet_batch_1.json`)
///    → Each batch = 10 levels, so batch 20 = 200 levels.
import 'dart:io';

void main() {
  final curriculumDir = Directory('assets/curriculum');
  if (!curriculumDir.existsSync()) {
    print('ERROR: assets/curriculum/ directory not found.');
    print('Run this script from the project root.');
    exit(1);
  }

  // Pattern 1 (main games): gameType_startLevel_endLevel.json
  final mainPattern = RegExp(r'^(.+?)_(\d+)_(\d+)\.json$');

  // Pattern 2 (kids games): gameType_batch_N.json
  final kidsPattern = RegExp(r'^(.+?)_batch_(\d+)\.json$');

  // Map<gameType, maxLevel>
  final Map<String, int> levelCounts = {};

  // Track kids games separately for the manifest comments
  final Set<String> kidsGames = {};

  for (final dir in curriculumDir.listSync(recursive: true)) {
    if (dir is! File) continue;
    final name = dir.uri.pathSegments.last;
    final pathStr = dir.path.replaceAll('\\', '/');

    // --- Main game pattern ---
    final mainMatch = mainPattern.firstMatch(name);
    if (mainMatch != null) {
      final gameType = mainMatch.group(1)!;

      // Skip daily_words, as it's a special feature not a standard game
      if (gameType == 'daily_words') continue;

      final endLevel = int.parse(mainMatch.group(3)!);

      final current = levelCounts[gameType] ?? 0;
      if (endLevel > current) {
        levelCounts[gameType] = endLevel;
      }
      continue;
    }

    // --- Kids batch pattern ---
    final kidsMatch = kidsPattern.firstMatch(name);
    if (kidsMatch != null) {
      final gameType = kidsMatch.group(1)!;
      final batchNum = int.parse(kidsMatch.group(2)!);
      final maxLevel = batchNum * 10; // Each batch = 10 levels

      kidsGames.add(gameType);

      // Prefix with 'kids_' to namespace kids games in the manifest
      // unless the path doesn't contain /kids/ (unlikely but safe)
      final isKids = pathStr.contains('/kids/');
      final key = isKids ? 'kids_$gameType' : gameType;

      final current = levelCounts[key] ?? 0;
      if (maxLevel > current) {
        levelCounts[key] = maxLevel;
      }
      continue;
    }
  }

  // Sort alphabetically for stable diffs
  final sortedEntries = levelCounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  // Separate main games and kids games for documentation
  final mainGames = sortedEntries
      .where((e) => !e.key.startsWith('kids_'))
      .toList();
  final kidsEntries = sortedEntries
      .where((e) => e.key.startsWith('kids_'))
      .toList();

  // Generate the Dart file
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED FILE — DO NOT EDIT');
  buffer.writeln('// Run: dart run scripts/generate_curriculum_manifest.dart');
  buffer.writeln('//');
  buffer.writeln('// Generated: ${DateTime.now().toIso8601String()}');
  buffer.writeln(
    '// Total game types: ${sortedEntries.length} (${mainGames.length} main + ${kidsEntries.length} kids)',
  );
  buffer.writeln();
  buffer.writeln("import 'package:flutter/foundation.dart';");
  buffer.writeln();
  buffer.writeln(
    '/// Build-time generated manifest of curriculum level counts.',
  );
  buffer.writeln('///');
  buffer.writeln(
    '/// Each entry maps a game type to its total number of available levels,',
  );
  buffer.writeln(
    '/// derived from the highest batch file found in `assets/curriculum/`.',
  );
  buffer.writeln('///');
  buffer.writeln(
    '/// **Main games** use their gameType as-is (e.g., `repeatSentence`).',
  );
  buffer.writeln(
    '/// **Kids games** are prefixed with `kids_` (e.g., `kids_alphabet`).',
  );
  buffer.writeln('///');
  buffer.writeln(
    '/// This eliminates runtime asset manifest scanning entirely.',
  );
  buffer.writeln('@immutable');
  buffer.writeln('abstract class CurriculumManifest {');
  buffer.writeln('  const CurriculumManifest._();');
  buffer.writeln();
  buffer.writeln(
    '  /// Default level count when a game type is not in the manifest.',
  );
  buffer.writeln(
    '  /// New games added after the last code-gen run will fall back to this.',
  );
  buffer.writeln('  static const int defaultLevelCount = 10;');
  buffer.writeln();

  // --- Main games map ---
  buffer.writeln('  /// Total number of levels for each registered game type.');
  buffer.writeln('  static const Map<String, int> levelCounts = {');
  buffer.writeln('    // ── Main Games (${mainGames.length}) ──');
  for (final entry in mainGames) {
    buffer.writeln("    '${entry.key}': ${entry.value},");
  }
  buffer.writeln();
  buffer.writeln('    // ── Kids Games (${kidsEntries.length}) ──');
  for (final entry in kidsEntries) {
    buffer.writeln("    '${entry.key}': ${entry.value},");
  }
  buffer.writeln('  };');
  buffer.writeln();

  // --- Kids-only convenience map ---
  buffer.writeln('  /// Kids game level counts (without the `kids_` prefix).');
  buffer.writeln(
    '  /// Use this when looking up kids games by their raw topic name.',
  );
  buffer.writeln('  static const Map<String, int> kidsLevelCounts = {');
  for (final entry in kidsEntries) {
    final rawName = entry.key.replaceFirst('kids_', '');
    buffer.writeln("    '$rawName': ${entry.value},");
  }
  buffer.writeln('  };');
  buffer.writeln();

  buffer.writeln(
    '  /// Returns the level count for [gameType], or [defaultLevelCount]',
  );
  buffer.writeln('  /// if the game type was not present at build time.');
  buffer.writeln('  static int getLevels(String gameType) =>');
  buffer.writeln('      levelCounts[gameType] ?? defaultLevelCount;');
  buffer.writeln();
  buffer.writeln(
    '  /// Returns the level count for a kids game by topic name.',
  );
  buffer.writeln(
    '  /// Accepts both `"alphabet"` and `"kids_alphabet"` forms.',
  );
  buffer.writeln('  static int getKidsLevels(String topic) =>');
  buffer.writeln(
    "      kidsLevelCounts[topic] ?? levelCounts['kids_\$topic'] ?? defaultLevelCount;",
  );
  buffer.writeln('}');

  // Write the output
  final outputPath = 'lib/core/data/constants/curriculum_manifest.dart';
  File(outputPath).writeAsStringSync(buffer.toString());
  print('✅ Generated $outputPath');
  print('   ${mainGames.length} main game types');
  print('   ${kidsEntries.length} kids game types');
  print('   ${sortedEntries.length} total entries');
}
