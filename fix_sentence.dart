import 'dart:io';

void main() {
  final file = File('lib/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<Offset> _erasePoints = [];', 'final ValueNotifier<List<Offset>> _erasePoints = ValueNotifier([]);');
  content = content.replaceAll('bool _isWiped = false;', 'final ValueNotifier<bool> _isWiped = ValueNotifier(false);');
  content = content.replaceAll('String? _selectedOption;', 'final ValueNotifier<String?> _selectedOption = ValueNotifier(null);');
  content = content.replaceAll('String? _pendingSelectedOption;', 'final ValueNotifier<String?> _pendingSelectedOption = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int _erasedAmount = 0;', 'final ValueNotifier<int> _erasedAmount = ValueNotifier(0);');
  content = content.replaceAll('List<String>? _shuffledOptions;', 'final ValueNotifier<List<String>?> _shuffledOptions = ValueNotifier(null);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _erasePoints.dispose();
    _isWiped.dispose();
    _selectedOption.dispose();
    _pendingSelectedOption.dispose();
    _showConfetti.dispose();
    _erasedAmount.dispose();
    _shuffledOptions.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    if (isAnswered || _isWiped) return;''', '''    if (isAnswered || _isWiped.value) return;''');

  content = content.replaceAll('''    setState(() {
      _erasePoints.add(localPosition);
      _erasedAmount++;
      if (_erasedAmount % 6 == 0) _hapticService.selection();
    });''', '''    _erasePoints.value = List.from(_erasePoints.value)..add(localPosition);
    _erasedAmount.value++;
    if (_erasedAmount.value % 6 == 0) _hapticService.selection();''');

  content = content.replaceAll('''    if (_erasedAmount > 35) {
      _hapticService.success();
      _soundService.playHint();
      setState(() => _isWiped = true);
    }''', '''    if (_erasedAmount.value > 35) {
      _hapticService.success();
      _soundService.playHint();
      _isWiped.value = true;
    }''');

  content = content.replaceAll('''    if (_pendingSelectedOption == null) return;''', '''    if (_pendingSelectedOption.value == null) return;''');

  content = content.replaceAll('''      setState(() {
        _selectedOption = _pendingSelectedOption;
      });''', '''      _selectedOption.value = _pendingSelectedOption.value;''');

  content = content.replaceAll('''    final selected = _pendingSelectedOption!;''', '''    final selected = _pendingSelectedOption.value!;''');

  content = content.replaceAll('''    setState(() {
      _selectedOption = _pendingSelectedOption;
    });''', '''    _selectedOption.value = _pendingSelectedOption.value;''');

  content = content.replaceAll('''          setState(() {
            _isWiped = false;
            _selectedOption = null;
            _pendingSelectedOption = null;
            _erasePoints.clear();
            _erasedAmount = 0;
          });''', '''          _isWiped.value = false;
          _selectedOption.value = null;
          _pendingSelectedOption.value = null;
          _erasePoints.value = [];
          _erasedAmount.value = 0;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
          _shuffledOptions = List.from(_lastQuest!.options ?? [])..shuffle();
        }''', '''        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
          _shuffledOptions.value = List.from(_lastQuest!.options ?? [])..shuffle();
        }''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? const SizedBox()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _isWiped, _selectedOption, _pendingSelectedOption, _erasePoints, _erasedAmount, _shuffledOptions]),
            builder: (context, _) {
              return quest == null
                  ? const SizedBox()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''                                FixTheSentenceInstruction(
                                  isWiped: _isWiped,''', '''                                FixTheSentenceInstruction(
                                  isWiped: _isWiped.value,''');

  content = content.replaceAll('''                                FixTheSentenceDigitalBlackboard(
                                  fullText: quest.passage ?? "",
                                  targetWord: quest.missingWord ?? "",
                                  selectedReplacement:
                                      _selectedOption ?? _pendingSelectedOption,
                                  isWiped: _isWiped,
                                  erasePoints: _erasePoints,''', '''                                FixTheSentenceDigitalBlackboard(
                                  fullText: quest.passage ?? "",
                                  targetWord: quest.missingWord ?? "",
                                  selectedReplacement:
                                      _selectedOption.value ?? _pendingSelectedOption.value,
                                  isWiped: _isWiped.value,
                                  erasePoints: _erasePoints.value,''');

  content = content.replaceAll('''                                if (_isWiped && !isAnswered)
                                  FixTheSentenceWipedAlert(
                                    primaryColor: theme.primaryColor,
                                  ),
                                if (_isWiped && !isAnswered) SizedBox(height: 16.h),
                                if (_isWiped)
                                  FixTheSentenceCorrectionOptions(
                                    options:
                                        _shuffledOptions ?? quest.options ?? [],''', '''                                if (_isWiped.value && !isAnswered)
                                  FixTheSentenceWipedAlert(
                                    primaryColor: theme.primaryColor,
                                  ),
                                if (_isWiped.value && !isAnswered) SizedBox(height: 16.h),
                                if (_isWiped.value)
                                  FixTheSentenceCorrectionOptions(
                                    options:
                                        _shuffledOptions.value ?? quest.options ?? [],''');

  content = content.replaceAll('''                                    onSelect: (selected, correct) {
                                      if (isAnswered ||
                                          _pendingSelectedOption != null) {
                                        return;
                                      }
                                      setState(
                                        () => _pendingSelectedOption = selected,
                                      );
                                    },''', '''                                    onSelect: (selected, correct) {
                                      if (isAnswered ||
                                          _pendingSelectedOption.value != null) {
                                        return;
                                      }
                                      _pendingSelectedOption.value = selected;
                                    },''');

  content = content.replaceAll('''                    if (_pendingSelectedOption != null && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _pendingSelectedOption!,''', '''                    if (_pendingSelectedOption.value != null && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _pendingSelectedOption.value!,''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                );
            },
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: 160.h), // Bottom padding for feedback card
                            ],
                          ),
                        ),''', '''                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: 160.h), // Bottom padding for feedback card
                            ],
                          ),
                        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
