import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/features/auth/presentation/widgets/signup_widgets.dart';
import 'package:vowl/features/auth/presentation/widgets/login_widgets.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignUpCubit>(),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _passwordKey = GlobalKey<FormFieldState>();
  final _legalKey = GlobalKey<FormFieldState<bool>>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final ValueNotifier<int> _nameShake = ValueNotifier(0);
  final ValueNotifier<int> _emailShake = ValueNotifier(0);
  final ValueNotifier<int> _passwordShake = ValueNotifier(0);
  final ValueNotifier<int> _legalShake = ValueNotifier(0);
  final ValueNotifier<bool> _acceptedLegal = ValueNotifier(false);

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameShake.dispose();
    _emailShake.dispose();
    _passwordShake.dispose();
    _legalShake.dispose();
    _acceptedLegal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SignUpCubit, SignUpState>(
          listenWhen: (previous, current) =>
              previous.isSuccess != current.isSuccess ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.isSuccess) {
              context.read<AuthBloc>().add(const AuthReloadUser());
              // Do nothing. We rely on GoRouter's automatic redirect (refreshListenable)
              // which evaluates _redirect in app_router.dart when AuthBloc completes its
              // backend synchronization. This ensures the LoadingOverlay remains perfectly
              // visible without flashing any intermediate UI during the transition.
            }
            if (state.errorMessage != null) {
              _showSnackBar(
                context,
                state.errorMessage!,
                CustomSnackBarType.error,
              );
            }
          },
        ),
        // Added for parity with LoginPage's equivalent listener — AuthBloc
        // can independently emit a message (e.g. the new
        // AuthStreamErrorOccurred → 'auth.stream_error' path), and this
        // page previously had no way to surface that while the user was
        // still on the sign-up screen.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            _showSnackBar(context, state.message!, CustomSnackBarType.success);
          },
        ),
      ],
      // Separate ThemeCubit watch from SignUpCubit watch to prevent
      // theme changes from triggering full SignUpCubit rebuilds.
      child: BlocSelector<ThemeCubit, ThemeState, bool>(
        selector: (themeState) => themeState.isMidnight,
        builder: (context, isMidnight) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isMidnight
              ? const Color(0xFF000000)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return BlocBuilder<SignUpCubit, SignUpState>(
            // Same rebuild-scoping fix as LoginPage: previously rebuilt this
            // whole subtree on every keystroke in every field, even fields
            // this builder's own output doesn't depend on.
            buildWhen: (previous, current) =>
                previous.password != current.password ||
                previous.isSubmitting != current.isSubmitting ||
                previous.isSuccess != current.isSuccess,
            builder: (context, state) {
              final contrastColor = MeshGradientBackground.getContrastColor(
                context,
              );
              final secondaryColor = contrastColor.withValues(alpha: 0.6);

              // auraColor logic moved to ListenableBuilder below
              return LoadingOverlay(
                isLoading: state.isSubmitting || state.isSuccess,
                message: context.tr(
                  'auth.preparing_journey',
                  fallback: 'Preparing your journey...',
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
                                              nameFocus: _nameFocus,
                                              nameValue: state.name,
                                              emailFocus: _emailFocus,
                                              passwordFocus: _passwordFocus,
                                              size: 60,
                                              isSignup: true,
                                            ),
                                            SizedBox(width: 10.w),
                                            // 'Vowl' is the app's brand name —
                                            // deliberately not localized.
                                            Hero(
                                              tag: 'auth_title',
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Text(
                                                  'Vowl',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 48.sp,
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
                                            'auth.signup_subtitle',
                                            fallback:
                                                'Create an account to start your learning adventure.',
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
                                              ValueListenableBuilder<int>(
                                                valueListenable: _nameShake,
                                                builder:
                                                    (
                                                      context,
                                                      shakeCount,
                                                      child,
                                                    ) {
                                                      return ShakeableWrapper(
                                                        shakeCount: shakeCount,
                                                        child: child!,
                                                      );
                                                    },
                                                child: SignUpNameInput(
                                                  fieldKey: _nameKey,
                                                  focusNode: _nameFocus,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              ValueListenableBuilder<int>(
                                                valueListenable: _emailShake,
                                                builder:
                                                    (
                                                      context,
                                                      shakeCount,
                                                      child,
                                                    ) {
                                                      return ShakeableWrapper(
                                                        shakeCount: shakeCount,
                                                        child: child!,
                                                      );
                                                    },
                                                child: SignUpEmailInput(
                                                  fieldKey: _emailKey,
                                                  focusNode: _emailFocus,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              ValueListenableBuilder<int>(
                                                valueListenable: _passwordShake,
                                                builder:
                                                    (
                                                      context,
                                                      shakeCount,
                                                      child,
                                                    ) {
                                                      return ShakeableWrapper(
                                                        shakeCount: shakeCount,
                                                        child: child!,
                                                      );
                                                    },
                                                child: SignUpPasswordInput(
                                                  fieldKey: _passwordKey,
                                                  focusNode: _passwordFocus,
                                                ),
                                              ),
                                              SizedBox(height: 24.h),
                                              ValueListenableBuilder<int>(
                                                valueListenable: _legalShake,
                                                builder:
                                                    (
                                                      context,
                                                      shakeCount,
                                                      child,
                                                    ) {
                                                      return ShakeableWrapper(
                                                        shakeCount: shakeCount,
                                                        child: child!,
                                                      );
                                                    },
                                                child: FormField<bool>(
                                                  key: _legalKey,
                                                  initialValue: false,
                                                  validator: (value) {
                                                    if (value != true) {
                                                      return context.tr(
                                                        'auth.legal_consent_required',
                                                        fallback:
                                                            'You must agree to the Terms & Privacy Policy',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                  builder: (state) {
                                                    final isDark =
                                                        Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                              width: 24.r,
                                                              height: 24.r,
                                                              child: Checkbox(
                                                                value:
                                                                    state.value,
                                                                onChanged: (val) {
                                                                  state
                                                                      .didChange(
                                                                        val,
                                                                      );
                                                                  _acceptedLegal
                                                                          .value =
                                                                      val ??
                                                                      false;
                                                                },
                                                                activeColor:
                                                                    const Color(
                                                                      0xFF6366F1,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6.r,
                                                                      ),
                                                                ),
                                                                side: BorderSide(
                                                                  color:
                                                                      state
                                                                          .hasError
                                                                      ? Colors
                                                                            .red
                                                                      : (isDark
                                                                            ? Colors.white54
                                                                            : Colors.black54),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 12.w,
                                                            ),
                                                            Expanded(
                                                              child: GestureDetector(
                                                                onTap: () {
                                                                  state.didChange(
                                                                    !(state.value ??
                                                                        false),
                                                                  );
                                                                  _acceptedLegal
                                                                          .value =
                                                                      state
                                                                          .value ??
                                                                      false;
                                                                },
                                                                child: Text.rich(
                                                                  TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text: context.tr(
                                                                          'auth.i_agree_to',
                                                                          fallback:
                                                                              'I agree to the ',
                                                                        ),
                                                                        style: TextStyle(
                                                                          color:
                                                                              isDark
                                                                              ? Colors.white70
                                                                              : Colors.black87,
                                                                          fontSize:
                                                                              13.sp,
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        text: context.tr(
                                                                          'auth.terms_of_service',
                                                                          fallback:
                                                                              'Terms of Service',
                                                                        ),
                                                                        style: TextStyle(
                                                                          color: const Color(
                                                                            0xFF6366F1,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              13.sp,
                                                                        ),
                                                                        recognizer: TapGestureRecognizer()
                                                                          ..onTap = () async {
                                                                            final url = Uri.parse(
                                                                              context.tr(
                                                                                'settings.terms_url',
                                                                                fallback: 'https://ansar7787.github.io/vowl-legal/terms.html',
                                                                              ),
                                                                            );
                                                                            if (await canLaunchUrl(
                                                                              url,
                                                                            )) {
                                                                              await launchUrl(
                                                                                url,
                                                                                mode: LaunchMode.externalApplication,
                                                                              );
                                                                            }
                                                                          },
                                                                      ),
                                                                      TextSpan(
                                                                        text: context.tr(
                                                                          'auth.and',
                                                                          fallback:
                                                                              ' and ',
                                                                        ),
                                                                        style: TextStyle(
                                                                          color:
                                                                              isDark
                                                                              ? Colors.white70
                                                                              : Colors.black87,
                                                                          fontSize:
                                                                              13.sp,
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        text: context.tr(
                                                                          'auth.privacy_policy',
                                                                          fallback:
                                                                              'Privacy Policy',
                                                                        ),
                                                                        style: TextStyle(
                                                                          color: const Color(
                                                                            0xFF6366F1,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              13.sp,
                                                                        ),
                                                                        recognizer: TapGestureRecognizer()
                                                                          ..onTap = () async {
                                                                            final url = Uri.parse(
                                                                              context.tr(
                                                                                'settings.privacy_url',
                                                                                fallback: 'https://ansar7787.github.io/vowl-legal/privacy.html',
                                                                              ),
                                                                            );
                                                                            if (await canLaunchUrl(
                                                                              url,
                                                                            )) {
                                                                              await launchUrl(
                                                                                url,
                                                                                mode: LaunchMode.externalApplication,
                                                                              );
                                                                            }
                                                                          },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (state.hasError) ...[
                                                          SizedBox(height: 8.h),
                                                          Text(
                                                            state.errorText!,
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 12.sp,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: 32.h),
                                              SignUpButton(
                                                formKey: _formKey,
                                                onValidationError: () {
                                                  try {
                                                    Haptics.vibrate(
                                                      HapticsType.error,
                                                    );
                                                  } catch (_) {}
                                                  if (!(_nameKey.currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    _nameShake.value++;
                                                  }
                                                  if (!(_emailKey.currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    _emailShake.value++;
                                                  }
                                                  if (!(_passwordKey
                                                          .currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    _passwordShake.value++;
                                                  }
                                                  if (!(_legalKey.currentState
                                                          ?.validate() ??
                                                      true)) {
                                                    _legalShake.value++;
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
                                            // Flexible + ellipsis — same
                                            // overflow-safety reasoning as
                                            // LoginPage's equivalent Row.
                                            Flexible(
                                              child: Text(
                                                context.tr(
                                                  'auth.have_account_prompt',
                                                  fallback:
                                                      'Already have an account?',
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
                                              onPressed: () {
                                                if (context.canPop()) {
                                                  context.pop();
                                                } else {
                                                  context.go(
                                                    AppRouter.loginRoute,
                                                  );
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(48, 48),
                                              ),
                                              child: Text(
                                                context.tr(
                                                  'auth.login',
                                                  fallback: 'Log In',
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
