import 'dart:io';

void main() {
  final file = File('lib/features/accent/word_linking/presentation/pages/word_linking_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('int? _selectedNodeIndex;', 'final ValueNotifier<int?> _selectedNodeIndex = ValueNotifier(null);');
  content = content.replaceAll('bool _isFirstStagePassed = false;', 'final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);');

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
    _selectedNodeIndex.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    if (_isAnswered || _isFirstStagePassed) return;''', '''    if (_isAnswered.value || _isFirstStagePassed.value) return;''');

  content = content.replaceAll('''    setState(() {
      _selectedNodeIndex = index;
    });''', '''    _selectedNodeIndex.value = index;''');

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
              _selectedNodeIndex = null;
              _isFirstStagePassed = false;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedNodeIndex.value = null;
            _isFirstStagePassed.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          child: AccentBaseLayout(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedNodeIndex, _isFirstStagePassed]),
            builder: (context, _) {
              return AccentBaseLayout(''');

  // Widget properties
  content = content.replaceAll('''            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''                                                      instruction: _isFirstStagePassed''', '''                                                      instruction: _isFirstStagePassed.value''');

  content = content.replaceAll('''                                                instruction: _isFirstStagePassed''', '''                                                instruction: _isFirstStagePassed.value''');


  content = content.replaceAll('''                                                      isAnswered:
                                                          _isAnswered ||
                                                          _isFirstStagePassed,
                                                      selectedNodeIndex:
                                                          _selectedNodeIndex,''', '''                                                      isAnswered:
                                                          _isAnswered.value ||
                                                          _isFirstStagePassed.value,
                                                      selectedNodeIndex:
                                                          _selectedNodeIndex.value,''');

  content = content.replaceAll('''                                                isAnswered:
                                                    _isAnswered ||
                                                    _isFirstStagePassed,
                                                selectedNodeIndex: _selectedNodeIndex,''', '''                                                isAnswered:
                                                    _isAnswered.value ||
                                                    _isFirstStagePassed.value,
                                                selectedNodeIndex: _selectedNodeIndex.value,''');

  content = content.replaceAll('''                                if (_isFirstStagePassed && !_isAnswered)''', '''                                if (_isFirstStagePassed.value && !_isAnswered.value)''');

  content = content.replaceAll('''                                SizedBox(height: (_isAnswered || _isFirstStagePassed) ? 380.h : 20.h),''', '''                                SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 380.h : 20.h),''');

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
