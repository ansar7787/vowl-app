import 'dart:io';

void main() {
  final file = File('lib/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('double _rotation = 0.0;', 'final ValueNotifier<double> _rotation = ValueNotifier(0.0);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedIndex.dispose();\n    _rotation.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('setState(() => _selectedIndex = index);', '_selectedIndex.value = index;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _rotation = 0.0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _rotation.value = 0.0;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                        if (!_isAnswered) {
                                          setState(() {
                                            _rotation += delta * 0.01;
                                          });
                                        }''', '''                                        if (!_isAnswered.value) {
                                          _rotation.value += delta * 0.01;
                                        }''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _rotation]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                if (_isAnswered && quest.audioTranscript != null)''', '''                                if (_isAnswered.value && quest.audioTranscript != null)''');

  content = content.replaceAll('''                                      rotation: _rotation,
                                      selectedIndex: _selectedIndex,
                                      isAnswered: _isAnswered,
                                      isCorrectState: _isCorrect,''', '''                                      rotation: _rotation.value,
                                      selectedIndex: _selectedIndex.value,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                    ),
                  ],
                ),
        );
      },
    );
  }
}''', '''                    ),
                  ],
                ),
            );
          },
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isAnswered.value && quest.audioTranscript != null)
                                  SizedBox(
                                    height: 350.h,
                                    child: EvidenceHighlightWrapper(
                                      passage: quest.audioTranscript!,
                                      evidenceWords: [quest.correctAnswer ?? quest.options?[quest.correctAnswerIndex ?? 0] ?? ''],
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onCorrectHighlight: () {},
                                      onWrongHighlight: () {
                                        final authState = context.read<AuthBloc>().state;
                                        if (authState.status == AuthStatus.authenticated && authState.user != null) {
                                          ErrorJournalCollector.record(
                                            userId: authState.user!.id,
                                            gameType: widget.gameType.name,
                                            question: 'Evidence Highlight',
                                            userAnswer: '[Wrong evidence tap]',
                                            correctAnswer: quest.correctAnswer ?? '',
                                            level: widget.level,
                                          );
                                        }
                                      },
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 350.h,
                                    child: AudioMultipleChoiceSpinner(
                                      options: quest.options ?? [],
                                      correct: quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      tts: quest.textToSpeak ?? "",
                                      emoji: quest.emoji,
                                      rotation: _rotation.value,
                                      selectedIndex: _selectedIndex.value,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,
                                      onSpin: (delta) {
                                        if (!_isAnswered.value) {
                                          _rotation.value += delta * 0.01;
                                        }
                                      },
                                      onSelectSatellite: (index) {
                                        _submitFinalAnswer(
                                          index,
                                          quest.correctAnswerIndex ?? 0,
                                        );
                                      },
                                      onTapCore: () {
                                        _soundService.playTts(
                                          quest.textToSpeak ?? "",
                                        );
                                        _hapticService.selection();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),''', '''                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isAnswered.value && quest.audioTranscript != null)
                                  SizedBox(
                                    height: 350.h,
                                    child: EvidenceHighlightWrapper(
                                      passage: quest.audioTranscript!,
                                      evidenceWords: [quest.correctAnswer ?? quest.options?[quest.correctAnswerIndex ?? 0] ?? ''],
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onCorrectHighlight: () {},
                                      onWrongHighlight: () {
                                        final authState = context.read<AuthBloc>().state;
                                        if (authState.status == AuthStatus.authenticated && authState.user != null) {
                                          ErrorJournalCollector.record(
                                            userId: authState.user!.id,
                                            gameType: widget.gameType.name,
                                            question: 'Evidence Highlight',
                                            userAnswer: '[Wrong evidence tap]',
                                            correctAnswer: quest.correctAnswer ?? '',
                                            level: widget.level,
                                          );
                                        }
                                      },
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 350.h,
                                    child: AudioMultipleChoiceSpinner(
                                      options: quest.options ?? [],
                                      correct: quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      tts: quest.textToSpeak ?? "",
                                      emoji: quest.emoji,
                                      rotation: _rotation.value,
                                      selectedIndex: _selectedIndex.value,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,
                                      onSpin: (delta) {
                                        if (!_isAnswered.value) {
                                          _rotation.value += delta * 0.01;
                                        }
                                      },
                                      onSelectSatellite: (index) {
                                        _submitFinalAnswer(
                                          index,
                                          quest.correctAnswerIndex ?? 0,
                                        );
                                      },
                                      onTapCore: () {
                                        _soundService.playTts(
                                          quest.textToSpeak ?? "",
                                        );
                                        _hapticService.selection();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
