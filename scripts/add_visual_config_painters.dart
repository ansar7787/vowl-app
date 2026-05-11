import 'dart:io';

void main() {
  final dir = Directory('lib/features');
  final files = dir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_screen.dart'))
      .toList();

  int updated = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Check if it's a game screen with MeshGradientBackground and state.currentQuest
    if (!content.contains('MeshGradientBackground')) continue;
    if (!content.contains('state.currentQuest')) continue;

    bool changed = false;

    // Add import if missing
    if (!content.contains('visual_config_background.dart')) {
      final importString = "import 'package:voxai_quest/core/presentation/painters/visual_config_background.dart';\n";
      content = content.replaceFirst(RegExp(r"import 'package:flutter/material\.dart';\n"), "import 'package:flutter/material.dart';\n$importString");
      changed = true;
    }

    // Add VisualConfigBackground if missing (handling const and non-const)
    if (!content.contains('VisualConfigBackground')) {
      content = content.replaceAllMapped(
        RegExp(r'((?:const\s+)?MeshGradientBackground\([^)]*\),)'),
        (match) => "${match.group(1)}\n                if (state.currentQuest.visualConfig != null) VisualConfigBackground(config: state.currentQuest.visualConfig!),"
      );
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
      updated++;
    }
  }
  print('Total updated: $updated');
}
