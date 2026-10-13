import 'dart:async';
import 'package:vowl/core/theme/app_colors.dart';
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
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
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
  Timer? _debounceTimer;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : Colors.white,
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
                          SizedBox(height: 12.h),
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
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: () {
                _haptics.light();
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: AutoSizeText(
              context.tr('word_bank.title', fallback: 'Word Bank'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.slate200,
            width: 1,
          ),
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

  Widget _buildMasteryStats(Map<String, int> stats, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatIndicator(
            label: 'Learning',
            count: stats['learning'] ?? 0,
            color: AppColors.blue500,
            isDark: isDark,
          ),
          _StatIndicator(
            label: 'Reviewing',
            count: stats['reviewing'] ?? 0,
            color: AppColors.amber500,
            isDark: isDark,
          ),
          _StatIndicator(
            label: 'Mastered',
            count: stats['mastered'] ?? 0,
            color: AppColors.emerald500,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<WordProgress> words, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      physics: const BouncingScrollPhysics(),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
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
                            'Learned on ${word.learnedDate}',
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
                      onPressed: () {
                        _haptics.selection();
                        di.sl<TtsService>().speak(word.word);
                      },
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
      },
    );
  }

  Future<void> _showWordDetailSheet(
    BuildContext context,
    WordProgress progress,
    bool isDark,
  ) async {
    _haptics.selection();
    final service = di.sl<DailyWordsService>();
    final wordDetail = await service.getWordDetails(progress.wordId);

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
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
              padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 24.h),
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
                                color:
                                    Theme.of(sheetContext).colorScheme.onSurface,
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
                        onPressed: () {
                          _haptics.selection();
                          di.sl<TtsService>().speak(progress.word);
                        },
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
                            color: AppColors.indigo500.withValues(alpha: 0.12),
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
                    wordDetail?.definition ?? 'Definition currently unavailable.',
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
                                color: Theme.of(sheetContext).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              _haptics.selection();
                              di.sl<TtsService>().speak(wordDetail.example);
                            },
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
                      color: isDark ? AppColors.slate800 : AppColors.slate50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Learned: ${progress.learnedDate}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark ? Colors.white54 : AppColors.slate500,
                          ),
                        ),
                        Text(
                          'Reviews: ${progress.reviewCount}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
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
              color: isDark ? Colors.white24 : AppColors.slate300,
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              _searchController.text.isEmpty
                  ? context.tr(
                      'word_bank.empty',
                      fallback: 'No words learned yet.',
                    )
                  : context.tr(
                      'word_bank.no_results',
                      fallback: 'No matching words found.',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
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
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
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
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
