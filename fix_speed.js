const fs = require('fs');

let f1 = 'lib/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart';
let c1 = fs.readFileSync(f1, 'utf8');
c1 = c1.replace(/final correctWord =\s*\(\"\" : null\) \?\?\s*quest\.correctAnswer \?\?\s*'';/m, "final correctWord = quest.correctAnswer ?? '';");
fs.writeFileSync(f1, c1);
