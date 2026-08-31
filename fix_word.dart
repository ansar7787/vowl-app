import 'dart:io';

void main() {
  final file = File('lib/features/grammar/word_reorder/presentation/pages/word_reorder_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<int> _availableIndices = [];', 'final ValueNotifier<List<int>> _availableIndices = ValueNotifier([]);');
  content = content.replaceAll('final List<int> _assembledIndices = [];', 'final ValueNotifier<List<int>> _assembledIndices = ValueNotifier([]);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingTypeSubmit = false;', 'final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _availableIndices.dispose();\n    _assembledIndices.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _pendingTypeSubmit.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _assembledIndices.add(index);
      _availableIndices.remove(index);
    });''', '''    _assembledIndices.value = List.from(_assembledIndices.value)..add(index);
    _availableIndices.value = List.from(_availableIndices.value)..remove(index);''');

  content = content.replaceAll('''    setState(() {
      _assembledIndices.remove(index);
      _availableIndices.add(index);
      _availableIndices.sort();
    });''', '''    _assembledIndices.value = List.from(_assembledIndices.value)..remove(index);
    _availableIndices.value = List.from(_availableIndices.value)..add(index)..sort();''');

  content = content.replaceAll('if (_assembledIndices.isEmpty) return;', 'if (_assembledIndices.value.isEmpty) return;');
  content = content.replaceAll('bool correct = _assembledIndices.length == correctOrder.length;', 'bool correct = _assembledIndices.value.length == correctOrder.length;');
  content = content.replaceAll('if (_assembledIndices[i] != correctOrder[i]) {', 'if (_assembledIndices.value[i] != correctOrder[i]) {');

  content = content.replaceAll('setState(() => _pendingTypeSubmit = true);', '_pendingTypeSubmit.value = true;');
  
  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('setState(() => _pendingTypeSubmit = false);', '_pendingTypeSubmit.value = false;');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingTypeSubmit = false;

              _assembledIndices.clear();
              _availableIndices.clear();
              final quest = state.currentQuest;
              if (quest.shuffledWords != null) {
                _availableIndices.addAll(
                  List.generate(quest.shuffledWords!.length, (i) => i),
                );
              }
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingTypeSubmit.value = false;

            _assembledIndices.value = [];
            final quest = state.currentQuest;
            if (quest.shuffledWords != null) {
              _availableIndices.value = List.generate(quest.shuffledWords!.length, (i) => i);
            } else {
              _availableIndices.value = [];
            }''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _availableIndices, _assembledIndices, _pendingTypeSubmit]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''            (hintUsed && _assembledIndices.length < correctOrder.length)
            ? correctOrder[_assembledIndices.length]''', '''            (hintUsed && _assembledIndices.value.length < correctOrder.length)
            ? correctOrder[_assembledIndices.value.length]''');

  content = content.replaceAll('''                          WordReorderAssemblyCard(
                            assembledIndices: _assembledIndices,
                            shuffledWords: shuffledWords,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered,''', '''                          WordReorderAssemblyCard(
                            assembledIndices: _assembledIndices.value,
                            shuffledWords: shuffledWords,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                              children: _availableIndices.map((idx) {
                                return WordReorderFloatingTile(''', '''                              children: _availableIndices.value.map((idx) {
                                return WordReorderFloatingTile(''');

  content = content.replaceAll('''                        if (!_isAnswered && !_pendingTypeSubmit)
                          WordReorderCheckButton(
                            hasWords: _assembledIndices.isNotEmpty,
                            isDark: isDark,
                            primaryColor: theme.primaryColor,
                            onCheck: () => _checkSentence(correctOrder),
                          ),
                        if (_pendingTypeSubmit && !_isAnswered)
                          TypeToConfirmOverlay(
                            expectedText: correctOrder.map((idx) => shuffledWords[idx]).join(" "),
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true),
                            onSkipped: () => _submitFinalAnswer(false),
                            isPositioned: false,
                          ),
                        SizedBox(height: _isAnswered ? 160.h : 60.h),
                      ],
                    ),
                    ),
                  ],
                );
                  },
                ),
        );
      },
    );
  }
}''', '''                        if (!_isAnswered.value && !_pendingTypeSubmit.value)
                          WordReorderCheckButton(
                            hasWords: _assembledIndices.value.isNotEmpty,
                            isDark: isDark,
                            primaryColor: theme.primaryColor,
                            onCheck: () => _checkSentence(correctOrder),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_pendingTypeSubmit.value && !_isAnswered.value)
                  SliverToBoxAdapter(
                    child: TypeToConfirmOverlay(
                      expectedText: correctOrder.map((idx) => shuffledWords[idx]).join(" "),
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(true),
                      onSkipped: () => _submitFinalAnswer(false),
                      isPositioned: false,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: _isAnswered.value ? 160.h : 60.h),
                ),
              ],
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('final bool correct = _isCorrect == true;', 'final bool correct = _isCorrect.value == true;');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
