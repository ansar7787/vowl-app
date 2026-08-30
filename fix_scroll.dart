import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    bool changed = false;
    
    final regex = RegExp(r'([ \t]*)(_scrollController\.animateTo\([\s\S]*?\);)');
    
    content = content.replaceAllMapped(regex, (match) {
      final whitespace = match.group(1)!;
      final statement = match.group(2)!;
      
      // Check if the previous line contains hasClients
      final matchStart = match.start;
      final previousCode = content.substring(0, matchStart);
      final lines = previousCode.split('\n');
      final lastLine = lines.length > 1 ? lines[lines.length - 2] : '';
      
      if (!lastLine.contains('hasClients')) {
        changed = true;
        return '${whitespace}if (_scrollController.hasClients) {\n${whitespace}  $statement\n${whitespace}}';
      }
      return match.group(0)!;
    });
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
