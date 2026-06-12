/// Immutable configuration flags for [ListeningBaseLayout].
///
/// Grouping these into a value object keeps the widget constructor clean
/// (6 booleans → 1 named parameter) and makes call-sites self-documenting.
class ListeningBaseLayoutConfig {
  /// Whether to wrap the child in a [SingleChildScrollView].
  final bool useScrolling;

  /// Disables the default horizontal/vertical padding around [child].
  final bool disablePadding;

  /// Fires the confetti animation overlay (level-complete celebration).
  final bool showConfetti;

  /// Shows the briefing overlay on first render.
  /// Defaults to `true` on level 1 and level 100; can be forced on demand.
  final bool? overrideBriefing;

  const ListeningBaseLayoutConfig({
    this.useScrolling = false,
    this.disablePadding = false,
    this.showConfetti = false,
    this.overrideBriefing,
  });

  /// Convenience preset for a standard question screen.
  static const standard = ListeningBaseLayoutConfig();

  /// Preset for a scrollable question with extra vertical content.
  static const scrollable = ListeningBaseLayoutConfig(useScrolling: true);

  /// Preset for the level-complete celebration frame.
  static const complete = ListeningBaseLayoutConfig(showConfetti: true);

  @override
  bool operator ==(Object other) =>
      other is ListeningBaseLayoutConfig &&
      other.useScrolling == useScrolling &&
      other.disablePadding == disablePadding &&
      other.showConfetti == showConfetti &&
      other.overrideBriefing == overrideBriefing;

  @override
  int get hashCode =>
      Object.hash(useScrolling, disablePadding, showConfetti, overrideBriefing);
}
