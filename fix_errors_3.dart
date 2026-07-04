import 'dart:io';

void main() {
  final f1 = File('lib/features/accent/connected_speech/presentation/pages/connected_speech_screen.dart');
  var c1 = f1.readAsStringSync();
  c1 = c1.replaceAll('color: theme.primaryColor,\r\n                                            instruction: quest.instruction,', 'color: theme.primaryColor,');
  c1 = c1.replaceAll('color: theme.primaryColor,\n                                            instruction: quest.instruction,', 'color: theme.primaryColor,');
  c1 = c1.replaceAll('primaryColor: theme.primaryColor,\r\n                                      isCompact: isCompact,', 'primaryColor: theme.primaryColor,\r\n                                      instruction: quest.instruction,\r\n                                      isCompact: isCompact,');
  c1 = c1.replaceAll('primaryColor: theme.primaryColor,\n                                      isCompact: isCompact,', 'primaryColor: theme.primaryColor,\n                                      instruction: quest.instruction,\n                                      isCompact: isCompact,');
  f1.writeAsStringSync(c1);

  final f2 = File('lib/features/accent/consonant_clarity/presentation/pages/consonant_clarity_screen.dart');
  var c2 = f2.readAsStringSync();
  c2 = c2.replaceAll('color: theme.primaryColor,\r\n                                            instruction: quest.instruction,', 'color: theme.primaryColor,');
  c2 = c2.replaceAll('color: theme.primaryColor,\n                                            instruction: quest.instruction,', 'color: theme.primaryColor,');
  c2 = c2.replaceAll('primaryColor:\r\n                                                        theme.primaryColor,\r\n                                                  ),', 'primaryColor:\r\n                                                        theme.primaryColor,\r\n                                                    instruction: quest.instruction,\r\n                                                  ),');
  c2 = c2.replaceAll('primaryColor:\n                                                        theme.primaryColor,\n                                                  ),', 'primaryColor:\n                                                        theme.primaryColor,\n                                                    instruction: quest.instruction,\n                                                  ),');
  c2 = c2.replaceAll('primaryColor: theme.primaryColor,\r\n                                          ),', 'primaryColor: theme.primaryColor,\r\n                                            instruction: quest.instruction,\r\n                                          ),');
  c2 = c2.replaceAll('primaryColor: theme.primaryColor,\n                                          ),', 'primaryColor: theme.primaryColor,\n                                            instruction: quest.instruction,\n                                          ),');
  f2.writeAsStringSync(c2);
}
