import 'dart:io';

void main() {
  final file = File('lib/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _pullProgress = 0.0;', 'final ValueNotifier<double> _pullProgress = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _timeVal = 0.0;', 'final ValueNotifier<double> _timeVal = ValueNotifier(0.0);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _sparkController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _sparkController.dispose();
    _pullProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    _sparkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            setState(() {
              _timeVal = _sparkController.value;
            });
          });''', '''    _sparkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _timeVal.value = _sparkController.value;
          });''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
      _pullProgress = nailedIt ? 1.0 : 0.0;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    _pullProgress.value = nailedIt ? 1.0 : 0.0;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _pullProgress = 1.0;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;
    _pullProgress.value = 1.0;''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pullProgress = 0.0;
              _timerKey.currentState?.start();
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pullProgress.value = 0.0;
            _timerKey.currentState?.start();''');

  content = content.replaceAll('''            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });''', '''            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            } else {
              _isAnswered.value = false;
            }''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _pullProgress, _timeVal]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                pullProgress: _pullProgress,
                                primaryColor: theme.primaryColor,
                                isListening: false,
                                timeVal: _timeVal,''', '''                                pullProgress: _pullProgress.value,
                                primaryColor: theme.primaryColor,
                                isListening: false,
                                timeVal: _timeVal.value,''');

  content = content.replaceAll('''                                pullProgress: _pullProgress,''', '''                                pullProgress: _pullProgress.value,''');

  // Fix brackets at bottom
  content = content.replaceAll('''                  ),
          ),
        );
      },
    );
  }
}''', '''                  ),
              );
            },
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered) ...[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 24.h),
                                  child: SpeedChallengeTimer(
                                    key: _timerKey,
                                    durationSeconds: 30,
                                    primaryColor: theme.primaryColor,
                                    onTimeUp: () => _onTimeUp(expectedText),
                                    autoStart: true,
                                  ),
                                ),
                                SpeakingSelfEvaluationControls(
                                  expectedText: expectedText,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true, expectedText),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false, expectedText),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),''', '''                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered.value) ...[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 24.h),
                                  child: SpeedChallengeTimer(
                                    key: _timerKey,
                                    durationSeconds: 30,
                                    primaryColor: theme.primaryColor,
                                    onTimeUp: () => _onTimeUp(expectedText),
                                    autoStart: true,
                                  ),
                                ),
                                SpeakingSelfEvaluationControls(
                                  expectedText: expectedText,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true, expectedText),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false, expectedText),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
