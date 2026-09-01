import 'dart:io';

void main() {
  final file = File('lib/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _scrubProgress = 0.0;', 'final ValueNotifier<double> _scrubProgress = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _timeVal = 0.0;', 'final ValueNotifier<double> _timeVal = ValueNotifier(0.0);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _shimmerController.dispose();
    _scrubProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addListener(() {
            setState(() {
              _timeVal = _shimmerController.value;
            });
          });''', '''    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addListener(() {
            _timeVal.value = _shimmerController.value;
          });''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;''');

  content = content.replaceAll('if (_isAnswered || _scrubProgress >= 1.0) return;', 'if (_isAnswered.value || _scrubProgress.value >= 1.0) return;');

  content = content.replaceAll('''    setState(() {
      _scrubProgress = (_scrubProgress + delta).clamp(0.0, 1.0);
      if (_scrubProgress > 0) _hapticService.selection();
      if (_scrubProgress >= 1.0) {
        _hapticService.success();
        _soundService.playCorrect();
      }
    });''', '''    _scrubProgress.value = (_scrubProgress.value + delta).clamp(0.0, 1.0);
    if (_scrubProgress.value > 0) _hapticService.selection();
    if (_scrubProgress.value >= 1.0) {
      _hapticService.success();
      _soundService.playCorrect();
    }''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _scrubProgress = 0.0;
              _timerKey.currentState?.start();
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _scrubProgress.value = 0.0;
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
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _scrubProgress, _timeVal]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                scrubProgress: _scrubProgress,
                                timeVal: _timeVal,''', '''                                scrubProgress: _scrubProgress.value,
                                timeVal: _timeVal.value,''');

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
                              if (!_isAnswered)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 24.h),
                                  child: SpeedChallengeTimer(
                                    key: _timerKey,
                                    durationSeconds: 20,
                                    primaryColor: theme.primaryColor,
                                    onTimeUp: () => _onTimeUp(quest.textToSpeak ?? ""),
                                    autoStart: true,
                                  ),
                                ),
                              if (!_isAnswered && _scrubProgress >= 1.0)
                                SpeakingSelfEvaluationControls(
                                  expectedText: quest.textToSpeak ?? "",
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () {
                                    _timerKey.currentState?.stop();
                                    _submitVerbalEvaluation(true, quest.textToSpeak ?? "");
                                  },
                                  onSkipped: () {
                                    _timerKey.currentState?.stop();
                                    _submitVerbalEvaluation(false, quest.textToSpeak ?? "");
                                  },
                                ),
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
                              if (!_isAnswered.value)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 24.h),
                                  child: SpeedChallengeTimer(
                                    key: _timerKey,
                                    durationSeconds: 20,
                                    primaryColor: theme.primaryColor,
                                    onTimeUp: () => _onTimeUp(quest.textToSpeak ?? ""),
                                    autoStart: true,
                                  ),
                                ),
                              if (!_isAnswered.value && _scrubProgress.value >= 1.0)
                                SpeakingSelfEvaluationControls(
                                  expectedText: quest.textToSpeak ?? "",
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () {
                                    _timerKey.currentState?.stop();
                                    _submitVerbalEvaluation(true, quest.textToSpeak ?? "");
                                  },
                                  onSkipped: () {
                                    _timerKey.currentState?.stop();
                                    _submitVerbalEvaluation(false, quest.textToSpeak ?? "");
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
