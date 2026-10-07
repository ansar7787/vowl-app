const fs = require('fs');
let f3 = 'lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
let c3 = fs.readFileSync(f3, 'utf8');
c3 = c3.replace(/_onFire\(i, correctIndex, hasSecondStage\);/g, '_onFire(i, correctIndex, hasSecondStage, _lastQuest!);');
fs.writeFileSync(f3, c3);
