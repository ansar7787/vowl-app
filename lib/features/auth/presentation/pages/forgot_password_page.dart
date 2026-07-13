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

  int _emailShake = 0;

  @override
  void dispose() {
    _emailFocus.dispose();
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
                previous.isSubmitting != current.isSubmitting,
            builder: (context, state) {
              final contrastColor = MeshGradientBackground.getContrastColor(
                context,
              );
              final secondaryColor = contrastColor.withValues(alpha: 0.6);

              return LoadingOverlay(
                isLoading: state.isSubmitting,
                message: context.tr('auth.sending_recovery_link', fallback: 'Sending recovery link...'),
                child: Scaffold(
                  backgroundColor: bgColor,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      const MeshGradientBackground(auraColor: Colors.blue),
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
                                        ForgotPasswordHeader(
                                          emailFocus: _emailFocus,
                                          secondaryColor: secondaryColor,
                                        ),
                                        SizedBox(height: 32.h),
                                        HolographicCard(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                context.tr(
                                                  'auth.forgot_password_instructions',
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  color: contrastColor
                                                      .withValues(alpha: 0.8),
                                                  height: 1.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 32.h),
                                              ShakeableWrapper(
                                                shakeCount: _emailShake,
                                                child: ForgotPasswordEmailInput(
                                                  fieldKey: _emailKey,
                                                  focusNode: _emailFocus,
                                                  contrastColor: contrastColor,
                                                ),
                                              ),
                                              SizedBox(height: 24.h),
                                              SendResetLinkButton(
                                                isSubmitting:
                                                    state.isSubmitting,
                                                onPressed: () {
                                                  if (_formKey.currentState
                                                          ?.validate() ??
                                                      false) {
                                                    context
                                                        .read<
                                                          ForgotPasswordCubit
                                                        >()
                                                        .sendPasswordResetEmail();
                                                  } else {
                                                    if (!(_emailKey.currentState
                                                            ?.validate() ??
                                                        true)) {
                                                      setState(
                                                        () => _emailShake++,
                                                      );
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
                                        SizedBox(height: 32.h),
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
