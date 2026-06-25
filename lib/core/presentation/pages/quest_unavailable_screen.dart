import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Displayed when a requested quest cannot be loaded.
///
/// Adapts its button layout based on whether a [onRetry] callback is provided:
///  - With retry: shows primary "Try Again" + secondary "Exit Game".
///  - Without retry: shows a single "Back to Levels" primary button.
class QuestUnavailableScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;
  final String? technicalError;

  const QuestUnavailableScreen({
    super.key,
    this.onRetry,
    this.message,
    this.technicalError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedMessage =
        message ?? context.tr('quest_unavailable.default_message');

    return Scaffold(
      body: Stack(
        children: [
          MeshGradientBackground(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ───────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(32.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 80.r,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF475569),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // ── Title ──────────────────────────────────────────
                  Text(
                    context.tr('quest_unavailable.title'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16.h),

                  // ── Message ────────────────────────────────────────
                  Text(
                    resolvedMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // ── Debug error panel (debug builds only) ──────────
                  if (technicalError != null && kDebugMode) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        'TECHNICAL INFO:\n$technicalError',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 10.sp,
                          color: Colors.redAccent.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 40.h),

                  // ── Actions ────────────────────────────────────────
                  if (onRetry != null) ...[
                    _ActionButton.primary(
                      label: context.tr('games.try_again').toUpperCase(),
                      onTap: onRetry!,
                    ),
                    SizedBox(height: 16.h),
                    _ActionButton.secondary(
                      label: context.tr('quest_unavailable.exit_button'),
                      isDark: isDark,
                      onTap: () => context.pop(),
                    ),
                  ] else ...[
                    _ActionButton.primary(
                      label: context.tr('quest_unavailable.back_button'),
                      onTap: () => context.pop(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared action button — eliminates duplicated decoration code.
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool _isPrimary;
  final bool isDark;

  const _ActionButton.primary({required this.label, required this.onTap})
    : _isPrimary = true,
      isDark = false;

  const _ActionButton.secondary({
    required this.label,
    required this.onTap,
    required this.isDark,
  }) : _isPrimary = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          constraints: BoxConstraints(minHeight: 48.h),
          decoration: BoxDecoration(
            gradient: _isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  )
                : null,
            color: _isPrimary
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: _isPrimary
                    ? Colors.white
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF475569)),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
