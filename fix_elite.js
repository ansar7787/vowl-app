const fs = require('fs');

let f1 = 'lib/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart';
let c1 = fs.readFileSync(f1, 'utf8');
c1 = "import '../../../domain/entities/elite_mastery_quest.dart';\n" + c1;
c1 = c1.replace(/void _submit\(GameQuest quest\)/, 'void _submit(EliteMasteryQuest quest)');
fs.writeFileSync(f1, c1);

let f2 = 'lib/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';
let c2 = fs.readFileSync(f2, 'utf8');
c2 = "import '../../../domain/entities/elite_mastery_quest.dart';\n" + c2;
c2 = c2.replace(/void _submitOrder\(GameQuest quest\)/, 'void _submitOrder(EliteMasteryQuest quest)');
c2 = c2.replace(/void _submitVerbalEvaluation\(bool nailedIt, GameQuest quest\)/, 'void _submitVerbalEvaluation(bool nailedIt, EliteMasteryQuest quest)');
fs.writeFileSync(f2, c2);

