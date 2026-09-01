import 'dart:io';

void main() {
  final file = File('lib/features/listening/audio_true_false/presentation/pages/audio_true_false_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _tuningValue = 0.5;', 'final ValueNotifier<double> _tuningValue = ValueNotifier(0.5);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool? _selectedVerdict;', 'final ValueNotifier<bool?> _selectedVerdict = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _tuningValue.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedVerdict.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''    bool isCorrect =
        _selectedVerdict.toString().toLowerCase() ==
        correct.trim().toLowerCase();''', '''    bool isCorrect =
        _selectedVerdict.value.toString().toLowerCase() ==
        correct.trim().toLowerCase();''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''          userAnswer: _selectedVerdict.toString(),''', '''          userAnswer: _selectedVerdict.value.toString(),''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _tuningValue = 0.5;
              _selectedVerdict = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _tuningValue.value = 0.5;
            _selectedVerdict.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                    setState(() => _tuningValue = v);''', '''                                    _tuningValue.value = v;''');
  
  content = content.replaceAll('''                                      setState(
                                        () => _selectedVerdict = true,
                                      );''', '''                                      _selectedVerdict.value = true;''');
  
  content = content.replaceAll('''                                      setState(
                                        () => _selectedVerdict = false,
                                      );''', '''                                      _selectedVerdict.value = false;''');

  content = content.replaceAll('''                                    if (_isAnswered ||
                                        _selectedVerdict != null) {''', '''                                    if (_isAnswered.value ||
                                        _selectedVerdict.value != null) {''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _tuningValue, _selectedVerdict]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                    isCorrectState: _isCorrect,''', '''                                    isCorrectState: _isCorrect.value,''');

  content = content.replaceAll('''                                    tuningValue: _tuningValue,''', '''                                    tuningValue: _tuningValue.value,''');

  content = content.replaceAll('''                                  isAnswered: _isAnswered,''', '''                                  isAnswered: _isAnswered.value,''');

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

  content = content.replaceAll('''                    if (_selectedVerdict != null && !_isAnswered)''', '''                    if (_selectedVerdict.value != null && !_isAnswered.value)''');

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
                                AudioTrueFalsePolarizedFilters(
                                  tuningValue: _tuningValue.value,
                                  isAnswered: _isAnswered.value,
                                  isCorrectState: _isCorrect.value,
                                  color: theme.primaryColor,
                                  onChanged: (v) {
                                    _tuningValue.value = v;
                                    _hapticService.selection();
                                  },
                                  onChangeEnd: (v) {
                                    if (_isAnswered.value ||
                                        _selectedVerdict.value != null) {
                                      return;
                                    }
                                    if (v > 0.9) {
                                      _selectedVerdict.value = true;
                                    }
                                    if (v < 0.1) {
                                      _selectedVerdict.value = false;
                                    }
                                  },
                                ),
                                SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
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
                                AudioTrueFalsePolarizedFilters(
                                  tuningValue: _tuningValue.value,
                                  isAnswered: _isAnswered.value,
                                  isCorrectState: _isCorrect.value,
                                  color: theme.primaryColor,
                                  onChanged: (v) {
                                    _tuningValue.value = v;
                                    _hapticService.selection();
                                  },
                                  onChangeEnd: (v) {
                                    if (_isAnswered.value ||
                                        _selectedVerdict.value != null) {
                                      return;
                                    }
                                    if (v > 0.9) {
                                      _selectedVerdict.value = true;
                                    }
                                    if (v < 0.1) {
                                      _selectedVerdict.value = false;
                                    }
                                  },
                                ),
                                SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                              ],
                            ),
                          ),
                        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
