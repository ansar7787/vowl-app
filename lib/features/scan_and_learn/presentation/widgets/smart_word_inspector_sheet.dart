import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/word_bank_bridge.dart';
import 'package:vowl/features/scan_and_learn/domain/entities/scanned_word_token.dart';
import 'package:vowl/features/scan_and_learn/utils/scan_vocabulary_dictionary.dart';

/// Modal bottom sheet providing deep vocabulary inspection, IPA phonetics,
/// audio pronunciation, Word Bank persistence, and instant challenge triggers.
class SmartWordInspectorSheet extends StatefulWidget {
  final ScannedWordToken token;
  final VoidCallback onStartChallenge;

  const SmartWordInspectorSheet({
    super.key,
    required this.token,
    required this.onStartChallenge,
  });

  static Future<void> show(
    BuildContext context, {
    required ScannedWordToken token,
    required VoidCallback onStartChallenge,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartWordInspectorSheet(
        token: token,
        onStartChallenge: onStartChallenge,
      ),
    );
  }

  @override
  State<SmartWordInspectorSheet> createState() => _SmartWordInspectorSheetState();
}

class _SmartWordInspectorSheetState extends State<SmartWordInspectorSheet> {
  bool _isSaved = false;
  late final WordBankBridge _wordBankBridge;

  @override
  void initState() {
    super.initState();
    _wordBankBridge = const WordBankBridge();
    _isSaved = _wordBankBridge.isWordSaved(widget.token.cleanWord);
  }

  void _onToggleSave() async {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    if (_isSaved) return;

    final entry = ScanVocabularyDictionary.getEntry(widget.token.cleanWord);
    final success = await _wordBankBridge.saveWord(
      word: widget.token.cleanWord,
      phonetic: widget.token.ipa,
      partOfSpeech: widget.token.partOfSpeech ?? 'noun',
      definition: widget.token.definition ?? entry.meaning,
      example: widget.token.grammarTip ?? entry.realWorldTip,
    );

    if (success && mounted) {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
      setState(() {
        _isSaved = true;
      });
    }
  }

  void _onPronounce() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl<SoundService>().playTts(widget.token.cleanWord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = ScanVocabularyDictionary.getEntry(widget.token.cleanWord);

    final String cefr = widget.token.cefr ?? _inferCefr(widget.token.cleanWord);
    final String definition = widget.token.definition ?? entry.meaning;
    final String tip = widget.token.grammarTip ?? entry.realWorldTip;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Word Header + CEFR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.token.cleanWord.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${entry.signCategory} • English',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$cefr Level',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigo400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Definition Card
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.45,
                      ),
                    ),
                    if (tip.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.lightbulb, size: 14.r, color: AppColors.amber500),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Action Buttons Row
              Row(
                children: [
                  // Pronounce button
                  ScaleButton(
                    onTap: _onPronounce,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.volume2, size: 18.r, color: AppColors.indigo400),
                          SizedBox(width: 6.w),
                          Text(
                            context.tr('common.audio', fallback: 'Listen'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Add to Word Bank button
                  Expanded(
                    child: ScaleButton(
                      onTap: _onToggleSave,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: _isSaved
                              ? null
                              : const LinearGradient(
                                  colors: [AppColors.indigo500, AppColors.teal500],
                                ),
                          color: _isSaved
                              ? (isDark ? Colors.white12 : Colors.black12)
                              : null,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSaved ? LucideIcons.checkCheck : LucideIcons.bookmarkPlus,
                              size: 18.r,
                              color: _isSaved ? AppColors.teal400 : Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _isSaved
                                  ? context.tr('word_bank.saved', fallback: 'In Word Bank ✓')
                                  : context.tr('word_bank.add', fallback: 'Add to Word Bank'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: _isSaved ? (isDark ? Colors.white70 : Colors.black87) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Instant 3-Question Snap Challenge Launch
              ScaleButton(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onStartChallenge();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.playCircle, size: 18.r, color: AppColors.teal400),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('scan.play_word_challenge', fallback: 'Play Snap Challenge on this word (+10 Coins)'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.teal400 : AppColors.teal500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _inferCefr(String word) {
    if (word.length <= 4) return 'A1';
    if (word.length <= 6) return 'A2';
    if (word.length <= 8) return 'B1';
    return 'B2';
  }
}
