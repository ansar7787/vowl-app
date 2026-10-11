import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Modal bottom sheet allowing users to customize speech pronunciation voice style.
/// Designed with responsive layout to prevent overflows across all screen sizes and text scales.
class TtsVoiceSelectionBottomSheet extends StatefulWidget {
  final TtsVoicePreset initialPreset;

  const TtsVoiceSelectionBottomSheet({super.key, required this.initialPreset});

  static Future<TtsVoicePreset?> show(
    BuildContext context, {
    required TtsVoicePreset currentPreset,
  }) async {
    final result = await showModalBottomSheet<TtsVoicePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          TtsVoiceSelectionBottomSheet(initialPreset: currentPreset),
    );
    return result ?? await TtsVoiceHelper.getSavedPreset();
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

    _previewTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });

    _previewTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });

    _previewTts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    try {
      _previewTts.stop();
    } catch (_) {}
    super.dispose();
  }

  int _previewSessionId = 0;

  Future<void> _playPreview(TtsVoicePreset preset) async {
    di.sl<HapticService>().light();

    // Toggle stop if already playing the current preset
    if (_currentlyPlayingId == preset.id) {
      _previewSessionId++;
      try {
        await _previewTts.stop();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
      return;
    }

    final sessionId = ++_previewSessionId;

    try {
      await _previewTts.stop();
    } catch (_) {}
    if (!mounted || sessionId != _previewSessionId) return;

    setState(() {
      _currentlyPlayingId = preset.id;
    });

    try {
      await TtsVoiceHelper.applyPresetToTts(
        _previewTts,
        preset: preset,
        isKids: preset == TtsVoicePreset.friendlyTeacher,
      );
      if (!mounted || sessionId != _previewSessionId) return;

      final sample = TtsVoiceHelper.getSampleSentence(preset);
      await _previewTts.speak(sample);
    } catch (_) {
      if (mounted && sessionId == _previewSessionId) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    }
  }

  Future<void> _selectPreset(TtsVoicePreset preset) async {
    if (_selectedPreset == preset) return;

    di.sl<HapticService>().selection();
    _previewSessionId++;
    try {
      await _previewTts.stop();
    } catch (_) {}

    setState(() {
      _selectedPreset = preset;
      _currentlyPlayingId = null;
    });

    // Persist and synchronize services in the background without abruptly closing sheet
    await TtsVoiceHelper.savePreset(preset);

    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().reloadVoice();
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        await di.sl<KidsTTSService>().reloadVoice();
      }
    } catch (_) {}
  }

  void _closeSheet() {
    di.sl<HapticService>().light();
    try {
      _previewTts.stop();
    } catch (_) {}
    Navigator.of(context).pop(_selectedPreset);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
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
                        color: AppColors.indigo500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        LucideIcons.mic,
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
                            'Pronunciation Voice',
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
                            'Natural on-device voices for lessons & games',
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
                      onPressed: _closeSheet,
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
                SizedBox(height: 18.h),

                // Voice Preset Option Cards
                ...TtsVoicePreset.values.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  final isPlaying = _currentlyPlayingId == preset.id;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectPreset(preset),
                        borderRadius: BorderRadius.circular(16.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF1E2235)
                                    : const Color(0xFFF0F3FF))
                                : (isDark
                                    ? const Color(0xFF1A1C26)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.indigo500
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.black.withValues(alpha: 0.06)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Preset Icon
                              Container(
                                width: 38.r,
                                height: 38.r,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.indigo500.withValues(
                                          alpha: 0.15,
                                        )
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            )),
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                child: Icon(
                                  preset.icon,
                                  size: 19.r,
                                  color: isSelected
                                      ? AppColors.indigo500
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // Title, Badge and Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6.w,
                                      runSpacing: 2.h,
                                      children: [
                                        Text(
                                          preset.title,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : AppColors.indigo500)
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                          ),
                                        ),
                                        if (preset ==
                                            TtsVoicePreset.friendlyTeacher)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF14291E)
                                                  : const Color(0xFFE8F5E9),
                                              borderRadius:
                                                  BorderRadius.circular(5.r),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF1E462E)
                                                    : const Color(0xFFC8E6C9),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              'KIDS FAVORITE',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.4,
                                                color: isDark
                                                    ? const Color(0xFF81C784)
                                                    : const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      preset.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.5.sp,
                                        height: 1.25,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),

                              // Interactive Audio Preview Button
                              _AudioPreviewButton(
                                isPlaying: isPlaying,
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () => _playPreview(preset),
                              ),

                              SizedBox(width: 8.w),

                              // Selection Indicator (Radio / Checkmark)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22.r,
                                height: 22.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.indigo500
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.indigo500
                                        : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.2,
                                              )),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 14.r,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(height: 12.h),

                // Bottom Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ScaleButton(
                    onTap: _closeSheet,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.indigo500,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sleek 2026 audio preview button with dynamic equalizer wave animation.
/// Completely avoids legacy circular progress spinners.
class _AudioPreviewButton extends StatefulWidget {
  final bool isPlaying;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AudioPreviewButton({
    required this.isPlaying,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AudioPreviewButton> createState() => _AudioPreviewButtonState();
}

class _AudioPreviewButtonState extends State<_AudioPreviewButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AudioPreviewButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.indigo500;
    final idleColor = widget.isDark ? Colors.white54 : Colors.black45;

    return Tooltip(
      message: widget.isPlaying
          ? 'Stop voice sample'
          : 'Listen to voice sample',
      child: Semantics(
        button: true,
        label: widget.isPlaying
            ? 'Stop voice sample'
            : 'Listen to voice sample',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? activeColor.withValues(alpha: 0.12)
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: widget.isPlaying
                      ? activeColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: widget.isPlaying
                  ? AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final val = _controller.value;
                        final h1 =
                            5.0 +
                            7.0 * (0.5 + 0.5 * math.sin(val * 2 * math.pi));
                        final h2 =
                            5.0 +
                            9.0 *
                                (0.5 +
                                    0.5 *
                                        math.sin((val + 0.33) * 2 * math.pi));
                        final h3 =
                            5.0 +
                            6.5 *
                                (0.5 +
                                    0.5 *
                                        math.sin((val + 0.66) * 2 * math.pi));

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildBar(h1.r, activeColor),
                            SizedBox(width: 2.w),
                            _buildBar(h2.r, activeColor),
                            SizedBox(width: 2.w),
                            _buildBar(h3.r, activeColor),
                          ],
                        );
                      },
                    )
                  : Icon(
                      LucideIcons.volume2,
                      size: 16.r,
                      color: widget.isSelected ? activeColor : idleColor,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 2.5.w,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}
