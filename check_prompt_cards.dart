import 'dart:io';

void main() {
  final dir = Directory('lib/features/accent');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('_prompt_card.dart'));
  
  for (var file in files) {
    final content = file.readAsStringSync();
    final match = RegExp(r'Text\(\s*"([^"]+)"').firstMatch(content);
    if (match != null) {
      print('${file.path.split('/').last}:\n${match.group(1)}\n');
    }
  }
}
