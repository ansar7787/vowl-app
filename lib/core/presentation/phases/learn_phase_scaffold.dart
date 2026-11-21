import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Standard, zero-stress UI scaffold for all Learn phase screens.
///
/// Unlike the Test phase, this scaffold:
/// - Has NO timer and NO lives
/// - Displays a prominent "🧠 LEARN" phase indicator
/// - Focuses purely on conceptual discovery, comprehension, and exploration
class LearnPhaseScaffold extends StatelessWidget {
  /// Name of the game or topic (e.g. 'Flashcards', 'Big vs Large').
  final String title;

  /// Game subtype or category identifier.
  final String gameType;

  /// Target curriculum level number.
  final int level;

  /// Content widget (teaching cards, interactive exploration, etc.).
  final Widget child;

  /// Callback invoked when the user finishes reviewing the learn material.
  final VoidCallback onComplete;

  /// Optional exit callback. Defaults to popping the current route.
  final VoidCallback? onExit;

  /// Label for the primary forward action button. Defaults to 'Got It! Continue'.
  final String actionLabel;

  /// Whether the complete action is currently enabled.
  final bool isActionEnabled;

  /// Optional action buttons displayed on the trailing side of the AppBar.
  final List<Widget>? actions;

  const LearnPhaseScaffold({
    super.key,
    required this.title,
    required this.gameType,
    required this.level,
    required this.child,
    required this.onComplete,
    this.onExit,
    this.actionLabel = 'Got It! Continue',
    this.isActionEnabled = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slate950 : AppColors.slate50;

    void handleExit() {
      if (di.sl.isRegistered<TtsService>()) {
        try {
          di.sl<TtsService>().stop();
        } catch (_) {}
      }
      if (onExit != null) {
        onExit!();
      } else {
        GameDialogHelper.showExitConfirmation(
          context,
          onQuit: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleExit();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: actions,
          leading: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
            onPressed: handleExit,
          ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🧠', style: TextStyle(fontSize: 11.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      'LEARN PHASE • LEVEL $level',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigo500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            // Bottom Action Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: isActionEnabled ? onComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? AppColors.slate800
                        : AppColors.slate200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
