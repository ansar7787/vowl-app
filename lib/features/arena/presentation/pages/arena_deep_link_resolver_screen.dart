import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAndJoin();
    });
  }

  Future<void> _resolveAndJoin() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (authState.status != AuthStatus.authenticated || user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in or create an account to accept this Arena duel.';
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
            _errorMessage = 'An active internet connection is required to join an Arena Duel. Please check your network connection and try again.';
          });
        }
        return;
      }
    }

    if (user.coins < 30) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You need at least 30 coins to enter this duel stake. Your current balance is ${user.coins} coins.';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final bgColor = isMidnight ? Colors.black : (isDark ? AppColors.slate900 : const Color(0xFFF8FAFC));
    final cardBg = isMidnight ? AppColors.midnightSurface : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: ArenaMatchingLoader(
            roomCode: widget.roomCode.toUpperCase(),
            customMessage: 'Entering Arena Duel chamber...',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                  width: 1.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
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
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF59E0B),
                          Color(0xFFD97706),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _errorMessage != null ? LucideIcons.alertCircle : LucideIcons.swords,
                        size: 32.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    _errorMessage != null ? 'Duel Unavailable' : 'Duel Ready!',
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
                    ),
                    child: Text(
                      'ROOM CODE: ${widget.roomCode.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF6366F1),
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
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _resolveAndJoin();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber500,
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

