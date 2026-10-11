import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/feature_catalog/app_feature_catalog.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Bottom sheet directory allowing users to search and discover every single feature in Vowl.
class FeatureDirectoryBottomSheet extends StatefulWidget {
  const FeatureDirectoryBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppFeatureItem> get _filteredFeatures {
    return AppFeatureCatalog.allFeatures.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSubtitle = item.subtitle.toLowerCase().contains(query);
        final matchBadge = item.badge?.toLowerCase().contains(query) ?? false;
        return matchTitle || matchSubtitle || matchBadge;
      }
      return true;
    }).toList();
  }

  void _launchFeature(AppFeatureItem feature) {
    di.sl<HapticService>().selection();
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(feature.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final features = _filteredFeatures;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
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
            left: 20.w,
            right: 20.w,
            top: 14.h,
            bottom: bottomInset + 16.h,
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
              SizedBox(height: 16.h),

              // Sheet Header
              Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      LucideIcons.compass,
                      color: AppColors.indigo500,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore All Features',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '100+ Games, AI Camera, Boutique & Kids Tools',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.r,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32.r,
                      minHeight: 32.r,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Search Bar
              Container(
                height: 42.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 16.r,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search 100+ games, camera, boutique, kids...',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5.sp,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.r,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Filter Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All (${AppFeatureCatalog.allFeatures.length})',
                      isSelected: _selectedCategory == null,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    ...FeatureCategory.values.map((cat) {
                      final count = AppFeatureCatalog.allFeatures
                          .where((f) => f.category == cat)
                          .length;
                      return _buildFilterChip(
                        label: '${cat.label} ($count)',
                        icon: cat.icon,
                        isSelected: _selectedCategory == cat,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == cat ? null : cat;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // List of Feature Cards
              Expanded(
                child: features.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.searchX,
                              size: 36.r,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'No features matching "$_searchQuery"',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            di.sl<HapticService>().light();
            onTap();
          },
          borderRadius: BorderRadius.circular(20.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.indigo500
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.indigo500
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 12.r,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  SizedBox(width: 5.w),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(AppFeatureItem item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchFeature(item),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C26) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              // Icon container with accent tint
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  item.icon,
                  size: 20.r,
                  color: item.accentColor,
                ),
              ),
              SizedBox(width: 12.w),

              // Title, Badge, and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              item.badge!,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        height: 1.25,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Launch chevron
              Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14.r,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

