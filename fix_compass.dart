import 'dart:io';

void main() {
  final file = File('lib/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('double _needleRotation = 0.0;', 'final ValueNotifier<double> _needleRotation = ValueNotifier(0.0);');
  content = content.replaceAll('bool _isDragging = false;', 'final ValueNotifier<bool> _isDragging = ValueNotifier(false);');

  content = content.replaceFirst('  void dispose() {', '  void dispose() {\n    _needleRotation.dispose();\n    _isDragging.dispose();');

  content = content.replaceAll('''      setState(() {
        _needleRotation = 0.0;
        _isDragging = false;
        _lastHapticQuadrant = -1;
      });''', '''      _needleRotation.value = 0.0;
      _isDragging.value = false;
      _lastHapticQuadrant = -1;''');

  content = content.replaceAll('''    setState(() {
      _needleRotation = math.atan2(dy, dx) + (math.pi / 2);
      _isDragging = true;
    });''', '''    _needleRotation.value = math.atan2(dy, dx) + (math.pi / 2);
    _isDragging.value = true;''');

  content = content.replaceAll('(_needleRotation % (2 * math.pi)', '(_needleRotation.value % (2 * math.pi)');
  
  content = content.replaceAll('setState(() => _isDragging = false);', '_isDragging.value = false;');

  content = content.replaceAll('''    setState(() {
      _needleRotation = (index * (math.pi * 2) / 4);
    });''', '''    _needleRotation.value = (index * (math.pi * 2) / 4);''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
