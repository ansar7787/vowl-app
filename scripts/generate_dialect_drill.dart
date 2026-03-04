import 'dart:convert';
import 'dart:io';

// Core dictionary of British vs American pronunciation differences.
final List<Map<String, String>> dialectPool = [
  {"word": "Schedule", "br": "SHED-yool", "am": "SKED-yool"},
  {"word": "Tomato", "br": "tuh-MAH-toh", "am": "tuh-MAY-toh"},
  {"word": "Garage", "br": "GARR-ij", "am": "guh-RAHZH"},
  {"word": "Either", "br": "EYE-ther", "am": "EE-ther"},
  {"word": "Neither", "br": "NY-ther", "am": "NEE-ther"},
  {"word": "Aluminum", "br": "al-yoo-MIN-ee-um", "am": "uh-LOO-min-um"},
  {"word": "Vase", "br": "VAHZ", "am": "VAYS"},
  {"word": "Route", "br": "ROOT", "am": "ROWT"},
  {"word": "Privacy", "br": "PRIV-uh-see", "am": "PRY-vuh-see"},
  {"word": "Mobile", "br": "MOH-byle", "am": "MOH-b'l"},
  {"word": "Advertisement", "br": "ad-VER-tiss-ment", "am": "ad-ver-TYZE-ment"},
  {"word": "Hostile", "br": "HOS-tyle", "am": "HOS-t'l"},
  {"word": "Agile", "br": "AJ-yle", "am": "AJ-il"},
  {"word": "Leisure", "br": "LEZH-er", "am": "LEE-zher"},
  {"word": "Direct", "br": "dy-REKT", "am": "duh-REKT"},
  {"word": "Herb", "br": "HERB", "am": "ERB"},
  {"word": "Aunt", "br": "AHNT", "am": "ANT"},
  {"word": "Data", "br": "DAH-tuh", "am": "DAY-tuh"},
  {"word": "Vitamin", "br": "VIT-uh-min", "am": "VY-tuh-min"},
  {"word": "Laboratory", "br": "luh-BOR-uh-tree", "am": "LAB-ruh-tor-ee"},
  {"word": "Missile", "br": "MISS-yle", "am": "MISS-il"},
  {"word": "Zebra", "br": "ZEB-ruh", "am": "ZEE-bruh"},
  {"word": "Patriot", "br": "PAT-ree-ut", "am": "PAY-tree-ut"},
  {"word": "Yogurt", "br": "YOG-ert", "am": "YOH-gert"},
  {"word": "Bouquet", "br": "Boo-KAY", "am": "Boh-KAY"},
  {"word": "Docile", "br": "DOH-syle", "am": "DAH-s'l"},
  {"word": "Futile", "br": "FYOO-tyle", "am": "FYOO-t'l"},
  {"word": "Fragile", "br": "FRAJ-yle", "am": "FRAJ-il"},
  {"word": "Status", "br": "STAY-tus", "am": "STAT-us"},
  {"word": "Epoch", "br": "EE-pok", "am": "EP-uck"},
  {"word": "Glacier", "br": "GLASS-ee-er", "am": "GLAY-sher"},
  {"word": "Niche", "br": "NEESH", "am": "NITCH"},
  {"word": "Beta", "br": "BEE-tuh", "am": "BAY-tuh"},
  {"word": "Multi", "br": "MUL-tee", "am": "MUL-ty"},
  {
    "word": "Simultaneous",
    "br": "sim-ul-TAY-nee-us",
    "am": "sy-mul-TAY-nee-us",
  },
  {"word": "Dynasty", "br": "DIN-us-tee", "am": "DY-nus-tee"},
  {"word": "Foyer", "br": "FOY-ay", "am": "FOY-er"},
  {"word": "Cantaloupe", "br": "CAN-tuh-loop", "am": "CAN-tuh-lohp"},
  {"word": "Lieutenant", "br": "lef-TEN-unt", "am": "loo-TEN-unt"},
  {"word": "Premier", "br": "PREM-ee-er", "am": "pruh-MEER"},
  {"word": "Pasta", "br": "PASS-tuh", "am": "PAH-stuh"},
  {"word": "Process", "br": "PROH-sess", "am": "PRAH-sess"},
  {"word": "Semi", "br": "SEM-ee", "am": "SEM-eye"},
];

void main() async {
  final outDir = Directory('assets/curriculum/accent');
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }

  // Remove old files
  for (var entity in outDir.listSync()) {
    if (entity is File && entity.path.contains('dialectDrill_')) {
      await entity.delete();
    }
  }

  int globalQuestionIndex = 0;
  final totalLevels = 200;
  final numFiles = 20;
  final levelsPerFile = totalLevels ~/ numFiles;

  for (int fileIndex = 0; fileIndex < numFiles; fileIndex++) {
    int startLevel = (fileIndex * levelsPerFile) + 1;
    int endLevel = startLevel + levelsPerFile - 1;
    String filename = 'dialectDrill_${startLevel}_$endLevel.json';
    List<Map<String, dynamic>> quests = [];

    // 10 levels per file, 3 quests per level = 30 quests per file
    for (int l = startLevel; l <= endLevel; l++) {
      for (int q = 1; q <= 3; q++) {
        // Use deterministic rotation
        final poolItem = dialectPool[globalQuestionIndex % dialectPool.length];

        // Randomly pick if we're asking for British or American
        final bool askForBritish = (globalQuestionIndex % 2 == 0);

        // Randomly assign options to 0 or 1 slot
        final bool brIsFirst = ((globalQuestionIndex ~/ 2) % 2 == 0);

        final brOpt = '${poolItem['br']} (British)';
        final amOpt = '${poolItem['am']} (American)';

        final List<String> options = brIsFirst
            ? [brOpt, amOpt]
            : [amOpt, brOpt];

        final String instruction = askForBritish
            ? "Which pronunciation is British?"
            : "Which pronunciation is American?";

        final int correctIndex = askForBritish
            ? (brIsFirst ? 0 : 1)
            : (brIsFirst ? 1 : 0);

        final String hint = askForBritish
            ? "Listen closely to the vowel sounds and specific consonant hits typical in UK English."
            : "Listen for the relaxed vowels or flapped 't' sounds typical in US English.";

        quests.add({
          "id": "dialectDrill_l${l}_q${q}",
          "instruction": instruction,
          "difficulty": ((l - 1) ~/ 40) + 1, // 1 to 5 scaling
          "subtype": "dialectDrill",
          "interactionType": "choice",
          "word": poolItem['word'],
          "options": options,
          "correctAnswerIndex": correctIndex,
          "hint": hint,
          "xpReward": 5,
          "coinReward": 10,
        });

        globalQuestionIndex++;
      }
    }

    final outPath = '${outDir.path}/$filename';
    final jsonData = {
      "gameType": "dialectDrill",
      "batchIndex": fileIndex + 1,
      "levels": "$startLevel-$endLevel",
      "quests": quests,
    };

    final file = File(outPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
    print('Generated $filename with ${quests.length} questions.');
  }

  print(
    'Successfully generated 20 Dialect Drill JSON files (600 unique items total).',
  );
}
