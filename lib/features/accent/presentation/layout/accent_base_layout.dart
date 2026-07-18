import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_content_body.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_feedback_card.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_header.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_peeking_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ---------------------------------------------------------------------------
// AccentBaseLayout
// ---------------------------------------------------------------------------

/// Scaffold shell for all Accent game variants.
class AccentBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final VoidCallback? onTutorPass;
  final bool showConfetti;
  final String title;
  final String subtitle;
  final bool useScrolling;
  final bool disablePadding;

  const AccentBaseLayout({
    super.key,
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    required this.onContinue,
    required this.onHint,
    this.onTutorPass,
    this.showConfetti = false,
    this.title = 'ACCENT TRAINING',
    this.subtitle = 'Master the Sound',
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  State<AccentBaseLayout> createState() => _AccentBaseLayoutState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _AccentBaseLayoutState extends State<AccentBaseLayout> {
  // Services resolved once at field-initialisation time.
  // All three are stored as fields so Future.delayed callbacks and
  // sub-widgets can reference them without re-calling the locator.
  final _ttsService = di.sl<TtsService>();
  final _soundService = di.sl<SoundService>();
  final _hapticService = di.sl<HapticService>();

  bool _hasSpokenNudge = false;
  int _lastIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  late bool _showBriefing;

  @override
  void initState() {
    super.initState();
    _showBriefing = AccentGameConstants.briefingAutoShowLevels.contains(
      widget.level,
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Subscribes only to vowlMascot changes — not every AuthState emission.
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? 'vowl_prime',
    );

    return BlocListener<AccentBloc, AccentState>(
      listenWhen: (prev, curr) {
        if (curr is AccentGameOver) return true;
        if (curr is AccentLoaded) {
          if (prev is! AccentLoaded) return true;
          return prev.currentIndex != curr.currentIndex ||
              prev.livesRemaining != curr.livesRemaining;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRetry: () => context.read<AccentBloc>().add(const RestoreLife()),
            onQuit: () => Navigator.of(context).pop(),
          );
          return;
        }

        if (state is! AccentLoaded) return;

        if (state.currentIndex != _lastIndex) {
          _lastIndex = state.currentIndex;
        }

        // Trigger voice + haptic nudge exactly once when lives drop to 1.
        if (_lastLives == 2 && state.livesRemaining == 1 && !_hasSpokenNudge) {
          _hasSpokenNudge = true;
          final nudgeMsg = AccentGameConstants.nudgeMessage(context);
          Future.delayed(
            const Duration(milliseconds: AccentGameConstants.nudgeDelayMs),
            () {
              if (!mounted) return;
              _ttsService.stop();
              _ttsService.speak(nudgeMsg);
              _hapticService.warning();
            },
          );
        }
        _lastLives = state.livesRemaining;
      },
      child: BlocBuilder<AccentBloc, AccentState>(
        builder: (context, state) {
          // ── Theme ─────────────────────────────────────────────────────
          // Use Dart type inference — never write the return-type name of
          // getTheme() explicitly.  This avoids "Undefined class 'LevelTheme'"
          // regardless of what the internal class is called.
          final rawTheme = LevelThemeHelper.getTheme(
            'accent',
            level: widget.level,
          );
          final Color primaryColor = rawTheme.primaryColor;
          final List<Color> backgroundColors = rawTheme.backgroundColors;

          // ── Error state ─────────────────────────────────────────────
          if (state is AccentError) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: backgroundColors[1],
              body: GameErrorWidget(
                // Security: technicalError only surfaced in debug builds.
                message: kDebugMode && state.technicalError != null
                    ? '${state.message}\n\n[DEBUG] ${state.technicalError}'
                    : state.message,
                onRetry: () => context.read<AccentBloc>().add(
                  FetchAccentQuests(
                    gameType: widget.gameType,
                    level: widget.level,
                  ),
                ),
                onBack: () => Navigator.pop(context),
                primaryColor: primaryColor,
              ),
            );
          }

          final isComplete = state is AccentGameComplete;
          final lives = state.livesRemaining;
          final progress = state is AccentLoaded
              ? (state.currentIndex + 1) / state.quests.length
              : (isComplete ? 1.0 : 0.0);

          return PopScope(
            canPop: isComplete,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              GameDialogHelper.showExitConfirmation(
                context,
                onQuit: () => Navigator.of(context).pop(),
              );
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: backgroundColors[1],
              body: Stack(
                children: [
                  // Prevents white flash during theme transitions.
                  Container(color: backgroundColors[1]),
                  MeshGradientBackground(colors: backgroundColors),
                  // ClipRect prevents HarmonicWaves overflowing in landscape.
                  ClipRect(
                    child: HarmonicWaves(
                      color: primaryColor.withValues(alpha: 0.3),
                      height: 150.h,
                    ),
                  ),

                  if (state is AccentLoading)
                    GameShimmerLoading(primaryColor: primaryColor)
                  else ...[
                    SafeArea(
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          AccentHeader(
                            level: widget.level,
                            progress: progress,
                            lives: lives,
                            streak: state is AccentLoaded
                                ? state.currentIndex
                                : 0,
                            isDark: isDark,
                            quest: state is AccentLoaded
                                ? state.currentQuest
                                : null,
                            isAnswered: widget.isAnswered,
                            hintUsed: state is AccentLoaded
                                ? state.hintUsed
                                : false,
                            soundService: _soundService,
                            onBack: () => GameDialogHelper.showExitConfirmation(
                              context,
                              onQuit: () => Navigator.pop(context),
                            ),
                            onShowBriefing: () =>
                                setState(() => _showBriefing = true),
                            onHintTap: () {
                              context.read<AccentBloc>().add(
                                const AccentHintUsed(),
                              );
                              widget.onHint();
                            },
                          ),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: widget.isAnswered ? 0.6 : 1.0,
                                  child: AbsorbPointer(
                                    absorbing: widget.isAnswered,
                                    child: AccentContentBody(
                                      useScrolling: widget.useScrolling,
                                      disablePadding: widget.disablePadding,
                                      isAnswered: widget.isAnswered,
                                      title: widget.title,
                                      subtitle: widget.subtitle,
                                      primaryColor: primaryColor,
                                      isDark: isDark,
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -10.h,
                                  right: 10.w,
                                  child: AccentPeekingMascot(
                                    state: state,
                                    lives: lives,
                                    mascotId: mascotId,
                                    isCorrect: widget.isCorrect,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Feedback card — only when state is definitively AccentLoaded.
                  // Typed param eliminates all unsafe `state as AccentLoaded` casts.
                  if (widget.isAnswered && state is AccentLoaded)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AccentFeedbackCard(
                        state: state,
                        isDark: isDark,
                        isCorrect: widget.isCorrect,
                        onContinue: widget.onContinue,
                        onTutorPass: widget.onTutorPass,
                      ),
                    ),

                  // RepaintBoundary isolates particle system repaints.
                  if (widget.showConfetti)
                    const RepaintBoundary(child: GameConfetti()),

                  // Briefing overlay.
                  if (_showBriefing) _buildBriefingOverlay(primaryColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Briefing overlay ──────────────────────────────────────────────────────

  Widget _buildBriefingOverlay(Color primaryColor) {
    final briefing = GameInstructionService.getBriefing(
      context,
      widget.gameType,
      'Accent',
      level: widget.level,
    );
    return QuestBriefingOverlay(
      title: briefing.title,
      objective: briefing.objective,
      rules: briefing.rules,
      actionText: briefing.actionText,
      tip: briefing.tip,
      icon: briefing.icon,
      primaryColor: primaryColor,
      onStart: () => setState(() => _showBriefing = false),
    );
  }
}
