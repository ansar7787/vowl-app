import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/usecases/increment_xp.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/handwriting/domain/models/handwriting_puzzle.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/utils/handwriting_evaluator.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_canvas.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_completed_view.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_top_bar.dart';

/// Key prefix for handwriting daily completion persistence.
const _kCompletionKeyPrefix = 'handwriting_completed_';

/// Brand accent color for Handwriting challenge matching Explore & Tools.
const _kPrimaryColor = AppColors.teal500;

/// Production daily challenge screen for Handwriting and stroke tracing.
///
/// Features the blackboard canvas with wood frame, guidelines, chalk dust FX,
/// demo stroke guide, undo, and duster, while eliminating bulky progress bars
/// and intrusive question cards.
class HandwritingScreen extends StatefulWidget {
  final int level;

  const HandwritingScreen({super.key, this.level = 1});

  @override
  State<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  static const HandwritingEvaluator _evaluator = HandwritingEvaluator();

  final ValueNotifier<HandwritingPuzzle?> _currentPuzzle = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyCompleted = ValueNotifier(false);
  final ValueNotifier<bool> _isPracticeMode = ValueNotifier(false);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isChecking = ValueNotifier(false);
  final ValueNotifier<bool> _hasInk = ValueNotifier(false);

  final GlobalKey<HandwritingCanvasState> _canvasKey =
      GlobalKey<HandwritingCanvasState>();
  Ink? _currentInk;

  @override
  void initState() {
    super.initState();
    _loadDailyPuzzle();
    _ensureModelDownloaded();
  }

  Future<void> _ensureModelDownloaded() async {
    try {
      if (di.sl.isRegistered<DigitalInkService>()) {
        await di.sl<DigitalInkService>().downloadModel();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _currentPuzzle.dispose();
    _isAnswered.dispose();
    _hasError.dispose();
    _alreadyCompleted.dispose();
    _isPracticeMode.dispose();
    _showConfetti.dispose();
    _isChecking.dispose();
    _hasInk.dispose();
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  String get _todayKey =>
      _kCompletionKeyPrefix + DateTime.now().toIso8601String().split('T')[0];

  Future<void> _loadDailyPuzzle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDoneToday = prefs.getBool(_todayKey) == true;

      final rawMap = await DailyChallengeService.getTodayHandwriting();
      if (!mounted) return;

      if (rawMap == null) {
        _hasError.value = true;
        return;
      }

      final puzzle = HandwritingPuzzle.fromMap(rawMap);
      _currentPuzzle.value = puzzle;

      if (isDoneToday) {
        _alreadyCompleted.value = true;
      }
    } catch (_) {
      if (mounted) _hasError.value = true;
    }
  }

  Future<void> _checkHandwriting(BuildContext context) async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) {
      _hapticService.warning();
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'daily_challenges.handwriting_draw_first',
          fallback: 'Draw your strokes on the chalkboard slate first!',
        ),
        type: CustomSnackBarType.warning,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final puzzle = _currentPuzzle.value;
    if (puzzle == null) return;

    _isChecking.value = true;

    final targetText = puzzle.target.trim();
    List<String> recognitionResults = const [];

    try {
      if (di.sl.isRegistered<DigitalInkService>()) {
        final digitalInkService = di.sl<DigitalInkService>();
        recognitionResults = await digitalInkService.recognize(_currentInk!);
      }
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'DigitalInkService recognition fallback: $e',
          tag: 'HandwritingScreen',
        );
      }
      recognitionResults = const [];
    }

    if (!mounted) return;

    final bool correct = _evaluator.evaluate(
      ink: _currentInk!,
      target: targetText,
      candidates: recognitionResults,
    );

    _isChecking.value = false;

    if (!mounted) return;

    if (correct) {
      _soundService.playCorrect();
      _hapticService.success();
      _showConfetti.value = true;

      // Mark daily challenge complete if not in practice mode
      if (!_isPracticeMode.value) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_todayKey, true);
        } catch (_) {}
      }

      _grantRewards();
      _isAnswered.value = true;
    } else {
      _hapticService.warning();
      _soundService.playWrong();
      if (!context.mounted) return;
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'daily_challenges.handwriting_try_again',
          fallback: 'Good effort! Check stroke direction and try once more.',
        ),
        type: CustomSnackBarType.warning,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _grantRewards() {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    final int awardedCoins = isPremium ? 30 : 10;

    if (di.sl.isRegistered<UpdateUserRewards>()) {
      di.sl<UpdateUserRewards>().call(
        UpdateUserRewardsParams(
          gameType: 'handwriting',
          xpIncrease: 5,
          coinIncrease: awardedCoins,
          level: widget.level,
        ),
      );
    } else {
      if (di.sl.isRegistered<UpdateUserCoins>()) {
        di.sl<UpdateUserCoins>().call(
          UpdateUserCoinsParams(
            amountChange: awardedCoins,
            title: 'Handwriting Challenge',
            isEarned: true,
          ),
        );
      }
      if (di.sl.isRegistered<IncrementXp>()) {
        di.sl<IncrementXp>().call(const IncrementXpParams(amount: 5));
      }
    }

    GameDialogHelper.showCompletion(
      context,
      xp: 5,
      coins: awardedCoins,
      title: context.tr(
        'daily_challenges.handwriting_master',
        fallback: 'HANDWRITING MASTER!',
      ),
      enableDoubleUp: true,
    );
  }

  Future<void> _startPracticeMode() async {
    _hapticService.light();
    try {
      final rawMap = await DailyChallengeService.getRandomHandwriting();
      if (!mounted) return;

      if (rawMap != null) {
        setState(() {
          _isPracticeMode.value = true;
          _alreadyCompleted.value = false;
          _isAnswered.value = false;
          _showConfetti.value = false;
          _currentInk = null;
          _hasInk.value = false;
          _currentPuzzle.value = HandwritingPuzzle.fromMap(rawMap);
        });
        _canvasKey.currentState?.clearCanvas();
      }
    } catch (_) {}
  }

  void _handleExitConfirmation() {
    final isCompleted = _alreadyCompleted.value;
    final isPractice = _isPracticeMode.value;

    if ((isCompleted && !isPractice) || _hasError.value || _isAnswered.value) {
      context.pop();
      return;
    }

    if (_hasInk.value) {
      GameDialogHelper.showExitConfirmation(
        context,
        onQuit: () => context.pop(),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final streak = user?.currentStreak ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleExitConfirmation();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _currentPuzzle,
          _isAnswered,
          _hasError,
          _alreadyCompleted,
          _isPracticeMode,
          _showConfetti,
          _isChecking,
          _hasInk,
        ]),
        builder: (context, _) {
          final puzzle = _currentPuzzle.value;
          final isCompleted = _alreadyCompleted.value;
          final isPractice = _isPracticeMode.value;
          final showConfetti = _showConfetti.value;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  _hasError.value
                      ? _buildErrorState(streak)
                      : ((isCompleted && !isPractice) || _isAnswered.value)
                      ? HandwritingCompletedView(
                          puzzle: puzzle,
                          streak: streak,
                          primaryColor: _kPrimaryColor,
                          hapticService: _hapticService,
                          onPracticeAgain: _startPracticeMode,
                          isPracticeMode: isPractice,
                        )
                      : puzzle == null
                      ? const GameShimmerLoading(primaryColor: _kPrimaryColor)
                      : _buildActiveGameContent(puzzle, streak, isPractice),

                  // Celebration confetti
                  if (showConfetti)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: GameConfetti(shouldPop: true),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveGameContent(
    HandwritingPuzzle puzzle,
    int streak,
    bool isPractice,
  ) {
    final isChecking = _isChecking.value;
    final hasInk = _hasInk.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // 1. Sleek Modern Top Bar (No bulky progress bar, no mascot)
        HandwritingTopBar(
          streak: streak,
          isPracticeMode: isPractice,
          onBackPressed: _handleExitConfirmation,
        ),

        // 2. Minimalist Prompt / Target Banner
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _kPrimaryColor.withValues(alpha: 0.25),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Target display chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    puzzle.target,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: _kPrimaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Instruction text
                Expanded(
                  child: Text(
                    puzzle.instruction.isNotEmpty
                        ? puzzle.instruction
                        : 'Trace the target on the slate',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Audio speech button
                Semantics(
                  button: true,
                  label: 'Listen to instruction',
                  child: ScaleButton(
                    onTap: () {
                      _hapticService.light();
                      final textToSpeak = puzzle.instruction.isNotEmpty
                          ? puzzle.instruction
                          : puzzle.target;
                      if (di.sl.isRegistered<TtsService>()) {
                        di.sl<TtsService>().speak(textToSpeak);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.volume2,
                        size: 16.r,
                        color: _kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Chalkboard Slate Canvas (Preserved with frame, dust, guidelines, demo, undo, duster)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520.w),
                child: HandwritingCanvas(
                  key: _canvasKey,
                  ghostText: puzzle.target,
                  showGuidelines: true,
                  initialShowGuide: puzzle.level <= 10,
                  onStrokeCountChanged: (count) {
                    _hasInk.value = count > 0;
                  },
                  onInkUpdated: (ink) {
                    _currentInk = ink;
                    _hasInk.value = ink.strokes.isNotEmpty;
                  },
                  onClear: () {
                    _currentInk = null;
                    _hasInk.value = false;
                  },
                ),
              ),
            ),
          ),
        ),

        // 4. Modern Bottom Action Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: ScaleButton(
            onTap: isChecking ? null : () => _checkHandwriting(context),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 420.w, minHeight: 56.h),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                gradient: hasInk && !isChecking
                    ? const LinearGradient(
                        colors: [_kPrimaryColor, Color(0xFF0F766E)],
                      )
                    : null,
                color: !hasInk || isChecking
                    ? Colors.grey.shade400
                    : null,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: hasInk && !isChecking
                    ? [
                        BoxShadow(
                          color: _kPrimaryColor.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isChecking
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VowlButtonSpinner(
                            color: Colors.white,
                            size: 20.h,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            context.tr(
                              'daily_challenges.checking',
                              fallback: 'Checking...',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        context.tr('common.check', fallback: 'Check Writing'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(int streak) {
    return Column(
      children: [
        HandwritingTopBar(streak: streak),
        Expanded(
          child: Center(
            child: Padding(
              padding: AppSpacing.spaciousPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    color: AppColors.rose500,
                    size: 48.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr(
                      'daily_challenges.load_error',
                      fallback: 'Unable to load today\'s challenge',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ScaleButton(
                    onTap: () {
                      _hasError.value = false;
                      _loadDailyPuzzle();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        context.tr('common.retry', fallback: 'Retry'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
