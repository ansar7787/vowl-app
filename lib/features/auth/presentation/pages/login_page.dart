import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/features/auth/presentation/widgets/login_widgets.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _passwordKey = GlobalKey<FormFieldState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final ValueNotifier<int> _emailShake = ValueNotifier(0);
  final ValueNotifier<int> _passwordShake = ValueNotifier(0);

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailShake.dispose();
    _passwordShake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.isSuccess != current.isSuccess ||
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage,
          listener: (context, state) {
            if (state.isSuccess) {
              context.read<AuthBloc>().add(const AuthReloadUser());
              // Do nothing. We rely on GoRouter's automatic redirect (refreshListenable)
              // which evaluates _redirect in app_router.dart when AuthBloc completes its
              // backend synchronization. This ensures the LoadingOverlay remains perfectly
              // visible without flashing the login form during the transition.
            }
            if (state.errorMessage != null) {
              // errorMessage is a stable code (from AuthErrorHandler.getKey),
              // never already-localized text, so checking for a "cancel"-style
              // code here is locale-independent — this runs before
              // _showSnackBar's context.tr() call translates it for display.
              final isWarning = state.errorMessage!.contains('cancel');
              _showSnackBar(
                context,
                state.errorMessage!,
                isWarning
                    ? CustomSnackBarType.warning
                    : CustomSnackBarType.error,
              );
            }
            if (state.successMessage != null) {
              _showSnackBar(
                context,
                state.successMessage!,
                CustomSnackBarType.success,
              );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            try {
              Haptics.vibrate(HapticsType.success);
            } catch (_) {}
            _showSnackBar(context, state.message!, CustomSnackBarType.success);
          },
        ),
      ],
      // Separate ThemeCubit watch from LoginCubit watch to prevent
      // theme changes from triggering full LoginCubit rebuilds.
      child: BlocSelector<ThemeCubit, ThemeState, bool>(
        selector: (themeState) => themeState.isMidnight,
        builder: (context, isMidnight) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isMidnight
              ? const Color(0xFF000000)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return BlocBuilder<LoginCubit, LoginState>(
            buildWhen: (previous, current) =>
                previous.password != current.password ||
                previous.isSubmitting != current.isSubmitting ||
                previous.isSuccess != current.isSuccess,
            builder: (context, state) {
              final contrastColor = MeshGradientBackground.getContrastColor(
                context,
              );
              final secondaryColor = contrastColor.withValues(alpha: 0.6);

              return LoadingOverlay(
                isLoading: state.isSubmitting || state.isSuccess,
                message: context.tr(
                  'auth.preparing_adventure',
                  fallback: 'Getting things ready...',
                ),
                child: Scaffold(
                  backgroundColor: bgColor,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      ListenableBuilder(
                        listenable: _passwordFocus,
                        builder: (context, _) {
                          Color? auraColor;
                          if (_passwordFocus.hasFocus &&
                              state.password.isNotEmpty) {
                            if (state.password.length < 6) {
                              auraColor = Colors.red;
                            } else if (state.password.length < 10) {
                              auraColor = Colors.blue;
                            } else {
                              auraColor = Colors.green;
                            }
                          }
                          return MeshGradientBackground(auraColor: auraColor);
                        },
                      ),
                      SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                    20.h,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 10.h,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // --- Header: Brand (Perfectly Centered) ---
                                        Hero(
                                          tag: 'auth_title',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'Vowl',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 48.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(
                                                    0xFF6366F1,
                                                  ), // Solid premium brand color
                                                  letterSpacing: -1.5,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 36.h,
                                        ), // Perfect premium gap without disconnecting the UI
                                        // --- Interactive Form Card ---
                                        Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.topCenter,
                                          children: [
                                            // The card itself, pushed down slightly so the mascot can straddle the top border
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 30.r,
                                              ),
                                              child: HolographicCard(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    ValueListenableBuilder<int>(
                                                      valueListenable:
                                                          _emailShake,
                                                      builder:
                                                          (
                                                            context,
                                                            shakeCount,
                                                            child,
                                                          ) {
                                                            return ShakeableWrapper(
                                                              shakeCount:
                                                                  shakeCount,
                                                              child: child!,
                                                            );
                                                          },
                                                      child: LoginEmailInput(
                                                        fieldKey: _emailKey,
                                                        focusNode: _emailFocus,
                                                      ),
                                                    ),
                                                    SizedBox(height: 16.h),
                                                    ValueListenableBuilder<int>(
                                                      valueListenable:
                                                          _passwordShake,
                                                      builder:
                                                          (
                                                            context,
                                                            shakeCount,
                                                            child,
                                                          ) {
                                                            return ShakeableWrapper(
                                                              shakeCount:
                                                                  shakeCount,
                                                              child: child!,
                                                            );
                                                          },
                                                      child: LoginPasswordInput(
                                                        fieldKey: _passwordKey,
                                                        formKey: _formKey,
                                                        focusNode:
                                                            _passwordFocus,
                                                      ),
                                                    ),
                                                    Align(
                                                      // AlignmentDirectional.centerEnd,
                                                      // not Alignment.centerRight —
                                                      // the latter is a physical
                                                      // (non-mirroring) alignment
                                                      // that would stay pinned to
                                                      // the visual right even in
                                                      // Arabic, where this link
                                                      // should sit on the visual
                                                      // left (the "end" of the
                                                      // line in an RTL layout).
                                                      alignment:
                                                          AlignmentDirectional
                                                              .centerEnd,
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            context.push(
                                                              AppRouter
                                                                  .forgotPasswordRoute,
                                                            ),
                                                        style: TextButton.styleFrom(
                                                          minimumSize:
                                                              const Size(
                                                                48,
                                                                48,
                                                              ),
                                                          splashFactory: NoSplash
                                                              .splashFactory,
                                                          overlayColor: Colors
                                                              .transparent,
                                                        ),
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            context.tr(
                                                              'auth.forgot_password_question',
                                                              fallback:
                                                                  'Forgot your password?',
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  color: Color(
                                                                    0xFF6366F1,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    LoginButton(
                                                      formKey: _formKey,
                                                      onValidationError: () {
                                                        try {
                                                          Haptics.vibrate(
                                                            HapticsType.error,
                                                          );
                                                        } catch (_) {}
                                                        if (!(_emailKey
                                                                .currentState
                                                                ?.validate() ??
                                                            true)) {
                                                          _emailShake.value++;
                                                        }
                                                        if (!(_passwordKey
                                                                .currentState
                                                                ?.validate() ??
                                                            true)) {
                                                          _passwordShake
                                                              .value++;
                                                        }
                                                      },
                                                    ),
                                                    SizedBox(height: 16.h),
                                                    const GoogleLoginButton(),
                                                  ],
                                                ),
                                              ),
                                            ), // Close Padding
                                            Positioned(
                                              top: 0,
                                              child: VowlBotAuthCompanion(
                                                emailFocus: _emailFocus,
                                                passwordFocus: _passwordFocus,
                                                size: 60,
                                              ),
                                            ),
                                          ],
                                        ), // Close Stack
                                        SizedBox(height: 16.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // FittedBox ensures the text
                                            // scales down on narrow devices
                                            // instead of overflowing.
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  context.tr(
                                                    'auth.no_account_prompt',
                                                    fallback: 'New to Vowl?',
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    color: secondaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => context.push(
                                                AppRouter.signupRoute,
                                              ),
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(48, 48),
                                                splashFactory:
                                                    NoSplash.splashFactory,
                                                overlayColor:
                                                    Colors.transparent,
                                              ),
                                              child: Text(
                                                context.tr(
                                                  'auth.signup',
                                                  fallback: 'Sign Up',
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: Color(0xFF6366F1),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    CustomSnackBarType type,
  ) {
    CustomSnackBar.show(
      context: context,
      message: context.tr(message),
      type: type,
    );
  }
}
