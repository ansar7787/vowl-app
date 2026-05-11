import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:go_router/go_router.dart';

class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Catch Flutter Framework errors within the widget tree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule a post-frame callback to update state safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = details.exceptionAsString();
          });
        }
      });
      return _buildErrorUI(details.exceptionAsString());
    };
  }

  Widget _buildErrorUI(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🛸",
                style: TextStyle(fontSize: 80.sp),
              ),
              SizedBox(height: 24.h),
              Text(
                "SYSTEM ANOMALY",
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                error.length > 100 ? "${error.substring(0, 100)}..." : error,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Vowl encountered an unexpected cosmic event. Don't worry, your progress is safe!",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40.h),
              ScaleButton(
                onTap: () {
                  // Attempt to go home
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                  setState(() {
                    _hasError = false;
                    _errorMessage = "";
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "RETURN TO BASE",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorUI(_errorMessage);
    }
    return widget.child;
  }
}
