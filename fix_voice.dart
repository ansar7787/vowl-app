import 'dart:io';

void main() {
  final file = File('lib/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isPassive = false;', 'final ValueNotifier<bool> _isPassive = ValueNotifier(false);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _isPassive.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isFirstStagePassed.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _isFirstStagePassed || quest == null) return;', 'if (_isAnswered.value || _isFirstStagePassed.value || quest == null) return;');

  content = content.replaceAll('final selectedVoice = _isPassive ? "Passive" : "Active";', 'final selectedVoice = _isPassive.value ? "Passive" : "Active";');

  content = content.replaceAll('''      setState(() {
        _isFirstStagePassed = true;
      });''', '''      _isFirstStagePassed.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('if (_isPassive) {', 'if (_isPassive.value) {');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isPassive, _isFirstStagePassed]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                            VoiceSwapToggle(
                              isPassive: _isPassive,
                              isAnswered: _isAnswered,''', '''                            VoiceSwapToggle(
                              isPassive: _isPassive.value,
                              isAnswered: _isAnswered.value,''');

  content = content.replaceAll('setState(() => _isPassive = val),', '_isPassive.value = val,');
  content = content.replaceAll('if (_isAnswered) ...[', 'if (_isAnswered.value) ...[');
  content = content.replaceAll('if (!_isAnswered)', 'if (!_isAnswered.value)');

  // Fix Sliver Layout
  content = content.replaceAll('''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_isFirstStagePassed && !_isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: expectedConversion,
                        displayText: "Type the \$targetVoiceStr conversion to lock it in",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitVerbalEvaluation(true),
                        onSkipped: () => _submitVerbalEvaluation(false),
                        isPositioned: false,
                      ),
                    SizedBox(height: _isAnswered ? 160.h : 60.h),
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
  }
}''', '''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
                    if (_isFirstStagePassed.value && !_isAnswered.value)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: expectedConversion,
                          displayText: "Type the \$targetVoiceStr conversion to lock it in",
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitVerbalEvaluation(true),
                          onSkipped: () => _submitVerbalEvaluation(false),
                          isPositioned: false,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: _isAnswered.value ? 160.h : 60.h),
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
  }
}''');

  content = content.replaceAll('final bool correct = _isCorrect == true;', 'final bool correct = _isCorrect.value == true;');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
