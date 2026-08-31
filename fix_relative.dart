import 'dart:io';

void main() {
  final file = File('lib/features/grammar/relative_clauses/presentation/pages/relative_clauses_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('Offset? _hookPoint;', 'final ValueNotifier<Offset?> _hookPoint = ValueNotifier(null);');
  content = content.replaceAll('int _targetFish = -1;', 'final ValueNotifier<int> _targetFish = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _hookPoint.dispose();\n    _targetFish.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingJigsaw) return;', 'if (_isAnswered.value || _pendingJigsaw.value) return;');

  content = content.replaceAll('''      setState(() {
        _targetFish = fishIndex;
        _pendingJigsaw = true;
      });''', '''      _targetFish.value = fishIndex;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetFish = fishIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetFish.value = fishIndex;''');

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
              _targetFish = -1;
              _pendingJigsaw = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _targetFish.value = -1;
            _pendingJigsaw.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('if (sentence.contains("___") && _targetFish != -1)', 'if (sentence.contains("___") && _targetFish.value != -1)');
  content = content.replaceAll('fishOptions[_targetFish]', 'fishOptions[_targetFish.value]');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _targetFish, _pendingJigsaw, _hookPoint]),
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
  
  content = content.replaceAll('''            setState(() {
              _hookPoint = details.localPosition;
              if (details.localPosition.dy.toInt() % 10 == 0) {
                _hapticService.selection();
              }
            });''', '''            _hookPoint.value = details.localPosition;
            if (details.localPosition.dy.toInt() % 10 == 0) {
              _hapticService.selection();
            }''');

  content = content.replaceAll('onPanEnd: (_) => setState(() => _hookPoint = null),', 'onPanEnd: (_) => _hookPoint.value = null,');
  content = content.replaceAll('(_isAnswered || _pendingJigsaw) &&\n                                                  _targetFish != -1', '(_isAnswered.value || _pendingJigsaw.value) &&\n                                                  _targetFish.value != -1');

  // _buildQuantumArena parameters
  content = content.replaceAll('hookPoint: _hookPoint,', 'hookPoint: _hookPoint.value,');
  content = content.replaceAll('isAnswered: _isAnswered || _pendingJigsaw,', 'isAnswered: _isAnswered.value || _pendingJigsaw.value,');
  content = content.replaceAll('isCorrect: _isCorrect,', 'isCorrect: _isCorrect.value,');
  content = content.replaceAll('targetNode: _targetFish,', 'targetNode: _targetFish.value,');

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
