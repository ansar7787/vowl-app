import 'dart:io';

void main() {
  // 1. connected_speech_instruction.dart
  final f1 = File('lib/features/accent/connected_speech/presentation/widgets/connected_speech_instruction.dart');
  String c1 = f1.readAsStringSync();
  c1 = c1.replaceFirst('final Color primaryColor;\r\n  final bool isCompact;', 'final Color primaryColor;\n  final String instruction;\n  final bool isCompact;');
  c1 = c1.replaceFirst('final Color primaryColor;\n  final bool isCompact;', 'final Color primaryColor;\n  final String instruction;\n  final bool isCompact;');
  c1 = c1.replaceFirst('required this.primaryColor,\r\n    this.isCompact = false,', 'required this.primaryColor,\n    required this.instruction,\n    this.isCompact = false,');
  c1 = c1.replaceFirst('required this.primaryColor,\n    this.isCompact = false,', 'required this.primaryColor,\n    required this.instruction,\n    this.isCompact = false,');
  f1.writeAsStringSync(c1);

  // 2. consonant_clarity_instruction.dart
  final f2 = File('lib/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_instruction.dart');
  String c2 = f2.readAsStringSync();
  if (!c2.contains('final String instruction;')) {
    c2 = c2.replaceFirst('final Color primaryColor;\r\n', 'final Color primaryColor;\n  final String instruction;\n');
    c2 = c2.replaceFirst('final Color primaryColor;\n', 'final Color primaryColor;\n  final String instruction;\n');
    c2 = c2.replaceFirst('required this.primaryColor,\r\n', 'required this.primaryColor,\n    required this.instruction,\n');
    c2 = c2.replaceFirst('required this.primaryColor,\n', 'required this.primaryColor,\n    required this.instruction,\n');
  }
  c2 = c2.replaceFirst('Text(\r\n            instruction', 'Text(\n            instruction');
  c2 = c2.replaceFirst('Text(\n            instruction', 'Text(\n            instruction');
  f2.writeAsStringSync(c2);

  // 3. minimal_pairs_screen.dart (has duplicate named parameter instruction)
  final f3 = File('lib/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart');
  String c3 = f3.readAsStringSync();
  // Remove duplicates. It has instruction: quest.instruction multiple times probably.
  c3 = c3.replaceAll('instruction: quest.instruction,\r\n                                            instruction: quest.instruction,', 'instruction: quest.instruction,');
  c3 = c3.replaceAll('instruction: quest.instruction,\n                                            instruction: quest.instruction,', 'instruction: quest.instruction,');
  f3.writeAsStringSync(c3);

  // 4. pitch_pattern_match_screen.dart (duplicate named parameter)
  final f4 = File('lib/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart');
  String c4 = f4.readAsStringSync();
  c4 = c4.replaceAll('instruction: quest.instruction,\r\n                                            instruction: quest.instruction,', 'instruction: quest.instruction,');
  c4 = c4.replaceAll('instruction: quest.instruction,\n                                            instruction: quest.instruction,', 'instruction: quest.instruction,');
  f4.writeAsStringSync(c4);
}
