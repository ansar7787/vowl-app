import 'dart:io';

void main() {
  final file = File('lib/features/reading/reading_speed_check/presentation/pages/reading_speed_check_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _pulseScale = 1.0;', 'final ValueNotifier<double> _pulseScale = ValueNotifier(1.0);');
  content = content.replaceAll('double _clarityRadius = 0.0;', 'final ValueNotifier<double> _clarityRadius = ValueNotifier(0.0);');
  content = content.replaceAll('int _timerValue = 12;', 'final ValueNotifier<int> _timerValue = ValueNotifier(12);');
  content = content.replaceAll('int _timeLimit = 12;', 'final ValueNotifier<int> _timeLimit = ValueNotifier(12);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isRevealed = false;', 'final ValueNotifier<bool> _isRevealed = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _pulseScale.dispose();\n    _clarityRadius.dispose();\n    _timerValue.dispose();\n    _timeLimit.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isRevealed.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _isRevealed) return;', 'if (_isAnswered.value || _isRevealed.value) return;');

  content = content.replaceAll('''    setState(() {
      _pulseScale = 1.4;
      _clarityRadius = 1.0;
      _hapticService.selection();
    });''', '''    _pulseScale.value = 1.4;
    _clarityRadius.value = 1.0;
    _hapticService.selection();''');

  content = content.replaceAll('''      if (mounted) {
        setState(() => _pulseScale = 1.0);
      }''', '''      if (mounted) {
        _pulseScale.value = 1.0;
      }''');

  content = content.replaceAll('''      if (mounted && !_isAnswered && !_isRevealed) {
        setState(() => _clarityRadius = 0.0);
      }''', '''      if (mounted && !_isAnswered.value && !_isRevealed.value) {
        _clarityRadius.value = 0.0;
      }''');

  content = content.replaceAll('''    setState(() {
      _isRevealed = true;
      _clarityRadius = 0.0;
    });''', '''    _isRevealed.value = true;
    _clarityRadius.value = 0.0;''');

  content = content.replaceAll('''    setState(() {
      _timerValue = remaining;
    });''', '''    _timerValue.value = remaining;''');

  content = content.replaceAll('if (_isAnswered || !_isRevealed) return;', 'if (_isAnswered.value || !_isRevealed.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isCorrect;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isRevealed = false;
              _clarityRadius = 0.0;
              _timeLimit = state.currentQuest.timeLimit ?? 12;
              _timerValue = _timeLimit;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isRevealed.value = false;
            _clarityRadius.value = 0.0;
            _timeLimit.value = state.currentQuest.timeLimit ?? 12;
            _timerValue.value = _timeLimit.value;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isRevealed, _pulseScale, _clarityRadius, _timerValue, _timeLimit]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                              isRevealed: _isRevealed,''', '''                              isRevealed: _isRevealed.value,''');
  content = content.replaceAll('''                            if (!_isRevealed)''', '''                            if (!_isRevealed.value)''');
  content = content.replaceAll('''                            if (_isRevealed)''', '''                            if (_isRevealed.value)''');
  
  content = content.replaceAll('''                                  durationSeconds: _timeLimit,''', '''                                  durationSeconds: _timeLimit.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isRevealed)
                              ReadingSpeedPulseZone(
                                passage: quest.passage ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                                clarityRadius: _clarityRadius,
                                pulseScale: _pulseScale,
                                timerValue: _timerValue,
                                timeLimit: _timeLimit,
                                wordCount: quest.passageWordCount ?? quest.passage?.split(RegExp(r'\\s+')).length ?? 0,
                                wpmTarget: quest.wpmTarget ?? 0,
                                onTapPulse: _onPulseTap,
                              )
                            else ...[
                              SizedBox(height: 32.h),
                              ReadingSelfEvaluationCard(
                                correctAnswer: quest.correctAnswer ?? "",
                                explanation: quest.explanation,
                                primaryColor: theme.primaryColor,
                                onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                              ),
                            ],
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ReadingSpeedResult(
                                quest: quest,
                                isCorrect: _isCorrect == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}''', '''                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isRevealed.value)
                              ReadingSpeedPulseZone(
                                passage: quest.passage ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                                clarityRadius: _clarityRadius.value,
                                pulseScale: _pulseScale.value,
                                timerValue: _timerValue.value,
                                timeLimit: _timeLimit.value,
                                wordCount: quest.passageWordCount ?? quest.passage?.split(RegExp(r'\\s+')).length ?? 0,
                                wpmTarget: quest.wpmTarget ?? 0,
                                onTapPulse: _onPulseTap,
                              )
                            else ...[
                              SizedBox(height: 32.h),
                              ReadingSelfEvaluationCard(
                                correctAnswer: quest.correctAnswer ?? "",
                                explanation: quest.explanation,
                                primaryColor: theme.primaryColor,
                                onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                              ),
                            ],
                            if (_isAnswered.value) ...[
                              SizedBox(height: 30.h),
                              ReadingSpeedResult(
                                quest: quest,
                                isCorrect: _isCorrect.value == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
