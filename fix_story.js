const fs = require('fs');

let f2 = 'lib/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';
let c2 = fs.readFileSync(f2, 'utf8');
c2 = c2.replace(/void _submitOrder\(EliteMasteryQuest quest\)/g, 'void _submitOrder(GameQuest quest)');
fs.writeFileSync(f2, c2);
