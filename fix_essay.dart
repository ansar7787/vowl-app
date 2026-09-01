import 'dart:io';

void main() {
  final file = File('lib/features/writing/essay_drafting/presentation/pages/essay_drafting_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('final Map<String, String?> _blueprintSlots = {};', 'final ValueNotifier<Map<String, String?>> _blueprintSlots = ValueNotifier({});');
  content = content.replaceAll('List<String> _shuffledOptions = [];', 'final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _pendingSubmit = false;', 'final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _blueprintSlots.dispose();
    _shuffledOptions.dispose();
    _showConfetti.dispose();
    _pendingSubmit.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _blueprintSlots.forEach((key, val) {
        if (val == data) {
          _blueprintSlots[key] = null;
        }
      });
      _blueprintSlots[slotKey] = data;
    });''', '''    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots.forEach((key, val) {
      if (val == data) {
        newSlots[key] = null;
      }
    });
    newSlots[slotKey] = data;
    _blueprintSlots.value = newSlots;''');

  content = content.replaceAll('''  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _blueprintSlots[slotKey] == null) return;
    _hapticService.selection();
    setState(() {
      _blueprintSlots[slotKey] = null;
    });
  }''', '''  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _blueprintSlots.value[slotKey] == null) return;
    _hapticService.selection();
    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots[slotKey] = null;
    _blueprintSlots.value = newSlots;
  }''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = true;
    });''', '''    _pendingSubmit.value = true;''');

  content = content.replaceAll('''    setState(() {
      _pendingSubmit = false;
    });''', '''    _pendingSubmit.value = false;''');

  content = content.replaceAll('''    bool isSlot0Correct =
        _blueprintSlots[points[0]] == options[correctOrderIndices[0]];
    bool isSlot1Correct =
        _blueprintSlots[points[1]] == options[correctOrderIndices[1]];
    bool isSlot2Correct =
        _blueprintSlots[points[2]] == options[correctOrderIndices[2]];
    bool isSlot3Correct =
        _blueprintSlots[points[3]] == options[correctOrderIndices[3]];''', '''    bool isSlot0Correct =
        _blueprintSlots.value[points[0]] == options[correctOrderIndices[0]];
    bool isSlot1Correct =
        _blueprintSlots.value[points[1]] == options[correctOrderIndices[1]];
    bool isSlot2Correct =
        _blueprintSlots.value[points[2]] == options[correctOrderIndices[2]];
    bool isSlot3Correct =
        _blueprintSlots.value[points[3]] == options[correctOrderIndices[3]];''');

  content = content.replaceAll('''          setState(() {
            _blueprintSlots.clear();
            _pendingSubmit = false;
            final quest = state.currentQuest;
            for (var point in (quest.requiredPoints ?? [])) {
              _blueprintSlots[point] = null;
            }
            _shuffledOptions = List<String>.from(quest.options ?? [])
              ..shuffle();
          });''', '''          final newSlots = <String, String?>{};
          final quest = state.currentQuest;
          for (var point in (quest.requiredPoints ?? [])) {
            newSlots[point] = null;
          }
          _blueprintSlots.value = newSlots;
          _pendingSubmit.value = false;
          _shuffledOptions.value = List<String>.from(quest.options ?? [])..shuffle();''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: activeQuest == null
              ? const SizedBox()
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _blueprintSlots, _shuffledOptions, _pendingSubmit]),
            builder: (context, _) {
              final slotsFilled =
                  _blueprintSlots.value.values.every((v) => v != null) &&
                  _blueprintSlots.value.isNotEmpty;

              return activeQuest == null
                  ? const SizedBox()
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''        final slotsFilled =
            _blueprintSlots.values.every((v) => v != null) &&
            _blueprintSlots.isNotEmpty;''', '''''');

  content = content.replaceAll('''                                ..._blueprintSlots.keys.map(
                                  (k) => EssayDraftingHexSlot(
                                    slotKey: k,
                                    slotValue: _blueprintSlots[k],''', '''                                ..._blueprintSlots.value.keys.map(
                                  (k) => EssayDraftingHexSlot(
                                    slotKey: k,
                                    slotValue: _blueprintSlots.value[k],''');

  content = content.replaceAll('''                                EssayDraftingDataStream(
                                  items: _shuffledOptions.isNotEmpty
                                      ? _shuffledOptions
                                      : options,
                                  slots: _blueprintSlots,''', '''                                EssayDraftingDataStream(
                                  items: _shuffledOptions.value.isNotEmpty
                                      ? _shuffledOptions.value
                                      : options,
                                  slots: _blueprintSlots.value,''');

  content = content.replaceAll('''                    if (_pendingSubmit && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText:
                            _blueprintSlots.isNotEmpty &&
                                _blueprintSlots.values.first != null
                            ? _blueprintSlots.values.first!''', '''                    if (_pendingSubmit.value && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText:
                            _blueprintSlots.value.isNotEmpty &&
                                _blueprintSlots.value.values.first != null
                            ? _blueprintSlots.value.values.first!''');

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
                                    onTap: slotsFilled
                                        ? () => _submitAnswer(isAnswered)
                                        : null,
                                    child: Container(
                                      width: double.infinity,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        color: slotsFilled
                                            ? theme.primaryColor
                                            : Colors.grey,
                                        boxShadow: [
                                          if (slotsFilled)
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
                                          "TRANSMIT BLUEPRINT",
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
                                    onTap: slotsFilled
                                        ? () => _submitAnswer(isAnswered)
                                        : null,
                                    child: Container(
                                      width: double.infinity,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        color: slotsFilled
                                            ? theme.primaryColor
                                            : Colors.grey,
                                        boxShadow: [
                                          if (slotsFilled)
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
                                          "TRANSMIT BLUEPRINT",
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
