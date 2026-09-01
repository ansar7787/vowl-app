import 'dart:io';

void main() {
  final file = File('lib/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('double _revealProgress = 0.0;', 'final ValueNotifier<double> _revealProgress = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _controller.dispose();\n    _revealProgress.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('''  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }''', '');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _revealProgress = (_revealProgress + delta).clamp(0.0, 1.0);
      if (_revealProgress > 0.05) _hapticService.selection();
    });''', '''    _revealProgress.value = (_revealProgress.value + delta).clamp(0.0, 1.0);
    if (_revealProgress.value > 0.05) _hapticService.selection();''');

  content = content.replaceAll('if (_isAnswered || input.isEmpty || correct == null || correct.isEmpty)', 'if (_isAnswered.value || input.isEmpty || correct == null || correct.isEmpty)');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isCorrect;''');

  content = content.replaceAll('''    setState(() {
      _lastProcessedIndex = newIndex;
      _isAnswered = false;
      _isCorrect = null;
      _revealProgress = 0.0;
      _controller.clear();
    });''', '''    _lastProcessedIndex = newIndex;
    _isAnswered.value = false;
    _isCorrect.value = null;
    _revealProgress.value = 0.0;
    _controller.clear();''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                    setState(() {
                      _isAnswered = true;
                      _isCorrect = correct;
                    });''', '''                    _isAnswered.value = true;
                    _isCorrect.value = correct;''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _revealProgress]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Pass value accesses
  content = content.replaceAll('''                  isAnswered: _isAnswered,
                  isCorrect: _isCorrect,
                  revealProgress: _revealProgress,''', '''                  isAnswered: _isAnswered.value,
                  isCorrect: _isCorrect.value,
                  revealProgress: _revealProgress.value,''');

  // Fix bracket at the bottom of build
  content = content.replaceAll('''                ),
        );
      },
    );
  }
}''', '''                ),
            );
          },
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (level >= 8 && !isAnswered)
                  BlindDictationWrapper(
                    expectedText: quest.correctAnswer ?? quest.textToSpeak ?? '',
                    primaryColor: theme.primaryColor,
                    isPositioned: false,
                    onConfirmed: () => onBlindSubmit(true),
                    onSkipped: () => onBlindSubmit(false),
                  )
                else ...[
                  AudioFillBlanksInput(
                    controller: controller,
                    isAnswered: isAnswered,
                    primaryColor: theme.primaryColor,
                    maxLength: maxInputLength,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  SizedBox(height: 16.h),
                  if (!isAnswered)
                    _SubmitButton(
                      isCompact: false,
                      primaryColor: theme.primaryColor,
                      onTap: onSubmit,
                    ),
                ],
              ],
            ),
          ),
        ),''', '''        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (level >= 8 && !isAnswered)
                  BlindDictationWrapper(
                    expectedText: quest.correctAnswer ?? quest.textToSpeak ?? '',
                    primaryColor: theme.primaryColor,
                    isPositioned: false,
                    onConfirmed: () => onBlindSubmit(true),
                    onSkipped: () => onBlindSubmit(false),
                  )
                else ...[
                  AudioFillBlanksInput(
                    controller: controller,
                    isAnswered: isAnswered,
                    primaryColor: theme.primaryColor,
                    maxLength: maxInputLength,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  SizedBox(height: 16.h),
                  if (!isAnswered)
                    _SubmitButton(
                      isCompact: false,
                      primaryColor: theme.primaryColor,
                      onTap: onSubmit,
                    ),
                ],
              ],
            ),
          ),
        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
