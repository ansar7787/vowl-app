import 'dart:io';

void main() {
  final file = File('lib/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart');
  List<String> lines = file.readAsLinesSync();
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('setState(() {')) {
      if (i + 1 < lines.length && lines[i+1].contains('_pendingTypeSubmit = true;')) {
        lines[i] = '      _pendingTypeSubmit.value = true;';
        lines[i+1] = '';
        lines[i+2] = '';
      } else if (i + 2 < lines.length && lines[i+1].contains('_isAnswered = true;') && lines[i+2].contains('_isCorrect = false;')) {
        lines[i] = '      _isAnswered.value = true;';
        lines[i+1] = '      _isCorrect.value = false;';
        lines[i+2] = '';
        lines[i+3] = '';
      } else if (i + 2 < lines.length && lines[i+1].contains('_isAnswered = true;') && lines[i+2].contains('_isCorrect = true;')) {
        lines[i] = '      _isAnswered.value = true;';
        lines[i+1] = '      _isCorrect.value = true;';
        lines[i+2] = '';
        lines[i+3] = '';
      }
    }
  }
  
  // Remove empty lines
  lines.removeWhere((line) => line == '');
  
  file.writeAsStringSync(lines.join('\r\n'));
}
