import 'dart:io';

void main() {
  final file = File('lib/features/grammar/conjunctions/presentation/pages/conjunctions_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('String? _placedBrick;', 'final ValueNotifier<String?> _placedBrick = ValueNotifier(null);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _placedBrick.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('if (_isAnswered || _pendingJigsaw) return;', 'if (_isAnswered.value || _pendingJigsaw.value) return;');

  content = content.replaceAll('''      setState(() {
        _placedBrick = conj;
        _pendingJigsaw = true;
      });''', '''      _placedBrick.value = conj;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _placedBrick = conj;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _placedBrick.value = conj;''');

  content = content.replaceAll('setState(() => _pendingJigsaw = false);', '_pendingJigsaw.value = false;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = correct;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _placedBrick = null;
              _pendingJigsaw = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _placedBrick.value = null;
            _pendingJigsaw.value = false;''');

  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('\n', '\r\n');
  
  file.writeAsStringSync(content);
}
