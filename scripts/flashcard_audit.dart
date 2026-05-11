import 'dart:convert';
import 'dart:io';

void main() async {
  final directory = Directory('assets/curriculum/vocabulary');
  final files = directory.listSync()
      .where((f) => f.path.contains('flashcards_') && f.path.endsWith('.json'))
      .toList();

  print('🔍 Auditing ${files.length} Flashcard files...');

  final Set<String> globalIds = {};
  final Set<String> words = {};
  int placeholders = 0;
  int realWords = 0;
  final List<String> errors = [];

  for (var file in files) {
    try {
      final content = File(file.path).readAsStringSync();
      final data = jsonDecode(content);
      final quests = data['quests'] as List;

      for (var quest in quests) {
        final id = quest['id'];
        final word = quest['word'];
        final interactionType = quest['interactionType'];

        bool isPlaceholder = word.toString().contains('Lexicon-') || word.toString().contains('TODO');
        if (isPlaceholder) {
          placeholders++;
        } else {
          realWords++;
        }

        // 1. Check ID Uniqueness
        if (globalIds.contains(id)) {
          errors.add('[${file.path}] Duplicate ID: $id');
        }
        globalIds.add(id);

        // 2. Check Word Uniqueness
        if (words.contains(word)) {
          errors.add('[${file.path}] Duplicate Word: $word');
        }
        words.add(word);

        // 3. Check Interaction Type
        if (interactionType != 'flip') {
          errors.add('[${file.path}] Wrong interactionType: $interactionType for quest $id');
        }

        // 4. Check Required Fields
        final requiredFields = ['word', 'definition', 'example'];
        for (var field in requiredFields) {
          if (quest[field] == null || quest[field].toString().isEmpty) {
            errors.add('[${file.path}] Missing/Empty field "$field" in quest $id');
          }
        }
      }
    } catch (e) {
      errors.add('[${file.path}] Critical Error: $e');
    }
  }

  print('\n--- Flashcard Audit Results ---');
  print('Total Quests: ${placeholders + realWords}');
  print('Real Words: $realWords');
  print('Placeholders: $placeholders');
  print('Unique Words: ${words.length}');
  print('Unique IDs: ${globalIds.length}');
  
  if (errors.isEmpty) {
    print('✅ SUCCESS: All flashcards are unique and properly formatted (ignoring placeholder status).');
  } else {
    print('❌ ERRORS FOUND (${errors.length}):');
    errors.forEach(print);
  }
}
