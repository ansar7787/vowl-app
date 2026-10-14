import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';

/// Unified, high-performance bottom sheet for selecting translation languages across Vowl.
///
/// Features:
/// - Pinned downloaded/offline models at the top for instant discovery.
/// - Full 50+ language catalog sorted and filterable in real time.
/// - Unified single-surface search bar with instant clear action.
/// - Instant one-tap selection with haptic feedback.
/// - Reusable for in-game hint translations, translation screen, photo vocab, and settings.
class LanguageSelectionBottomSheet extends StatefulWidget {
  final bool isSource;
  final String? currentLanguage;
  final List<String>? downloadedLanguages;
  final ValueChanged<String>? onSelected;
  final String? title;
  final String? subtitle;

  const LanguageSelectionBottomSheet({
    super.key,
    this.isSource = false,
    this.currentLanguage,
    this.downloadedLanguages,
    this.onSelected,
    this.title,
    this.subtitle,
  });

  static Future<String?> show(
    BuildContext context, {
    bool isSource = false,
    String? currentLanguage,
    List<String>? downloadedLanguages,
    ValueChanged<String>? onSelected,
    String? title,
    String? subtitle,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LanguageSelectionBottomSheet(
        isSource: isSource,
        currentLanguage: currentLanguage,
        downloadedLanguages: downloadedLanguages,
        onSelected: onSelected,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allLanguages = [];
  List<String> _filteredLanguages = [];
  List<String> _downloadedLanguages = [];
  String? _activeLanguage;

  @override
  void initState() {
    super.initState();
    _allLanguages = TranslationService.supportedLanguages.keys.toList()..sort();
    _filteredLanguages = List.from(_allLanguages);
    _activeLanguage = widget.currentLanguage;
    if (widget.downloadedLanguages != null) {
      _downloadedLanguages = List.from(widget.downloadedLanguages!);
    }
    _searchController.addListener(_onSearchChanged);
    _loadInitialMetadata();
  }

  Future<void> _loadInitialMetadata() async {
    final translationService = di.sl<TranslationService>();

    if (widget.currentLanguage == null) {
      final configured = widget.isSource
          ? await translationService.getConfiguredSourceLanguageName()
          : await translationService.getConfiguredLanguageName();
      if (mounted && configured != null) {
        setState(() {
          _activeLanguage = configured;
        });
      }
    }

    if (widget.downloadedLanguages == null) {
      final downloaded = await translationService.getDownloadedLanguageNames();
      if (mounted) {
        setState(() {
          _downloadedLanguages = downloaded;
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = List.from(_allLanguages);
      } else {
        _filteredLanguages = _allLanguages
            .where((lang) => lang.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _onLanguageSelected(String lang) async {
    di.sl<HapticService>().selection();

    if (widget.onSelected != null) {
      widget.onSelected!(lang);
    } else {
      // Default: persist to TranslationService
      final target = TranslationService.supportedLanguages[lang];
      if (target != null) {
        final translationService = di.sl<TranslationService>();
        if (widget.isSource) {
          await translationService.setSourceLanguage(target);
        } else {
          await translationService.setTargetLanguage(target);
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop(lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final readyList = _downloadedLanguages
        .where((lang) => _filteredLanguages.contains(lang))
        .toList();

    final defaultTitle = widget.isSource
        ? context.tr(
            'translation.select_source_language',
            fallback: 'Select Source Language',
          )
        : context.tr(
            'translation.select_target_language',
            fallback: 'Select Target Language',
          );

    final defaultSubtitle = widget.isSource
        ? context.tr(
            'translation.select_source_desc',
            fallback: 'Translate from',
          )
        : context.tr(
            'translation.select_target_desc',
            fallback: 'Translate to / used for in-game hints & explanations',
          );

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
                          widget.title ?? defaultTitle,
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
                          widget.subtitle ?? defaultSubtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : AppColors.slate500,
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
                            color: isDark ? Colors.white60 : AppColors.slate600,
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
                    'common.search',
                    fallback: 'Search',
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
                        tooltip: context.tr('common.clear', fallback: 'Clear'),
                        icon: Icon(
                          Icons.cancel_rounded,
                          color: isDark ? Colors.white38 : AppColors.slate400,
                          size: 18.r,
                        ),
                        onPressed: () {
                          _searchController.clear();
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
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Content Area: Pinned Downloaded + All Languages List
            Expanded(
              child: _filteredLanguages.isEmpty
                  ? Center(
                      child: Text(
                        context.tr(
                          'language_picker.no_results',
                          fallback: 'No results found',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          color: isDark ? Colors.white38 : AppColors.slate400,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        // Pinned Downloaded Section
                        if (readyList.isNotEmpty &&
                            _searchController.text.isEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                4.h,
                                20.w,
                                8.h,
                              ),
                              child: Text(
                                context.tr(
                                  'translation.downloaded_ready',
                                  fallback: 'Downloaded',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final lang = readyList[index];
                                final isActive = lang == _activeLanguage;
                                return _buildLanguageRow(
                                  lang,
                                  isActive,
                                  true,
                                  isDark,
                                );
                              }, childCount: readyList.length),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                16.h,
                                20.w,
                                8.h,
                              ),
                              child: Text(
                                context.tr(
                                  'translation.all_languages',
                                  fallback: 'All languages',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.slate400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // All Languages List
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final lang = _filteredLanguages[index];
                              final isActive = lang == _activeLanguage;
                              final isDownloaded = _downloadedLanguages
                                  .contains(lang);
                              return _buildLanguageRow(
                                lang,
                                isActive,
                                isDownloaded,
                                isDark,
                              );
                            }, childCount: _filteredLanguages.length),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(
    String lang,
    bool isActive,
    bool isDownloaded,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onLanguageSelected(lang),
          borderRadius: BorderRadius.circular(16.r),
          splashColor: AppColors.indigo500.withValues(alpha: 0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.indigo500.withValues(alpha: isDark ? 0.15 : 0.08)
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
                Expanded(
                  child: Text(
                    lang,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.indigo500
                          : (isDark ? Colors.white : AppColors.slate800),
                    ),
                  ),
                ),
                if (isDownloaded)
                  Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      context.tr('common.ready', fallback: 'READY'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald500,
                        letterSpacing: 0.3,
                      ),
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
    );
  }
}
