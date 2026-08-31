import 'dart:io';

void main() {
  final file = File('lib/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('Offset _ringOffset = Offset.zero;', 'final ValueNotifier<Offset> _ringOffset = ValueNotifier(Offset.zero);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingTypeSubmit = false;', 'final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _ringOffset.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingTypeSubmit.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingTypeSubmit) return;', 'if (_isAnswered.value || _pendingTypeSubmit.value) return;');

  content = content.replaceAll('''      setState(() {
        _ringOffset = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);
        _pendingTypeSubmit = true;
      });''', '''      _ringOffset.value = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);
      _pendingTypeSubmit.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _ringOffset = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _ringOffset.value = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);''');

  content = content.replaceAll('setState(() => _pendingTypeSubmit = false);', '_pendingTypeSubmit.value = false;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = correct;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingTypeSubmit = false;
              _ringOffset = Offset.zero;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingTypeSubmit.value = false;
            _ringOffset.value = Offset.zero;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('if (_ringOffset.dx < -threshold) {', 'if (_ringOffset.value.dx < -threshold) {');
  content = content.replaceAll('} else if (_ringOffset.dx > threshold) {', '} else if (_ringOffset.value.dx > threshold) {');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _ringOffset, _pendingTypeSubmit]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('onPanUpdate: _isAnswered || _pendingTypeSubmit\n                                          ? null', 'onPanUpdate: _isAnswered.value || _pendingTypeSubmit.value\n                                          ? null');
  
  content = content.replaceAll('''                                              final double newDx =
                                                  (_ringOffset.dx +
                                                          details.delta.dx)''', '''                                              final double newDx =
                                                  (_ringOffset.value.dx +
                                                          details.delta.dx)''');

  content = content.replaceAll('''                                              setState(() {
                                                _ringOffset = Offset(
                                                  newDx,
                                                  0.0,
                                                );
                                              });''', '''                                              _ringOffset.value = Offset(
                                                  newDx,
                                                  0.0,
                                                );''');

  content = content.replaceAll('onPanEnd: _isAnswered || _pendingTypeSubmit\n                                          ? null', 'onPanEnd: _isAnswered.value || _pendingTypeSubmit.value\n                                          ? null');
  
  content = content.replaceAll('''                                              setState(
                                                () => _ringOffset = Offset.zero,
                                              );''', '''                                              _ringOffset.value = Offset.zero;''');

  content = content.replaceAll('offset: _ringOffset,', 'offset: _ringOffset.value,');

  content = content.replaceAll('''        (_isAnswered || _pendingTypeSubmit) &&
        _isCorrect != false &&''', '''        (_isAnswered.value || _pendingTypeSubmit.value) &&
        _isCorrect.value != false &&''');
        
  content = content.replaceAll('final isWrong = _isAnswered && _isCorrect == false && index != correctIndex;', 'final isWrong = _isAnswered.value && _isCorrect.value == false && index != correctIndex;');

  content = content.replaceAll('''    final Color coreColor = (_isAnswered || _pendingTypeSubmit)
        ? (_isCorrect != false ? Colors.greenAccent : Colors.redAccent)''', '''    final Color coreColor = (_isAnswered.value || _pendingTypeSubmit.value)
        ? (_isCorrect.value != false ? Colors.greenAccent : Colors.redAccent)''');


  // Fix Sliver Layout
  content = content.replaceAll('''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingTypeSubmit && !_isAnswered && cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        displayText: "Type the complete sentence to lock in the rule",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        allowSkip: true,
                      ),
                    SizedBox(height: (_isAnswered || _pendingTypeSubmit) ? 160.h : 60.h),
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
                    if (_pendingTypeSubmit.value && !_isAnswered.value && cleanTargetSentence.isNotEmpty)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: cleanTargetSentence,
                          displayText: "Type the complete sentence to lock in the rule",
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitFinalAnswer(true),
                          onSkipped: () => _submitFinalAnswer(false),
                          allowSkip: true,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: (_isAnswered.value || _pendingTypeSubmit.value) ? 160.h : 60.h),
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
