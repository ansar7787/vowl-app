import 'dart:io';

void main() {
  final file = File('lib/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _tiltValue = 0.0;', 'final ValueNotifier<double> _tiltValue = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isSnapped = false;', 'final ValueNotifier<bool> _isSnapped = ValueNotifier(false);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _autoplayTimer?.cancel();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _tiltValue.dispose();
    _isSnapped.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('if (_isAnswered || _isSnapped) return;', 'if (_isAnswered.value || _isSnapped.value) return;');

  content = content.replaceAll('''    setState(() {
      _tiltValue = (_tiltValue + deltaNormalized).clamp(-1.0, 1.0);

      if (_tiltValue <= -0.85) {
        _tiltValue = -1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      } else if (_tiltValue >= 0.85) {
        _tiltValue = 1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      }
    });''', '''    _tiltValue.value = (_tiltValue.value + deltaNormalized).clamp(-1.0, 1.0);

    if (_tiltValue.value <= -0.85) {
      _tiltValue.value = -1.0;
      _isSnapped.value = true;
      _soundService.playClick();
      _hapticService.selection();
    } else if (_tiltValue.value >= 0.85) {
      _tiltValue.value = 1.0;
      _isSnapped.value = true;
      _soundService.playClick();
      _hapticService.selection();
    }''');

  content = content.replaceAll('if (_isAnswered || !_isSnapped) return;', 'if (_isAnswered.value || !_isSnapped.value) return;');

  content = content.replaceAll('final bool chosenMatch = _tiltValue > 0;', 'final bool chosenMatch = _tiltValue.value > 0;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isOverallCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isOverallCorrect;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isSnapped = false;
              _tiltValue = 0.0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isSnapped.value = false;
            _tiltValue.value = 0.0;''');

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

  content = content.replaceAll('''                                  if (!_isSnapped) {
                                    setState(() => _tiltValue = 0.0);
                                  }''', '''                                  if (!_isSnapped.value) {
                                    _tiltValue.value = 0.0;
                                  }''');

  // Builder Wrap
  content = content.replaceAll('''          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isSnapped, _tiltValue]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                isSnapped: _isSnapped,''', '''                                isSnapped: _isSnapped.value,''');
  content = content.replaceAll('''                                tiltValue: _tiltValue,''', '''                                tiltValue: _tiltValue.value,''');
  content = content.replaceAll('''                              if (_isSnapped && !_isAnswered)''', '''                              if (_isSnapped.value && !_isAnswered.value)''');

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
                              if (_isSnapped.value && !_isAnswered.value)
                                TypeToConfirmOverlay(
                                  expectedText: quest.sampleAnswer ?? "",
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        doTheyMatch,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        doTheyMatch,
                                      ),
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
                              if (_isSnapped.value && !_isAnswered.value)
                                TypeToConfirmOverlay(
                                  expectedText: quest.sampleAnswer ?? "",
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        doTheyMatch,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        doTheyMatch,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
