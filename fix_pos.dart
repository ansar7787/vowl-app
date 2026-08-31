import 'dart:io';

void main() {
  final file = File('lib/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('Offset _dragOffset = Offset.zero;', 'final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);');
  content = content.replaceAll('bool _isAnswered = false;', 'final ValueNotifier<bool> _isAnswered = ValueNotifier(false);');
  content = content.replaceAll('bool? _isCorrect;', 'final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _isSubmitting = false;', 'final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingTypeSubmit = false;', 'final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _dragOffset.dispose();\n    _isAnswered.dispose();\n    _isCorrect.dispose();\n    _showConfetti.dispose();\n    _isSubmitting.dispose();\n    _pendingTypeSubmit.dispose();\n    super.dispose();\n  }');

  // In _onFlick
  content = content.replaceAll('if (_isAnswered || _isSubmitting) return;', 'if (_isAnswered.value || _isSubmitting.value) return;');
  content = content.replaceAll('_isSubmitting = true;', '_isSubmitting.value = true;');
  
  content = content.replaceAll('''      setState(() {
        _pendingTypeSubmit = true;
      });''', '''      _pendingTypeSubmit.value = true;''');

  content = content.replaceAll('''      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });''', '''      _isAnswered.value = true;
      _isCorrect.value = false;''');

  content = content.replaceAll('setState(() => _pendingTypeSubmit = false);', '_pendingTypeSubmit.value = false;');

  content = content.replaceAll('''    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });''', '''    _isAnswered.value = true;
    _isCorrect.value = correct;''');

  content = content.replaceAll('if (_pendingTypeSubmit || _isAnswered) return;', 'if (_pendingTypeSubmit.value || _isAnswered.value) return;');
  
  content = content.replaceAll('final distance = _dragOffset.distance;', 'final distance = _dragOffset.value.distance;');
  
  content = content.replaceAll('final targetIndex = switch ((_dragOffset.dx < 0, _dragOffset.dy < 0)) {', 'final targetIndex = switch ((_dragOffset.value.dx < 0, _dragOffset.value.dy < 0)) {');

  // ListenableBuilder Wrap
  content = content.replaceAll('''        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,''', '''        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dragOffset, _isSubmitting, _pendingTypeSubmit]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,''');

  // In _PosQuestLayout usage
  content = content.replaceAll('dragOffset: _dragOffset,', 'dragOffset: _dragOffset.value,');
  content = content.replaceAll('isAnswered: _isAnswered || _pendingTypeSubmit,', 'isAnswered: _isAnswered.value || _pendingTypeSubmit.value,');
  content = content.replaceAll('setState(() => _dragOffset += details.delta);', '_dragOffset.value += details.delta;');
  content = content.replaceAll('setState(() => _dragOffset = Offset.zero);', '_dragOffset.value = Offset.zero;');

  content = content.replaceAll('''        setState(() {
          _lastProcessedIndex = state.currentIndex;
          _isAnswered = false;
          _isCorrect = null;
          _dragOffset = Offset.zero;
          _isSubmitting = false;
          _pendingTypeSubmit = false;
        });''', '''        _lastProcessedIndex = state.currentIndex;
        _isAnswered.value = false;
        _isCorrect.value = null;
        _dragOffset.value = Offset.zero;
        _isSubmitting.value = false;
        _pendingTypeSubmit.value = false;''');

  content = content.replaceAll('final isRetry = _isAnswered && !state.answerStatus.isAnswered;', 'final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;');
  content = content.replaceAll('if (state.answerStatus.isAnswered && !_isAnswered)', 'if (state.answerStatus.isAnswered && !_isAnswered.value)');

  content = content.replaceAll('''        setState(() {
          _isAnswered = true;
          _isCorrect = state.answerStatus.asBoolOrNull;
        });''', '''        _isAnswered.value = true;
        _isCorrect.value = state.answerStatus.asBoolOrNull;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Sliver Layout Fix
  // Right now, the Stack contains CustomScrollView and the TypeToConfirmOverlay.
  // We need to move the TypeToConfirmOverlay INSIDE the CustomScrollView's slivers array!
  content = content.replaceAll('''                            SizedBox(height: (_isAnswered || _pendingTypeSubmit) ? 160.h : 60.h),
                          ],
                        ),
                      ),
                    ],
                  );
                  },
                ),
                  if (_pendingTypeSubmit && !_isAnswered && cleanTargetSentence.isNotEmpty)
                    TypeToConfirmOverlay(
                      expectedText: cleanTargetSentence,
                      displayText: "Type the complete sentence to lock in the part of speech",
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(true),
                      onSkipped: () => _submitFinalAnswer(false),
                      allowSkip: true,
                    ),
                ],
              ),
        );
      },
    );
  }''', '''                          ],
                        ),
                      ),
                      if (_pendingTypeSubmit.value && !_isAnswered.value && cleanTargetSentence.isNotEmpty)
                        SliverToBoxAdapter(
                          child: TypeToConfirmOverlay(
                            expectedText: cleanTargetSentence,
                            displayText: "Type the complete sentence to lock in the part of speech",
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true),
                            onSkipped: () => _submitFinalAnswer(false),
                            allowSkip: true,
                            isPositioned: false,
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: (_isAnswered.value || _pendingTypeSubmit.value) ? 160.h : 60.h),
                      ),
                    ],
                  );
                  },
                ),
            );
          },
        );
      },
    );
  }''');

  // Also remove the `Stack` completely.
  content = content.replaceAll('''              : Stack(
                  children: [
                    LayoutBuilder(
                  builder: (context, constraints) {''', '''              : LayoutBuilder(
                  builder: (context, constraints) {''');
                  
  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
