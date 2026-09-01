import 'dart:io';

void main() {
  final file = File('lib/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('List<DescribeFrameSlot> _slots = [];', 'final ValueNotifier<List<DescribeFrameSlot>> _slots = ValueNotifier([]);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingSubmit = false;', 'final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _slots.dispose();
    _showConfetti.dispose();
    _pendingSubmit.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _slots[slotIdx].sentence = sentence;
    });''', '''    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = sentence;
    _slots.value = newSlots;''');

  content = content.replaceAll('''    final firstEmptyIdx = _slots.indexWhere((s) => s.sentence == null);
    if (firstEmptyIdx != -1) {
      _hapticService.success();
      setState(() {
        _slots[firstEmptyIdx].sentence = sentence;
      });
    }''', '''    final firstEmptyIdx = _slots.value.indexWhere((s) => s.sentence == null);
    if (firstEmptyIdx != -1) {
      _hapticService.success();
      final newSlots = List<DescribeFrameSlot>.from(_slots.value);
      newSlots[firstEmptyIdx].sentence = sentence;
      _slots.value = newSlots;
    }''');

  content = content.replaceAll('''    setState(() {
      _slots[slotIdx].sentence = null;
    });''', '''    final newSlots = List<DescribeFrameSlot>.from(_slots.value);
    newSlots[slotIdx].sentence = null;
    _slots.value = newSlots;''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = true;
    });''', '''    _pendingSubmit.value = true;''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = false;
    });''', '''    _pendingSubmit.value = false;''');

  content = content.replaceAll('''    for (int i = 0; i < _slots.length; i++) {
      final slotSentence = _slots[i].sentence;''', '''    for (int i = 0; i < _slots.value.length; i++) {
      final slotSentence = _slots.value[i].sentence;''');

  content = content.replaceAll('''    if (_pendingSubmit) return;''', '''    if (_pendingSubmit.value) return;''');

  content = content.replaceAll('''          setState(() {
            _pendingSubmit = false;
            for (var slot in _slots) {
              slot.sentence = null;
            }
          });''', '''          _pendingSubmit.value = false;
          final newSlots = List<DescribeFrameSlot>.from(_slots.value);
          for (var slot in newSlots) {
            slot.sentence = null;
          }
          _slots.value = newSlots;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''              _slots = List.generate(
                correctCount,
                (i) => DescribeFrameSlot(index: i),
              );''', '''              _slots.value = List.generate(
                correctCount,
                (i) => DescribeFrameSlot(index: i),
              );''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? const SizedBox()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _slots, _pendingSubmit]),
            builder: (context, _) {
              final isSlotsFilled = _slots.value.isNotEmpty && _slots.value.every((s) => s.sentence != null);

              return quest == null
                  ? const SizedBox()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''        final isSlotsFilled = _slots.every((s) => s.sentence != null);''', '''''');

  content = content.replaceAll('''                                SummarizeStoryFilmStrip(
                                  slots: _slots,''', '''                                SummarizeStoryFilmStrip(
                                  slots: _slots.value,''');

  content = content.replaceAll('''                                SummarizeStoryFrameVault(
                                  options: options,
                                  slots: _slots,''', '''                                SummarizeStoryFrameVault(
                                  options: options,
                                  slots: _slots.value,''');

  content = content.replaceAll('''                    if (_pendingSubmit && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _slots.isNotEmpty
                            ? (_slots[0].sentence ?? "")
                            : "",''', '''                    if (_pendingSubmit.value && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _slots.value.isNotEmpty
                            ? (_slots.value[0].sentence ?? "")
                            : "",''');

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
                                if (isSlotsFilled && !isAnswered)
                                  ScaleButton(
                                    onTap: () => _submitAnswer(isAnswered),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 18.h),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          context.tr(
                                            'common.check_answer',
                                            fallback: 'CHECK ANSWER',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 18.sp,
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
                                if (isSlotsFilled && !isAnswered)
                                  ScaleButton(
                                    onTap: () => _submitAnswer(isAnswered),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 18.h),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          context.tr(
                                            'common.check_answer',
                                            fallback: 'CHECK ANSWER',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 18.sp,
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
