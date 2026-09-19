import 'dart:io';

void main() async {
  final file = File('analyze_output.txt');
  if (!file.existsSync()) {
    print('Analyze output not found');
    return;
  }

  final lines = await file.readAsLines();
  final Map<String, List<Map<String, dynamic>>> fileEdits = {};

  for (var line in lines) {
    if (line.contains('unused_local_variable') && line.contains("'tokens'")) {
      // warning - The value of the local variable 'tokens' isn't used - lib\features\...dart:70:11 - unused_local_variable
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final pathInfo = parts[2].trim();
        final pathParts = pathInfo.split(':');
        if (pathParts.length >= 3) {
          final filePath = pathParts[0];
          final lineNumber = int.tryParse(pathParts[1]);
          if (lineNumber != null) {
            fileEdits.putIfAbsent(filePath, () => []).add({
              'type': 'unused',
              'line': lineNumber,
            });
          }
        }
      }
    } else if (line.contains('const_eval_method_invocation')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final pathInfo = parts[2].trim();
        final pathParts = pathInfo.split(':');
        if (pathParts.length >= 3) {
          final filePath = pathParts[0];
          final lineNumber = int.tryParse(pathParts[1]);
          if (lineNumber != null) {
            fileEdits.putIfAbsent(filePath, () => []).add({
              'type': 'const_eval',
              'line': lineNumber,
            });
          }
        }
      }
    }
  }

  for (final filePath in fileEdits.keys) {
    print('Fixing $filePath');
    final targetFile = File(filePath);
    if (!targetFile.existsSync()) continue;

    final contentLines = await targetFile.readAsLines();
    final edits = fileEdits[filePath]!;

    // Process backwards to not mess up line numbers for 'unused' which removes lines
    edits.sort((a, b) => b['line'].compareTo(a['line']));

    bool needsAppColorsImport = false;

    for (final edit in edits) {
      final lineIdx = edit['line'] - 1;
      if (lineIdx < 0 || lineIdx >= contentLines.length) continue;

      if (edit['type'] == 'unused') {
        if (contentLines[lineIdx].contains('tokens =')) {
          contentLines.removeAt(lineIdx);
        } else if (lineIdx - 1 >= 0 &&
            contentLines[lineIdx - 1].contains('tokens =')) {
          contentLines.removeAt(lineIdx - 1);
        } else if (lineIdx + 1 < contentLines.length &&
            contentLines[lineIdx + 1].contains('tokens =')) {
          contentLines.removeAt(lineIdx + 1);
        }
      } else if (edit['type'] == 'const_eval') {
        String lineContent = contentLines[lineIdx];
        if (lineContent.contains('tokens.')) {
          lineContent = lineContent.replaceAll('tokens.', 'AppColors.');
          needsAppColorsImport = true;
        }
        if (lineContent.contains('Theme.of(context).colorScheme.primary')) {
          lineContent = lineContent.replaceAll(
            'Theme.of(context).colorScheme.primary',
            'AppColors.indigo500',
          );
          needsAppColorsImport = true;
        }
        if (lineContent.contains('Theme.of(context).colorScheme.error')) {
          lineContent = lineContent.replaceAll(
            'Theme.of(context).colorScheme.error',
            'AppColors.red500',
          );
          needsAppColorsImport = true;
        }
        contentLines[lineIdx] = lineContent;
      }
    }

    if (needsAppColorsImport) {
      bool hasImport = contentLines.any((l) => l.contains('app_colors.dart'));
      if (!hasImport) {
        int importIdx = contentLines.indexWhere((l) => l.startsWith('import '));
        if (importIdx != -1) {
          contentLines.insert(
            importIdx,
            "import 'package:vowl/core/theme/app_colors.dart';",
          );
        } else {
          contentLines.insert(
            0,
            "import 'package:vowl/core/theme/app_colors.dart';",
          );
        }
      }
    }

    await targetFile.writeAsString(contentLines.join('\n'));
  }
}
