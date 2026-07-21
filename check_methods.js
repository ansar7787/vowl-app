const fs = require('fs');

const files = [
    'lib/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_screen.dart',
    'lib/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_screen.dart',
    'lib/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart',
    'lib/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart',
    'lib/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart',
    'lib/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart',
    'lib/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart',
    'lib/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart',
    'lib/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart',
    'lib/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart',
    'lib/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart',
    'lib/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart'
];

for (let file of files) {
    let content = fs.readFileSync(file, 'utf8');
    let match = content.match(/void _(checkResult|verifySpeech)\([^)]+\)\s*\{([\s\S]*?)setState\(\(\)\s*\{/);
    if (match) {
        console.log('--- ' + file + ' ---');
        console.log(match[0]);
    }
}
