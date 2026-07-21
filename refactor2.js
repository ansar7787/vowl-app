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

    if (file.includes('accent_shadowing_screen.dart')) {
        content = content.replace(/void _checkResult\(String spoken, String target\) \{([\s\S]*?)bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?\);/,
            'void _checkResult(String spoken, String target) {\n' +
            '    if (_isAnswered) return;\n\n' +
            '    bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [spoken] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, target, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _lastWords = candidate; // Update UI to show the correctly matched string\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('elevator_pitch_screen.dart')) {
        content = content.replace(/bool isCorrect = alignmentAccuracy >= 0.40 && _spokenText\.length >= 12;/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (alignmentAccuracy >= 0.40 && candidate.length >= 12) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else {
        content = content.replace(/final bool isCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate; // Update UI to show the correct matched string\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
        content = content.replace(/bool isCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate; // Update UI to show the correct matched string\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    }

    fs.writeFileSync(file, content);
    console.log('Processed ' + file);
}
