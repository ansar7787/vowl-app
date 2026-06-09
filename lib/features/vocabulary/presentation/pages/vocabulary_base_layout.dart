import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_scaffold.dart';

class VocabularyBaseLayout extends StatefulWidget {
  final GameSubtype gameType;
  final int level;
  final Widget child;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;
  final VoidCallback onHint;
  final bool showConfetti;
  final bool useScrolling;
  final bool disablePadding;

  const VocabularyBaseLayout({
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
  State<VocabularyBaseLayout> createState() => _VocabularyBaseLayoutState();
}

class _VocabularyBaseLayoutState extends State<VocabularyBaseLayout> {
  late final TtsService _ttsService;
  late final HapticService _hapticService;

  bool _hasSpokenNudge = false;
  int _lastLives = VocabularyRewardConstants.initialLives;
  bool _showBriefing = false;

  @override
  void initState() {
    super.initState();
    _ttsService = di.sl<TtsService>();
    _hapticService = di.sl<HapticService>();
    _showBriefing = widget.level == 1 || widget.level == 100;
  }

  void _handleLastLifeNudge(BuildContext ctx) {
    if (_hasSpokenNudge) return;
    _hasSpokenNudge = true;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!ctx.mounted) return;
      _ttsService.speak(
        'Focus! Use a hint if you need help saving your last life.',
      );
      _hapticService.warning();
    });
  }

  void _onStateChange(BuildContext ctx, VocabularyState state) {
    if (state is! VocabularyLoaded) return;
    final justDroppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;
    if (justDroppedToLastLife) _handleLastLifeNudge(ctx);
    _lastLives = state.livesRemaining;
  }

  void _onExitPressed(BuildContext ctx) {
    GameDialogHelper.showExitConfirmation(
      ctx,
      onQuit: () => Navigator.of(ctx).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocListener<VocabularyBloc, VocabularyState>(
      listenWhen: (prev, curr) {
        if (curr is! VocabularyLoaded) return false;
        if (prev is! VocabularyLoaded) return true;
        return prev.livesRemaining != curr.livesRemaining ||
            prev.currentIndex != curr.currentIndex;
      },
      listener: _onStateChange,
      child: BlocBuilder<VocabularyBloc, VocabularyState>(
        buildWhen: (prev, curr) {
          if (prev.runtimeType != curr.runtimeType) return true;
          if (curr is VocabularyLoaded && prev is VocabularyLoaded) {
            return prev.currentIndex != curr.currentIndex ||
                prev.lastAnswerCorrect != curr.lastAnswerCorrect ||
                prev.hintUsed != curr.hintUsed ||
                prev.isFinalFailure != curr.isFinalFailure;
          }
          return true;
        },
        builder: (context, state) {
          final isComplete = state is VocabularyGameComplete;
          return PopScope(
            canPop: isComplete,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _onExitPressed(context);
            },
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(
                  context,
                ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.1),
              ),
              child: VocabularyScaffold(
                state: state,
                theme: theme,
                isDark: isDark,
                config: widget,
                showBriefing: _showBriefing,
                onBriefingDismiss: () => setState(() => _showBriefing = false),
                onBriefingShow: () => setState(() => _showBriefing = true),
                onExitPressed: () => _onExitPressed(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
