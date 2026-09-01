import 'dart:io';

void main() {
  final file = File('lib/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _sliderValue = 0.5;', 'final ValueNotifier<double> _sliderValue = ValueNotifier(0.5);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _mismatchResetTimer?.cancel();
    _autoplayTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _mismatchResetTimer?.cancel();
    _autoplayTimer?.cancel();
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _sliderValue.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;
    setState(() => _sliderValue = value);''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _sliderValue.value = value;''');

  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;
    setState(() {
      _selectedIndex = index;
      _sliderValue = index == 0 ? 0.0 : 1.0;
    });''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _sliderValue.value = index == 0 ? 0.0 : 1.0;''');

  content = content.replaceAll('''      setState(() {
        _isFirstStagePassed = true;
      });''', '''      _isFirstStagePassed.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''              (!state.answerStatus.isAnswered && _isAnswered)) {''', '''              (!state.answerStatus.isAnswered && _isAnswered.value)) {''');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
              _isFirstStagePassed = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _sliderValue.value = 0.5;
            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          child: AccentBaseLayout(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _sliderValue, _selectedIndex, _isFirstStagePassed]),
            builder: (context, _) {
              return AccentBaseLayout(''');

  // Widget properties
  content = content.replaceAll('''            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                                                  _isFirstStagePassed''', '''                                                                  _isFirstStagePassed.value''');

  content = content.replaceAll('''                                                            _isFirstStagePassed''', '''                                                            _isFirstStagePassed.value''');

  content = content.replaceAll('''                                                if (_isFirstStagePassed && quest.vowelChart != null)''', '''                                                if (_isFirstStagePassed.value && quest.vowelChart != null)''');

  content = content.replaceAll('''                                                                  _isAnswered ||
                                                                  _isFirstStagePassed,
                                                              selectedIndex:
                                                                  _selectedIndex,
                                                              sliderValue:
                                                                  _sliderValue,''', '''                                                                  _isAnswered.value ||
                                                                  _isFirstStagePassed.value,
                                                              selectedIndex:
                                                                  _selectedIndex.value,
                                                              sliderValue:
                                                                  _sliderValue.value,''');

  content = content.replaceAll('''                                                        isAnswered:
                                                            _isAnswered ||
                                                            _isFirstStagePassed,
                                                        selectedIndex: _selectedIndex,
                                                        sliderValue: _sliderValue,''', '''                                                        isAnswered:
                                                            _isAnswered.value ||
                                                            _isFirstStagePassed.value,
                                                        selectedIndex: _selectedIndex.value,
                                                        sliderValue: _sliderValue.value,''');

  content = content.replaceAll('''                                    if (_isFirstStagePassed && !_isAnswered)''', '''                                    if (_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                                      height: (_isAnswered || _isFirstStagePassed) ? 140.h : 20.h,''', '''                                      height: (_isAnswered.value || _isFirstStagePassed.value) ? 140.h : 20.h,''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''                  ),
          ),
        );
      },
    );
  }
}''', '''                  ),
              );
            },
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(''', '''                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
