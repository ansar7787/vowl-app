import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Premium language picker bottom sheet for the Settings screen.
///
/// Displays all supported languages in a scrollable sheet with search,
/// flags, native names, and a prominent active-language indicator.
class LanguagePickerSheet extends StatefulWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  void initState() {
    super.initState();
  }

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

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

                // Title + subtitle
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            color: const Color(0xFF3B82F6),
                            size: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              localeService.tr('language_picker.title'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        localeService.tr('language_picker.subtitle'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search field
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: localeService.tr('language_picker.search_hint'),
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white54 : Colors.black54,
                        size: 22.r,
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 20.r),
                              color: isDark ? Colors.white54 : Colors.black54,
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20.h,
                        horizontal: 20.w,
                      ),
                    ),
                  ),
                ),

                // Language list
                Expanded(
                  child: filteredLocales.isEmpty
                      ? Padding(
                          padding: EdgeInsets.only(top: 32.h, bottom: 64.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48.r,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                // FIX (HIGH-2): Localised via l10n system.
                                localeService.tr('language_picker.no_results'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
                          itemCount: filteredLocales.length,
                          itemBuilder: (context, index) {
                            final localeInfo = filteredLocales[index];
                            final isActive =
                                localeInfo.locale.languageCode == currentCode;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: _LanguageTile(
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
                              ),
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
    return Semantics(
      label:
          '${localeInfo.name} — ${localeInfo.nativeName}${isActive ? " — currently selected" : ""}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.05)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC)),
          border: Border.all(
            color: isActive
                ? const Color(0xFF3B82F6)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
        ),
        child: Material(
          color: isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      localeInfo.flag,
                      style: TextStyle(fontSize: 28.sp),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localeInfo.name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: isActive
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: isActive
                                ? const Color(0xFF3B82F6)
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A)),
                          ),
                        ),
                        if (localeInfo.name != localeInfo.nativeName)
                          Text(
                            localeInfo.nativeName,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14.r,
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
}
