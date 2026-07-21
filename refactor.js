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

    // 1. Add _spokenCandidates to state
    if (!content.includes('List<String> _spokenCandidates = [];')) {
        content = content.replace(/String _spokenText = "";|String _spokenPhrase = "";|String _lastWords = "";/, match => match + '\n  List<String> _spokenCandidates = [];');
    }

    // 2. Change onResult: (text) { ... }
    content = content.replace(/onResult:\s*\(\s*text\s*\)\s*\{/g, 
        'onResult: (candidates) {\n' +
        '          if (candidates.isEmpty) return;\n' +
        '          _spokenCandidates = candidates;\n' +
        '          final text = candidates.first;'
    );

    fs.writeFileSync(file, content);
    console.log('Processed ' + file);
}
