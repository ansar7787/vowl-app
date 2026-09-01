import 'dart:io';

void main() {
  final file = File('lib/features/accent/speed_variance/presentation/pages/speed_variance_screen.dart');
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
  content = content.replaceAll('bool _isNaturalSpeed = true;', 'final ValueNotifier<bool> _isNaturalSpeed = ValueNotifier(true);');

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
    _isNaturalSpeed.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;''');

  content = content.replaceAll('''    setState(() {
      _isDragging = true;
      _dialRotation = (_dialRotation + totalRot).clamp(-1.0, 1.0);
    });''', '''    _isDragging.value = true;
    _dialRotation.value = (_dialRotation.value + totalRot).clamp(-1.0, 1.0);''');

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

  content = content.replaceAll('''    setState(() {
      _selectedIndex = index;
      _dialRotation = index == 0 ? -0.8 : 0.8;
      _isDragging = false;
    });''', '''    _selectedIndex.value = index;
    _dialRotation.value = index == 0 ? -0.8 : 0.8;
    _isDragging.value = false;''');

  content = content.replaceAll('''      setState(() {
        _isFirstStagePassed = true;
      });''', '''      _isFirstStagePassed.value = true;''');

  content = content.replaceAll('''      setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _timerKey.currentState?.stop();
    });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;
      _timerKey.currentState?.stop();''');

  content = content.replaceAll('''  if (_isAnswered || _isFirstStagePassed) return;
  setState(() {
    _isAnswered = true;
    _isCorrect = false;
  });''', '''  if (_isAnswered.value || _isFirstStagePassed.value) return;
  _isAnswered.value = true;
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
              _isNaturalSpeed = true;
              if (!_isAnswered) _timerKey.currentState?.start();
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dialRotation.value = 0.0;
            _selectedIndex.value = null;
            _isDragging.value = false;
            _isFirstStagePassed.value = false;
            _isNaturalSpeed.value = true;
            if (!_isAnswered.value) _timerKey.currentState?.start();''');

  content = content.replaceAll('''          setState(() => _showConfetti = true);''', '''          _showConfetti.value = true;''');

  content = content.replaceAll('''                                                setState(() => _isNaturalSpeed = val);''', '''                                                _isNaturalSpeed.value = val;''');

  // Builder Wrap
  content = content.replaceAll('''            child: LayoutBuilder(''', '''            child: ListenableBuilder(
              listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dialRotation, _isDragging, _selectedIndex, _isFirstStagePassed, _isNaturalSpeed]),
              builder: (context, _) {
                return LayoutBuilder(''');

  // Widget properties
  content = content.replaceAll('''            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                      if (!_isFirstStagePassed && !_isAnswered)''', '''                                      if (!_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                                        instruction: _isFirstStagePassed''', '''                                        instruction: _isFirstStagePassed.value''');

  content = content.replaceAll('''                                        if (_isFirstStagePassed && !_isAnswered)''', '''                                        if (_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                                              isNatural: _isNaturalSpeed,''', '''                                              isNatural: _isNaturalSpeed.value,''');

  content = content.replaceAll('''                                            speed: _isFirstStagePassed
                                                ? (_isNaturalSpeed ? (quest.naturalSpeed ?? 1.0) : (quest.clearSpeed ?? 0.75))''', '''                                            speed: _isFirstStagePassed.value
                                                ? (_isNaturalSpeed.value ? (quest.naturalSpeed ?? 1.0) : (quest.clearSpeed ?? 0.75))''');

  content = content.replaceAll('''                                        isAnswered:
                                            _isAnswered || _isFirstStagePassed,
                                        isDragging: _isDragging,
                                        dialRotation: _dialRotation,
                                        selectedIndex: _selectedIndex,''', '''                                        isAnswered:
                                            _isAnswered.value || _isFirstStagePassed.value,
                                        isDragging: _isDragging.value,
                                        dialRotation: _dialRotation.value,
                                        selectedIndex: _selectedIndex.value,''');

  content = content.replaceAll('''                          if (_isFirstStagePassed && !_isAnswered)''', '''                          if (_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                          SizedBox(height: _isAnswered || _isFirstStagePassed ? 140.h : 0),''', '''                          SizedBox(height: _isAnswered.value || _isFirstStagePassed.value ? 140.h : 0),''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''            ),
          ),
        );
      },
    );
  }
}''', '''              );
            },
          ),
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(''', '''                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
