import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    bool modified = false;

    if (content.contains('math.max(10,')) {
      // 1. replace `math.max(10, someVar.unlockedLevels[key] ?? 10)` with `someVar.unlockedLevels[key] ?? 1`
      content = content.replaceAllMapped(
        RegExp(r'math\.max\(10, (.+?\.unlockedLevels\[.+?\]) \?\? 10\)'),
        (match) => '${match.group(1)} ?? 1'
      );
      // 2. replace `math.max(10, unlockedLevels[key] ?? 10)` with `unlockedLevels[key] ?? 1`
      content = content.replaceAllMapped(
        RegExp(r'math\.max\(10, (unlockedLevels\[.+?\]) \?\? 10\)'),
        (match) => '${match.group(1)} ?? 1'
      );
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      print('Fixed \${file.path}');
    }
  }
}
