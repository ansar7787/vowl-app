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
    if (!fs.existsSync(file)) {
        console.log("Not found: " + file);
        continue;
    }
    
    let content = fs.readFileSync(file, 'utf8');

    // 1. Add _spokenCandidates to state
    if (!content.includes('List<String> _spokenCandidates = [];')) {
        content = content.replace(/(String _spokenText = "";|String _spokenPhrase = "";|String _lastWords = "";)/, '$1\n  List<String> _spokenCandidates = [];');
    }

    // 2. Change onResult: (text) { ... }
    content = content.replace(/onResult:\s*\(\s*text\s*\)\s*\{/g, 
        'onResult: (candidates) {\n' +
        '          if (candidates.isEmpty) return;\n' +
        '          _spokenCandidates = candidates;\n' +
        '          final text = candidates.first;'
    );
    
    // 3. Fix the specific logic blocks
    if (file.includes('accent_shadowing_screen.dart')) {
        content = content.replace(/bool isCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [spoken] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, target, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _lastWords = candidate; // Update UI to show the correctly matched string\n' +
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
        content = content.replace(/bool matchFound = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.70,\s*\);/,
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
        content = content.replace(/bool matchFound = false;\s*final String cleanSpeech = _spokenText\.trim\(\)\.toLowerCase\(\)\.replaceAll\([\s\S]*?matchFound = true;\s*break;\s*\}\s*\}/,
            'bool matchFound = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      final String cleanSpeech = candidate.trim().toLowerCase().replaceAll(RegExp(r\'[^\\w\\s]\'), \'\');\n' +
            '      for (var sub in targetSubs) {\n' +
            '        final String cleanSub = sub.trim().toLowerCase().replaceAll(RegExp(r\'[^\\w\\s]\'), \'\');\n' +
            '        if (cleanSpeech.contains(cleanSub) || TextSimilarityHelper.isMatch(cleanSpeech, cleanSub, threshold: 0.70)) {\n' +
            '          matchFound = true;\n' +
            '          _spokenText = candidate;\n' +
            '          break;\n' +
            '        }\n' +
            '      }\n' +
            '      if (matchFound) break;\n' +
            '    }'
        );
    } else if (file.includes('pronunciation_focus_screen.dart')) {
        content = content.replace(/bool isCorrect = false;\s*\/\/\s*Direct match against the focus word[\s\S]*?isCorrect = true;\s*\}\s*\}/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expectedWord, threshold: 0.70)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      } else {\n' +
            '        final words = candidate.toLowerCase().replaceAll(RegExp(r\'[^a-z\\s]\'), \'\').split(\' \');\n' +
            '        if (words.contains(expectedWord.toLowerCase())) {\n' +
            '          isCorrect = true;\n' +
            '          _spokenText = candidate;\n' +
            '          break;\n' +
            '        }\n' +
            '      }\n' +
            '    }'
        );
    } else if (file.includes('yes_no_speaking_screen.dart')) {
        content = content.replace(/bool speechIsCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.75,\s*\);/,
            'bool speechIsCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, expectedSpeech, threshold: 0.75)) {\n' +
            '        speechIsCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    } else {
        // Generalized replacement for the standard ones (repeat_sentence, situation, scene_desc, speak_missing, speak_opposite, speak_synonym)
        content = content.replace(/bool isCorrect = TextSimilarityHelper\.isMatch\(\s*[^,]+,\s*([^,]+),\s*threshold:\s*([^,]+),\s*\);/,
            'bool isCorrect = false;\n' +
            '    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {\n' +
            '      if (TextSimilarityHelper.isMatch(candidate, $1, threshold: $2)) {\n' +
            '        isCorrect = true;\n' +
            '        _spokenText = candidate;\n' +
            '        break;\n' +
            '      }\n' +
            '    }'
        );
    }

    fs.writeFileSync(file, content);
    console.log('Processed ' + file);
}
