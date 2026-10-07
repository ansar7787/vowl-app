const fs = require('fs');
const file = 'lib/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
let content = fs.readFileSync(file, 'utf8');

// Fix submitWrongAnswer
content = content.replace(
  'void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {\n    submitSharedWrongAnswer',
  'void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {\n    if (isAnsweredNotifier.value) return;\n    submitSharedWrongAnswer'
);

// Fix submitCorrectAnswer
content = content.replace(
  'void submitCorrectAnswer() {\n    submitSharedCorrectAnswer',
  'void submitCorrectAnswer() {\n    if (isAnsweredNotifier.value) return;\n    submitSharedCorrectAnswer'
);

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed listening mixin guards.');
