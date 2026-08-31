import 'dart:io';

void main() {
  _fixScreen();
  _fixOptions();
}

void _fixScreen() {
  final file = File('lib/features/reading/guess_title/presentation/pages/guess_title_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showTypeToConfirm = false;', 'final ValueNotifier<bool> _showTypeToConfirm = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _showTypeToConfirm.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('if (_isAnswered || _showTypeToConfirm) return;', 'if (_isAnswered.value || _showTypeToConfirm.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = isCorrect;''');

  content = content.replaceAll('''      setState(() {
        _showTypeToConfirm = true;
      });''', '''      _showTypeToConfirm.value = true;''');

  content = content.replaceAll('''    setState(() {
      _showTypeToConfirm = false;
    });''', '''    _showTypeToConfirm.value = false;''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _showTypeToConfirm = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _showTypeToConfirm.value = false;''');

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
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _showTypeToConfirm]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget State Accesses
  content = content.replaceAll('''                                if (!_isAnswered || _isCorrect == null) ...[''', '''                                if (!_isAnswered.value || _isCorrect.value == null) ...[''');
  
  content = content.replaceAll('''                                    isAnswered: _isAnswered,''', '''                                    isAnswered: _isAnswered.value,''');

  content = content.replaceAll('''                                if (_isAnswered) ...[''', '''                                if (_isAnswered.value) ...[''');

  content = content.replaceAll('''                                    isCorrect: _isCorrect == true,''', '''                                    isCorrect: _isCorrect.value == true,''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: 50.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_showTypeToConfirm && _isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: quest.correctAnswer ?? '',
                        primaryColor: theme.primaryColor,
                        onConfirmed: _onTypeConfirmed,
                        onSkipped: _onTypeConfirmed,
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }''', '''                      ],
                    ),
                  ),
                ),
                if (_showTypeToConfirm.value && _isAnswered.value)
                  SliverToBoxAdapter(
                    child: TypeToConfirmOverlay(
                      expectedText: quest.correctAnswer ?? '',
                      primaryColor: theme.primaryColor,
                      onConfirmed: _onTypeConfirmed,
                      onSkipped: _onTypeConfirmed,
                      allowSkip: true,
                      isPositioned: false,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 50.h),
                ),
              ],
            );
          },
        );
      },
    );
  }''');

  // _buildPassageContent method
  content = content.replaceAll('''    if (!_isAnswered || evidence.isEmpty || !passage.contains(evidence)) {''', '''    if (!_isAnswered.value || evidence.isEmpty || !passage.contains(evidence)) {''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}

void _fixOptions() {
  final file = File('lib/features/reading/guess_title/presentation/widgets/guess_title_options.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _selectedIndex.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('''      _selectedIndex = null;''', '''      _selectedIndex.value = null;''');

  content = content.replaceAll('''    setState(() {
      _selectedIndex = index;
    });''', '''    _selectedIndex.value = index;''');

  content = content.replaceAll('''  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.options.length, (index) {
        final isSelected = _selectedIndex == index;''', '''  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndex, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.options.length, (index) {
            final isSelected = selectedIndex == index;''');

  content = content.replaceAll('''      }),
    );
  }''', '''          }),
        );
      },
    );
  }''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
