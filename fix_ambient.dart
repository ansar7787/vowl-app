import 'dart:io';

void main() {
  final file = File('lib/features/listening/ambient_id/presentation/pages/ambient_id_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('int? _pendingSelectedIndex;', 'final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _radarController.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedIndex.dispose();\n    _pendingSelectedIndex.dispose();\n    super.dispose();\n  }');

  // Dispose block is added above, remove original
  content = content.replaceAll('''  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }''', '');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingSelectedIndex == null) return;', 'if (_isAnswered.value || _pendingSelectedIndex.value == null) return;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedIndex.value = _pendingSelectedIndex.value;''');

  content = content.replaceAll('bool isCorrect = _pendingSelectedIndex == correct;', 'bool isCorrect = _pendingSelectedIndex.value == correct;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _selectedIndex = _pendingSelectedIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;
      _selectedIndex.value = _pendingSelectedIndex.value;''');

  content = content.replaceAll('''          userAnswer: _pendingSelectedIndex.toString(),''', '''          userAnswer: _pendingSelectedIndex.value.toString(),''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _pendingSelectedIndex = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _pendingSelectedIndex.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _pendingSelectedIndex]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                              AmbientIdSonarField(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                radarController: _radarController,
                                isAnswered: _isAnswered,
                                isCorrectState: _isCorrect,
                                selectedIndex: _selectedIndex,
                                onSubmitAnswer: (index) {
                                  if (_isAnswered || _pendingSelectedIndex != null) return;
                                  setState(() {
                                    _pendingSelectedIndex = index;
                                  });
                                },
                                imageUrl: quest.imageUrl,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AmbientIdEmitterNode(
                                onTap: () {
                                  _soundService.playTts(
                                    quest.textToSpeak ?? "",
                                  );
                                  _hapticService.selection();
                                },
                                color: theme.primaryColor,
                              ),
                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pendingSelectedIndex != null && !_isAnswered)
                    SpeakToConfirmOverlay(
                      expectedText: quest.options![_pendingSelectedIndex!],
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(
                        true,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      onSkipped: () => _submitFinalAnswer(
                        false,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      allowSkip: true,
                    ),
                ],
              ),
        );
      },
    );
  }
}''', '''                              AmbientIdSonarField(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                radarController: _radarController,
                                isAnswered: _isAnswered.value,
                                isCorrectState: _isCorrect.value,
                                selectedIndex: _selectedIndex.value,
                                onSubmitAnswer: (index) {
                                  if (_isAnswered.value || _pendingSelectedIndex.value != null) return;
                                  _pendingSelectedIndex.value = index;
                                },
                                imageUrl: quest.imageUrl,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AmbientIdEmitterNode(
                                onTap: () {
                                  _soundService.playTts(
                                    quest.textToSpeak ?? "",
                                  );
                                  _hapticService.selection();
                                },
                                color: theme.primaryColor,
                              ),
                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pendingSelectedIndex.value != null && !_isAnswered.value)
                    SpeakToConfirmOverlay(
                      expectedText: quest.options![_pendingSelectedIndex.value!],
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(
                        true,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      onSkipped: () => _submitFinalAnswer(
                        false,
                        quest.correctAnswerIndex ?? 0,
                      ),
                      allowSkip: true,
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
