import 'dart:convert';
import 'dart:io';

void main() async {
  print('✨ Starting Global ID Purification (V3 - Filename Aware)...');
  final curriculumDir = Directory('assets/curriculum');
  if (!curriculumDir.existsSync()) return;

  final entities = curriculumDir.listSync(recursive: true);
  
  int totalFiles = 0;
  int totalRenamed = 0;

  final Map<String, String> categoryMap = {
    'accent': 'ACC',
    'grammar': 'GRM',
    'listening': 'LIS',
    'reading': 'RDG',
    'roleplay': 'RLP',
    'speaking': 'SPK',
    'vocabulary': 'VOC',
    'writing': 'WRT',
    'elite_mastery': 'ELT',
    'kids': 'KID',
    'calendar': 'CAL',
  };

  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.json')) {
      totalFiles++;
      
      final normalizedPath = entity.path.replaceAll('\\', '/');
      final pathParts = normalizedPath.split('assets/curriculum/').last.split('/');
      
      String categoryKey = pathParts.first;
      String category = categoryMap[categoryKey] ?? categoryKey.toUpperCase().substring(0, 3);
      
      String gameName = '';
      if (category == 'KID') {
        gameName = pathParts[1].toUpperCase();
      } else {
        final filename = pathParts.last;
        gameName = filename.split('_').first.toUpperCase();
      }

      // Extract base level from filename (e.g., game_111_120.json -> 111)
      int baseLevel = 0;
      final filename = pathParts.last;
      final rangeMatch = RegExp(r'_(\d+)_(\d+)\.json$').firstMatch(filename);
      if (rangeMatch != null) {
        baseLevel = int.parse(rangeMatch.group(1)!);
      }

      try {
        final content = await entity.readAsString();
        final dynamic data = jsonDecode(content);
        bool modified = false;

        void processQuests(List quests, [int? fixedLevel]) {
          // Track quest index per level
          Map<int, int> levelQuestCounter = {};
          
          for (var i = 0; i < quests.length; i++) {
            final quest = quests[i];
            if (quest is Map) {
              int currentLevel = fixedLevel ?? 0;
              
              if (fixedLevel == null) {
                // Try to determine level based on quest index and baseLevel
                // Assuming 3 quests per level in Core games
                currentLevel = baseLevel + (i ~/ 3);
              }

              levelQuestCounter[currentLevel] = (levelQuestCounter[currentLevel] ?? 0) + 1;
              final qIndex = levelQuestCounter[currentLevel];
              
              final newId = '${category}_${gameName}_L${currentLevel}_Q$qIndex';
              
              if (quest['id'] != newId) {
                quest['id'] = newId;
                modified = true;
                totalRenamed++;
              }
            }
          }
        }

        if (data is Map) {
          if (data.containsKey('quests')) {
            processQuests(data['quests'] as List);
          }
        } else if (data is List) {
          for (var levelObj in data) {
            if (levelObj is Map && levelObj.containsKey('level') && levelObj.containsKey('quests')) {
              processQuests(levelObj['quests'] as List, levelObj['level']);
            }
          }
        }

        if (modified) {
          final encoder = const JsonEncoder.withIndent('  ');
          await entity.writeAsString(encoder.convert(data));
        }

      } catch (e) {
        print('❌ Error processing ${entity.path}: $e');
      }
    }
  }

  print('\n✅ Purification V3 Complete!');
  print('Total Files Processed: $totalFiles');
  print('Total IDs Renamed: $totalRenamed');
}
