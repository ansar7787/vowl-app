import 'dart:io';

void main() {
  final file = File('lib/features/accent/pitch_modulation/presentation/pages/pitch_modulation_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _dialRotation = 0.0;', 'final ValueNotifier<double> _dialRotation = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isDragging = false;', 'final ValueNotifier<bool> _isDragging = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);');
  content = content.replaceAll('int _spokenMeaningsCount = 0;', 'final ValueNotifier<int> _spokenMeaningsCount = ValueNotifier(0);');

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
    _dialRotation.dispose();
    _isDragging.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    _spokenMeaningsCount.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;
    setState(() {
      _isDragging = true;
      // UP drag = negative delta.dy. We want UP to increase rotation to +1.0.
      _dialRotation = (_dialRotation - details.delta.dy / 150.0).clamp(
        -1.0,
        1.0,
      );
    });''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _isDragging.value = true;
    _dialRotation.value = (_dialRotation.value - details.delta.dy / 150.0).clamp(-1.0, 1.0);''');

  content = content.replaceAll('''    // Auto-lock when reaching ends
    if (_dialRotation < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation > 0.8) {
      _submitChoice(1, correct);
    }''', '''    // Auto-lock when reaching ends
    if (_dialRotation.value < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation.value > 0.8) {
      _submitChoice(1, correct);
    }''');

  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed || !_isDragging) return;
    setState(() {
      _isDragging = false;
      if (!_isAnswered) {
        _dialRotation = 0.0;
      }
    });''', '''    if (_isAnswered.value || _isFirstStagePassed.value || !_isDragging.value) return;
    _isDragging.value = false;
    if (!_isAnswered.value) {
      _dialRotation.value = 0.0;
    }''');

  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;
    setState(() {
      _selectedIndex = index;
      _dialRotation = index == 0 ? -0.8 : 0.8;
      _isDragging = false;
    });''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _dialRotation.value = index == 0 ? -0.8 : 0.8;
    _isDragging.value = false;''');

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
              _dialRotation = 0.0;
              _selectedIndex = null;
              _isDragging = false;
              _isFirstStagePassed = false;
              _spokenMeaningsCount = 0;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dialRotation.value = 0.0;
            _selectedIndex.value = null;
            _isDragging.value = false;
            _isFirstStagePassed.value = false;
            _spokenMeaningsCount.value = 0;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                        setState(() => _spokenMeaningsCount = 1);''', '''                                        _spokenMeaningsCount.value = 1;''');

  // Builder Wrap
  content = content.replaceAll('''          child: AccentBaseLayout(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dialRotation, _isDragging, _selectedIndex, _isFirstStagePassed, _spokenMeaningsCount]),
            builder: (context, _) {
              return AccentBaseLayout(''');

  // Widget properties
  content = content.replaceAll('''            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                              instruction: _isFirstStagePassed''', '''                                              instruction: _isFirstStagePassed.value''');

  content = content.replaceAll('''                                              isAnswered:
                                                  _isAnswered || _isFirstStagePassed,
                                              isDragging: _isDragging,
                                              dialRotation: _dialRotation,
                                              selectedIndex: _selectedIndex,''', '''                                              isAnswered:
                                                  _isAnswered.value || _isFirstStagePassed.value,
                                              isDragging: _isDragging.value,
                                              dialRotation: _dialRotation.value,
                                              selectedIndex: _selectedIndex.value,''');

  content = content.replaceAll('''                                if (_isFirstStagePassed && !_isAnswered)
                                  SpeakToConfirmOverlay(
                                    expectedText: quest.textToSpeak ?? "",
                                    displayText: '\${quest.textToSpeak ?? ""}\\n\\n(Meaning: \${options[_spokenMeaningsCount]})',''', '''                                if (_isFirstStagePassed.value && !_isAnswered.value)
                                  SpeakToConfirmOverlay(
                                    expectedText: quest.textToSpeak ?? "",
                                    displayText: '\${quest.textToSpeak ?? ""}\\n\\n(Meaning: \${options[_spokenMeaningsCount.value]})',''');

  content = content.replaceAll('''                                      if (_spokenMeaningsCount == 0) {''', '''                                      if (_spokenMeaningsCount.value == 0) {''');

  content = content.replaceAll('''                                SizedBox(height: _isAnswered ? 180.h : 20.h),''', '''                                SizedBox(height: _isAnswered.value ? 180.h : 20.h),''');

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
