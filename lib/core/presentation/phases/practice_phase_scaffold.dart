import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Guided application and exercise scaffold for all Practice phase screens.
///
/// Unlike the Test phase:
/// - Mistakes provide educational feedback rather than ending the run
/// - Hints and scaffolding are accessible
/// - Displays a prominent "✋ PRACTICE" phase indicator and progress tracker
class PracticePhaseScaffold extends StatelessWidget {
  /// Name of the game or topic (e.g. 'Word Gym', 'Nuance Practice').
  final String title;

  /// Game subtype or category identifier.
  final String gameType;

  /// Target curriculum level number.
  final int level;

  /// Current exercise index (0-based).
  final int currentExerciseIndex;

  /// Total number of exercises in this practice round.
  final int totalExercises;

  /// Content widget (active exercise interactive component).
  final Widget child;

  /// Callback invoked when the user finishes all practice exercises.
  final VoidCallback onComplete;

  /// Optional exit callback. Defaults to popping the current route.
  final VoidCallback? onExit;

  /// Optional hint tap callback.
  final VoidCallback? onHint;

  /// Whether a hint is available for the current exercise.
  final bool isHintAvailable;

  /// Primary button label (e.g. 'Next Exercise', 'Finish Practice').
  final String actionLabel;

  /// Whether the primary button is clickable.
  final bool isActionEnabled;

  const PracticePhaseScaffold({
    super.key,
    required this.title,
    required this.gameType,
    required this.level,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.child,
    required this.onComplete,
    this.onExit,
    this.onHint,
    this.isHintAvailable = false,
    this.actionLabel = 'Check & Continue',
    this.isActionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slate950 : AppColors.slate50;
    final progress = totalExercises > 0
        ? ((currentExerciseIndex + 1) / totalExercises).clamp(0.0, 1.0)
        : 0.0;

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
          title: 'QUIT PRACTICE?',
          description:
              'Your completed Learn phase is safe! You will only restart this practice session from exercise 1 when you return.',
          continueButtonText: 'KEEP PRACTICING',
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
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✋', style: TextStyle(fontSize: 11.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      'PRACTICE PHASE • LEVEL $level',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
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
        actions: [
          if (onHint != null)
            IconButton(
              icon: Icon(
                Icons.lightbulb_outline_rounded,
                color: isHintAvailable ? Colors.amber : (isDark ? AppColors.slate700 : AppColors.slate300),
              ),
              onPressed: isHintAvailable ? onHint : null,
              tooltip: 'Hint',
            ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6.h,
                  backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),
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
                    backgroundColor: Colors.amber.shade600,
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
