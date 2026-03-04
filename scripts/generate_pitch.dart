import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final curriculumDir = Directory(
    'c:/Users/asus/Documents/App Projects/voxai_quest/assets/curriculum/accent',
  );

  if (!curriculumDir.existsSync()) {
    print('Directory does not exist!');
    exit(1);
  }

  // Sentence pools mapping pitch patterns to arrays of sentences
  final pools = {
    'Rising ↗': [
      'Are you coming?',
      'Is it raining?',
      'Do you like coffee?',
      'Can you help me?',
      'Should we leave now?',
      'Will it work?',
      'Did you see that?',
      'Are they ready?',
      'Have you finished?',
      'Is this yours?',
      'May I come in?',
      'Would you mind?',
      'Could she do it?',
      'Does he know?',
      'Are we there yet?',
      'Has it started?',
      'Do they understand?',
      'Is she asleep?',
      'Can he drive?',
      'Will you join us?',
      'Are you sure?',
      'Is that true?',
      'Do we have time?',
      'Can they see us?',
      'Should I wait?',
      'Will she be late?',
      'Did he call?',
      'Are you okay?',
      'Have we met?',
      'Is it possible?',
    ],
    'Falling ↘': [
      'I finished the report.',
      'She is coming home.',
      'They won the game.',
      'It is raining outside.',
      'He bought a new car.',
      'We are going to sleep.',
      'The book is on the table.',
      'I like apples.',
      'She sings beautifully.',
      'He runs fast.',
      'They walked to the park.',
      'I need some rest.',
      'The sky is blue.',
      'She read a novel.',
      'He wrote a letter.',
      'We ate dinner.',
      'The dog is barking.',
      'I saw a movie.',
      'She opened the window.',
      'He closed the door.',
      'They painted the wall.',
      'I found my keys.',
      'She lost her phone.',
      'He fixed the bike.',
      'We watched TV.',
      'The sun is shining.',
      'I drank water.',
      'She cooked lunch.',
      'He drove carefully.',
      'They left early.',
    ],
    'Flat →': [
      'I don\'t know.',
      'Whatever you say.',
      'It doesn\'t matter.',
      'I suppose so.',
      'Maybe later.',
      'If you want.',
      'I guess it\'s fine.',
      'We will see.',
      'Just leave it there.',
      'Nothing special.',
      'As you wish.',
      'It is what it is.',
      'Let it be.',
      'Who cares.',
      'Same old story.',
      'Just another day.',
      'Not really sure.',
      'Either way is fine.',
      'Takes time.',
      'In a minute.',
      'Just around the corner.',
      'Somewhere out there.',
      'Now and then.',
      'Off and on.',
      'Back and forth.',
      'Here and there.',
      'More or less.',
      'So so.',
      'Kind of.',
      'Sort of.',
    ],
    'Rise-fall ↗↘': [
      'That was amazing!',
      'What a surprise!',
      'I can\'t believe it!',
      'How wonderful!',
      'That is absolutely incredible!',
      'You did a great job!',
      'What a fantastic idea!',
      'I am so happy for you!',
      'That hurts!',
      'Watch out!',
      'Stop doing that!',
      'How dare you!',
      'What a beautiful day!',
      'This is the best!',
      'I am completely shocked!',
      'That is so funny!',
      'You are kidding me!',
      'What a relief!',
      'That is a disaster!',
      'I am so excited!',
      'How terrifying!',
      'That is brilliant!',
      'What a mess!',
      'I am incredibly tired!',
      'That is outrageous!',
      'What a tragedy!',
      'I am so proud!',
      'That is fabulous!',
      'How interesting!',
      'That is unbelievable!',
    ],
  };

  final hints = {
    'Rising ↗': 'Questions usually end with a rising pitch.',
    'Falling ↘': 'Statements usually end with a falling pitch.',
    'Flat →': 'Neutral or uncertain phrases often have a flat pitch.',
    'Rise-fall ↗↘': 'Excitement or strong emotion often rises then falls.',
  };

  final options = ['Rising ↗', 'Falling ↘', 'Flat →', 'Rise-fall ↗↘'];
  final random = Random();

  String getRandomItem(List<String> arr) {
    return arr[random.nextInt(arr.length)];
  }

  // Clean old files
  for (var entity in curriculumDir.listSync()) {
    if (entity is File && entity.path.contains('pitchPatternMatch_')) {
      entity.deleteSync();
    }
  }

  final totalLevels = 200;
  final numFiles = 20;
  final levelsPerFile = totalLevels ~/ numFiles;

  for (int fileIndex = 0; fileIndex < numFiles; fileIndex++) {
    int startLevel = (fileIndex * levelsPerFile) + 1;
    int endLevel = startLevel + levelsPerFile - 1;
    String filename = 'pitchPatternMatch_${startLevel}_$endLevel.json';
    List<Map<String, dynamic>> quests = [];

    for (int l = startLevel; l <= endLevel; l++) {
      for (int q = 1; q <= 3; q++) {
        final correctIndex = random.nextInt(options.length);
        final correctPatternLabel = options[correctIndex];

        final sentence = getRandomItem(pools[correctPatternLabel]!);
        final hint = hints[correctPatternLabel];
        final diff = max(1, min(10, ((l - 1) ~/ 40) + 1));

        final quest = {
          "id": "pitchPatternMatch_l${l}_q$q",
          "instruction": "Match the pitch pattern.",
          "difficulty": diff,
          "subtype": "pitchPatternMatch",
          "interactionType": "choice",
          "textToSpeak": sentence,
          "pitchPattern": correctPatternLabel,
          "options": options,
          "correctAnswerIndex": correctIndex,
          "hint": hint,
          "xpReward": 5,
          "coinReward": 10,
        };
        quests.add(quest);
      }
    }

    final data = {
      "gameType": "pitchPatternMatch",
      "batchIndex": fileIndex + 1,
      "levels": "$startLevel-$endLevel",
      "quests": quests,
    };

    final file = File('${curriculumDir.path}/$filename');
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    print('Generated $filename with ${quests.length} questions.');
  }

  print('Successfully generated 20 JSON files (600 items total).');
}
