import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

class ReviewMistakesScreen extends StatefulWidget {
  const ReviewMistakesScreen({super.key});

  @override
  State<ReviewMistakesScreen> createState() => _ReviewMistakesScreenState();
}

class _ReviewMistakesScreenState extends State<ReviewMistakesScreen> {
  bool _isLoading = true;
  List<ErrorJournalEntry> _entries = [];
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    setState(() => _isLoading = true);
    
    final authState = context.read<AuthBloc>().state;
    _userId = authState.user?.id ?? 'local';

    final entries = await ErrorJournalCollector.fetch(
      userId: _userId,
      limit: 50,
    );
    
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissMistake(String id) async {
    await ErrorJournalCollector.dismiss(userId: _userId, entryId: id);
    if (mounted) {
      setState(() {
        _entries.removeWhere((e) => e.id == id);
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: isDark ? AppColors.slate800 : Colors.white,
          title: Text(
            context.tr('profile.clear_all_title', fallback: 'Clear All Mistakes?'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            context.tr('profile.clear_all_desc', fallback: 'This will permanently delete your entire error journal. You will not be able to practice these mistakes again.'),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                context.tr('general.cancel', fallback: 'Cancel'),
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
              child: Text(
                context.tr('general.delete', fallback: 'Delete'),
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ErrorJournalCollector.clearAll(userId: _userId);
      if (mounted) {
        setState(() {
          _entries.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slate900 : AppColors.slate50;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('profile.review_mistakes', fallback: 'My Mistakes'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          if (_entries.isNotEmpty && !_isLoading)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: AppColors.red500),
              tooltip: context.tr('profile.clear_all', fallback: 'Clear All'),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading 
        ? _buildShimmerLoading(context, isDark)
        : _entries.isEmpty 
          ? _buildEmptyState(context, isDark)
          : _buildList(context, isDark),
      bottomNavigationBar: _entries.isNotEmpty && !_isLoading
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push(AppRouter.practiceMistakesRoute);
                    // Reload mistakes after returning, as practice mode might have dismissed some
                    if (mounted) {
                      _loadMistakes();
                    }
                  },
                  icon: const Icon(Icons.psychology_rounded),
                  label: Text(
                    context.tr('profile.practice_weaknesses', fallback: 'Practice Weaknesses'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 64.r,
            color: AppColors.emerald500,
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr('profile.no_mistakes_title', fallback: "You're All Caught Up!"),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr('profile.no_mistakes_subtitle', fallback: 'Your error journal is completely empty.'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: 6,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? AppColors.slate800 : Colors.grey[300]!,
          highlightColor: isDark ? AppColors.slate700 : Colors.grey[100]!,
          child: Container(
            height: 140.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return TweenAnimationBuilder<double>(
          // Staggered delay based on index (max 10 to avoid too long delay)
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index.clamp(0, 10) * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: ScaleButton(
            onTap: () async {
              di.sl<HapticService>().selection();
              
              final category = QuestRegistry.gameToCategory[entry.gameType] ?? 'reading';
              final uri = Uri(
                path: '/game',
                queryParameters: {
                  'category': category,
                  'subtype': entry.gameType,
                  'level': entry.level.toString(),
                },
              );
              
              await context.push(uri.toString());
              
              // Reload if they created new mistakes while replaying
              if (mounted) {
                _loadMistakes();
              }
            },
            child: GlassTile(
              borderRadius: BorderRadius.circular(16.r),
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      entry.gameType.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indigo500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.r, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => _dismissMistake(entry.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                entry.question,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              _buildAnswerRow(
                context, 
                Icons.close_rounded, 
                AppColors.red500, 
                context.tr('profile.you_answered', fallback: 'You answered:'), 
                entry.userAnswer,
              ),
              SizedBox(height: 8.h),
              _buildAnswerRow(
                context, 
                Icons.check_rounded, 
                AppColors.emerald500, 
                context.tr('profile.correct_answer', fallback: 'Correct answer:'), 
                entry.correctAnswer,
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildAnswerRow(BuildContext context, IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
