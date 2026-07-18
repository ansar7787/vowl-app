import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/constants/grammar_constants.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/presentation/widgets/grammar/logic_circuit.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_error_widget.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_feedback_card.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_game_header.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_peeking_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Shared scaffold for all grammar question-type screens.
///
/// Responsibilities:
/// - BLoC listener (TTS nudge, life-drop feedback)
/// - Scaffold + background layers
/// - Pop interception
/// - Assembles [GrammarGameHeader], [GrammarMascotOverlay],
///   [GrammarFeedbackCard], and the question child.
///
/// Each visual section is a dedicated widget — this file is intentionally
/// an orchestration layer only.
class GrammarBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool isFinalFailure;
  final bool useScrolling;
  final bool disablePadding;

  const GrammarBaseLayout({
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
    this.useScrolling = false,
    this.disablePadding = false,
  });

  @override
  State<GrammarBaseLayout> createState() => _GrammarBaseLayoutState();
}

class _GrammarBaseLayoutState extends State<GrammarBaseLayout> {
  // All services resolved once in initState so failures are visible at
  // widget-creation time rather than buried inside callbacks.
  late final TtsService _ttsService;
  late final SoundService _soundService;
  late final HapticService _hapticService;

  // Level theme cached here because widget.level is final — the theme is
  // stable for this State's entire lifecycle.
  // : Replace `dynamic` with LevelThemeHelper's concrete return type.
  late final dynamic _theme;

  // Mascot ID cached once; user profile does not change mid-session.
  late final String _mascotId;

  bool _hasSpokenNudge = false;
  int _lastLives = GrammarConstants.livesPerLevel;
  late bool _showBriefing;

  @override
  void initState() {
    super.initState();
    _ttsService = di.sl<TtsService>();
    _soundService = di.sl<SoundService>();
    _hapticService = di.sl<HapticService>();
    _theme = LevelThemeHelper.getTheme('grammar', level: widget.level);
    _mascotId = context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';
    _showBriefing = widget.level == 1 || widget.level == 100;
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  EdgeInsets _contentPadding() {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (widget.disablePadding) return EdgeInsets.only(bottom: keyboard);
    return EdgeInsets.only(
      left: 16.w,
      right: 16.w,
      top: 20.h,
      bottom: (widget.isAnswered ? 200.h : 40.h) + keyboard,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<GrammarBloc, GrammarState>(
      listenWhen: (previous, current) {
        if (current is! GrammarLoaded) return false;
        if (previous is! GrammarLoaded) return true;
        return previous.currentIndex != current.currentIndex ||
            previous.livesRemaining != current.livesRemaining;
      },
      listener: _handleStateChange,
      child: BlocBuilder<GrammarBloc, GrammarState>(builder: _buildScaffold),
    );
  }

  void _handleStateChange(BuildContext context, GrammarState state) {
    if (state is! GrammarLoaded) return;

    final droppedToLast = _lastLives == 2 && state.livesRemaining == 1;
    _lastLives = state.livesRemaining;

    if (droppedToLast && !_hasSpokenNudge) {
      _hasSpokenNudge = true;
      final nudgeMessage = context.tr(
        'games.kids_nudge',
        fallback: 'Let\'s go!',
      );
      Future.delayed(
        const Duration(milliseconds: GrammarConstants.lastLifeNudgeDelayMs),
        () async {
          if (!mounted) return;
          await _ttsService.stop();
          await _ttsService.speak(nudgeMessage);
          _hapticService.warning();
        },
      );
    }
  }

  Widget _buildScaffold(BuildContext context, GrammarState state) {
    if (state is GrammarError) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _theme.backgroundColors[1],
        body: GameErrorWidget(
          message: state.message,
          onRetry: () => context.read<GrammarBloc>().add(
            FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
          ),
          onBack: () => context.pop(),
          primaryColor: _theme.primaryColor,
        ),
      );
    }

    final isComplete = state is GrammarGameComplete;
    final questCount = state is GrammarLoaded
        ? state.quests.length.clamp(1, 999)
        : 1;
    final progress = state is GrammarLoaded
        ? (state.currentIndex + 1) / questCount
        : (isComplete ? 1.0 : 0.0);
    final lives = state is GrammarLoaded ? state.livesRemaining : 3;
    final currentQuest = state is GrammarLoaded ? state.currentQuest : null;

    return PopScope(
      canPop: isComplete,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        GameDialogHelper.showExitConfirmation(
          context,
          onQuit: () => context.pop(),
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _theme.backgroundColors[1],
        body: Stack(
          children: [
            Positioned.fill(
              child: MeshGradientBackground(colors: _theme.backgroundColors),
            ),
            Positioned.fill(
              child: LogicCircuit(
                color: (_theme.primaryColor as Color).withValues(alpha: 0.2),
              ),
            ),
            if (state is GrammarLoading)
              GameShimmerLoading(primaryColor: _theme.primaryColor)
            else ...[
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    GrammarGameHeader(
                      state: state,
                      level: widget.level,
                      progress: progress,
                      lives: lives,
                      theme: _theme,
                      quest: currentQuest,
                      isAnswered: widget.isAnswered,
                      isFinalFailure: widget.isFinalFailure,
                      soundService: _soundService,
                      onShowBriefing: () =>
                          setState(() => _showBriefing = true),
                      onHint: widget.onHint,
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
                              child: _buildContent(),
                            ),
                          ),
                          Positioned(
                            top: -20.h,
                            right: 20.w,
                            child: GrammarPeekingMascot(
                              state: state,
                              lives: lives,
                              isCorrect: widget.isCorrect,
                              isAnswered: widget.isAnswered,
                              mascotId: _mascotId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.isAnswered)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GrammarFeedbackCard(
                  state: state,
                  isCorrect: widget.isCorrect,
                  isFinalFailure: widget.isFinalFailure,
                  onContinue: widget.onContinue,
                ),
              ),
            if (widget.showConfetti) const GameConfetti(),
            if (_showBriefing) _buildBriefingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final padding = _contentPadding();
    if (!widget.useScrolling) {
      return Padding(padding: padding, child: widget.child);
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(padding: padding, child: widget.child),
        ),
      ),
    );
  }

  Widget _buildBriefingOverlay() {
    final briefing = GameInstructionService.getBriefing(
      context,
      widget.gameType,
      'Grammar',
      level: widget.level,
    );
    return QuestBriefingOverlay(
      title: briefing.title,
      objective: briefing.objective,
      rules: briefing.rules,
      actionText: briefing.actionText,
      tip: briefing.tip,
      icon: briefing.icon,
      primaryColor: _theme.primaryColor,
      onStart: () => setState(() => _showBriefing = false),
    );
  }
}
