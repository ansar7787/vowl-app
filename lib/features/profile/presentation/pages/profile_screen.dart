import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/image_utils.dart';
import 'package:vowl/features/social_share/services/social_share_rasterizer.dart';

// Decoupled sub-widgets
import 'package:vowl/features/profile/presentation/widgets/profile_header.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_quick_action_hud.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_segmented_tabs.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_arena_card.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_bento_stats.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_badges_list.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_vault_section.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_feature_card.dart';

import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color059669 = Color(0xFF059669);
  static const Color color4f46e5 = Color(0xFF4F46E5);
}

/// Main user profile screen displaying stats, achievements, preferences, and avatars.
///
/// Refactored to the 10/10 Grandmaster Passport Architecture:
/// - Hero Passport Card with User Avatar & Equipped Mascot Companion.
/// - Floating Quick-Action HUD for Treasury, Daily Streak, and VIP Gift Claim.
/// - Fluid 3-Tab Segmented Controller:
///   1. ⚔️ Journey & Arena (PvP Combat record, Bento XP/Level stats, Learning Report, Review Mistakes).
///   2. 🏆 Hall of Fame (Badge Collection progress, 3D Badges, Direct Trophy Room link).
///   3. 💎 Vault & Rewards (Ambassador Referral Code, Store, Premium perks, Quarantined Kids Room).
class ProfileScreen extends StatefulWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _heroPassportKey = GlobalKey();
  String? _pendingLocalPhotoPath;
  late final ScrollController _scrollController;
  bool _ownsScrollController = false;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<ScrollController>(instanceName: 'profile')) {
      _scrollController = di.sl<ScrollController>(instanceName: 'profile');
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _sharePlayerCard(UserEntity user) async {
    di.sl<HapticService>().selection();
    final code = user.referralCode ?? '';
    final shareText =
        'Proud of my learning progress on Vowl! 🚀\n'
        'Use my invite code $code to unlock 100 Bonus Coins & VIP perks:\n'
        'https://vowl-acbc5.web.app/invite/$code';

    try {
      await SocialShareRasterizer.captureAndShare(
        boundaryKey: _heroPassportKey,
        shareText: shareText,
        subject: 'My Vowl Player Passport',
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'My Vowl Player Passport'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (prev, curr) =>
            (prev.isPhotoUploading != curr.isPhotoUploading &&
                !curr.isPhotoUploading) ||
            (curr.message != null && prev.message != curr.message),
        listener: (context, profileState) {
          if (!profileState.isPhotoUploading &&
              _pendingLocalPhotoPath != null) {
            setState(() {
              _pendingLocalPhotoPath = null;
            });
          }

          final msg = profileState.message;
          if (msg != null && msg.isNotEmpty) {
            final isSuccess =
                msg == 'profile.picture_updated' ||
                msg == 'profile.display_name_updated';
            final isError =
                msg.contains('error') ||
                msg.contains('failed') ||
                msg.contains('unreachable') ||
                msg.contains('invalid');

            if (isSuccess) {
              try {
                di.sl<HapticService>().success();
              } catch (_) {}
            } else if (isError) {
              try {
                di.sl<HapticService>().error();
              } catch (_) {}
            }

            final fallback = msg == 'profile.picture_updated'
                ? 'Profile photo updated successfully!'
                : msg == 'profile.display_name_updated'
                ? 'Display name updated successfully!'
                : isSuccess
                ? 'Updated successfully!'
                : 'Failed to update profile.';

            CustomSnackBar.show(
              context: context,
              message: context.tr(msg, fallback: fallback),
              type: isSuccess
                  ? CustomSnackBarType.success
                  : CustomSnackBarType.error,
            );

            context.read<ProfileBloc>().add(const ProfileClearMessage());
          }
        },
        child: BlocSelector<AuthBloc, AuthState, bool>(
          selector: (state) => state.status == AuthStatus.loggingOut,
          builder: (context, isLoggingOut) {
            return LoadingOverlay(
              isLoading: isLoggingOut,
              message: context.tr(
                'settings.signing_out_overlay',
                fallback: 'Signing out...',
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
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
                    color: AppColors.indigo500,
                    displacement: 32.h,
                    child: Stack(
                      children: [
                        const MeshGradientBackground(showLetters: false),
                        CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            // 1. Sleek Pinned App Bar with Settings & Share actions
                            _buildSliverAppBar(context, isDark, user),

                            // 2. Profile Content Body
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 4.h,
                                  bottom:
                                      110.h +
                                      MediaQuery.paddingOf(context).bottom,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hero Passport Card (Avatar + Active Mascot Companion)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.screen,
                                      ),
                                      child:
                                          BlocBuilder<
                                            ProfileBloc,
                                            ProfileState
                                          >(
                                            buildWhen: (prev, curr) =>
                                                prev.photoUrl !=
                                                    curr.photoUrl ||
                                                prev.photoUserId !=
                                                    curr.photoUserId ||
                                                prev.isPhotoUploading !=
                                                    curr.isPhotoUploading,
                                            builder: (context, profileState) {
                                              final immediatePhoto =
                                                  _pendingLocalPhotoPath ??
                                                  (profileState.isPhotoForUser(
                                                        user.id,
                                                      )
                                                      ? profileState.photoUrl
                                                      : null);
                                              final isUploading =
                                                  profileState
                                                      .isPhotoUploading ||
                                                  _pendingLocalPhotoPath !=
                                                      null;

                                              return ProfileHeader(
                                                user: user,
                                                immediatePhotoUrl:
                                                    immediatePhoto,
                                                isUploading: isUploading,
                                                repaintKey: _heroPassportKey,
                                                onEditName: () =>
                                                    _showEditNameSheet(
                                                      context,
                                                      user.displayName ?? '',
                                                    ),
                                                onEditPhoto: () =>
                                                    _showImageSourceSheet(
                                                      context,
                                                    ),
                                              );
                                            },
                                          ),
                                    ),
                                    SizedBox(height: 14.h),

                                    // Quick Action HUD Strip (Treasury, Streak, VIP Gift)
                                    ProfileQuickActionHud(user: user),
                                    SizedBox(height: 18.h),

                                    // Sticky Segmented Tabs
                                    ProfileSegmentedTabs(
                                      activeIndex: _activeTabIndex,
                                      onTabSelected: (index) {
                                        setState(() {
                                          _activeTabIndex = index;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 16.h),

                                    // Tab Content Switcher with smooth transition (no cutter effect)
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      layoutBuilder:
                                          (currentChild, previousChildren) {
                                            return Stack(
                                              alignment: Alignment.topCenter,
                                              children: <Widget>[
                                                ...previousChildren,
                                                ?currentChild,
                                              ],
                                            );
                                          },
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.0, 0.02),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildActiveTabContent(
                                        context,
                                        user,
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
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
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    UserEntity user,
  ) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final barBg = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      toolbarHeight: 50.h,
      leadingWidth: 70.w,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(color: barBg.withValues(alpha: 0.95)),
      leading: Padding(
        padding: EdgeInsets.only(left: AppSpacing.screen),
        child: Center(
          child: ScaleButton(
            onTap: () {
              di.sl<HapticService>().selection();
              context.push(AppRouter.settingsRoute);
            },
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Center(
                child: Icon(
                  Icons.settings_rounded,
                  size: 20.r,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        context.tr('nav.profile', fallback: 'Profile'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.screen),
          child: Center(
            child: ScaleButton(
              onTap: () => _sharePlayerCard(user),
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Center(
                  child: Icon(
                    Icons.share_rounded,
                    size: 20.r,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    UserEntity user,
    bool isDark,
  ) {
    switch (_activeTabIndex) {
      case 0:
        return _buildJourneyTab(context, user);
      case 1:
        return _buildHallOfFameTab(context, user);
      case 2:
        return _buildVaultTab(context, user);
      default:
        return _buildJourneyTab(context, user);
    }
  }

  Widget _buildJourneyTab(BuildContext context, UserEntity user) {
    return KeyedSubtree(
      key: const ValueKey('tab_journey'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 1v1 Arena Combat Card (Surfacing Duel Wins, Losses, and Win Rate)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ProfileArenaCard(user: user),
          ),
          SizedBox(height: 16.h),

          // 2. Adventure Bento Stats Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ProfileBentoStats(user: user),
          ),
          SizedBox(height: 16.h),

          // 3. Learning Report Feature Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ProfileFeatureCard(
              iconContent: Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: 24.r,
              ),
              color: const Color(0xFF10B981), // Emerald
              shadowColor: _LocalPalette.color059669,
              title: context.tr(
                'profile.learning_report',
                fallback: 'Learning Report',
              ),
              subtitle: context.tr(
                'profile.learning_report_subtitle',
                fallback: 'Weekly XP, mastery overview & quick resume.',
              ),
              onTap: () {
                di.sl<HapticService>().selection();
                context.push(AppRouter.progressDashboardRoute);
              },
            ),
          ),

          // 4. Review Mistakes Feature Card
          if (!user.isKidsModeOnly) ...[
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: ProfileFeatureCard(
                iconContent: Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 24.r,
                ),
                color: const Color(0xFFF59E0B), // Amber
                shadowColor: const Color(0xFFD97706),
                title: context.tr(
                  'profile.review_mistakes',
                  fallback: 'Review & Master',
                ),
                subtitle: context.tr(
                  'profile.review_mistakes_subtitle',
                  fallback: 'Master skills from previous challenges.',
                ),
                onTap: () {
                  di.sl<HapticService>().selection();
                  context.push(AppRouter.reviewMistakesRoute);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHallOfFameTab(BuildContext context, UserEntity user) {
    return KeyedSubtree(
      key: const ValueKey('tab_hall_of_fame'),
      child: ProfileBadgesList(user: user),
    );
  }

  Widget _buildVaultTab(BuildContext context, UserEntity user) {
    return KeyedSubtree(
      key: const ValueKey('tab_vault'),
      child: ProfileVaultSection(user: user),
    );
  }

  void _showEditNameSheet(BuildContext context, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditNameSheetContent(currentName: currentName),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _pendingLocalPhotoPath = pickedFile.path;
        });
        final croppedFile = await ImageUtils.cropToSquare(
          File(pickedFile.path),
          targetDimension: 512,
        );

        if (mounted) {
          setState(() {
            _pendingLocalPhotoPath = croppedFile.path;
          });
          context.read<ProfileBloc>().add(
            ProfileUpdatePictureRequested(croppedFile.path),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingLocalPhotoPath = null;
        });
      }
      if (kDebugMode) {
        debugPrint('Error picking image: $e');
      }
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = AppTheme.isMidnight(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          24.h,
          AppSpacing.screen,
          32.h,
        ),
        decoration: BoxDecoration(
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? AppColors.slate900 : Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: SingleChildScrollView(
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
                  color: isDark ? Colors.white : AppColors.slate900,
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
                        fallback: 'Camera',
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
                        fallback: 'Gallery',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h + MediaQuery.paddingOf(context).bottom),
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
        blur: 0,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.indigo500, size: 32.r),
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
                  color: isDark ? Colors.white : AppColors.slate800,
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
    final isMidnight = AppTheme.isMidnight(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: math.max(
          MediaQuery.viewInsetsOf(context).bottom,
          MediaQuery.paddingOf(context).bottom,
        ),
      ),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? AppColors.midnightNavy : Colors.white),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: SingleChildScrollView(
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                16.h,
                AppSpacing.screen,
                24.h,
              ),
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
                      color: isDark ? Colors.white : AppColors.slate900,
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
                        color: isDark ? Colors.white : AppColors.slate900,
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
                          colors: [
                            AppColors.indigo500,
                            _LocalPalette.color4f46e5,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
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
      ),
    );
  }
}

/// Loading placeholder screen displayed while user profile data is being loaded.
class ProfileShimmerLoading extends StatelessWidget {
  /// Creates a [ProfileShimmerLoading] placeholder.
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
