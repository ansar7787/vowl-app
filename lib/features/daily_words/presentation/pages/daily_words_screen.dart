import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/translation_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/core/utils/widgets/translation_download_sheet.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';
import 'package:vowl/features/daily_words/presentation/widgets/daily_words_widgets.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';

class DailyWordsScreen extends StatefulWidget {
  const DailyWordsScreen({super.key});

  @override
  State<DailyWordsScreen> createState() => _DailyWordsScreenState();
}

class _DailyWordsScreenState extends State<DailyWordsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _slideController;
  late final Animation<double> _flipAnimation;
  late final Animation<Offset> _slideAnimation;

  final HapticService _haptics = di.sl<HapticService>();
  final SoundService _sound = di.sl<SoundService>();
  final TtsService _tts = di.sl<TtsService>();
  final TranslationService _translationService = di.sl<TranslationService>();

  final ValueNotifier<bool> _isFlipped = ValueNotifier(false);
  final ValueNotifier<bool> _isAnimating = ValueNotifier(false);

  // Session Access State
  final ValueNotifier<bool> _hasUnlockedFullSession = ValueNotifier(false);

  // Translation Session State
  final ValueNotifier<bool> _translationUnlocked = ValueNotifier(false);
  final ValueNotifier<bool> _isTranslating = ValueNotifier(false);
  final ValueNotifier<String?> _translatedWord = ValueNotifier(null);
  final ValueNotifier<String?> _translatedDefinition = ValueNotifier(null);
  final ValueNotifier<String?> _translatedExample = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic),
        );

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    _translationUnlocked.value = isPremium;
    _hasUnlockedFullSession.value = isPremium;

    context.read<DailyWordsBloc>().add(
      DailyWordsLoadRequested(isPremium: isPremium),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    _isFlipped.dispose();
    _isAnimating.dispose();
    _hasUnlockedFullSession.dispose();
    _translationUnlocked.dispose();
    _isTranslating.dispose();
    _translatedWord.dispose();
    _translatedDefinition.dispose();
    _translatedExample.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isAnimating.value) return;
    _haptics.light();
    _isFlipped.value = !_isFlipped.value;
    if (_isFlipped.value) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Future<bool> _showHalfwayMonetizationGate() async {
    final completer = Completer<bool>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 56.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr(
                    'daily_words.halfway_title',
                    fallback: 'You\'re on fire!',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    context.tr(
                      'daily_words.halfway_desc',
                      fallback:
                          'Unlock the final 5 words with a quick ad, or go Premium for an ad-free experience.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                // Watch Ad Button (Primary)
                Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () {
                        // FIX: Do NOT pop the modal immediately!
                        // Popping it triggers the bottom sheet's .then() callback which prematurely completes the
                        // future with `false`, breaking the Zeigarnik gate flow.
                        // We must wait for the ad to finish before popping.
                        final adService = di.sl<AdService>();
                        adService.showRewardedAd(
                          context: context,
                          isPremium: false,
                          childSafe: false,
                          onUserEarnedReward: (_) {
                            if (!completer.isCompleted) {
                              completer.complete(true);
                            }
                          },
                          onDismissed: () {
                            if (!completer.isCompleted) {
                              completer.complete(false);
                            }
                            if (context.mounted) {
                              // Only close the bottom sheet after the ad is completely dismissed
                              context.pop();
                            }
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            context.tr(
                              'daily_words.watch_ad',
                              fallback: 'Watch Ad to Unlock',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Go Premium Button (Secondary)
                Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () {
                        context.pop();
                        context.push('/premium');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            context.tr(
                              'daily_words.go_premium',
                              fallback: 'Unlock Premium',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Dismiss Ghost Button
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white54
                        : const Color(0xFF94A3B8),
                  ),
                  child: Text(
                    context.tr(
                      'daily_words.maybe_later',
                      fallback: 'Maybe Later',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  Future<void> _markLearnedAndNext(DailyWord word) async {
    if (_isAnimating.value) return;
    final state = context.read<DailyWordsBloc>().state;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    // GATING LOGIC: If they are on the 5th word (index 4) and haven't unlocked the rest
    if (!isPremium &&
        state.currentIndex == 4 &&
        !_hasUnlockedFullSession.value) {
      final unlocked = await _showHalfwayMonetizationGate();
      if (!unlocked) return; // User chose not to watch ad, stay on word 5

      _hasUnlockedFullSession.value = true;
    }

    _isAnimating.value = true;
    _haptics.success();
    _sound.playCorrect();

    if (!mounted) return;
    context.read<DailyWordsBloc>().add(DailyWordMarkedLearned(word));

    await _slideController.forward();
    if (!mounted) return;

    _slideController.reset();
    _flipController.reset();
    _isFlipped.value = false;
    _isAnimating.value = false;
    _translationUnlocked.value = isPremium;
    // Reset translations for the new card
    _translatedWord.value = null;
    _translatedDefinition.value = null;
    _translatedExample.value = null;

    context.read<DailyWordsBloc>().add(const DailyWordNextRequested());
  }

  void _speakWord(String word) {
    _tts.speak(word);
    _haptics.selection();
  }

  Future<void> _handleTranslate(DailyWord word) async {
    if (_isTranslating.value) return;

    if (_translationUnlocked.value) {
      _isTranslating.value = true;
      await _performTranslation(word);
      if (mounted) _isTranslating.value = false;
      return;
    }

    _isTranslating.value = true;

    try {
      // 1. Check if language is configured
      final isConfigured = await _translationService.isLanguageConfigured();
      if (!isConfigured) {
        if (!mounted) return;
        await LanguageSelectionBottomSheet.show(context);

        // Check again if they configured it
        final recheck = await _translationService.isLanguageConfigured();
        if (!recheck) {
          _isTranslating.value = false;
          return;
        }
      }

      // 2. Check if model is downloaded
      final isDownloaded = await _translationService.isTargetModelDownloaded();

      // 3. Monetization gate
      if (!mounted) return;
      await TranslationMonetizationController.attemptTranslation(
        context,
        isKidsZone: false,
        onSuccess: () async {
          if (!isDownloaded && mounted) {
            await TranslationDownloadSheet.show(
              context,
              _translationService.ensureModelDownloaded(),
            );
          }
          await _performTranslation(word);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'translation.error',
                fallback:
                    'Translation failed. Please check internet connection.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        _isTranslating.value = false;
      }
    }
  }

  Future<void> _performTranslation(DailyWord word) async {
    try {
      final tWord = await _translationService.translate(word.word);
      final tDef = await _translationService.translate(word.definition);
      final tEx = await _translationService.translate(word.example);

      if (mounted) {
        _translatedWord.value = tWord;
        _translatedDefinition.value = tDef;
        _translatedExample.value = tEx;
        _translationUnlocked.value = true;
        _haptics.success();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'translation.downloading',
                fallback: 'Translation model downloading... Please wait.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          BlocBuilder<DailyWordsBloc, DailyWordsState>(
            builder: (context, state) {
              if (state.status == DailyWordsStatus.loading) {
                return _buildShimmerLoading(isDark);
              }
              if (state.status == DailyWordsStatus.error) {
                return SafeArea(
                  child: DailyWordsErrorView(message: state.errorMessage ?? ''),
                );
              }
              if (state.status == DailyWordsStatus.sessionComplete) {
                return SafeArea(
                  child: SessionCompleteView(
                    streak:
                        context.watch<AuthBloc>().state.user?.currentStreak ??
                        0,
                    totalLearned: state.totalWordsLearned,
                    day: state.currentDay,
                  ),
                );
              }
              final word = state.currentWord;
              if (word == null) {
                return _buildShimmerLoading(isDark);
              }
              return _buildContent(context, state, word, isDark);
            },
          ),
          BlocBuilder<DailyWordsBloc, DailyWordsState>(
            builder: (context, state) {
              if (state.status == DailyWordsStatus.sessionComplete) {
                return const IgnorePointer(child: GameConfetti());
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.white24 : Colors.grey[100]!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 40.h,
                width: 200.w,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DailyWordsState state,
    DailyWord word,
    bool isDark,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _isFlipped,
        _isTranslating,
        _translatedWord,
        _translatedDefinition,
        _translatedExample,
      ]),
      builder: (context, _) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        di.sl<HapticService>().light();
                        context.pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20.r,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'home.level_label_short',
                              args: [state.currentDay.toString()],
                              fallback: 'Lesson ${state.currentDay}',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (state.wordSet != null)
                            AutoSizeText(
                              state.wordSet!.theme,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6366F1),
                              ),
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final streak =
                            context
                                .watch<AuthBloc>()
                                .state
                                .user
                                ?.currentStreak ??
                            0;
                        if (streak == 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$streak',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: _DailyWordsProgressBar(
                  progress: state.totalWords > 0
                      ? (state.currentIndex + 1) / state.totalWords
                      : 0,
                  currentIndex: state.currentIndex + 1,
                  totalWords: state.totalWords,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GestureDetector(
                      onTap: _toggleFlip,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * 3.14159;
                          final showBack = _flipAnimation.value > 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: showBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..rotateY(3.14159),
                                    child: WordCardBack(
                                      word: word,
                                      isDark: isDark,
                                      onSpeak: () => _speakWord(word.word),
                                      onTranslate: () => _handleTranslate(word),
                                      isTranslating: _isTranslating.value,
                                      translatedDefinition:
                                          _translatedDefinition.value,
                                      translatedExample:
                                          _translatedExample.value,
                                    ),
                                  )
                                : WordCardFront(
                                    word: word,
                                    isDark: isDark,
                                    onSpeak: () => _speakWord(word.word),
                                    onTranslate: () => _handleTranslate(word),
                                    isTranslating: _isTranslating.value,
                                    translatedWord: _translatedWord.value,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.95,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: !_isFlipped.value
                      ? ActionButton(
                          key: const ValueKey('flip_btn'),
                          label: context.tr(
                            'daily_words.show_definition',
                            fallback: 'Show Definition',
                          ),
                          icon: Icons.visibility_rounded,
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                          onTap: _toggleFlip,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ActionButton(
                                label: context.tr(
                                  'daily_words.pronounce',
                                  fallback: 'Pronounce',
                                ),
                                icon: Icons.volume_up_rounded,
                                color: const Color(0xFF6366F1),
                                isDark: isDark,
                                onTap: () => _speakWord(word.word),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ActionButton(
                                key: const ValueKey('learned_btn'),
                                label: context.tr(
                                  'daily_words.learned',
                                  fallback: 'Got it! Next Word',
                                ),
                                icon: Icons.verified_rounded,
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                onTap: () => _markLearnedAndNext(word),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyWordsProgressBar extends StatelessWidget {
  final double progress;
  final int currentIndex;
  final int totalWords;

  const _DailyWordsProgressBar({
    required this.progress,
    required this.currentIndex,
    required this.totalWords,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8.h,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '$currentIndex / $totalWords',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
