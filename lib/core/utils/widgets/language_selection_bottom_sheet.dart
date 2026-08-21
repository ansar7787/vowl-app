import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';

/// A sleek 2026 glassmorphic bottom sheet for selecting the native translation language.
class LanguageSelectionBottomSheet extends StatefulWidget {
  const LanguageSelectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LanguageSelectionBottomSheet(),
    );
  }

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  String? _selectedLanguage;
  bool _isLoading = false;
  int _downloadProgress = 0;
  Timer? _progressTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _progressTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startFakeProgress() {
    setState(() => _downloadProgress = 0);
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_downloadProgress < 85) {
          _downloadProgress += 2;
        } else if (_downloadProgress < 95) {
          if (timer.tick % 3 == 0) _downloadProgress += 1;
        } else if (_downloadProgress < 99) {
          if (timer.tick % 10 == 0) _downloadProgress += 1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIndigo = const Color(0xFF6366F1);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.of(context).padding.bottom + 20.h,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Premium Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.languages,
                      color: primaryIndigo,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'translation.first_time_title',
                            fallback: 'Translation Language',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          context.tr(
                            'translation.language_selection_subtitle',
                            fallback:
                                'We will translate in-game hints & explanations into this language.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Auto-Detect Feature Button
              ScaleButton(
                onTap: () =>
                    _showAutoDetectDialog(context, isDark, primaryIndigo),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryIndigo.withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: primaryIndigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: primaryIndigo,
                        size: 20.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'translation.auto_detect',
                                fallback: 'Auto-Detect Language',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              context.tr(
                                'translation.auto_detect_desc',
                                fallback:
                                    'Type a sentence and we will find your language.',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 24.r,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Search field
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr(
                      'language_picker.search_hint',
                      fallback: 'Search languages...',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18.r,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.r,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Language List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Builder(
                      builder: (context) {
                        final filteredEntries = TranslationService
                            .supportedLanguages
                            .entries
                            .where(
                              (e) => e.key.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                        if (filteredEntries.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.r),
                              child: Text(
                                context.tr(
                                  'language_picker.no_results',
                                  fallback: 'No results found',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.all(16.r),
                          itemCount: filteredEntries.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            final isSelected = _selectedLanguage == entry.key;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(
                                  () => _selectedLanguage = entry.key,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryIndigo.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryIndigo.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16.sp,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? primaryIndigo
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        Icon(
                                          LucideIcons.checkCircle2,
                                          color: primaryIndigo,
                                          size: 22.r,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Premium CTA Button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: context.tr(
                    'common.continue_text',
                    fallback: 'Continue',
                  ),
                  child: ScaleButton(
                    onTap: (_selectedLanguage == null || _isLoading)
                        ? () {}
                        : () async {
                            setState(() => _isLoading = true);
                            _startFakeProgress();
                            final target = TranslationService
                                .supportedLanguages[_selectedLanguage]!;

                            try {
                              await di
                                  .sl<TranslationService>()
                                  .setTargetLanguage(target);
                              _progressTimer?.cancel();
                              if (mounted) {
                                setState(() => _downloadProgress = 100);
                              }
                              // Add a tiny delay so user can see 100%
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) setState(() => _isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr(
                                        'translation.error',
                                        fallback: 'Failed to set language',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFF43F5E),
                                  ),
                                );
                              }
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: _selectedLanguage == null
                            ? Colors.grey.withValues(alpha: 0.3)
                            : primaryIndigo,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: _selectedLanguage != null
                            ? [
                                BoxShadow(
                                  color: primaryIndigo.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: _isLoading
                            ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24.r,
                                        height: 24.r,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: _downloadProgress == 0
                                                  ? null
                                                  : _downloadProgress / 100,
                                              color: Colors.white,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.2),
                                              strokeWidth: 2.5,
                                            ),
                                            Text(
                                              '$_downloadProgress%',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 8.sp,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Flexible(
                                        child: Text(
                                          context.tr(
                                            'translation.downloading_short',
                                            fallback: 'Downloading...',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 1500.ms,
                                    color: Colors.white54,
                                  )
                            : Text(
                                context
                                    .tr(
                                      'common.continue_text',
                                      fallback: 'Continue',
                                    )
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: _selectedLanguage == null
                                      ? Colors.grey.withValues(alpha: 0.8)
                                      : Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
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

  void _showAutoDetectDialog(
    BuildContext context,
    bool isDark,
    Color primaryIndigo,
  ) {
    final TextEditingController typeController = TextEditingController();
    bool isDetecting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: primaryIndigo),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  context.tr(
                    'translation.type_sentence',
                    fallback: 'Type a Sentence',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  'translation.type_sentence_desc',
                  fallback:
                      'Type a short sentence in your native language, and ML Kit will automatically detect it.',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: typeController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Hola, ¿cómo estás?',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black26
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (isDetecting) ...[
                SizedBox(height: 16.h),
                const VowlButtonSpinner(color: Color(0xFF6366F1)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                context.tr('common.cancel', fallback: 'Cancel'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isDetecting
                  ? null
                  : () async {
                      final text = typeController.text.trim();
                      if (text.isEmpty) return;

                      setDialogState(() => isDetecting = true);
                      final bcpCode = await di
                          .sl<LanguageIdService>()
                          .identifyLanguage(text);

                      if (!mounted) return;

                      String? matchedLanguageName;
                      if (bcpCode != 'und') {
                        // Find the matching language in our supported list
                        for (final entry
                            in TranslationService.supportedLanguages.entries) {
                          if (entry.value.bcpCode.startsWith(bcpCode) ||
                              bcpCode.startsWith(entry.value.bcpCode)) {
                            matchedLanguageName = entry.key;
                            break;
                          }
                        }
                      }

                      if (!mounted) return;

                      setDialogState(() => isDetecting = false);
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }

                      if (!mounted) return;
                      if (matchedLanguageName != null) {
                        setState(() {
                          _selectedLanguage = matchedLanguageName;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Detected: $matchedLanguageName',
                                style: const TextStyle(fontFamily: 'Outfit'),
                              ),
                              backgroundColor: primaryIndigo,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  'translation.detect_failed',
                                  fallback:
                                      'Could not detect language confidently.',
                                ),
                                style: const TextStyle(fontFamily: 'Outfit'),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryIndigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                context.tr('translation.detect', fallback: 'Detect'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      ),
    ).then((_) {
      typeController.dispose();
    });
  }
}
