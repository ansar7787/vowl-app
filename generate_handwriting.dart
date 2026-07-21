import 'dart:convert';
import 'dart:io';

void main() {
  List<String> coreWords = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'CAT', 'DOG', 'BAT', 'HAT', 'RAT', 'MAT', 'FAT', 'PAT', 'SAT', 'VAT',
    'ANT', 'BUG', 'BEE', 'FLY', 'PIG', 'COW', 'HEN', 'FOX', 'OWL', 'BIRD',
    'SUN', 'MOON', 'STAR', 'SKY', 'SEA', 'CAR', 'BUS', 'VAN', 'JET', 'BOX',
    'CUP', 'MUG', 'POT', 'PAN', 'BED', 'COT', 'MAP', 'BAG', 'TAG', 'RAG',
    'LEG', 'ARM', 'LIP', 'EYE', 'EAR', 'TOE', 'BOY', 'GIRL', 'MAN', 'PEN',
    'INK', 'JOY', 'FUN', 'RUN', 'JUMP', 'HOP', 'SKIP', 'PLAY', 'WIN', 'TOP',
    'BALL', 'DOLL', 'KITE', 'BIKE', 'TOYS', 'GAME', 'WALK', 'SWIM', 'READ', 
    'BOOK', 'PAGE', 'WORD', 'FISH', 'FROG', 'TOAD', 'BEAR', 'LION', 'WOLF', 
    'DEER', 'DUCK', 'SWAN', 'CROW', 'DOVE', 'TREE', 'LEAF', 'ROOT', 'SEED', 
    'ROSE', 'LILY', 'FERN', 'WEED', 'ROCK', 'DIRT', 'SAND', 'DUST', 'WIND', 
    'RAIN', 'SNOW', 'HAIL', 'COLD', 'WARM', 'HOT', 'COOL', 'TIME', 'HOUR',
    'APPLE', 'GRAPE', 'MELON', 'PEACH', 'PLUM', 'PEAR', 'LEMON', 'MANGO', 
    'WATER', 'OCEAN', 'RIVER', 'PLANT', 'GRASS', 'CLOUD', 'EARTH', 'WORLD',
    'SMILE', 'HAPPY', 'LAUGH', 'DANCE', 'MUSIC', 'SONG', 'PIANO', 'DRUM',
  ];

  // Extend list to 600
  List<String> words = [];
  while (words.length < 600) {
    words.addAll(coreWords);
  }
  words = words.sublist(0, 600);

  final dir = Directory('assets/curriculum/kids/handwriting');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  for (int batch = 1; batch <= 20; batch++) {
    final List<Map<String, dynamic>> levels = [];
    for (int levelInBatch = 1; levelInBatch <= 10; levelInBatch++) {
      final int level = (batch - 1) * 10 + levelInBatch;
      final List<Map<String, dynamic>> quests = [];
      for (int q = 1; q <= 3; q++) {
        final int index = ((level - 1) * 3 + (q - 1));
        final String word = words[index];
        quests.add({
          "id": "KIDS_HANDWRITING_L${level}_Q$q",
          "gameType": "handwriting",
          "level": level,
          "instruction": "Draw the word: $word!",
          "question": word,
          "correctAnswer": word,
          "options": [word, "wrong1", "wrong2"],
          "hint": "Try your best to write '$word' clearly inside the box.",
          "emoji": "✍️",
          "explanation": "Great job writing '$word'!"
        });
      }
      levels.add({
        "level": level,
        "quests": quests
      });
    }
    
    final file = File('${dir.path}/handwriting_batch_$batch.json');
    file.writeAsStringSync(jsonEncode(levels));
  }
  print('Generated 20 JSON batches for handwriting curriculum in ${dir.path}');
}
