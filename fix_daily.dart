import 'dart:io';

void main() {
  final file = File('lib/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _scratchProgress = 0.0;', 'final ValueNotifier<double> _scratchProgress = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _timeVal = 0.0;', 'final ValueNotifier<double> _timeVal = ValueNotifier(0.0);');
  
  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _glowController.dispose();
    _scratchProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            setState(() {
              _timeVal = _glowController.value;
            });
          });''', '''    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            _timeVal.value = _glowController.value;
          });''');

  content = content.replaceAll('if (_scratchProgress >= 1.0) return;', 'if (_scratchProgress.value >= 1.0) return;');

  content = content.replaceAll('''    setState(() {
      _scratchProgress += delta;
      if (_scratchProgress >= 0.85) {
        _scratchProgress = 1.0;
        _hapticService.selection();
        _soundService.playTts(_targetExpression);
      }
    });''', '''    _scratchProgress.value += delta;
    if (_scratchProgress.value >= 0.85) {
      _scratchProgress.value = 1.0;
      _hapticService.selection();
      _soundService.playTts(_targetExpression);
    }''');

  content = content.replaceAll('if (_isAnswered || _scratchProgress < 1.0) return;', 'if (_isAnswered.value || _scratchProgress.value < 1.0) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _scratchProgress = 1.0;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;
    _scratchProgress.value = 1.0;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _scratchProgress = 0.0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _scratchProgress.value = 0.0;''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isCorrect = false;
              _isAnswered = true;
            });''', '''            _isCorrect.value = false;
            _isAnswered.value = true;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _scratchProgress, _timeVal]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                scratchProgress: _scratchProgress,''', '''                                scratchProgress: _scratchProgress.value,''');
  content = content.replaceAll('''                                timeVal: _timeVal,''', '''                                timeVal: _timeVal.value,''');
  content = content.replaceAll('''                              if (_scratchProgress > 0.3)''', '''                              if (_scratchProgress.value > 0.3)''');
  content = content.replaceAll('''                              if (!_isAnswered && _scratchProgress >= 1.0)''', '''                              if (!_isAnswered.value && _scratchProgress.value >= 1.0)''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                  );
                  },
                ),
          ),
        );
      },
    );
  }
}''', '''                  );
                  },
                ),
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
                              if (!_isAnswered.value && _scratchProgress.value >= 1.0)
                                SpeakToConfirmOverlay(
                                  expectedText: _targetExpression,
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
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
                              if (!_isAnswered.value && _scratchProgress.value >= 1.0)
                                SpeakToConfirmOverlay(
                                  expectedText: _targetExpression,
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
