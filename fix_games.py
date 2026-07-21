import os

files = [
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
]

for file in files:
    if not os.path.exists(file):
        continue
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Add _spokenCandidates
    if 'List<String> _spokenCandidates = [];' not in content:
        content = content.replace('String _spokenText = "";', 'String _spokenText = "";\n  List<String> _spokenCandidates = [];')
        content = content.replace('String _spokenPhrase = "";', 'String _spokenPhrase = "";\n  List<String> _spokenCandidates = [];')
        content = content.replace('String _lastWords = "";', 'String _lastWords = "";\n  List<String> _spokenCandidates = [];')

    # 2. Replace onResult
    import re
    content = re.sub(r'onResult:\s*\(\s*text\s*\)\s*\{', 
        'onResult: (candidates) {\\n          if (candidates.isEmpty) return;\\n          _spokenCandidates = candidates;\\n          final text = candidates.first;', 
        content)

    # 3. Validation Logic Replacement
    if 'accent_shadowing' in file:
        content = re.sub(r'bool isCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.70,\s*\);',
            '''bool isCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [spoken] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(candidate, target, threshold: 0.70)) {
        isCorrect = true;
        _lastWords = candidate;
        break;
      }
    }''', content)
    elif 'elevator_pitch' in file:
        content = content.replace('bool isCorrect = alignmentAccuracy >= 0.40 && _spokenText.length >= 12;',
            '''bool isCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (alignmentAccuracy >= 0.40 && candidate.length >= 12) {
        isCorrect = true;
        _spokenText = candidate;
        break;
      }
    }''')
    elif 'daily_expression' in file:
        content = re.sub(r'bool matchFound = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.70,\s*\);',
            '''bool matchFound = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(candidate, _targetExpression, threshold: 0.70)) {
        matchFound = true;
        _spokenText = candidate;
        break;
      }
    }''', content)
    elif 'dialogue_roleplay' in file:
        content = re.sub(r'bool matchFound = false;[\s\S]*?matchFound = true;\s*break;\s*\}\s*\}',
            '''bool matchFound = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      final String cleanSpeech = candidate.trim().toLowerCase().replaceAll(RegExp(r\'[^\\w\\s]\'), \'\');
      for (var sub in targetSubs) {
        final String cleanSub = sub.trim().toLowerCase().replaceAll(RegExp(r\'[^\\w\\s]\'), \'\');
        if (cleanSpeech.contains(cleanSub) || TextSimilarityHelper.isMatch(cleanSpeech, cleanSub, threshold: 0.70)) {
          matchFound = true;
          _spokenText = candidate;
          break;
        }
      }
      if (matchFound) break;
    }''', content)
    elif 'pronunciation_focus' in file:
        content = re.sub(r'bool isCorrect = false;[\s\S]*?isCorrect = true;\s*\}\s*\}',
            '''bool isCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(candidate, expectedWord, threshold: 0.70)) {
        isCorrect = true;
        _spokenText = candidate;
        break;
      } else {
        final words = candidate.toLowerCase().replaceAll(RegExp(r\'[^a-z\\s]\'), \'\').split(\' \');
        if (words.contains(expectedWord.toLowerCase())) {
          isCorrect = true;
          _spokenText = candidate;
          break;
        }
      }
    }''', content)
    elif 'yes_no_speaking' in file:
        content = re.sub(r'bool speechIsCorrect = TextSimilarityHelper\.isMatch\([\s\S]*?threshold: 0\.75,\s*\);',
            '''bool speechIsCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(candidate, expectedSpeech, threshold: 0.75)) {
        speechIsCorrect = true;
        _spokenText = candidate;
        break;
      }
    }''', content)
    else:
        # Generic for the remaining 6 files
        content = re.sub(r'(?:final\s+)?bool isCorrect = TextSimilarityHelper\.isMatch\(\s*[^,]+,\s*([^,]+),\s*threshold:\s*([^,]+),\s*\);',
            r'''bool isCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(candidate, \1, threshold: \2)) {
        isCorrect = true;
        _spokenText = candidate;
        break;
      }
    }''', content)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched " + file)
