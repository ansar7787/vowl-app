import 'dart:ui';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:auto_size_text/auto_size_text.dart';

class VowlMascotScreen extends StatefulWidget {
  const VowlMascotScreen({super.key});

  @override
  State<VowlMascotScreen> createState() => _VowlMascotScreenState();
}

class _VowlMascotScreenState extends State<VowlMascotScreen> {
  final ValueNotifier<int> _activeTabIndex = ValueNotifier(0);
  late final HapticService _hapticService;

  /// Tracks the ID of the specific item currently being purchased/equipped.
  /// `null` means no item is processing. Replaces the old global boolean
  /// `_isProcessing` that blocked ALL tiles simultaneously with no per-item
  /// visual feedback.
  final ValueNotifier<String?> _processingItemId = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _hapticService = di.sl<HapticService>();
  }

  /// Starts a 5-second safety timeout that clears [_processingItemId] if
  /// the BlocListener hasn't already cleared it. Prevents the UI from
  /// staying locked forever if a server response is lost.
  void _startSafetyTimeout(String itemId) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _processingItemId.value == itemId) {
        _processingItemId.value = null;
      }
    });
  }

  void _showModernSnackbar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    CustomSnackBar.show(
      context: context,
      message: message,
      type: isSuccess ? CustomSnackBarType.success : CustomSnackBarType.error,
    );
  }

  @override
  void dispose() {
    _activeTabIndex.dispose();
    _processingItemId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = isMidnight
        ? const Color(0xFF020617)
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          curr.lastPurchaseType != null &&
          curr.lastPurchaseType != prev.lastPurchaseType,
      listener: (context, state) {
        // Clear per-item processing immediately on any server response.
        if (mounted) _processingItemId.value = null;

        if (state.lastPurchaseSuccess == true) {
          _hapticService.success();
          _showModernSnackbar(
            context,
            state.lastPurchaseType == 'vowl_mascot'
                ? context.tr(
                    'vowl_mascot.feedback_mascot_linked',
                    fallback: 'Mascot Linked!',
                  )
                : context.tr(
                    'vowl_mascot.feedback_augment_integrated',
                    fallback: 'Augment Integrated!',
                  ),
            true,
          );
        } else if (state.lastPurchaseSuccess == false) {
          _hapticService.error();
          _showModernSnackbar(
            context,
            state.message ??
                context.tr(
                  'vowl_mascot.feedback_sync_failed',
                  fallback: 'Sync Failed',
                ),
            false,
          );
        }
        context.read<ProfileBloc>().add(const ProfileClearPurchaseFeedback());
      },
      child: BlocSelector<AuthBloc, AuthState, UserEntity?>(
        selector: (state) => state.user,
        builder: (context, user) {
          if (user == null) {
            return Scaffold(
              backgroundColor: surfaceColor,
              body: const SafeArea(child: HomeShimmerLoading()),
            );
          }

          final bottomPad = MediaQuery.of(context).padding.bottom;

          return Scaffold(
            backgroundColor: surfaceColor,
            body: Stack(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _activeTabIndex,
                  builder: (context, activeTabIndex, _) {
                    return ValueListenableBuilder<String?>(
                      valueListenable: _processingItemId,
                      builder: (context, processingId, _) {
                        return CustomScrollView(
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
                                child: RepaintBoundary(
                                  child: _buildTabSwitcher(
                                    isDark,
                                    primaryColor,
                                    textColor,
                                    activeTabIndex,
                                  ),
                                ),
                              ),
                            ),

                            // Bottom padding accounts for the floating status
                            // bar overlay height + device safe area.
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom: 60.h + bottomPad + 20.h,
                              ),
                              sliver: activeTabIndex == 0
                                  ? _buildSelectionSliver(
                                      context,
                                      user,
                                      isDark,
                                      primaryColor,
                                      textColor,
                                      processingId,
                                    )
                                  : _buildBoutiqueSliver(
                                      context,
                                      user,
                                      isDark,
                                      primaryColor,
                                      textColor,
                                      processingId,
                                    ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                _buildEliteStatusOverlay(context, primaryColor, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Sliver App Bar
  // ===========================================================================

  Widget _buildSliverAppBar(
    BuildContext context,
    UserEntity user,
    Color textColor,
    bool isDark,
    Color primaryColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SliverAppBar(
      expandedHeight: 100.h,
      collapsedHeight: 70.h,
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
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.zero,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust threshold since we reduced max height
                  final isCollapsed = constraints.maxHeight <= 80.h;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left side: Back Button
                          Positioned(
                            left: 0,
                            child: Semantics(
                              button: true,
                              label: context.tr(
                                'common.back',
                                fallback: 'Back',
                              ),
                              child: ScaleButton(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRouter.homeRoute);
                                  }
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: 48.r,
                                    minHeight: 48.r,
                                  ),
                                  alignment: Alignment.center,
                                  child: ExcludeSemantics(
                                    child: Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: textColor.withValues(
                                          alpha: 0.05,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: textColor.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        isRtl
                                            ? Icons.arrow_forward_ios_rounded
                                            : Icons.arrow_back_ios_new_rounded,
                                        color: textColor,
                                        size: 14.r,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Center: Titles
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 70.w),
                              child: isCollapsed
                                  ? AutoSizeText(
                                      context.tr(
                                        'vowl_mascot.nest_title',
                                        fallback: 'Vowl Nest',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        letterSpacing: 2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      minFontSize: 10,
                                      overflow: TextOverflow.visible,
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AutoSizeText(
                                          context.tr(
                                            'vowl_mascot.nest_title',
                                            fallback: 'Vowl Nest',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w900,
                                            color: textColor,
                                            letterSpacing: 2,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          minFontSize: 12,
                                          overflow: TextOverflow.visible,
                                        ).animate().fadeIn(),
                                        AutoSizeText(
                                          context.tr(
                                            'vowl_mascot.nest_subtitle',
                                            fallback: 'Manage your companion',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            letterSpacing: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          minFontSize: 8,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Right side: Coins
                          Positioned(
                            right: 0,
                            child: _buildGreenDollarDisplay(
                              context,
                              user,
                              isDark,
                              primaryColor,
                            ),
                          ),
                        ],
                      ),
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
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
  ) {
    // One-shot entrance animation — no infinite shimmer. The old infinite
    // shimmer burned GPU every frame and psychologically signaled "loading"
    // when nothing was loading.
    return Semantics(
          label: context.tr(
            'home.coins_value_label',
            fallback: 'Coins',
            args: [user.coins.toString()],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    color: primaryColor,
                    size: 12.r,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    NumberFormat.decimalPattern().format(user.coins),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.1, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  // ===========================================================================
  // Tab Switcher — Animated Sliding Pill
  // ===========================================================================

  Widget _buildTabSwitcher(
    bool isDark,
    Color primaryColor,
    Color textColor,
    int activeTabIndex,
  ) {
    final tabs = [
      context.tr('vowl_mascot.tab_companion', fallback: 'Companion'),
      context.tr('vowl_mascot.tab_boutique', fallback: 'Boutique'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(6.r),
        blur: 0,
        child: SizedBox(
          height: 48.h,
          child: Stack(
            children: [
              // ── Sliding pill indicator ─────────────────────────────
              // AnimatedAlign slides the pill smoothly between tabs.
              AnimatedAlign(
                alignment: activeTabIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Tab labels (always visible, on top of pill) ────────
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = activeTabIndex == index;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: tabs[index],
                      child: GestureDetector(
                        onTap: () {
                          _hapticService.selection();
                          _activeTabIndex.value = index;
                        },
                        behavior: HitTestBehavior.opaque,
                        child: ExcludeSemantics(
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.withValues(alpha: 0.6),
                                letterSpacing: 1.5,
                              ),
                              child: Text(
                                tabs[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Companion Tab — Mascot Selection Grid
  // ===========================================================================

  Widget _buildSelectionSliver(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
    Color textColor,
    String? processingId,
  ) {
    final mascots = VowlAssets.mascotMap.keys.toList();
    // Responsive: 3 columns on tablets (>600dp), 2 on phones.
    final crossAxisCount = MediaQuery.sizeOf(context).width > 600 ? 3 : 2;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader(
            context.tr(
              'vowl_mascot.section_synchronized_elites',
              fallback: 'Synchronized Elites',
            ),
            textColor,
          ),
          SizedBox(height: 20.h),
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
            child: RepaintBoundary(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: crossAxisCount > 2 ? 0.82 : 0.85,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                itemCount: mascots.length,
                itemBuilder: (context, index) {
                  final id = mascots[index];
                  final emoji = VowlAssets.mascotMap[id]!;
                  final name = VowlAssets.mascotNames[id]!;
                  final isOwned = user.vowlOwnedMascots.contains(id);
                  final price = VowlAssets.getMascotPrice(id);
                  final isSelected =
                      user.vowlMascot == id ||
                      (user.vowlMascot == null && id == 'vowl_prime');

                  return _buildMascotTile(
                    context,
                    id,
                    name,
                    emoji,
                    isSelected,
                    isOwned,
                    price,
                    isDark,
                    primaryColor,
                    textColor,
                    user,
                    processingId,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 32.h),
          if (user.vowlMascot != null)
            RepaintBoundary(
              child: _buildEquippedSection(
                context,
                user,
                isDark,
                primaryColor,
                textColor,
              ),
            ),
        ]),
      ),
    );
  }

  // ===========================================================================
  // Boutique Tab — Accessory Grid
  // ===========================================================================

  Widget _buildBoutiqueSliver(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
    Color textColor,
    String? processingId,
  ) {
    final accessories = VowlAssets.accessoryMap.keys.toList();
    final crossAxisCount = MediaQuery.sizeOf(context).width > 600 ? 3 : 2;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader(
            context.tr(
              'vowl_mascot.section_cybernetic_augments',
              fallback: 'Cybernetic Augments',
            ),
            textColor,
          ),
          SizedBox(height: 20.h),
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
            child: RepaintBoundary(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: crossAxisCount > 2 ? 0.75 : 0.78,
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
                    processingId,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 100.h),
        ]),
      ),
    );
  }

  // ===========================================================================
  // Mascot Tile
  // ===========================================================================

  Widget _buildMascotTile(
    BuildContext context,
    String id,
    String name,
    String emoji,
    bool isSelected,
    bool isOwned,
    int price,
    bool isDark,
    Color primaryColor,
    Color textColor,
    UserEntity user,
    String? processingId,
  ) {
    final canAfford = isOwned || user.coins >= price;
    final isProcessing = processingId == id;

    final statusLabel = isSelected
        ? context.tr('vowl_mascot.equipped_status', fallback: 'Equipped')
        : isOwned
        ? context.tr('vowl_mascot.sync_ready', fallback: 'Sync Ready')
        : (canAfford
              ? '$price 🪙'
              : context.tr('vowl_mascot.locked_label', fallback: 'Locked'));

    // ── Avatar widget ──────────────────────────────────────────────────
    // The buddy emoji ALWAYS stays visible — even during loading. A
    // circular progress ring wraps around it instead of replacing it.
    // Hiding the buddy on tap felt jarring; the user needs to see what
    // they picked.
    Widget avatar = Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : (!isOwned && !canAfford)
            ? textColor.withValues(alpha: 0.02)
            : textColor.withValues(alpha: 0.03),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: isProcessing ? 0.5 : ((!isOwned && !canAfford) ? 0.4 : 1.0),
          duration: const Duration(milliseconds: 300),
          child: Text(emoji, style: TextStyle(fontSize: 36.sp)),
        ),
      ),
    );

    // When processing: wrap the avatar with a sleek progress ring so the
    // user sees "this buddy is loading" — not "the buddy vanished."
    if (isProcessing) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          SizedBox(
            width: 64.r,
            height: 64.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: primaryColor,
            ),
          ),
        ],
      );
    } else if (isSelected) {
      // Only the selected mascot gets a subtle breathing animation.
      // Every other tile is static — no shimmers, no infinite animations.
      avatar = avatar
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${name.toUpperCase()}, $statusLabel',
      child: ScaleButton(
        onTap: isSelected || isProcessing
            ? null
            : () {
                if (_processingItemId.value != null) return;

                if (isOwned) {
                  _processingItemId.value = id;
                  _hapticService.light();
                  context.read<ProfileBloc>().add(
                    ProfileUpdateVowlMascotRequested(id),
                  );
                  _startSafetyTimeout(id);
                } else if (canAfford) {
                  _processingItemId.value = id;
                  _hapticService.light();
                  context.read<ProfileBloc>().add(
                    ProfileBuyVowlMascotRequested(id, price),
                  );
                  _startSafetyTimeout(id);
                } else {
                  _hapticService.error();
                  _showModernSnackbar(
                    context,
                    context.tr(
                      'vowl_mascot.feedback_insufficient_credits',
                      fallback: 'Insufficient Credits',
                    ),
                    false,
                  );
                }
              },
        child: ExcludeSemantics(
          child: GlassTile(
            borderRadius: BorderRadius.circular(24.r),
            blur: 0,
            child: Container(
              width: double.infinity,
              height: double.infinity,
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
                  avatar,

                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: AutoSizeText(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? primaryColor
                            : (!isOwned && !canAfford)
                            ? textColor.withValues(alpha: 0.4)
                            : textColor,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      minFontSize: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(height: 8.h),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: primaryColor,
                      size: 14.r,
                    ).animate().scale()
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isOwned
                            ? primaryColor.withValues(alpha: 0.15)
                            : (canAfford
                                  ? primaryColor.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isOwned
                              ? primaryColor.withValues(alpha: 0.3)
                              : (canAfford
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: isOwned
                          ? AutoSizeText(
                              context.tr(
                                'vowl_mascot.sync_ready',
                                fallback: 'Sync Ready',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.sp,
                                color: primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              minFontSize: 5,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  canAfford
                                      ? Icons.attach_money_rounded
                                      : Icons.lock_rounded,
                                  color: canAfford ? primaryColor : Colors.grey,
                                  size: 10.r,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  NumberFormat.decimalPattern().format(price),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    color: canAfford
                                        ? primaryColor
                                        : Colors.grey.withValues(alpha: 0.8),
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
      ),
    );
  }

  // ===========================================================================
  // Equipped Mascot Section
  // ===========================================================================

  Widget _buildEquippedSection(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final mascotName = VowlAssets.getMascotName(
      user.vowlMascot ?? 'vowl_prime',
    ).toUpperCase();
    final accessoryLabel = user.vowlEquippedAccessory != null
        ? VowlAssets.getAccessoryName(user.vowlEquippedAccessory!)
        : context.tr(
            'vowl_mascot.no_augmentations',
            fallback: 'No augmentations yet',
          );

    return Semantics(
      label:
          '${context.tr('vowl_mascot.elite_interface_label', fallback: 'Elite Interface')} $mascotName. $accessoryLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context.tr(
              'vowl_mascot.section_elite_neural_link',
              fallback: 'Elite Neural Link',
            ),
            textColor,
          ),
          SizedBox(height: 20.h),
          ExcludeSemantics(
            child: GlassTile(
              borderRadius: BorderRadius.circular(28.r),
              blur: 0,
              child: Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Breathing glow ring — replaces the old infinite
                        // rotate + shimmer combo that felt cheap. This
                        // gentle fade pulse is premium and subtle.
                        Container(
                              width: 84.r,
                              height: 84.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(
                              begin: 0.6,
                              end: 1.0,
                              duration: 3.seconds,
                              curve: Curves.easeInOut,
                            ),
                        Text(
                          VowlAssets.getMascotEmoji(
                            user.vowlMascot ?? 'vowl_prime',
                          ),
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
                            context.tr(
                              'vowl_mascot.elite_interface_label',
                              fallback: 'Elite Interface',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: 2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mascotName,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              Flexible(
                                child: Text(
                                  accessoryLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  // ===========================================================================
  // Accessory Tile
  // ===========================================================================

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
    UserEntity user,
    String? processingId,
  ) {
    final canAfford = user.coins >= price;
    final isProcessing = processingId == id;

    final statusLabel = isOwned
        ? (isEquipped
              ? context.tr(
                  'vowl_mascot.action_disconnect',
                  fallback: 'Disconnect',
                )
              : context.tr('vowl_mascot.action_link', fallback: 'Link'))
        : context.tr(
            'vowl_mascot.price_label',
            fallback: 'Price',
            args: [price.toString()],
          );
    final accessibleActionLabel = '${name.toUpperCase()}, $statusLabel';

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      blur: 0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isEquipped ? primaryColor : textColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child:
                  ExcludeSemantics(
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: (!isOwned && !canAfford) ? 0.4 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: 48.sp),
                            ),
                          ),
                        ),
                      )
                      .animate(target: isEquipped ? 1 : 0)
                      .shimmer(color: primaryColor.withValues(alpha: 0.3)),
            ),
            AutoSizeText(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: (!isOwned && !canAfford)
                    ? textColor.withValues(alpha: 0.4)
                    : (isDark ? textColor.withValues(alpha: 0.9) : textColor),
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Semantics(
              button: true,
              enabled: isOwned || canAfford,
              label: accessibleActionLabel,
              child: ExcludeSemantics(
                child: isOwned
                    ? _buildActionButton(
                        label: isEquipped
                            ? context.tr(
                                'vowl_mascot.action_disconnect',
                                fallback: 'Disconnect',
                              )
                            : context.tr(
                                'vowl_mascot.action_link',
                                fallback: 'Link',
                              ),
                        color: isEquipped
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : primaryColor.withValues(alpha: 0.15),
                        textColor: isEquipped ? Colors.redAccent : primaryColor,
                        isLoading: isProcessing,
                        onTap: isProcessing
                            ? null
                            : () {
                                if (_processingItemId.value != null) return;
                                _processingItemId.value = id;
                                _hapticService.selection();
                                context.read<ProfileBloc>().add(
                                  ProfileEquipVowlAccessoryRequested(
                                    isEquipped ? null : id,
                                  ),
                                );
                                _startSafetyTimeout(id);
                              },
                        primaryColor: primaryColor,
                      )
                    : _buildActionButton(
                        label: NumberFormat.decimalPattern().format(price),
                        color: canAfford
                            ? primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        textColor: canAfford ? primaryColor : Colors.grey,
                        isLoading: isProcessing,
                        onTap: isProcessing
                            ? null
                            : () {
                                if (_processingItemId.value != null) return;
                                if (canAfford) {
                                  _processingItemId.value = id;
                                  _hapticService.selection();
                                  context.read<ProfileBloc>().add(
                                    ProfileBuyVowlAccessoryRequested(id, price),
                                  );
                                  _startSafetyTimeout(id);
                                } else {
                                  _hapticService.error();
                                  _showModernSnackbar(
                                    context,
                                    context.tr(
                                      'vowl_mascot.feedback_insufficient_credits',
                                      fallback: 'Insufficient Credits',
                                    ),
                                    false,
                                  );
                                }
                              },
                        icon: Icons.attach_money_rounded,
                        primaryColor: primaryColor,
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ===========================================================================
  // Shared Action Button — Now with loading spinner support
  // ===========================================================================

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
    IconData? icon,
    required Color primaryColor,
    bool isLoading = false,
  }) {
    return ScaleButton(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 40.h),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isLoading ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isLoading
                ? textColor.withValues(alpha: 0.15)
                : textColor.withValues(alpha: 0.3),
          ),
        ),
        child: isLoading
            ? VowlButtonSpinner(size: 16, color: textColor)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14.r, color: textColor),
                    SizedBox(width: 2.w),
                  ],
                  Flexible(
                    child: AutoSizeText(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      minFontSize: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // Section Header
  // ===========================================================================

  Widget _buildSectionHeader(String label, Color textColor) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          SizedBox(
            width: 4.w,
            height: 16.h,
            child: const ColoredBox(color: Colors.greenAccent),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AutoSizeText(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: textColor.withValues(alpha: 0.7),
                letterSpacing: 2.5,
              ),
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Bottom Status Bar — with SafeArea bottom padding
  // ===========================================================================

  Widget _buildEliteStatusOverlay(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 60.h + bottomPad,
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
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                bottom: bottomPad,
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: primaryColor,
                      size: 14.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AutoSizeText(
                        context.tr(
                          'vowl_mascot.status_bar_text',
                          fallback: 'Status OK',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryColor.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        minFontSize: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildSyncIndicator(primaryColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sync indicator bars — slow breathing pulse (2s cycle) instead of the
  /// old 600ms frenetic animation. Calm enough to feel "alive" without
  /// burning GPU cycles on something nobody watches after 0.5 seconds.
  Widget _buildSyncIndicator(Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleY(
              begin: 0.7,
              end: 1.0,
              delay: (index * 150).ms,
              duration: 2.seconds,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}
