import 'dart:convert';
import 'dart:io';

void main() async {
  final curriculumDir = Directory('assets/curriculum');
  final entities = curriculumDir.listSync(recursive: true);
  final Map<String, String> gamePrefixes = {};
  final Map<String, List<String>> prefixToGames = {};

  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.json')) {
      final String relativePath = entity.path.split('assets\\curriculum\\').last;
      String gameName = '';
      if (relativePath.contains('kids')) {
        final parts = relativePath.split('\\');
        gameName = 'kids/${parts[1]}';
      } else {
        final filename = relativePath.split('\\').last;
        gameName = relativePath.split('\\').first + '/' + filename.split('_').first;
      }

      if (gamePrefixes.containsKey(gameName)) continue;

      try {
        final content = await entity.readAsString();
        final dynamic data = jsonDecode(content);
        String? firstId;

        if (data is Map && data.containsKey('quests')) {
          final quests = data['quests'] as List;
          if (quests.isNotEmpty) firstId = quests.first['id'];
        } else if (data is List && data.isNotEmpty) {
          final levelQuests = data.first['quests'] as List;
          if (levelQuests.isNotEmpty) firstId = levelQuests.first['id'];
        }

        if (firstId != null) {
          final prefix = firstId.split('_').first;
          gamePrefixes[gameName] = prefix;
          prefixToGames.putIfAbsent(prefix, () => []).add(gameName);
        }
      } catch (e) {}
    }
  }

  print('--- Prefix Analysis ---');
  prefixToGames.forEach((prefix, games) {
    if (games.length > 1) {
      print('❌ Collision on prefix "$prefix":');
      for (var game in games) print('   - $game');
    }
  });
}
