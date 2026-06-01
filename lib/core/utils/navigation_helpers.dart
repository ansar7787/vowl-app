import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Exposes shared transition animations to prevent white flashes and provide
/// premium, polished visual aesthetics during screen transitions.
class NavigationHelpers {
  NavigationHelpers._();

  // Premium animation configuration defaults
  static const Duration defaultForwardDuration = Duration(milliseconds: 250);
  static const Duration defaultReverseDuration = Duration(milliseconds: 200);
  static const Curve defaultCurve = Curves.easeInOut;

  /// Custom cross-fade page transition.
  ///
  /// Prevents blank frames/flashes by smoothly interpolating opacity.
  /// Generic type parameter [T] represents the optional return value on page pop.
  static Page<T> fadeTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = defaultForwardDuration,
    Duration reverseDuration = defaultReverseDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: curve).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  /// Premium sliding transition from the right (ideal for master-detail push steps).
  static Page<T> slideRightTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = defaultForwardDuration,
    Duration reverseDuration = defaultReverseDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: curve)).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  /// Premium bottom-up modal sheet sliding transition (ideal for full-screen dialogs).
  static Page<T> slideUpTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = defaultForwardDuration,
    Duration reverseDuration = defaultReverseDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: curve)).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  /// Premium dynamic zoom/scale transitions (ideal for quest completion panels).
  static Page<T> scaleTransitionPage<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = defaultForwardDuration,
    Duration reverseDuration = defaultReverseDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurveTween(curve: curve).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }
}

/// Kept top-level [fadeTransitionPage] for 100% backward compatibility
/// with existing routes in the app.
Page<T> fadeTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return NavigationHelpers.fadeTransitionPage<T>(
    child: child,
    state: state,
  );
}
