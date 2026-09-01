import 'dart:io';

void main() {
  final file = File('lib/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);');
  content = content.replaceAll('double _currentSpeed = 1.0;', 'final ValueNotifier<double> _currentSpeed = ValueNotifier(1.0);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    _currentSpeed.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    // Assuming base speed is around 0.4. We'll adjust it by _currentSpeed.
    _soundService.playTts(text, speed: 0.4 * _currentSpeed);''', '''    // Assuming base speed is around 0.4. We'll adjust it by _currentSpeed.
    _soundService.playTts(text, speed: 0.4 * _currentSpeed.value);''');

  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;
    setState(() {
      _selectedIndex = index;
    });''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;''');

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
              _isFirstStagePassed = false;

              _selectedIndex = null;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _selectedIndex.value = null;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''              _currentSpeed = quest.speedLevel ?? 1.0;''', '''              _currentSpeed.value = quest.speedLevel ?? 1.0;''');

  content = content.replaceAll('''                                            setState(() {
                                              _currentSpeed = val;
                                            });''', '''                                            _currentSpeed.value = val;''');

  // Builder Wrap
  content = content.replaceAll('''          child: AccentBaseLayout(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _isFirstStagePassed, _currentSpeed]),
            builder: (context, _) {
              return AccentBaseLayout(''');

  // Widget properties
  content = content.replaceAll('''            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                          instruction: _isFirstStagePassed''', '''                                          instruction: _isFirstStagePassed.value''');

  content = content.replaceAll('''                                          speed: _currentSpeed,''', '''                                          speed: _currentSpeed.value,''');

  content = content.replaceAll('''                                          isAnswered:
                                              _isAnswered || _isFirstStagePassed,
                                          selectedIndex: _selectedIndex,''', '''                                          isAnswered:
                                              _isAnswered.value || _isFirstStagePassed.value,
                                          selectedIndex: _selectedIndex.value,''');

  content = content.replaceAll('''                                if (_isFirstStagePassed && !_isAnswered)''', '''                                if (_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                                    speedMultiplier: _currentSpeed,''', '''                                    speedMultiplier: _currentSpeed.value,''');

  content = content.replaceAll('''                                SizedBox(height: (_isAnswered || _isFirstStagePassed) ? 380.h : 24.h),''', '''                                SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 380.h : 24.h),''');

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
  content = content.replaceAll('''                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(''', '''                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
