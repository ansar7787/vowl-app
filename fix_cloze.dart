import 'dart:io';

void main() {
  final file = File('lib/features/reading/cloze_test/presentation/pages/cloze_test_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('String? _dockedOption;', 'final ValueNotifier<String?> _dockedOption = ValueNotifier(null);');
  content = content.replaceAll('String? _pendingDockedOption;', 'final ValueNotifier<String?> _pendingDockedOption = ValueNotifier(null);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _dockedOption.dispose();\n    _pendingDockedOption.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingDockedOption != null) return;', 'if (_isAnswered.value || _pendingDockedOption.value != null) return;');

  content = content.replaceAll('setState(() => _pendingDockedOption = option);', '_pendingDockedOption.value = option;');
  
  content = content.replaceAll('if (_pendingDockedOption == null) return;', 'if (_pendingDockedOption.value == null) return;');

  content = content.replaceAll('''      setState(() {
        _dockedOption = _pendingDockedOption;
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _dockedOption.value = _pendingDockedOption.value;
      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('final selected = _pendingDockedOption!;', 'final selected = _pendingDockedOption.value!;');
  content = content.replaceAll('setState(() => _dockedOption = _pendingDockedOption);', '_dockedOption.value = _pendingDockedOption.value;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dockedOption = null;
              _pendingDockedOption = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dockedOption.value = null;
            _pendingDockedOption.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dockedOption, _pendingDockedOption]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                                  dockedOption:
                                      _dockedOption ?? _pendingDockedOption,
                                  wordCategory: quest.wordCategory,
                                  isAnswered: _isAnswered,''', '''                                  dockedOption:
                                      _dockedOption.value ?? _pendingDockedOption.value,
                                  wordCategory: quest.wordCategory,
                                  isAnswered: _isAnswered.value,''');
                                  
  content = content.replaceAll('''                                  dockedOption:
                                      _dockedOption ?? _pendingDockedOption,''', '''                                  dockedOption:
                                      _dockedOption.value ?? _pendingDockedOption.value,''');

  content = content.replaceAll('if (_pendingDockedOption != null && !_isAnswered)', 'if (_pendingDockedOption.value != null && !_isAnswered.value)');

  content = content.replaceAll('''                      ],
                    ),
                    if (_pendingDockedOption != null && !_isAnswered)
                      DynamicAnagramWrapper(
                        expectedText: quest.targetWord ?? quest.correctAnswer ?? "",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, quest.correctAnswer ?? ""),
                        onFailed: () => _submitFinalAnswer(false, quest.correctAnswer ?? ""),
                      ),
                  ],
                ),
        );
      },
    );
  }
}''', '''                      ],
                    ),
                    if (_pendingDockedOption.value != null && !_isAnswered.value)
                      DynamicAnagramWrapper(
                        expectedText: quest.targetWord ?? quest.correctAnswer ?? "",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, quest.correctAnswer ?? ""),
                        onFailed: () => _submitFinalAnswer(false, quest.correctAnswer ?? ""),
                      ),
                  ],
                ),
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
