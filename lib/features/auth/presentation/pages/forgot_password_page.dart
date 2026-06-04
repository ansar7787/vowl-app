import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/presentation/widgets/forgot_password_widgets.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _emailFocus = FocusNode();
  
  int _emailShake = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          _showSnackBar(context, state.successMessage!, CustomSnackBarType.success);
        }
        if (state.errorMessage != null) {
          _showSnackBar(context, state.errorMessage!, CustomSnackBarType.error);
        }
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          final contrastColor = MeshGradientBackground.getContrastColor(context);
          final secondaryColor = contrastColor.withValues(alpha: 0.6);
          
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
          
          final bgColor = isMidnight 
              ? const Color(0xFF000000) 
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return LoadingOverlay(
            isLoading: state.isSubmitting,
            message: 'Sending Recovery Link...',
            child: Scaffold(
              backgroundColor: bgColor,
              resizeToAvoidBottomInset: false, // Keep background static
              body: Stack(
                children: [
                  const MeshGradientBackground(auraColor: Colors.blue), // Recovery aura
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                        return SingleChildScrollView(
                          physics: keyboardOpen 
                              ? const BouncingScrollPhysics() 
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ForgotPasswordHeader(
                                      emailFocus: _emailFocus,
                                      secondaryColor: secondaryColor,
                                    ),
                                    SizedBox(height: 32.h),
                                    HolographicCard(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Enter your email address below and we will send you a link to reset your password.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14.sp,
                                              color: contrastColor.withValues(alpha: 0.8),
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 32.h),
                                          ShakeableWrapper(
                                            shakeCount: _emailShake,
                                            child: ForgotPasswordEmailInput(
                                              fieldKey: _emailKey,
                                              controller: _emailController,
                                              focusNode: _emailFocus,
                                              contrastColor: contrastColor,
                                            ),
                                          ),
                                          SizedBox(height: 24.h),
                                          SendResetLinkButton(
                                            isSubmitting: state.isSubmitting,
                                            onPressed: () {
                                              if (_formKey.currentState?.validate() ?? false) {
                                                context.read<LoginCubit>().forgotPassword(
                                                      _emailController.text.trim(),
                                                    );
                                              } else {
                                                if (!(_emailKey.currentState?.validate() ?? true)) {
                                                  setState(() => _emailShake++);
                                                }
                                                try {
                                                  Haptics.vibrate(HapticsType.error);
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
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, CustomSnackBarType type) {
    CustomSnackBar.show(context: context, message: message, type: type);
  }
}
