const fs = require('fs');
let p2 = 'lib/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart';
let c2 = fs.readFileSync(p2, 'utf8');
c2 = c2.replace(/_submitVerbalEvaluation\(\s*false,\s*\)/g, '_submitVerbalEvaluation(false, quest)');
fs.writeFileSync(p2, c2);
