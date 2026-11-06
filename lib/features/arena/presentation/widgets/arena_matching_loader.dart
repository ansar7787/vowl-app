import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

/// Modern clashing-swords loader with animated radar pulse and dynamic status copy.
/// Replaces outdated default circular progress indicators for all Arena matching & loading states.
class ArenaMatchingLoader extends StatefulWidget {
  final String? roomCode;
  final String? customMessage;
  final bool showShareCode;

  const ArenaMatchingLoader({
    super.key,
    this.roomCode,
    this.customMessage,
    this.showShareCode = false,
  });

  @override
  State<ArenaMatchingLoader> createState() => _ArenaMatchingLoaderState();
}

class _ArenaMatchingLoaderState extends State<ArenaMatchingLoader>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _swordController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _swordRotation;

  int _messageIndex = 0;
  static const List<String> _statusMessages = [
    'Searching for a challenger...',
    'Synchronizing arena duel chamber...',
    'Sharpening vocabulary blades...',
    'Matching skill ratings & discipline...',
    'Preparing speed questions...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _swordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _swordRotation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _swordController, curve: Curves.easeInOut),
    );

    // Message rotation timer
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.forward && mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _statusMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _swordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isDark ? AppColors.slate700 : AppColors.slate200;
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    final displayMessage = widget.customMessage ?? _statusMessages[_messageIndex];

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: borderColor, width: 1.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Clashing Blades with Pulsing Radar Rings
              SizedBox(
                width: 120.r,
                height: 120.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Radar Waves
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale1 = 0.8 + (_pulseAnimation.value * 0.45);
                        final opacity1 = (1.0 - _pulseAnimation.value).clamp(0.0, 1.0);
                        return Container(
                          width: 110.r * scale1,
                          height: 110.r * scale1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.indigo500.withValues(alpha: opacity1 * 0.5),
                              width: 2.r,
                            ),
                          ),
                        );
                      },
                    ),

                    // Inner Core Glow
                    Container(
                      width: 74.r,
                      height: 74.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.indigo500, AppColors.indigo600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo500.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Clashing Swords Icon with Rocking Rotation
                    AnimatedBuilder(
                      animation: _swordRotation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _swordRotation.value * math.pi,
                          child: Icon(
                            LucideIcons.swords,
                            size: 34.sp,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Title Header
              Text(
                '1v1 ARENA MATCHMAKING',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.indigo500,
                ),
              ),
              SizedBox(height: 6.h),

              // Dynamic Status Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  displayMessage,
                  key: ValueKey(displayMessage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),
              ),

              if (widget.showShareCode && widget.roomCode != null) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROOM CODE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: textSecondary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.roomCode!.toUpperCase(),
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.all(6.r),
                            constraints: const BoxConstraints(),
                            icon: Icon(LucideIcons.copy, size: 18.sp, color: AppColors.indigo500),
                            tooltip: 'Copy Code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.roomCode!.toUpperCase()));
                              CustomSnackBar.show(
                                context: context,
                                message: 'Room code copied to clipboard! Share it with a friend.',
                                type: CustomSnackBarType.success,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.all(6.r),
                            constraints: const BoxConstraints(),
                            icon: Icon(LucideIcons.share2, size: 18.sp, color: AppColors.indigo500),
                            tooltip: 'Share Duel Invite',
                            onPressed: () {
                              final code = widget.roomCode!.toUpperCase();
                              SharePlus.instance.share(
                                ShareParams(
                                  text: '⚔️ I\'m waiting for you in the Vowl 1v1 Arena!\n'
                                      'Room Code: $code\n\n'
                                      'Tap the link to join our vocabulary duel:\n'
                                      'https://vowl-acbc5.web.app/duel/$code',
                                  subject: '⚔️ 1v1 Vocabulary Duel Challenge',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Waiting for your friend to enter this code in Vowl...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
