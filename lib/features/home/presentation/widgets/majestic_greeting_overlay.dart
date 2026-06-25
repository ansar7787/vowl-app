import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

class MajesticGreetingOverlay extends StatelessWidget {
  final String mascotName;
  final String? accessoryId;
  final int level;
  final VoidCallback onDismiss;

  const MajesticGreetingOverlay({
    super.key,
    required this.mascotName,
    required this.level,
    required this.onDismiss,
    this.accessoryId,
  });

  @override
  Widget build(BuildContext context) {
    final greetingMessage = context.tr(
      'home.mascot_greeting_message',
      args: [mascotName],
    );

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Semantics(
        // Announce the whole overlay as a single dismissible alert so screen
        // readers don't have to traverse decorative mascot art separately.
        liveRegion: true,
        label: greetingMessage,
        child: GestureDetector(
          onTap: onDismiss,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The Mascot
                ExcludeSemantics(
                  child: VowlMascot(
                    state: VowlMascotState.happy,
                    size: 180.r,
                    level: level,
                    accessoryId: accessoryId,
                  ),
                ).animate().fadeIn().scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                ),

                SizedBox(height: 32.h),

                // The Greeting Card
                ExcludeSemantics(
                  child:
                      Container(
                            margin: EdgeInsets.symmetric(horizontal: 40.w),
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  context.tr('home.mascot_greeting_hoot'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.greenAccent.shade700,
                                    letterSpacing: 4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  greetingMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  context.tr('home.mascot_greeting_cta'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black26,
                                    letterSpacing: 2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.2, duration: 600.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
