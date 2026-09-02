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

  const WordCardFront({
    super.key,
    required this.word,
    required this.isDark,
    required this.onSpeak,
    required this.onTranslate,
    required this.isTranslating,
    this.translatedWord,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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
            SizedBox(height: 24.h),
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
          ],
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
        fontSize: 11.sp,
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

  const SessionCompleteView({
    super.key,
    required this.streak,
    required this.totalLearned,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 80.r,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(height: 32.h),
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
            SizedBox(height: 12.h),
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
            SizedBox(height: 48.h),
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
          ],
        ),
      ),
    );
  }
}
