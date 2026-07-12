import 'package:flutter/foundation.dart';
import 'dart:io';

void main() {
  final dir = Directory('lib/features/listening');
  final files = dir.listSync(recursive: true).whereType<File>();

  for (final file in files) {
    if (file.path.endsWith('_quest.dart') &&
        file.path.contains('domain') &&
        file.path.contains('entities')) {
      final lines = file.readAsLinesSync();
      final newLines = <String>[];

      bool seenFinalTranscript = false;
      bool seenThisTranscript = false;
      bool seenPropTranscript = false;

      for (final line in lines) {
        if (line.contains('final String? audioTranscript;')) {
          if (seenFinalTranscript) continue;
          seenFinalTranscript = true;
        }
        if (line.contains('this.audioTranscript,')) {
          if (seenThisTranscript) continue;
          seenThisTranscript = true;
        }
        if (line.contains('audioTranscript,')) {
          if (line.contains('this.')) continue; // handled above
          if (seenPropTranscript) continue;
          seenPropTranscript = true;
        }
        newLines.add(line);
      }

      file.writeAsStringSync(newLines.join('\n'));
    }
  }
  debugPrint('Done deduplicating audioTranscript');
}
