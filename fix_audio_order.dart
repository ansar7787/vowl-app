import 'dart:io';

void main() {
  final file = File('lib/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('List<String> _slots = [];\n  List<String> _segments = [];\n  bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    super.dispose();\n  }');

  // Clean up legacy logic in submitAnswer
  content = content.replaceAll('''  void _submitAnswer(String correctFull) {
    if (_isAnswered) return;

    if (_segments.isNotEmpty) {
      CustomSnackBar.show(
        context: context,
        message: "Please place all segments in the timeline!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    String current = _slots
        .join(" ")
        .replaceAll(RegExp(r'[^\\w\\s]'), '')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim()
        .toLowerCase();
    String target = correctFull
        .replaceAll(RegExp(r'[^\\w\\s]'), '')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim()
        .toLowerCase();
    bool isCorrect = current == target;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Sentence Order',
          userAnswer: current,
          correctAnswer: target,
          level: widget.level,
        );
      }
      
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }''', '''  void _submitAnswer(String correctFull) {
    if (_isAnswered.value) return;

    _hapticService.success();
    _soundService.playCorrect();
    _isAnswered.value = true;
    _isCorrect.value = true;
    context.read<ListeningBloc>().add(SubmitAnswer(true));
  }'''); // _submitAnswer is ONLY called onConfirmed, meaning they already solved the Jigsaw internally!

  content = content.replaceAll('''            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _segments = List.from(state.currentQuest.shuffledSentences ?? []);
              _slots = List.generate(_segments.length, (_) => "");
            });''', '''            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });''', '''            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                    setState(() {
                                      _isAnswered = true;
                                      _isCorrect = false;
                                    });''', '''                                    _isAnswered.value = true;
                                    _isCorrect.value = false;''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,''');

  // Widget state accesses
  content = content.replaceAll('''                                isCorrectState: _isCorrect,''', '''                                isCorrectState: _isCorrect.value,''');
  content = content.replaceAll('''                              if (!_isAnswered)''', '''                              if (!_isAnswered.value)''');

  // Fix bracket at the bottom
  content = content.replaceAll('''                    ],
                  ),
        );
      },
    );
  }
}''', '''                    ],
                  ),
            );
          },
        );
      },
    );
  }
}''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
