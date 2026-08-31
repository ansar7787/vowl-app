import 'dart:io';

void main() {
  final file = File('lib/features/grammar/modals_selection/presentation/widgets/modals_rotary_dial.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('double _rotation = 0.0;', 'final ValueNotifier<double> _rotation = ValueNotifier(0.0);');
  content = content.replaceAll('int _selectedIndex = 0;', 'final ValueNotifier<int> _selectedIndex = ValueNotifier(0);\n\n  @override\n  void dispose() {\n    _rotation.dispose();\n    _selectedIndex.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('''      setState(() {
        _rotation = 0.0;
        _selectedIndex = 0;
      });''', '''      _rotation.value = 0.0;
      _selectedIndex.value = 0;''');

  content = content.replaceAll('''            setState(() {
              _rotation = newRotation;
              _selectedIndex = selected;
            });''', '''            _rotation.value = newRotation;
            _selectedIndex.value = selected;''');

  content = content.replaceAll('final isSelected = _selectedIndex == i;', 'final isSelected = _selectedIndex.value == i;');

  content = content.replaceAll('_rotation', '_rotation.value');
  content = content.replaceAll('_selectedIndex', '_selectedIndex.value');

  // Fix the replacements that messed up initializations
  content = content.replaceAll('final ValueNotifier<double> _rotation.value = ValueNotifier(0.0);', 'final ValueNotifier<double> _rotation = ValueNotifier(0.0);');
  content = content.replaceAll('final ValueNotifier<int> _selectedIndex.value = ValueNotifier(0);', 'final ValueNotifier<int> _selectedIndex = ValueNotifier(0);');
  content = content.replaceAll('_rotation.value.dispose();', '_rotation.dispose();');
  content = content.replaceAll('_selectedIndex.value.dispose();', '_selectedIndex.dispose();');
  content = content.replaceAll('setState(() {\n      _rotation.value.value', '_rotation.value'); // Just in case
  
  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
