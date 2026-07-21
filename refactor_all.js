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

    // 3. Update Verification logic
    if (file.includes('accent_shadowing_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [spoken] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, target, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _lastWords = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('elevator_pitch_screen.dart')) {
        content = content.replace(/bool isCorrect = alignmentAccuracy >= 0\.40 && _spokenText\.length >= 12;/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (alignmentAccuracy >= 0.40 && candidate.length >= 12) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('daily_expression_screen.dart')) {
        content = content.replace(/bool matchFound = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool matchFound = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, _targetExpression, threshold: 0.70)) {\n' +
            '        matchFound = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('dialogue_roleplay_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, targetText, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('pronunciation_focus_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.80,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expectedWord, threshold: 0.80)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('repeat_sentence_screen.dart')) {
        content = content.replace(/final bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('scene_description_speaking_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.60,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, description, threshold: 0.60)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('situation_speaking_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.65,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expression, threshold: 0.65)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('speak_missing_word_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('speak_opposite_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.80,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.80)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('speak_synonym_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.80,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expected, threshold: 0.80)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('yes_no_speaking_screen.dart')) {
        content = content.replace(/bool speechIsCorrect = TextSimilarityHelper.isMatch\([\s\S]*?threshold: 0\.75,\s*\);/,
            'bool speechIsCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expectedSpeech, threshold: 0.75)) {\n' +
            '        speechIsCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    }

    fs.writeFileSync(file, content);
    console.log('Processed ' + file);
}
