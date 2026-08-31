import 'dart:io';

void main() {
  final file = File('lib/features/grammar/tense_mastery/presentation/pages/tense_mastery_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _sliderValue = 0.5;', 'final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isDragging = false;', 'final ValueNotifier<bool> _isDragging = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingSubmit = false;', 'final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _sliderValue.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isDragging.dispose();\n    _pendingSubmit.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_sliderValue < 0.25) return "Past";', 'if (_sliderValue.value < 0.25) return "Past";');
  content = content.replaceAll('if (_sliderValue > 0.75) return "Future";', 'if (_sliderValue.value > 0.75) return "Future";');
  
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = true;
    });''', '''    _pendingSubmit.value = true;''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = false;
    });''', '''    _pendingSubmit.value = false;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingSubmit = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingSubmit.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: _isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _sliderValue, _isDragging, _pendingSubmit]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: _isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                            TenseMasteryTimelineSlider(
                              sliderValue: _sliderValue,
                              currentTense: _currentTense,
                              isAnswered: _isAnswered,
                              isDragging: _isDragging,''', '''                            TenseMasteryTimelineSlider(
                              sliderValue: _sliderValue.value,
                              currentTense: _currentTense,
                              isAnswered: _isAnswered.value,
                              isDragging: _isDragging.value,''');

  content = content.replaceAll('setState(() => _sliderValue = value),', '_sliderValue.value = value,');
  content = content.replaceAll('setState(() => _isDragging = value),', '_isDragging.value = value,');
  content = content.replaceAll('if (!_isAnswered)', 'if (!_isAnswered.value)');

  // Fix Sliver Layout
  content = content.replaceAll('''                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_pendingSubmit && !_isAnswered)
                            TypeToConfirmOverlay(
                              expectedText: quest.correctAnswer ?? quest.sentence ?? _currentTense,
                              displayText: "Type the complete sentence to lock in the timeline",
                              primaryColor: theme.primaryColor,
                              onConfirmed: () => _submitFinalAnswer(quest, true),
                              onSkipped: () => _submitFinalAnswer(quest, false),
                              isPositioned: false,
                              allowSkip: true,
                            ),
                          SizedBox(height: (_isAnswered || _pendingSubmit) ? 160.h : 60.h),
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
                    if (_pendingSubmit.value && !_isAnswered.value)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: quest.correctAnswer ?? quest.sentence ?? _currentTense,
                          displayText: "Type the complete sentence to lock in the timeline",
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitFinalAnswer(quest, true),
                          onSkipped: () => _submitFinalAnswer(quest, false),
                          isPositioned: false,
                          allowSkip: true,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: (_isAnswered.value || _pendingSubmit.value) ? 160.h : 60.h),
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
