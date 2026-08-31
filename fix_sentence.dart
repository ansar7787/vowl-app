import 'dart:io';

void main() {
  final file = File('lib/features/grammar/sentence_correction/presentation/pages/sentence_correction_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('int? _selectedWordIndex;', 'final ValueNotifier<int?> _selectedWordIndex = ValueNotifier(null);');
  content = content.replaceAll('String? _selectedOption;', 'final ValueNotifier<String?> _selectedOption = ValueNotifier(null);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _selectedWordIndex.dispose();\n    _selectedOption.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isFirstStagePassed.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _isFirstStagePassed) return;', 'if (_isAnswered.value || _isFirstStagePassed.value) return;');

  content = content.replaceAll('''    setState(() {
      _selectedWordIndex = index;
      _selectedOption = null;
    });''', '''    _selectedWordIndex.value = index;
    _selectedOption.value = null;''');

  content = content.replaceAll('if (_selectedWordIndex == null || _selectedOption == null) return;', 'if (_selectedWordIndex.value == null || _selectedOption.value == null) return;');
  content = content.replaceAll('bool isWordCorrect = correctIndices.contains(_selectedWordIndex);', 'bool isWordCorrect = correctIndices.contains(_selectedWordIndex.value);');
  content = content.replaceAll('int chosenIndex = quest.options?.indexOf(_selectedOption!) ?? -1;', 'int chosenIndex = quest.options?.indexOf(_selectedOption.value!) ?? -1;');
  content = content.replaceAll('(_selectedOption == quest.correctAnswer)', '(_selectedOption.value == quest.correctAnswer)');
  
  content = content.replaceAll('''      print(
        "Tapped Word Index: \$_selectedWordIndex (Word: \${words[_selectedWordIndex!]})",
      );''', '''      print(
        "Tapped Word Index: \${_selectedWordIndex.value} (Word: \${words[_selectedWordIndex.value!]})",
      );''');
  content = content.replaceAll('print("Tapped Option: \\\'\$_selectedOption\\\'");', 'print("Tapped Option: \\\'\${_selectedOption.value}\\\'");');

  content = content.replaceAll('''      setState(() {
        _isFirstStagePassed = true;
      });''', '''      _isFirstStagePassed.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedWordIndex, _selectedOption, _isFirstStagePassed]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('isSuspected: _selectedWordIndex == i,', 'isSuspected: _selectedWordIndex.value == i,');
  content = content.replaceAll('_isAnswered &&\n                                          _isCorrect == true &&', '_isAnswered.value &&\n                                          _isCorrect.value == true &&');
  content = content.replaceAll('_isAnswered &&\n                                          _isCorrect == false &&\n                                          _selectedWordIndex == i,', '_isAnswered.value &&\n                                          _isCorrect.value == false &&\n                                          _selectedWordIndex.value == i,');

  content = content.replaceAll('if (_selectedWordIndex != null) ...[', 'if (_selectedWordIndex.value != null) ...[');
  
  content = content.replaceAll('''                          SentenceCorrectionOptionsPanel(
                            options: _shuffledOptions ?? [],
                            selectedOption: _selectedOption,
                            isAnswered: _isAnswered,''', '''                          SentenceCorrectionOptionsPanel(
                            options: _shuffledOptions ?? [],
                            selectedOption: _selectedOption.value,
                            isAnswered: _isAnswered.value,''');

  content = content.replaceAll('''                            onOptionSelect: (option) {
                              _hapticService.selection();
                              setState(() => _selectedOption = option);
                            },''', '''                            onOptionSelect: (option) {
                              _hapticService.selection();
                              _selectedOption.value = option;
                            },''');

  content = content.replaceAll('if (_isAnswered && _isCorrect == false) ...[', 'if (_isAnswered.value && _isCorrect.value == false) ...[');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_isFirstStagePassed && !_isAnswered)
                            TypeToConfirmOverlay(
                              expectedText: quest.correctAnswer ?? _selectedOption ?? '',
                              primaryColor: theme.primaryColor,
                              onConfirmed: () => _submitVerbalEvaluation(true),
                              onSkipped: () => _submitVerbalEvaluation(false),
                              isPositioned: false,
                            ),
                          SizedBox(height: _isAnswered ? 160.h : 60.h),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}''', '''                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                    if (_isFirstStagePassed.value && !_isAnswered.value)
                      SliverToBoxAdapter(
                        child: TypeToConfirmOverlay(
                          expectedText: quest.correctAnswer ?? _selectedOption.value ?? '',
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitVerbalEvaluation(true),
                          onSkipped: () => _submitVerbalEvaluation(false),
                          isPositioned: false,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: _isAnswered.value ? 160.h : 60.h),
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
