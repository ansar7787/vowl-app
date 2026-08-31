import 'dart:io';

void main() {
  final file = File('lib/features/grammar/article_insertion/presentation/pages/article_insertion_screen.dart');
  String content = file.readAsStringSync();
  
  // Normalize line endings to avoid CRLF mismatch
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('''      setState(() {
        _selectedArticle = article;
        _pendingJigsaw = true;
      });''', '''      _selectedArticle.value = article;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedArticle = article;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedArticle.value = article;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = correct;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedArticle = null;
              _pendingJigsaw = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedArticle.value = null;
            _pendingJigsaw.value = false;''');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  // Convert LF back to CRLF because it's Windows
  content = content.replaceAll('\n', '\r\n');
  
  file.writeAsStringSync(content);
}
