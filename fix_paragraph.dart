import 'dart:io';

void main() {
  final file = File('lib/features/reading/paragraph_summary/presentation/pages/paragraph_summary_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _pinchWidth = 1.0;', 'final ValueNotifier<double> _pinchWidth = ValueNotifier(1.0);');
  content = content.replaceAll('bool _isDistilled = false;', 'final ValueNotifier<bool> _isDistilled = ValueNotifier(false);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _pinchWidth.dispose();\n    _isDistilled.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _isDistilled) return;', 'if (_isAnswered.value || _isDistilled.value) return;');

  content = content.replaceAll('''    setState(() {
      _pinchWidth = scale.clamp(0.4, 1.0);
      if (_pinchWidth < 0.6) {
        _hapticService.selection();
      }
    });''', '''    _pinchWidth.value = scale.clamp(0.4, 1.0);
    if (_pinchWidth.value < 0.6) {
      _hapticService.selection();
    }''');

  content = content.replaceAll('''    if (_pinchWidth < 0.55) {
      _hapticService.heavy();
      setState(() {
        _isDistilled = true;
        _pinchWidth = 0.45;
      });
    } else {
      setState(() => _pinchWidth = 1.0);
    }''', '''    if (_pinchWidth.value < 0.55) {
      _hapticService.heavy();
      _isDistilled.value = true;
      _pinchWidth.value = 0.45;
    } else {
      _pinchWidth.value = 1.0;
    }''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isCorrect;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isDistilled = false;
              _pinchWidth = 1.0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isDistilled.value = false;
            _pinchWidth.value = 1.0;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isDistilled, _pinchWidth]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                                pinchWidth: _pinchWidth,
                                isDistilled: _isDistilled,''', '''                                pinchWidth: _pinchWidth.value,
                                isDistilled: _isDistilled.value,''');

  content = content.replaceAll('''                              _isDistilled
                                  ? "DISTILLATION COMPLETE! THINK OF THE CORE SUMMARY AND REVEAL:"
                                  : "PINCH/SQUEEZE THE TUBE TO DISTILL CORE CONCEPTS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: _isDistilled
                                    ? Colors.greenAccent
                                    : theme.primaryColor.withValues(alpha: 0.6),''', '''                              _isDistilled.value
                                  ? "DISTILLATION COMPLETE! THINK OF THE CORE SUMMARY AND REVEAL:"
                                  : "PINCH/SQUEEZE THE TUBE TO DISTILL CORE CONCEPTS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: _isDistilled.value
                                    ? Colors.greenAccent
                                    : theme.primaryColor.withValues(alpha: 0.6),''');

  // Fix Sliver Layout
  content = content.replaceAll('''                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isDistilled && !_isAnswered) ...[
                              SizedBox(height: 24.h),
                              TypeToConfirmOverlay(
                                expectedText: quest.correctAnswer ?? "",
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitFinalAnswer(true, quest),
                                onSkipped: () => _submitFinalAnswer(false, quest),
                                allowSkip: true,
                              ),
                            ],
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ParagraphSummaryResult(
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
                            if (_isDistilled.value && !_isAnswered.value) ...[
                              SizedBox(height: 24.h),
                              TypeToConfirmOverlay(
                                expectedText: quest.correctAnswer ?? "",
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitFinalAnswer(true, quest),
                                onSkipped: () => _submitFinalAnswer(false, quest),
                                allowSkip: true,
                                isPositioned: false,
                              ),
                            ],
                            if (_isAnswered.value) ...[
                              SizedBox(height: 30.h),
                              ParagraphSummaryResult(
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
