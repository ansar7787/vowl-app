import 'dart:convert';
import 'dart:io';

// Pool of fast speech reductions and their slow forms
final List<Map<String, String>> speechPool = [
  {"textToSpeak": "What are you going to do?", "fastForm": "Whatcha gonna do?"},
  {"textToSpeak": "I want to go.", "fastForm": "I wanna go."},
  {"textToSpeak": "Let me see.", "fastForm": "Lemme see."},
  {"textToSpeak": "I don't know.", "fastForm": "I dunno."},
  {
    "textToSpeak": "You should have done it.",
    "fastForm": "You shoulda done it.",
  },
  {"textToSpeak": "Could you help me?", "fastForm": "Couldja help me?"},
  {"textToSpeak": "Give me that.", "fastForm": "Gimme that."},
  {"textToSpeak": "I got to go.", "fastForm": "I gotta go."},
  {"textToSpeak": "Would you like some?", "fastForm": "Wouldja like some?"},
  {"textToSpeak": "Tell them I said hi.", "fastForm": "Tell 'em I said hi."},
  {"textToSpeak": "Sort of.", "fastForm": "Sorta."},
  {"textToSpeak": "Kind of.", "fastForm": "Kinda."},
  {"textToSpeak": "Lot of people.", "fastForm": "Lotta people."},
  {"textToSpeak": "Out of here.", "fastForm": "Outta here."},
  {"textToSpeak": "What are you doing?", "fastForm": "Whatcha doin'?"},
  {"textToSpeak": "Did you see that?", "fastForm": "Didja see that?"},
  {"textToSpeak": "I have got to leave.", "fastForm": "I've gotta leave."},
  {"textToSpeak": "Don't you know?", "fastForm": "Doncha know?"},
  {"textToSpeak": "Might have been.", "fastForm": "Mighta been."},
  {"textToSpeak": "Must have seen it.", "fastForm": "Musta seen it."},
  {"textToSpeak": "Going to happen.", "fastForm": "Gonna happen."},
  {"textToSpeak": "Want to eat?", "fastForm": "Wanna eat?"},
  {"textToSpeak": "Let me know.", "fastForm": "Lemme know."},
  {"textToSpeak": "Give me a second.", "fastForm": "Gimme a sec."},
  {"textToSpeak": "Trying to find it.", "fastForm": "Tryna find it."},
  {"textToSpeak": "Front of the line.", "fastForm": "Fronta the line."},
  {"textToSpeak": "Cup of coffee.", "fastForm": "Cuppa coffee."},
  {"textToSpeak": "I am going to.", "fastForm": "I'm'a."},
  {"textToSpeak": "Because I said so.", "fastForm": "Cuz I said so."},
  {"textToSpeak": "Probably not.", "fastForm": "Prolly not."},
  {"textToSpeak": "Come on.", "fastForm": "C'mon."},
  {"textToSpeak": "Nothing to do.", "fastForm": "Nothin' to do."},
  {"textToSpeak": "Need to go.", "fastForm": "Needa go."},
  {"textToSpeak": "Ought to be.", "fastForm": "Oughta be."},
  {"textToSpeak": "Used to say.", "fastForm": "Useta say."},
];

void main() async {
  final outDir = Directory('assets/curriculum/accent');
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }

  int globalQuestionIndex = 0;
  final totalLevels = 200;
  final numFiles = 20;
  final levelsPerFile = totalLevels ~/ numFiles;

  for (int fileIndex = 0; fileIndex < numFiles; fileIndex++) {
    int startLevel = (fileIndex * levelsPerFile) + 1;
    int endLevel = startLevel + levelsPerFile - 1;
    String filename = 'speedVariance_${startLevel}_$endLevel.json';
    List<Map<String, dynamic>> quests = [];

    // 10 levels per file, 3 quests per level = 30 quests per file
    for (int l = startLevel; l <= endLevel; l++) {
      for (int q = 1; q <= 3; q++) {
        // Use a deterministic rotation through the pool
        final poolItem = speechPool[globalQuestionIndex % speechPool.length];

        quests.add({
          "id": "speedVariance_l${l}_q${q}",
          "instruction": "Identify the speaking speed.",
          "difficulty": ((l - 1) ~/ 40) + 1, // 1 to 5 scaling
          "subtype": "speedVariance",
          "interactionType": "choice",
          "textToSpeak": poolItem['fastForm'],
          "options": ["Fast casual speech", "Careful slow speech"],
          "correctAnswerIndex":
              0, // fast casual is always 0 based on textToSpeak
          "slowForm": poolItem['textToSpeak'],
          "hint": "Words blend together (reduction) in fast speech.",
          "xpReward": 5,
          "coinReward": 10,
        });

        globalQuestionIndex++;
      }
    }

    final outPath = '${outDir.path}/$filename';
    final jsonData = {
      "gameType": "speedVariance",
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
    'Successfully generated 20 speed variance JSON files (600 unique items total).',
  );
}
