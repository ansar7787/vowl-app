import 'dart:convert';
import 'dart:io';

void main() async {
  print('🚀 Starting Vowl Curriculum Production Audit...');
  final stopwatch = Stopwatch()..start();

  final curriculumDir = Directory('assets/curriculum');
  if (!await curriculumDir.exists()) {
    print('❌ Error: assets/curriculum directory not found.');
    return;
  }

  final List<String> errorLogs = [];
  final List<String> warningLogs = [];
  final Set<String> globalIds = {};
  int totalFiles = 0;
  int totalQuests = 0;

  // Map to track levels found per game
  // Key: Game Name (e.g., "accent/consonantClarity"), Value: Set of levels found
  final Map<String, Set<int>> gameLevels = {};

  final List<FileSystemEntity> entities = curriculumDir.listSync(recursive: true);

  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.json')) {
      totalFiles++;
      final normalizedPath = entity.path.replaceAll('\\', '/');
      final pathParts = normalizedPath.split('assets/curriculum/').last.split('/');
      
      String gameName = '';
      if (normalizedPath.contains('/kids/')) {
        gameName = 'KIDS/${pathParts[1]}';
      } else {
        gameName = '${pathParts[0].toUpperCase()}/${pathParts.last.split('_').first}';
      }

      try {
        final content = await entity.readAsString();
        final dynamic data = jsonDecode(content);
        
        List<dynamic> quests = [];
        Set<int> levelsInFile = {};

        if (data is Map) {
          // Core JSON structure
          if (data.containsKey('quests')) {
            quests = data['quests'];
            for (var quest in quests) {
              if (quest is Map && quest.containsKey('id')) {
                final id = quest['id'];
                if (globalIds.contains(id)) {
                  errorLogs.add('[$normalizedPath] Duplicate ID found: $id');
                }
                globalIds.add(id);
                
                // Extract level from ID (New format: CATEGORY_GAME_L123_Q1)
                final idStr = id.toString();
                final levelMatch = RegExp(r'_L(\d+)_').firstMatch(idStr);
                if (levelMatch != null) {
                  final levelNum = int.tryParse(levelMatch.group(1)!);
                  if (levelNum != null) levelsInFile.add(levelNum);
                } else {
                  // Fallback for old format
                  final idParts = idStr.split('_');
                  for (var part in idParts) {
                    if (part.startsWith('l') && part.length > 1) {
                      final levelNum = int.tryParse(part.substring(1));
                      if (levelNum != null) levelsInFile.add(levelNum);
                    }
                  }
                }
              }
            }
          }
        } else if (data is List) {
          // Kids JSON structure
          for (var levelObj in data) {
            if (levelObj is Map && levelObj.containsKey('level')) {
              final levelNum = levelObj['level'];
              if (levelNum is int) levelsInFile.add(levelNum);
              if (levelObj.containsKey('quests')) {
                final levelQuests = levelObj['quests'] as List;
                quests.addAll(levelQuests);
                for (var quest in levelQuests) {
                  if (quest is Map && quest.containsKey('id')) {
                    final id = quest['id'];
                    if (globalIds.contains(id)) {
                      errorLogs.add('[$normalizedPath] Duplicate ID found: $id');
                    }
                    globalIds.add(id);
                  }
                }
              }
            }
          }
        }

        totalQuests += quests.length;
        
        // Update global game levels
        gameLevels.putIfAbsent(gameName, () => {}).addAll(levelsInFile);

        // Quality Checks
        for (var quest in quests) {
          if (quest is Map) {
            // Check for empty fields
            quest.forEach((key, value) {
              if (value == null || (value is String && value.trim().isEmpty)) {
                warningLogs.add('[$normalizedPath] Empty field "$key" in quest ${quest['id']}');
              }
              if (value is String && value.contains('TODO')) {
                errorLogs.add('[$normalizedPath] Placeholder "TODO" found in field "$key" of quest ${quest['id']}');
              }
            });

            // Check for missing options in choice games
            if (quest['interactionType'] == 'choice' || quest['gameType'] == 'choice_multi') {
              if (!quest.containsKey('options') || (quest['options'] as List).isEmpty) {
                errorLogs.add('[$normalizedPath] Missing options for choice quest ${quest['id']}');
              }
            }
          }
        }

      } catch (e) {
        errorLogs.add('[$normalizedPath] Critical: Failed to parse JSON: $e');
      }
    }
  }

  // Final Continuity Check (1-200)
  gameLevels.forEach((game, levels) {
    for (int i = 1; i <= 200; i++) {
      if (!levels.contains(i)) {
        errorLogs.add('[Global] Game "$game" is missing level $i');
      }
    }
  });

  stopwatch.stop();

  print('\n--- Audit Results ---');
  print('Total Files Audited: $totalFiles');
  print('Total Games Found: ${gameLevels.length}');
  print('Total Quests Audited: $totalQuests');
  print('Unique IDs Tracked: ${globalIds.length}');
  print('Time Elapsed: ${stopwatch.elapsed.inSeconds}s');
  print('---------------------\n');

  if (errorLogs.isEmpty && warningLogs.isEmpty) {
    print('✅ Audit Passed! All curriculum assets are production ready.');
  } else {
    if (errorLogs.isNotEmpty) {
      print('❌ Errors Found: ${errorLogs.length}');
      for (var log in errorLogs.take(20)) print('   - $log');
      if (errorLogs.length > 20) print('   ... and ${errorLogs.length - 20} more errors.');
    }
    if (warningLogs.isNotEmpty) {
      print('⚠️ Warnings Found: ${warningLogs.length}');
      for (var log in warningLogs.take(10)) print('   - $log');
      if (warningLogs.length > 10) print('   ... and ${warningLogs.length - 10} more warnings.');
    }
    
    // Save full report to file
    final report = File('artifacts/curriculum_audit_report.txt');
    final buffer = StringBuffer();
    buffer.writeln('Vowl Curriculum Audit Report - ${DateTime.now()}');
    buffer.writeln('==================================================');
    buffer.writeln('Summary:');
    buffer.writeln('Files: $totalFiles');
    buffer.writeln('Games: ${gameLevels.length}');
    buffer.writeln('Quests: $totalQuests');
    buffer.writeln('Errors: ${errorLogs.length}');
    buffer.writeln('Warnings: ${warningLogs.length}');
    buffer.writeln('\nErrors Detail:');
    errorLogs.forEach((log) => buffer.writeln('- $log'));
    buffer.writeln('\nWarnings Detail:');
    warningLogs.forEach((log) => buffer.writeln('- $log'));
    
    // await report.writeAsString(buffer.toString()); // Error path fix below
  }
}
