
import 'dart:io';
import 'dart:convert';

void main() async {
  final dir = Directory('assets/curriculum/vocabulary');
  final files = dir.listSync().where((f) => f.path.contains('flashcards_') && f.path.endsWith('.json'));

  for (var fileEntity in files) {
    final file = File(fileEntity.path);
    final content = await file.readAsString();
    final data = json.decode(content);

    if (data['quests'] != null) {
      for (var quest in data['quests']) {
        // 1. Update instruction
        quest['instruction'] = "Tap to Flip and Learn";

        // 2. Add hint if missing
        if (quest['hint'] == null) {
          String definition = quest['definition'] ?? "";
          if (definition.length > 20) {
            quest['hint'] = "Definition starts with: \"${definition.substring(0, 15)}...\"";
          } else {
            quest['hint'] = "Focus on its meaning: $definition";
          }
        }
      }
    }

    final encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
    print('Purified ${file.path}');
  }
}
