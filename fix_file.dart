import 'dart:io';

void main() {
  final file = File('lib/features/grammar/conditionals/presentation/pages/conditionals_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('List<Offset> _chainPoints = [];', 'final ValueNotifier<List<Offset>> _chainPoints = ValueNotifier([]);');
  content = content.replaceAll('int _targetIndex = -1;', 'final ValueNotifier<int> _targetIndex = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _chainPoints.dispose();\n    _targetIndex.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isFirstStagePassed.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('if (_isAnswered || _isFirstStagePassed) return;', 'if (_isAnswered.value || _isFirstStagePassed.value) return;');
  
  content = content.replaceAll('''      setState(() {
        _isFirstStagePassed = true;
        _targetIndex = nodeIndex;
      });''', '''      _isFirstStagePassed.value = true;
      _targetIndex.value = nodeIndex;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetIndex = nodeIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetIndex.value = nodeIndex;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;''');

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
