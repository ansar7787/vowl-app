import 'dart:io';

void main() async {
  final file = File('docs/game_architecture_plan.md');
  final lines = await file.readAsLines();

  final newLines = <String>[];
  bool inTargetSection = false;

  final targetPattern = RegExp(r'### 🟠 Listening|### 🟡 Speaking|### 🟤 Writing|### 🔴 Accent|### 🎭 Roleplay|### 👑 Elite Mastery');
  final gameTitlePattern = RegExp(r'^\d+\.\s+\*\*(.*)\*\*$');

  final diamondChecklist = [
    "- [ ] Dual-Stage Scroll UX",
    "- [ ] Sliver Performance Layout",
    "- [ ] Zero setState (ValueNotifier)",
    "- [ ] Feedback Card Logic",
    "- [ ] Pedagogical Component: `TBD`",
    "- [ ] Edge-to-Edge Scrollbar (RawScrollbar)",
    "- [ ] Keyboard Scroll Stability (FocusNode visibility)",
    "- [ ] Docked Input Padding (Keyboard Games Only)",
    "- [ ] 10/10 UX Confirmation (No Patchwork)",
    "- [ ] Git Commit & Push"
  ];

  for (final line in lines) {
    if (targetPattern.hasMatch(line)) {
      inTargetSection = true;
    }

    if (inTargetSection) {
      if (line.startsWith("- [x] ") || line.startsWith("- [ ] ")) {
        continue;
      }

      final match = gameTitlePattern.firstMatch(line.trim());
      if (match != null) {
        newLines.add(line);
        newLines.addAll(diamondChecklist);
        continue;
      }
    }

    newLines.add(line);
  }

  await file.writeAsString(newLines.join('\n'));
  print('Updated game_architecture_plan.md');
}
