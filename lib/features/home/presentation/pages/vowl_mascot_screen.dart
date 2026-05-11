import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/presentation/widgets/banner_ad_widget.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class VowlMascotScreen extends StatefulWidget {
  const VowlMascotScreen({super.key});

  @override
  State<VowlMascotScreen> createState() => _VowlMascotScreenState();
}

class _VowlMascotScreenState extends State<VowlMascotScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;
  final HapticService _hapticService = HapticService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _activeTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showModernSnackbar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: 3.seconds,
        content: GlassTile(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: (isSuccess ? Colors.greenAccent : Colors.redAccent)
                    .withValues(alpha: 0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  (isSuccess ? Colors.green : Colors.red).withValues(
                    alpha: 0.15,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSuccess
                      ? Icons.offline_bolt_rounded
                      : Icons.report_problem_rounded,
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  size: 24.r,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess ? 'SYSTEM SYNC FEEDBACK' : 'SECURITY ALERT',
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: isSuccess
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        message.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.greenAccent;
    final surfaceColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          curr.lastPurchaseType != null &&
          curr.lastPurchaseType != prev.lastPurchaseType,
      listener: (context, state) {
        if (state.lastPurchaseSuccess == true) {
          _hapticService.success();
          _showModernSnackbar(
            context,
            state.lastPurchaseType == 'vowl_mascot'
                ? 'Neural Link established successfully'
                : 'Augmentation integrated to system',
            true,
          );
        } else if (state.lastPurchaseSuccess == false) {
          _hapticService.error();
          _showModernSnackbar(
            context,
            state.message ?? 'System synchronization failed',
            false,
          );
        }
        // Clear feedback to prevent repeat
        context.read<ProfileBloc>().add(const ProfileClearPurchaseFeedback());
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          return Scaffold(
            backgroundColor: surfaceColor,
            body: Stack(
              children: [
                MeshGradientBackground(
                  colors: isDark
                      ? [
                          primaryColor.withValues(alpha: 0.25),
                          Colors.green.withValues(alpha: 0.15),
                        ]
                      : [
                          primaryColor.withValues(alpha: 0.12),
                          Colors.green.withValues(alpha: 0.08),
                        ],
                ),

                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(
                      context,
                      user,
                      textColor,
                      isDark,
                      primaryColor,
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: _buildTabSwitcher(
                          isDark,
                          primaryColor,
                          textColor,
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: EdgeInsets.only(bottom: 100.h),
                      sliver: _activeTabIndex == 0
                          ? _buildSelectionSliver(
                              context,
                              user,
                              isDark,
                              primaryColor,
                              textColor,
                            )
                          : _buildBoutiqueSliver(
                              context,
                              user,
                              isDark,
                              primaryColor,
                              textColor,
                            ),
                    ),
                  ],
                ),

                _buildEliteStatusOverlay(primaryColor, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    dynamic user,
    Color textColor,
    bool isDark,
    Color primaryColor,
  ) {
    return SliverAppBar(
      expandedHeight: 120.h,
      collapsedHeight: 80.h,
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(top: ScreenUtil().statusBarHeight),
            child: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.zero,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final isCollapsed = constraints.maxHeight <= 90.h;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        ScaleButton(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: textColor,
                              size: 14.r,
                            ),
                          ),
                        ),
                        // 1. Fix Overflow: Wrap center column in Expanded
                        const Expanded(child: SizedBox()),
                        if (!isCollapsed)
                          Expanded(
                            flex: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VOWL NEST',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: 3,
                                  ),
                                ).animate().fadeIn(),
                                Text(
                                  'COMPANION SANCTUARY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor.withValues(alpha: 0.7),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'VOWL NEST',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: 2,
                            ),
                          ),
                        const Expanded(child: SizedBox()),
                        _buildGreenDollarDisplay(user, isDark, primaryColor),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreenDollarDisplay(
    dynamic user,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money_rounded, color: primaryColor, size: 16.r),
          SizedBox(width: 4.w),
          Text(
            '${user.coins}',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    ).animate().shimmer(
      duration: 2.seconds,
      color: primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildTabSwitcher(bool isDark, Color primaryColor, Color textColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'COMPANION', primaryColor),
          _buildTabItem(1, 'BOUTIQUE', primaryColor),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, Color primaryColor) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _hapticService.selection();
          setState(() {
            _activeTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18.r),
            border: isSelected
                ? Border.all(color: primaryColor.withValues(alpha: 0.4))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: isSelected ? primaryColor : Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSliver(
    BuildContext context,
    dynamic user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final mascots = VowlAssets.mascotMap.keys.toList();
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader('SYNCHRONIZED ELITES', textColor),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: mascots.length,
            itemBuilder: (context, index) {
              final id = mascots[index];
              final emoji = VowlAssets.mascotMap[id]!;
              final name = VowlAssets.mascotNames[id]!;
              // 2. Unlock all mascots (remove isOwned check for switching)
              final isSelected =
                  user.vowlMascot == id ||
                  (user.vowlMascot == null && id == 'vowl_prime');

              return _buildMascotTile(
                context,
                id,
                name,
                emoji,
                isSelected,
                isDark,
                primaryColor,
                textColor,
              );
            },
          ),
          SizedBox(height: 32.h),
          const BannerAdWidget(),
          SizedBox(height: 32.h),
          if (user.vowlMascot != null)
            _buildEquippedSection(user, isDark, primaryColor, textColor),
        ]),
      ),
    );
  }

  Widget _buildBoutiqueSliver(
    BuildContext context,
    dynamic user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final accessories = VowlAssets.accessoryMap.keys.toList();
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader('CYBERNETIC AUGMENTS', textColor),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: accessories.length,
            itemBuilder: (context, index) {
              final id = accessories[index];
              final emoji = VowlAssets.accessoryMap[id]!;
              final name = VowlAssets.accessoryNames[id]!;
              final price = VowlAssets.accessoryPrices[id]!;
              final isOwned = user.vowlOwnedAccessories.contains(id);
              final isEquipped = user.vowlEquippedAccessory == id;

              return _buildAccessoryTile(
                context,
                id,
                name,
                emoji,
                price,
                isOwned,
                isEquipped,
                isDark,
                primaryColor,
                textColor,
                user,
              );
            },
          ),
          SizedBox(height: 32.h),
          const BannerAdWidget(),
          SizedBox(height: 100.h),
        ]),
      ),
    );
  }

  Widget _buildMascotTile(
    BuildContext context,
    String id,
    String name,
    String emoji,
    bool isSelected,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    return ScaleButton(
      onTap: _isProcessing ? null : () async {
        setState(() => _isProcessing = true);
        _hapticService.light();
        context.read<ProfileBloc>().add(ProfileUpdateVowlMascotRequested(id));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => _isProcessing = false);
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : textColor.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3. Add Premium Tile Animation
              Container(
                    width: 60.r,
                    height: 60.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.15)
                          : textColor.withValues(alpha: 0.03),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 36.sp)),
                    ),
                  )
                  .animate(onPlay: (c) => isSelected ? c.repeat() : c.stop())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .shimmer(
                    duration: 3.seconds,
                    color: primaryColor.withValues(alpha: 0.3),
                  ),

              SizedBox(height: 12.h),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? primaryColor : textColor,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 8.h),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: primaryColor,
                  size: 14,
                ).animate().scale()
              else
                Text(
                  'SYNC READY',
                  style: GoogleFonts.outfit(
                    fontSize: 8.sp,
                    color: textColor.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquippedSection(
    dynamic user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ELITE NEURAL LINK', textColor),
        SizedBox(height: 20.h),
        GlassTile(
          borderRadius: BorderRadius.circular(28.r),
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 84.r,
                          height: 84.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 5.seconds)
                        .shimmer(color: primaryColor.withValues(alpha: 0.2)),
                    Text(
                      VowlAssets.mascotMap[user.vowlMascot ?? 'vowl_prime']!,
                      style: TextStyle(fontSize: 42.sp),
                    ),
                  ],
                ),
                SizedBox(width: 24.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELITE INTERFACE:',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        VowlAssets
                            .mascotNames[user.vowlMascot ?? 'vowl_prime']!
                            .toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_fix_high_rounded,
                            color: primaryColor,
                            size: 14.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            user.vowlEquippedAccessory != null
                                ? VowlAssets.accessoryNames[user
                                      .vowlEquippedAccessory!]!
                                : 'NO AUGMENTATIONS',
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildAccessoryTile(
    BuildContext context,
    String id,
    String name,
    String emoji,
    int price,
    bool isOwned,
    bool isEquipped,
    bool isDark,
    Color primaryColor,
    Color textColor,
    dynamic user,
  ) {
    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isEquipped ? primaryColor : textColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child:
                  Center(
                        child: Text(emoji, style: TextStyle(fontSize: 48.sp)),
                      )
                      .animate(target: isEquipped ? 1 : 0)
                      .shimmer(color: primaryColor.withValues(alpha: 0.3)),
            ),
            Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? textColor.withValues(alpha: 0.9) : textColor,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12.h),
            if (isOwned)
              _buildActionButton(
                label: isEquipped ? 'DISCONNECT' : 'LINK',
                color: isEquipped
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.15),
                textColor: isEquipped ? Colors.redAccent : primaryColor,
                onTap: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  _hapticService.selection();
                  context.read<ProfileBloc>().add(
                    ProfileEquipVowlAccessoryRequested(isEquipped ? null : id),
                  );
                  await Future.delayed(const Duration(milliseconds: 1000));
                  if (mounted) setState(() => _isProcessing = false);
                },
                primaryColor: primaryColor,
              )
            else
              _buildActionButton(
                label: '$price',
                color: user.coins >= price
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                textColor: user.coins >= price ? primaryColor : Colors.grey,
                onTap: _isProcessing ? null : () async {
                  if (user.coins >= price) {
                    setState(() => _isProcessing = true);
                    _hapticService.selection();
                    context.read<ProfileBloc>().add(
                      ProfileBuyVowlAccessoryRequested(id, price),
                    );
                    await Future.delayed(const Duration(milliseconds: 1500));
                    if (mounted) setState(() => _isProcessing = false);
                  } else {
                    // 4. Implement real error feedback for insufficient coins
                    _hapticService.error();
                    _showModernSnackbar(
                      context,
                      'Insufficient Elite credits for this augment',
                      false,
                    );
                  }
                },
                icon: Icons.attach_money_rounded,
                primaryColor: primaryColor,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
    IconData? icon,
    required Color primaryColor,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.r, color: textColor),
              SizedBox(width: 2.w),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color textColor) {
    return Row(
      children: [
        SizedBox(width: 4.w, height: 16.h, child: ColoredBox(color: Colors.greenAccent)),
        SizedBox(width: 12.w),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: textColor.withValues(alpha: 0.7),
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEliteStatusOverlay(Color primaryColor, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Icon(Icons.security_rounded, color: primaryColor, size: 14.r),
                SizedBox(width: 12.w),
                Text(
                  'NEURAL CONNECTION STABLE // ELITE STATUS ACTIVE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                _buildSyncIndicator(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncIndicator(Color primaryColor) {
    return Row(
      children: List.generate(4, (index) {
        return Container(
              width: 3.w,
              height: 10.h,
              margin: EdgeInsets.only(left: 3.w),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scaleY(
              begin: 0.5,
              end: 1.5,
              delay: (index * 200).ms,
              duration: 600.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

