import 'dart:io';

void main() {
  final file = File('lib/features/writing/correction_writing/presentation/pages/correction_writing_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('String? _selectedCorrection;', 'final ValueNotifier<String?> _selectedCorrection = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showEvidence = false;', 'final ValueNotifier<bool> _showEvidence = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _selectedCorrection.dispose();
    _showConfetti.dispose();
    _showEvidence.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _selectedCorrection = choice;
    });''', '''    _selectedCorrection.value = choice;''');

  content = content.replaceAll('''        (!isHardMode && _selectedCorrection == null) ||''', '''        (!isHardMode && _selectedCorrection.value == null) ||''');

  content = content.replaceAll('''      correct = _selectedCorrection == quest.correctAnswer;''', '''      correct = _selectedCorrection.value == quest.correctAnswer;''');

  content = content.replaceAll('''      if ((quest.options?.isNotEmpty ?? false) && _selectedCorrection != null) {
        setState(() => _showEvidence = true);
      }''', '''      if ((quest.options?.isNotEmpty ?? false) && _selectedCorrection.value != null) {
        _showEvidence.value = true;
      }''');

  content = content.replaceAll('''          setState(() {
            _selectedCorrection = null;
            _showEvidence = false;
          });''', '''          _selectedCorrection.value = null;
          _showEvidence.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                          setState(() => _showEvidence = false);''', '''                          _showEvidence.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: activeQuest == null
              ? const SizedBox()
              : CustomScrollView(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _selectedCorrection, _showEvidence]),
            builder: (context, _) {
              return activeQuest == null
                  ? const SizedBox()
                  : CustomScrollView(''');

  // Widget properties
  content = content.replaceAll('''                                  ? null
                                  : _selectedCorrection,''', '''                                  ? null
                                  : _selectedCorrection.value,''');

  content = content.replaceAll('''                                selectedCorrection: _selectedCorrection,''', '''                                selectedCorrection: _selectedCorrection.value,''');

  content = content.replaceAll('''                                onTap: _selectedCorrection != null''', '''                                onTap: _selectedCorrection.value != null''');

  content = content.replaceAll('''                                        color: _selectedCorrection != null''', '''                                        color: _selectedCorrection.value != null''');

  content = content.replaceAll('''                                      if (_selectedCorrection != null)''', '''                                      if (_selectedCorrection.value != null)''');

  content = content.replaceAll('''                    if (_showEvidence && !isAnswered)
                      EvidenceHighlightWrapper(
                        passage: (activeQuest.passage ?? "").replaceAll(RegExp(r'\\[(.*?)\\]'), _selectedCorrection ?? ""),
                        evidenceWords: [_selectedCorrection ?? ""],''', '''                    if (_showEvidence.value && !isAnswered)
                      EvidenceHighlightWrapper(
                        passage: (activeQuest.passage ?? "").replaceAll(RegExp(r'\\[(.*?)\\]'), _selectedCorrection.value ?? ""),
                        evidenceWords: [_selectedCorrection.value ?? ""],''');

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
                            if (!isAnswered && widget.level < 6)
                              ScaleButton(
                                onTap: _selectedCorrection.value != null
                                    ? () => _submitAnswer(isAnswered)
                                    : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _selectedCorrection.value != null
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_selectedCorrection.value != null)
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
                                      "AUDIT SYNTAX",
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
                            if (!isAnswered && widget.level < 6)
                              ScaleButton(
                                onTap: _selectedCorrection.value != null
                                    ? () => _submitAnswer(isAnswered)
                                    : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _selectedCorrection.value != null
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_selectedCorrection.value != null)
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
                                      "AUDIT SYNTAX",
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
