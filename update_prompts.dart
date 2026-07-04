import 'dart:io';

void main() {
  final updates = {
    'connected_speech_instruction.dart': [
      '"IDENTIFY THE CONNECTED SPEECH PHENOMENON ENUNCIATED"',
      '"SELECT THE CARD THAT LINKS THE WORDS"'
    ],
    'consonant_clarity_instruction.dart': [
      '"IDENTIFY THE TARGET CONSONANT PHONEME DISPLAYED"',
      'instruction.trim().isEmpty\n                ? "TAP THE CORRECT CONSONANT SOUND"\n                : instruction.toUpperCase()'
    ],
    'dialect_drill_instruction.dart': [
      '"RADAR FREQUENCY DIALECT SWITCH"',
      '"IDENTIFY THE REGIONAL DIALECT"'
    ],
    'intonation_mimic_instruction.dart': [
      '"IDENTIFY THE INTONATION CONTOUR ENUNCIATED IN PHRASE"',
      '"MATCH THE PITCH USING THE FADER"'
    ],
    'minimal_pairs_instruction.dart': [
      'instruction?.toUpperCase() ?? "LISTEN AND CHOOSE THE MATCHING WORD"',
      '(instruction?.trim().isEmpty ?? true)\n                ? "LISTEN AND CHOOSE THE MATCHING WORD"\n                : instruction!.toUpperCase()'
    ],
    'pitch_modulation_instruction.dart': [
      '"IDENTIFY PITCH MODULATION CONTOUR & EMOTIONAL NUANCE"',
      '"IDENTIFY THE PITCH CHANGE"'
    ],
    'pitch_pattern_match_instruction.dart': [
      'instruction.toUpperCase()',
      'instruction.trim().isEmpty\n                ? "MATCH THE MELODY USING THE FADER"\n                : instruction.toUpperCase()'
    ],
    'shadowing_challenge_instruction.dart': [
      '"SHADOW SPONTANEOUSLY BLENDING PHONETIC TECHNIQUES"',
      '"TAP THE CHAT BUBBLE TO SHADOW THE VOICE"'
    ],
    'speed_variance_instruction.dart': [
      '"IDENTIFY SPEED VARIANCE CONTOUR & PACING INTENT ENUNCIATED"',
      '"IDENTIFY THE SPEAKING SPEED"'
    ],
    'syllable_stress_instruction.dart': [
      '"STRIKE THE DRUM PAD CONTAINING THE STRESSED SYLLABLE"',
      '"TAP THE STRESSED SYLLABLE"'
    ],
    'vowel_distinction_instruction.dart': [
      '"SLIDE OR TAP TO MATCH THE VOWEL SOUND"',
      '"SLIDE TO MATCH THE VOWEL SOUND"'
    ],
    'word_linking_instruction.dart': [
      '"TAP THE CHAIN LINK NODE WHERE CONTEXTUAL WORD LINKING OCCURS"',
      '"IDENTIFY HOW THE WORDS ARE LINKED"'
    ],
  };

  final dir = Directory('lib/features/accent');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('_instruction.dart'));

  for (var file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    if (updates.containsKey(fileName)) {
      var content = file.readAsStringSync();
      final target = updates[fileName]![0];
      final replacement = updates[fileName]![1];
      
      content = content.replaceAll(target, replacement);
      file.writeAsStringSync(content);
      print('Updated $fileName');
    }
  }
}
