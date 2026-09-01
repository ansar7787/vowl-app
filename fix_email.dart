import 'dart:io';

void main() {
  final file = File('lib/features/writing/writing_email/presentation/pages/writing_email_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('''  final Map<String, String?> _slots = {
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  };''', '''  final ValueNotifier<Map<String, String?>> _slots = ValueNotifier({
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  });''');
  content = content.replaceAll('List<String> _shuffledOptions = [];', 'final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showSpeakToConfirm = false;', 'final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void initState() {''', '''  @override
  void dispose() {
    _slots.dispose();
    _shuffledOptions.dispose();
    _showConfetti.dispose();
    _showSpeakToConfirm.dispose();
    super.dispose();
  }

  @override
  void initState() {''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _slots.forEach((key, val) {
        if (val == data) {
          _slots[key] = null;
        }
      });
      _slots[slotKey] = data;
    });''', '''    final newSlots = Map<String, String?>.from(_slots.value);
    newSlots.forEach((key, val) {
      if (val == data) {
        newSlots[key] = null;
      }
    });
    newSlots[slotKey] = data;
    _slots.value = newSlots;''');

  content = content.replaceAll('''    for (final key in ['SUBJECT', 'SALUTATION', 'BODY', 'SIGN-OFF']) {
      if (_slots[key] == null) {''', '''    for (final key in ['SUBJECT', 'SALUTATION', 'BODY', 'SIGN-OFF']) {
      if (_slots.value[key] == null) {''');

  content = content.replaceAll('''      setState(() {
        _slots.forEach((key, val) {
          if (val == data) {
            _slots[key] = null;
          }
        });
        _slots[targetSlot!] = data;
      });''', '''      final newSlots = Map<String, String?>.from(_slots.value);
      newSlots.forEach((key, val) {
        if (val == data) {
          newSlots[key] = null;
        }
      });
      newSlots[targetSlot!] = data;
      _slots.value = newSlots;''');

  content = content.replaceAll('''    if (isAnswered || _slots[slotKey] == null) return;
    _hapticService.selection();
    setState(() {
      _slots[slotKey] = null;
    });''', '''    if (isAnswered || _slots.value[slotKey] == null) return;
    _hapticService.selection();
    final newSlots = Map<String, String?>.from(_slots.value);
    newSlots[slotKey] = null;
    _slots.value = newSlots;''');

  content = content.replaceAll('''    bool isSubjectCorrect =
        _slots['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect =
        _slots['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect = _slots['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect =
        _slots['SIGN-OFF'] == options[correctOrderIndices[3]];''', '''    bool isSubjectCorrect =
        _slots.value['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect =
        _slots.value['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect = _slots.value['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect =
        _slots.value['SIGN-OFF'] == options[correctOrderIndices[3]];''');

  content = content.replaceAll('''      setState(() => _showSpeakToConfirm = true);''', '''      _showSpeakToConfirm.value = true;''');

  content = content.replaceAll('''    setState(() => _showSpeakToConfirm = false);''', '''    _showSpeakToConfirm.value = false;''');

  content = content.replaceAll('''          setState(() {
            _slots.updateAll((k, v) => null);
            _showSpeakToConfirm = false;
            final quest = state.currentQuest;
            _shuffledOptions = List<String>.from(quest.options ?? [])
              ..shuffle();
          });''', '''          final newSlots = Map<String, String?>.from(_slots.value);
          newSlots.updateAll((k, v) => null);
          _slots.value = newSlots;
          _showSpeakToConfirm.value = false;
          final quest = state.currentQuest;
          _shuffledOptions.value = List<String>.from(quest.options ?? [])..shuffle();''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  content = content.replaceAll('''                                  setState(() => _showSpeakToConfirm = false);''', '''                                  _showSpeakToConfirm.value = false;''');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''              : CustomScrollView(''', '''              : ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _slots, _shuffledOptions, _showSpeakToConfirm]),
            builder: (context, _) {
              final slotsFilled = _slots.value.values.every((v) => v != null);

              return CustomScrollView(''');

  // Widget properties
  content = content.replaceAll('''        final slotsFilled = _slots.values.every((v) => v != null);''', '''''');

  content = content.replaceAll('''                            ..._slots.keys.map(
                              (k) => WritingEmailHexSlot(
                                slotKey: k,
                                slotValue: _slots[k],''', '''                            ..._slots.value.keys.map(
                              (k) => WritingEmailHexSlot(
                                slotKey: k,
                                slotValue: _slots.value[k],''');

  content = content.replaceAll('''                                        slots: _slots,''', '''                                        slots: _slots.value,''');

  content = content.replaceAll('''                                  validOptions: options
                                      .where((opt) => !_slots.values.contains(opt))
                                      .toList(),''', '''                                  validOptions: options
                                      .where((opt) => !_slots.value.values.contains(opt))
                                      .toList(),''');

  content = content.replaceAll('''                                  items: _shuffledOptions.isNotEmpty
                                      ? _shuffledOptions
                                      : options,''', '''                                  items: _shuffledOptions.value.isNotEmpty
                                      ? _shuffledOptions.value
                                      : options,''');

  content = content.replaceAll('''                             if (_showSpeakToConfirm && !isAnswered)
                              SpeakToConfirmOverlay(
                                expectedText: "\${_slots['SUBJECT'] ?? ''} \${_slots['SALUTATION'] ?? ''} \${_slots['BODY'] ?? ''} \${_slots['SIGN-OFF'] ?? ''}".trim(),''', '''                             if (_showSpeakToConfirm.value && !isAnswered)
                              SpeakToConfirmOverlay(
                                expectedText: "\${_slots.value['SUBJECT'] ?? ''} \${_slots.value['SALUTATION'] ?? ''} \${_slots.value['BODY'] ?? ''} \${_slots.value['SIGN-OFF'] ?? ''}".trim(),''');

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
                            if (_showSpeakToConfirm && !isAnswered)
                              SpeakToConfirmOverlay(
                                expectedText: "\${_slots['SUBJECT'] ?? ''} \${_slots['SALUTATION'] ?? ''} \${_slots['BODY'] ?? ''} \${_slots['SIGN-OFF'] ?? ''}".trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  setState(() => _showSpeakToConfirm = false);
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
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
                                      "SEND EMAIL",
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
                                expectedText: "\${_slots.value['SUBJECT'] ?? ''} \${_slots.value['SALUTATION'] ?? ''} \${_slots.value['BODY'] ?? ''} \${_slots.value['SIGN-OFF'] ?? ''}".trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: _onSpeakConfirmed,
                                onSkipped: () {
                                  _showSpeakToConfirm.value = false;
                                  context.read<WritingBloc>().add(const SubmitAnswer(false));
                                },
                              )
                            else if (!isAnswered)
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
                                      "SEND EMAIL",
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
