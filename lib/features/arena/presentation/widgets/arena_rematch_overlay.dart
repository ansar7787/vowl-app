import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Floating banner/overlay displayed post-match when a PvP rival
/// sends a live rematch request, featuring a 15-second accept window.
class ArenaRematchOverlay extends StatefulWidget {
  final String requesterName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final int countdownSeconds;

  const ArenaRematchOverlay({
    super.key,
    required this.requesterName,
    required this.onAccept,
    required this.onDecline,
    this.countdownSeconds = 15,
  });

  @override
  State<ArenaRematchOverlay> createState() => _ArenaRematchOverlayState();
}

class _ArenaRematchOverlayState extends State<ArenaRematchOverlay> {
  late int _secondsLeft;
  Timer? _timer;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        if (!_handled) {
          _handled = true;
          widget.onDecline();
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.midnightSurface : Colors.white;
    final borderColor = AppColors.indigo500.withValues(alpha: 0.55);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  '⚔️ REMATCH REQUEST • ${_secondsLeft}s',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber500,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr(
                  'arena.rematch_request_title',
                  args: [widget.requesterName],
                  fallback: '${widget.requesterName} wants a rematch!',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'New 7-round Hybrid Pentathlon • Entry 30🪙',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: () {
                        if (_handled) return;
                        _handled = true;
                        _timer?.cancel();
                        widget.onDecline();
                      },
                      child: Container(
                        height: 44.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.rose500.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          context.tr(
                            'arena.rematch_decline',
                            fallback: 'Decline',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ScaleButton(
                      onTap: () {
                        if (_handled) return;
                        _handled = true;
                        _timer?.cancel();
                        widget.onAccept();
                      },
                      child: Container(
                        height: 44.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.indigo500, AppColors.indigo600],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.swords,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              context.tr(
                                'arena.rematch_accept',
                                fallback: 'Accept (30🪙)',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
