import 'dart:io';

void main() {
  final file = File('lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _rotation = 0.0;', 'final ValueNotifier<double> _rotation = ValueNotifier(0.0);');
  content = content.replaceAll('int _targetIndex = -1;', 'final ValueNotifier<int> _targetIndex = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingJigsaw = false;', 'final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _rotation.dispose();\n    _targetIndex.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingJigsaw.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingJigsaw) return;', 'if (_isAnswered.value || _pendingJigsaw.value) return;');

  content = content.replaceAll('''      setState(() {
        _targetIndex = nodeIndex;
        _pendingJigsaw = true;
      });''', '''      _targetIndex.value = nodeIndex;
      _pendingJigsaw.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetIndex = nodeIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _targetIndex.value = nodeIndex;''');

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
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _targetIndex.value = -1;
            _pendingJigsaw.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('} else if (_targetIndex != -1) {', '} else if (_targetIndex.value != -1) {');
  content = content.replaceAll('cleanTargetSentence = options[_targetIndex];', 'cleanTargetSentence = options[_targetIndex.value];');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _targetIndex, _pendingJigsaw, _rotation]),
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
              _rotation = atan2(
                localPos.dy - centerPoint.dy,
                localPos.dx - centerPoint.dx,
              );
            });''', '''            _rotation.value = atan2(
              localPos.dy - centerPoint.dy,
              localPos.dx - centerPoint.dx,
            );''');

  content = content.replaceAll('if ((_rotation - nodeAngle).abs() < 0.15)', 'if ((_rotation.value - nodeAngle).abs() < 0.15)');

  // _buildGravityWell parameters
  content = content.replaceAll('rotation: _rotation,', 'rotation: _rotation.value,');
  content = content.replaceAll('isAnswered: _isAnswered || _pendingJigsaw,', 'isAnswered: _isAnswered.value || _pendingJigsaw.value,');
  content = content.replaceAll('isCorrect: _isCorrect ?? false,', 'isCorrect: _isCorrect.value ?? false,');
  content = content.replaceAll('targetNode: _targetIndex,', 'targetNode: _targetIndex.value,');

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
                        displayText: "Type the resolved sentence to lock it in",
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
                          displayText: "Type the resolved sentence to lock it in",
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
