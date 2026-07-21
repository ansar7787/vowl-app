const fs = require('fs');

const files = [
    'lib/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart',
    'lib/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart',
    'lib/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart',
    'lib/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart',
    'lib/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart',
    'lib/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart',
    'lib/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart',
    'lib/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart',
    'lib/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart'
];

for (let file of files) {
    let content = fs.readFileSync(file, 'utf8');

    // Replace the specific verification check block
    content = content.replace(/bool (\w+) = TextSimilarityHelper\.isMatch\([\s\S]*?\);/,
        'bool  = false;\n' +
        '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
        '      if (TextSimilarityHelper.isMatch(candidate, _targetExpression ?? "", threshold: 0.70)) {\n' +
        '         = true;\n' +
        '        _spokenText = candidate;\n' +
        '        break;\n' +
        '      }\n' +
        '    }'
    );
    
    // Some might not use _targetExpression, wait, we need to match the original variables.
    // Let's capture the original arguments:
    content = content.replace(/bool (\w+) = TextSimilarityHelper\.isMatch\(\s*[^,]+,\s*([^,]+),\s*threshold:\s*([^)]+)\s*\);/,
        'bool  = false;\n' +
        '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
        '      if (TextSimilarityHelper.isMatch(candidate, , threshold: )) {\n' +
        '         = true;\n' +
        '        _spokenText = candidate;\n' +
        '        break;\n' +
        '      }\n' +
        '    }'
    );

    fs.writeFileSync(file, content);
    console.log('Processed ' + file);
}
