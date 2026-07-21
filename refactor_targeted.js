const fs = require('fs');

const filesToPatch = {
    'lib/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart': {
        find: \    bool matchFound = false;
    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(
      RegExp(r'[^\\w\\s]'),
      '',
    );

    // Any part of the target dialogue matches sufficiently?
    for (var sub in targetSubs) {
      final String cleanSub = sub.trim().toLowerCase().replaceAll(
        RegExp(r'[^\\w\\s]'),
        '',
      );
      if (cleanSpeech.contains(cleanSub) ||
          TextSimilarityHelper.isMatch(
            cleanSpeech,
            cleanSub,
            threshold: 0.70,
          )) {
        matchFound = true;
        break;
      }
    }\,
        replace: \    bool matchFound = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      final String cleanSpeech = candidate.trim().toLowerCase().replaceAll(
        RegExp(r'[^\\w\\s]'),
        '',
      );

      for (var sub in targetSubs) {
        final String cleanSub = sub.trim().toLowerCase().replaceAll(
          RegExp(r'[^\\w\\s]'),
          '',
        );
        if (cleanSpeech.contains(cleanSub) ||
            TextSimilarityHelper.isMatch(
              cleanSpeech,
              cleanSub,
              threshold: 0.70,
            )) {
          matchFound = true;
          _spokenText = candidate;
          break;
        }
      }
      if (matchFound) break;
    }\
    },
    'lib/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart': {
        find: \    bool isCorrect = false;

    // Direct match against the focus word
    if (TextSimilarityHelper.isMatch(
      _spokenText,
      expectedWord,
      threshold: 0.70,
    )) {
      isCorrect = true;
    } else {
      // If they spoke a whole sentence, check if the expected word is in there
      final words = _spokenText
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z\\s]'), '')
          .split(' ');
      final target = expectedWord.toLowerCase();
      if (words.contains(target)) {
        isCorrect = true;
      }
    }\,
        replace: \    bool isCorrect = false;
    for (var candidate in _spokenCandidates.isEmpty ? [_spokenText] : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(
        candidate,
        expectedWord,
        threshold: 0.70,
      )) {
        isCorrect = true;
        _spokenText = candidate;
        break;
      } else {
        final words = candidate
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z\\s]'), '')
            .split(' ');
        final target = expectedWord.toLowerCase();
        if (words.contains(target)) {
          isCorrect = true;
          _spokenText = candidate;
          break;
        }
      }
    }\
    }
};

for (const [file, patch] of Object.entries(filesToPatch)) {
    let content = fs.readFileSync(file, 'utf8');
    if (content.includes(patch.find)) {
        content = content.replace(patch.find, patch.replace);
        fs.writeFileSync(file, content);
        console.log('Successfully patched ' + file);
    } else {
        console.log('Could not find match in ' + file);
    }
}
