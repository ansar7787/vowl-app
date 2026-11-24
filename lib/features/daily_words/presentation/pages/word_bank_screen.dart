import 'dart:async';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';

/// Filter categories for the user's personal vocabulary word bank.
enum WordBankFilter { all, today, practice, mastered }

/// Searchable personal word bank screen showcasing learned vocabulary,
/// mastery stages (learning, reviewing, mastered), and spaced repetition status.
class WordBankScreen extends StatefulWidget {
  final String? initialFilter;
  const WordBankScreen({super.key, this.initialFilter});

  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HapticService _haptics = di.sl<HapticService>();
  bool _isPremium = false;
  Timer? _debounceTimer;
  late WordBankFilter _currentFilter;

  // Multi-touch / double-tap prevention locks
  bool _isOpeningDetail = false;
  DateTime? _lastTtsTime;

  @override
  void initState() {
    super.initState();
    _isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (widget.initialFilter == 'today') {
      _currentFilter = WordBankFilter.today;
    } else if (widget.initialFilter == 'learning' ||
        widget.initialFilter == 'reviewing' ||
        widget.initialFilter == 'practice') {
      _currentFilter = WordBankFilter.practice;
    } else if (widget.initialFilter == 'mastered') {
      _currentFilter = WordBankFilter.mastered;
    } else {
      _currentFilter = WordBankFilter.all;
    }

    // Initial load of the word bank
    context.read<DailyWordsBloc>().add(
      WordBankLoadRequested(query: '', isPremium: _isPremium),
    );

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<DailyWordsBloc>().add(
        WordBankLoadRequested(
          query: _searchController.text.trim(),
          isPremium: _isPremium,
        ),
      );
    });
  }

  void _playTts(String text) {
    final now = DateTime.now();
    if (_lastTtsTime != null &&
        now.difference(_lastTtsTime!).inMilliseconds < 500) {
      return;
    }
    _lastTtsTime = now;
    _haptics.selection();
    di.sl<TtsService>().speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            child: BlocBuilder<DailyWordsBloc, DailyWordsState>(
              builder: (context, state) {
                if (state.status == DailyWordsStatus.loading ||
                    state.status == DailyWordsStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }

                return _buildSliverContent(
                  allWords: state.wordBankEntries,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverContent({
    required List<WordProgress> allWords,
    required bool isDark,
  }) {
    final service = di.sl<DailyWordsService>();
    final query = _searchController.text.trim().toLowerCase();

    // Segment words into categories with Leitner logic
    final todayWords = allWords
        .where((w) => service.isWordLearnedToday(w.wordId))
        .toList();
    final learningWords = allWords.where((w) => w.box == 1).toList();
    final reviewingWords = allWords
        .where((w) => w.box == 0 || w.box == 2)
        .toList();
    final masteredWords = allWords.where((w) => w.box >= 3).toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context, isDark),
                _buildSegmentedFilterBar(
                  totalCount: allWords.length,
                  todayCount: todayWords.length,
                  practiceCount: learningWords.length + reviewingWords.length,
                  masteredCount: masteredWords.length,
                  isDark: isDark,
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
          ..._buildSliverWordSections(
            allWords: allWords,
            todayWords: todayWords,
            learningWords: learningWords,
            reviewingWords: reviewingWords,
            masteredWords: masteredWords,
            query: query,
            isDark: isDark,
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onPressed: () {
          _haptics.light();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.homeRoute);
          }
        },
      ),
      title: AutoSizeText(
        context.tr('word_bank.title', fallback: 'Word Bank'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);
    final cardBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 6.h,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white54 : AppColors.slate400,
              size: 22.r,
            ),
            hintText: context.tr(
              'word_bank.search_hint',
              fallback: 'Search learned words...',
            ),
            hintStyle: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              color: isDark ? Colors.white38 : AppColors.slate400,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, val, _) {
                if (val.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : AppColors.slate400,
                    size: 20.r,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _haptics.selection();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedFilterBar({
    required int totalCount,
    required int todayCount,
    required int practiceCount,
    required int masteredCount,
    required bool isDark,
  }) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final containerBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? AppColors.slate800.withValues(alpha: 0.6)
              : AppColors.slate100);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 8.h,
      ),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isMidnight
                ? Colors.white.withValues(alpha: 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.slate200),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentTab(
                label: 'All',
                count: totalCount,
                isSelected: _currentFilter == WordBankFilter.all,
                activeColor: AppColors.indigo500,
                isDark: isDark,
                onTap: () {
                  _haptics.selection();
                  setState(() => _currentFilter = WordBankFilter.all);
                },
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildSegmentTab(
                label: 'Today',
                count: todayCount,
                isSelected: _currentFilter == WordBankFilter.today,
                activeColor: AppColors.amber500,
                isDark: isDark,
                onTap: () {
                  _haptics.selection();
                  setState(() => _currentFilter = WordBankFilter.today);
                },
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildSegmentTab(
                label: 'Practice',
                count: practiceCount,
                isSelected: _currentFilter == WordBankFilter.practice,
                activeColor: AppColors.blue500,
                isDark: isDark,
                onTap: () {
                  _haptics.selection();
                  setState(() => _currentFilter = WordBankFilter.practice);
                },
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildSegmentTab(
                label: 'Mastered',
                count: masteredCount,
                isSelected: _currentFilter == WordBankFilter.mastered,
                activeColor: AppColors.emerald500,
                isDark: isDark,
                onTap: () {
                  _haptics.selection();
                  setState(() => _currentFilter = WordBankFilter.mastered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? activeColor.withValues(alpha: 0.28) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? activeColor.withValues(alpha: 0.5)
                      : activeColor.withValues(alpha: 0.25),
                  width: 1,
                )
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? Colors.white54 : AppColors.slate500),
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: isDark ? 0.4 : 0.15)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.slate200.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white54 : AppColors.slate600),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSliverWordSections({
    required List<WordProgress> allWords,
    required List<WordProgress> todayWords,
    required List<WordProgress> learningWords,
    required List<WordProgress> reviewingWords,
    required List<WordProgress> masteredWords,
    required String query,
    required bool isDark,
  }) {
    if (query.isNotEmpty) {
      final List<WordProgress> pool;
      switch (_currentFilter) {
        case WordBankFilter.today:
          pool = todayWords;
          break;
        case WordBankFilter.practice:
          pool = [...learningWords, ...reviewingWords];
          break;
        case WordBankFilter.mastered:
          pool = masteredWords;
          break;
        case WordBankFilter.all:
          pool = allWords;
          break;
      }
      final matches = pool
          .where((w) => w.word.toLowerCase().contains(query))
          .toList();
      if (matches.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              isDark,
              customMessage: 'No words found matching "$query"',
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(matches[index], isDark),
              childCount: matches.length,
            ),
          ),
        ),
      ];
    }

    if (_currentFilter == WordBankFilter.today) {
      if (todayWords.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              isDark,
              customMessage: 'No words completed today yet.',
              icon: Icons.bolt_rounded,
            ),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildSectionHeader(
              title: "Today's Words",
              count: todayWords.length,
              color: AppColors.indigo500,
              icon: Icons.bolt_rounded,
              isDark: isDark,
              trailingAction: GestureDetector(
                onTap: () {
                  _haptics.selection();
                  context.push(AppRouter.dailyWordsRoute);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.25 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 15.r,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Practice',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(todayWords[index], isDark),
              childCount: todayWords.length,
            ),
          ),
        ),
      ];
    }

    if (_currentFilter == WordBankFilter.practice) {
      final practiceWords = [...learningWords, ...reviewingWords];
      if (practiceWords.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              isDark,
              customMessage: 'No words currently in practice. All caught up!',
              icon: Icons.school_rounded,
            ),
          ),
        ];
      }
      final slivers = <Widget>[];
      if (learningWords.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _buildSectionHeader(
                title: 'Learning',
                count: learningWords.length,
                color: AppColors.blue500,
                icon: Icons.school_rounded,
                isDark: isDark,
              ),
            ),
          ),
        );
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWordCard(learningWords[index], isDark),
                childCount: learningWords.length,
              ),
            ),
          ),
        );
      }
      if (reviewingWords.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _buildSectionHeader(
                title: 'Reviewing',
                count: reviewingWords.length,
                color: AppColors.amber500,
                icon: Icons.loop_rounded,
                isDark: isDark,
              ),
            ),
          ),
        );
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWordCard(reviewingWords[index], isDark),
                childCount: reviewingWords.length,
              ),
            ),
          ),
        );
      }
      return slivers;
    }

    if (_currentFilter == WordBankFilter.mastered) {
      if (masteredWords.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              isDark,
              customMessage: 'No words mastered yet. Keep practicing!',
              icon: Icons.workspace_premium_rounded,
            ),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildSectionHeader(
              title: 'Mastered',
              count: masteredWords.length,
              color: AppColors.emerald500,
              icon: Icons.workspace_premium_rounded,
              isDark: isDark,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(masteredWords[index], isDark),
              childCount: masteredWords.length,
            ),
          ),
        ),
      ];
    }

    // Default: WordBankFilter.all -> Sections for Learning, Reviewing, Mastered (no duplicate Today section)!
    if (allWords.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState(context, isDark))];
    }

    final slivers = <Widget>[];

    if (learningWords.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildSectionHeader(
              title: 'Learning',
              count: learningWords.length,
              color: AppColors.blue500,
              icon: Icons.school_rounded,
              isDark: isDark,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(learningWords[index], isDark),
              childCount: learningWords.length,
            ),
          ),
        ),
      );
    }

    if (reviewingWords.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildSectionHeader(
              title: 'Reviewing',
              count: reviewingWords.length,
              color: AppColors.amber500,
              icon: Icons.loop_rounded,
              isDark: isDark,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(reviewingWords[index], isDark),
              childCount: reviewingWords.length,
            ),
          ),
        ),
      );
    }

    if (masteredWords.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _buildSectionHeader(
              title: 'Mastered',
              count: masteredWords.length,
              color: AppColors.emerald500,
              icon: Icons.workspace_premium_rounded,
              isDark: isDark,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWordCard(masteredWords[index], isDark),
              childCount: masteredWords.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  String _formatLearnedDate(String rawDate, int box) {
    final prefix = box >= 3 ? 'Mastered' : 'Learned';
    if (rawDate.isEmpty) return '$prefix recently';
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (rawDate == todayStr) {
        return '$prefix today';
      }
      if (rawDate == yesterdayStr) {
        return '$prefix yesterday';
      }

      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return '$prefix on ${DateFormat.MMMd().format(parsed)}';
      }
    } catch (_) {}
    return '$prefix on $rawDate';
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
    Widget? trailingAction,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 10.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null) ...[
            const Spacer(),
            trailingAction,
          ],
        ],
      ),
    );
  }

  Widget _buildWordCard(WordProgress word, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => _showWordDetailSheet(context, word, isDark),
          child: GlassTile(
            padding: EdgeInsets.all(16.r),
            usePremiumStyle: false,
            blur: 0,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        word.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        _formatLearnedDate(word.learnedDate, word.box),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white54 : AppColors.slate500,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _playTts(word.word),
                  icon: Icon(
                    Icons.volume_up_rounded,
                    size: 20.r,
                    color: AppColors.indigo500,
                  ),
                  tooltip: 'Listen to ${word.word}',
                ),
                SizedBox(width: 4.w),
                _buildMasteryBadge(word.box, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWordDetailSheet(
    BuildContext context,
    WordProgress progress,
    bool isDark,
  ) async {
    // Prevent double-touch / rapid taps from opening multiple bottom sheets
    if (_isOpeningDetail) return;
    _isOpeningDetail = true;
    _haptics.selection();

    try {
      final service = di.sl<DailyWordsService>();
      final wordDetail = await service.getWordDetails(progress.wordId);

      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        isScrollControlled: true,
        enableDrag: true,
        isDismissible: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final isMidnight = isDark &&
              Theme.of(sheetContext).scaffoldBackgroundColor == Colors.black;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isMidnight
                  ? AppColors.midnightSurface
                  : (isDark ? AppColors.slate900 : Colors.white),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              border: isMidnight
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  14.h,
                  AppSpacing.screen,
                  24.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle pill
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : AppColors.slate300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Header with word, phonetic, and TTS button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.word,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              if (wordDetail?.phonetic.isNotEmpty ?? false) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  wordDetail!.phonetic,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.sp,
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.slate500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.indigo500,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _playTts(progress.word),
                          icon: Icon(Icons.volume_up_rounded, size: 22.r),
                          tooltip: 'Listen to pronunciation',
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Tags row (Part of speech & Mastery Status)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        if (wordDetail?.partOfSpeech.isNotEmpty ?? false)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              wordDetail!.partOfSpeech.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        _buildMasteryBadge(progress.box, isDark),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Divider(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                      height: 1,
                    ),
                    SizedBox(height: 16.h),

                    // Definition section
                    Text(
                      'DEFINITION',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.white38 : AppColors.slate400,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      wordDetail?.definition ??
                          'Definition currently unavailable.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(sheetContext).colorScheme.onSurface,
                      ),
                    ),

                    // Example section
                    if (wordDetail?.example.isNotEmpty ?? false) ...[
                      SizedBox(height: 18.h),
                      Text(
                        'EXAMPLE IN CONTEXT',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white38 : AppColors.slate400,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.slate200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '"${wordDetail!.example}"',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => _playTts(wordDetail.example),
                              child: Icon(
                                Icons.volume_up_outlined,
                                size: 18.r,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Spaced repetition info
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: isMidnight
                            ? AppColors.midnightNavy
                            : (isDark ? AppColors.slate800 : AppColors.slate100),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatLearnedDate(
                              progress.learnedDate,
                              progress.box,
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.slate500,
                            ),
                          ),
                          Text(
                            'Reviews: ${progress.reviewCount}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Practice / Test for Mastery button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: progress.box >= 3
                              ? AppColors.emerald500
                              : (progress.box == 1
                                    ? AppColors.blue500
                                    : AppColors.amber500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _showWordPracticeDialog(
                            context,
                            progress,
                            wordDetail?.definition ?? '',
                          );
                        },
                        icon: Icon(
                          progress.box >= 3
                              ? Icons.workspace_premium_rounded
                              : (progress.box >= 2
                                    ? Icons.emoji_events_rounded
                                    : Icons.school_rounded),
                          size: 18.r,
                        ),
                        label: Text(
                          progress.box >= 3
                              ? 'Practice Mastered Word'
                              : 'Test for Mastery',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white70
                              : AppColors.slate600,
                          side: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.slate300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error opening word detail sheet: $e');
    } finally {
      if (mounted) {
        _isOpeningDetail = false;
      }
    }
  }

  Future<void> _showWordPracticeDialog(
    BuildContext context,
    WordProgress progress,
    String definition,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sound = di.sl<SoundService>();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final isMidnight = isDark &&
            Theme.of(modalContext).scaffoldBackgroundColor == Colors.black;
        final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: isMidnight
                  ? AppColors.midnightSurface
                  : (isDark ? AppColors.slate900 : Colors.white),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              border: isMidnight
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    )
                  : null,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  16.h,
                  AppSpacing.screen,
                  24.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : AppColors.slate300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.emerald500,
                          size: 22.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: AutoSizeText(
                            'Test for Mastery · ${progress.word}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                modalContext,
                              ).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (definition.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          definition,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white70 : AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    TypeToConfirmOverlay(
                      expectedText: progress.word,
                      displayText: progress.word,
                      primaryColor: AppColors.indigo500,
                      isPositioned: false,
                      allowSkip: false,
                      onConfirmed: () {
                        Navigator.of(modalContext).pop();
                        _haptics.success();
                        sound.playCorrect();
                        context.read<DailyWordsBloc>().add(
                          DailyWordReviewed(
                            wordId: progress.wordId,
                            correct: true,
                            promoteToMastered: true,
                          ),
                        );
                      },
                      onSkipped: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasteryBadge(int box, bool isDark) {
    Color color;
    String label;
    IconData icon;

    if (box == 1) {
      color = AppColors.blue500;
      label = 'Learning';
      icon = Icons.school_rounded;
    } else if (box == 0 || box == 2) {
      color = AppColors.amber500;
      label = box == 0 ? 'Review Later' : 'Reviewing';
      icon = Icons.loop_rounded;
    } else {
      color = AppColors.emerald500;
      label = 'Mastered';
      icon = Icons.workspace_premium_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.r),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark, {
    String? customMessage,
    IconData? icon,
  }) {
    final message =
        customMessage ??
        (_searchController.text.isEmpty
            ? context.tr('word_bank.empty', fallback: 'No words learned yet.')
            : context.tr(
                'word_bank.no_results',
                fallback: 'No matching words found.',
              ));

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.menu_book_rounded,
              size: 56.r,
              color: isDark ? Colors.white24 : AppColors.slate300,
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : AppColors.slate500,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
