import 'dart:io';

void main() {
  final file = File('lib/features/reading/presentation/widgets/reading_highlightable_passage.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('int? _selectedIndex;', 'final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);\n\n  @override\n  void dispose() {\n    _selectedIndex.dispose();\n    super.dispose();\n  }');

  content = content.replaceAll('_selectedIndex = null;', '_selectedIndex.value = null;');

  content = content.replaceAll('''    setState(() {
      _selectedIndex = index;
    });''', '''    _selectedIndex.value = index;''');

  // ListenableBuilder Wrap
  content = content.replaceAll('''    return Container(''', '''    return ValueListenableBuilder<int?>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndexValue, _) {
        return Container(''');
        
  // Fix bracket at the bottom
  content = content.replaceAll('''        ],
      ),
    );
  }
}''', '''        ],
      ),
    );
      },
    );
  }
}''');

  content = content.replaceAll('''              final isSelected = _selectedIndex == index;''', '''              final isSelected = selectedIndexValue == index;''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
