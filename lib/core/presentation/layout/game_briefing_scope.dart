import 'package:flutter/widgets.dart';

/// Provides descendant widgets access to open the full-screen mission briefing overlay
/// and reactively observe whether the briefing is currently open (e.g. to pause game timers).
class GameBriefingScope extends InheritedWidget {
  final VoidCallback showBriefing;
  final bool isBriefingOpen;

  const GameBriefingScope({
    super.key,
    required this.showBriefing,
    this.isBriefingOpen = false,
    required super.child,
  });

  static VoidCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GameBriefingScope>()
        ?.showBriefing;
  }

  static bool isOpen(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GameBriefingScope>()
        ?.isBriefingOpen ??
        false;
  }

  static void show(BuildContext context) {
    of(context)?.call();
  }

  @override
  bool updateShouldNotify(GameBriefingScope oldWidget) =>
      oldWidget.isBriefingOpen != isBriefingOpen;
}
