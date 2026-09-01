import 'dart:io';

void main() {
  final file = File('lib/features/writing/daily_journal/presentation/pages/daily_journal_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showSpeakToConfirm = false;', 'final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);');
  content = content.replaceAll('int _wordCount = 0;', 'final ValueNotifier<int> _wordCount = ValueNotifier(0);');
  content = content.replaceAll('double _journalProgress = 0.0;', 'final ValueNotifier<double> _journalProgress = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isSubmitting = false;', 'final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _controller.dispose();
    _showConfetti.dispose();
    _showSpeakToConfirm.dispose();
    _wordCount.dispose();
    _journalProgress.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _wordCount = words;
      _journalProgress = (text.length / 80).clamp(0.0, 1.0);
    });''', '''    _wordCount.value = words;
    _journalProgress.value = (text.length / 80).clamp(0.0, 1.0);''');

  content = content.replaceAll('''    if (isAnswered || _controller.text.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);''', '''    if (isAnswered || _controller.text.trim().isEmpty || _isSubmitting.value) return;

    _isSubmitting.value = true;''');

  content = content.replaceAll('''      setState(() => _isSubmitting = false);''', '''      _isSubmitting.value = false;''');

  content = content.replaceAll('''    if (_wordCount < 10) {''', '''    if (_wordCount.value < 10) {''');

  content = content.replaceAll('''    setState(() {
      _showSpeakToConfirm = true;
      _isSubmitting = false;
    });''', '''    _showSpeakToConfirm.value = true;
    _isSubmitting.value = false;''');

  content = content.replaceAll('''    setState(() => _showSpeakToConfirm = false);''', '''    _showSpeakToConfirm.value = false;''');

  content = content.replaceAll('''          setState(() {
            _controller.clear();
            _wordCount = 0;
            _journalProgress = 0.0;
            _showSpeakToConfirm = false;
          });''', '''          _controller.clear();
          _wordCount.value = 0;
          _journalProgress.value = 0.0;
          _showSpeakToConfirm.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                  setState(() => _showSpeakToConfirm = false);''', '''                                  _showSpeakToConfirm.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: activeQuest == null
              ? const SizedBox()
              : CustomScrollView(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _showSpeakToConfirm, _wordCount, _journalProgress, _isSubmitting]),
            builder: (context, _) {
              return activeQuest == null
                  ? const SizedBox()
                  : CustomScrollView(''');

  // Widget properties
  content = content.replaceAll('''                              wordCount: _wordCount,
                              journalProgress: _journalProgress,''', '''                              wordCount: _wordCount.value,
                              journalProgress: _journalProgress.value,''');

  content = content.replaceAll('''                            if (_showSpeakToConfirm && !isAnswered)''', '''                            if (_showSpeakToConfirm.value && !isAnswered)''');

  content = content.replaceAll('''                                    color: _wordCount >= 10''', '''                                    color: _wordCount.value >= 10''');
  
  content = content.replaceAll('''                                      if (_wordCount >= 10)''', '''                                      if (_wordCount.value >= 10)''');

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
  content = content.replaceAll('''                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_showSpeakToConfirm.value && !isAnswered)
                              SpeakToConfirmOverlay(
                                expectedText: _controller.text.trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  _showSpeakToConfirm.value = false;
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
                              ScaleButton(
                                onTap: () =>
                                    _submitAnswer(targetKeywords, isAnswered),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _wordCount.value >= 10
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount.value >= 10)
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
                                      "CRYSTALLIZE MEMORY",
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
                    ),''', '''                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_showSpeakToConfirm.value && !isAnswered)
                              SpeakToConfirmOverlay(
                                expectedText: _controller.text.trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  _showSpeakToConfirm.value = false;
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
                              ScaleButton(
                                onTap: () =>
                                    _submitAnswer(targetKeywords, isAnswered),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _wordCount.value >= 10
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount.value >= 10)
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
                                      "CRYSTALLIZE MEMORY",
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
