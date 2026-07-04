import 'dart:io';
void main() {
  final f2 = File('lib/features/accent/consonant_clarity/presentation/widgets/consonant_clarity_instruction.dart');
  var c2 = f2.readAsStringSync();
  c2 = c2.replaceFirst('final String instruction;\r\n  final String instruction;', 'final String instruction;');
  c2 = c2.replaceFirst('final String instruction;\n  final String instruction;', 'final String instruction;');
  c2 = c2.replaceFirst('required this.instruction,\r\n    required this.instruction,', 'required this.instruction,');
  c2 = c2.replaceFirst('required this.instruction,\n    required this.instruction,', 'required this.instruction,');
  f2.writeAsStringSync(c2);

  final f3 = File('lib/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart');
  var c3 = f3.readAsStringSync();
  c3 = c3.replaceAll(RegExp(r'instruction:\s*quest\.instruction,\s*instruction:\s*quest\.instruction,'), 'instruction: quest.instruction,');
  f3.writeAsStringSync(c3);

  final f4 = File('lib/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart');
  var c4 = f4.readAsStringSync();
  c4 = c4.replaceAll(RegExp(r'instruction:\s*quest\.instruction,\s*instruction:\s*quest\.instruction,'), 'instruction: quest.instruction,');
  f4.writeAsStringSync(c4);
}
