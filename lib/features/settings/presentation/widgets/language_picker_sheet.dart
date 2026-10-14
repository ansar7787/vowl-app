import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Unified, modern language picker bottom sheet for the Settings screen.
///
/// Displays all supported app UI languages in a clean, scrollable sheet with real-time
/// search, emoji flags, native names, and active-language highlight.
class LanguagePickerSheet extends StatefulWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = di.sl<LocaleService>();
    final currentCode = localeService.currentLocale.languageCode;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, searchVal, child) {
        final query = searchVal.text.trim().toLowerCase();
        List<LocaleInfo> filteredLocales;
        if (query.isEmpty) {
          filteredLocales = LocaleService.supportedLocales;
        } else {
          filteredLocales = LocaleService.supportedLocales.where((l) {
            return l.name.toLowerCase().contains(query) ||
                l.nativeName.toLowerCase().contains(query);
          }).toList();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: 12.h),
                // Grab handle
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.5.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.slate300,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Header title row with close button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'language_picker.title',
                                fallback: 'Choose Language',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              context.tr(
                                'language_picker.subtitle',
                                fallback: 'Select the language for the app interface. Game content will remain in English.',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: context.tr('common.close', fallback: 'Close'),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              di.sl<HapticService>().light();
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.slate100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.r,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.slate600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Unified Single-Surface Search Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TextField(
                    controller: _searchController,
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
                        'language_picker.search_hint',
                        fallback: 'Search languages...',
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
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              tooltip: context.tr(
                                'common.clear',
                                fallback: 'Clear',
                              ),
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.slate400,
                                size: 18.r,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
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
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Language list
                Expanded(
                  child: filteredLocales.isEmpty
                      ? Center(
                          child: Text(
                            context.tr(
                              'language_picker.no_results',
                              fallback: 'No results found',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                          itemCount: filteredLocales.length,
                          itemBuilder: (context, index) {
                            final localeInfo = filteredLocales[index];
                            final isActive =
                                localeInfo.locale.languageCode == currentCode;

                            return _LanguageTile(
                              localeInfo: localeInfo,
                              isActive: isActive,
                              isDark: isDark,
                              onTap: () async {
                                di.sl<HapticService>().selection();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                // Allow bottom sheet close animation to finish
                                // before triggering app-wide locale rebuild.
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                await localeService.setLocale(
                                  localeInfo.locale,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final LocaleInfo localeInfo;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.localeInfo,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Semantics(
        label:
            '${localeInfo.name} — ${localeInfo.nativeName}${isActive ? " — currently selected" : ""}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            splashColor: AppColors.indigo500.withValues(alpha: 0.1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.indigo500.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      )
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : AppColors.slate50),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isActive
                      ? AppColors.indigo500.withValues(alpha: 0.4)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.slate200.withValues(alpha: 0.6)),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      localeInfo.flag,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localeInfo.name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.indigo500
                                : (isDark ? Colors.white : AppColors.slate800),
                          ),
                        ),
                        if (localeInfo.name != localeInfo.nativeName) ...[
                          SizedBox(height: 1.h),
                          Text(
                            localeInfo.nativeName,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.indigo500,
                      size: 20.r,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
