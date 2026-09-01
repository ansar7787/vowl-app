import 'dart:io';

void main() {
  final file = File('lib/features/reading/presentation/widgets/reading_feedback_card.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('String? _translatedText;', 'final ValueNotifier<String?> _translatedText = ValueNotifier(null);');
  content = content.replaceAll('List<EntityAnnotation>? _entities;', 'final ValueNotifier<List<EntityAnnotation>?> _entities = ValueNotifier(null);');
  content = content.replaceAll('bool _isExtracting = false;', 'final ValueNotifier<bool> _isExtracting = ValueNotifier(false);');
  content = content.replaceAll('bool _entitiesRevealed = false;', 'final ValueNotifier<bool> _entitiesRevealed = ValueNotifier(false);\n\n  @override\n  void dispose() {\n    _translatedText.dispose();\n    _entities.dispose();\n    _isExtracting.dispose();\n    _entitiesRevealed.dispose();\n    super.dispose();\n  }');

  // Logic
  content = content.replaceAll('setState(() => _isExtracting = true);', '_isExtracting.value = true;');

  content = content.replaceAll('''      setState(() {
        _entities = entities;
        _isExtracting = false;
        _entitiesRevealed = true;
      });''', '''      _entities.value = entities;
      _isExtracting.value = false;
      _entitiesRevealed.value = true;''');

  content = content.replaceAll('''                          setState(() => _translatedText = translated);''', '''                          _translatedText.value = translated;''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.explanation;

    Widget card = Column(''', '''  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_translatedText, _entities, _isExtracting, _entitiesRevealed]),
      builder: (context, _) {
        final displayText = _translatedText.value ?? widget.explanation;
        
        Widget card = Column(''');
        
  // Fix bracket at the bottom
  content = content.replaceAll('''    return card;
  }
}''', '''    return card;
      },
    );
  }
}''');

  // Widget State Accesses
  content = content.replaceAll('''                    if (!_entitiesRevealed && !_isExtracting)''', '''                    if (!_entitiesRevealed.value && !_isExtracting.value)''');
  content = content.replaceAll('''                if (_isExtracting)''', '''                if (_isExtracting.value)''');
  content = content.replaceAll('''                else if (_entitiesRevealed && _entities != null)''', '''                else if (_entitiesRevealed.value && _entities.value != null)''');
  content = content.replaceAll('''                    annotations: _entities!,''', '''                    annotations: _entities.value!,''');
  content = content.replaceAll('''                if (_entitiesRevealed &&
                    _entities != null &&
                    _entities!.isNotEmpty) ...[''', '''                if (_entitiesRevealed.value &&
                    _entities.value != null &&
                    _entities.value!.isNotEmpty) ...[''');
  content = content.replaceAll('''                  if (_translatedText == null)''', '''                  if (_translatedText.value == null)''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
