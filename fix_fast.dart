import 'dart:io';

void main() {
  final file = File('lib/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('int? _pendingSelectedIndex;', 'final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedIndex.dispose();\n    _pendingSelectedIndex.dispose();\n    _dialRotation.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('''  @override
  void dispose() {
    _dialRotation.dispose();
    super.dispose();
  }''', '');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('if (_isAnswered || _pendingSelectedIndex == null) return;', 'if (_isAnswered.value || _pendingSelectedIndex.value == null) return;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _selectedIndex.value = _pendingSelectedIndex.value;''');

  content = content.replaceAll('''bool isCorrect = _pendingSelectedIndex == correct;''', '''bool isCorrect = _pendingSelectedIndex.value == correct;''');

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
              _dialRotation.value = 0.33;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _pendingSelectedIndex.value = null;
            _dialRotation.value = 0.33;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                  if (_isAnswered || _pendingSelectedIndex != null) return;
                                  setState(() {
                                    _pendingSelectedIndex = index;
                                  });''', '''                                  if (_isAnswered.value || _pendingSelectedIndex.value != null) return;
                                  _pendingSelectedIndex.value = index;''');

  // ListenableBuilder Wrap (Combine existing builder with the global one)
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _pendingSelectedIndex, _dialRotation]),
          builder: (context, _) {
            double rotation = _dialRotation.value;
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Remove the old ValueListenableBuilder entirely and fix indentation
  content = content.replaceAll('''                              ValueListenableBuilder<double>(
                                valueListenable: _dialRotation,
                                builder: (context, rotation, _) {
                                  double speed = 0.3 + (rotation * 0.6);
                                  return Column(
                                    children: [
                                      FastSpeechDecoderGauges(
                                        speed: speed * 2,
                                        color: theme.primaryColor,
                                      ),
                                      SizedBox(height: 20.h),
                                      FastSpeechDecoderCore(
                                        textToSpeak: quest.textToSpeak ?? "",
                                        speed: speed,
                                        color: theme.primaryColor,
                                        rotation: rotation,
                                        onRotate: _onRotate,
                                        onTapTts: () {
                                          _soundService.playTts(
                                            quest.textToSpeak ?? "",
                                            speed: speed,
                                          );
                                          _hapticService.selection();
                                        },
                                        emoji: quest.emoji,
                                        isCorrectState: _isCorrect,
                                      ),
                                    ],
                                  );
                                },
                              ),''', '''                              (() {
                                double speed = 0.3 + (rotation * 0.6);
                                return Column(
                                  children: [
                                    FastSpeechDecoderGauges(
                                      speed: speed * 2,
                                      color: theme.primaryColor,
                                    ),
                                    SizedBox(height: 20.h),
                                    FastSpeechDecoderCore(
                                      textToSpeak: quest.textToSpeak ?? "",
                                      speed: speed,
                                      color: theme.primaryColor,
                                      rotation: rotation,
                                      onRotate: _onRotate,
                                      onTapTts: () {
                                        _soundService.playTts(
                                          quest.textToSpeak ?? "",
                                          speed: speed,
                                        );
                                        _hapticService.selection();
                                      },
                                      emoji: quest.emoji,
                                      isCorrectState: _isCorrect.value,
                                    ),
                                  ],
                                );
                              })(),''');

  // Widget properties
  content = content.replaceAll('''                                isAnswered: _isAnswered,''', '''                                isAnswered: _isAnswered.value,''');
  content = content.replaceAll('''                                isCorrectState: _isCorrect,''', '''                                isCorrectState: _isCorrect.value,''');
  content = content.replaceAll('''                                selectedIndex: _selectedIndex,''', '''                                selectedIndex: _selectedIndex.value,''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                ),
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('''                  if (_pendingSelectedIndex != null && !_isAnswered)
                    SpeakToConfirmOverlay(
                      expectedText: quest.options![_pendingSelectedIndex!],''', '''                  if (_pendingSelectedIndex.value != null && !_isAnswered.value)
                    SpeakToConfirmOverlay(
                      expectedText: quest.options![_pendingSelectedIndex.value!],''');

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
                              FastSpeechDecoderSteamVents(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                isAnswered: _isAnswered.value,
                                isCorrectState: _isCorrect.value,
                                selectedIndex: _selectedIndex.value,
                                onSubmitAnswer: (index) {
                                  if (_isAnswered.value || _pendingSelectedIndex.value != null) return;
                                  _pendingSelectedIndex.value = index;
                                },
                              ),
                              SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
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
                              FastSpeechDecoderSteamVents(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                isAnswered: _isAnswered.value,
                                isCorrectState: _isCorrect.value,
                                selectedIndex: _selectedIndex.value,
                                onSubmitAnswer: (index) {
                                  if (_isAnswered.value || _pendingSelectedIndex.value != null) return;
                                  _pendingSelectedIndex.value = index;
                                },
                              ),
                              SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
