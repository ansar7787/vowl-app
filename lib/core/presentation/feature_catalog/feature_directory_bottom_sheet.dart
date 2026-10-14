import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/feature_catalog/app_feature_catalog.dart';
import 'package:vowl/core/presentation/feature_catalog/first_time_welcome_showcase.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Bottom sheet directory allowing users to search and discover every single feature in Vowl.
class FeatureDirectoryBottomSheet extends StatefulWidget {
  const FeatureDirectoryBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FeatureDirectoryBottomSheet(),
    );
  }

  @override
  State<FeatureDirectoryBottomSheet> createState() =>
      _FeatureDirectoryBottomSheetState();
}

class _FeatureDirectoryBottomSheetState
    extends State<FeatureDirectoryBottomSheet> {
  FeatureCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLaunching = false;
  late List<AppFeatureItem> _filteredFeatures;

  @override
  void initState() {
    super.initState();
    _recomputeFilteredFeatures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recomputeFilteredFeatures() {
    final query = _searchQuery.toLowerCase().trim();
    _filteredFeatures = AppFeatureCatalog.allFeatures.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSubtitle = item.subtitle.toLowerCase().contains(query);
        final matchBadge = item.badge?.toLowerCase().contains(query) ?? false;
        final matchCategory = item.category.label.toLowerCase().contains(query);
        final matchKeywords = item.keywords.any(
          (k) => k.toLowerCase().contains(query),
        );
        return matchTitle ||
            matchSubtitle ||
            matchBadge ||
            matchCategory ||
            matchKeywords;
      }
      return true;
    }).toList();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim();
      _recomputeFilteredFeatures();
    });
  }

  void _selectCategory(FeatureCategory? cat) {
    setState(() {
      _selectedCategory = _selectedCategory == cat ? null : cat;
      _recomputeFilteredFeatures();
    });
  }

  void _clearSearch() {
    di.sl<HapticService>().light();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _recomputeFilteredFeatures();
    });
  }

  void _launchFeature(AppFeatureItem feature) {
    if (_isLaunching) return;
    _isLaunching = true;
    di.sl<HapticService>().selection();
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(feature.route);
  }

  void _openWelcomeTour() {
    if (_isLaunching) return;
    _isLaunching = true;
    di.sl<HapticService>().selection();
    final nav = Navigator.of(context, rootNavigator: true);
    final rootContext = nav.context;
    nav.pop();
    if (rootContext.mounted) {
      FirstTimeWelcomeShowcase.show(rootContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    final viewInsetsBottom = mediaQuery.viewInsets.bottom;
    final features = _filteredFeatures;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 540.w,
            maxHeight: mediaQuery.size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF13141C).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: 12.h,
            bottom: bottomInset + viewInsetsBottom + 12.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Sheet Header: Top Row with Title & Actions, Subtitle underneath
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(
                              'feature_catalog.title',
                              fallback: 'Explore All Features',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Tour Pill
                        GestureDetector(
                          onTap: _openWelcomeTour,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.indigo500.withValues(
                                  alpha: 0.2,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 13.r,
                                  color: AppColors.indigo500,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr(
                                    'feature_catalog.tour_pill',
                                    fallback: 'Tour',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.indigo500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // Close Button
                        IconButton(
                          onPressed: () {
                            if (!_isLaunching) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: Container(
                            width: 30.r,
                            height: 30.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.r,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 40.r,
                            minHeight: 40.r,
                          ),
                          tooltip: context.tr(
                            'common.close',
                            fallback: 'Close',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.tr(
                        'feature_catalog.subtitle',
                        fallback:
                            'Find any game, tool, or practice lab in Vowl',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        height: 1.35,
                        color: isDark ? Colors.white60 : AppColors.slate500,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // Single Unified Search Field matching Translate language screen
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  cursorColor: AppColors.indigo500,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : AppColors.slate100,
                    hintText: context.tr(
                      'feature_catalog.search_hint',
                      fallback: 'Search features and games...',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : AppColors.slate400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white54 : AppColors.slate500,
                      size: 20.r,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 44.w,
                      minHeight: 44.h,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, val, _) {
                        if (val.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: context.tr(
                            'common.clear',
                            fallback: 'Clear',
                          ),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white38 : AppColors.slate400,
                            size: 18.r,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        );
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : AppColors.slate200,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : AppColors.slate200,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(
                        color: AppColors.indigo500,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Filter Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label:
                          '${context.tr('common.all', fallback: 'All')} (${AppFeatureCatalog.allFeatures.length})',
                      isSelected: _selectedCategory == null,
                      isDark: isDark,
                      onTap: () => _selectCategory(null),
                    ),
                    ...FeatureCategory.values.map((cat) {
                      final count = AppFeatureCatalog.categoryCounts[cat] ?? 0;
                      return _buildFilterChip(
                        label: '${cat.label} ($count)',
                        icon: cat.icon,
                        isSelected: _selectedCategory == cat,
                        isDark: isDark,
                        onTap: () => _selectCategory(cat),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              // List of Feature Cards or Empty State
              Expanded(
                child: features.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 32.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64.r,
                                height: 64.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04),
                                ),
                                child: Icon(
                                  LucideIcons.searchX,
                                  size: 30.r,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black26,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                '${context.tr('feature_catalog.no_match', fallback: 'No features matching')} "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                softWrap: true,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                context.tr(
                                  'feature_catalog.no_match_hint',
                                  fallback:
                                      'Try searching for topics like words, speaking, camera, or kids.',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                ),
                                softWrap: true,
                              ),
                              SizedBox(height: 16.h),
                              ScaleButton(
                                onTap: _clearSearch,
                                child: Container(
                                  constraints: BoxConstraints(minHeight: 44.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo500.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: AppColors.indigo500.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        size: 16.r,
                                        color: AppColors.indigo500,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        context.tr(
                                          'feature_catalog.clear_search',
                                          fallback: 'Reset & Show All',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.indigo500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
                        itemCount: features.length,
                        separatorBuilder: (_, _) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final item = features[index];
                          return _buildFeatureCard(item, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label filter',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              di.sl<HapticService>().light();
              onTap();
            },
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.indigo500
                    : (isDark
                          ? const Color(0xFF1E2130)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.indigo500
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 13.r,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.slate600),
                    ),
                    SizedBox(width: 5.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.slate700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(AppFeatureItem item, bool isDark) {
    final semanticLabel =
        '${item.title}, ${item.category.label}. '
        '${item.badge != null ? "${item.badge!}. " : ""}'
        '${item.subtitle}';

    return Semantics(
      button: true,
      label: semanticLabel,
      hint: 'Tap to launch ${item.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchFeature(item),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 74.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark
                  ? (item.isHighlight
                        ? item.accentColor.withValues(alpha: 0.08)
                        : const Color(0xFF1A1C26))
                  : (item.isHighlight
                        ? item.accentColor.withValues(alpha: 0.04)
                        : Colors.white),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: item.isHighlight
                    ? item.accentColor.withValues(alpha: isDark ? 0.35 : 0.25)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0)),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon container with accent tint
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: item.accentColor.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(item.icon, size: 20.r, color: item.accentColor),
                ),
                SizedBox(width: 12.w),

                // Title, Badges, and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ),
                          if (item.badge != null) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: item.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          height: 1.35,
                          color: isDark ? Colors.white70 : AppColors.slate600,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),

                // Launch chevron
                Icon(
                  LucideIcons.chevronRight,
                  size: 18.r,
                  color: isDark ? Colors.white38 : AppColors.slate400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
