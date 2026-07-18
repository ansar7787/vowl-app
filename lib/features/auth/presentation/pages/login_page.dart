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

  int _emailShake = 0;
  int _passwordShake = 0;

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
            // Previously had no buildWhen at all, so this entire subtree
            // (gradient background, holographic card, every child widget)
            // rebuilt on *every* LoginState change — including typing in the
            // email field, which this builder's own output never depends on.
            // The individual field widgets already scope their own rebuilds
            // precisely (see LoginEmailInput/LoginPasswordInput's buildWhen);
            // this builder only needs to react to what it actually reads
            // below: password (for the aura color) and the submit/success
            // flags (for the loading overlay).
            buildWhen: (previous, current) =>
                previous.password != current.password ||
                previous.isSubmitting != current.isSubmitting ||
                previous.isSuccess != current.isSuccess,
            builder: (context, state) {
              final contrastColor = MeshGradientBackground.getContrastColor(
                context,
              );
              final secondaryColor = contrastColor.withValues(alpha: 0.6);

              Color? auraColor;
              if (_passwordFocus.hasFocus && state.password.isNotEmpty) {
                if (state.password.length < 6) {
                  auraColor = Colors.red;
                } else if (state.password.length < 10) {
                  auraColor = Colors.blue;
                } else {
                  auraColor = Colors.green;
                }
              }

              return LoadingOverlay(
                isLoading: state.isSubmitting || state.isSuccess,
                message: context.tr(
                  'auth.preparing_adventure',
                  fallback: 'Preparing your adventure...',
                ),
                child: Scaffold(
                  backgroundColor: bgColor,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      MeshGradientBackground(auraColor: auraColor),
                      SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final keyboardOpen =
                                MediaQuery.of(context).viewInsets.bottom > 0;
                            return SingleChildScrollView(
                              physics: keyboardOpen
                                  ? const BouncingScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),
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
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            VowlBotAuthCompanion(
                                              emailFocus: _emailFocus,
                                              passwordFocus: _passwordFocus,
                                              size: 60,
                                            ),
                                            SizedBox(width: 8.w),
                                            // 'Vowl' is the app's brand name —
                                            // deliberately not localized, same
                                            // as everywhere else it appears.
                                            Hero(
                                              tag: 'auth_title',
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Text(
                                                  'Vowl',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 44.sp,
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(
                                                      0xFF6366F1,
                                                    ),
                                                    letterSpacing: -1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          context.tr(
                                            'auth.login_subtitle',
                                            fallback:
                                                'Welcome back! Your journey continues here.',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 32.h),
                                        HolographicCard(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ShakeableWrapper(
                                                shakeCount: _emailShake,
                                                child: LoginEmailInput(
                                                  fieldKey: _emailKey,
                                                  focusNode: _emailFocus,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              ShakeableWrapper(
                                                shakeCount: _passwordShake,
                                                child: LoginPasswordInput(
                                                  fieldKey: _passwordKey,
                                                  formKey: _formKey,
                                                  focusNode: _passwordFocus,
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
                                                alignment: AlignmentDirectional
                                                    .centerEnd,
                                                child: TextButton(
                                                  onPressed: () => context.go(
                                                    AppRouter
                                                        .forgotPasswordRoute,
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    minimumSize: const Size(
                                                      48,
                                                      48,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    context.tr(
                                                      'auth.forgot_password_question',
                                                      fallback:
                                                          'Forgot your password?',
                                                    ),
                                                    style: const TextStyle(
                                                      fontFamily: 'Outfit',
                                                      color: Color(0xFF6366F1),
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                  if (!(_emailKey.currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    setState(
                                                      () => _emailShake++,
                                                    );
                                                  }
                                                  if (!(_passwordKey
                                                          .currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    setState(
                                                      () => _passwordShake++,
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(height: 16.h),
                                              const GoogleLoginButton(),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 32.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Flexible + ellipsis: a longer
                                            // translation of this prompt on a
                                            // narrow (320px) device could
                                            // otherwise push this Row into a
                                            // RenderFlex overflow next to the
                                            // "Sign Up" button.
                                            Flexible(
                                              child: Text(
                                                context.tr(
                                                  'auth.no_account_prompt',
                                                  fallback:
                                                      'Don\'t have an account?',
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => context.go(
                                                AppRouter.signupRoute,
                                              ),
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(48, 48),
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
