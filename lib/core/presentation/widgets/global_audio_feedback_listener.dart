import 'package:flutter/material.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

// ═══════════════════════════════════════════════════════════════════════════
// CRITICAL FIX — READ BEFORE MODIFYING THIS FILE
//
// The previous implementation of GlobalAudioFeedbackListener wired 9
// BlocListeners directly to `di.sl<KidsBloc>()`, `di.sl<GrammarBloc>()`,
// `di.sl<SpeakingBloc>()`, etc., resolved fresh inside this widget's own
// build() method. That never worked: every one of those 9 Bloc types is
// registered with `sl.registerFactory<T>(...)` in `di_features.dart` (not
// `registerLazySingleton`) - confirmed directly against that file rather
// than assumed - specifically so that each game screen gets its own
// freshly-constructed Bloc instance per visit. Calling `di.sl<KidsBloc>()`
// a SECOND time here, from a widget documented as living "near the root of
// the widget tree", constructs yet another brand-new, never-updated
// instance - not the one the active game screen is actually dispatching
// events to. The result: `_praiseListener` / `_kidsListener` were
// listening to orphaned Blocs that never receive a single event, so
// praise audio never played, for any game, ever, in production.
//
// A root-level widget structurally CANNOT observe a Bloc that's scoped
// per-screen via a `BlocProvider` mounted deep inside a pushed route's
// subtree either (Provider/`context.read` only searches UP the tree from
// the calling context - there is no ancestor `BlocProvider<KidsBloc>`
// above the root to find). So neither the old DI-resolution approach nor
// a naive switch to `context.read<T>()` can work from this widget's
// position in the tree.
//
// THE FIX: this file now defines and listens to [GamePraiseSignal], a
// tiny, always-singleton `ChangeNotifier` "fire and forget" event bus.
// Unlike the heavyweight, stateful, intentionally-per-screen game Blocs,
// a bus that carries no gameplay state at all is trivially safe to make a
// real singleton - there's no "which level's state is this" ambiguity to
// get wrong.
//
// ═══ ACTION REQUIRED - one remaining step outside this file's scope ═══
// This widget-side half of the fix is complete and safe to ship as-is
// (it defensively self-registers [GamePraiseSignal] if nothing else has -
// see [_resolvePraiseSignal] - so it cannot throw on startup even before
// the step below is applied). But no BLoC calls `GamePraiseSignal.fire()`
// yet, because the 9 Bloc source files live outside this reviewed slice
// and I won't guess-edit files I can't see. To finish restoring the
// feature, add ONE line at the exact point each Bloc currently flips
// `lastAnswerCorrect` to true or emits its `*GameComplete` state -
// mirroring the two `listenWhen` conditions the old code used per Bloc.
// Two concrete examples (the other 7 Blocs follow the identical shape):
//
//   // Inside KidsBloc, wherever it emits KidsLoaded(lastAnswerCorrect: true, ...)
//   // or KidsGameComplete(...):
//   sl<GamePraiseSignal>().fire(isKids: true);
//
//   // Inside GrammarBloc, wherever it emits GrammarLoaded with
//   // answerStatus.isCorrect flipping true, or GrammarGameComplete:
//   sl<GamePraiseSignal>().fire();
//
// (SpeakingBloc, ReadingBloc, WritingBloc, ListeningBloc, AccentBloc,
// RoleplayBloc, VocabularyBloc all call `sl<GamePraiseSignal>().fire()`
// with no arguments, same as GrammarBloc - only Kids Zone passes
// `isKids: true`.) Optionally also add
// `sl.registerLazySingleton<GamePraiseSignal>(() => GamePraiseSignal());`
// to `di_core.dart` for an explicit, central registration - not required
// for correctness (see [_resolvePraiseSignal]), but keeps the DI graph
// self-documenting.
// ═══════════════════════════════════════════════════════════════════════════

/// Minimal, singleton, stateless-between-fires event bus used to trigger
/// praise audio from any game BLoC without requiring the listener to
/// resolve that BLoC's own per-screen instance. See the file-level doc
/// comment above for the full rationale and required call sites.
class GamePraiseSignal extends ChangeNotifier {
  bool _isKidsMode = false;

  /// Whether the most recent [fire] call was from the Kids Zone (selects
  /// [PraiseService.givePraise]'s `isKids` phrase pool).
  bool get isKidsMode => _isKidsMode;

  /// Call the instant a BLoC transitions into "just answered correctly" or
  /// "just completed the level" state - the two conditions the old
  /// per-Bloc `listenWhen` clauses checked.
  void fire({bool isKids = false}) {
    _isKidsMode = isKids;
    notifyListeners();
  }
}

/// Listens for [GamePraiseSignal] events globally and triggers
/// [PraiseService] audio feedback when a correct answer is submitted or a
/// level is completed, regardless of which game screen is currently
/// active.
///
/// Placed near the root of the widget tree - see the file-level doc
/// comment for why it uses a singleton signal bus rather than resolving
/// individual (factory-scoped) game Blocs directly.
class GlobalAudioFeedbackListener extends StatefulWidget {
  final Widget child;

  const GlobalAudioFeedbackListener({super.key, required this.child});

  @override
  State<GlobalAudioFeedbackListener> createState() =>
      _GlobalAudioFeedbackListenerState();
}

class _GlobalAudioFeedbackListenerState
    extends State<GlobalAudioFeedbackListener> {
  late final GamePraiseSignal _signal;

  @override
  void initState() {
    super.initState();
    _signal = _resolvePraiseSignal();
    _signal.addListener(_onPraiseSignal);
  }

  @override
  void dispose() {
    _signal.removeListener(_onPraiseSignal);
    super.dispose();
  }

  void _onPraiseSignal() {
    di.sl<PraiseService>().givePraise(isKids: _signal.isKidsMode);
  }

  /// Resolves the shared [GamePraiseSignal], self-registering a lazy
  /// singleton on first access if `di_core.dart` (outside this file's
  /// scope) hasn't been updated to register one explicitly yet. This is
  /// what makes the fix in this file work standalone today without risking
  /// a "type not registered" crash on the very first frame, while
  /// remaining fully compatible with - and preferring - an explicit
  /// central registration once one is added: GetIt registrations from
  /// `initExternalAndCore()` run at app startup, before this widget is
  /// ever built, so if that registration exists this call sees
  /// `isRegistered` already `true` and simply reuses it.
  static GamePraiseSignal _resolvePraiseSignal() {
    if (!di.sl.isRegistered<GamePraiseSignal>()) {
      di.sl.registerLazySingleton<GamePraiseSignal>(() => GamePraiseSignal());
    }
    return di.sl<GamePraiseSignal>();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
