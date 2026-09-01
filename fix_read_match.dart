import 'dart:io';

void main() {
  final file = File('lib/features/reading/read_and_match/presentation/pages/read_and_match_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('String? _activeKey;', 'final ValueNotifier<String?> _activeKey = ValueNotifier(null);');
  content = content.replaceAll('final Map<String, String> _matches = {};', 'final ValueNotifier<Map<String, String>> _matches = ValueNotifier({});');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingSubmission = false;', 'final ValueNotifier<bool> _pendingSubmission = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _activeKey.dispose();\n    _matches.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingSubmission.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');
  
  content = content.replaceAll('''    setState(() {
      if (_matches.containsKey(key)) {
        _matches.remove(key);
      }
      _activeKey = key;
    });''', '''    final Map<String, String> currentMatches = Map.from(_matches.value);
    if (currentMatches.containsKey(key)) {
      currentMatches.remove(key);
    }
    _matches.value = currentMatches;
    _activeKey.value = key;''');

  content = content.replaceAll('if (_isAnswered || _activeKey == null) return;', 'if (_isAnswered.value || _activeKey.value == null) return;');

  content = content.replaceAll('''    setState(() {
      // Remove any existing match containing this value
      _matches.removeWhere((k, v) => v == value);

      _matches[_activeKey!] = value;
      _activeKey = null;
    });''', '''    final Map<String, String> currentMatches = Map.from(_matches.value);
    currentMatches.removeWhere((k, v) => v == value);
    currentMatches[_activeKey.value!] = value;
    _matches.value = currentMatches;
    _activeKey.value = null;''');

  content = content.replaceAll('if (_matches.length == pairs.length)', 'if (_matches.value.length == pairs.length)');

  content = content.replaceAll('''      setState(() {
        _pendingSubmission = true;
      });''', '''      _pendingSubmission.value = true;''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmission = false;
    });''', '''    _pendingSubmission.value = false;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''          setState(() {
            _matches.clear();
            _isAnswered = false;
            _isCorrect = null;
          });''', '''          _matches.value = {};
          _isAnswered.value = false;
          _isCorrect.value = null;''');

  content = content.replaceAll('''      if (_matches[pair['key']] != pair['value']) {''', '''      if (_matches.value[pair['key']] != pair['value']) {''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _matches.clear();
              _activeKey = null;
              _pendingSubmission = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _matches.value = {};
            _activeKey.value = null;
            _pendingSubmission.value = false;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _matches, _activeKey, _pendingSubmission]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''          if (_matches.containsValue(v)) {
            final key = _matches.entries.firstWhere((e) => e.value == v).key;''', '''          if (_matches.value.containsValue(v)) {
            final key = _matches.value.entries.firstWhere((e) => e.value == v).key;''');

  content = content.replaceAll('''                                                      isMatched: _matches
                                                          .containsKey(k),
                                                      isActive: _activeKey == k,''', '''                                                      isMatched: _matches.value
                                                          .containsKey(k),
                                                      isActive: _activeKey.value == k,''');

  content = content.replaceAll('''                                                      isMatched: _matches
                                                          .containsValue(v),''', '''                                                      isMatched: _matches.value
                                                          .containsValue(v),''');

  content = content.replaceAll('''                                            painter: LaserBridgePainter(
                                              matches: _matches,
                                              activeKey: _activeKey,''', '''                                            painter: LaserBridgePainter(
                                              matches: _matches.value,
                                              activeKey: _activeKey.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isAnswered) ...[
                                  SizedBox(height: 30.h),
                                  ReadAndMatchResult(
                                    quest: quest,
                                    isCorrect: _isCorrect == true,
                                    isDark: isDark,
                                  ),
                                ],
                                SizedBox(height: 50.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                    if (_pendingSubmission && !_isAnswered)
                      SpeakToConfirmOverlay(
                        expectedText:
                            quest.textToSpeak ??
                            quest.correctAnswer ??
                            "Confirm",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, pairs),
                        onSkipped: () => _submitFinalAnswer(false, pairs),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}''', '''                      ],
                    );
                  },
                ),
                if (_pendingSubmission.value && !_isAnswered.value)
                  SpeakToConfirmOverlay(
                    expectedText:
                        quest.textToSpeak ??
                        quest.correctAnswer ??
                        "Confirm",
                    primaryColor: theme.primaryColor,
                    onConfirmed: () => _submitFinalAnswer(true, pairs),
                    onSkipped: () => _submitFinalAnswer(false, pairs),
                    allowSkip: true,
                    isPositioned: false, // Since it's in a stack... Wait!
                  ),
                if (_isAnswered.value)
                  Positioned(
                    bottom: 50.h,
                    left: 20.w,
                    right: 20.w,
                    child: ReadAndMatchResult(
                      quest: quest,
                      isCorrect: _isCorrect.value == true,
                      isDark: isDark,
                    ),
                  ),
              ],
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
