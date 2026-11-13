import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/app_update_dialog.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_update_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Root application scaffold wrapping top-level tab destinations in a stateful shell.
class MainWrapper extends StatefulWidget {
  /// Navigation shell governing indexed stack tab routing.
  final StatefulNavigationShell navigationShell;

  /// Creates a [MainWrapper] with [navigationShell].
  const MainWrapper({required this.navigationShell, super.key});

  @visibleForTesting
  static void resetSessionCheck() {
    _MainWrapperState._hasCheckedForUpdateThisSession = false;
  }

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  static bool _hasCheckedForUpdateThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    if (_hasCheckedForUpdateThisSession || !mounted) return;
    _hasCheckedForUpdateThisSession = true;

    if (!di.sl.isRegistered<AppUpdateService>()) return;

    final updateService = di.sl<AppUpdateService>();
    final updateInfo = await updateService.checkForUpdate();

    if (updateInfo.hasUpdate && mounted) {
      await AppUpdateDialog.show(context, updateInfo: updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    // Resilient safe-area clearance across all device form factors:
    // viewPaddingOf retains physical navigation bar hardware/software insets even if keyboard opens.
    final systemBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    // Adaptive bottom margin:
    // 1. Android 3-Button Navigation (systemBottom >= 36dp, typically 48-56dp):
    //    OS already renders a thick black system bar. Adding 6dp gives a tight, grounded
    //    cushion so the floating bar doesn't awkwardly float high in the sky.
    // 2. Gesture Pill / iOS Home Indicator (systemBottom between 16dp and 34dp):
    //    Adds 10dp cushion so quick thumb taps never accidentally trigger the system "Home" swipe.
    // 3. Hardware Button / Chin Bezel (systemBottom == 0):
    //    Guarantees at least 14dp clearance so the bar never collides with the physical screen bezel.
    final double adaptiveBottomMargin = systemBottom >= 36
        ? (systemBottom + 6.h)
        : (systemBottom > 0 ? (systemBottom + 10.h) : 14.h);

    // ─────────────────────────────────────────────────────────────────────────
    // WhatsApp iOS & Apple HIG Tab Bar Standard Geometry
    // ─────────────────────────────────────────────────────────────────────────
    const navBarHeight = 62.0;
    const cornerRadius = 31.0;

    final navDecoration = BoxDecoration(
      color: isMidnight
          ? Colors.black.withValues(alpha: 0.92)
          : (isDark
              ? AppColors.slate900.withValues(alpha: 0.88)
              : Colors.white.withValues(alpha: 0.92)),
      borderRadius: BorderRadius.circular(cornerRadius.r),
      border: Border.all(
        color: isMidnight
            ? Colors.white.withValues(alpha: 0.14)
            : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.slate200.withValues(alpha: 0.80)),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (isDark ? Colors.black : AppColors.indigo500)
              .withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: widget.navigationShell,
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          height: navBarHeight.h,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, adaptiveBottomMargin),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Premium Glass Surface (Optimized for 120fps hardware rasterizer)
              VowlMotion.lowAnimationModeOverride.value
                  ? Container(
                      height: navBarHeight.h,
                      decoration: navDecoration,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(cornerRadius.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          height: navBarHeight.h,
                          decoration: navDecoration,
                        ),
                      ),
                    ),

              // 2. Navigation Items (Fixed-Ratio Grid with 120Hz Implicit Animators)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  height: navBarHeight.h,
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: Row(
                      children: [
                        _buildNavItem(
                          context,
                          0,
                          LucideIcons.home,
                          context.tr('nav.home', fallback: 'Home'),
                        ),
                        _buildNavItem(
                          context,
                          1,
                          LucideIcons.gamepad2,
                          context.tr('nav.games', fallback: 'Games'),
                        ),
                        _buildNavItem(
                          context,
                          2,
                          LucideIcons.trophy,
                          context.tr('nav.ranks', fallback: 'Ranks'),
                        ),
                        _buildNavItem(
                          context,
                          3,
                          LucideIcons.user,
                          context.tr('nav.profile', fallback: 'Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).animateIf(
            context,
            (w) => w.animate().slideY(
              begin: 0.5,
              end: 0,
              duration: VowlMotion.entrance,
              curve: VowlMotion.entranceCurve,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.navigationShell.currentIndex == index;

    // Vowl Brand Palette
    final activeColor =
        isDark ? AppColors.indigo400 : AppColors.indigo600;
    final inactiveColor =
        isDark ? AppColors.slate400 : AppColors.slate500;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () => _onTap(context, index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // WhatsApp iOS Compact Pill Indicator
                    AnimatedContainer(
                      duration: VowlMotion.fast,
                      curve: Curves.easeOutCubic,
                      width: 48.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.indigo400.withValues(alpha: 0.20)
                                : AppColors.indigo500.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: _NavIconSpring(
                        icon: icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 23.r,
                        isSelected: isSelected,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // WhatsApp iOS 10.5sp Typography
                    AnimatedDefaultTextStyle(
                      duration: VowlMotion.fast,
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
                        letterSpacing: 0.15,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();

    if (widget.navigationShell.currentIndex == index) {
      final String? controllerName = switch (index) {
        0 => 'home',
        1 => 'games',
        2 =>
          di.sl.isRegistered<ScrollController>(instanceName: 'leaderboard')
              ? 'leaderboard'
              : 'ranks',
        3 => 'profile',
        _ => null,
      };

      if (controllerName != null &&
          di.sl.isRegistered<ScrollController>(instanceName: controllerName)) {
        final controller = di.sl<ScrollController>(
          instanceName: controllerName,
        );
        if (controller.hasClients) {
          controller.animateTo(
            0.0,
            duration: VowlMotion.slow,
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

/// Hardware-accelerated 120fps spring pop for navigation bar icons.
///
/// Executes an elastic micro-bounce on selection, then settles smoothly to 1.0x
/// so all icons remain optically identical in size at rest.
class _NavIconSpring extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isSelected;
  final bool reduceMotion;

  const _NavIconSpring({
    required this.icon,
    required this.color,
    required this.size,
    required this.isSelected,
    required this.reduceMotion,
  });

  @override
  State<_NavIconSpring> createState() => _NavIconSpringState();
}

class _NavIconSpringState extends State<_NavIconSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Idle at 1.0x -> Pops to 1.15x -> Settles smoothly back to 1.0x
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _NavIconSpring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected && !widget.reduceMotion) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return Icon(widget.icon, color: widget.color, size: widget.size);
    }
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
