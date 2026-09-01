import 'dart:io';

void main() {
  final file = File('lib/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final Set<int> _inspectedHotspots = {};', 'final ValueNotifier<Set<int>> _inspectedHotspots = ValueNotifier({});');
  content = content.replaceAll('int _activeHotspot = -1;', 'final ValueNotifier<int> _activeHotspot = ValueNotifier(-1);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _radarController.dispose();
    _inspectedHotspots.dispose();
    _activeHotspot.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('if (_isAnswered || _inspectedHotspots.contains(index)) return;', 'if (_isAnswered.value || _inspectedHotspots.value.contains(index)) return;');

  content = content.replaceAll('''    setState(() {
      _activeHotspot = index;
    });''', '''    _activeHotspot.value = index;''');

  content = content.replaceAll('if (_isAnswered || _activeHotspot == -1) return;', 'if (_isAnswered.value || _activeHotspot.value == -1) return;');

  content = content.replaceAll('''      setState(() {
        _inspectedHotspots.add(_activeHotspot);
        _activeHotspot = -1;
      });''', '''      _inspectedHotspots.value = Set.from(_inspectedHotspots.value)..add(_activeHotspot.value);
      _activeHotspot.value = -1;''');

  content = content.replaceAll('if (_inspectedHotspots.length >= 3) {', 'if (_inspectedHotspots.value.length >= 3) {');

  content = content.replaceAll('''        setState(() {
          _isAnswered = true;
          _isCorrect = true;
        });''', '''        _isAnswered.value = true;
        _isCorrect.value = true;''');

  content = content.replaceAll('''          question: _hotspotPrompts[_activeHotspot],
          userAnswer: '[Failed Self-Evaluation]',
          correctAnswer: _hotspotPrompts[_activeHotspot],''', '''          question: _hotspotPrompts[_activeHotspot.value],
          userAnswer: '[Failed Self-Evaluation]',
          correctAnswer: _hotspotPrompts[_activeHotspot.value],''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _inspectedHotspots.addAll([0, 1, 2]);
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;
    _inspectedHotspots.value = Set.from(_inspectedHotspots.value)..addAll([0, 1, 2]);''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _inspectedHotspots.clear();
              _activeHotspot = -1;
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _inspectedHotspots.value = {};
            _activeHotspot.value = -1;''');

  content = content.replaceAll('''            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });''', '''            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            } else {
              _isAnswered.value = false;
            }''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _activeHotspot, _inspectedHotspots]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                inspectedHotspots: _inspectedHotspots,
                                activeHotspot: _activeHotspot,''', '''                                inspectedHotspots: _inspectedHotspots.value,
                                activeHotspot: _activeHotspot.value,''');

  content = content.replaceAll('''                                child: _activeHotspot != -1
                                    ? SceneDescriptionActivePromptCard(
                                        activeHotspot: _activeHotspot,
                                        activePrompt:
                                            _hotspotPrompts[_activeHotspot],''', '''                                child: _activeHotspot.value != -1
                                    ? SceneDescriptionActivePromptCard(
                                        activeHotspot: _activeHotspot.value,
                                        activePrompt:
                                            _hotspotPrompts[_activeHotspot.value],''');

  // Fix brackets at bottom
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
  content = content.replaceAll('''                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered && _activeHotspot != -1)
                                SpeakingSelfEvaluationControls(
                                  expectedText: _hotspotPrompts[_activeHotspot],
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                            ],
                          ),
                        ),
                      ),''', '''                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered.value && _activeHotspot.value != -1)
                                SpeakingSelfEvaluationControls(
                                  expectedText: _hotspotPrompts[_activeHotspot.value],
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                            ],
                          ),
                        ),
                      ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
