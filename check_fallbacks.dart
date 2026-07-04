import 'dart:io';

void main() {
  final dir = Directory('lib/features/accent');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('_instruction.dart'));
  
  for (var file in files) {
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('instruction.trim().isEmpty')) {
        print('${file.path.split('/').last}:');
        print(lines[i]);
        if (i + 1 < lines.length) print(lines[i+1]);
        if (i + 2 < lines.length) print(lines[i+2]);
        print('---');
      }
    }
  }
}
