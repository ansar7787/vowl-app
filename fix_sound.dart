import 'dart:io';

void main() {
  final file = File('lib/features/listening/sound_image_match/presentation/pages/sound_image_match_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('Offset _lensPosition = const Offset(150, 150);', 'final ValueNotifier<Offset> _lensPosition = ValueNotifier(const Offset(150, 150));');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('int? _pendingSelectedIndex;', 'final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _selectedIndex.dispose();\n    _pendingSelectedIndex.dispose();\n    _lensPosition.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _lensPosition = position;
      _hapticService.selection();
    });''', '''    _lensPosition.value = position;
    _hapticService.selection();''');

  content = content.replaceAll('if (_isAnswered || _pendingSelectedIndex == null) return;', 'if (_isAnswered.value || _pendingSelectedIndex.value == null) return;');

  content = content.replaceAll('''                                          setState(() {
                                            _isAnswered = true;
                                            _isCorrect = false;
                                            _pendingSelectedIndex = -1;
                                            _selectedIndex = -1;
                                          });''', '''                                          _isAnswered.value = true;
                                          _isCorrect.value = false;
                                          _pendingSelectedIndex.value = -1;
                                          _selectedIndex.value = -1;''');

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
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _pendingSelectedIndex.value = null;
            _lensPosition.value = const Offset(150, 150);''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                        if (_isAnswered ||
                                            _pendingSelectedIndex != null) {
                                          return;
                                        }
                                        _timerKey.currentState?.pause();
                                        setState(() {
                                          _pendingSelectedIndex = index;
                                        });''', '''                                        if (_isAnswered.value ||
                                            _pendingSelectedIndex.value != null) {
                                          return;
                                        }
                                        _timerKey.currentState?.pause();
                                        _pendingSelectedIndex.value = index;''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _pendingSelectedIndex, _lensPosition]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                  if (!_isAnswered)''', '''                                  if (!_isAnswered.value)''');
  content = content.replaceAll('''                                    isCorrectState: _isCorrect,''', '''                                    isCorrectState: _isCorrect.value,''');
  content = content.replaceAll('''                                      isAnswered: _isAnswered,''', '''                                      isAnswered: _isAnswered.value,''');
  content = content.replaceAll('''                                      isCorrectState: _isCorrect,''', '''                                      isCorrectState: _isCorrect.value,''');
  content = content.replaceAll('''                                      selectedIndex: _selectedIndex,''', '''                                      selectedIndex: _selectedIndex.value,''');
  content = content.replaceAll('''                                      lensPosition: _lensPosition,''', '''                                      lensPosition: _lensPosition.value,''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                  ),
        );
      },
    );
  }
}''', '''                  ),
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('''                      if (_pendingSelectedIndex != null && !_isAnswered)
                        SpeakToConfirmOverlay(
                          expectedText:
                              quest.options![_pendingSelectedIndex!],''', '''                      if (_pendingSelectedIndex.value != null && !_isAnswered.value)
                        SpeakToConfirmOverlay(
                          expectedText:
                              quest.options![_pendingSelectedIndex.value!],''');

  // Fix Sliver Layout
  content = content.replaceAll('''                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 350.h,
                                    child: SoundImageMatchScannerField(
                                      options: quest.options ?? [],
                                      correctAnswerIndex:
                                          quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,
                                      selectedIndex: _selectedIndex.value,
                                      lensPosition: _lensPosition.value,
                                      onScan: _onScan,
                                      onSelect: (index) {
                                        if (_isAnswered.value ||
                                            _pendingSelectedIndex.value != null) {
                                          return;
                                        }
                                        _timerKey.currentState?.pause();
                                        _pendingSelectedIndex.value = index;
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                                ],
                              ),
                            ),
                          ),''', '''                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 350.h,
                                    child: SoundImageMatchScannerField(
                                      options: quest.options ?? [],
                                      correctAnswerIndex:
                                          quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,
                                      selectedIndex: _selectedIndex.value,
                                      lensPosition: _lensPosition.value,
                                      onScan: _onScan,
                                      onSelect: (index) {
                                        if (_isAnswered.value ||
                                            _pendingSelectedIndex.value != null) {
                                          return;
                                        }
                                        _timerKey.currentState?.pause();
                                        _pendingSelectedIndex.value = index;
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                                ],
                              ),
                            ),
                          ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
