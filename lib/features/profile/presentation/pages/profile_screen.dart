import 'package:vowl/core/utils/sound_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleSound(bool value) async {
    if (!value) {
      final confirmed = await _showSoundConfirmationDialog();
      if (!confirmed) return;
    }

    setState(() {
      _soundEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);

    di.sl<SoundService>().setMuted(!value);

    final kidsAudio = di.sl<KidsAudioService>();
    final kidsTTS = di.sl<KidsTTSService>();

    if (!value) {
      await kidsAudio.stopBgm();
      await kidsTTS.stop();
    }
  }

  Future<bool> _showSoundConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(32.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_off_rounded,
                        color: const Color(0xFFFACC15),
                        size: 48.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Mute Game Sounds?',
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Clear audio and guidance are key to mastering your quests. Are you sure you want to silence them?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    ScaleButton(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Keep It On',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : const Color(0xFF94A3B8),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Mute Anyway',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
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
              context.read<AuthBloc>().add(AuthReloadUser());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF2563EB),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20.h),
                                _buildProfileHeader(context, user),
                              ],
                            ),
                          ),
                        ),
                        collapseMode: CollapseMode.pin,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!user.isPremium) ...[
                              _buildPremiumBanner(context),
                            ],

                            SizedBox(height: 12.h),
                            const AdRewardCard(margin: EdgeInsets.zero),

                            SizedBox(height: 20.h),
                            _buildSectionHeader(context, 'Adventure Stats'),
                            SizedBox(height: 12.h),
                            _buildBentoStats(context, user),

                            SizedBox(height: 40.h),
                            _buildSectionHeader(context, 'Hall of Fame'),
                            SizedBox(height: 20.h),
                            _buildBadgesList(context, user),

                            SizedBox(height: 40.h),
                            _buildSectionHeader(context, 'Kids Stickers'),
                            SizedBox(height: 20.h),
                            _buildKidsStickersList(context, user),

                            SizedBox(height: 40.h),
                            _buildSectionHeader(context, 'App Preferences'),
                            SizedBox(height: 20.h),
                            _buildPreferencesList(context, user),

                            SizedBox(height: 140.h),
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
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = user.isPremium;
    final glowColor = isPremium
        ? const Color(0xFFF59E0B)
        : const Color(0xFF2563EB);

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isPremium ? 0.4 : 0.1),
                      blurRadius: isPremium ? 40 : 30,
                      spreadRadius: isPremium ? 2 : 0,
                      offset: const Offset(0, 10),
                    ),
                    if (user.level >= 200)
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Hero(
                  tag: 'profile_pic',
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isPremium || user.level >= 200)
                            ? const Color(0xFFF59E0B)
                            : Colors.transparent,
                        width: 3.r,
                      ),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                    ),
                    child: ClipOval(
                      child: user.photoUrl != null
                          ? ShimmerImage(imageUrl: user.photoUrl!)
                          : Icon(
                              Icons.person_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 60.r,
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 5.h,
                right: 5.w,
                child: ScaleButton(
                  onTap: () {
                    Haptics.vibrate(HapticsType.light);
                    _showImageSourceSheet(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: glowColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      isPremium ? Icons.star_rounded : Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: ScaleButton(
            onTap: () {
              Haptics.vibrate(HapticsType.selection);
              _showEditNameSheet(context, user.displayName ?? '');
            },
            child: GlassTile(
              borderRadius: BorderRadius.circular(20.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.displayName ?? 'Hero In Training',
                    style: GoogleFonts.outfit(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'ID',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPremium) ...[
              Icon(
                Icons.verified_rounded,
                color: const Color(0xFFF59E0B),
                size: 16.r,
              ),
              SizedBox(width: 4.w),
              Text(
                'PREMIUM MEMBER',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 4.r,
                height: 4.r,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              user.email,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildBadgesList(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedBadgesList = BadgeConstants.badges
        .where((b) => user.claimedLevelMilestones.contains(b.minLevel))
        .toList();

    if (earnedBadgesList.isEmpty) {
      return GlassTile(
        width: double.infinity,
        padding: EdgeInsets.all(32.w),
        borderRadius: BorderRadius.circular(32.r),
        child: Column(
          children: [
            VowlMascot(state: VowlMascotState.thinking, size: 60.r),
            SizedBox(height: 16.h),
            Text(
              'HALL OF FAME VACANT',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Claim milestones to display your legendary trophies here.',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220.h,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.7),
        physics: const BouncingScrollPhysics(),
        itemCount: earnedBadgesList.length,
        itemBuilder: (context, index) {
          final badge = earnedBadgesList[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  badge.color.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GlassTile(
              borderRadius: BorderRadius.circular(32.r),
              usePremiumStyle: true,
              child: Stack(
                children: [
                  Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(0.1),
                          alignment: FractionalOffset.center,
                          child: Image.asset(
                            'assets/images/mascot/gold_trophy.webp',
                            height: 140.h,
                            color: badge.color.withValues(alpha: 0.9),
                            colorBlendMode: BlendMode.screen,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -5, end: 5, duration: 2000.ms),

                  Positioned(
                    bottom: 20.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          badge.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'LEVEL ${badge.minLevel} ACHIEVED',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  Widget _buildKidsStickersList(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedStickers = user.kidsStickers;
    const totalPossible = 88; // 22 categories * 4 stickers

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.orange,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION PROGRESS',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange[400],
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${earnedStickers.length} / $totalPossible Stickers',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => context.push(AppRouter.kidsStickerBookRoute),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (earnedStickers.isNotEmpty) ...[
            SizedBox(height: 20.h),
            SizedBox(
              height: 50.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: earnedStickers.length.clamp(0, 6),
                itemBuilder: (context, index) {
                  final revIndex = earnedStickers.length - 1 - index;
                  final stickerId = earnedStickers[revIndex];
                  final emoji = KidsAssets.getStickerEmoji(stickerId);
                  return Container(
                    margin: EdgeInsets.only(right: 12.w),
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
            Text(
              'Start your collection in Kids Zone!',
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBentoStats(BuildContext context, UserEntity user) {
    return Column(
      children: [
        _buildAdventureLevelCard(context, user),

        SizedBox(height: 16.h),

        Row(
          children: [
            Expanded(
              child: _buildStatPod(
                context: context,
                title: 'Vowl Treasury',
                value: '${user.coins}',
                icon: Icons.paid_rounded,
                color: const Color(0xFF10B981),
                onTap: () => context.push(AppRouter.questCoinsRoute),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildStatPod(
                context: context,
                title: 'Daily Streak',
                value: '${user.currentStreak} Days',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => context.push(AppRouter.streakRoute),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

        SizedBox(height: 16.h),

        _buildAdventureXPCard(
          context,
          user,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildAdventureLevelCard(BuildContext context, UserEntity user) {
    return ScaleButton(
      onTap: () => context.push(AppRouter.levelRoute),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFF8B5CF6),
                size: 32.r,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT LEVEL',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Level ${user.level}',
                    style: GoogleFonts.outfit(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tap to view rank details',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black12,
              size: 28.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdventureXPCard(BuildContext context, UserEntity user) {
    final xpProgress = (user.totalExp % 100) / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () => context.push(AppRouter.adventureXPRoute),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: const Color(0xFF3B82F6),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADVENTURE XP',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${user.totalExp} Total Experience',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: 28.r,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS TO LEVEL ${user.level + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38
                            : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${(xpProgress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Stack(
                  children: [
                    Container(
                      height: 10.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 800.ms,
                      height: 10.h,
                      width:
                          (MediaQuery.of(context).size.width - 96.w) *
                          xpProgress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPod({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: () {
        Haptics.vibrate(HapticsType.medium);
        onTap();
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(height: 16.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return ScaleButton(
      onTap: () {
        Haptics.vibrate(HapticsType.selection);
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
                    'UPGRADE TO PREMIUM',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Get 2x Coins, No Ads & VIP Gifts',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black12,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesList(BuildContext context, UserEntity user) {
    return GlassTile(
      borderRadius: BorderRadius.circular(28.r),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          // Theme preferences have been unified to "Match System" for production stability
          // Manual switches removed to eliminate splash flicker and state mismatch
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            indent: 20.w,
            endIndent: 20.w,
          ),
          _buildSwitchTile(
            context,
            'Sound Effects',
            Icons.volume_up_rounded,
            Colors.pink,
            _soundEnabled,
            _toggleSound,
          ),
          if (user.isAdmin) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              indent: 20.w,
              endIndent: 20.w,
            ),
            _buildPreferenceTile(
              context,
              'Admin Dashboard',
              Icons.admin_panel_settings_rounded,
              Colors.orange,
              () {
                Haptics.vibrate(HapticsType.medium);
                context.push(AppRouter.adminRoute);
              },
            ),
          ],
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            indent: 20.w,
            endIndent: 20.w,
          ),
          _buildPreferenceTile(
            context,
            'Settings',
            Icons.settings_rounded,
            Colors.grey,
            () {
              Haptics.vibrate(HapticsType.medium);
              context.push(AppRouter.settingsRoute);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDisabled = onChanged == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: isDisabled
                    ? null
                    : (v) {
                        Haptics.vibrate(HapticsType.selection);
                        onChanged(v);
                      },
                activeThumbColor: color,
                activeTrackColor: color.withValues(alpha: 0.2),
                inactiveThumbColor: isDark ? Colors.white60 : Colors.white,
                inactiveTrackColor: isDark
                    ? Colors.white24
                    : const Color(0xFFE2E8F0),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameSheet(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                      'Update Identity',
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your name is visible to other explorers in the realm.',
                      style: GoogleFonts.outfit(
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
                        controller: nameController,
                        autofocus: true,
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter new name',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey),
                          border: InputBorder.none,
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
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty && newName != currentName) {
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
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.outfit(
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
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

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
                'Avatar Projection',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Choose a source to capture your manifestation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
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
                      label: 'Reality',
                      subtitle: 'Camera',
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
                      label: 'Memory',
                      subtitle: 'Gallery',
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
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 32.r),
            ),
            SizedBox(height: 16.h),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
