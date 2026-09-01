import 'dart:io';

void main() {
  _fixScreen();
  _fixConsole();
}

void _fixScreen() {
  final file = File('lib/features/accent/dialect_drill/presentation/pages/dialect_drill_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;''');

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
              _shuffleOptions(state.currentQuest as AccentQuest?);
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _shuffleOptions(state.currentQuest as AccentQuest?);''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''        if (originalQuest != null && _shuffledOptions == null) {''', '''        if (originalQuest != null && _shuffledOptions == null && !_isAnswered.value) {''');

  // Builder Wrap
  content = content.replaceAll('''          child: AccentBaseLayout(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isFirstStagePassed]),
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
                                              isCorrect: _isFirstStagePassed
                                                  ? true
                                                  : _isCorrect,''', '''                                              isAnswered:
                                                  _isAnswered.value || _isFirstStagePassed.value,
                                              isCorrect: _isFirstStagePassed.value
                                                  ? true
                                                  : _isCorrect.value,''');

  content = content.replaceAll('''                                  child: (_isAnswered || _isFirstStagePassed)''', '''                                  child: (_isAnswered.value || _isFirstStagePassed.value)''');

  content = content.replaceAll('''                                                      _isCorrect == true ||
                                                      _isFirstStagePassed;''', '''                                                      _isCorrect.value == true ||
                                                      _isFirstStagePassed.value;''');

  content = content.replaceAll('''                                                    isCorrect:
                                                        _isCorrect ??
                                                        _isFirstStagePassed,''', '''                                                    isCorrect:
                                                        _isCorrect.value ??
                                                        _isFirstStagePassed.value,''');

  content = content.replaceAll('''                                              if (_isFirstStagePassed && !_isAnswered) ...[''', '''                                              if (_isFirstStagePassed.value && !_isAnswered.value) ...[''');

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

void _fixConsole() {
  final file = File('lib/features/accent/dialect_drill/presentation/widgets/dialect_drill_hologram_console.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('''  int? _hoveredTowerIndex;

  @override
  void didUpdateWidget(covariant DialectDrillHologramConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest ||
        (!widget.isAnswered && oldWidget.isAnswered)) {
      setState(() {
        _hoveredTowerIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(''', '''  final ValueNotifier<int?> _hoveredTowerIndex = ValueNotifier(null);

  @override
  void didUpdateWidget(covariant DialectDrillHologramConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest ||
        (!widget.isAnswered && oldWidget.isAnswered)) {
      _hoveredTowerIndex.value = null;
    }
  }
  
  @override
  void dispose() {
    _hoveredTowerIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: _hoveredTowerIndex,
      builder: (context, hoveredTowerIndex, child) {
        return Column(''');

  content = content.replaceAll('''          setState(() => _hoveredTowerIndex = index);''', '''          _hoveredTowerIndex.value = index;''');

  content = content.replaceAll('''              setState(() => _hoveredTowerIndex = index);''', '''              _hoveredTowerIndex.value = index;''');

  content = content.replaceAll('''            setState(() => _hoveredTowerIndex = null);''', '''            _hoveredTowerIndex.value = null;''');

  content = content.replaceAll('''          setState(() => _hoveredTowerIndex = index); // Lock selection visually''', '''          _hoveredTowerIndex.value = index; // Lock selection visually''');

  content = content.replaceAll('''_hoveredTowerIndex != null''', '''hoveredTowerIndex != null''');
  content = content.replaceAll('''_hoveredTowerIndex != index''', '''hoveredTowerIndex != index''');
  content = content.replaceAll('''_hoveredTowerIndex == index''', '''hoveredTowerIndex == index''');

  content = content.replaceAll('''      ],
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }''', '''      ],
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
      },
    );
  }''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
