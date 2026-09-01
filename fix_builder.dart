import 'dart:io';

void main() {
  final file = File('lib/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<String> _assembledPieces = [];', 'final ValueNotifier<List<String>> _assembledPieces = ValueNotifier([]);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showTypeToConfirm = false;', 'final ValueNotifier<bool> _showTypeToConfirm = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _textController.dispose();
    _assembledPieces.dispose();
    _showConfetti.dispose();
    _showTypeToConfirm.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    setState(() => _assembledPieces.add(piece));''', '''    _assembledPieces.value = List.from(_assembledPieces.value)..add(piece);''');
  content = content.replaceAll('''    setState(() => _assembledPieces.removeAt(index));''', '''    _assembledPieces.value = List.from(_assembledPieces.value)..removeAt(index);''');

  content = content.replaceAll('''        (!isHardMode && _assembledPieces.isEmpty) ||''', '''        (!isHardMode && _assembledPieces.value.isEmpty) ||''');

  content = content.replaceAll('''    final built = _normalizeAnswer(
      isHardMode ? _textController.text : _assembledPieces.join(' '),
    );''', '''    final built = _normalizeAnswer(
      isHardMode ? _textController.text : _assembledPieces.value.join(' '),
    );''');

  content = content.replaceAll('''      setState(() {
        _showTypeToConfirm = true;
      });''', '''      _showTypeToConfirm.value = true;''');

  content = content.replaceAll('''    setState(() {
      _showTypeToConfirm = false;
    });''', '''    _showTypeToConfirm.value = false;''');

  content = content.replaceAll('''          setState(() {
            _assembledPieces.clear();
            _textController.clear();
            _showTypeToConfirm = false;
          });''', '''          _assembledPieces.value = [];
          _textController.clear();
          _showTypeToConfirm.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                          setState(() => _showTypeToConfirm = false);''', '''                          _showTypeToConfirm.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? const SizedBox.shrink()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _showTypeToConfirm, _assembledPieces]),
            builder: (context, _) {
              return quest == null
                  ? const SizedBox.shrink()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''                      assembledPieces: _assembledPieces,''', '''                      assembledPieces: _assembledPieces.value,''');

  content = content.replaceAll('''                    if (_showTypeToConfirm && !isAnswered)''', '''                    if (_showTypeToConfirm.value && !isAnswered)''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                );
            },
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 40.h),
                if (!isAnswered) _SubmitButton(theme: theme, onTap: onSubmit),
                SizedBox(height: isAnswered ? 160.h : 60.h),
              ],
            ),
          ),
        ),''', '''        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 40.h),
                if (!isAnswered) _SubmitButton(theme: theme, onTap: onSubmit),
                SizedBox(height: isAnswered ? 160.h : 60.h),
              ],
            ),
          ),
        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
