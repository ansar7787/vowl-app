import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_anagram_wrapper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Word Mixer Screen — Daily Challenge (10/10 Production Rewrite)
//
// Architecture:
//   ┌─────────────────────────────────────────┐
//   │  Top Bar (Back • Title • Streak Badge)  │
//   ├─────────────────────────────────────────┤
//   │  Word Info Card (length + difficulty)   │
//   ├─────────────────────────────────────────┤
//   │  Collapsible Hint Card (💡)             │
//   ├─────────────────────────────────────────┤
//   │  DynamicAnagramWrapper (INLINE)         │
//   │  (isPositioned: false — no overlay)     │
//   └─────────────────────────────────────────┘
//
// Key decisions:
//   • Hint is collapsible but ALWAYS accessible during gameplay.
//   • Anagram panel is inline (not Positioned overlay) — no content occlusion.
//   • Uses Theme.of(context) for all surface colors — no hardcoded values.
//   • Daily completion persisted via SharedPreferences (date-stamped key).
//   • bonusCoins: 0 on wrapper — single reward path via _grantRewards only.
//   • Streak read from AuthBloc's user.currentStreak.
// ═══════════════════════════════════════════════════════════════════════════════

/// Persistence key prefix for daily challenge completion tracking.
const _kCompletionKeyPrefix = 'word_mixer_completed_';

/// The fixed brand colour for this game screen.
const _kPrimaryColor = Color(0xFFA855F7);

class WordMixerScreen extends StatefulWidget {
  const WordMixerScreen({super.key});

  @override
  State<WordMixerScreen> createState() => _WordMixerScreenState();
}

class _WordMixerScreenState extends State<WordMixerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Map<String, dynamic>?> _currentPuzzle = ValueNotifier(
    null,
  );
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool> _isHintExpanded = ValueNotifier(false);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _alreadyCompleted = ValueNotifier(false);

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
    super.dispose();
  }

  String get _todayKey =>
      _kCompletionKeyPrefix + DateTime.now().toIso8601String().split('T')[0];

  Future<void> _loadDailyPuzzle() async {
    try {
      // Check if already completed today
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_todayKey) == true) {
        if (mounted) {
          _alreadyCompleted.value = true;
          // Still load the puzzle so we can show what they solved
          final puzzle = await DailyChallengeService.getTodayWordMixer();
          _currentPuzzle.value = puzzle;
        }
        return;
      }

      final puzzle = await DailyChallengeService.getTodayWordMixer();
      if (mounted) {
        if (puzzle == null) {
          _hasError.value = true;
        } else {
          _currentPuzzle.value = puzzle;
        }
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
    _hapticService.success();
    _soundService.playCorrect();
    _isAnswered.value = true;
    _markCompleted();

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (!isPremium) {
      final adService = di.sl<AdService>();
      adService.recordLevelCompletion();
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () {
          if (mounted) _grantRewards();
        },
      );
    } else {
      _grantRewards();
    }
  }

  void _onBypassed() {
    _isAnswered.value = true;
    _markCompleted();

    GameDialogHelper.showCompletion(
      context,
      xp: 10,
      coins: 0,
      title: context.tr(
        'home.challenge_bypassed',
        fallback: 'CHALLENGE BYPASSED',
      ),
      description: context.tr(
        'home.challenge_bypassed_desc',
        fallback: 'You bypassed today\'s challenge.',
      ),
      enableDoubleUp: false,
    );
  }

  void _grantRewards() {
    // Single reward path — the ONLY place coins are credited.
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

  void _onFail() {
    _hapticService.error();
    _soundService.playWrong();
  }

  int _getWordLength() {
    final word = _currentPuzzle.value?['word'] as String?;
    if (word == null) return 0;
    return word.replaceAll(' ', '').length;
  }

  String _getDifficultyLabel() {
    final length = _getWordLength();
    if (length <= 4) return 'Easy';
    if (length <= 6) return 'Medium';
    if (length <= 8) return 'Hard';
    return 'Expert';
  }

  Color _getDifficultyColor() {
    final length = _getWordLength();
    if (length <= 4) return const Color(0xFF10B981); // Emerald
    if (length <= 6) return const Color(0xFFF59E0B); // Amber
    if (length <= 8) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _currentPuzzle,
        _isAnswered,
        _hasError,
        _alreadyCompleted,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: _hasError.value
                ? _buildErrorState(isDark)
                : _alreadyCompleted.value
                ? _buildCompletedState(isDark)
                : _currentPuzzle.value == null
                ? GameShimmerLoading(primaryColor: _kPrimaryColor)
                : _buildGameContent(isDark),
          ),
        );
      },
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    final user = context.watch<AuthBloc>().state.user;
    final streak = user?.currentStreak ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        children: [
          // Back button — clear, accessible, standard placement
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 24.r,
            ),
            tooltip: context.tr('common.back', fallback: 'Back'),
          ),

          // Title — centered via Expanded
          Expanded(
            child: Text(
              context.tr('home.word_mixer', fallback: 'Word Mixer'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Streak badge
          if (streak > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 4.w),
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(width: 48.w), // Balance spacing when no streak
        ],
      ),
    );
  }

  // ─── Word Info Card ──────────────────────────────────────────────────

  Widget _buildWordInfoCard(bool isDark) {
    final wordLength = _getWordLength();
    final difficulty = _getDifficultyLabel();
    final diffColor = _getDifficultyColor();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _kPrimaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _kPrimaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: _kPrimaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.sort_by_alpha_rounded,
              color: _kPrimaryColor,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),

          // Daily Challenge label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'home.daily_challenge',
                    fallback: 'DAILY CHALLENGE',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: _kPrimaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.tr(
                    'home.unscramble_word',
                    fallback: 'Unscramble the letters to form the word',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Difficulty + length pills
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Difficulty pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: diffColor.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: diffColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              // Length pill
              Text(
                '$wordLength ${context.tr('home.letters', fallback: 'letters')}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, duration: 400.ms);
  }

  // ─── Collapsible Hint Card ───────────────────────────────────────────

  Widget _buildHintCard(bool isDark) {
    final hint = _currentPuzzle.value?['hint'] as String? ?? '';
    if (hint.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
          valueListenable: _isHintExpanded,
          builder: (context, isExpanded, _) {
            return GestureDetector(
              onTap: () {
                _hapticService.light();
                _isHintExpanded.value = !_isHintExpanded.value;
              },
              child: AnimatedContainer(
                duration: 300.ms,
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _kPrimaryColor.withValues(
                      alpha: isExpanded ? 0.4 : 0.15,
                    ),
                    width: isExpanded ? 1.5 : 1,
                  ),
                  boxShadow: isExpanded
                      ? [
                          BoxShadow(
                            color: _kPrimaryColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — always visible
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text('💡', style: TextStyle(fontSize: 14.sp)),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            isExpanded
                                ? context.tr('home.hint', fallback: 'HINT')
                                : context.tr(
                                    'home.tap_for_hint',
                                    fallback: 'Tap for hint',
                                  ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isExpanded
                                  ? _kPrimaryColor
                                  : (isDark ? Colors.white60 : Colors.black45),
                              letterSpacing: isExpanded ? 1.5 : 0.5,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: 300.ms,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20.r,
                          ),
                        ),
                      ],
                    ),

                    // Hint text — shown when expanded
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: Text(
                          hint,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: 300.ms,
                      sizeCurve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05, duration: 400.ms);
  }

  // ─── Main Game Content ───────────────────────────────────────────────

  Widget _buildGameContent(bool isDark) {
    return Column(
      children: [
        _buildTopBar(isDark),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 8.h),

                // Word info card
                _buildWordInfoCard(isDark),
                SizedBox(height: 16.h),

                // Collapsible hint — always accessible
                _buildHintCard(isDark),
                SizedBox(height: 24.h),

                // Inline anagram game — NOT positioned overlay
                if (!_isAnswered.value)
                  DynamicAnagramWrapper(
                    expectedText: _currentPuzzle.value!['word']!,
                    primaryColor: _kPrimaryColor,
                    onConfirmed: _onSuccess,
                    onBypassed: _onBypassed,
                    onFailed: _onFail,
                    // FIX: bonusCoins set to 0 — single reward path via
                    // _grantRewards only. Eliminates double-coin exploit.
                    bonusCoins: 0,
                    title: context.tr('home.spell_it', fallback: 'SPELL IT!'),
                    subtitle: context.tr(
                      'home.spell_it_subtitle',
                      fallback:
                          'Tap the letters in the correct order to form the word.',
                    ),
                    isPositioned: false,
                    allowSkip: true,
                  ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Column(
      children: [
        _buildTopBar(isDark),
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      context.tr('common.retry', fallback: 'Try Again'),
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

  // ─── Already Completed State ─────────────────────────────────────────

  Widget _buildCompletedState(bool isDark) {
    final user = context.watch<AuthBloc>().state.user;
    final streak = user?.currentStreak ?? 0;
    final word =
        (_currentPuzzle.value?['word'] as String?)?.toUpperCase() ?? '';

    return Column(
      children: [
        _buildTopBar(isDark),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40.r,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    context.tr(
                      'home.already_completed_title',
                      fallback: 'Challenge Complete!',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Show the word they solved
                  if (word.isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _kPrimaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: _kPrimaryColor,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],

                  Text(
                    context.tr(
                      'home.come_back_tomorrow',
                      fallback: 'Come back tomorrow for a new challenge!',
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

                  // Streak card
                  if (streak > 0) ...[
                    SizedBox(height: 32.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            const Color(0xFFEF4444).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 28.sp)),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$streak ${context.tr('home.day_streak', fallback: 'Day Streak')}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                context.tr(
                                  'home.keep_it_going',
                                  fallback: 'Keep it going!',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32.h),

                  // Return button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.tr('common.go_back', fallback: 'Go Back'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
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
