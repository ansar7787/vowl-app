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
import 'package:vowl/features/photo_vocabulary/domain/entities/visual_object_target.dart';

/// Interactive liquid-glass floating badge bar displaying detected computer
/// vision entities over the captured camera viewport with direct word bank saving.
class VisualObjectBadges extends StatefulWidget {
  final List<VisualObjectTarget> objects;
  final VisualObjectTarget? selectedObject;
  final ValueChanged<VisualObjectTarget> onSelectObject;
  final VoidCallback onStartChallenge;

  const VisualObjectBadges({
    super.key,
    required this.objects,
    required this.selectedObject,
    required this.onSelectObject,
    required this.onStartChallenge,
  });

  @override
  State<VisualObjectBadges> createState() => _VisualObjectBadgesState();
}

class _VisualObjectBadgesState extends State<VisualObjectBadges> {
  final WordBankBridge _wordBankBridge = const WordBankBridge();
  bool _isSaved = false;

  @override
  void didUpdateWidget(covariant VisualObjectBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedObject != oldWidget.selectedObject &&
        widget.selectedObject != null) {
      _isSaved = _wordBankBridge.isWordSaved(widget.selectedObject!.label);
    }
  }

  void _onSaveWord() async {
    final obj = widget.selectedObject;
    if (obj == null || _isSaved) return;

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    final success = await _wordBankBridge.saveWord(
      word: obj.label,
      phonetic: obj.ipa,
      partOfSpeech: obj.partOfSpeech,
      definition: obj.definition,
      example: obj.example,
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
    final obj = widget.selectedObject;
    if (obj == null) return;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl<SoundService>().playTts(obj.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected =
        widget.selectedObject ??
        (widget.objects.isNotEmpty ? widget.objects.first : null);

    if (widget.objects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Floating Object Badges Row ───────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.scanLine,
                          size: 14.r,
                          color: AppColors.teal500,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            context.tr(
                              'photo.detected_objects',
                              fallback: 'DETECTED IN PHOTO',
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.teal500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${widget.objects.length} ${context.tr('photo.items_found', fallback: 'items')}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Badges Wrap
              Wrap(
                spacing: 8.w,
                runSpacing: 10.h,
                children: widget.objects.map((obj) {
                  final isCurrent =
                      selected?.label.toLowerCase() == obj.label.toLowerCase();
                  final confidencePct = (obj.confidence * 100).round();

                  return ScaleButton(
                    onTap: () {
                      if (di.sl.isRegistered<HapticService>()) {
                        di.sl<HapticService>().selection();
                      }
                      widget.onSelectObject(obj);
                      setState(() {
                        _isSaved = _wordBankBridge.isWordSaved(obj.label);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: isCurrent
                            ? const LinearGradient(
                                colors: [
                                  AppColors.teal500,
                                  AppColors.indigo500,
                                ],
                              )
                            : null,
                        color: isCurrent
                            ? null
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.teal400
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: isCurrent ? 2.w : 1.w,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.teal500.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            obj.label,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '$confidencePct%',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white70
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Active Object Inspector Card ─────────────────────────────────────
        if (selected != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word & CEFR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.label.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (selected.ipa != null)
                                  Text(
                                    selected.ipa!,
                                    style: TextStyle(
                                      fontFamily: 'Spectral',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14.sp,
                                      color: AppColors.teal400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (selected.cefr != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal500.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: AppColors.teal500.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${selected.cefr} Level',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal400,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Definition & Example
                      Text(
                        selected.definition,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      if (selected.example.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          '"${selected.example}"',
                          style: TextStyle(
                            fontFamily: 'Spectral',
                            fontStyle: FontStyle.italic,
                            fontSize: 13.sp,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),

                      // Action Buttons
                      Row(
                        children: [
                          ScaleButton(
                            onTap: _onPronounce,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(
                                LucideIcons.volume2,
                                size: 18.r,
                                color: AppColors.teal400,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ScaleButton(
                              onTap: _onSaveWord,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  gradient: _isSaved
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            AppColors.indigo500,
                                            AppColors.teal500,
                                          ],
                                        ),
                                  color: _isSaved
                                      ? (isDark
                                            ? Colors.white12
                                            : Colors.black12)
                                      : null,
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSaved
                                          ? LucideIcons.checkCheck
                                          : LucideIcons.bookmarkPlus,
                                      size: 16.r,
                                      color: _isSaved
                                          ? AppColors.teal400
                                          : Colors.white,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      _isSaved
                                          ? 'In Word Bank ✓'
                                          : 'Add to Word Bank',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: _isSaved
                                            ? (isDark
                                                  ? Colors.white70
                                                  : Colors.black87)
                                            : Colors.white,
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

                      // Snap-to-Quiz Challenge Launch
                      ScaleButton(
                        onTap: widget.onStartChallenge,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.teal500, AppColors.indigo500],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal500.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.gamepad2,
                                size: 18.r,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  'Play 3-Question Snap Challenge (+10 Coins)',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
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
            ),
          ),
      ],
    );
  }
}
