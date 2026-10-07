const fs = require('fs');

['shadowing_challenge', 'syllable_stress', 'vowel_distinction'].forEach(f => {
    let p = 'lib/features/accent/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)){
        let c = fs.readFileSync(p, 'utf8');
        c = c.replace(/context\.read<AccentBloc>\(\)\.add\(SubmitAnswer\(false\)\);/g, "submitWrongAnswer(quest: context.read<AccentBloc>().state.currentQuestOrNull!, userAnswer: '');");
        fs.writeFileSync(p, c);
    }
});
