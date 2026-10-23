import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/translation_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/core/utils/widgets/translation_download_sheet.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';
import 'package:vowl/features/daily_words/presentation/widgets/daily_words_widgets.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Daily vocabulary flashcard screen that guides learners through curated daily words,
/// audio pronunciation, native translations, and spaced-repetition mastery tracking.
class DailyWordsScreen extends StatefulWidget {
  const DailyWordsScreen({super.key});

  @override
  State<DailyWordsScreen> createState() => _DailyWordsScreenState();
}

class _DailyWordsScreenState extends State<DailyWordsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _slideController;
  late final AnimationController _entranceController;
  late final Animation<double> _flipAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<Offset> _entranceAnimation;
  late Tween<Offset> _slideTween;

  final HapticService _haptics = di.sl<HapticService>();
  final SoundService _sound = di.sl<SoundService>();
  final TtsService _tts = di.sl<TtsService>();
  final TranslationService _translationService = di.sl<TranslationService>();

  final ValueNotifier<bool> _isFlipped = ValueNotifier(false);
  final ValueNotifier<bool> _isAnimating = ValueNotifier(false);
  final ValueNotifier<bool> _showFlipHint = ValueNotifier(true);
  final ValueNotifier<bool> _pendingTyping = ValueNotifier(false);
  final ScrollController _cardScrollController = ScrollController();

  // Progressive Monetization Gating: Words 1-5 free (index 0-4).
  // Gate 1 (Word 5 finish) unlocks words 6 & 7 (up to index 6).
  // Gate 2 (Word 7 finish) unlocks words 8 & 9 (up to index 8).
  // Gate 3 (Word 9 finish) unlocks word 10 (index 9).
  final ValueNotifier<int> _unlockedUpToIndex = ValueNotifier(4);

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
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutQuad),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _slideTween = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0));
    _slideAnimation = _slideTween.animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInQuad),
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _entranceAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuad,
          ),
        );
    _entranceController.value = 1.0; // Start at final position

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    _translationUnlocked.value = isPremium;
    final isTodayDone = di.sl<DailyWordsService>().isTodayCompleted;
    final blocState = context.read<DailyWordsBloc>().state;
    if (isPremium ||
        isTodayDone ||
        blocState.isSessionDone ||
        blocState.currentIndex >= 9) {
      _unlockedUpToIndex.value = 9;
    } else if (blocState.currentIndex >= 7) {
      _unlockedUpToIndex.value = 8;
    } else if (blocState.currentIndex >= 5) {
      _unlockedUpToIndex.value = 6;
    } else {
      _unlockedUpToIndex.value = 4;
    }

    context.read<DailyWordsBloc>().add(
      DailyWordsLoadRequested(isPremium: isPremium),
    );

    // Audio Pre-caching: Warm up TTS voice engine for instantaneous pronunciation
    unawaited(_tts.reloadVoice());
  }

  @override
  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
    _flipController.dispose();
    _slideController.dispose();
    _entranceController.dispose();
    _isFlipped.dispose();
    _isAnimating.dispose();
    _showFlipHint.dispose();
    _pendingTyping.dispose();
    _cardScrollController.dispose();
    _unlockedUpToIndex.dispose();
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
    _showFlipHint.value = false;
    _pendingTyping.value = false;
    _isFlipped.value = !_isFlipped.value;
    if (_isFlipped.value) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Future<bool> _showMonetizationGate({required int gateStep}) async {
    final completer = Completer<bool>();

    final String title;
    final String desc;
    final String buttonText;
    final String progressText;
    final IconData icon;
    final Color accentColor;

    switch (gateStep) {
      case 1:
        title = context.tr(
          'daily_words.gate1_title',
          fallback: 'Halfway There!',
        );
        desc = context.tr(
          'daily_words.gate1_desc',
          fallback:
              'You completed 5 words! Watch a short ad to unlock words 6 and 7, or upgrade to Premium for ad-free learning.',
        );
        buttonText = context.tr(
          'daily_words.gate1_btn',
          fallback: 'Watch Ad · Unlock Words 6 & 7',
        );
        progressText = '5 / 10 Words Complete · 50%';
        icon = Icons.local_fire_department_rounded;
        accentColor = AppColors.amber500;
        break;
      case 2:
        title = context.tr(
          'daily_words.gate2_title',
          fallback: 'Keep Going!',
        );
        desc = context.tr(
          'daily_words.gate2_desc',
          fallback:
              'You mastered 7 words today! Watch a short ad to unlock words 8 and 9, or upgrade to Premium for ad-free learning.',
        );
        buttonText = context.tr(
          'daily_words.gate2_btn',
          fallback: 'Watch Ad · Unlock Words 8 & 9',
        );
        progressText = '7 / 10 Words Complete · 70%';
        icon = Icons.trending_up_rounded;
        accentColor = AppColors.indigo500;
        break;
      case 3:
      default:
        title = context.tr(
          'daily_words.gate3_title',
          fallback: 'Final Word Ahead!',
        );
        desc = context.tr(
          'daily_words.gate3_desc',
          fallback:
              'Only 1 word left to finish today\'s lesson and claim your streak trophy! Watch a short ad to unlock Word 10.',
        );
        buttonText = context.tr(
          'daily_words.gate3_btn',
          fallback: 'Watch Ad · Unlock Final Word',
        );
        progressText = '9 / 10 Words Complete · 90%';
        icon = Icons.emoji_events_rounded;
        accentColor = AppColors.emerald500;
        break;
    }

    bool isAdRequestInProgress = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
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
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 56.r,
                  ),
                ),
                SizedBox(height: 18.h),
                // Progress Pill
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    progressText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white70 : AppColors.slate600,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // Watch Ad Button (Primary)
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.violet500],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
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
                        if (isAdRequestInProgress) return;
                        isAdRequestInProgress = true;
                        final adService = di.sl<AdService>();
                        adService.showRewardedAd(
                          context: sheetContext,
                          isPremium: false,
                          childSafe: false,
                          onUserEarnedReward: (_) {
                            if (!completer.isCompleted) {
                              completer.complete(true);
                            }
                          },
                          onDismissed: () {
                            isAdRequestInProgress = false;
                            if (!completer.isCompleted) {
                              completer.complete(false);
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
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
                            size: 22.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            buttonText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                // Go Premium Button (Secondary)
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    color: AppColors.amber500.withValues(alpha: 0.05),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.push('/premium');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.amber500,
                            size: 22.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            context.tr(
                              'daily_words.go_premium',
                              fallback: 'Unlock Premium',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Dismiss Ghost Button
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white54
                        : AppColors.slate400,
                  ),
                  child: Text(
                    context.tr(
                      'daily_words.maybe_later',
                      fallback: 'Maybe Later',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
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

  Future<void> _initiateGotItConfirmation(DailyWord word) async {
    if (_isAnimating.value || _pendingTyping.value) return;

    _haptics.selection();
    _pendingTyping.value = true;

    // Auto-scroll immediately to bottom to show the TypeToConfirmOverlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cardScrollController.hasClients) {
        _cardScrollController.animateTo(
          _cardScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _executeGotIt(DailyWord word, {bool mastered = false}) async {
    if (_isAnimating.value) return;
    _pendingTyping.value = false;
    final state = context.read<DailyWordsBloc>().state;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    // PROGRESSIVE MONETIZATION GATING: 5th, 7th, and 9th word gates for free users
    if (!isPremium) {
      if (state.currentIndex == 4 && _unlockedUpToIndex.value < 6) {
        final unlocked = await _showMonetizationGate(gateStep: 1);
        if (!unlocked) return; // Stay on word 5
        _unlockedUpToIndex.value = 6;
      } else if (state.currentIndex == 6 && _unlockedUpToIndex.value < 8) {
        final unlocked = await _showMonetizationGate(gateStep: 2);
        if (!unlocked) return; // Stay on word 7
        _unlockedUpToIndex.value = 8;
      } else if (state.currentIndex == 8 && _unlockedUpToIndex.value < 9) {
        final unlocked = await _showMonetizationGate(gateStep: 3);
        if (!unlocked) return; // Stay on word 9
        _unlockedUpToIndex.value = 9;
      }
    }

    _isAnimating.value = true;
    _haptics.success();
    _sound.playCorrect();

    if (!mounted) return;
    final service = di.sl<DailyWordsService>();
    if (service.isWordLearned(word.id)) {
      context.read<DailyWordsBloc>().add(
        DailyWordReviewed(
          wordId: word.id,
          correct: true,
          promoteToMastered: mastered,
        ),
      );
    } else {
      context.read<DailyWordsBloc>().add(
        DailyWordMarkedLearned(word, mastered: mastered),
      );
    }

    _slideTween.end = const Offset(1.5, 0);
    await _slideController.forward();
    if (!mounted) return;

    if (_cardScrollController.hasClients) {
      _cardScrollController.jumpTo(0);
    }
    _slideController.reset();
    _flipController.reset();
    _isFlipped.value = false;
    _isAnimating.value = false;
    _showFlipHint.value = true;
    _translationUnlocked.value = isPremium;
    // Reset translations for the new card
    _translatedWord.value = null;
    _translatedDefinition.value = null;
    _translatedExample.value = null;

    context.read<DailyWordsBloc>().add(const DailyWordNextRequested());

    // Entrance animation for new card only if session is not finished
    if (!context.read<DailyWordsBloc>().state.isSessionDone) {
      _entranceController.value = 0.0;
      _entranceController.forward();
    }
  }

  Future<void> _markNeedsReviewAndNext(DailyWord word) async {
    if (_isAnimating.value) return;
    _pendingTyping.value = false;
    final state = context.read<DailyWordsBloc>().state;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    // PROGRESSIVE MONETIZATION GATING: 5th, 7th, and 9th word gates for free users
    if (!isPremium) {
      if (state.currentIndex == 4 && _unlockedUpToIndex.value < 6) {
        final unlocked = await _showMonetizationGate(gateStep: 1);
        if (!unlocked) return;
        _unlockedUpToIndex.value = 6;
      } else if (state.currentIndex == 6 && _unlockedUpToIndex.value < 8) {
        final unlocked = await _showMonetizationGate(gateStep: 2);
        if (!unlocked) return;
        _unlockedUpToIndex.value = 8;
      } else if (state.currentIndex == 8 && _unlockedUpToIndex.value < 9) {
        final unlocked = await _showMonetizationGate(gateStep: 3);
        if (!unlocked) return;
        _unlockedUpToIndex.value = 9;
      }
    }

    _isAnimating.value = true;
    _haptics.light();

    // Mark as needs review (Box 0) or record incorrect review
    if (!mounted) return;
    final service = di.sl<DailyWordsService>();
    if (service.isWordLearned(word.id)) {
      context.read<DailyWordsBloc>().add(
        DailyWordReviewed(wordId: word.id, correct: false),
      );
    } else {
      context.read<DailyWordsBloc>().add(DailyWordMarkedReviewLater(word));
    }

    _slideTween.end = const Offset(-1.5, 0); // Slide left for review later
    await _slideController.forward();
    if (!mounted) return;

    if (_cardScrollController.hasClients) {
      _cardScrollController.jumpTo(0);
    }
    _slideController.reset();
    _flipController.reset();
    _isFlipped.value = false;
    _isAnimating.value = false;
    _showFlipHint.value = true;
    _translationUnlocked.value = isPremium;
    _translatedWord.value = null;
    _translatedDefinition.value = null;
    _translatedExample.value = null;

    context.read<DailyWordsBloc>().add(const DailyWordNextRequested());

    // Entrance animation for new card only if session is not finished
    if (!context.read<DailyWordsBloc>().state.isSessionDone) {
      _entranceController.value = 0.0;
      _entranceController.forward();
    }
  }

  Future<void> _navigatePrevious() async {
    if (_isAnimating.value) return;
    _pendingTyping.value = false;
    final bloc = context.read<DailyWordsBloc>();
    if (!bloc.state.canGoPrevious) return;

    _isAnimating.value = true;
    _haptics.selection();

    _slideTween.end = const Offset(1.5, 0);
    await _slideController.forward();
    if (!mounted) return;

    if (_cardScrollController.hasClients) {
      _cardScrollController.jumpTo(0);
    }
    _slideController.reset();
    _flipController.reset();
    _isFlipped.value = false;
    _isAnimating.value = false;
    _showFlipHint.value = true;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    _translationUnlocked.value = isPremium;
    _translatedWord.value = null;
    _translatedDefinition.value = null;
    _translatedExample.value = null;

    bloc.add(const DailyWordPreviousRequested());

    _entranceController.value = 0.0;
    _entranceController.forward();
  }

  void _speakWord(String text, {double? rate}) {
    unawaited(_tts.stop());
    _tts.speak(text, rate: rate);
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
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'translation.error',
            fallback: 'Translation failed. Please check internet connection.',
          ),
          type: CustomSnackBarType.error,
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
                fallback: 'Downloading language model... Please wait.',
              ),
            ),
          ),
        );
      }
    }
  }

  void _confirmExitSession(DailyWordsState state) {
    GameDialogHelper.showExitConfirmation(
      context,
      title: context.tr('games.pause_title', fallback: 'Pause Lesson?'),
      description: context.tr(
        'games.pause_desc',
        args: [
          (state.currentIndex + 1).toString(),
          state.totalWords.toString(),
        ],
        fallback:
            'You are on word ${state.currentIndex + 1} of ${state.totalWords}. Leaving now will pause your progress.',
      ),
      onQuit: () {
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<DailyWordsBloc, DailyWordsState>(
      listenWhen: (prev, current) =>
          prev.status != current.status ||
          prev.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.status == DailyWordsStatus.sessionComplete) {
          _unlockedUpToIndex.value = 9;
          _sound.playLevelComplete();
        } else if (state.currentIndex >= 9) {
          if (_unlockedUpToIndex.value < 9) _unlockedUpToIndex.value = 9;
        } else if (state.currentIndex >= 7) {
          if (_unlockedUpToIndex.value < 8) _unlockedUpToIndex.value = 8;
        } else if (state.currentIndex >= 5) {
          if (_unlockedUpToIndex.value < 6) _unlockedUpToIndex.value = 6;
        }
      },
      builder: (context, state) {
        final canDirectPop =
            (state.isSessionDone || state.currentIndex == 0) &&
            !_pendingTyping.value;
        return PopScope(
          canPop: canDirectPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_pendingTyping.value) {
              _pendingTyping.value = false;
              return;
            }
            _confirmExitSession(state);
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: isDark ? AppColors.slate900 : Colors.white,
            body: Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                if (state.status == DailyWordsStatus.loading)
                  _buildShimmerLoading(isDark)
                else if (state.status == DailyWordsStatus.error)
                  SafeArea(
                    child: DailyWordsErrorView(
                      message: state.errorMessage ?? '',
                    ),
                  )
                else if (state.status == DailyWordsStatus.sessionComplete)
                  SafeArea(
                    child: Builder(
                      builder: (context) {
                        final authUser = context.watch<AuthBloc>().state.user;
                        final streakVal = authUser != null && authUser.currentStreak > 0
                            ? authUser.currentStreak
                            : state.streak;
                        final wordsCount = state.learnedThisSession.isNotEmpty
                            ? state.learnedThisSession.length
                            : (state.wordSet?.words.length ?? 10);
                        return SessionCompleteView(
                          streak: streakVal,
                          totalLearned: state.totalWordsLearned,
                          day: state.currentDay,
                          wordsThisSession: wordsCount,
                          wordsForReview: state.reviewedThisSession.length,
                          isPremium: authUser?.isPremium ?? false,
                          onReviewAgain: () {
                            _unlockedUpToIndex.value = 9;
                            context
                                .read<DailyWordsBloc>()
                                .add(const DailySessionRestartRequested());
                          },
                          onWordsTodayTap: () =>
                              context.push('/word-bank?filter=today'),
                          onTotalWordsTap: () =>
                              context.push('/word-bank?filter=all'),
                          onStreakTap: () =>
                              context.push(AppRouter.streakRoute),
                        );
                      },
                    ),
                  )
                else if (state.currentWord != null)
                  _buildContent(context, state, state.currentWord!, isDark)
                else
                  _buildShimmerLoading(isDark),
                if (state.status == DailyWordsStatus.sessionComplete)
                  const IgnorePointer(child: GameConfetti()),
              ],
            ),
          ),
        );
      },
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
        _showFlipHint,
      ]),
      builder: (context, _) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Back',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          di.sl<HapticService>().light();
                          if (_pendingTyping.value) {
                            _pendingTyping.value = false;
                            return;
                          }
                          if (state.isSessionDone || state.currentIndex == 0) {
                            context.pop();
                          } else {
                            _confirmExitSession(state);
                          }
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
                    ),
                    if (state.canGoPrevious) ...[
                      SizedBox(width: 8.w),
                      Semantics(
                        label: 'Previous Word',
                        button: true,
                        child: GestureDetector(
                          onTap: _navigatePrevious,
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.skip_previous_rounded,
                              size: 20.r,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.cycle > 1
                                ? 'Cycle ${state.cycle} · Lesson ${state.effectiveDay}'
                                : context.tr(
                                    'home.level_label_short',
                                    args: [state.currentDay.toString()],
                                    fallback: 'Lesson ${state.currentDay}',
                                  ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          if (state.wordSet != null)
                            AutoSizeText(
                              state.wordSet!.theme,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.indigo500,
                              ),
                              maxLines: 2,
                              minFontSize: 10,
                            ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final authUser = context.watch<AuthBloc>().state.user;
                        final streak = state.streak > 0
                            ? state.streak
                            : (authUser?.currentStreak ?? 0);
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
                                color: AppColors.amber500,
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$streak',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber500,
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
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SlideTransition(
                      position: _entranceAnimation,
                      child: GestureDetector(
                        onTap: _pendingTyping.value ? null : _toggleFlip,
                        onHorizontalDragEnd:
                            (_pendingTyping.value || _isAnimating.value)
                                ? null
                                : (details) {
                                    final velocity =
                                        details.primaryVelocity ?? 0.0;
                                    if (!_isFlipped.value) {
                                      // Loophole protection: Card must be flipped first to see the definition.
                                      // Swiping while front is visible flips the card so the learner sees the definition!
                                      if (velocity.abs() > 300) {
                                        _toggleFlip();
                                      }
                                      return;
                                    }
                                    if (velocity < -300) {
                                      // Swiped left -> Review Later
                                      _markNeedsReviewAndNext(word);
                                    } else if (velocity > 300) {
                                      // Swiped right -> Got it! triggers type-to-confirm game mechanism
                                      _initiateGotItConfirmation(word);
                                    }
                                  },
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _flipAnimation,
                            _pendingTyping,
                          ]),
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
                                        onSpeakExample: () =>
                                            _speakWord(word.example),
                                        onTranslate: () =>
                                            _handleTranslate(word),
                                        isTranslating: _isTranslating.value,
                                        translatedDefinition:
                                            _translatedDefinition.value,
                                        translatedExample:
                                            _translatedExample.value,
                                        showTypeToConfirm: _pendingTyping.value,
                                        scrollController: _cardScrollController,
                                        onTypingConfirmed: () =>
                                            _executeGotIt(word, mastered: true),
                                        onTypingSkipped: () =>
                                            _executeGotIt(word, mastered: false),
                                      ),
                                    )
                                  : WordCardFront(
                                      word: word,
                                      isDark: isDark,
                                      onSpeak: () => _speakWord(word.word),
                                      onSpeakSlow: () => _speakWord(word.word, rate: 0.28),
                                      onTranslate: () => _handleTranslate(word),
                                      isTranslating: _isTranslating.value,
                                      translatedWord: _translatedWord.value,
                                      difficulty: word.difficulty,
                                      theme: state.wordSet?.theme,
                                      showFlipHint: _showFlipHint.value,
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _pendingTyping,
                  builder: (context, isPendingTyping, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutQuad,
                      switchOutCurve: Curves.easeInQuad,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
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
                              color: AppColors.indigo500,
                              isDark: isDark,
                              onTap: _toggleFlip,
                            )
                          : isPendingTyping
                              ? const SizedBox.shrink(
                                  key: ValueKey('typing_active'),
                                )
                              : Row(
                                  key: const ValueKey('actions_row'),
                                  children: [
                                    Expanded(
                                      child: ActionButton(
                                        key: const ValueKey('skip_btn'),
                                        label: context.tr(
                                          'daily_words.skip',
                                          fallback: 'Review Later',
                                        ),
                                        icon: Icons.replay_rounded,
                                        color: AppColors.amber500,
                                        isDark: isDark,
                                        onTap: () =>
                                            _markNeedsReviewAndNext(word),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: ActionButton(
                                        key: const ValueKey('learned_btn'),
                                        label: context.tr(
                                          'daily_words.learned',
                                          fallback: 'Got it!',
                                        ),
                                        icon: Icons.verified_rounded,
                                        color: AppColors.emerald500,
                                        isDark: isDark,
                                        onTap: () =>
                                            _initiateGotItConfirmation(word),
                                      ),
                                    ),
                                  ],
                                ),
                    );
                  },
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    : AppColors.slate200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.indigo500),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '$currentIndex / $totalWords',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
