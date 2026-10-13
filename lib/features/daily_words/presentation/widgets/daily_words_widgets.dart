import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/app_colors.dart';

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
        padding: EdgeInsets.all(20.r),
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
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${word.word} card back: definition and example. Tap card or button to flip back.',
      child: GlassTile(
        padding: EdgeInsets.zero,
        child: RawScrollbar(
          thumbColor: isDark ? Colors.white30 : Colors.black26,
          radius: Radius.circular(8.r),
          thickness: 6.w,
          padding: EdgeInsets.all(6.r),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(22.r),
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
                  SizedBox(height: 16.h),
                  Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                    height: 1,
                  ),
                  SizedBox(height: 20.h),
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
                  SizedBox(height: 22.h),
                  // Example section with TTS button
                  Row(
                    children: [
                      SectionLabel(
                        label: context.tr(
                          'daily_words.example',
                          fallback: 'Example Sentence',
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
                    padding: EdgeInsets.all(14.r),
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
                  SizedBox(height: 36.h),
                ],
              ),
            ),
          ),
        ),
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
            duration: const Duration(milliseconds: 300),
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
                duration: const Duration(milliseconds: 300),
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
                  fallback: 'Lesson Complete!',
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
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.auto_stories_rounded,
                      value: '$wordsThisSession',
                      label: context.tr(
                        'daily_words.words_today',
                        fallback: 'Learned',
                      ),
                      color: AppColors.indigo500,
                      isDark: isDark,
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
                                  fallback: 'Learn Without Limits',
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
                                      'Unlock all 10 words daily, ad-free',
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
              // Word Bank quick link
              if (onOpenWordBank != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed: onOpenWordBank,
                    icon: Icon(Icons.menu_book_rounded, size: 20.r),
                    label: Text(
                      context.tr(
                        'daily_words.view_word_bank',
                        fallback: 'View Word Bank',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : AppColors.slate700,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.slate300,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
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

  const _CompletionStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          AutoSizeText(
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
        ],
      ),
    );
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
