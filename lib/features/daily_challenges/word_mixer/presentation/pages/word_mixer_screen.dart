import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_completed_view.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_hint_card.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_info_card.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_spelling_card.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_top_bar.dart';

/// Persistence key prefix for daily challenge completion tracking.
const _kCompletionKeyPrefix = 'word_mixer_completed_';

/// Brand primary color for Word Mixer.
const _kPrimaryColor = IllustrationColors.richPurple;

/// Daily challenge screen for Word Mixer anagram puzzles with letter-tile manipulation,
/// phonetic hints, audio playback, and streak rewards.
class WordMixerScreen extends StatefulWidget {
  const WordMixerScreen({super.key});

  @override
  State<WordMixerScreen> createState() => _WordMixerScreenState();
}

class _WordMixerScreenState extends State<WordMixerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<WordMixerPuzzle?> _currentPuzzle = ValueNotifier(null);
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
      final isDoneToday = prefs.getBool(_todayKey) == true;

      final rawMap = await DailyChallengeService.getTodayWordMixer();
      if (!mounted) return;

      if (rawMap == null) {
        _hasError.value = true;
        return;
      }

      final puzzle = WordMixerPuzzle.fromMap(rawMap);
      _currentPuzzle.value = puzzle;

      if (isDoneToday) {
        _alreadyCompleted.value = true;
      }
    } catch (_) {
      if (mounted) _hasError.value = true;
    }
  }

  Future<void> _startPracticeMode() async {
    _hapticService.light();
    try {
      final rawMap = await DailyChallengeService.getRandomWordMixer();
      if (!mounted) return;

      if (rawMap != null) {
        setState(() {
          _sessionCounter++;
          _isPracticeMode.value = true;
          _alreadyCompleted.value = false;
          _isAnswered.value = false;
          _isHintExpanded.value = false;
          _showConfetti.value = false;
          _currentPuzzle.value = WordMixerPuzzle.fromMap(rawMap);
        });
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
    _isAnswered.value = true;

    if (_isPracticeMode.value) {
      // Practice mode reward dialog
      GameDialogHelper.showCompletion(
        context,
        xp: 20,
        coins: 0,
        title: context.tr('home.practice_complete', fallback: 'Practice Complete!'),
        description: context.tr(
          'word_mixer.practice_complete_desc',
          fallback: 'Great job unscrambling this bonus word!',
        ),
        enableDoubleUp: false,
      );
    } else {
      // Daily challenge completion & rewards
      _alreadyCompleted.value = true;
      _markCompleted();
      _grantRewards();
    }
  }

  void _grantRewards() {
    di.sl<UpdateUserCoins>().call(
      const UpdateUserCoinsParams(
        amountChange: 10,
        title: 'Word Mixer Challenge',
        isEarned: true,
      ),
    );

    GameDialogHelper.showCompletion(
      context,
      xp: 50,
      coins: 10,
      title: context.tr(
        'home.word_mixer_master',
        fallback: 'WORD MIXER MASTER!',
      ),
      enableDoubleUp: true,
    );
  }

  void _handleExitConfirmation() {
    final isCompleted = _alreadyCompleted.value;
    final isPractice = _isPracticeMode.value;

    if ((isCompleted && !isPractice) || _hasError.value || _isAnswered.value || _currentPuzzle.value == null) {
      context.pop();
      return;
    }

    GameDialogHelper.showExitConfirmation(
      context,
      onQuit: () => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  _hasError.value
                      ? _buildErrorState()
                      : ((isCompleted && !isPractice) || _isAnswered.value)
                          ? _buildCompletedState(streak)
                          : puzzle == null
                              ? const GameShimmerLoading(primaryColor: _kPrimaryColor)
                              : _buildGameContent(streak),

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

  Widget _buildCompletedState(int streak) {
    return Column(
      children: [
        WordMixerTopBar(
          onBackPressed: () => context.pop(),
          streak: streak,
          isPracticeMode: _isPracticeMode.value,
        ),
        Expanded(
          child: WordMixerCompletedView(
            puzzle: _currentPuzzle.value,
            streak: streak,
            onGoBack: () => context.pop(),
            onPracticeMore: _startPracticeMode,
            primaryColor: _kPrimaryColor,
            isPracticeMode: _isPracticeMode.value,
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent(int streak) {
    final puzzle = _currentPuzzle.value!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // ── Sticky/Top Bar ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: WordMixerTopBar(
            onBackPressed: _handleExitConfirmation,
            streak: streak,
            isPracticeMode: _isPracticeMode.value,
          ),
        ),

        // ── Main Game Content ───────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 8.h),

              // 1. Mystery Target Word Card
              WordMixerInfoCard(
                puzzle: puzzle,
                isPracticeMode: _isPracticeMode.value,
                primaryColor: _kPrimaryColor,
              ),

              SizedBox(height: 16.h),

              // 2. Collapsible Anti-leak Clue Card with Rewarded Ad / Premium Unlock
              WordMixerHintCard(
                puzzle: puzzle,
                isExpanded: _isHintExpanded,
                primaryColor: _kPrimaryColor,
                hapticService: _hapticService,
                ttsService: di.sl.isRegistered<TtsService>() ? di.sl<TtsService>() : null,
              ),

              SizedBox(height: 20.h),

              // 3. Bespoke Interactive Spelling Board (Submit only, no skip)
              if (!_isAnswered.value)
                WordMixerSpellingCard(
                  key: ValueKey('mixer_${puzzle.id}_$_sessionCounter'),
                  puzzle: puzzle,
                  primaryColor: _kPrimaryColor,
                  onSuccess: _onSuccess,
                  soundService: _soundService,
                  hapticService: _hapticService,
                ),

              SizedBox(height: 32.h),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        WordMixerTopBar(
          onBackPressed: () => context.pop(),
          streak: 0,
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
