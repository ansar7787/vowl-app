const fs = require('fs');

['shadowing_challenge', 'syllable_stress', 'vowel_distinction'].forEach(f => {
    let p = 'lib/features/accent/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)){
        let c = fs.readFileSync(p, 'utf8');
        c = c.replace(/submitWrongAnswer\(quest: _lastQuest!/g, 'submitWrongAnswer(quest: currentQuestOrNull!');
        fs.writeFileSync(p, c);
    }
});

let p1 = 'lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
if(fs.existsSync(p1)){
    let c1 = fs.readFileSync(p1, 'utf8');
    c1 = c1.replace(/_lastQuest!/g, 'currentQuestOrNull!');
    fs.writeFileSync(p1, c1);
}

let p2 = 'lib/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart';
if(fs.existsSync(p2)){
    let c2 = fs.readFileSync(p2, 'utf8');
    c2 = c2.replace(/_submitVerbalEvaluation\(false, _lastQuest!\);/g, '_submitVerbalEvaluation(false);');
    fs.writeFileSync(p2, c2);
}
