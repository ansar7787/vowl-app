import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:vowl/features/auth/presentation/widgets/forgot_password_widgets.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';

// ---------------------------------------------------------------------------
// Page — provides the dedicated [ForgotPasswordCubit]
// ---------------------------------------------------------------------------

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _emailFocus = FocusNode();

  final ValueNotifier<int> _emailShake = ValueNotifier(0);

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailShake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              _showSnackBar(
                context,
                state.successMessage!,
                CustomSnackBarType.success,
              );
            } else if (state.errorMessage != null) {
              _showSnackBar(
                context,
                state.errorMessage!,
                CustomSnackBarType.error,
              );
            }
          },
        ),
      ],
      child: BlocSelector<ThemeCubit, ThemeState, bool>(
        selector: (themeState) => themeState.isMidnight,
        builder: (context, isMidnight) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isMidnight
              ? const Color(0xFF000000)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
            // Previously rebuilt this entire subtree (gradient background,
            // holographic card, header, footer) on every keystroke in the
            // email field, even though this builder only actually reads
            // isSubmitting below — the email TextFormField manages its own
            // visible text internally and doesn't need this rebuild to
            // reflect what's typed.
            buildWhen: (previous, current) =>
                previous.isSubmitting != current.isSubmitting ||
                previous.isSuccess != current.isSuccess,
            builder: (context, state) {
              final contrastColor = MeshGradientBackground.getContrastColor(
                context,
              );
              final secondaryColor = contrastColor.withValues(alpha: 0.6);

              return LoadingOverlay(
                isLoading: state.isSubmitting,
                message: context.tr(
                  'auth.sending_recovery_link',
                  fallback: 'Sending recovery link...',
                ),
                child: Scaffold(
                  backgroundColor: bgColor,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      ListenableBuilder(
                        listenable: _emailFocus,
                        builder: (context, _) {
                          return MeshGradientBackground(
                            auraColor: _emailFocus.hasFocus ? Colors.blue : null,
                          );
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
                                        ForgotPasswordHeader(
                                          emailFocus: _emailFocus,
                                          secondaryColor: secondaryColor,
                                        ),
                                        SizedBox(height: 32.h),
                                        
                                        // --- Interactive Form Card ---
                                        Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.topCenter,
                                          children: [
                                            // Pushed down slightly so the mascot can straddle the top border
                                            Padding(
                                              padding: EdgeInsets.only(top: 30.r),
                                              child: HolographicCard(
                                          child: state.isSuccess
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .mark_email_read_outlined,
                                                      size: 64.sp,
                                                      color: Colors.greenAccent,
                                                    ),
                                                    SizedBox(height: 16.h),
                                                    Text(
                                                      context.tr(
                                                        'auth.reset_link_sent_title',
                                                        fallback:
                                                            'Check your email',
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 24.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: contrastColor,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(height: 16.h),
                                                    Text(
                                                      context.tr(
                                                        'auth.reset_link_sent_desc',
                                                        fallback:
                                                            'We have sent a password reset link to your email address.',
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 14.sp,
                                                        color: contrastColor
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        height: 1.5,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(height: 32.h),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (context.canPop()) {
                                                          context.pop();
                                                        } else {
                                                          context.go(
                                                            AppRouter
                                                                .loginRoute,
                                                          );
                                                        }
                                                      },
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            minimumSize:
                                                                const Size(
                                                                  double
                                                                      .infinity,
                                                                  56,
                                                                ),
                                                          ),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          context.tr(
                                                            'auth.back_to_login',
                                                            fallback:
                                                                'Back to Login',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      context.tr(
                                                        'auth.forgot_password_instructions',
                                                        fallback:
                                                            'Enter your email address and we will send you a link to reset your password.',
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 14.sp,
                                                        color: contrastColor
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        height: 1.5,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(height: 32.h),
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
                                                      child:
                                                          ForgotPasswordEmailInput(
                                                            fieldKey: _emailKey,
                                                            focusNode:
                                                                _emailFocus,
                                                            contrastColor:
                                                                contrastColor,
                                                          ),
                                                    ),
                                                    SizedBox(height: 24.h),
                                                    SendResetLinkButton(
                                                      isSubmitting:
                                                          state.isSubmitting,
                                                      onPressed: () {
                                                        if (_formKey
                                                                .currentState
                                                                ?.validate() ??
                                                            false) {
                                                          context
                                                              .read<
                                                                ForgotPasswordCubit
                                                              >()
                                                              .sendPasswordResetEmail();
                                                        } else {
                                                          if (!(_emailKey
                                                                  .currentState
                                                                  ?.validate() ??
                                                              true)) {
                                                            _emailShake.value++;
                                                          }
                                                          try {
                                                            Haptics.vibrate(
                                                              HapticsType.error,
                                                            );
                                                          } catch (_) {}
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ), // Close Padding
                                      Positioned(
                                        top: 0,
                                        child: VowlBotAuthCompanion(
                                          emailFocus: _emailFocus,
                                          size: 60,
                                          isForgotPassword: true,
                                        ),
                                      ),
                                    ],
                                  ), // Close Stack
                                  SizedBox(height: 16.h),
                                        RememberPasswordFooter(
                                          secondaryColor: secondaryColor,
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
