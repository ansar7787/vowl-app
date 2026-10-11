import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Modal bottom sheet allowing users to customize speech pronunciation voice style.
class TtsVoiceSelectionBottomSheet extends StatefulWidget {
  final TtsVoicePreset initialPreset;

  const TtsVoiceSelectionBottomSheet({super.key, required this.initialPreset});

  static Future<TtsVoicePreset?> show(
    BuildContext context, {
    required TtsVoicePreset currentPreset,
  }) {
    return showModalBottomSheet<TtsVoicePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          TtsVoiceSelectionBottomSheet(initialPreset: currentPreset),
    );
  }

  @override
  State<TtsVoiceSelectionBottomSheet> createState() =>
      _TtsVoiceSelectionBottomSheetState();
}

class _TtsVoiceSelectionBottomSheetState
    extends State<TtsVoiceSelectionBottomSheet> {
  late TtsVoicePreset _selectedPreset;
  final FlutterTts _previewTts = FlutterTts();
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
  }

  @override
  void dispose() {
    _previewTts.stop();
    super.dispose();
  }

  Future<void> _playPreview(TtsVoicePreset preset) async {
    di.sl<HapticService>().light();
    setState(() {
      _currentlyPlayingId = preset.id;
    });

    try {
      await _previewTts.stop();
      await TtsVoiceHelper.applyPresetToTts(
        _previewTts,
        preset: preset,
        isKids: preset == TtsVoicePreset.friendlyTeacher,
      );
      final sample = TtsVoiceHelper.getSampleSentence(preset);
      await _previewTts.speak(sample);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentlyPlayingId = null;
      });
    }
  }

  Future<void> _selectPreset(TtsVoicePreset preset) async {
    di.sl<HapticService>().selection();
    await _previewTts.stop();
    setState(() {
      _selectedPreset = preset;
    });

    await TtsVoiceHelper.savePreset(preset);

    // Immediately reload both services without restarting the app
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().reloadVoice();
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        await di.sl<KidsTTSService>().reloadVoice();
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF13131A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 16.h,
            bottom: MediaQuery.of(context).padding.bottom + 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 18.h),

              // Title and Subtitle
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      LucideIcons.mic,
                      color: AppColors.indigo500,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pronunciation Voice',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Natural human voices powered by device speech engine',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Voice Preset Options
              ...TtsVoicePreset.values.map((preset) {
                final isSelected = _selectedPreset == preset;
                final isPlaying = _currentlyPlayingId == preset.id;

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    onTap: () => _selectPreset(preset),
                    borderRadius: BorderRadius.circular(20.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indigo500.withValues(
                                alpha: isDark ? 0.18 : 0.08,
                              )
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.indigo500
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06)),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Preset Icon
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.indigo500.withValues(alpha: 0.2)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              preset.icon,
                              size: 18.r,
                              color: isSelected
                                  ? AppColors.indigo500
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Title and Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      preset.title,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.indigo500
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (preset ==
                                        TtsVoicePreset.friendlyTeacher) ...[
                                      SizedBox(width: 6.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                        ),
                                        child: Text(
                                          'KIDS FAVORITE',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green.shade600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  preset.subtitle,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Live Audio Preview Button
                          Semantics(
                            button: true,
                            label: 'Listen to sample for ${preset.title}',
                            child: IconButton(
                              icon: isPlaying
                                  ? SizedBox(
                                      width: 18.r,
                                      height: 18.r,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.indigo500,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.volume2,
                                      size: 18.r,
                                      color: isSelected
                                          ? AppColors.indigo500
                                          : (isDark
                                                ? Colors.white54
                                                : Colors.black45),
                                    ),
                              onPressed: () => _playPreview(preset),
                              tooltip: 'Listen Sample',
                            ),
                          ),

                          // Selection Checkmark
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20.r,
                              color: AppColors.indigo500,
                            ).animate().scale(duration: 200.ms),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
