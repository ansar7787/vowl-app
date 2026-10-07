const fs = require('fs');
['shadowing_challenge', 'syllable_stress', 'vowel_distinction'].forEach(f => {
    let p = 'lib/features/accent/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)){
        let c = fs.readFileSync(p, 'utf8');
        c = c.replace(/state\.currentQuestOrNull!/g, "state.currentQuest");
        fs.writeFileSync(p, c);
    }
});
