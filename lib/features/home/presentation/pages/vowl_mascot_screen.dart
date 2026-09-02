import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // Use the app-wide injected singleton instead of constructing a new
    // instance, consistent with how every other screen obtains it.
    _hapticService = di.sl<HapticService>();
  }

  void _showModernSnackbar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    // BUG FIX: this previously discarded the real, descriptive `message`
    // (e.g. "Insufficient Elite credits for this augment") in favor of a
    // generic fixed title, AND always rendered as an error-styled toast
    // even on success. Both the displayed text and the visual treatment
    // now correctly reflect what actually happened.
    CustomSnackBar.show(
      context: context,
      message: message,
      type: isSuccess ? CustomSnackBarType.success : CustomSnackBarType.error,
    );
  }

  @override
  void dispose() {
    _activeTabIndex.dispose();
    _isProcessing.dispose();
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
        // Clear feedback to prevent repeat
        context.read<ProfileBloc>().add(const ProfileClearPurchaseFeedback());
      },
      // BlocSelector instead of BlocBuilder: this screen renders two
      // GridViews plus a sliver app bar, so unrelated AuthState changes
      // (anything other than the user actually changing) no longer force a
      // full rebuild of all of that.
      child: BlocSelector<AuthBloc, AuthState, UserEntity?>(
        selector: (state) => state.user,
        builder: (context, user) {
          if (user == null) {
            return Scaffold(
              backgroundColor: surfaceColor,
              body: const SafeArea(child: HomeShimmerLoading()),
            );
          }

          return Scaffold(
            backgroundColor: surfaceColor,
            body: Stack(
              children: [
                MeshGradientBackground(
                  colors: isDark
                      ? [
                          primaryColor.withValues(alpha: 0.25),
                          primaryColor.withValues(alpha: 0.15),
                        ]
                      : [
                          primaryColor.withValues(alpha: 0.12),
                          primaryColor.withValues(alpha: 0.08),
                        ],
                ),

                ValueListenableBuilder<int>(
                  valueListenable: _activeTabIndex,
                  builder: (context, activeTabIndex, _) {
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

                        SliverPadding(
                          padding: EdgeInsets.only(bottom: 100.h),
                          sliver: activeTabIndex == 0
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

  Widget _buildSliverAppBar(
    BuildContext context,
    UserEntity user,
    Color textColor,
    bool isDark,
    Color primaryColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
                        Semantics(
                          button: true,
                          label: context.tr('common.back', fallback: 'Back'),
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
                                minWidth: 32.r,
                                minHeight: 32.r,
                              ),
                              alignment: Alignment.center,
                              child: ExcludeSemantics(
                                child: Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: textColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Icon(
                                    isRtl
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.arrow_back_ios_new_rounded,
                                    color: textColor,
                                    size: 12.r,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        if (!isCollapsed)
                          Expanded(
                            flex: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AutoSizeText(
                                  context.tr(
                                    'vowl_mascot.nest_title',
                                    fallback: 'Vowl Nest',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: 2,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 8,
                                  overflow: TextOverflow.ellipsis,
                                ).animate().fadeIn(),
                                AutoSizeText(
                                  context.tr(
                                    'vowl_mascot.nest_subtitle',
                                    fallback: 'Manage your companion',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 7.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor.withValues(alpha: 0.8),
                                    letterSpacing: 1.0,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: AutoSizeText(
                              context.tr(
                                'vowl_mascot.nest_title',
                                fallback: 'Vowl Nest',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: 2,
                              ),
                              maxLines: 1,
                              minFontSize: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const Expanded(child: SizedBox()),
                        _buildGreenDollarDisplay(
                          context,
                          user,
                          isDark,
                          primaryColor,
                        ),
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
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
  ) {
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
              Icon(Icons.attach_money_rounded, color: primaryColor, size: 12.r),
              SizedBox(width: 2.w),
              Text(
                '${user.coins}',
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
    ).animate().shimmer(
      duration: 2.seconds,
      color: primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildTabSwitcher(
    bool isDark,
    Color primaryColor,
    Color textColor,
    int activeTabIndex,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(6.r),
        child: Row(
          children: [
            _buildTabItem(
              0,
              context.tr('vowl_mascot.tab_companion', fallback: 'Companion'),
              primaryColor,
              activeTabIndex,
            ),
            _buildTabItem(
              1,
              context.tr('vowl_mascot.tab_boutique', fallback: 'Boutique'),
              primaryColor,
              activeTabIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    int index,
    String label,
    Color primaryColor,
    int activeTabIndex,
  ) {
    final isSelected = activeTabIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () {
            _hapticService.selection();
            // A TabController used to mirror this index but never drove any
            // TabBarView/TabBar — it was dead weight. The local index alone
            // is the single source of truth for which sliver renders below.
            _activeTabIndex.value = index;
          },
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(minHeight: 48.h),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: AutoSizeText(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? primaryColor
                      : Colors.grey.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
                maxLines: 1,
                minFontSize: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSliver(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final mascots = VowlAssets.mascotMap.keys.toList();
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
          // Clamp local text scale: these are fixed-aspect-ratio grid cells
          // by design. Without this, a large OS accessibility text-scale
          // setting combined with a longer translated mascot name could
          // overflow the cell. The rest of the app still scales freely.
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
            child: RepaintBoundary(
              child: GridView.builder(
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

  Widget _buildBoutiqueSliver(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final accessories = VowlAssets.accessoryMap.keys.toList();
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
            ),
          ),
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
    bool isOwned,
    int price,
    bool isDark,
    Color primaryColor,
    Color textColor,
    UserEntity user,
  ) {
    final statusLabel = isSelected
        ? context.tr('vowl_mascot.equipped_status', fallback: 'Equipped')
        : isOwned
        ? context.tr('vowl_mascot.sync_ready', fallback: 'Sync Ready')
        : '$price 🪙';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${name.toUpperCase()}, $statusLabel',
      child: ScaleButton(
        onTap: isSelected
            ? null
            : () async {
                if (_isProcessing.value) return;
                _isProcessing.value = true;
                if (isOwned) {
                  _hapticService.light();
                  context.read<ProfileBloc>().add(
                    ProfileUpdateVowlMascotRequested(id),
                  );
                } else {
                  if (user.coins >= price) {
                    _hapticService.light();
                    context.read<ProfileBloc>().add(
                      ProfileBuyVowlMascotRequested(id, price),
                    );
                  } else {
                    _hapticService.error();
                    _showModernSnackbar(context, "Not enough coins!", false);
                  }
                }
                await Future.delayed(const Duration(milliseconds: 1000));
                if (mounted) _isProcessing.value = false;
              },
        child: ExcludeSemantics(
          child: GlassTile(
            borderRadius: BorderRadius.circular(24.r),
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
                      .animate(
                        onPlay: (c) => isSelected ? c.repeat() : c.stop(),
                      )
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: AutoSizeText(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? primaryColor : textColor,
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
                      size: 14,
                    ).animate().scale()
                  else if (isOwned)
                    AutoSizeText(
                      context.tr(
                        'vowl_mascot.sync_ready',
                        fallback: 'Sync Ready',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        color: textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 5,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money_rounded,
                          color: primaryColor,
                          size: 12.r,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '$price',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                            .shimmer(
                              color: primaryColor.withValues(alpha: 0.2),
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
  ) {
    final canAfford = user.coins >= price;
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
                          child: Text(emoji, style: TextStyle(fontSize: 48.sp)),
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
                color: isDark ? textColor.withValues(alpha: 0.9) : textColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            // The Semantics node here wraps the ONE real tappable widget
            // (the action button below), so screen readers announce a
            // button that actually does something when activated — unlike
            // wrapping the whole card, which would announce a "button"
            // with no attached action.
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
                        onTap: () async {
                          if (_isProcessing.value) return;
                          _isProcessing.value = true;
                          _hapticService.selection();
                          context.read<ProfileBloc>().add(
                            ProfileEquipVowlAccessoryRequested(
                              isEquipped ? null : id,
                            ),
                          );
                          await Future.delayed(
                            const Duration(milliseconds: 1000),
                          );
                          _isProcessing.value = false;
                        },
                        primaryColor: primaryColor,
                      )
                    : _buildActionButton(
                        label: '$price',
                        color: canAfford
                            ? primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        textColor: canAfford ? primaryColor : Colors.grey,
                        onTap: () async {
                          if (_isProcessing.value) return;
                          if (canAfford) {
                            _isProcessing.value = true;
                            _hapticService.selection();
                            context.read<ProfileBloc>().add(
                              ProfileBuyVowlAccessoryRequested(id, price),
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 1500),
                            );
                            _isProcessing.value = false;
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
        constraints: BoxConstraints(minHeight: 40.h),
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

  Widget _buildEliteStatusOverlay(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: RepaintBoundary(
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
