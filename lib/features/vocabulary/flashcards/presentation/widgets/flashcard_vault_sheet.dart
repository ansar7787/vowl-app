import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import '../../data/services/flashcard_vault_service.dart';
import 'flashcard_vault_entry_tile.dart';
import 'flashcard_vault_quick_review_dialog.dart';
import 'flashcard_vault_stats_bar.dart';

/// Modal sheet displaying the learner's Lexicon Memory Vault with Ebbinghaus retention scores.
class FlashcardVaultSheet extends StatefulWidget {
  final List<FlashcardVaultEntry> initialEntries;
  const FlashcardVaultSheet({super.key, required this.initialEntries});

  static Future<void> show(BuildContext context) async {
    final entries = await FlashcardVaultService().getVaultEntries();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlashcardVaultSheet(initialEntries: entries),
    );
  }

  @override
  State<FlashcardVaultSheet> createState() => _FlashcardVaultSheetState();
}

class _FlashcardVaultSheetState extends State<FlashcardVaultSheet> {
  bool _filterDueOnly = false;
  late List<FlashcardVaultEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.initialEntries);
  }

  Future<void> _startQuickReview(List<FlashcardVaultEntry> targets) async {
    HapticFeedback.mediumImpact();
    await FlashcardVaultQuickReviewDialog.show(
      context,
      entriesToReview: targets,
      onWordMastered: (word, level, {struggled = false}) async {
        await FlashcardVaultService().recordMastery(
          word,
          level,
          perfect: !struggled,
          struggled: struggled,
        );
      },
    );
    final updated = await FlashcardVaultService().getVaultEntries();
    if (mounted) {
      setState(() {
        _entries = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final dueCount = _entries.where((e) => e.retention < 0.60).length;
    final displayed = _filterDueOnly
        ? _entries.where((e) => e.retention < 0.60).toList()
        : _entries;
    final avgRetention = _entries.isEmpty
        ? 0
        : (_entries.map((e) => e.retention).reduce((a, b) => a + b) /
                  _entries.length *
                  100)
              .round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text('📚', style: TextStyle(fontSize: 18.sp)),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Word Bank',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          Text(
                            'Review words you\'ve learned',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: FlashcardVaultStatsBar(
                  totalCount: _entries.length,
                  dueCount: dueCount,
                  avgRetention: avgRetention,
                  isDark: isDark,
                  isLandscape: false,
                ),
              ),
              SizedBox(height: 12.h),
              if (_entries.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildTab(
                          'All (${_entries.length})',
                          !_filterDueOnly,
                          () => setState(() => _filterDueOnly = false),
                          isDark,
                        ),
                        SizedBox(width: 8.w),
                        _buildTab(
                          'Needs Review ($dueCount)',
                          _filterDueOnly,
                          () => setState(() => _filterDueOnly = true),
                          isDark,
                          highlightColor:
                              dueCount > 0 ? AppColors.rose500 : null,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 8.h),
              if (displayed.isEmpty)
                _buildEmpty(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  itemCount: displayed.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 10.h),
                  itemBuilder: (context, idx) => FlashcardVaultEntryTile(
                    entry: displayed[idx],
                    isDark: isDark,
                    onTap: () => _startQuickReview([displayed[idx]]),
                  ),
                ),
              if (_entries.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
                  child: ScaleButton(
                  key: const ValueKey('btn_quick_review'),
                  onTap: () {
                    final targets = dueCount > 0
                        ? _entries.where((e) => e.retention < 0.60).toList()
                        : _entries;
                    _startQuickReview(targets);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: isLandscape ? 8.h : 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: dueCount > 0
                          ? AppColors.rose500
                          : AppColors.indigo500,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (dueCount > 0
                                      ? AppColors.rose500
                                      : AppColors.indigo500)
                                  .withValues(alpha: 0.25),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dueCount > 0
                                  ? 'Practice Fading Words ($dueCount)'
                                  : 'Quick Review (${_entries.length})',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
    String label,
    bool sel,
    VoidCallback onTap,
    bool isDark, {
    Color? highlightColor,
  }) {
    final col = highlightColor ?? AppColors.indigo500;
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: sel
              ? col.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.slate800 : AppColors.slate100),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: sel ? col : Colors.transparent, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.5.sp,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel
                ? (isDark ? Colors.white : col)
                : (isDark ? AppColors.slate400 : AppColors.slate600),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) => Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 40.r,
                color: isDark ? AppColors.slate600 : AppColors.slate400,
              ),
              SizedBox(height: 10.h),
              Text(
                _filterDueOnly
                    ? 'No Words Due for Review! 🎉'
                    : 'Your Word Bank is Empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.slate800,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _filterDueOnly
                    ? 'All your saved words are fresh in memory.'
                    : 'Master words to add them here and review them before they fade.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      );
}
