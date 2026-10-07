const fs = require('fs');

let f1 = 'lib/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart';
if(fs.existsSync(f1)){
    let c1 = fs.readFileSync(f1, 'utf8');
    c1 = c1.replace(/import '\.\.\/\.\.\/domain\/entities\/elite_mastery_quest\.dart';\n?/g, '');
    c1 = c1.replace(/quest is EliteMasteryQuest \? quest\.word :/g, '"" :');
    fs.writeFileSync(f1, c1);
}

let f2 = 'lib/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';
if(fs.existsSync(f2)){
    let c2 = fs.readFileSync(f2, 'utf8');
    c2 = c2.replace(/import '\.\.\/\.\.\/domain\/entities\/elite_mastery_quest\.dart';\n?/g, '');
    c2 = c2.replace(/EliteMasteryQuest\?/g, 'GameQuest?');
    fs.writeFileSync(f2, c2);
}

let f3 = 'lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
if(fs.existsSync(f3)){
    let c3 = fs.readFileSync(f3, 'utf8');
    c3 = c3.replace(/_onFire\(_activeShardIndex\.value!, context, true\);/g, '_onFire(_activeShardIndex.value!, context, true, _lastQuest!);');
    fs.writeFileSync(f3, c3);
}

let f4 = 'lib/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart';
if(fs.existsSync(f4)){
    let c4 = fs.readFileSync(f4, 'utf8');
    c4 = c4.replace(/_submitVerbalEvaluation\(false\);/g, '_submitVerbalEvaluation(false, _lastQuest!);');
    fs.writeFileSync(f4, c4);
}

['shadowing_challenge', 'syllable_stress', 'vowel_distinction'].forEach(f => {
    let p = 'lib/features/accent/'+f+'/presentation/pages/'+f+'_screen.dart';
    if(fs.existsSync(p)){
        let c = fs.readFileSync(p, 'utf8');
        c = c.replace(/submitWrongAnswer\(quest: quest/g, 'submitWrongAnswer(quest: _lastQuest!');
        fs.writeFileSync(p, c);
    }
});

console.log('Fixed final elite mastery and accent issues');
