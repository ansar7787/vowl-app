import 'dart:io';

void main() {
  final file = File('lib/features/reading/reading_inference/presentation/pages/reading_inference_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<Offset> _rubPoints = [];', 'final ValueNotifier<List<Offset>> _rubPoints = ValueNotifier([]);');
  content = content.replaceAll('double _clarity = 0.0;', 'final ValueNotifier<double> _clarity = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showEvidence = false;', 'final ValueNotifier<bool> _showEvidence = ValueNotifier(false);');
  content = content.replaceAll('bool _evidenceFound = false;', 'final ValueNotifier<bool> _evidenceFound = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _rubPoints.dispose();\n    _clarity.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _showEvidence.dispose();\n    _evidenceFound.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _rubPoints.add(point);
      _clarity = (_rubPoints.length / 100).clamp(0.0, 1.0);
      if (_rubPoints.length % 5 == 0) {
        _hapticService.selection();
      }
    });''', '''    _rubPoints.value = List.from(_rubPoints.value)..add(point);
    _clarity.value = (_rubPoints.value.length / 100).clamp(0.0, 1.0);
    if (_rubPoints.value.length % 5 == 0) {
      _hapticService.selection();
    }''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isCorrect;''');

  content = content.replaceAll('''        setState(() {
          _showEvidence = true;
        });''', '''        _showEvidence.value = true;''');

  content = content.replaceAll('''    setState(() {
      _showEvidence = false;
      _evidenceFound = true;
    });''', '''    _showEvidence.value = false;
    _evidenceFound.value = true;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _rubPoints.clear();
              _clarity = 0.0;
              _showEvidence = false;
              _evidenceFound = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _rubPoints.value = [];
            _clarity.value = 0.0;
            _showEvidence.value = false;
            _evidenceFound.value = false;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _rubPoints, _clarity, _showEvidence, _evidenceFound]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                            if (_showEvidence)''', '''                            if (_showEvidence.value)''');
  
  content = content.replaceAll('''                                isAnswered: _isAnswered || _showEvidence,''', '''                                isAnswered: _isAnswered.value || _showEvidence.value,''');
  
  content = content.replaceAll('''                                rubPoints: _rubPoints,
                                clarity: _clarity,''', '''                                rubPoints: _rubPoints.value,
                                clarity: _clarity.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: 24.h),
                            if (!_showEvidence && !_evidenceFound)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _clarity >= 0.3 ? 1.0 : 0.3,
                                child: AbsorbPointer(
                                  absorbing: _clarity < 0.3 || _isAnswered,
                                  child: ReadingSelfEvaluationCard(
                                    correctAnswer: quest.correctAnswer ?? "",
                                    explanation: quest.explanation,
                                    primaryColor: theme.primaryColor,
                                    onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                                  ),
                                ),
                              ),

                            if (_isAnswered && (!_showEvidence || _evidenceFound)) ...[
                              SizedBox(height: 30.h),
                              ReadingInferenceResult(
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
                            SizedBox(height: 24.h),
                            if (!_showEvidence.value && !_evidenceFound.value)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _clarity.value >= 0.3 ? 1.0 : 0.3,
                                child: AbsorbPointer(
                                  absorbing: _clarity.value < 0.3 || _isAnswered.value,
                                  child: ReadingSelfEvaluationCard(
                                    correctAnswer: quest.correctAnswer ?? "",
                                    explanation: quest.explanation,
                                    primaryColor: theme.primaryColor,
                                    onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                                  ),
                                ),
                              ),

                            if (_isAnswered.value && (!_showEvidence.value || _evidenceFound.value)) ...[
                              SizedBox(height: 30.h),
                              ReadingInferenceResult(
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
