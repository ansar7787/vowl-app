import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';

// Decoupled sub-widgets
import 'package:vowl/features/profile/presentation/widgets/profile_header.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_bento_stats.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_badges_list.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_stickers_progress.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_feature_card.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_preferences_list.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const ProfileShimmerLoading();
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(const AuthReloadUser());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF6366F1),
            displacement: 100.h,
            child: Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280.h,
                      collapsedHeight: 80.h,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      leading: const SizedBox.shrink(),
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate collapse progress for smooth transition
                          final expandedHeight = 280.h;
                          final collapsedHeight = 80.h;
                          final currentHeight = constraints.biggest.height;
                          final collapseProgress = 1.0 -
                              ((currentHeight - collapsedHeight) /
                                      (expandedHeight - collapsedHeight))
                                  .clamp(0.0, 1.0);

                          return FlexibleSpaceBar(
                            background: Opacity(
                              opacity: (1.0 - collapseProgress * 1.5)
                                  .clamp(0.0, 1.0),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    width: 1.sw,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 20.h),
                                        BlocBuilder<ProfileBloc,
                                            ProfileState>(
                                          buildWhen: (prev, curr) =>
                                              prev.photoUrl !=
                                              curr.photoUrl,
                                          builder:
                                              (context, profileState) {
                                            return ProfileHeader(
                                              user: user,
                                              immediatePhotoUrl:
                                                  profileState.photoUrl,
                                              onEditName: () =>
                                                  _showEditNameSheet(
                                                context,
                                                user.displayName ?? '',
                                              ),
                                              onEditPhoto: () =>
                                                  _showImageSourceSheet(
                                                      context),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Collapsed state: show mini avatar + name
                            title: collapseProgress > 0.6
                                ? Opacity(
                                    opacity:
                                        ((collapseProgress - 0.6) / 0.4)
                                            .clamp(0.0, 1.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 16.r,
                                          backgroundColor: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : const Color(0xFFF1F5F9),
                                          backgroundImage: (user
                                                      .photoUrl !=
                                                  null)
                                              ? NetworkImage(
                                                  user.photoUrl!)
                                              : null,
                                          child: user.photoUrl == null
                                              ? Icon(
                                                  Icons.person_rounded,
                                                  color: const Color(
                                                      0xFF94A3B8),
                                                  size: 18.r,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 10.w),
                                        Text(
                                          user.displayName ?? 'Explorer',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(
                                                    0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                            collapseMode: CollapseMode.pin,
                          );
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Adventure Stats ──
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildSectionHeader(
                              context,
                              context.tr(
                                'profile.adventure_stats',
                                fallback: 'Adventure Stats',
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfileBentoStats(user: user),
                          ),
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfileFeatureCard(
                              iconContent: Icon(
                                Icons.insights_rounded,
                                color: Colors.white,
                                size: 24.r,
                              ),
                              color: const Color(0xFF10B981), // Emerald
                              shadowColor: const Color(0xFF059669),
                              title: context.tr(
                                'profile.learning_report',
                                fallback: 'Learning Report',
                              ),
                              subtitle: context.tr(
                                'profile.learning_report_subtitle',
                                fallback:
                                    'Weekly XP, mastery overview & quick resume.',
                              ),
                              onTap: () {
                                di.sl<HapticService>().selection();
                                context.push(
                                    AppRouter.progressDashboardRoute);
                              },
                            ),
                          ),

                          // ── 2. Key Shop (inline, compact) ──
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildKeyShopBanner(context, user),
                          ),

                          // ── 3. Hall of Fame ──
                          SizedBox(height: 40.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildSectionHeader(
                              context,
                              context.tr(
                                'profile.hall_of_fame',
                                fallback: 'Hall of Fame',
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          ProfileBadgesList(user: user),

                          // ── 4. Kids Zone (conditional) ──
                          if (user.kidsStickers.isNotEmpty ||
                              user.kidsTotalLevelsCompleted > 0) ...[
                            SizedBox(height: 40.h),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 24.w),
                              child: _buildSectionHeader(
                                context,
                                context.tr(
                                  'profile.kids_zone',
                                  fallback: 'Kids Zone',
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 24.w),
                              child: _buildKidsRoomCard(context),
                            ),
                            SizedBox(height: 16.h),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 24.w),
                              child:
                                  ProfileStickersProgress(user: user),
                            ),
                          ],

                          // ── 5. Premium CTA (single, after value) ──
                          if (!user.isPremium) ...[
                            SizedBox(height: 40.h),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 24.w),
                              child: _buildPremiumBanner(context),
                            ),
                          ],

                          // ── 6. Settings ──
                          SizedBox(height: 40.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfilePreferencesList(user: user),
                          ),

                          // ── 7. Sign Out ──
                          SizedBox(height: 24.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildSignOutButton(context),
                          ),

                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return ProfileFeatureCard(
      iconContent: Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 24.r,
      ),
      color: const Color(0xFF6366F1), // Premium screen Indigo
      shadowColor: const Color(0xFF4F46E5), // Darker Indigo for shadow
      title: context.tr(
        'profile.upgrade_to_premium',
        fallback: 'Upgrade to Premium',
      ),
      subtitle: context.tr(
        'profile.upgrade_to_premium_subtitle',
        fallback: 'Unlock all features and remove limits.',
      ),
      onTap: () {
        di.sl<HapticService>().selection();
        context.push(AppRouter.premiumRoute);
      },
    );
  }

  Widget _buildKidsRoomCard(BuildContext context) {
    return ProfileFeatureCard(
      iconContent: Icon(Icons.toys_rounded, color: Colors.white, size: 24.r),
      color: const Color(0xFFEF4444),
      shadowColor: const Color(0xFFDC2626),
      title: context.tr('profile.kids_room_title', fallback: 'Kids Room'),
      subtitle: context.tr(
        'profile.kids_room_subtitle',
        fallback: 'Play, customize, and explore your room!',
      ),
      onTap: () {
        di.sl<HapticService>().selection();
        context.push('/kids-room');
      },
    );
  }

  Widget _buildKeyShopBanner(BuildContext context, dynamic user) {
    final keys = user.keys ?? 0;

    return ProfileFeatureCard(
      iconContent: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key_rounded, color: Colors.white, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            keys.toString(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
      color: Colors.amber,
      shadowColor: Colors.amber.shade700,
      title: context.tr(
        'profile.golden_keys_title',
        fallback: 'Golden Keys',
      ),
      subtitle: context.tr(
        'profile.golden_keys_subtitle',
        fallback: 'Get more keys to unlock gates instantly!',
      ),
      onTap: () {
        di.sl<HapticService>().selection();
        KeyShopBottomSheet.show(context: context, isKidsMode: false);
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().warning();
        SettingsDialogs.showLogout(context);
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              color: const Color(0xFFEF4444),
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Text(
              context.tr('settings.sign_out', fallback: 'Sign Out'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameSheet(BuildContext context, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditNameSheetContent(currentName: currentName),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        context.read<ProfileBloc>().add(
          ProfileUpdatePictureRequested(pickedFile.path),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                context.tr(
                  'profile.avatar_projection_title',
                  fallback: 'Avatar Projection',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr(
                  'profile.avatar_projection_subtitle',
                  fallback: 'Select a new avatar style.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(height: 40.h),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      context: context,
                      icon: Icons.camera_rounded,
                      label: context.tr(
                        'profile.source_reality_label',
                        fallback: 'Reality',
                      ),
                      subtitle: context.tr(
                        'profile.source_reality_subtitle',
                        fallback: 'Use your device camera.',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: _buildSourceOption(
                      context: context,
                      icon: Icons.image_search_rounded,
                      label: context.tr(
                        'profile.source_memory_label',
                        fallback: 'Memory',
                      ),
                      subtitle: context.tr(
                        'profile.source_memory_subtitle',
                        fallback: 'Choose from your photo library.',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 32.r),
              ),
              SizedBox(height: 16.h),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNameSheetContent extends StatefulWidget {
  final String currentName;

  const _EditNameSheetContent({required this.currentName});

  @override
  State<_EditNameSheetContent> createState() => _EditNameSheetContentState();
}

class _EditNameSheetContentState extends State<_EditNameSheetContent> {
  late final TextEditingController _nameController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _focusNode = FocusNode();

    // Delay focus request until bottom sheet animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'profile.update_identity_title',
                    fallback: 'Update Identity',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  context.tr(
                    'profile.update_identity_subtitle',
                    fallback: 'Change your display name and avatar.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                SizedBox(height: 32.h),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    maxLength: 40,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr(
                        'profile.enter_new_name_hint',
                        fallback: 'Enter new name',
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                ScaleButton(
                  onTap: () {
                    final newName = _nameController.text.trim();
                    if (newName.isNotEmpty && newName != widget.currentName) {
                      context.read<ProfileBloc>().add(
                        ProfileUpdateDisplayNameRequested(newName),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        context.tr(
                          'profile.save_changes_button',
                          fallback: 'Save Changes',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingOverlay(isLoading: true, child: SizedBox.expand()),
    );
  }
}
