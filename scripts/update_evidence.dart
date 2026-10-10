import 'dart:convert';
import 'dart:io';

String getCleanPassage(String passage) {
  final match = RegExp(r'^\[(.*?)\]\s*(.*)$', dotAll: true).firstMatch(passage);
  if (match != null) {
    return match.group(2) ?? passage;
  }
  return passage;
}

List<String> getWords(String text) {
  text = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
}

String findBestSubstring(String passage, String answer, String explanation) {
  final passageLower = passage.toLowerCase();
  final ansLower = answer.toLowerCase();

  if (passageLower.contains(ansLower)) {
    final startIdx = passageLower.indexOf(ansLower);
    return passage.substring(startIdx, startIdx + ansLower.length);
  }

  // Split into sentences roughly
  final sentences = passage.split(RegExp(r'(?<=[.!?])\s+'));
  String bestSentence = "";
  double maxOverlap = -1;

  final ansWords = getWords(answer).toSet();
  final expWords = getWords(explanation).toSet();

  for (final sentence in sentences) {
    final sWords = getWords(sentence).toSet();

    double overlap = sWords.intersection(ansWords).length.toDouble();
    overlap += sWords.intersection(expWords).length * 0.1;

    if (overlap > maxOverlap) {
      maxOverlap = overlap;
      bestSentence = sentence;
    }
  }

  if (bestSentence.isEmpty) {
    bestSentence = passage;
  }

  bestSentence = bestSentence.trim();

  final wordSpans = <Map<String, dynamic>>[];
  final wordMatches = RegExp(r'\b\w+\b').allMatches(bestSentence);
  for (final m in wordMatches) {
    wordSpans.add({
      'word': m.group(0)!.toLowerCase(),
      'start': m.start,
      'end': m.end,
    });
  }

  int firstIdx = -1;
  int lastIdx = -1;

  final stopWords = {
    'the',
    'a',
    'an',
    'is',
    'are',
    'was',
    'were',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'and',
    'or',
    'but',
  };
  var significantAnsWords = ansWords.difference(stopWords);
  if (significantAnsWords.isEmpty) {
    significantAnsWords = ansWords;
  }

  for (final span in wordSpans) {
    if (significantAnsWords.contains(span['word'])) {
      if (firstIdx == -1) {
        firstIdx = span['start'] as int;
      }
      lastIdx = span['end'] as int;
    }
  }

  if (firstIdx != -1 && lastIdx != -1) {
    return bestSentence.substring(firstIdx, lastIdx).trim();
  }

  return bestSentence;
}

void main() {
  final dir = Directory('assets/curriculum/reading');
  final files = dir.listSync().where(
    (f) => f.path.endsWith('.json') && f.path.contains('readAndAnswer_'),
  );

  int updatedCount = 0;

  for (final file in files) {
    if (file is File) {
      final text = file.readAsStringSync();
      final data = json.decode(text) as Map<String, dynamic>;

      final quests = data['quests'] as List;
      bool modified = false;

      for (final quest in quests) {
        final passage = quest['passage'] as String?;
        if (passage == null || passage.isEmpty) continue;

        final cleanPassage = getCleanPassage(passage);
        final answer = quest['correctAnswer'] as String? ?? '';
        final explanation = quest['explanation'] as String? ?? '';

        final evidence = findBestSubstring(cleanPassage, answer, explanation);

        if (evidence.isNotEmpty) {
          quest['evidenceLine'] = evidence;
          modified = true;
          updatedCount++;
        }
      }

      if (modified) {
        // Pretty print JSON
        final encoder = JsonEncoder.withIndent('  ');
        file.writeAsStringSync(encoder.convert(data));
      }
    }
  }

  print(
    'Processed ${files.length} files. Updated $updatedCount questions with evidenceLine.',
  );
}
