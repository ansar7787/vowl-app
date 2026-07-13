import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/constants/reading_constants.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_content_area.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_feedback_card.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_header.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_passage_area.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Orchestration-only layout for all reading game screens.
///
/// This widget owns:
/// - BLoC subscription (BlocConsumer)
/// - Theme resolution (type-inferred, no `dynamic`)
/// - Briefing overlay state
/// - TTS nudge timer
/// - Widget assembly (delegates all rendering to focused sub-widgets)
///
/// It deliberately contains NO layout or paint logic — every visual
/// responsibility is handled by the extracted sub-widgets in `widgets/`.
class ReadingBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool isFinalFailure;
  final String? passage;
  final bool useScrolling;
  final bool disablePadding;

  const ReadingBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.passage,
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  State<ReadingBaseLayout> createState() => _ReadingBaseLayoutState();
}

class _ReadingBaseLayoutState extends State<ReadingBaseLayout> {
  // ---------------------------------------------------------------------------
  // Pre-resolved services
  // ---------------------------------------------------------------------------

  final _ttsService = di.sl<TtsService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  // ---------------------------------------------------------------------------
  // Local state
  // ---------------------------------------------------------------------------

  late bool _showBriefing;
  bool _hasSpokenNudge = false;

  /// Tracks lives from the previous build to detect the 2→1 life transition.
  int _lastLives = ReadingGameConfig.initialLives;

  Timer? _nudgeTimer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  bool _computeShowBriefing() =>
      widget.level == 1 ||
      widget.level == ReadingGameConfig.milestoneBriefingLevel;

  @override
  void initState() {
    super.initState();
    _showBriefing = _computeShowBriefing();
  }

  @override
  void didUpdateWidget(covariant ReadingBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      setState(() => _showBriefing = _computeShowBriefing());
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Type-inferred — Dart resolves the concrete LevelTheme return type from
    // LevelThemeHelper.getTheme(). No `dynamic` anywhere in this file.
    //  Annotate explicitly once the LevelTheme class name is confirmed:
    //   final LevelTheme theme = LevelThemeHelper.getTheme(...)
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );
    final primaryColor = theme.primaryColor;
    final backgroundColors = theme.backgroundColors;

    // Auth read — mascotId rarely changes, safe to read in build.
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );
    final mascotName = mascotId
        .split('_')
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');

    return BlocConsumer<ReadingBloc, ReadingState>(
      // Only listen when lives or question index change — avoids running the
      // TTS nudge logic on every answer submission.
      listenWhen: (prev, curr) {
        if (curr is ReadingLoaded) {
          if (prev is! ReadingLoaded) return true;
          return prev.livesRemaining != curr.livesRemaining ||
              prev.currentIndex != curr.currentIndex;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! ReadingLoaded) return;
        final droppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;
        if (droppedToLastLife && !_hasSpokenNudge) {
          _hasSpokenNudge = true;
          _nudgeTimer?.cancel();
          _nudgeTimer = Timer(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            _ttsService.stop();
            _ttsService.speak(context.tr('games.kids_nudge', fallback: 'Let\\'s go!'));
            _hapticService.warning();
          });
        }
        _lastLives = state.livesRemaining;
      },
      builder: (context, state) {
        // ---------------------------------------------------------------------------
        // Error state — shown before the full scaffold to keep it lightweight.
        // ---------------------------------------------------------------------------
        if (state is ReadingError) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: backgroundColors[1],
            body: GameErrorWidget(
              message: state.message,
              onRetry: () => context.read<ReadingBloc>().add(
                FetchReadingQuests(
                  gameType: widget.gameType,
                  level: widget.level,
                ),
              ),
              onBack: () => Navigator.pop(context),
              primaryColor: primaryColor,
            ),
          );
        }

        // ---------------------------------------------------------------------------
        // Derived state values
        // ---------------------------------------------------------------------------
        final isLoaded = state is ReadingLoaded;
        final isComplete = state is ReadingGameComplete;
        final isGameOver = state is ReadingGameOver;

        final lives = isLoaded
            ? state.livesRemaining
            : ReadingGameConfig.initialLives;
        final progress = isLoaded
            ? (state.currentIndex + 1) / state.quests.length
            : (isComplete ? 1.0 : 0.0);
        final streak = isLoaded ? state.currentIndex : 0;
        final hintUsed = isLoaded ? state.hintUsed : false;
        final currentQuest = isLoaded ? state.currentQuest : null;

        // Briefing object is resolved once per build pass — not per property.
        final briefing = _showBriefing
            ? GameInstructionService.getBriefing(
                context,
                widget.gameType,
                'Reading',
                level: widget.level,
              )
            : null;

        // GameProgressHeader is built here so ReadingHeader never needs to import
        // the theme type — it just receives a pre-built Widget.
        final gameProgressHeader = GameProgressHeader(
          level: widget.level,
          progress: progress,
          lives: lives,
          streak: streak,
          theme: theme, // typed via inference — no dynamic
          isDark: isDark,
          onBack: () => GameDialogHelper.showExitConfirmation(
            context,
            onQuit: () => Navigator.of(context).pop(),
          ),
        );

        // ---------------------------------------------------------------------------
        // Scaffold
        // ---------------------------------------------------------------------------
        return Builder(
          // Builder gives us a context that is a descendant of BlocConsumer,
          // ensuring Navigator and dialog lookups resolve correctly.
          builder: (localContext) {
            return PopScope(
              canPop: isComplete,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                GameDialogHelper.showExitConfirmation(
                  localContext,
                  onQuit: () => Navigator.of(localContext).pop(),
                );
              },
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: backgroundColors[1],
                body: Stack(
                  children: [
                    // Solid base colour prevents white flash during theme transitions.
                    ColoredBox(
                      color: backgroundColors[1],
                      child: const SizedBox.expand(),
                    ),

                    MeshGradientBackground(colors: backgroundColors),

                    if (state is ReadingLoading)
                      GameShimmerLoading(primaryColor: primaryColor)
                    else
                      SafeArea(
                        child: Column(
                          children: [
                            SizedBox(height: 10.h),
                            ReadingHeader(
                              gameProgressHeader: gameProgressHeader,
                              primaryColor: primaryColor,
                              currentQuest: currentQuest,
                              isAnswered: widget.isAnswered,
                              hintUsed: hintUsed,
                              lives: lives,
                              soundService: _soundService,
                              onInfoTap: () =>
                                  setState(() => _showBriefing = true),
                              onHint: () {
                                context.read<ReadingBloc>().add(
                                  const ReadingHintUsed(),
                                );
                                widget.onHint();
                              },
                            ),
                            if (widget.passage != null && !widget.isAnswered)
                              ReadingPassageArea(
                                passage: widget.passage!,
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                            ReadingContentArea(
                              isAnswered: widget.isAnswered,
                              useScrolling: widget.useScrolling,
                              disablePadding: widget.disablePadding,
                              lives: lives,
                              isCorrect: widget.isCorrect,
                              isGameComplete: isComplete,
                              isGameOver: isGameOver,
                              mascotId: mascotId,
                              mascotName: mascotName,
                              child: widget.child,
                            ),
                          ],
                        ),
                      ),

                    // Feedback card — guard is now a state type check (not a
                    // fragile prop check) so there is no unsafe cast risk.
                    if (widget.isAnswered && isLoaded)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ReadingFeedbackCard(
                          isCorrect: widget.isCorrect,
                          lives: lives,
                          isFinalFailure: state.isFinalFailure,
                          currentQuest: state.currentQuest,
                          onContinue: widget.onContinue,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                      ),

                    // RepaintBoundary isolates the confetti particle system
                    // from the rest of the widget tree.
                    if (widget.showConfetti)
                      const RepaintBoundary(child: GameConfetti()),

                    if (briefing != null)
                      QuestBriefingOverlay(
                        title: briefing.title,
                        objective: briefing.objective,
                        rules: briefing.rules,
                        actionText: briefing.actionText,
                        tip: briefing.tip,
                        icon: briefing.icon,
                        primaryColor: primaryColor,
                        onStart: () => setState(() => _showBriefing = false),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
