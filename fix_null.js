const fs = require('fs');
function fixQuestNull(file) {
    let content = fs.readFileSync(file, 'utf8');
    content = content.replace(/submitWrongAnswer\(quest: quest, userAnswer: ''\);/g, "submitWrongAnswer(quest: quest!, userAnswer: '');");
    content = content.replace(/submitWrongAnswer\(quest: q, userAnswer: ''\);/g, "submitWrongAnswer(quest: q!, userAnswer: '');");
    fs.writeFileSync(file, content);
}
['academic_word', 'antonym_search', 'contextual_usage', 'idioms', 'prefix_suffix', 'synonym_search', 'topic_vocab', 'word_formation'].forEach(f => {
    let p;
    if(f === 'flashcards') p = 'lib/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';
    else if(f === 'antonym_search') p = 'lib/features/vocabulary/antonym_search/presentation/pages/antonym_search_screen.dart';
    else p = 'lib/features/vocabulary/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)) fixQuestNull(p);
});
['sentence_correction', 'voice_swap', 'pronoun_resolution'].forEach(f => {
    let p = 'lib/features/grammar/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)){
        let content = fs.readFileSync(p, 'utf8');
        content = content.replace(/submitWrongAnswer\(quest: quest/g, "submitWrongAnswer(quest: _lastQuest!");
        fs.writeFileSync(p, content);
    }
});
let fc = 'lib/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';
if(fs.existsSync(fc)){
    let content = fs.readFileSync(fc, 'utf8');
    content = content.replace(/submitWrongAnswer\(quest: quest/g, "submitWrongAnswer(quest: _lastQuest!");
    fs.writeFileSync(fc, content);
}
