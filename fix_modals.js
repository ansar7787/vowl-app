const fs = require('fs');
let file = 'lib/features/grammar/modals_selection/presentation/pages/modals_selection_screen.dart';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/quest\.options\[_selectedIndex\.value\]/g, 'quest.options![_selectedIndex.value]');
content = content.replace(/_selectedIndex\.value < \(\(quest\.options\?\.length \?\? 0\) \?\? 0\)/g, '_selectedIndex.value! < (quest.options?.length ?? 0)');
content = content.replace(/_selectedIndex\.value < quest\.options\.length/g, '_selectedIndex.value! < quest.options!.length');
content = content.replace(/_selectedIndex\.value != null/g, '_selectedIndex.value != null');
fs.writeFileSync(file, content);
