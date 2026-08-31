import 'dart:io';

void main() {
  final file = File('lib/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('int _selectedQuadrant = -1;', 'final ValueNotifier<int> _selectedQuadrant = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingTypeSubmit = false;', 'final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _selectedQuadrant.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingTypeSubmit.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('if (_isAnswered || _pendingTypeSubmit) return;', 'if (_isAnswered.value || _pendingTypeSubmit.value) return;');
  
  content = content.replaceAll('''      setState(() {
        _selectedQuadrant = index;
        _pendingTypeSubmit = true;
      });''', '''      _selectedQuadrant.value = index;
      _pendingTypeSubmit.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedQuadrant = index;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedQuadrant.value = index;''');

  content = content.replaceAll('setState(() => _pendingTypeSubmit = false);', '_pendingTypeSubmit.value = false;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedQuadrant = -1;
              _pendingTypeSubmit = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedQuadrant.value = -1;
            _pendingTypeSubmit.value = false;''');

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
