import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

/// Unified, production-grade bottom sheet for translation language selection,
/// model downloading, and pack management across the entire Vowl app.
///
/// Key Features:
/// - Single Source of Truth: syncs reactively with TranslationService.
/// - Modern Shimmer Loading: prevents content jumping during initial metadata resolution.
/// - Small country flag emoji next to every language name (all 58 languages).
/// - Dedicated inline download button on un-downloaded languages with real-time progress.
/// - One-tap card click:
///     - If downloaded: instantly selects/switches language & pops sheet.
///     - If not downloaded: downloads the model with progress, then auto-selects & pops.
/// - Pack management: delete option on downloaded packs with confirmation dialog.
/// - Clean, professional UI: no repetitive/alarming "30 MB" badges.
/// - Production error handling with CustomSnackBar.
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
    TtsSpeakerButtonWidget.stopAll();
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
  final TranslationService _translationService = di.sl<TranslationService>();

  List<String> _allLanguages = [];
  List<String> _filteredLanguages = [];
  String? _activeLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _allLanguages = TranslationService.supportedLanguages.keys.toList()..sort();
    _filteredLanguages = List.from(_allLanguages);
    _activeLanguage = widget.currentLanguage;

    // Instant warm rendering if caller provided languages or already cached
    if (widget.downloadedLanguages != null &&
        widget.downloadedLanguages!.isNotEmpty) {
      _translationService.downloadedLanguagesNotifier.value = widget
          .downloadedLanguages!
          .toSet();
      _isLoading = false;
    } else if (_translationService
        .downloadedLanguagesNotifier
        .value
        .isNotEmpty) {
      _isLoading = false;
    }

    _searchController.addListener(_onSearchChanged);
    _loadInitialMetadata();

    // Listen to app-wide reactive state so any download anywhere updates this sheet live
    _translationService.downloadedLanguagesNotifier.addListener(
      _onStateUpdated,
    );
    _translationService.downloadingProgressNotifier.addListener(
      _onStateUpdated,
    );
  }

  void _onStateUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInitialMetadata() async {
    try {
      if (widget.currentLanguage == null) {
        final configured = widget.isSource
            ? await _translationService.getConfiguredSourceLanguageName()
            : await _translationService.getConfiguredLanguageName();
        if (mounted && configured != null) {
          _activeLanguage = configured;
        }
      }

      // Refresh downloaded languages in the single source of truth
      await _translationService.refreshDownloadedLanguages();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _translationService.downloadedLanguagesNotifier.removeListener(
      _onStateUpdated,
    );
    _translationService.downloadingProgressNotifier.removeListener(
      _onStateUpdated,
    );
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = List.from(_allLanguages);
      } else {
        _filteredLanguages = _allLanguages.where((lang) {
          if (lang.toLowerCase().contains(query)) return true;
          final aliases = TranslationService.languageAliases[lang];
          if (aliases != null) {
            return aliases.any((a) => a.toLowerCase().contains(query));
          }
          return false;
        }).toList();
      }
    });
  }

  /// Triggered when the dedicated download button is tapped on a language row.
  Future<void> _onDownloadButtonTapped(String lang) async {
    final downloadingMap =
        _translationService.downloadingProgressNotifier.value;
    if (downloadingMap.containsKey(lang)) return;

    if (di.sl.isRegistered<NetworkInfo>()) {
      final isOnline = await di.sl<NetworkInfo>().isConnected;
      if (!isOnline) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'translation.network_required',
              fallback:
                  'Internet connection required to download offline packs.',
            ),
            type: CustomSnackBarType.error,
          );
        }
        return;
      }
    }

    di.sl<HapticService>().light();

    try {
      final success = await _translationService.downloadLanguage(lang);
      if (success && mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'translation.download_ready_msg',
            args: [lang],
            fallback: '$lang is downloaded and ready for offline use.',
          ),
          type: CustomSnackBarType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'translation.download_failed',
            fallback:
                'Failed to download language. Please check your internet connection.',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  /// Triggered when the language card itself is tapped.
  /// - If already downloaded: selects/switches immediately and pops sheet.
  /// - If not downloaded: starts downloading with progress, then auto-selects & pops on completion.
  Future<void> _onCardTapped(String lang, bool isDownloaded) async {
    final downloadingMap =
        _translationService.downloadingProgressNotifier.value;
    if (downloadingMap.containsKey(lang)) {
      // Already downloading in-place
      return;
    }

    if (isDownloaded) {
      await _applySelection(lang);
      return;
    }

    if (di.sl.isRegistered<NetworkInfo>()) {
      final isOnline = await di.sl<NetworkInfo>().isConnected;
      if (!isOnline) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'translation.network_required',
              fallback:
                  'Internet connection required to download offline packs.',
            ),
            type: CustomSnackBarType.error,
          );
        }
        return;
      }
    }

    // Un-downloaded: start download, show progress, then auto-switch on completion
    di.sl<HapticService>().light();

    try {
      final success = await _translationService.downloadLanguage(lang);
      if (success && mounted) {
        await _applySelection(lang);
      }
    } catch (_) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'translation.download_failed',
            fallback:
                'Failed to download language. Please check your internet connection.',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  Future<void> _applySelection(String lang) async {
    di.sl<HapticService>().selection();

    if (widget.onSelected != null) {
      widget.onSelected!(lang);
    } else {
      // Default: persist to TranslationService
      final target = TranslationService.supportedLanguages[lang];
      if (target != null) {
        if (widget.isSource) {
          await _translationService.setSourceLanguage(target);
        } else {
          await _translationService.setTargetLanguage(target);
        }
      }
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(lang);
    }
  }

  void _confirmDelete(String lang, bool isDark) {
    GameDialogHelper.showDeleteConfirmation(
      context,
      title: context.tr(
        'translation.delete_pack_title',
        args: [lang],
        fallback: 'Delete $lang?',
      ),
      description: context.tr(
        'translation.delete_pack_desc',
        args: [lang],
        fallback:
            'This will remove the offline pack and free up storage space. You can redownload anytime.',
      ),
      confirmText: context.tr('common.delete', fallback: 'Delete'),
      cancelText: context.tr('common.cancel', fallback: 'Cancel'),
      onConfirm: () async {
        await _translationService.deleteLanguageModel(lang);
        if (mounted) {
          try {
            context.read<TranslationBloc>().add(TranslationModelDeleted(lang));
          } catch (_) {}
          if (_activeLanguage == lang) {
            setState(() {
              _activeLanguage = null;
            });
          }
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'translation.pack_deleted',
              args: [lang],
              fallback: '$lang pack removed.',
            ),
            type: CustomSnackBarType.info,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadedSet = _translationService.downloadedLanguagesNotifier.value;
    final downloadingMap =
        _translationService.downloadingProgressNotifier.value;

    final readyList =
        downloadedSet
            .where((lang) => _filteredLanguages.contains(lang))
            .toList()
          ..sort();

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
            'translation.fast_offline_desc',
            fallback: 'Fast offline translation • One-time setup per language',
          );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                        SizedBox(height: 3.h),
                        Text(
                          widget.subtitle ?? defaultSubtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
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

            // Unified Search Field
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

            // Content Area: Pinned Downloaded + All Languages List (with Modern Shimmer Loading)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLoading
                    ? _buildShimmerLoading(isDark)
                    : _filteredLanguages.isEmpty
                    ? Center(
                        key: const ValueKey('empty_results'),
                        child: Text(
                          context.tr(
                            'language_picker.no_results',
                            fallback: 'No languages found',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            color: isDark ? Colors.white38 : AppColors.slate400,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        key: const ValueKey('loaded_content'),
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
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.offline_pin_rounded,
                                      color: AppColors.emerald500,
                                      size: 16.r,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${context.tr('translation.downloaded_ready', fallback: 'Downloaded')} (${readyList.length})',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.emerald500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
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
                                  final downloadProgress = downloadingMap[lang];
                                  return _buildLanguageRow(
                                    lang: lang,
                                    isActive: isActive,
                                    isDownloaded: true,
                                    downloadProgress: downloadProgress,
                                    isDark: isDark,
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
                                    fallback: 'All Languages',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
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
                                final isDownloaded = downloadedSet.contains(
                                  lang,
                                );
                                final downloadProgress = downloadingMap[lang];
                                return _buildLanguageRow(
                                  lang: lang,
                                  isActive: isActive,
                                  isDownloaded: isDownloaded,
                                  downloadProgress: downloadProgress,
                                  isDark: isDark,
                                );
                              }, childCount: _filteredLanguages.length),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern shimmer loading skeleton mirroring the exact layout of the bottom sheet.
  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.slate200.withValues(alpha: 0.7);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.95);

    return Shimmer.fromColors(
      key: const ValueKey('shimmer_skeleton'),
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        children: [
          // Pinned section header placeholder
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 8.h),
            child: Row(
              children: [
                Container(
                  width: 16.r,
                  height: 16.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  width: 110.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          // 2 Pinned item placeholders
          _buildShimmerRow(hasBadge: true, isDark: isDark),
          _buildShimmerRow(hasBadge: true, isDark: isDark),

          // All languages header placeholder
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 8.h),
            child: Container(
              width: 90.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),

          // All languages row placeholders
          _buildShimmerRow(hasBadge: false, isDark: isDark),
          _buildShimmerRow(hasBadge: false, isDark: isDark),
          _buildShimmerRow(hasBadge: false, isDark: isDark),
          _buildShimmerRow(hasBadge: false, isDark: isDark),
          _buildShimmerRow(hasBadge: false, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildShimmerRow({required bool hasBadge, required bool isDark}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.slate200.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 110.w,
              height: 14.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            const Spacer(),
            if (hasBadge)
              Container(
                width: 48.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              )
            else
              Container(
                width: 28.r,
                height: 28.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow({
    required String lang,
    required bool isActive,
    required bool isDownloaded,
    required double? downloadProgress,
    required bool isDark,
  }) {
    final flag = TranslationService.getFlag(lang);
    final isDownloading = downloadProgress != null;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCardTapped(lang, isDownloaded),
          borderRadius: BorderRadius.circular(16.r),
          splashColor: AppColors.indigo500.withValues(alpha: 0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.indigo500.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.slate50),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isActive
                    ? AppColors.indigo500.withValues(alpha: 0.5)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.slate200.withValues(alpha: 0.6)),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Small Country Flag Emoji Badge
                Container(
                  width: 36.r,
                  height: 36.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Text(flag, style: TextStyle(fontSize: 18.sp)),
                ),
                SizedBox(width: 12.w),

                // Language Name
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

                // Trailing Action / State Area
                if (isDownloading) ...[
                  // Real-time downloading progress
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          value:
                              (downloadProgress > 0 && downloadProgress < 0.95)
                              ? downloadProgress
                              : null,
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.indigo500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        downloadProgress >= 0.95
                            ? context.tr(
                                'translation.finalizing_short',
                                fallback: 'Finalizing...',
                              )
                            : '${(downloadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: downloadProgress >= 0.95 ? 10.5.sp : 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                ] else if (isDownloaded) ...[
                  // Ready Badge
                  Container(
                    margin: EdgeInsets.only(right: 6.w),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Active Checkmark or Delete Icon
                  if (isActive) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.indigo500,
                      size: 20.r,
                    ),
                  ] else ...[
                    // Delete pack option for downloaded items
                    Semantics(
                      button: true,
                      label: 'Delete $lang pack',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmDelete(lang, isDark),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.all(4.r),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 19.r,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Dedicated Download Button for un-downloaded language
                  Semantics(
                    button: true,
                    label: 'Download $lang pack',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onDownloadButtonTapped(lang),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_download_rounded,
                            size: 20.r,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
