import 'dart:io';

void main() {
  final file = File('lib/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('List<String> _currentOrder = [];', 'final ValueNotifier<List<String>> _currentOrder = ValueNotifier([]);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _currentOrder.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
      _hapticService.selection();
    });''', '''    final List<String> current = List.from(_currentOrder.value);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    _currentOrder.value = current;
    _hapticService.selection();''');

  content = content.replaceAll('''    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i] != original[correctOrder[i]]) {''', '''    for (int i = 0; i < _currentOrder.value.length; i++) {
      if (_currentOrder.value[i] != original[correctOrder[i]]) {''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _currentOrder = List<String>.from(
                state.currentQuest.shuffledSentences ?? [],
              );
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _currentOrder.value = List<String>.from(
              state.currentQuest.shuffledSentences ?? [],
            );''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _currentOrder]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                            ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              proxyDecorator: (child, index, animation) =>
                                  _buildProxy(child, animation, theme.primaryColor),
                              onReorder: _onReorder,
                              children: List.generate(
                                _currentOrder.length,
                                (index) => SentenceOrderReadingStoneSlab(
                                  key: ValueKey(_currentOrder[index]),
                                  text: _currentOrder[index],
                                  index: index,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  transitionWords: quest.transitionWords,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isAnswered) ...[
                              SizedBox(height: 24.h),
                              SentenceOrderReadingCapstone(
                                color: theme.primaryColor,
                                onTap: () {
                                  _hapticService.heavy();
                                  _submitAnswer(
                                    quest.correctOrder ?? [],
                                    quest.shuffledSentences ?? [],
                                  );
                                },
                              ),
                            ],
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              SentenceOrderReadingResult(
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
  }''', '''                            ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              proxyDecorator: (child, index, animation) =>
                                  _buildProxy(child, animation, theme.primaryColor),
                              onReorder: _onReorder,
                              children: List.generate(
                                _currentOrder.value.length,
                                (index) => SentenceOrderReadingStoneSlab(
                                  key: ValueKey(_currentOrder.value[index]),
                                  text: _currentOrder.value[index],
                                  index: index,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  transitionWords: quest.transitionWords,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isAnswered.value) ...[
                              SizedBox(height: 24.h),
                              SentenceOrderReadingCapstone(
                                color: theme.primaryColor,
                                onTap: () {
                                  _hapticService.heavy();
                                  _submitAnswer(
                                    quest.correctOrder ?? [],
                                    quest.shuffledSentences ?? [],
                                  );
                                },
                              ),
                            ],
                            if (_isAnswered.value) ...[
                              SizedBox(height: 30.h),
                              SentenceOrderReadingResult(
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
  }''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
