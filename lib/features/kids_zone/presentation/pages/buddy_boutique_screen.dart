import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class BuddyBoutiqueScreen extends StatefulWidget {
  const BuddyBoutiqueScreen({super.key});

  @override
  State<BuddyBoutiqueScreen> createState() => _BuddyBoutiqueScreenState();
}

class _BuddyBoutiqueScreenState extends State<BuddyBoutiqueScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update filtered grid
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          KidsBackgroundRenderer(
            painterName: 'KidsWorldBackground',
            shaderName: 'magic_twinkle',
            primaryColor: isDark ? const Color(0xFF1E3A8A) : Colors.blue.shade100,
            gameType: 'shop',
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              _buildBuddyPassportPreview(context, isDark),
              _buildCurrencyHeader(context, isDark),
              _buildCategoryTabs(isDark),
              _buildShopGrid(context, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
                  child: _buildWatchAndEarn(context, isDark),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70.h,
      automaticallyImplyLeading: false,
      title: GlassTile(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        borderRadius: BorderRadius.circular(24.r),
        child: Row(
          children: [
            SizedBox(
              width: 32.r,
              height: 32.r,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18.r,
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Buddy Boutique',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyPassportPreview(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;

          return Container(
            margin: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)]
                    : [Colors.white, const Color(0xFFF1F5F9)],
              ),
              borderRadius: BorderRadius.circular(35.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.blue : Colors.black).withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "BUDDY PASSPORT",
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                          Text(
                            "Holographic Identity",
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.fingerprint_rounded, color: Colors.blue[400], size: 24.r),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Glow
                      Container(
                        width: 140.r,
                        height: 140.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.blue.withValues(alpha: 0.2), Colors.transparent],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),

                      // Mascot
                      VowlMascot(
                        size: 110.r,
                        useFloatingAnimation: true,
                        state: VowlMascotState.happy,
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPassportTag(_getBuddyRank(user?.level ?? 1), (user?.level ?? 1) > 25 ? Colors.purpleAccent : Colors.green, isDark),
                        SizedBox(width: 8.w),
                        _buildPassportTag("STREAK: ${user?.currentStreak ?? 0}", Colors.orangeAccent, isDark),
                        SizedBox(width: 8.w),
                        _buildPassportTag("LVL: ${user?.level ?? 1}", Colors.blue, isDark),
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

  Widget _buildCurrencyHeader(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final coins = state.user?.kidsCoins ?? 0;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.directions_car_filled_rounded, color: Colors.redAccent, size: 32),
                ),
                SizedBox(width: 18.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("KIDS COINS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 2)),
                      Text("$coins", style: GoogleFonts.outfit(fontSize: 28.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          tabs: [
            _buildTab("All", Icons.apps_rounded, const Color(0xFF6366F1), isDark),
            _buildTab("Clothes", Icons.checkroom_rounded, const Color(0xFFEC4899), isDark),
            _buildTab("Toys", Icons.toys_rounded, const Color(0xFFEF4444), isDark),
            _buildTab("Magic", Icons.auto_awesome_rounded, const Color(0xFFA855F7), isDark),
            _buildTab("Buddies", Icons.pets_rounded, const Color(0xFF10B981), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, Color color, bool isDark) {
    final isSelected = _tabController.index == ["All", "Clothes", "Toys", "Magic", "Buddies"].indexOf(label);
    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.r, color: isSelected ? Colors.white : color),
            SizedBox(width: 8.w),
            Text(label, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
          ],
        ),
      ),
    );
  }

  Widget _buildShopGrid(BuildContext context, bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final owned = user?.kidsOwnedAccessories ?? [];
        final equipped = user?.kidsEquippedAccessory;
        final categories = ["All", "Clothes", "Toys", "Magic", "Buddies"];
        final currentCategory = categories[_tabController.index];
        final filteredItems = KidsAssets.shopItems
            .where((i) => currentCategory == "All" || i['category'] == currentCategory)
            .toList()..sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));

        return SliverPadding(
          padding: EdgeInsets.all(24.r),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = filteredItems[index];
              return _buildShopItem(context, item, isDark, isOwned: owned.contains(item['id']), isEquipped: equipped == item['id']);
            }, childCount: filteredItems.length),
          ),
        );
      },
    );
  }

  Widget _buildShopItem(BuildContext context, Map<String, dynamic> item, bool isDark, {required bool isOwned, required bool isEquipped}) {
    return ScaleButton(
      onTap: () => _handleItemAction(context, item, isOwned, isEquipped),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? (item['color'] as Color).withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: isEquipped ? (item['color'] as Color) : (isDark ? Colors.white10 : Colors.white), width: 2),
            ),
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['icon'] as String, style: TextStyle(fontSize: 40.sp)).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                SizedBox(height: 12.h),
                Text(item['name'] as String, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                SizedBox(height: 8.h),
                if (isEquipped)
                  _buildItemStatusTag("EQUIPPED", item['color'] as Color, item['color'] as Color)
                else if (isOwned)
                  _buildItemStatusTag("EQUIP", isDark ? Colors.white10 : Colors.grey[200]!, isDark ? Colors.white70 : Colors.black54)
                else
                  _buildPriceTag(item['price'] as int, item['color'] as Color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemStatusTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12.r)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: textColor)),
    );
  }

  Widget _buildPriceTag(int price, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_filled_rounded, color: Color(0xFFEF4444), size: 14),
          SizedBox(width: 4.w),
          Text(
            "$price",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemAction(BuildContext context, Map<String, dynamic> item, bool isOwned, bool isEquipped) {
    Haptics.vibrate(HapticsType.selection);
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state.user;
    if (user == null) return;
    final isMascot = (item['id'] as String).startsWith('mascot_');

    if (isEquipped) {
      if (isMascot) return;
      context.read<ProfileBloc>().add(const ProfileEquipAccessoryRequested(null));
      return;
    }

    if (isOwned) {
      if (isMascot) {
        context.read<ProfileBloc>().add(ProfileUpdateMascotRequested(item['id'] as String));
      } else {
        context.read<ProfileBloc>().add(ProfileEquipAccessoryRequested(item['id'] as String));
      }
      return;
    }

    if (user.kidsCoins < (item['price'] as int)) {
      di.sl<SoundService>().playWrong();
      _showModernNotification(context, "NOT ENOUGH COINS! 🚗", isError: true);
      return;
    }

    _confettiController.play();
    di.sl<SoundService>().playCorrect();
    
    // The Bloc automatically handles deducting coins and adding to owned items
    context.read<ProfileBloc>().add(ProfileBuyAccessoryRequested(item['id'] as String, item['price'] as int));
    
    // Auto-equip the item they just purchased
    if (isMascot) {
      context.read<ProfileBloc>().add(ProfileUpdateMascotRequested(item['id'] as String));
    } else {
      context.read<ProfileBloc>().add(ProfileEquipAccessoryRequested(item['id'] as String));
    }
    
    _showModernNotification(context, "PURCHASE SUCCESSFUL! ✨");
  }

  Widget _buildWatchAndEarn(BuildContext context, bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isPremium = state.user?.isPremium ?? false;
        return ScaleButton(
          onTap: () {
            di.sl<AdService>().showRewardedAd(
              isPremium: isPremium,
              onUserEarnedReward: (reward) {
                di.sl<SoundService>().playCorrect();
                context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(10));
                _showModernNotification(context, "AWARDED 10 KIDS COINS! 🚗✨");
              },
              onDismissed: () {},
            );
          },
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFEF4444), const Color(0xFF991B1B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("WATCH & EARN", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2)),
                      Text("Get 10 Kids Coins", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white24);
      },
    );
  }

  String _getBuddyRank(int level) {
    if (level < 10) return "SPROUTY BUDDY 🌱";
    if (level < 25) return "STAR BUDDY ⭐";
    if (level < 50) return "GALAXY GUARDIAN 🌌";
    return "LEGENDARY HERO 👑";
  }

  Widget _buildPassportTag(String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 8.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
    );
  }

  void _showModernNotification(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.h, left: 20.w, right: 20.w,
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            borderRadius: BorderRadius.circular(25.r),
            borderColor: isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isError ? Colors.redAccent : Colors.greenAccent, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isError
                          ? Colors.redAccent
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -1, end: 0, curve: Curves.easeOutBack).fadeIn().then(delay: 2000.ms).fadeOut().slideY(begin: 0, end: -1),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}
