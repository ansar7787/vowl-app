import 'dart:io';

void main() {
  final file = File('lib/features/reading/true_false_reading/presentation/pages/true_false_reading_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _coinX = 0.0;', 'final ValueNotifier<double> _coinX = ValueNotifier(0.0);');
  content = content.replaceAll('double _coinY = 0.0;', 'final ValueNotifier<double> _coinY = ValueNotifier(0.0);');
  content = content.replaceAll('double _coinRotation = 0.0;', 'final ValueNotifier<double> _coinRotation = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool? _pendingAnswer;', 'final ValueNotifier<bool?> _pendingAnswer = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _coinX.dispose();\n    _coinY.dispose();\n    _coinRotation.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingAnswer.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _pendingAnswer != null) return;', 'if (_isAnswered.value || _pendingAnswer.value != null) return;');

  content = content.replaceAll('''    setState(() {
      _coinX += delta.dx;
      _coinY += delta.dy;
      _coinRotation += (delta.dx + delta.dy) / 100;
      _hapticService.selection();
    });''', '''    _coinX.value += delta.dx;
    _coinY.value += delta.dy;
    _coinRotation.value += (delta.dx + delta.dy) / 100;
    _hapticService.selection();''');

  content = content.replaceAll('if (_coinX.abs() > 100.w) {', 'if (_coinX.value.abs() > 100.w) {');
  content = content.replaceAll('final bool pending = _coinX > 0;', 'final bool pending = _coinX.value > 0;');

  content = content.replaceAll('''        setState(() {
          _pendingAnswer = pending;
        });''', '''        _pendingAnswer.value = pending;''');

  content = content.replaceAll('''        setState(() {
          _pendingAnswer = pending;
        });''', '''        _pendingAnswer.value = pending;''');

  content = content.replaceAll('if (_pendingAnswer == null) return;', 'if (_pendingAnswer.value == null) return;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _coinX = _pendingAnswer! ? 120.w : -120.w;
        _coinY = 0.0;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _coinX.value = _pendingAnswer.value! ? 120.w : -120.w;
      _coinY.value = 0.0;''');

  content = content.replaceAll('''        userAnswer: failedCoin ? (_pendingAnswer! ? "True" : "False") : 'Failed to find evidence',''', '''        userAnswer: failedCoin ? (_pendingAnswer.value! ? "True" : "False") : 'Failed to find evidence',''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _coinX = _pendingAnswer! ? 120.w : -120.w;
      _coinY = 0.0;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;
    _coinX.value = _pendingAnswer.value! ? 120.w : -120.w;
    _coinY.value = 0.0;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingAnswer = null;
              _coinX = 0.0;
              _coinY = 0.0;
              _coinRotation = 0.0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingAnswer.value = null;
            _coinX.value = 0.0;
            _coinY.value = 0.0;
            _coinRotation.value = 0.0;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _pendingAnswer, _coinX, _coinY, _coinRotation]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                    if (_pendingAnswer != null && !_isAnswered)''', '''                    if (_pendingAnswer.value != null && !_isAnswered.value)''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(height: 40.h),
                                TrueFalseReadingCoinZone(
                                  coinX: _coinX,
                                  coinY: _coinY,
                                  coinRotation: _coinRotation,
                                  onFlick: _onFlick,
                                  isDark: isDark,
                                  themeColor: theme.primaryColor,
                                ),
                                if (_isAnswered) ...[
                                  SizedBox(height: 30.h),
                                  TrueFalseReadingResult(
                                    quest: quest,
                                    isCorrect: _isCorrect == true,
                                    isDark: isDark,
                                  ),
                                ],
                                SizedBox(height: 60.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pendingAnswer != null && !_isAnswered)''', '''                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(height: 40.h),
                                TrueFalseReadingCoinZone(
                                  coinX: _coinX.value,
                                  coinY: _coinY.value,
                                  coinRotation: _coinRotation.value,
                                  onFlick: _onFlick,
                                  isDark: isDark,
                                  themeColor: theme.primaryColor,
                                ),
                                if (_isAnswered.value) ...[
                                  SizedBox(height: 30.h),
                                  TrueFalseReadingResult(
                                    quest: quest,
                                    isCorrect: _isCorrect.value == true,
                                    isDark: isDark,
                                  ),
                                ],
                                SizedBox(height: 60.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pendingAnswer.value != null && !_isAnswered.value)'''); // Note: Re-replaced _pendingAnswer.value for safety if previous replaceAll didn't match nicely due to string wrapping

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
