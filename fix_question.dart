import 'dart:io';

void main() {
  final file = File('lib/features/grammar/question_formatter/presentation/pages/question_formatter_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _crankRotation = 0.0;', 'final ValueNotifier<double> _crankRotation = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);');
  content = content.replaceAll('String? _selectedOptionText;', 'final ValueNotifier<String?> _selectedOptionText = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _crankRotation.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    _selectedOptionText.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _crankRotation.abs() >= 6.28 || _pendingJigsaw) return;', 'if (_isAnswered.value || _crankRotation.value.abs() >= 6.28 || _pendingJigsaw.value) return;');

  content = content.replaceAll('''      begin: _crankRotation,''', '''      begin: _crankRotation.value,''');

  content = content.replaceAll('''      setState(() => _crankRotation = animation.value);''', '''      _crankRotation.value = animation.value;''');

  content = content.replaceAll('if (_isAnswered || _pendingJigsaw) return;', 'if (_isAnswered.value || _pendingJigsaw.value) return;');

  content = content.replaceAll('''    setState(() {
      _crankRotation += delta * 0.01;
      if ((_crankRotation * 57.29).abs().toInt() % 10 == 0) {
        _hapticService.selection();
      }
    });''', '''    _crankRotation.value += delta * 0.01;
    if ((_crankRotation.value * 57.29).abs().toInt() % 10 == 0) {
      _hapticService.selection();
    }''');

  content = content.replaceAll('''      setState(() {
        _selectedOptionText = optionText;
        _pendingJigsaw = true;
      });''', '''      _selectedOptionText.value = optionText;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _crankRotation = 0.0;
        _selectedOptionText = optionText;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _crankRotation.value = 0.0;
      _selectedOptionText.value = optionText;''');

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
              _crankRotation = 0.0;
              _pendingJigsaw = false;
              _selectedOptionText = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _crankRotation.value = 0.0;
            _pendingJigsaw.value = false;
            _selectedOptionText.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('} else if (_selectedOptionText != null) {', '} else if (_selectedOptionText.value != null) {');
  content = content.replaceAll('cleanTargetSentence = _selectedOptionText!;', 'cleanTargetSentence = _selectedOptionText.value!;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _crankRotation, _pendingJigsaw, _selectedOptionText]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('..rotateX(_crankRotation),', '..rotateX(_crankRotation.value),');
  
  content = content.replaceAll('''                                    if (!_isAnswered &&
                                        !_pendingJigsaw &&
                                        _crankRotation.abs() < 6.28)
                                      QuestionFormatterCrank(
                                        crankRotation: _crankRotation,
                                        isAnswered:
                                            _isAnswered || _pendingJigsaw,''', '''                                    if (!_isAnswered.value &&
                                        !_pendingJigsaw.value &&
                                        _crankRotation.value.abs() < 6.28)
                                      QuestionFormatterCrank(
                                        crankRotation: _crankRotation.value,
                                        isAnswered:
                                            _isAnswered.value || _pendingJigsaw.value,''');

  content = content.replaceAll('else if (!_isAnswered && !_pendingJigsaw)', 'else if (!_isAnswered.value && !_pendingJigsaw.value)');
  content = content.replaceAll('else if (_isAnswered)', 'else if (_isAnswered.value)');
  content = content.replaceAll('quest.correctAnswer ??\n                                            _selectedOptionText ??', 'quest.correctAnswer ??\n                                            _selectedOptionText.value ??');

  // Fix Sliver Layout
  content = content.replaceAll('''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                        displayText: "Type the full question to lock it in",
                      ),
                    SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                  ],
                ),
                ),
              ],
            );
                  },
                ),
        );
      },
    );
  }''', '''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
                    if (_pendingJigsaw.value &&
                        !_isAnswered.value &&
                        cleanTargetSentence.isNotEmpty)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: cleanTargetSentence,
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitFinalAnswer(true),
                          onSkipped: () => _submitFinalAnswer(false),
                          isPositioned: false,
                          displayText: "Type the full question to lock it in",
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: (_isAnswered.value || _pendingJigsaw.value) ? 160.h : 60.h),
                    ),
                  ],
                );
                  },
                ),
            );
          },
        );
      },
    );
  }''');

  content = content.replaceAll('final bool correct = _isCorrect == true;', 'final bool correct = _isCorrect.value == true;');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
