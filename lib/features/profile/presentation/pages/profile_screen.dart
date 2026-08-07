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
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';

// Decoupled sub-widgets
import 'package:vowl/features/profile/presentation/widgets/profile_header.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_bento_stats.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_badges_list.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_stickers_progress.dart';
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
                      flexibleSpace: FlexibleSpaceBar(
                        background: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 1.sw,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 20.h),
                                  BlocBuilder<ProfileBloc, ProfileState>(
                                    buildWhen: (prev, curr) =>
                                        prev.photoUrl != curr.photoUrl,
                                    builder: (context, profileState) {
                                      return ProfileHeader(
                                        user: user,
                                        immediatePhotoUrl:
                                            profileState.photoUrl,
                                        onEditName: () => _showEditNameSheet(
                                          context,
                                          user.displayName ?? '',
                                        ),
                                        onEditPhoto: () =>
                                            _showImageSourceSheet(context),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        collapseMode: CollapseMode.pin,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!user.isPremium) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: _buildPremiumBanner(context),
                            ),
                          ],

                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: const AdRewardCard(margin: EdgeInsets.zero),
                          ),

                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildKeyShopBanner(context, user),
                          ),

                          SizedBox(height: 24.h),
                          _buildInteractiveAILab(context),

                          SizedBox(height: 20.h),
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
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfileBadgesList(user: user),
                          ),

                          SizedBox(height: 40.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildSectionHeader(
                              context,
                              context.tr(
                                'profile.kids_stickers',
                                fallback: 'Sticker Book',
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfileStickersProgress(user: user),
                          ),

                          SizedBox(height: 40.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildSectionHeader(
                              context,
                              context.tr(
                                'settings.app_preferences',
                                fallback: 'App Preferences',
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ProfilePreferencesList(
                              user: user,
                              soundEnabled: false,
                              onSoundToggle: (_) {},
                            ),
                          ),

                          SizedBox(height: 140.h),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        context.push(AppRouter.premiumRoute);
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFFF59E0B),
                size: 28.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'profile.upgrade_to_premium',
                      fallback: 'Upgrade to Premium',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.tr(
                      'profile.upgrade_to_premium_subtitle',
                      fallback: 'Unlock all features and remove limits.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyShopBanner(BuildContext context, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = user.keys ?? 0;

    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        KeyShopBottomSheet.show(context: context, isKidsMode: false);
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.amber.shade700, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade700,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Row(
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
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Golden Keys',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Get more keys to unlock gates instantly!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveAILab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final features = [
      (
        icon: Icons.document_scanner_rounded,
        title: context.tr(
          'translation.scan_learn_title',
          fallback: 'Scan & Learn',
        ),
        subtitle: context.tr(
          'translation.scan_learn_desc',
          fallback: 'Extract & translate real-world text.',
        ),
        color: const Color(0xFF6366F1),
        onTap: () {
          di.sl<HapticService>().selection();
          context.push(AppRouter.scanAndLearnRoute);
        },
      ),
      (
        icon: Icons.camera_alt_rounded,
        title: context.tr(
          'vocabulary.photo_vocab_title',
          fallback: 'Photo Vocab',
        ),
        subtitle: context.tr(
          'vocabulary.photo_vocab_desc',
          fallback: 'Point camera to learn object names.',
        ),
        color: const Color(0xFF14B8A6),
        onTap: () {
          di.sl<HapticService>().selection();
          context.push(AppRouter.photoVocabularyRoute);
        },
      ),
      (
        icon: Icons.translate_rounded,
        title: 'Translation',
        subtitle: 'Real-time native hints.',
        color: const Color(0xFFF43F5E),
        onTap: () => _showEngineInfoSheet(
          context,
          icon: Icons.translate_rounded,
          color: const Color(0xFFF43F5E),
          title: 'Instant Translation',
          desc:
              'Runs directly on your device to provide real-time translations during reading and speaking games without needing internet.',
        ),
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: 'Smart Reply',
        subtitle: 'AI conversation suggestions.',
        color: const Color(0xFF8B5CF6),
        onTap: () => _showEngineInfoSheet(
          context,
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF8B5CF6),
          title: 'AI Smart Reply',
          desc:
              'Generates context-aware conversation replies during the Dialogue Roleplay modules to keep the chat flowing naturally.',
        ),
      ),
      (
        icon: Icons.search_rounded,
        title: 'Entity Extract',
        subtitle: 'Finds dates & places.',
        color: const Color(0xFF10B981),
        onTap: () => _showEngineInfoSheet(
          context,
          icon: Icons.search_rounded,
          color: const Color(0xFF10B981),
          title: 'Entity Extraction',
          desc:
              'Automatically scans reading passages to highlight important entities like dates, times, money, and locations.',
        ),
      ),
      (
        icon: Icons.language_rounded,
        title: 'Language ID',
        subtitle: 'Detects native language.',
        color: const Color(0xFFF59E0B),
        onTap: () => _showEngineInfoSheet(
          context,
          icon: Icons.language_rounded,
          color: const Color(0xFFF59E0B),
          title: 'Language ID',
          desc:
              'Runs silently during speaking exercises to detect if you accidentally spoke in your native language instead of English.',
        ),
      ),
      (
        icon: Icons.draw_rounded,
        title: 'Digital Ink',
        subtitle: 'Handwriting recognition.',
        color: const Color(0xFFEC4899),
        onTap: () => _showEngineInfoSheet(
          context,
          icon: Icons.draw_rounded,
          color: const Color(0xFFEC4899),
          title: 'Digital Ink',
          desc:
              'Powers the handwriting canvas in the Kids Zone, translating drawn strokes into digital text instantly.',
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFF6366F1),
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              _buildSectionHeader(
                context,
                context.tr('profile.ai_lab', fallback: 'Vowl AI Lab'),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            context.tr(
              'profile.ai_lab_desc',
              fallback: '7 powerful AI engines running 100% offline.',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 170.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: features.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final f = features[index];
              return ScaleButton(
                onTap: f.onTap,
                child: Container(
                  width: 145.w,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: f.color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f.icon, color: f.color, size: 24.r),
                      ),
                      const Spacer(),
                      Text(
                        f.title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        f.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEngineInfoSheet(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    di.sl<HapticService>().selection();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32.r),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ScaleButton(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    context.tr('common.got_it', fallback: 'Got it!'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
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
