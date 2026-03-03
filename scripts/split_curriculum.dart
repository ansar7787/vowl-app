import 'dart:convert';
import 'dart:io';

void main() async {
  final Directory curriculumDir = Directory('assets/curriculum');
  if (!await curriculumDir.exists()) {
    stdout.writeln('Curriculum directory not found!');
    return;
  }

  final List<String> categories = [
    'accent',
    'grammar',
    'listening',
    'reading',
    'roleplay',
    'speaking',
    'vocabulary',
    'writing',
  ];

  for (final category in categories) {
    final categoryDir = Directory('${curriculumDir.path}/$category');
    if (!await categoryDir.exists()) continue;

    final List<FileSystemEntity> files = await categoryDir.list().toList();
    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        await splitFile(file, category);
      }
    }
  }
}

Future<void> splitFile(File file, String category) async {
  final String content = await file.readAsString();
  final Map<String, dynamic> data = jsonDecode(content);
  final String gameType = data['gameType'] ?? '';
  final List<dynamic> quests = data['quests'] ?? [];

  if (gameType.isEmpty || quests.isEmpty) return;

  stdout.writeln('Splitting $gameType...');

  // Group quests by batch (10 levels per batch)
  final Map<int, List<dynamic>> batches = {};

  for (final quest in quests) {
    final String id = quest['id'] as String? ?? '';
    final RegExp regExp = RegExp(r'_L(\d{3})_');
    final match = regExp.firstMatch(id);

    if (match != null) {
      final int level = int.parse(match.group(1)!);
      final int batchIndex = ((level - 1) ~/ 10) + 1;

      batches.putIfAbsent(batchIndex, () => []).add(quest);
    }
  }

  // Save each batch
  for (final entry in batches.entries) {
    final int batchIndex = entry.key;
    final List<dynamic> batchQuests = entry.value;

    final int startLevel = (batchIndex - 1) * 10 + 1;
    final int endLevel = batchIndex * 10;

    final fileName = '${gameType}_${startLevel}_$endLevel.json';
    final File batchFile = File('assets/curriculum/$category/$fileName');

    final Map<String, dynamic> batchData = {
      'gameType': gameType,
      'batchIndex': batchIndex,
      'levels': '$startLevel-$endLevel',
      'quests': batchQuests,
    };

    await batchFile.writeAsString(jsonEncode(batchData));
    // print('  Created $fileName');
  }
}
