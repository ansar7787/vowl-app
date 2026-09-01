import 'dart:io';

void main() {
  final file = File('lib/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('List<String> _dynamicOptions = [];', 'final ValueNotifier<List<String>> _dynamicOptions = ValueNotifier([]);');
  content = content.replaceAll('String? _selectedWord;', 'final ValueNotifier<String?> _selectedWord = ValueNotifier(null);');
  content = content.replaceAll('double _pullForce = 0.0;', 'final ValueNotifier<double> _pullForce = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isListening = false;', 'final ValueNotifier<bool> _isListening = ValueNotifier(false);');
  content = content.replaceAll('bool _isWordPlaced = false;', 'final ValueNotifier<bool> _isWordPlaced = ValueNotifier(false);');
  
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _vortexController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _vortexController.dispose();
    _dynamicOptions.dispose();
    _selectedWord.dispose();
    _pullForce.dispose();
    _isListening.dispose();
    _isWordPlaced.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    _dynamicOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    _dynamicOptions.shuffle(math.Random(widget.level));''', '''    final newOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    newOptions.shuffle(math.Random(widget.level));
    _dynamicOptions.value = newOptions;''');

  content = content.replaceAll('if (_isAnswered || _isWordPlaced) return;', 'if (_isAnswered.value || _isWordPlaced.value) return;');

  content = content.replaceAll('''    setState(() {
      _selectedWord = word;
      _isListening = true;
    });''', '''    _selectedWord.value = word;
    _isListening.value = true;''');

  content = content.replaceAll('''    setState(() {
      _isListening = false;
    });''', '''    _isListening.value = false;''');

  content = content.replaceAll('''    if (_pullForce >= 1.0) {
      _hapticService.success();
      _soundService.playClick();
      setState(() {
        _isWordPlaced = true;
      });
    } else {
      setState(() {
        _pullForce = 0.0;
        _selectedWord = null;
      });
    }''', '''    if (_pullForce.value >= 1.0) {
      _hapticService.success();
      _soundService.playClick();
      _isWordPlaced.value = true;
    } else {
      _pullForce.value = 0.0;
      _selectedWord.value = null;
    }''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''        _selectedWord?.toLowerCase() == expectedWord.toLowerCase();''', '''        _selectedWord.value?.toLowerCase() == expectedWord.toLowerCase();''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isOverallCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isOverallCorrect;''');

  content = content.replaceAll('''          userAnswer: _selectedWord ?? '[None]',''', '''          userAnswer: _selectedWord.value ?? '[None]',''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;''');

  content = content.replaceAll('if (_isListening && _pullForce < 1.0)', 'if (_isListening.value && _pullForce.value < 1.0)');

  content = content.replaceAll('''      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted && _isListening) {
          setState(() {
            _pullForce = (_pullForce + 0.045).clamp(0.0, 1.0);
            _hapticService.selection();
          });
        }
      });''', '''      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted && _isListening.value) {
          _pullForce.value = (_pullForce.value + 0.045).clamp(0.0, 1.0);
          _hapticService.selection();
        }
      });''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _pullForce = 0.0;
              _selectedWord = null;
              _isWordPlaced = false;
              _generateDynamicOptions(
                state.currentQuest.missingWord ?? "drone",
              );
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isListening.value = false;
            _pullForce.value = 0.0;
            _selectedWord.value = null;
            _isWordPlaced.value = false;
            _generateDynamicOptions(
              state.currentQuest.missingWord ?? "drone",
            );''');

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

  content = content.replaceAll('''          if (state.isLetterRevealed && _dynamicOptions.length > 1) {
            final correctWord =
                state.currentQuest.missingWord?.toLowerCase() ?? "";
            if (_dynamicOptions.contains(correctWord)) {
              setState(() {
                _dynamicOptions = [correctWord];
              });
            }
          }''', '''          if (state.isLetterRevealed && _dynamicOptions.value.length > 1) {
            final correctWord =
                state.currentQuest.missingWord?.toLowerCase() ?? "";
            if (_dynamicOptions.value.contains(correctWord)) {
              _dynamicOptions.value = [correctWord];
            }
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
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dynamicOptions, _selectedWord, _pullForce, _isWordPlaced, _isListening]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                isWordPlaced: _isWordPlaced,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              SpeakMissingWordVortexSentence(
                                text: _isWordPlaced
                                    ? completedSentence
                                    : initialBlankSentence,
                                insertedWord: _isWordPlaced
                                    ? (_selectedWord ?? "")
                                    : "",''', '''                                isWordPlaced: _isWordPlaced.value,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              SpeakMissingWordVortexSentence(
                                text: _isWordPlaced.value
                                    ? completedSentence
                                    : initialBlankSentence,
                                insertedWord: _isWordPlaced.value
                                    ? (_selectedWord.value ?? "")
                                    : "",''');

  content = content.replaceAll('''                              if (!_isWordPlaced)
                                SpeakMissingWordMagnetArena(
                                  dynamicOptions: _dynamicOptions,
                                  selectedWord: _selectedWord,
                                  pullForce: _pullForce,''', '''                              if (!_isWordPlaced.value)
                                SpeakMissingWordMagnetArena(
                                  dynamicOptions: _dynamicOptions.value,
                                  selectedWord: _selectedWord.value,
                                  pullForce: _pullForce.value,''');

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
                              if (_isWordPlaced && !_isAnswered)
                                SpeakingSelfEvaluationControls(
                                  expectedText: completedSentence,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        missingWord,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        missingWord,
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
                              if (_isWordPlaced.value && !_isAnswered.value)
                                SpeakingSelfEvaluationControls(
                                  expectedText: completedSentence,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        missingWord,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        missingWord,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
