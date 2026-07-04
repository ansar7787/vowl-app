import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/features/accent');
  final entities = dir.listSync(recursive: true);

  // 1. Process instruction widgets
  final instructionFiles = entities
      .whereType<File>()
      .where((f) => f.path.endsWith('_instruction.dart') && !f.path.contains('vowel_distinction'));

  for (final file in instructionFiles) {
    String content = file.readAsStringSync();
    
    // Extract existing hardcoded text
    final regex = RegExp(r'Text\(\s*"([^"]+)"');
    final match = regex.firstMatch(content);
    if (match != null) {
      final fallbackText = match.group(1);
      
      // Add final String instruction;
      if (!content.contains('final String instruction;')) {
        content = content.replaceFirst(
            'final Color color;', 
            'final Color color;\n  final String instruction;'
        );
        content = content.replaceFirst(
            'required this.color,', 
            'required this.color,\n    required this.instruction,'
        );
      }

      // Replace Text
      final newText = '''Text(
            instruction.trim().isEmpty 
                ? "$fallbackText"
                : instruction.toUpperCase()''';
      
      content = content.replaceFirst(match.group(0)!, newText);
      file.writeAsStringSync(content);
    }
  }

  // 2. Process screens
  final screenFiles = entities
      .whereType<File>()
      .where((f) => f.path.endsWith('_screen.dart') && !f.path.contains('vowel_distinction'));

  for (final file in screenFiles) {
    String content = file.readAsStringSync();
    
    // We want to add instruction: quest.instruction,
    // after color: theme.primaryColor,
    // but only inside the Instruction widget block.
    
    // A quick hack is to find the Instruction class name based on the file name.
    // e.g., word_linking_screen.dart -> WordLinkingInstruction
    final basename = file.uri.pathSegments.last.replaceAll('_screen.dart', '');
    final parts = basename.split('_');
    final className = parts.map((p) => p[0].toUpperCase() + p.substring(1)).join('') + 'Instruction';
    
    final r = RegExp(className + r'\(([\s\S]*?color:\s*theme\.primaryColor,)');
    
    if (r.hasMatch(content)) {
      content = content.replaceAllMapped(r, (m) {
        if (!m.group(0)!.contains('instruction:')) {
          return m.group(0)! + '\n                                            instruction: quest.instruction,';
        }
        return m.group(0)!;
      });
      file.writeAsStringSync(content);
    }
  }
}
