import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_assembly_card.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_completed_view.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_hint_card.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_target_card.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_top_bar.dart';

/// Persistence key prefix for daily challenge completion tracking.
const _kCompletionKeyPrefix = 'word_snap_completed_';

/// Brand primary color for Word Snap matching tools_strip vibrant pink.
const _kPrimaryColor = IllustrationColors.vibrantPink;

/// Daily challenge screen for Word Snap sentence assembly puzzles featuring
/// tactile token snapping, contextual cloze hints, and CEFR metrics.
class WordSnapScreen extends StatefulWidget {
  final int level;

  const WordSnapScreen({super.key, this.level = 1});

  @override
  State<WordSnapScreen> createState() => _WordSnapScreenState();
}

class _WordSnapScreenState extends State<WordSnapScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<WordSnapPuzzle?> _currentPuzzle = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool> _isHintExpanded = ValueNotifier(false);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyCompleted = ValueNotifier(false);
  final ValueNotifier<bool> _isPracticeMode = ValueNotifier(false);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  int _sessionCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyPuzzle();
  }

  @override
  void dispose() {
    _currentPuzzle.dispose();
    _isAnswered.dispose();
    _isHintExpanded.dispose();
    _hasError.dispose();
    _alreadyCompleted.dispose();
    _isPracticeMode.dispose();
    _showConfetti.dispose();
    super.dispose();
  }

  String get _todayKey =>
      _kCompletionKeyPrefix + DateTime.now().toIso8601String().split('T')[0];

  Future<void> _loadDailyPuzzle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_todayKey) == true;

      final rawPuzzle = await DailyChallengeService.getTodayWordSnap();
      if (!mounted) return;

      if (rawPuzzle == null) {
        _hasError.value = true;
        return;
      }

      final puzzle = WordSnapPuzzle.fromMap(rawPuzzle);
      _currentPuzzle.value = puzzle;

      if (isCompleted) {
        _alreadyCompleted.value = true;
      }
    } catch (_) {
      if (mounted) _hasError.value = true;
    }
  }

  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_todayKey, true);
  }

  void _onSuccess() {
    if (_isAnswered.value) return;
    _showConfetti.value = true;

    if (_isPracticeMode.value) {
      _isAnswered.value = true;
      if (mounted) {
        GameDialogHelper.showCompletion(
          context,
          xp: 15,
          coins: 0,
          title: context.tr(
            'vocabulary.practice_complete',
            fallback: 'Practice Complete!',
          ),
          description: context.tr(
            'vocabulary.practice_complete_desc',
            fallback: 'Well done! Keep practicing to strengthen your vocabulary.',
          ),
          enableDoubleUp: false,
        );
      }
      return;
    }

    _alreadyCompleted.value = true;
    _markCompleted();
    _grantRewards();
  }

  void _grantRewards() {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    final int awardedCoins = isPremium ? 30 : 10;
    di.sl<UpdateUserCoins>().call(
      UpdateUserCoinsParams(
        amountChange: awardedCoins,
        title: 'Word Snap Challenge',
        isEarned: true,
      ),
    );

    GameDialogHelper.showCompletion(
      context,
      xp: 50,
      coins: 10,
      title: context.tr(
        'vocabulary.word_snap_master',
        fallback: 'WORD SNAP MASTER!',
      ),
      enableDoubleUp: true,
    );
  }

  Future<void> _startPracticeMode() async {
    _hapticService.light();
    try {
      final rawMap = await DailyChallengeService.getRandomWordSnap();
      if (!mounted) return;

      if (rawMap != null) {
        setState(() {
          _sessionCounter++;
          _isPracticeMode.value = true;
          _alreadyCompleted.value = false;
          _isAnswered.value = false;
          _isHintExpanded.value = false;
          _showConfetti.value = false;
          _currentPuzzle.value = WordSnapPuzzle.fromMap(rawMap);
        });
      }
    } catch (_) {
      if (mounted) _hasError.value = true;
    }
  }

  void _exitPracticeMode() {
    _isPracticeMode.value = false;
    _isAnswered.value = false;
    _isHintExpanded.value = false;
    _showConfetti.value = false;
  }

  void _handleExitConfirmation() {
    final isCompleted = _alreadyCompleted.value;
    final isPractice = _isPracticeMode.value;

    // If game has already finished or in error state, allow immediate pop
    if ((isCompleted && !isPractice) || _hasError.value || _isAnswered.value) {
      context.pop();
      return;
    }

    // Active gameplay: prompt standardized exit confirmation
    GameDialogHelper.showExitConfirmation(
      context,
      onQuit: () => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          ? WordSnapCompletedView(
                              puzzle: puzzle,
                              streak: streak,
                              primaryColor: _kPrimaryColor,
                              soundService: _soundService,
                              hapticService: _hapticService,
                              onPracticeAgain: _startPracticeMode,
                              isPracticeMode: isPractice,
                            )
                          : puzzle == null
                              ? const GameShimmerLoading(primaryColor: _kPrimaryColor)
                              : _buildSliverGameContent(puzzle, streak, isDark, isPractice),

                  // Celebratory Confetti Burst Overlay
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

  // ─── High-Performance Sliver Game Content ──────────────────────────────

  Widget _buildSliverGameContent(
    WordSnapPuzzle puzzle,
    int streak,
    bool isDark,
    bool isPractice,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Top Navigation Bar
        SliverToBoxAdapter(
          child: WordSnapTopBar(
            streak: streak,
            onBackPressed: _handleExitConfirmation,
          ),
        ),

        // 2. Practice Mode Banner (if active)
        if (isPractice)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _kPrimaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: _kPrimaryColor, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr('vocabulary.practice_mode', fallback: 'Practice Mode'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryColor,
                      ),
                    ),
                  ),
                  ScaleButton(
                    onTap: _exitPracticeMode,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: Text(
                        context.tr('common.exit', fallback: 'Exit'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: _kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Main Gameplay Cards in SliverList with smooth padding
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(
            top: 6.h,
            bottom: MediaQuery.of(context).padding.bottom + 32.h,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Target Word Card
              WordSnapTargetCard(
                puzzle: puzzle,
                primaryColor: _kPrimaryColor,
                soundService: _soundService,
                hapticService: _hapticService,
              ),
              SizedBox(height: 14.h),

              // Progressive Hint Card
              WordSnapHintCard(
                puzzle: puzzle,
                isExpandedNotifier: _isHintExpanded,
                primaryColor: _kPrimaryColor,
                soundService: _soundService,
                hapticService: _hapticService,
              ),
              SizedBox(height: 18.h),

              // Bespoke Sentence Assembly Card (No Skip button, non-punitive)
              WordSnapAssemblyCard(
                key: ValueKey('snap_${puzzle.id}_${isPractice}_$_sessionCounter'),
                puzzle: puzzle,
                primaryColor: _kPrimaryColor,
                onSuccess: _onSuccess,
                soundService: _soundService,
                hapticService: _hapticService,
                isAnswered: _isAnswered.value,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorState(int streak) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        WordSnapTopBar(
          streak: streak,
          onBackPressed: () => context.pop(),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: _kPrimaryColor.withValues(alpha: 0.6),
                      size: 48.r,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    context.tr(
                      'home.puzzle_load_failed',
                      fallback: 'Couldn\'t load today\'s puzzle',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr(
                      'home.puzzle_load_failed_desc',
                      fallback: 'Check your connection and try again.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      _hapticService.light();
                      _hasError.value = false;
                      _loadDailyPuzzle();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      context.tr('common.retry', fallback: 'Retry'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
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
