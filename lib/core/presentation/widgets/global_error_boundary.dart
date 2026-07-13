import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Global widget-tree error boundary.
///
/// Intercepts [ErrorWidget.builder] at the framework level to catch widget
/// rendering errors. On error:
///  1. Immediately shows a minimal dark placeholder (context-free, no ScreenUtil).
///  2. Schedules a post-frame state update to display the full premium error UI.
///  3. On "Return to Base", clears the error flag and lets [child] rebuild.
///
/// IMPORTANT: Mount only **once** at the root. Multiple instances will override
/// each other's [ErrorWidget.builder] registration.
class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';
  late ErrorWidgetBuilder _originalErrorBuilder;

  @override
  void initState() {
    super.initState();
    _originalErrorBuilder = ErrorWidget.builder;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule a state update for the next frame — safe to call from any
      // Flutter framework callback since addPostFrameCallback is thread-safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = details.exceptionAsString();
          });
        }
      });
      // Return a minimal, context-free placeholder that does NOT rely on
      // ScreenUtil or Localizations (which may not be available at the
      // point where the framework calls this callback).
      return const _MinimalErrorFallback();
    };
  }

  @override
  void dispose() {
    // Restore the original global builder to prevent leaking our override.
    ErrorWidget.builder = _originalErrorBuilder;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _FullErrorScreen(
        errorMessage: _errorMessage,
        onRetry: () {
          if (mounted) {
            setState(() {
              _hasError = false;
              _errorMessage = '';
            });
          }
        },
      );
    }
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// Minimal placeholder — shown for one frame while the state update schedules.
// Must NOT use ScreenUtil, Localizations, or any BuildContext-dependent APIs.
// ---------------------------------------------------------------------------

class _MinimalErrorFallback extends StatelessWidget {
  const _MinimalErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF0F172A), child: SizedBox.expand());
  }
}

// ---------------------------------------------------------------------------
// Full premium error screen — shown once _hasError is true in build().
// Has full access to BuildContext, ScreenUtil, and Localizations.
// ---------------------------------------------------------------------------

class _FullErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _FullErrorScreen({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final truncated = errorMessage.length > 100
        ? '${errorMessage.substring(0, 100)}…'
        : errorMessage;

    return Semantics(
      label: context.tr('error.system_anomaly', fallback: 'System Anomaly Detected'),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: RepaintBoundary(
          // FIX (RESPONSIVENESS/ACCESSIBILITY): a fixed Column centered
          // directly in the viewport overflows at large accessibility
          // text-scale factors (up to 3.0x) or with longer translations of
          // the error copy, on small phones (320x568) - the same class of
          // issue already fixed on this app's other standalone status
          // pages (NoInternetPage, InsecureDeviceScreen, AppRouter's error
          // page). LayoutBuilder + SingleChildScrollView +
          // ConstrainedBox(minHeight) preserves the exact current centered
          // look whenever content fits, and only scrolls (instead of
          // overflowing) when it doesn't.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Text('🛸', style: TextStyle(fontSize: 80.sp)),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        context.tr('error.system_anomaly', fallback: 'System Anomaly Detected'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        truncated,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        context.tr('error.system_anomaly_description', fallback: 'Our systems encountered an unexpected error.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      Semantics(
                        button: true,
                        label: context.tr('error.return_to_base', fallback: 'Return to Base'),
                        child: ScaleButton(
                          onTap: onRetry,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 16.h,
                            ),
                            constraints: BoxConstraints(minHeight: 48.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              context.tr('error.return_to_base', fallback: 'Return to Base'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
