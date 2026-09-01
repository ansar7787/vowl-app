import 'dart:io';

void main() {
  final file = File('lib/features/reading/skimming_scanning/presentation/pages/skimming_scanning_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');

  content = content.replaceAll('''  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('if (!mounted || _isAnswered) return;', 'if (!mounted || _isAnswered.value) return;');
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = false;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = false;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                            if (!_isAnswered)''', '''                            if (!_isAnswered.value)''');
  
  content = content.replaceAll('''                                isAnswered: _isAnswered,''', '''                                isAnswered: _isAnswered.value,''');
  
  content = content.replaceAll('''                            Text(
                              _isAnswered''', '''                            Text(
                              _isAnswered.value''');
                              
  content = content.replaceAll('''                                color: _isAnswered''', '''                                color: _isAnswered.value''');

  // Fix Sliver Layout
  content = content.replaceAll('''                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isAnswered) ...[
                              SizedBox(height: 24.h),
                              SkimmingScanningResult(
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
                ),
        );
      },
    );
  }
}''', '''                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isAnswered.value) ...[
                              SizedBox(height: 24.h),
                              SkimmingScanningResult(
                                quest: quest,
                                isCorrect: _isCorrect.value == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
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
