import 'dart:io';

void main() {
  final file = File('lib/features/writing/opinion_writing/presentation/pages/opinion_writing_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<String> _leftPanArgs = [];', 'final ValueNotifier<List<String>> _leftPanArgs = ValueNotifier([]);');
  content = content.replaceAll('final List<String> _rightPanArgs = [];', 'final ValueNotifier<List<String>> _rightPanArgs = ValueNotifier([]);');
  content = content.replaceAll('double _scaleRotation = 0.0;', 'final ValueNotifier<double> _scaleRotation = ValueNotifier(0.0);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('List<String> _shuffledOptions = [];', 'final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);');
  content = content.replaceAll('bool _pendingScaleSubmit = false;', 'final ValueNotifier<bool> _pendingScaleSubmit = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _leftPanArgs.dispose();
    _rightPanArgs.dispose();
    _scaleRotation.dispose();
    _showConfetti.dispose();
    _shuffledOptions.dispose();
    _pendingScaleSubmit.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _leftPanArgs.remove(arg);
      _rightPanArgs.remove(arg);

      if (isLeft) {
        _leftPanArgs.add(arg);
      } else {
        _rightPanArgs.add(arg);
      }

      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.06).clamp(-0.15, 0.15);
    });''', '''    final newLeft = List<String>.from(_leftPanArgs.value)..remove(arg);
    final newRight = List<String>.from(_rightPanArgs.value)..remove(arg);

    if (isLeft) {
      newLeft.add(arg);
    } else {
      newRight.add(arg);
    }

    _leftPanArgs.value = newLeft;
    _rightPanArgs.value = newRight;

    double diff = (newLeft.length - newRight.length).toDouble();
    _scaleRotation.value = (diff * 0.06).clamp(-0.15, 0.15);''');

  content = content.replaceAll('''    setState(() {
      if (isLeft) {
        _leftPanArgs.remove(arg);
      } else {
        _rightPanArgs.remove(arg);
      }

      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.06).clamp(-0.15, 0.15);
    });''', '''    final newLeft = List<String>.from(_leftPanArgs.value);
    final newRight = List<String>.from(_rightPanArgs.value);

    if (isLeft) {
      newLeft.remove(arg);
    } else {
      newRight.remove(arg);
    }
    
    _leftPanArgs.value = newLeft;
    _rightPanArgs.value = newRight;

    double diff = (newLeft.length - newRight.length).toDouble();
    _scaleRotation.value = (diff * 0.06).clamp(-0.15, 0.15);''');

  content = content.replaceAll('''    setState(() {
      _pendingScaleSubmit = true;
    });''', '''    _pendingScaleSubmit.value = true;''');

  content = content.replaceAll('''    setState(() {
      _pendingScaleSubmit = false;
    });''', '''    _pendingScaleSubmit.value = false;''');

  content = content.replaceAll('''    bool isLeftCorrect =
        _leftPanArgs.length == 2 &&
        _leftPanArgs.every((arg) => correctPros.contains(arg));
    bool isRightCorrect =
        _rightPanArgs.length == 2 &&
        _rightPanArgs.every((arg) => correctCons.contains(arg));''', '''    bool isLeftCorrect =
        _leftPanArgs.value.length == 2 &&
        _leftPanArgs.value.every((arg) => correctPros.contains(arg));
    bool isRightCorrect =
        _rightPanArgs.value.length == 2 &&
        _rightPanArgs.value.every((arg) => correctCons.contains(arg));''');

  content = content.replaceAll('''          setState(() {
            _leftPanArgs.clear();
            _rightPanArgs.clear();
            _scaleRotation = 0.0;
            _pendingScaleSubmit = false;

            // Randomize options for pedagogical integrity
            _shuffledOptions = List.from(state.currentQuest.options ?? []);
            _shuffledOptions.shuffle();
          });''', '''          _leftPanArgs.value = [];
          _rightPanArgs.value = [];
          _scaleRotation.value = 0.0;
          _pendingScaleSubmit.value = false;
          _shuffledOptions.value = List.from(state.currentQuest.options ?? [])..shuffle();''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? const SizedBox()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _leftPanArgs, _rightPanArgs, _scaleRotation, _shuffledOptions, _pendingScaleSubmit]),
            builder: (context, _) {
              final options = _shuffledOptions.value.isNotEmpty
                  ? _shuffledOptions.value
                  : (quest?.options ?? []);
              final totalPlaced = _leftPanArgs.value.length + _rightPanArgs.value.length;

              return quest == null
                  ? const SizedBox()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''        final options = _shuffledOptions.isNotEmpty
            ? _shuffledOptions
            : (quest?.options ?? []);
        final totalPlaced = _leftPanArgs.length + _rightPanArgs.length;''', '''''');

  content = content.replaceAll('''                                OpinionWritingScaleInterface(
                                  scaleRotation: _scaleRotation,
                                  leftPanArgs: _leftPanArgs,
                                  rightPanArgs: _rightPanArgs,''', '''                                OpinionWritingScaleInterface(
                                  scaleRotation: _scaleRotation.value,
                                  leftPanArgs: _leftPanArgs.value,
                                  rightPanArgs: _rightPanArgs.value,''');

  content = content.replaceAll('''                                OpinionWritingArgumentStones(
                                  options: options,
                                  leftPanArgs: _leftPanArgs,
                                  rightPanArgs: _rightPanArgs,''', '''                                OpinionWritingArgumentStones(
                                  options: options,
                                  leftPanArgs: _leftPanArgs.value,
                                  rightPanArgs: _rightPanArgs.value,''');

  content = content.replaceAll('''                    if (_pendingScaleSubmit && !isAnswered)''', '''                    if (_pendingScaleSubmit.value && !isAnswered)''');

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
  content = content.replaceAll('''                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isAnswered)
                                  ScaleButton(
                                    onTap: totalPlaced == 4
                                        ? () => _submitAnswer(isAnswered)
                                        : null,
                                    child: Container(
                                      width: double.infinity,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        color: totalPlaced == 4
                                            ? theme.primaryColor
                                            : Colors.grey,
                                        boxShadow: [
                                          if (totalPlaced == 4)
                                            BoxShadow(
                                              color: theme.primaryColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 15,
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          totalPlaced == 4
                                              ? "BALANCE THE TRUTH"
                                              : "PLACE \${4 - totalPlaced} MORE CARDS",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: isAnswered ? 160.h : 60.h),
                              ],
                            ),
                          ),
                        ),''', '''                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isAnswered)
                                  ScaleButton(
                                    onTap: totalPlaced == 4
                                        ? () => _submitAnswer(isAnswered)
                                        : null,
                                    child: Container(
                                      width: double.infinity,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        color: totalPlaced == 4
                                            ? theme.primaryColor
                                            : Colors.grey,
                                        boxShadow: [
                                          if (totalPlaced == 4)
                                            BoxShadow(
                                              color: theme.primaryColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 15,
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          totalPlaced == 4
                                              ? "BALANCE THE TRUTH"
                                              : "PLACE \${4 - totalPlaced} MORE CARDS",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: isAnswered ? 160.h : 60.h),
                              ],
                            ),
                          ),
                        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
