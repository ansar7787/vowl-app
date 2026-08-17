import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/translatable_text.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';

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

  bool _isFlipped = false;
  bool _isAnimating = false;

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
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic),
    );

    // Load words
    final isPremium =
        context.read<AuthBloc>().state.user?.isPremium ?? false;
    context.read<DailyWordsBloc>().add(
          DailyWordsLoadRequested(isPremium: isPremium),
        );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isAnimating) return;
    _haptics.light();
    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Future<void> _markLearnedAndNext(DailyWord word) async {
    if (_isAnimating) return;
    _isAnimating = true;
    _haptics.success();
    _sound.playCorrect();

    context.read<DailyWordsBloc>().add(DailyWordMarkedLearned(word));

    await _slideController.forward();
    if (!mounted) return;

    // Reset for next card
    _slideController.reset();
    _flipController.reset();
    setState(() {
      _isFlipped = false;
      _isAnimating = false;
    });

    context.read<DailyWordsBloc>().add(const DailyWordNextRequested());
  }

  void _speakWord(String word) {
    _tts.speak(word);
    _haptics.selection();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            child: BlocBuilder<DailyWordsBloc, DailyWordsState>(
              builder: (context, state) {
                if (state.status == DailyWordsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == DailyWordsStatus.error) {
                  return _ErrorView(message: state.errorMessage ?? '');
                }
                if (state.status == DailyWordsStatus.sessionComplete) {
                  return _SessionCompleteView(
                    streak: state.streak,
                    totalLearned: state.totalWordsLearned,
                    day: state.currentDay - 1,
                  );
                }
                final word = state.currentWord;
                if (word == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildContent(context, state, word, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DailyWordsState state,
    DailyWord word,
    bool isDark,
  ) {
    return Column(
      children: [
        // ── Header ──
        _DailyWordsHeader(
          day: state.currentDay,
          streak: state.streak,
          progress: state.totalWords > 0
              ? (state.currentIndex + 1) / state.totalWords
              : 0,
          currentIndex: state.currentIndex + 1,
          totalWords: state.totalWords,
          theme: state.wordSet?.theme ?? '',
        ),
        // ── Card ──
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                              transform: Matrix4.identity()..rotateY(3.14159),
                              child: _WordCardBack(
                                word: word,
                                isDark: isDark,
                                onSpeak: () => _speakWord(word.word),
                              ),
                            )
                          : _WordCardFront(
                              word: word,
                              isDark: isDark,
                              onSpeak: () => _speakWord(word.word),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // ── Actions ──
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: context.tr(
                    'daily_words.flip_card',
                    fallback: 'Flip Card',
                  ),
                  icon: Icons.flip_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: _toggleFlip,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ActionButton(
                  label: context.tr(
                    'daily_words.learned',
                    fallback: 'Learned ✓',
                  ),
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _markLearnedAndNext(word),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyWordsHeader extends StatelessWidget {
  final int day;
  final int streak;
  final double progress;
  final int currentIndex;
  final int totalWords;
  final String theme;

  const _DailyWordsHeader({
    required this.day,
    required this.streak,
    required this.progress,
    required this.currentIndex,
    required this.totalWords,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Column(
        children: [
          // Top row: back, title, streak
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    AutoSizeText(
                      context.tr(
                        'daily_words.title',
                        fallback: 'Daily 10 Words',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (theme.isNotEmpty)
                      AutoSizeText(
                        theme,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 14.r),
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
              ),
              SizedBox(width: 12.w),
              // Word Bank Button
              GestureDetector(
                onTap: () {
                  di.sl<HapticService>().selection();
                  context.push(AppRouter.wordBankRoute);
                },
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    size: 20.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Progress bar
          Row(
            children: [
              Text(
                'Day $day',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6366F1),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$currentIndex / $totalWords',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _WordCardFront extends StatelessWidget {
  final DailyWord word;
  final bool isDark;
  final VoidCallback onSpeak;

  const _WordCardFront({
    required this.word,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(28.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Part of speech badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: AutoSizeText(
              word.partOfSpeech.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6366F1),
                letterSpacing: 1.2,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: 20.h),
          // Word
          AutoSizeText(
            word.word,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 42.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          // Phonetic
          GestureDetector(
            onTap: onSpeak,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: const Color(0xFF6366F1),
                  size: 18.r,
                ),
                SizedBox(width: 6.w),
                AutoSizeText(
                  word.phonetic,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          // Frequency badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: AutoSizeText(
              '#${word.frequencyRank} most used',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: 24.h),
          // Tap hint
          AutoSizeText(
            context.tr('daily_words.tap_to_flip', fallback: 'Tap to flip →'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _WordCardBack extends StatelessWidget {
  final DailyWord word;
  final bool isDark;
  final VoidCallback onSpeak;

  const _WordCardBack({
    required this.word,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header
            Center(
              child: AutoSizeText(
                word.word,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6366F1),
                ),
                maxLines: 1,
              ),
            ),
            SizedBox(height: 20.h),
            // Definition
            _SectionLabel(
              label: context.tr(
                'daily_words.definition',
                fallback: 'Definition',
              ),
            ),
            SizedBox(height: 6.h),
            TranslatableText(
              word.definition,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.5,
              ),
              maxLines: 4,
            ),
            SizedBox(height: 20.h),
            // Example
            _SectionLabel(
              label: context.tr(
                'daily_words.example',
                fallback: 'Example',
              ),
            ),
            SizedBox(height: 6.h),
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
              child: TranslatableText(
                '"${word.example}"',
                style: TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
                maxLines: 3,
              ),
            ),
            if (word.synonyms.isNotEmpty) ...[
              SizedBox(height: 20.h),
              _SectionLabel(
                label: context.tr(
                  'daily_words.synonyms',
                  fallback: 'Synonyms',
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: word.synonyms
                    .map((s) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AutoSizeText(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
      maxLines: 1,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20.r),
              SizedBox(width: 8.w),
              AutoSizeText(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCompleteView extends StatelessWidget {
  final int streak;
  final int totalLearned;
  final int day;

  const _SessionCompleteView({
    required this.streak,
    required this.totalLearned,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: GlassTile(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded,
                  color: const Color(0xFFF59E0B), size: 56.r),
              SizedBox(height: 16.h),
              AutoSizeText(
                context.tr(
                  'daily_words.session_complete',
                  fallback: 'Great Work! 🎉',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
              ),
              SizedBox(height: 8.h),
              AutoSizeText(
                'Day $day complete!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                maxLines: 1,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Streak',
                    color: const Color(0xFFEF4444),
                  ),
                  _StatPill(
                    icon: Icons.auto_stories_rounded,
                    value: '$totalLearned',
                    label: 'Total',
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    context.tr('daily_words.back_home', fallback: 'Back Home'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => context.push(AppRouter.wordBankRoute),
                child: Text(
                  context.tr('word_bank.view', fallback: 'View Word Bank →'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: color, size: 24.r),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: const Color(0xFFEF4444), size: 48.r),
            SizedBox(height: 16.h),
            AutoSizeText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
