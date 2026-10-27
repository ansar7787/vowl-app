import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Modal bottom sheet allowing users to customize speech pronunciation voice style.
/// Designed with responsive layout to prevent overflows across all screen sizes and text scales.
/// Supports Freemium monetization: free users can preview all voices, while premium voices
/// gracefully trigger [AppRouter.premiumRoute] when tapped for selection.
class TtsVoiceSelectionBottomSheet extends StatefulWidget {
  final TtsVoicePreset initialPreset;
  final bool? isPremium;
  final bool showUpgradePaywall;

  const TtsVoiceSelectionBottomSheet({
    super.key,
    required this.initialPreset,
    this.isPremium,
    this.showUpgradePaywall = true,
  });

  static Future<TtsVoicePreset?> show(
    BuildContext context, {
    required TtsVoicePreset currentPreset,
    bool? isPremium,
    bool showUpgradePaywall = true,
  }) async {
    final result = await showModalBottomSheet<TtsVoicePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TtsVoiceSelectionBottomSheet(
        initialPreset: currentPreset,
        isPremium: isPremium,
        showUpgradePaywall: showUpgradePaywall,
      ),
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
  String? _currentlyPlayingId;
  StreamSubscription<AuthState>? _authSubscription;

  bool get _isPremium {
    try {
      if (di.sl.isRegistered<AuthBloc>()) {
        final blocUser = di.sl<AuthBloc>().state.user;
        if (blocUser != null) {
          return blocUser.isPremium;
        }
      }
    } catch (_) {}
    if (widget.isPremium != null) return widget.isPremium!;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedPreset = (widget.initialPreset.isPremium && !_isPremium)
        ? TtsVoicePreset.clearGuide
        : widget.initialPreset;

    try {
      if (di.sl.isRegistered<AuthBloc>()) {
        _authSubscription = di.sl<AuthBloc>().stream.listen((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    try {
      if (di.sl.isRegistered<TtsService>()) {
        unawaited(di.sl<TtsService>().stop());
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _playPreview(TtsVoicePreset preset) async {
    di.sl<HapticService>().light();

    // Toggle stop if already playing the current preset
    if (_currentlyPlayingId == preset.id) {
      try {
        if (di.sl.isRegistered<TtsService>()) {
          await di.sl<TtsService>().stop();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
      return;
    }

    setState(() {
      _currentlyPlayingId = preset.id;
    });

    final targetId = preset.id;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().previewPreset(
          preset,
          onDone: () {
            if (mounted && _currentlyPlayingId == targetId) {
              setState(() {
                _currentlyPlayingId = null;
              });
            }
          },
          onError: (_) {
            if (mounted && _currentlyPlayingId == targetId) {
              setState(() {
                _currentlyPlayingId = null;
              });
            }
          },
        );
      }
    } catch (_) {
      if (mounted && _currentlyPlayingId == targetId) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    }
  }

  Future<void> _selectPreset(TtsVoicePreset preset) async {
    // If the voice is premium and user is on free tier, handle upsell or info
    if (preset.isPremium && !_isPremium) {
      di.sl<HapticService>().selection();
      try {
        if (di.sl.isRegistered<TtsService>()) {
          await di.sl<TtsService>().stop();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
      if (!mounted) return;

      if (!widget.showUpgradePaywall) {
        // Post-signup/login mode: Do not show hard paywall. Show polite informational guidance.
        _showPostSignupVoiceInfoDialog();
        return;
      }

      // Settings mode: Navigate directly to the full Premium screen
      await context.push(AppRouter.premiumRoute);

      // Re-check premium status upon return and refresh UI immediately
      if (mounted) {
        setState(() {});
        if (_isPremium) {
          await _applyPresetSelection(preset);
        }
      }
      return;
    }

    await _applyPresetSelection(preset);
  }

  void _showPostSignupVoiceInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        icon: Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: AppColors.amber500.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.crown, color: AppColors.amber500, size: 24.r),
        ),
        title: Text(
          'Premium Voice Accent',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Free accounts start with standard natural voices. You can unlock British, US, Australian, and Indian accents anytime with Vowl Premium.\n\nIf you already have a Premium subscription, simply log in to get full instant access.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyPresetSelection(TtsVoicePreset preset) async {
    if (_selectedPreset == preset) return;

    di.sl<HapticService>().selection();
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().stop();
      }
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
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().stop();
      }
    } catch (_) {}
    final safePreset = (_selectedPreset.isPremium && !_isPremium)
        ? TtsVoicePreset.clearGuide
        : _selectedPreset;
    Navigator.of(context).pop(safePreset);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isUserPremium = _isPremium;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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

                // No Engine Warning Banner (Empty/Degraded State)
                if (di.sl.isRegistered<TtsService>() &&
                    di.sl<TtsService>().engineStatus ==
                        TtsEngineStatus.noEngine)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.rose500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: AppColors.rose500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.rose500,
                          size: 20.r,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'No Text-to-Speech engine detected on this device. Voice previews and audio may be unavailable until a speech engine is installed in system settings.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Voice Preset Option Cards
                ...TtsVoicePreset.values.map((preset) {
                  final isLocked = preset.isPremium && !isUserPremium;
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
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
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

                              // Title, Badges and Subtitle
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
                                        if (preset.isPremium)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF261D0C)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(5.r),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF453314)
                                                    : const Color(0xFFFDE68A),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.crown,
                                                  size: 9.r,
                                                  color: isDark
                                                      ? const Color(0xFFFBBF24)
                                                      : const Color(0xFFD97706),
                                                ),
                                                SizedBox(width: 3.w),
                                                Text(
                                                  isUserPremium
                                                      ? 'UNLOCKED'
                                                      : 'PRO',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFFBBF24,
                                                          )
                                                        : const Color(
                                                            0xFFD97706,
                                                          ),
                                                  ),
                                                ),
                                              ],
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

                              // Interactive Audio Preview Button (Always available for preview)
                              _AudioPreviewButton(
                                isPlaying: isPlaying,
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () => _playPreview(preset),
                              ),

                              SizedBox(width: 8.w),

                              // Selection or Lock Indicator
                              if (isLocked)
                                Container(
                                  width: 22.r,
                                  height: 22.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black12,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.lock,
                                    size: 11.r,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                )
                              else
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
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      Icons.check,
                                      size: 14.r,
                                      color: Colors.white,
                                    ),
                                  ),
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
                                    0.5 * math.sin((val + 0.33) * 2 * math.pi));
                        final h3 =
                            5.0 +
                            6.5 *
                                (0.5 +
                                    0.5 * math.sin((val + 0.66) * 2 * math.pi));

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
