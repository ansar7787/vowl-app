import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

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
      label: '${word.word}, ${word.partOfSpeech}. Tap card to see definition.',
      child: GlassTile(
        padding: EdgeInsets.all(24.r),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top badges: POS + Difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      word.partOfSpeech.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF6366F1),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _DifficultyBadge(difficulty: difficulty),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    theme!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 28.h),
              AutoSizeText(
                word.word,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
                maxLines: 1,
                minFontSize: 24,
              ),
              if (translatedWord != null) ...[
                SizedBox(height: 12.h),
                AutoSizeText(
                  translatedWord!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                  maxLines: 1,
                  minFontSize: 16,
                ),
              ],
              SizedBox(height: 16.h),
              AutoSizeText(
                word.phonetic,
                style: TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 20.sp,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                minFontSize: 14,
              ),
              SizedBox(height: 32.h),
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
                  ),
                ],
              ),
              // Tap to flip hint
              if (showFlipHint) ...[
                SizedBox(height: 24.h),
                _FlipHint(isDark: isDark),
              ],
            ],
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
  final bool isTranslating;
  final String? translatedDefinition;
  final String? translatedExample;

  const WordCardBack({
    super.key,
    required this.word,
    required this.isDark,
    required this.onSpeak,
    required this.onTranslate,
    required this.isTranslating,
    this.translatedDefinition,
    this.translatedExample,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.zero,
      child: RawScrollbar(
        thumbColor: isDark ? Colors.white30 : Colors.black26,
        radius: Radius.circular(8.r),
        thickness: 6.w,
        padding: EdgeInsets.all(6.r),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        word.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF6366F1),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _TranslateButton(
                      isTranslating: isTranslating,
                      isTranslated: translatedDefinition != null,
                      onTap: onTranslate,
                    ),
                    SizedBox(width: 8.w),
                    DailyWordsIconButton(
                      icon: Icons.volume_up_rounded,
                      onTap: onSpeak,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 1,
                ),
                SizedBox(height: 24.h),
                // Definition
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
                if (translatedDefinition != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    translatedDefinition!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                      height: 1.5,
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                // Example
                SectionLabel(
                  label: context.tr('daily_words.example', fallback: 'Example'),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${word.example}"',
                        style: TextStyle(
                          fontFamily: 'Spectral',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                          height: 1.5,
                        ),
                      ),
                      if (translatedExample != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          '"${translatedExample!}"',
                          style: TextStyle(
                            fontFamily: 'Spectral',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF10B981),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
              ],
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
    return GestureDetector(
      onTap: isTranslated || isTranslating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: isTranslated
              ? const Color(0xFF10B981)
              : const Color(
                  0xFF10B981,
                ).withValues(alpha: isTranslating ? 0.05 : 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF10B981).withValues(
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
                    color: const Color(0xFF10B981),
                  )
                : Icon(
                    isTranslated
                        ? Icons.check_rounded
                        : Icons.g_translate_rounded,
                    key: ValueKey(isTranslated ? 'check' : 'translate'),
                    color: isTranslated
                        ? Colors.white
                        : const Color(0xFF10B981),
                    size: 20.r,
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

  const DailyWordsIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 20.r),
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
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF64748B),
        letterSpacing: 1.5,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r), // Premium rounded
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 18.h), // Taller button
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
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
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
              color: Colors.redAccent,
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
  final bool isPremium;

  const SessionCompleteView({
    super.key,
    required this.streak,
    required this.totalLearned,
    required this.day,
    this.wordsThisSession = 10,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Trophy icon with glow
              Container(
                padding: EdgeInsets.all(28.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 72.r,
                  color: const Color(0xFF10B981),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                context.tr(
                  'daily_words.session_complete',
                  fallback: 'Lesson Complete!',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr(
                  'daily_words.come_back_tomorrow',
                  fallback: 'Great job! You finished Lesson $day.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 32.h),
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
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.auto_stories_rounded,
                      value: '$wordsThisSession',
                      label: context.tr(
                        'daily_words.words_today',
                        fallback: 'Words Today',
                      ),
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _CompletionStatTile(
                      icon: Icons.library_books_rounded,
                      value: '$totalLearned',
                      label: context.tr(
                        'daily_words.total_learned',
                        fallback: 'Total Words',
                      ),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
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
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
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
                            color: const Color(0xFF6366F1),
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
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
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
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFF6366F1),
                          size: 16.r,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          AutoSizeText(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
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
// DIFFICULTY BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (difficulty) {
      case 1:
        color = const Color(0xFF10B981);
        label = 'EASY';
      case 2:
        color = const Color(0xFFF59E0B);
        label = 'MEDIUM';
      default:
        color = const Color(0xFFEF4444);
        label = 'HARD';
    }
    return Container(
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
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.0,
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
            color: widget.isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          SizedBox(width: 6.w),
          Text(
            'Tap to flip',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
