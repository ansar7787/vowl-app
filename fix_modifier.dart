import 'dart:io';

void main() {
  final file = File('lib/features/grammar/modifier_placement/presentation/pages/modifier_placement_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('int _targetIndex = -1;', 'final ValueNotifier<int> _targetIndex = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);');
  content = content.replaceAll('String? _assembledSentence;', 'final ValueNotifier<String?> _assembledSentence = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _targetIndex.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    _assembledSentence.dispose();\n    super.dispose();\n  }');

  // Usages in logic
  content = content.replaceAll('if (_isAnswered || _targetIndex == -1 || _pendingJigsaw) return;', 'if (_isAnswered.value || _targetIndex.value == -1 || _pendingJigsaw.value) return;');
  content = content.replaceAll('resultingWords.insert(_targetIndex, modifier);', 'resultingWords.insert(_targetIndex.value, modifier);');
  
  content = content.replaceAll('''      setState(() {
        _assembledSentence = result;
        _pendingJigsaw = true;
      });''', '''      _assembledSentence.value = result;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _assembledSentence = result;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _assembledSentence.value = result;''');

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
              _targetIndex = -1;
              _pendingJigsaw = false;
              _assembledSentence = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _targetIndex.value = -1;
            _pendingJigsaw.value = false;
            _assembledSentence.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('} else if (_assembledSentence != null) {', '} else if (_assembledSentence.value != null) {');
  content = content.replaceAll('cleanTargetSentence = _assembledSentence!;', 'cleanTargetSentence = _assembledSentence.value!;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _targetIndex, _pendingJigsaw, _assembledSentence]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('if (_isAnswered) ...[', 'if (_isAnswered.value) ...[');
  content = content.replaceAll('targetIndex: _targetIndex,', 'targetIndex: _targetIndex.value,');
  content = content.replaceAll('isAnswered: _isAnswered || _pendingJigsaw,', 'isAnswered: _isAnswered.value || _pendingJigsaw.value,');
  content = content.replaceAll('setState(() => _targetIndex = idx),', '_targetIndex.value = idx,');
  content = content.replaceAll('setState(() => _targetIndex = -1),', '_targetIndex.value = -1,');
  content = content.replaceAll('if (!_isAnswered &&\n                                !_pendingJigsaw &&\n                                _targetIndex == -1)', 'if (!_isAnswered.value &&\n                                !_pendingJigsaw.value &&\n                                _targetIndex.value == -1)');
  content = content.replaceAll('if (!_isAnswered &&\n                                !_pendingJigsaw &&\n                                _targetIndex != -1)', 'if (!_isAnswered.value &&\n                                !_pendingJigsaw.value &&\n                                _targetIndex.value != -1)');
  
  // Sliver Layout Fix
  content = content.replaceAll('''                            SizedBox(height: gapBottom),
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
                        displayText: "Type the complete sentence to lock it in",
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
  }''', '''                            SizedBox(height: gapBottom),
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
                          displayText: "Type the complete sentence to lock it in",
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
