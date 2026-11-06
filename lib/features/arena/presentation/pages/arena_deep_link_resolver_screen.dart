import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Transparent deep link landing screen for resolving and entering 1v1 duel invites.
class ArenaDeepLinkResolverScreen extends StatefulWidget {
  final String roomCode;

  const ArenaDeepLinkResolverScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<ArenaDeepLinkResolverScreen> createState() => _ArenaDeepLinkResolverScreenState();
}

class _ArenaDeepLinkResolverScreenState extends State<ArenaDeepLinkResolverScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCoinRefuelNeeded = false;
  bool _isAuthNeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAndJoin();
    });
  }

  Future<void> _resolveAndJoin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCoinRefuelNeeded = false;
      _isAuthNeeded = false;
    });

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (authState.status != AuthStatus.authenticated || user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthNeeded = true;
          _errorMessage = 'Please sign in or create an account to accept this 1v1 duel.';
        });
      }
      return;
    }

    if (di.sl.isRegistered<NetworkInfo>()) {
      final isOnline = await di.sl<NetworkInfo>().hasRealConnection;
      if (!isOnline) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'An active internet connection is required to join an Arena Duel. Please check your connection and try again.';
          });
        }
        return;
      }
    }

    if (user.coins < 30) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCoinRefuelNeeded = true;
          _errorMessage = 'You need 30 coins to enter this duel. Your current balance is ${user.coins} coins.';
        });
      }
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.joinRoom(
        roomCode: widget.roomCode.trim().toUpperCase(),
        currentUser: user,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          ArenaDuelScreen.route(session: session),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _watchAdForRefuel() {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    if (user == null) return;

    final adService = di.sl<AdService>();
    adService.showRewardedAd(
      context: context,
      isPremium: user.isPremium,
      onDismissed: () {},
      onUserEarnedReward: (_) async {
        try {
          if (di.sl.isRegistered<UpdateUserCoins>()) {
            await di.sl<UpdateUserCoins>()(
              const UpdateUserCoinsParams(
                amountChange: 30,
                title: 'Arena Duel Refuel',
              ),
            );
          }
          if (mounted) {
            context.read<AuthBloc>().add(const AuthRefreshUser());
            CustomSnackBar.show(
              context: context,
              message: '🎉 +30 Coins added! Entering the duel...',
              type: CustomSnackBarType.success,
            );
            _resolveAndJoin();
          }
        } catch (e) {
          debugPrint('[ArenaDeepLinkResolverScreen] Refuel reward error: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final bgColor = isMidnight ? Colors.black : (isDark ? AppColors.slate900 : const Color(0xFFF8FAFC));
    final cardBg = isMidnight ? AppColors.midnightSurface : (isDark ? const Color(0xFF131A29) : Colors.white);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.indigo500.withValues(alpha: 0.16);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: ArenaMatchingLoader(
            roomCode: widget.roomCode.toUpperCase(),
            customMessage: 'Connecting to 1v1 duel room...',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacious),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.cardSpacious),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: borderColor, width: 1.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: isDark ? 0.10 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68.r,
                    height: 68.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _errorMessage != null && !_isCoinRefuelNeeded
                            ? [AppColors.rose500, AppColors.rose700]
                            : [AppColors.indigo500, AppColors.indigo600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_errorMessage != null && !_isCoinRefuelNeeded
                                  ? AppColors.rose500
                                  : AppColors.indigo500)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCoinRefuelNeeded
                            ? LucideIcons.coins
                            : (_errorMessage != null ? LucideIcons.alertCircle : LucideIcons.swords),
                        size: 30.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    _isCoinRefuelNeeded
                        ? 'Coins Needed'
                        : (_errorMessage != null ? 'Duel Unavailable' : 'Duel Ready!'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF070A12) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'ROOM CODE: ${widget.roomCode.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : AppColors.indigo600,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Primary Action Button (Refuel, Auth, or Retry)
                    if (_isCoinRefuelNeeded) ...[
                      ElevatedButton.icon(
                        onPressed: _watchAdForRefuel,
                        icon: const Icon(LucideIcons.video, size: 16, color: Colors.white),
                        label: const Text('Watch Video (+30🪙 Refuel)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber500,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 44.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ] else if (_isAuthNeeded) ...[
                      ElevatedButton(
                        onPressed: () => context.go(AppRouter.loginRoute),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo500,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 44.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Sign In to Join Duel'),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRouter.homeRoute),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('Go Home'),
                          ),
                        ),
                        if (!_isCoinRefuelNeeded && !_isAuthNeeded) ...[
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resolveAndJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indigo500,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
