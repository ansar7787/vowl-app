import 'dart:io';

void main() {
  final file = File('lib/features/writing/short_answer_writing/presentation/pages/short_answer_writing_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showContextSentence = false;', 'final ValueNotifier<bool> _showContextSentence = ValueNotifier(false);');
  content = content.replaceAll('double _inkLevel = 0.0;', 'final ValueNotifier<double> _inkLevel = ValueNotifier(0.0);');
  content = content.replaceAll('int _wordCount = 0;', 'final ValueNotifier<int> _wordCount = ValueNotifier(0);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _answerController.dispose();
    _scrollController.dispose();
    _showConfetti.dispose();
    _showContextSentence.dispose();
    _inkLevel.dispose();
    _wordCount.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _wordCount = words;
      _inkLevel = (text.length / 75).clamp(0.0, 1.0);
    });''', '''    _wordCount.value = words;
    _inkLevel.value = (text.length / 75).clamp(0.0, 1.0);''');

  content = content.replaceAll('''    if (_wordCount < 10) {''', '''    if (_wordCount.value < 10) {''');

  content = content.replaceAll('''    setState(() {
      _showContextSentence = true;
    });''', '''    _showContextSentence.value = true;''');

  content = content.replaceAll('''    setState(() => _showContextSentence = false);''', '''    _showContextSentence.value = false;''');

  content = content.replaceAll('''          setState(() {
            _answerController.clear();
            _inkLevel = 0.0;
            _wordCount = 0;
            _showContextSentence = false;
          });''', '''          _answerController.clear();
          _inkLevel.value = 0.0;
          _wordCount.value = 0;
          _showContextSentence.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                      setState(() => _showContextSentence = false);''', '''                      _showContextSentence.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? const SizedBox()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _showContextSentence, _inkLevel, _wordCount]),
            builder: (context, _) {
              return quest == null
                  ? const SizedBox()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''                            ShortAnswerInkwell(
                              controller: _answerController,
                              isAnswered: isAnswered,
                              wordCount: _wordCount,
                              inkLevel: _inkLevel,''', '''                            ShortAnswerInkwell(
                              controller: _answerController,
                              isAnswered: isAnswered,
                              wordCount: _wordCount.value,
                              inkLevel: _inkLevel.value,''');

  content = content.replaceAll('''                            if (!_showContextSentence && !isAnswered && livesRemaining > 0) ...[''', '''                            if (!_showContextSentence.value && !isAnswered && livesRemaining > 0) ...[''');

  content = content.replaceAll('''                                    color: _wordCount >= 10
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount >= 10)''', '''                                    color: _wordCount.value >= 10
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount.value >= 10)''');

  content = content.replaceAll('''                if (_showContextSentence && !isAnswered)''', '''                if (_showContextSentence.value && !isAnswered)''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                );
            },
          ),
        );
      },
    );
  }
}''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
