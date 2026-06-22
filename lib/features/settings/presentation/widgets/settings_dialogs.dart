import 'dart:io';
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

class SettingsDialogs {
  static void showEditProfile(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController(
      text: user.displayName,
    );
    final ImagePicker picker = ImagePicker();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 340.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('settings_dialogs.profile_settings'),
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null && context.mounted) {
                      context.read<ProfileBloc>().add(
                            ProfileUpdatePictureRequested(image.path),
                          );
                      Navigator.pop(context);
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
                            colors: [
                              Colors.blue,
                              Colors.blue.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          backgroundImage: user.photoUrl != null &&
                                  user.photoUrl!.isNotEmpty
                              ? (user.photoUrl!.startsWith('http')
                                  ? NetworkImage(user.photoUrl!)
                                  : FileImage(File(user.photoUrl!)) as ImageProvider)
                              : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
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
                TextField(
                  controller: nameController,
                  style: TextStyle(fontFamily: 'Outfit', 
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('settings_dialogs.display_name'),
                    labelStyle: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white38 : Colors.black38),
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
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
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
                          context.tr('common.cancel'),
                          style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              nameController.text != user.displayName) {
                            context.read<ProfileBloc>().add(
                              ProfileUpdateDisplayNameRequested(
                                nameController.text,
                              ),
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
                          context.tr('common.save'),
                          style: TextStyle(fontFamily: 'Outfit', 
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
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void showLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authBloc = context.read<AuthBloc>();
    di.sl<HapticService>().warning();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.red,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr('settings_dialogs.sign_out_title'),
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Are you sure you want to leave?\nYour quest progress is safely synced to the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          authBloc.add(const AuthLogoutRequested());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          context.tr('settings_dialogs.sign_out_confirm'),
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        context.tr('settings_dialogs.sign_out_cancel'),
                        style: TextStyle(fontFamily: 'Outfit', 
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Future<bool?> showDisableNotificationConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().warning();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_rounded,
                    color: Colors.orange,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr('settings_dialogs.disable_notifications_title'),
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Owly won\'t be able to remind you to practice. You might lose your learning streak!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
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
                          context.tr('settings_dialogs.keep_reminders'),
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(
                        context.tr('settings_dialogs.yes_disable'),
                        style: TextStyle(fontFamily: 'Outfit', 
                          color: Colors.red.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Future<bool?> showDisableSoundConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().warning();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_off_rounded,
                    color: Colors.pink,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Mute Game Sounds?',
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Clear audio and guidance are key to mastering your quests. Are you sure you want to silence them?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
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
                          'Keep It On',
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(
                        'Mute Anyway',
                        style: TextStyle(fontFamily: 'Outfit', 
                          color: Colors.red.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void showPasswordReset(BuildContext context, String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().warning();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.blue,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr('settings_dialogs.reset_password_title'),
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'We will send a password recovery email to:\n$email',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            AuthPasswordResetRequested(email),
                          );
                          Navigator.pop(context);
                          CustomSnackBar.show(
      context: context,
      message: 'Reset link sent to $email',
      type: CustomSnackBarType.info,
    );
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
                          context.tr('settings_dialogs.send_link'),
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.tr('common.cancel'),
                        style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void showDeleteAccount(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().heavy();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr('settings_dialogs.delete_account_title'),
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr('settings_dialogs.delete_account_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showFinalDeleteConfirmation(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          context.tr('settings_dialogs.delete_everything'),
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        context.tr('settings_dialogs.keep_account'),
                        style: TextStyle(fontFamily: 'Outfit', 
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void _showFinalDeleteConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authBloc = context.read<AuthBloc>();
    final TextEditingController confirmController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (builderContext, setDialogState) {
              return GlassTile(
                width: 320.w,
                padding: EdgeInsets.all(32.r),
                borderRadius: BorderRadius.circular(40.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('settings_dialogs.final_warning'),
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      context.tr('settings_dialogs.type_delete'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 14.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    TextField(
                      controller: confirmController,
                      onChanged: (val) => setDialogState(() {}),
                      style: TextStyle(fontFamily: 'Outfit', 
                        color: isDark ? Colors.white : const Color(0xFF0F172A), 
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('common.delete').toUpperCase(),
                        hintStyle: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white10 : Colors.black12),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: confirmController.text == context.tr('common.delete').toUpperCase() 
                              ? () {
                                  Navigator.pop(dialogContext);
                                  authBloc.add(const AuthDeleteAccountRequested());
                                }
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              disabledBackgroundColor: Colors.red.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              context.tr('settings_dialogs.delete_forever'),
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            context.tr('settings_dialogs.nevermind'),
                            style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void showComingSoon(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    final resolvedTitle = title ?? context.tr('settings_dialogs.coming_soon_title');
    final resolvedMessage = message ?? context.tr('settings_dialogs.coming_soon_body');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    di.sl<HapticService>().selection();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(40.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.blue,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  resolvedTitle,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  resolvedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Got it!',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
