import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

/// All settings-related dialogs in one place.
///
/// PATTERN: Each dialog that requires stateful widget (TextEditingController,
/// image picker state, etc.) is extracted to a private StatefulWidget so that
/// Flutter's lifecycle correctly disposes resources when the dialog is closed.
class SettingsDialogs {
  SettingsDialogs._(); // Non-instantiable.

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Clamps the dialog content width to screen width minus 48px padding.
  /// Prevents GlassTile from overflowing on 320px-wide phones.
  static double _dialogWidth(BuildContext context, double nominal) {
    return math.min(nominal, MediaQuery.of(context).size.width - 48);
  }

  static Widget _dialogTransition(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Profile
  // ---------------------------------------------------------------------------

  static void showEditProfile(BuildContext context, UserEntity user) {
    di.sl<HapticService>().selection();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      // FIX (CRITICAL-3): Dialog body is now a StatefulWidget. The
      // TextEditingController is created in initState() and disposed in
      // dispose(). Previously it was created in this static method and was
      // NEVER disposed, leaking memory on every profile dialog open.
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: _EditProfileDialogContent(
            user: user,
            dialogWidth: _dialogWidth(context, 340.w),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  static void showLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authBloc = context.read<AuthBloc>();
    di.sl<HapticService>().warning();
    final width = _dialogWidth(context, 320.w);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: width,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogIcon(
                  icon: Icons.power_settings_new_rounded,
                  color: Colors.red,
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr(
                    'settings_dialogs.sign_out_title',
                    fallback: 'Sign Out',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  // FIX (HIGH-2): Was hardcoded English. Now localised.
                  context.tr(
                    'settings_dialogs.sign_out_body',
                    fallback: 'Are you sure you want to sign out?',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                _PrimaryButton(
                  label: context.tr(
                    'settings_dialogs.sign_out_confirm',
                    fallback: 'Sign Out',
                  ),
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    authBloc.add(const AuthLogoutRequested());
                  },
                ),
                SizedBox(height: 12.h),
                _SecondaryTextButton(
                  label: context.tr(
                    'settings_dialogs.sign_out_cancel',
                    fallback: 'Cancel',
                  ),
                  isDark: isDark,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  static Future<bool?> _showDisableConfirmation({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titleKey,
    required String titleFallback,
    required String bodyKey,
    required String bodyFallback,
    required String keepKey,
    required String keepFallback,
    required String disableKey,
    required String disableFallback,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().warning();
    final width = _dialogWidth(context, 320.w);

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: width,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogIcon(icon: icon, color: color),
                SizedBox(height: 24.h),
                Text(
                  context.tr(titleKey, fallback: titleFallback),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr(bodyKey, fallback: bodyFallback),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                _PrimaryButton(
                  label: context.tr(keepKey, fallback: keepFallback),
                  color: Colors.blue,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                SizedBox(height: 12.h),
                _DestructiveTextButton(
                  label: context.tr(disableKey, fallback: disableFallback),
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  // ---------------------------------------------------------------------------
  // Disable Notifications Confirmation
  // ---------------------------------------------------------------------------

  static Future<bool?> showDisableNotificationConfirmation(
    BuildContext context,
  ) {
    return _showDisableConfirmation(
      context: context,
      icon: Icons.notifications_off_rounded,
      color: Colors.orange,
      titleKey: 'settings_dialogs.disable_notifications_title',
      titleFallback: 'Disable Notifications?',
      bodyKey: 'settings_dialogs.disable_notifications_body',
      bodyFallback: 'You will miss out on daily reminders.',
      keepKey: 'settings_dialogs.keep_reminders',
      keepFallback: 'Keep Reminders',
      disableKey: 'settings_dialogs.yes_disable',
      disableFallback: 'Yes, Disable',
    );
  }

  // ---------------------------------------------------------------------------
  // Disable Sound Confirmation
  // ---------------------------------------------------------------------------

  static Future<bool?> showDisableSoundConfirmation(BuildContext context) {
    return _showDisableConfirmation(
      context: context,
      icon: Icons.volume_off_rounded,
      color: Colors.pink,
      titleKey: 'settings_dialogs.disable_sound_title',
      titleFallback: 'Disable Sound?',
      bodyKey: 'settings_dialogs.disable_sound_body',
      bodyFallback: 'This will mute all game sounds.',
      keepKey: 'settings_dialogs.keep_sound_on',
      keepFallback: 'Keep Sound On',
      disableKey: 'settings_dialogs.mute_anyway',
      disableFallback: 'Mute Anyway',
    );
  }

  // ---------------------------------------------------------------------------
  // Disable Speech Confirmation
  // ---------------------------------------------------------------------------

  static Future<bool?> showDisableSpeechConfirmation(BuildContext context) {
    return _showDisableConfirmation(
      context: context,
      icon: Icons.mic_off_rounded,
      color: Colors.cyan,
      titleKey: 'settings_dialogs.disable_speech_title',
      titleFallback: 'Disable Speaking?',
      bodyKey: 'settings_dialogs.disable_speech_body',
      bodyFallback: 'You will miss out on crucial speaking practice.',
      keepKey: 'settings_dialogs.keep_speaking',
      keepFallback: 'Keep Speaking',
      disableKey: 'settings_dialogs.disable_anyway',
      disableFallback: 'Disable Anyway',
    );
  }

  // ---------------------------------------------------------------------------
  // Password Reset
  // ---------------------------------------------------------------------------

  static void showPasswordReset(BuildContext context, String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().warning();
    final width = _dialogWidth(context, 320.w);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: width,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogIcon(
                  icon: Icons.mark_email_read_rounded,
                  color: Colors.blue,
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr(
                    'settings_dialogs.reset_password_title',
                    fallback: 'Reset Password',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  // FIX (HIGH-2): Was hardcoded 'We will send a password...'
                  context.tr(
                    'settings_dialogs.reset_password_body',
                    fallback: 'We will send a reset link to your email.',
                    args: [email],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                _PrimaryButton(
                  label: context.tr(
                    'settings_dialogs.send_link',
                    fallback: 'Send Link',
                  ),
                  color: Colors.blue,
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthPasswordResetRequested(email),
                    );
                    Navigator.pop(ctx);
                    if (ctx.mounted) {
                      CustomSnackBar.show(
                        context: ctx,
                        // FIX (HIGH-2): Was hardcoded 'Reset link sent to $email'
                        message: context.tr(
                          'settings_dialogs.reset_link_sent',
                          fallback: 'Reset link sent!',
                          args: [email],
                        ),
                        type: CustomSnackBarType.info,
                      );
                    }
                  },
                ),
                SizedBox(height: 12.h),
                _SecondaryTextButton(
                  label: context.tr('common.cancel', fallback: 'Cancel'),
                  isDark: isDark,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Account (Step 1 — warning)
  // ---------------------------------------------------------------------------

  static void showDeleteAccount(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().heavy();
    final width = _dialogWidth(context, 320.w);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: width,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogIcon(
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr(
                    'settings_dialogs.delete_account_title',
                    fallback: 'Delete Account',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr(
                    'settings_dialogs.delete_account_body',
                    fallback:
                        'This action cannot be undone. All your progress will be lost.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                _PrimaryButton(
                  label: context.tr(
                    'settings_dialogs.delete_everything',
                    fallback: 'Delete Everything',
                  ),
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showFinalDeleteConfirmation(context);
                  },
                ),
                SizedBox(height: 12.h),
                _SecondaryTextButton(
                  label: context.tr(
                    'settings_dialogs.keep_account',
                    fallback: 'Keep Account',
                  ),
                  isDark: isDark,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Account (Step 2 — final type-to-confirm)
  // FIX (CRITICAL-3): Extracted to StatefulWidget for controller disposal.
  // ---------------------------------------------------------------------------

  static void _showFinalDeleteConfirmation(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: _FinalDeleteDialogContent(
            authBloc: authBloc,
            dialogWidth: _dialogWidth(context, 320.w),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }

  // ---------------------------------------------------------------------------
  // Coming Soon
  // ---------------------------------------------------------------------------

  static void showComingSoon(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().selection();
    final width = _dialogWidth(context, 320.w);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: width,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogIcon(
                  icon: Icons.rocket_launch_rounded,
                  color: Colors.blue,
                ),
                SizedBox(height: 24.h),
                Text(
                  title ??
                      context.tr(
                        'settings_dialogs.coming_soon_title',
                        fallback: 'Coming Soon!',
                      ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  message ??
                      context.tr(
                        'settings_dialogs.coming_soon_body',
                        fallback: 'This feature is currently in development.',
                      ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                _PrimaryButton(
                  // FIX (HIGH-2): Was hardcoded 'Got it!'
                  label: context.tr(
                    'settings_dialogs.got_it',
                    fallback: 'Got It',
                  ),
                  color: Colors.blue,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim1, anim2, child) =>
          _dialogTransition(anim1, child),
    );
  }
}

// ===========================================================================
// Private reusable dialog sub-widgets
// ===========================================================================

/// Standard icon badge used in all dialogs.
class _DialogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _DialogIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 40.r),
    );
  }
}

/// Full-width filled CTA button.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.2),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}

/// Subtle cancel/secondary TextButton.
class _SecondaryTextButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onPressed;

  const _SecondaryTextButton({
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Destructive (red) TextButton for irreversible secondary actions.
class _DestructiveTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _DestructiveTextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: Colors.red.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ===========================================================================
// Private StatefulWidget dialog bodies
// ===========================================================================

/// FIX (CRITICAL-3): Edit-profile dialog extracted to StatefulWidget.
/// TextEditingController is created in initState and disposed in dispose.
class _EditProfileDialogContent extends StatefulWidget {
  final UserEntity user;
  final double dialogWidth;

  const _EditProfileDialogContent({
    required this.user,
    required this.dialogWidth,
  });

  @override
  State<_EditProfileDialogContent> createState() =>
      _EditProfileDialogContentState();
}

class _EditProfileDialogContentState extends State<_EditProfileDialogContent> {
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose(); // ← Now properly disposed on dialog close.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      width: widget.dialogWidth,
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(40.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr(
              'settings_dialogs.profile_settings',
              fallback: 'Profile Settings',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          // Avatar picker
          GestureDetector(
            onTap: () async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null && context.mounted) {
                context.read<ProfileBloc>().add(
                  ProfileUpdatePictureRequested(image.path),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    backgroundImage: widget.user.photoUrl?.isNotEmpty == true
                        ? (widget.user.photoUrl!.startsWith('http')
                              ? NetworkImage(widget.user.photoUrl!)
                              : FileImage(File(widget.user.photoUrl!))
                                    as ImageProvider)
                        : null,
                    child: widget.user.photoUrl?.isNotEmpty != true
                        ? Icon(
                            Icons.person_rounded,
                            size: 50.r,
                            color: Colors.white24,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20.r,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          // Name field
          TextField(
            controller: _nameController,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: context.tr(
                'settings_dialogs.display_name',
                fallback: 'Display Name',
              ),
              labelStyle: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Icon(
                Icons.badge_rounded,
                color: Colors.blue,
                size: 20.r,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.tr('common.cancel', fallback: 'Cancel'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final trimmed = _nameController.text.trim();
                    if (trimmed.isNotEmpty &&
                        trimmed != widget.user.displayName) {
                      context.read<ProfileBloc>().add(
                        ProfileUpdateDisplayNameRequested(trimmed),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    context.tr('common.save', fallback: 'Save'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// FIX (CRITICAL-3): Final delete confirmation extracted to StatefulWidget.
/// Both the TextEditingController and StatefulBuilder rebuild logic are
/// managed here, replacing the previous static-method + outer-scope approach.
class _FinalDeleteDialogContent extends StatefulWidget {
  final AuthBloc authBloc;
  final double dialogWidth;

  const _FinalDeleteDialogContent({
    required this.authBloc,
    required this.dialogWidth,
  });

  @override
  State<_FinalDeleteDialogContent> createState() =>
      _FinalDeleteDialogContentState();
}

class _FinalDeleteDialogContentState extends State<_FinalDeleteDialogContent> {
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose(); // ← Now properly disposed on dialog close.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const deleteWord = 'DELETE';
    final isConfirmed = _confirmController.text.trim() == deleteWord;

    return GlassTile(
      width: widget.dialogWidth,
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(40.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr(
              'settings_dialogs.final_warning',
              fallback: 'Final Warning',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr(
              'settings_dialogs.type_delete',
              fallback: 'Type DELETE to confirm',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 24.h),
          TextField(
            controller: _confirmController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          _PrimaryButton(
            label: context.tr(
              'settings_dialogs.delete_forever',
              fallback: 'Delete Forever',
            ),
            color: Colors.red,
            onPressed: isConfirmed
                ? () {
                    Navigator.pop(context);
                    widget.authBloc.add(const AuthDeleteAccountRequested());
                  }
                : null,
          ),
          SizedBox(height: 12.h),
          _SecondaryTextButton(
            label: context.tr(
              'settings_dialogs.nevermind',
              fallback: 'Nevermind',
            ),
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
