import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class WordCardFront extends StatelessWidget {
  final DailyWord word;
  final bool isDark;
  final VoidCallback onSpeak;
  final VoidCallback onTranslate;
  final bool isTranslating;
  final String? translatedWord;
  final int difficulty;
  final String? theme;
  final bool showFlipHint;

  const WordCardFront({
    super.key,
    required this.word,
    required this.isDark,
    required this.onSpeak,
    required this.onTranslate,
    required this.isTranslating,
    this.translatedWord,
    this.difficulty = 1,
    this.theme,
    this.showFlipHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${word.word}, ${word.partOfSpeech}. Tap card or button to see definition.',
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top badges: POS + Difficulty + Frequency Rank
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        word.partOfSpeech.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _DifficultyBadge(difficulty: difficulty),
                    if (word.frequencyRank > 0)
                      _FrequencyRankBadge(frequencyRank: word.frequencyRank),
                  ],
                ),
                // Theme context tag
                if (theme != null && theme!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      theme!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber500,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                // Word text with 2-line safety (never truncated)
                AutoSizeText(
                  word.word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  minFontSize: 20,
                ),
                if (translatedWord != null) ...[
                  SizedBox(height: 8.h),
                  AutoSizeText(
                    translatedWord!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                    maxLines: 2,
                    minFontSize: 14,
                  ),
                ],
                SizedBox(height: 12.h),
                AutoSizeText(
                  word.phonetic,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.slate500,
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                ),
                SizedBox(height: 28.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TranslateButton(
                      isTranslating: isTranslating,
                      isTranslated: translatedWord != null,
                      onTap: onTranslate,
                    ),
                    SizedBox(width: 16.w),
                    DailyWordsIconButton(
                      icon: Icons.volume_up_rounded,
                      onTap: onSpeak,
                      tooltip: 'Listen to pronunciation',
                    ),
                  ],
                ),
                // Tap to flip hint
                if (showFlipHint) ...[
                  SizedBox(height: 20.h),
                  _FlipHint(isDark: isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WordCardBack extends StatelessWidget {
  final DailyWord word;
  final bool isDark;
  final VoidCallback onSpeak;
  final VoidCallback onTranslate;
  final VoidCallback? onSpeakExample;
  final bool isTranslating;
  final String? translatedDefinition;
  final String? translatedExample;
  final bool showTypeToConfirm;
  final ScrollController? scrollController;
  final VoidCallback? onTypingConfirmed;
  final VoidCallback? onTypingSkipped;

  const WordCardBack({
    super.key,
    required this.word,
    required this.isDark,
    required this.onSpeak,
    required this.onTranslate,
    this.onSpeakExample,
    required this.isTranslating,
    this.translatedDefinition,
    this.translatedExample,
    this.showTypeToConfirm = false,
    this.scrollController,
    this.onTypingConfirmed,
    this.onTypingSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final scrollChild = SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          word.word,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          minFontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _TranslateButton(
                        isTranslating: isTranslating,
                        isTranslated: translatedDefinition != null,
                        onTap: onTranslate,
                      ),
                      SizedBox(width: 8.w),
                      DailyWordsIconButton(
                        icon: Icons.volume_up_rounded,
                        onTap: onSpeak,
                        tooltip: 'Listen to ${word.word}',
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                    height: 1,
                  ),
                  SizedBox(height: 14.h),
                  // Definition section
                  SectionLabel(
                    label: context.tr(
                      'daily_words.definition',
                      fallback: 'Definition',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    word.definition,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : AppColors.slate800,
                      height: 1.55,
                    ),
                  ),
                  if (translatedDefinition != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      translatedDefinition!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.emerald500,
                        height: 1.5,
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  // Example section with TTS button
                  Row(
                    children: [
                      SectionLabel(
                        label: context.tr(
                          'daily_words.example',
                          fallback: 'Example',
                        ),
                      ),
                      const Spacer(),
                      if (onSpeakExample != null)
                        Semantics(
                          button: true,
                          label: 'Listen to example sentence',
                          child: InkWell(
                            onTap: onSpeakExample,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up_rounded,
                                    size: 16.r,
                                    color: AppColors.indigo500,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    context.tr('daily_words.listen', fallback: 'Listen'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.indigo500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${word.example}"',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.slate700,
                            height: 1.55,
                          ),
                        ),
                        if (translatedExample != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            '"${translatedExample!}"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: AppColors.emerald500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showTypeToConfirm) ...[
                    SizedBox(height: 16.h),
                    TypeToConfirmOverlay(
                      expectedText: word.word,
                      displayText: word.word,
                      primaryColor: AppColors.emerald500,
                      isPositioned: false,
                      allowSkip: true,
                      onConfirmed: onTypingConfirmed ?? () {},
                      onSkipped: onTypingSkipped ?? () {},
                    ),
                    SizedBox(
                      height: MediaQuery.viewInsetsOf(context).bottom > 0
                          ? MediaQuery.viewInsetsOf(context).bottom + 40.h
                          : 40.h,
                    ),
                  ] else ...[
                    SizedBox(height: 20.h),
                  ],
                ],
              ),
            ),
          );

    return Semantics(
      label:
          '${word.word} card back: definition and example. Tap card or button to flip back.',
      child: GlassTile(
        padding: EdgeInsets.zero,
        child: scrollController != null
            ? RawScrollbar(
                controller: scrollController,
                thumbColor: isDark ? Colors.white30 : Colors.black26,
                radius: Radius.circular(4.r),
                thickness: 3.w,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 6.h),
                child: scrollChild,
              )
            : scrollChild,
      ),
    );
  }
}

class _TranslateButton extends StatelessWidget {
  final bool isTranslating;
  final bool isTranslated;
  final VoidCallback onTap;

  const _TranslateButton({
    required this.isTranslating,
    required this.isTranslated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isTranslated
          ? 'Translation complete'
          : (isTranslating ? 'Translating word' : 'Translate word'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isTranslated || isTranslating ? null : onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: isTranslated
                  ? AppColors.emerald500
                  : const Color(
                      0xFF10B981,
                    ).withValues(alpha: isTranslating ? 0.05 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald500.withValues(
                  alpha: isTranslated ? 1.0 : (isTranslating ? 0.1 : 0.3),
                ),
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: isTranslating
                    ? PulsingIcon(
                        key: const ValueKey('translating'),
                        icon: Icons.g_translate_rounded,
                        color: AppColors.emerald500,
                      )
                    : Icon(
                        isTranslated
                            ? Icons.check_rounded
                            : Icons.g_translate_rounded,
                        key: ValueKey(isTranslated ? 'check' : 'translate'),
                        color: isTranslated ? Colors.white : AppColors.emerald500,
                        size: 20.r,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const PulsingIcon({super.key, required this.icon, required this.color});

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Icon(widget.icon, color: widget.color, size: 20.r),
    );
  }
}

class DailyWordsIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const DailyWordsIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip ?? 'Action button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: AppColors.indigo500, size: 22.r),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      label,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.slate500,
        letterSpacing: 0.3,
      ),
      maxLines: 1,
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Ink(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24.r),
                SizedBox(width: 8.w),
                Flexible(
                  child: AutoSizeText(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DailyWordsErrorView extends StatelessWidget {
  final String message;

  const DailyWordsErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.r,
              color: AppColors.gameIncorrect,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionCompleteView extends StatelessWidget {
  final int streak;
  final int totalLearned;
  final int day;
  final int wordsThisSession;
  final int wordsForReview;
  final bool isPremium;
  final VoidCallback? onReviewAgain;
  final VoidCallback? onOpenWordBank;
  final VoidCallback? onStreakTap;
  final VoidCallback? onWordsTodayTap;
  final VoidCallback? onTotalWordsTap;

  const SessionCompleteView({
    super.key,
    required this.streak,
    required this.totalLearned,
    required this.day,
    this.wordsThisSession = 10,
    this.wordsForReview = 0,
    this.isPremium = false,
    this.onReviewAgain,
    this.onOpenWordBank,
    this.onStreakTap,
    this.onWordsTodayTap,
    this.onTotalWordsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cycle = ((day - 1) ~/ 750) + 1;
    final effectiveDay = ((day - 1) % 750) + 1;
    final lessonLabel =
        cycle > 1 ? 'Cycle $cycle · Lesson $effectiveDay' : 'Lesson $day';
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              // Trophy icon with glow
              Container(
                padding: EdgeInsets.all(26.r),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 68.r,
                  color: AppColors.emerald500,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                context.tr(
                  'daily_words.session_complete',
                  fallback: 'Lesson Completed!',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr(
                  'daily_words.come_back_tomorrow',
                  args: [lessonLabel],
                  fallback: 'Great job! You finished $lessonLabel.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white70 : AppColors.slate500,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.slate200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald500,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '$wordsThisSession Completed',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald500,
                      ),
                    ),
                    if (wordsForReview > 0) ...[
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.replay_rounded,
                        color: AppColors.amber500,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '$wordsForReview Needs Review',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              NextDayCountdownTimer(isDark: isDark),
              SizedBox(height: 20.h),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '$streak',
                      label: context.tr(
                        'daily_words.streak_label',
                        fallback: 'Day Streak',
                      ),
                      color: AppColors.amber500,
                      isDark: isDark,
                      onTap: onStreakTap ??
                          () => context.push(AppRouter.streakRoute),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.auto_stories_rounded,
                      value: '${wordsThisSession > 0 ? wordsThisSession : 10}',
                      label: context.tr(
                        'daily_words.words_today',
                        fallback: 'Words Today',
                      ),
                      color: AppColors.indigo500,
                      isDark: isDark,
                      onTap: onWordsTodayTap ??
                          () => context.push('/word-bank?filter=today'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.library_books_rounded,
                      value: '$totalLearned',
                      label: context.tr(
                        'daily_words.total_learned',
                        fallback: 'Total Words',
                      ),
                      color: AppColors.emerald500,
                      isDark: isDark,
                      onTap: onTotalWordsTap ??
                          () => context.push('/word-bank?filter=all'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              // Premium upsell for free users
              if (!isPremium) ...[
                GestureDetector(
                  onTap: () => context.push('/premium'),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          AppColors.violet500.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.indigo500,
                            size: 22.r,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'daily_words.premium_cta_title',
                                  fallback: 'Learn Without Ads',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                context.tr(
                                  'daily_words.premium_cta_desc',
                                  fallback:
                                      'Unlock daily 10 words ad-free',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.indigo500,
                          size: 16.r,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
              // Practice again button (if callback provided)
              if (onReviewAgain != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed: onReviewAgain,
                    icon: Icon(Icons.refresh_rounded, size: 20.r),
                    label: Text(
                      context.tr(
                        'daily_words.practice_again',
                        fallback: 'Practice Today\'s Words Again',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.indigo500,
                      side: BorderSide(
                        color: AppColors.indigo500.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Continue button (Primary)
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.tr('common.continue', fallback: 'Continue'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SESSION COMPLETE STAT TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletionStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _CompletionStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22.r),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AutoSizeText(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: 3.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9.r,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: tile,
        ),
      );
    }

    return tile;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIFFICULTY BADGE & FREQUENCY RANK BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (difficulty <= 1) {
      color = AppColors.emerald500;
      label = 'Beginner (A1)';
    } else if (difficulty == 2) {
      color = AppColors.emerald500;
      label = 'Elementary (A2)';
    } else if (difficulty == 3) {
      color = AppColors.amber500;
      label = 'Intermediate (B1)';
    } else if (difficulty == 4) {
      color = AppColors.amber500;
      label = 'Upper-Int (B2)';
    } else if (difficulty == 5) {
      color = AppColors.indigo500;
      label = 'Advanced (C1)';
    } else if (difficulty == 6) {
      color = AppColors.indigo500;
      label = 'Mastery (C2)';
    } else {
      color = AppColors.rose500;
      label = 'Expert (C2+)';
    }
    return Semantics(
      label: 'Difficulty level: $label',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _FrequencyRankBadge extends StatelessWidget {
  final int frequencyRank;
  const _FrequencyRankBadge({required this.frequencyRank});

  @override
  Widget build(BuildContext context) {
    if (frequencyRank <= 0) return const SizedBox.shrink();
    final tier = (frequencyRank / 1000).ceil();
    final formattedRank = (tier * 1000).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final String label = 'Top $formattedRank';
    return Semantics(
      label: 'Frequency rank: $label common words',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.teal400.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.teal400.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.teal400,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLIP HINT
// ═══════════════════════════════════════════════════════════════════════════════

class _FlipHint extends StatefulWidget {
  final bool isDark;
  const _FlipHint({required this.isDark});

  @override
  State<_FlipHint> createState() => _FlipHintState();
}

class _FlipHintState extends State<_FlipHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 16.r,
            color: widget.isDark ? Colors.white38 : AppColors.slate400,
          ),
          SizedBox(width: 6.w),
          Text(
            'Tap card to see definition',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white38 : AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

class NextDayCountdownTimer extends StatefulWidget {
  final bool isDark;
  const NextDayCountdownTimer({super.key, required this.isDark});

  @override
  State<NextDayCountdownTimer> createState() => _NextDayCountdownTimerState();
}

class _NextDayCountdownTimerState extends State<NextDayCountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_updateRemaining);
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _remaining = tomorrow.difference(now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.slate100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.slate200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 16.r,
            color: AppColors.indigo500,
          ),
          SizedBox(width: 8.w),
          Text(
            context.tr('daily_words.next_unlock', fallback: 'Next words unlock in:'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white70 : AppColors.slate600,
            ),
          ),
          Text(
            '$hours:$minutes:$seconds',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.indigo500,
            ),
          ),
        ],
      ),
    );
  }
}

