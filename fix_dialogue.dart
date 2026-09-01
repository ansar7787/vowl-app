import 'dart:io';

void main() {
  final file = File('lib/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('double _timeVal = 0.0;', 'final ValueNotifier<double> _timeVal = ValueNotifier(0.0);');
  content = content.replaceAll('List<String> _smartReplies = [];', 'final ValueNotifier<List<String>> _smartReplies = ValueNotifier([]);');
  content = content.replaceAll('String _chosenReply = "";', 'final ValueNotifier<String> _chosenReply = ValueNotifier("");');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _synapticController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _synapticController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    _smartReplies.dispose();
    _chosenReply.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    _synapticController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
            setState(() {
              _timeVal = _synapticController.value;
            });
          });''', '''    _synapticController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
            _timeVal.value = _synapticController.value;
          });''');

  content = content.replaceAll('''      final suggestions = await smartReplyService.getSuggestions();
      if (mounted) {
        setState(() {
          _smartReplies = suggestions
              .where(
                (s) => s.trim().length > 1 && RegExp(r'[a-zA-Z]').hasMatch(s),
              )
              .toList();
          final fallbackOptions = quest.smartReplies ?? quest.acceptedSynonyms;
          if (fallbackOptions != null) {
            final List<String> availableSynonyms = List.from(fallbackOptions)
              ..shuffle();

            for (var synonym in availableSynonyms) {
              if (_smartReplies.length >= 3) break;
              if (!_smartReplies.contains(synonym)) {
                _smartReplies.add(synonym);
              }
            }
          }
        });
      }''', '''      final suggestions = await smartReplyService.getSuggestions();
      if (mounted) {
        final List<String> newReplies = suggestions
            .where(
              (s) => s.trim().length > 1 && RegExp(r'[a-zA-Z]').hasMatch(s),
            )
            .toList();
        final fallbackOptions = quest.smartReplies ?? quest.acceptedSynonyms;
        if (fallbackOptions != null) {
          final List<String> availableSynonyms = List.from(fallbackOptions)
            ..shuffle();

          for (var synonym in availableSynonyms) {
            if (newReplies.length >= 3) break;
            if (!newReplies.contains(synonym)) {
              newReplies.add(synonym);
            }
          }
        }
        _smartReplies.value = newReplies;
      }''');

  content = content.replaceAll('if (_isAnswered) return;', 'if (_isAnswered.value) return;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = nailedIt;''');

  content = content.replaceAll('''      final responseText = _chosenReply.isNotEmpty
          ? _chosenReply
          : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "Yes");''', '''      final responseText = _chosenReply.value.isNotEmpty
          ? _chosenReply.value
          : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "Yes");''');

  content = content.replaceAll('''          question: _chosenReply.isNotEmpty ? _chosenReply : 'Roleplay',
          userAnswer: '[Failed Dialogue]',
          correctAnswer: _chosenReply.isNotEmpty ? _chosenReply : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : ''),''', '''          question: _chosenReply.value.isNotEmpty ? _chosenReply.value : 'Roleplay',
          userAnswer: '[Failed Dialogue]',
          correctAnswer: _chosenReply.value.isNotEmpty ? _chosenReply.value : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : ''),''');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = true;''');

  content = content.replaceAll('(!state.answerStatus.isAnswered && _isAnswered)', '(!state.answerStatus.isAnswered && _isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _smartReplies = [];
              _chosenReply = "";
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _smartReplies.value = [];
            _chosenReply.value = "";''');

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

  // Builder updates
  content = content.replaceAll('''        final expectedText = _chosenReply.isNotEmpty
            ? _chosenReply
            : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "");

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,''', '''        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _timeVal, _smartReplies, _chosenReply]),
            builder: (context, _) {
              final expectedText = _chosenReply.value.isNotEmpty
                  ? _chosenReply.value
                  : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "");

              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,''');

  // Widget properties
  content = content.replaceAll('''                                timeVal: _timeVal,
                                isAnswered: _isAnswered,
                                isCorrect: _isCorrect ?? false,''', '''                                timeVal: _timeVal.value,
                                isAnswered: _isAnswered.value,
                                isCorrect: _isCorrect.value ?? false,''');

  content = content.replaceAll('''                              if (_smartReplies.isNotEmpty && !_isAnswered) ...[''', '''                              if (_smartReplies.value.isNotEmpty && !_isAnswered.value) ...[''');

  content = content.replaceAll('''                                    itemCount: _smartReplies.length,
                                    itemBuilder: (context, index) {
                                      final reply = _smartReplies[index];''', '''                                    itemCount: _smartReplies.value.length,
                                    itemBuilder: (context, index) {
                                      final reply = _smartReplies.value[index];''');

  content = content.replaceAll('''                                              setState(() {
                                                _chosenReply = reply;
                                              });''', '''                                              _chosenReply.value = reply;''');

  content = content.replaceAll('''                              if (!_isAnswered)''', '''                              if (!_isAnswered.value)''');

  // Fix brackets at the bottom
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
                              if (!_isAnswered.value)
                                SpeakingSelfEvaluationControls(
                                  expectedText: expectedText,
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
                              if (!_isAnswered.value)
                                SpeakingSelfEvaluationControls(
                                  expectedText: expectedText,
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
