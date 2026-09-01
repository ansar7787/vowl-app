import 'dart:io';

void main() {
  final file = File('lib/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final List<String> _usedKeywords = [];', 'final ValueNotifier<List<String>> _usedKeywords = ValueNotifier([]);');
  content = content.replaceAll('int? _expandedEmojiIndex;', 'final ValueNotifier<int?> _expandedEmojiIndex = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showSpeakToConfirm = false;', 'final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);');
  content = content.replaceAll('int _wordCount = 0;', 'final ValueNotifier<int> _wordCount = ValueNotifier(0);');
  content = content.replaceAll('bool _isSubmitting = false;', 'final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _textController.dispose();
    _usedKeywords.dispose();
    _expandedEmojiIndex.dispose();
    _showConfetti.dispose();
    _showSpeakToConfirm.dispose();
    _wordCount.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _wordCount = words;
    });''', '''    _wordCount.value = words;''');

  content = content.replaceAll('''    setState(
      () => _expandedEmojiIndex = (_expandedEmojiIndex == index ? null : index),
    );''', '''    _expandedEmojiIndex.value = (_expandedEmojiIndex.value == index ? null : index);''');

  content = content.replaceAll('''    setState(() {
      if (!_usedKeywords.contains(keyword)) {
        _usedKeywords.add(keyword);
      }
      _expandedEmojiIndex = null;
    });''', '''    if (!_usedKeywords.value.contains(keyword)) {
      _usedKeywords.value = List.from(_usedKeywords.value)..add(keyword);
    }
    _expandedEmojiIndex.value = null;''');

  content = content.replaceAll('''    if (isAnswered || _textController.text.trim().isEmpty || _isSubmitting) {''', '''    if (isAnswered || _textController.text.trim().isEmpty || _isSubmitting.value) {''');

  content = content.replaceAll('''    setState(() => _isSubmitting = true);''', '''    _isSubmitting.value = true;''');

  content = content.replaceAll('''      setState(() => _isSubmitting = false);''', '''      _isSubmitting.value = false;''');

  content = content.replaceAll('''    if (_wordCount < minWords) {''', '''    if (_wordCount.value < minWords) {''');

  content = content.replaceAll('''    setState(() {
      _showSpeakToConfirm = true;
      _isSubmitting = false;
    });''', '''    _showSpeakToConfirm.value = true;
    _isSubmitting.value = false;''');

  content = content.replaceAll('''    setState(() => _showSpeakToConfirm = false);''', '''    _showSpeakToConfirm.value = false;''');

  content = content.replaceAll('''          setState(() {
            _usedKeywords.clear();
            _textController.clear();
            _expandedEmojiIndex = null;
            _showSpeakToConfirm = false;
          });''', '''          _usedKeywords.value = [];
          _textController.clear();
          _expandedEmojiIndex.value = null;
          _showSpeakToConfirm.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                  setState(() => _showSpeakToConfirm = false);''', '''                                  _showSpeakToConfirm.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: activeQuest == null
              ? const SizedBox()
              : CustomScrollView(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _showSpeakToConfirm, _wordCount, _isSubmitting, _expandedEmojiIndex, _usedKeywords]),
            builder: (context, _) {
              return activeQuest == null
                  ? const SizedBox()
                  : CustomScrollView(''');

  // Widget properties
  content = content.replaceAll('''                              wordCount: _wordCount,
                              usedKeywords: _usedKeywords,''', '''                              wordCount: _wordCount.value,
                              usedKeywords: _usedKeywords.value,''');

  content = content.replaceAll('''                              expandedEmojiIndex: _expandedEmojiIndex,''', '''                              expandedEmojiIndex: _expandedEmojiIndex.value,''');

  content = content.replaceAll('''                            if (_showSpeakToConfirm && !isAnswered)''', '''                            if (_showSpeakToConfirm.value && !isAnswered)''');

  content = content.replaceAll('''                                    color: _wordCount >= minWords''', '''                                    color: _wordCount.value >= minWords''');
  
  content = content.replaceAll('''                                      if (_wordCount >= minWords)''', '''                                      if (_wordCount.value >= minWords)''');

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
                                expectedText: _textController.text.trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  _showSpeakToConfirm.value = false;
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
                              ScaleButton(
                                onTap: () => _submitAnswer(
                                  minWords,
                                  allKeywordPool,
                                  isAnswered,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _wordCount.value >= minWords
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount.value >= minWords)
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
                                      "SEAL NARRATIVE",
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
                                expectedText: _textController.text.trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  _showSpeakToConfirm.value = false;
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
                              ScaleButton(
                                onTap: () => _submitAnswer(
                                  minWords,
                                  allKeywordPool,
                                  isAnswered,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _wordCount.value >= minWords
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_wordCount.value >= minWords)
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
                                      "SEAL NARRATIVE",
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
