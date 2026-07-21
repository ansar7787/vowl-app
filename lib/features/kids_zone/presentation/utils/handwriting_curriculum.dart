class HandwritingCurriculum {
  /// Core handwriting words including alphabet, numbers, and basic sight words.
  static const List<String> coreWords = [
    // Alphabet
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    // Numbers
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    // Basic 3-Letter Words
    'CAT', 'DOG', 'BAT', 'HAT', 'RAT', 'MAT', 'FAT', 'PAT', 'SAT', 'VAT',
    'ANT', 'BUG', 'BEE', 'FLY', 'PIG', 'COW', 'HEN', 'FOX', 'OWL', 'BIRD',
    'SUN', 'MOON', 'STAR', 'SKY', 'SEA', 'CAR', 'BUS', 'VAN', 'JET', 'BOX',
    'CUP', 'MUG', 'POT', 'PAN', 'BED', 'COT', 'MAP', 'BAG', 'TAG', 'RAG',
    'LEG', 'ARM', 'LIP', 'EYE', 'EAR', 'TOE', 'BOY', 'GIRL', 'MAN', 'PEN',
    'INK', 'JOY', 'FUN', 'RUN', 'JUMP', 'HOP', 'SKIP', 'PLAY', 'WIN', 'TOP',
    // Basic 4-Letter Words
    'BALL', 'DOLL', 'KITE', 'BIKE', 'TOYS', 'GAME', 'WALK', 'SWIM', 'READ', 
    'BOOK', 'PAGE', 'WORD', 'FISH', 'FROG', 'TOAD', 'BEAR', 'LION', 'WOLF', 
    'DEER', 'DUCK', 'SWAN', 'CROW', 'DOVE', 'TREE', 'LEAF', 'ROOT', 'SEED', 
    'ROSE', 'LILY', 'FERN', 'WEED', 'ROCK', 'DIRT', 'SAND', 'DUST', 'WIND', 
    'RAIN', 'SNOW', 'HAIL', 'COLD', 'WARM', 'HOT', 'COOL', 'TIME', 'HOUR',
    // Basic 5-Letter Words
    'APPLE', 'GRAPE', 'MELON', 'PEACH', 'PLUM', 'PEAR', 'LEMON', 'MANGO', 
    'WATER', 'OCEAN', 'RIVER', 'PLANT', 'GRASS', 'CLOUD', 'EARTH', 'WORLD',
    'SMILE', 'HAPPY', 'LAUGH', 'DANCE', 'MUSIC', 'SONG', 'PIANO', 'DRUM',
  ];

  /// Returns exactly 3 words for a specific level.
  /// Loops safely if the level exceeds the core list size.
  static List<String> getWordsForLevel(int level) {
    // 3 words per level
    final startIndex = ((level - 1) * 3) % coreWords.length;
    return [
      coreWords[startIndex],
      coreWords[(startIndex + 1) % coreWords.length],
      coreWords[(startIndex + 2) % coreWords.length],
    ];
  }
}
