import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';

class WordBankScreen extends StatefulWidget {
  const WordBankScreen({super.key});

  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HapticService _haptics = di.sl<HapticService>();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    
    // Initial load of the word bank
    context.read<DailyWordsBloc>().add(
      WordBankLoadRequested(query: '', isPremium: _isPremium),
    );

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<DailyWordsBloc>().add(
      WordBankLoadRequested(
        query: _searchController.text.trim(),
        isPremium: _isPremium,
      ),
    );
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
            child: Column(
              children: [
                _buildHeader(context, isDark),
                _buildSearchBar(context, isDark),
                Expanded(
                  child: BlocBuilder<DailyWordsBloc, DailyWordsState>(
                    builder: (context, state) {
                      if (state.status == DailyWordsStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      return Column(
                        children: [
                          _buildMasteryStats(state.masteryStats, isDark),
                          SizedBox(height: 16.h),
                          Expanded(
                            child: state.wordBankEntries.isEmpty
                                ? _buildEmptyState(context, isDark)
                                : _buildWordList(state.wordBankEntries, isDark),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AutoSizeText(
              context.tr('word_bank.title', fallback: 'Word Bank'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: context.tr('word_bank.search_hint', fallback: 'Search learned words...'),
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _haptics.selection();
                },
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  size: 20.r,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryStats(Map<String, int> stats, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatIndicator(
            label: 'Learning',
            count: (stats['new'] ?? 0) + (stats['learning'] ?? 0),
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          _StatIndicator(
            label: 'Reviewing',
            count: stats['reviewing'] ?? 0,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          _StatIndicator(
            label: 'Mastered',
            count: stats['mastered'] ?? 0,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<WordProgress> words, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
      physics: const BouncingScrollPhysics(),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GlassTile(
            padding: EdgeInsets.all(16.r),
            usePremiumStyle: false,
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
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        'Learned: ${word.learnedDate}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                _buildMasteryBadge(word.box, isDark),
              ],
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

    if (box == 0 || box <= 2) {
      color = const Color(0xFF3B82F6);
      label = 'Learning';
      icon = Icons.school_rounded;
    } else if (box < 5) {
      color = const Color(0xFFF59E0B);
      label = 'Reviewing';
      icon = Icons.loop_rounded;
    } else {
      color = const Color(0xFF10B981);
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
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 64.r,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              _searchController.text.isEmpty
                  ? context.tr('word_bank.empty', fallback: 'No words learned yet.')
                  : context.tr('word_bank.no_results', fallback: 'No matching words found.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatIndicator({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
