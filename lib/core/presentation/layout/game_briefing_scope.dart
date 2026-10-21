import 'package:flutter/widgets.dart';

/// Provides descendant widgets access to open the full-screen mission briefing overlay.
class GameBriefingScope extends InheritedWidget {
  final VoidCallback showBriefing;

  const GameBriefingScope({
    super.key,
    required this.showBriefing,
    required super.child,
  });

  static VoidCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GameBriefingScope>()
        ?.showBriefing;
  }

  static void show(BuildContext context) {
    of(context)?.call();
  }

  @override
  bool updateShouldNotify(GameBriefingScope oldWidget) => false;
}

