
import "dart:io";

void main() {
  final dir = Directory("lib/features/roleplay");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith("_screen.dart") && !f.path.contains("branching_dialogue") && !f.path.contains("situational_response")).toList();

  final listenerBlock = """    isFirstStagePassedNotifier.addListener(() {
      if (isFirstStagePassedNotifier.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });""";
    
  final listenerBlockWin = listenerBlock.replaceAll("\n", "\r\n");

  for (var file in files) {
    String content = file.readAsStringSync();

    // 1. 80.h to 24.h
    content = content.replaceAll(RegExp(r"SliverToBoxAdapter\(child:\s*SizedBox\(height:\s*80\.h\)\)"), "SliverToBoxAdapter(child: SizedBox(height: 24.h))");

    // 2. CustomScrollView controller
    content = content.replaceAllMapped(RegExp(r"(child:\s*CustomScrollView\(\s*)(physics:)"), (m) => "${m[1]}controller: _scrollController,\n                            ${m[2]}");

    // Add _scrollToBottom and remove listener
    if (!content.contains("void _scrollToBottom()")) {
      final scrollToBottom = """  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {""";
      content = content.replaceFirst(RegExp(r"  @override\r?\n  void initState\(\) \{"), scrollToBottom);
    }

    content = content.replaceFirst(listenerBlock, "");
    content = content.replaceFirst(listenerBlockWin, "");

    // 5. Insert _scrollToBottom() inside the answer handling logic.
    content = content.replaceAllMapped(RegExp(r"(if \([A-Za-z0-9_]*?isCorrect[A-Za-z0-9_]*?\) \{\s*hapticService\.selection\(\);\s*isFirstStagePassedNotifier\.value = true;)"), (m) => "${m[1]}\n      _scrollToBottom();");
    content = content.replaceAllMapped(RegExp(r"(\} else \{\s*)(submitWrongAnswer|final userAnswer =)"), (m) => "${m[1]}_scrollToBottom();\n      ${m[2]}");

    // 6. Remove double padding around SpeakToConfirmOverlay
    content = content.replaceAllMapped(RegExp(r"(SliverToBoxAdapter\(\s*child:\s*)Padding\(\s*padding:\s*EdgeInsets\.(?:symmetric|only)\([^)]+\),\s*child:\s*(SpeakToConfirmOverlay\([\s\S]*?onSkipped:\s*\(\)\s*=>[\s\S]*?\),\s*)\),\s*\)"), (m) {
      return "${m[1]}${m[2]})";
    });

    file.writeAsStringSync(content);
    print("Processed ${file.path}");
  }
}

