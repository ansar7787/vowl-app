const fs = require('fs');
let f4 = 'lib/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart';
let c4 = fs.readFileSync(f4, 'utf8');
c4 = c4.replace(/_submitVerbalEvaluation\(true\)/g, '_submitVerbalEvaluation(true, _lastQuest!)');
c4 = c4.replace(/_submitVerbalEvaluation\(false\)/g, '_submitVerbalEvaluation(false, _lastQuest!)');
fs.writeFileSync(f4, c4);
