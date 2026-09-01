import 'dart:io';

void main() {
  final file = File('lib/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedIndex.dispose();\n    _pulseController.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('''  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }''', '');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('setState(() => _selectedIndex = index);', '_selectedIndex.value = index;');

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
              _selectedIndex = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                  isCorrectState: _isCorrect,''', '''                                  isCorrectState: _isCorrect.value,''');
  content = content.replaceAll('''                                  isAnswered: _isAnswered,''', '''                                  isAnswered: _isAnswered.value,''');
  content = content.replaceAll('''                                  selectedIndex: _selectedIndex,''', '''                                  selectedIndex: _selectedIndex.value,''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                ),
            );
          },
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ListeningInferenceGrid(
                                  options: quest.options ?? [],
                                  correctAnswerIndex: quest.correctAnswerIndex ?? 0,
                                  color: theme.primaryColor,
                                  isAnswered: _isAnswered.value,
                                  isCorrectState: _isCorrect.value,
                                  selectedIndex: _selectedIndex.value,
                                  onSubmitAnswer: (index) {
                                    _submitFinalAnswer(
                                      index,
                                      quest.correctAnswerIndex ?? 0,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),''', '''                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ListeningInferenceGrid(
                                  options: quest.options ?? [],
                                  correctAnswerIndex: quest.correctAnswerIndex ?? 0,
                                  color: theme.primaryColor,
                                  isAnswered: _isAnswered.value,
                                  isCorrectState: _isCorrect.value,
                                  selectedIndex: _selectedIndex.value,
                                  onSubmitAnswer: (index) {
                                    _submitFinalAnswer(
                                      index,
                                      quest.correctAnswerIndex ?? 0,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
