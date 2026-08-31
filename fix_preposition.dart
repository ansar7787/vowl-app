import 'dart:io';

void main() {
  final file = File('lib/features/grammar/preposition_choice/presentation/pages/preposition_choice_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('List<Offset> _points = [];', 'final ValueNotifier<List<Offset>> _points = ValueNotifier([]);');
  content = content.replaceAll('int _targetNode = -1;', 'final ValueNotifier<int> _targetNode = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _points.dispose();\n    _targetNode.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingJigsaw) return;', 'if (_isAnswered.value || _pendingJigsaw.value) return;');

  content = content.replaceAll('''      setState(() {
        _targetNode = nodeIndex;
        _pendingJigsaw = true;
      });''', '''      _targetNode.value = nodeIndex;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetNode = nodeIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetNode.value = nodeIndex;''');

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
              _targetNode = -1;
              _pendingJigsaw = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _targetNode.value = -1;
            _pendingJigsaw.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('if (sentence.contains("___") && _targetNode != -1)', 'if (sentence.contains("___") && _targetNode.value != -1)');
  content = content.replaceAll('options[_targetNode]', 'options[_targetNode.value]');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _targetNode, _pendingJigsaw, _points]),
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
  content = content.replaceAll('isAnswered: _isAnswered || _pendingJigsaw,', 'isAnswered: _isAnswered.value || _pendingJigsaw.value,');
  content = content.replaceAll('(_isAnswered || _pendingJigsaw) &&\n                                                  _targetNode != -1', '(_isAnswered.value || _pendingJigsaw.value) &&\n                                                  _targetNode.value != -1');
  
  // _buildPathCanvas parameters
  content = content.replaceAll('''            setState(() {
              _points.add(details.localPosition);
            });''', '''            _points.value = List.from(_points.value)..add(details.localPosition);''');

  content = content.replaceAll('onPanEnd: (_) => setState(() => _points = []),', 'onPanEnd: (_) => _points.value = [],');
  content = content.replaceAll('points: _points,', 'points: _points.value,');
  content = content.replaceAll('targetNode: _targetNode,', 'targetNode: _targetNode.value,');

  // Fix Sliver Layout
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
                        displayText: "Type the full sentence to lock it in",
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
                          displayText: "Type the full sentence to lock it in",
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
