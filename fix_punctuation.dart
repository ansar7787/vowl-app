import 'dart:io';

void main() {
  final file = File('lib/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final Map<int, String> _placedStickers = {};', 'final ValueNotifier<Map<int, String>> _placedStickers = ValueNotifier({});');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingTyping = false;', 'final ValueNotifier<bool> _pendingTyping = ValueNotifier(false);');
  content = content.replaceAll('String? _assembledSentence;', 'final ValueNotifier<String?> _assembledSentence = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _placedStickers.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingTyping.dispose();\n    _assembledSentence.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingTyping) return;', 'if (_isAnswered.value || _pendingTyping.value) return;');

  content = content.replaceAll('''    setState(() => _placedStickers[index] = mark);''', '''    _placedStickers.value = Map.from(_placedStickers.value)..[index] = mark;''');

  content = content.replaceAll('if (_placedStickers.containsKey(i)) {', 'if (_placedStickers.value.containsKey(i)) {');
  content = content.replaceAll('result += _placedStickers[i]!;', 'result += _placedStickers.value[i]!;');

  content = content.replaceAll('''      setState(() {
        _assembledSentence = result;
        _pendingTyping = true;
      });''', '''      _assembledSentence.value = result;
      _pendingTyping.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _assembledSentence = result;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _assembledSentence.value = result;''');

  content = content.replaceAll('setState(() => _pendingTyping = false);', '_pendingTyping.value = false;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = correct;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingTyping = false;
              _placedStickers.clear();
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingTyping.value = false;
            _placedStickers.value = {};''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _placedStickers, _pendingTyping, _assembledSentence]),
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
  content = content.replaceAll('if (!_isAnswered && !_pendingTyping)', 'if (!_isAnswered.value && !_pendingTyping.value)');
  content = content.replaceAll('final mark = _placedStickers[slotIndex];', 'final mark = _placedStickers.value[slotIndex];');
  
  content = content.replaceAll('''                                setState(
                                  () => _placedStickers.remove(slotIndex),
                                );''', '''                                _placedStickers.value = Map.from(_placedStickers.value)..remove(slotIndex);''');

  // Fix Sliver Layout
  content = content.replaceAll('''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingTyping &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                      ),
                    SizedBox(height: (_isAnswered || _pendingTyping) ? 160.h : 60.h),
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
                    if (_pendingTyping.value &&
                        !_isAnswered.value &&
                        cleanTargetSentence.isNotEmpty)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: cleanTargetSentence,
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitFinalAnswer(true),
                          onSkipped: () => _submitFinalAnswer(false),
                          isPositioned: false,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: (_isAnswered.value || _pendingTyping.value) ? 160.h : 60.h),
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
