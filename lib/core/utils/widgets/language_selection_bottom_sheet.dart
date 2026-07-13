import 'dart:async';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
  State<LanguageSelectionBottomSheet> createState() => _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState extends State<LanguageSelectionBottomSheet> {
  String? _selectedLanguage;
  bool _isLoading = false;
  int _downloadProgress = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
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
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
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
                    child: Icon(LucideIcons.languages, color: primaryIndigo, size: 24.r),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('translation.first_time_title', fallback: 'Translation Language'),
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
                            fallback: 'We will translate in-game hints & explanations into this language.',
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
              SizedBox(height: 24.h),
              
              // Searchable-like List (Future proofing for search)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: ListView.separated(
                      padding: EdgeInsets.all(16.r),
                      itemCount: TranslationService.supportedLanguages.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final entry = TranslationService.supportedLanguages.entries.elementAt(index);
                        final isSelected = _selectedLanguage == entry.key;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selectedLanguage = entry.key),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryIndigo.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isSelected ? primaryIndigo.withValues(alpha: 0.5) : Colors.transparent,
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
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected 
                                          ? primaryIndigo 
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    Icon(LucideIcons.checkCircle2, color: primaryIndigo, size: 22.r),
                                ],
                              ),
                            ),
                          ),
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
                  label: context.tr('common.continue_text', fallback: 'Continue'),
                  child: ScaleButton(
                    onTap: (_selectedLanguage == null || _isLoading)
                        ? () {}
                        : () async {
                            setState(() => _isLoading = true);
                            _startFakeProgress();
                            final target = TranslationService.supportedLanguages[_selectedLanguage]!;
                            
                            try {
                              await TranslationService().setTargetLanguage(target);
                              _progressTimer?.cancel();
                              if (mounted) {
                                setState(() => _downloadProgress = 100);
                              }
                              // Add a tiny delay so user can see 100%
                              await Future.delayed(const Duration(milliseconds: 300));
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) setState(() => _isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('translation.error', fallback: 'Failed to set language')),
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
                        color: _selectedLanguage == null ? Colors.grey.withValues(alpha: 0.3) : primaryIndigo,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: _selectedLanguage != null
                            ? [
                                BoxShadow(
                                  color: primaryIndigo.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
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
                                          value: _downloadProgress == 0 ? null : _downloadProgress / 100,
                                          color: Colors.white,
                                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                                      context.tr('translation.downloading_short', fallback: 'Downloading...'),
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
                              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: Colors.white54)
                            : Text(
                                context.tr('common.continue_text', fallback: 'Continue').toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: _selectedLanguage == null ? Colors.grey.withValues(alpha: 0.8) : Colors.white,
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
}
