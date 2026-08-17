import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
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
  final TranslationService _translationService = di.sl<TranslationService>();

  bool _isFlipped = false;
  bool _isAnimating = false;
  
  // Translation Session State
  bool _translationUnlocked = false;
  bool _isTranslating = false;
  String? _translatedWord;
  String? _translatedDefinition;
  String? _translatedExample;

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

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    _translationUnlocked = isPremium;

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

    _slideController.reset();
    _flipController.reset();
    setState(() {
      _isFlipped = false;
      _isAnimating = false;
      // Reset translations for the new card
      _translatedWord = null;
      _translatedDefinition = null;
      _translatedExample = null;
    });

    context.read<DailyWordsBloc>().add(const DailyWordNextRequested());
  }

  void _speakWord(String word) {
    _tts.speak(word);
    _haptics.selection();
  }

  Future<void> _handleTranslate(DailyWord word) async {
    if (_isTranslating) return;
    
    // Check unlock
    if (!_translationUnlocked) {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: false,
        onUserEarnedReward: (_) {},
        onDismissed: () async {
          setState(() => _translationUnlocked = true);
          await _performTranslation(word);
        },
      );
      return;
    }

    await _performTranslation(word);
  }

  Future<void> _performTranslation(DailyWord word) async {
    setState(() => _isTranslating = true);
    try {
      final tWord = await _translationService.translate(word.word);
      final tDef = await _translationService.translate(word.definition);
      final tEx = await _translationService.translate(word.example);
      
      if (mounted) {
        setState(() {
          _translatedWord = tWord;
          _translatedDefinition = tDef;
          _translatedExample = tEx;
          _isTranslating = false;
        });
        _haptics.success();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation model downloading... Please wait.')),
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
                return SafeArea(child: _ErrorView(message: state.errorMessage ?? ''));
              }
              if (state.status == DailyWordsStatus.sessionComplete) {
                return SafeArea(
                  child: _SessionCompleteView(
                    streak: state.streak,
                    totalLearned: state.totalWordsLearned,
                    day: state.currentDay,
                  ),
                );
              }
              final word = state.currentWord;
              if (word == null) {
                return _buildShimmerLoading(isDark);
              }
              return _buildSliverContent(context, state, word, isDark);
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

  Widget _buildSliverContent(
    BuildContext context,
    DailyWordsState state,
    DailyWord word,
    bool isDark,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120.h,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: _DailyWordsHeader(
                  day: state.currentDay,
                  streak: state.streak,
                  progress: state.totalWords > 0
                      ? (state.currentIndex + 1) / state.totalWords
                      : 0,
                  currentIndex: state.currentIndex + 1,
                  totalWords: state.totalWords,
                  theme: state.wordSet?.theme ?? '',
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: SizedBox(
              height: 460.h,
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
                                  onTranslate: () => _handleTranslate(word),
                                  isTranslating: _isTranslating,
                                  translatedDefinition: _translatedDefinition,
                                  translatedExample: _translatedExample,
                                ),
                              )
                            : _WordCardFront(
                                word: word,
                                isDark: isDark,
                                onSpeak: () => _speakWord(word.word),
                                onTranslate: () => _handleTranslate(word),
                                isTranslating: _isTranslating,
                                translatedWord: _translatedWord,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 40.h),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: context.tr(
                      'daily_words.flip_card',
                      fallback: 'Flip Card',
                    ),
                    icon: Icons.360_rounded, // Better icon
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                    onTap: _toggleFlip,
                  ),
                ),
                SizedBox(width: 16.w), // Increased spacing
                Expanded(
                  child: _ActionButton(
                    label: context.tr(
                      'daily_words.learned',
                      fallback: 'Learned ✓',
                    ),
                    icon: Icons.verified_rounded, // Premium icon
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS
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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson $day',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    theme,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              if (streak > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
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
                ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
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
        ],
      ),
    );
  }
}

class _WordCardFront extends StatelessWidget {
  final DailyWord word;
  final bool isDark;
  final VoidCallback onSpeak;
  final VoidCallback onTranslate;
  final bool isTranslating;
  final String? translatedWord;

  const _WordCardFront({
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
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
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
                Text(
                  word.phonetic,
                  style: TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 20.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16.r,
            right: 16.r,
            child: Row(
              children: [
                _TranslateButton(
                  isTranslating: isTranslating,
                  onTap: onTranslate,
                ),
                SizedBox(width: 8.w),
                _IconButton(
                  icon: Icons.volume_up_rounded,
                  onTap: onSpeak,
                ),
              ],
            ),
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
  final VoidCallback onTranslate;
  final bool isTranslating;
  final String? translatedDefinition;
  final String? translatedExample;

  const _WordCardBack({
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
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24.r),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
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
                  SizedBox(height: 30.h),
                  // Definition
                  _SectionLabel(
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
                  _SectionLabel(
                    label: context.tr(
                      'daily_words.example',
                      fallback: 'Example',
                    ),
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
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
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
          Positioned(
            top: 16.r,
            right: 16.r,
            child: Row(
              children: [
                _TranslateButton(
                  isTranslating: isTranslating,
                  onTap: onTranslate,
                ),
                SizedBox(width: 8.w),
                _IconButton(
                  icon: Icons.volume_up_rounded,
                  onTap: onSpeak,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslateButton extends StatelessWidget {
  final bool isTranslating;
  final VoidCallback onTap;

  const _TranslateButton({
    required this.isTranslating,
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
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: isTranslating
              ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                )
              : Icon(
                  Icons.g_translate_rounded,
                  color: const Color(0xFF10B981),
                  size: 20.r,
                ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
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
        child: Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 20.r,
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
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 11.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF64748B),
        letterSpacing: 1.5,
      ),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r), // Premium rounded
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 18.h), // Taller button
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24.r),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

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
