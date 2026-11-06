import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';

/// Production 1v1 Arena private room waiting lobby.
///
/// Features:
/// - Real-time Firestore room snapshot subscription.
/// - Head-to-Head Split HUD (Host Ready vs Challenger Waiting).
/// - Prominent Room Code display with 1-tap Copy & 1-tap Share Challenge Card.
/// - Instant safe cancellation with guaranteed 30-coin stake refund.
/// - Seamless automatic route transition to [ArenaDuelScreen] upon guest arrival.
class ArenaLobbyWaitingScreen extends StatefulWidget {
  final ArenaDuelSession session;

  const ArenaLobbyWaitingScreen({super.key, required this.session});

  static Route<void> route({required ArenaDuelSession session}) {
    return MaterialPageRoute(
      builder: (_) => ArenaLobbyWaitingScreen(session: session),
    );
  }

  @override
  State<ArenaLobbyWaitingScreen> createState() => _ArenaLobbyWaitingScreenState();
}

class _ArenaLobbyWaitingScreenState extends State<ArenaLobbyWaitingScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ArenaDuelSession>? _roomSub;
  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeInOut,
    );

    _listenToRoom();
  }

  void _listenToRoom() {
    final repo = di.sl<ArenaRepository>();
    _roomSub = repo.listenToRoom(widget.session.roomCode).listen((updated) {
      if (updated.guestId != null && updated.status == 'in_progress') {
        _onChallengerJoined(updated);
      }
    });
  }

  void _onChallengerJoined(ArenaDuelSession activeSession) {
    if (!mounted) return;

    if (di.sl.isRegistered<SoundService>()) {
      try {
        di.sl<SoundService>().playArenaMatchFound();
      } catch (_) {}
    }
    if (di.sl.isRegistered<HapticService>()) {
      try {
        di.sl<HapticService>().heavy();
      } catch (_) {}
    }

    CustomSnackBar.show(
      context: context,
      message: '⚔️ ${activeSession.guestName ?? "Challenger"} joined! Duel starting...',
      type: CustomSnackBarType.success,
      duration: const Duration(seconds: 2),
    );

    Navigator.of(context).pushReplacement(
      ArenaDuelScreen.route(session: activeSession),
    );
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelRoom() async {
    if (_isCanceling) return;

    final shouldForfeit = await ArenaQuitMatchDialog.show(
      context: context,
      isWaitingLobby: true,
      onForfeit: () {},
    );

    if (shouldForfeit == true && mounted) {
      setState(() => _isCanceling = true);
      try {
        final authState = context.read<AuthBloc>().state;
        final user = authState.user;
        if (user != null) {
          final repo = di.sl<ArenaRepository>();
          await repo.forfeitMatch(
            roomCode: widget.session.roomCode,
            userId: user.id,
          );
        }
        if (mounted) {
          context.read<AuthBloc>().add(const AuthReloadUser());
          CustomSnackBar.show(
            context: context,
            message: 'Room dissolved. 30 coins have been refunded.',
            type: CustomSnackBarType.info,
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('[ArenaLobbyWaitingScreen] Cancel room error: $e');
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : const Color(0xFFF8FAFC));
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.indigo500.withValues(alpha: 0.16);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleCancelRoom();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isMidnight
              ? Colors.black
              : (isDark ? AppColors.slate900 : Colors.white),
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.x, size: 20.sp, color: textPrimary),
            onPressed: _handleCancelRoom,
          ),
          centerTitle: true,
          title: Text(
            '1v1 Private Duel Lobby',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: [
                SizedBox(height: 12.h),

                // Top Badge: Entry Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.35),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.coins, color: AppColors.amber500, size: 14.r),
                        SizedBox(width: 6.w),
                        Text(
                          'Entry 30🪙 each • Winner takes 50🪙 + 5 XP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Center Split HUD: Host Card vs Challenger Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: isDark ? 0.08 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Host Card (You)
                      Expanded(
                        child: Column(
                          children: [
                            UserAvatar(photoUrl: user?.photoUrl, size: 54.r),
                            SizedBox(height: 8.h),
                            Text(
                              user?.safeDisplayName ?? 'Host',
                              maxLines: 2,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'READY',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VS Emblem
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Challenger Slot (Waiting)
                      Expanded(
                        child: Column(
                          children: [
                            RepaintBoundary(
                              child: SizedBox(
                                width: 54.r,
                                height: 54.r,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _radarAnimation,
                                      builder: (context, _) {
                                        final scale = 0.85 + (_radarAnimation.value * 0.35);
                                        final opacity = (1.0 - _radarAnimation.value).clamp(0.0, 1.0);
                                        return Container(
                                          width: 54.r * scale,
                                          height: 54.r * scale,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.indigo500.withValues(alpha: opacity * 0.45),
                                              width: 1.5,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      width: 44.r,
                                      height: 44.r,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        border: Border.all(
                                          color: AppColors.indigo500.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.userPlus,
                                        size: 20.r,
                                        color: isDark ? AppColors.indigo400 : AppColors.indigo500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Challenger',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amber500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'WAITING...',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.amber500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Big Room Code Container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'DUEL ROOM CODE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.session.roomCode.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: isDark ? Colors.white : AppColors.indigo600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Share this code or image card with your challenger to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // 2 Action Buttons: Copy Code & Share Card
                      Row(
                        children: [
                          // 1. Copy Code Button
                          Expanded(
                            child: ScaleButton(
                              onTap: () {
                                try {
                                  Clipboard.setData(ClipboardData(
                                    text: widget.session.roomCode.toUpperCase(),
                                  ));
                                  CustomSnackBar.show(
                                    context: context,
                                    message: 'Room code copied to clipboard!',
                                    type: CustomSnackBarType.success,
                                    duration: const Duration(seconds: 2),
                                  );
                                } catch (_) {}
                              },
                              child: Container(
                                height: 42.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.indigo950.withValues(alpha: 0.4)
                                      : AppColors.indigo50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.indigo500.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.copy,
                                      size: 14.r,
                                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Copy Code',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.indigo600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // 2. Share Challenge Card Button
                          Expanded(
                            child: ScaleButton(
                              onTap: () {
                                if (user == null) return;
                                ShareCardPreviewModal.show(
                                  context: context,
                                  data: ShareCardData.fromDuelInvite(
                                    userName: user.safeDisplayName,
                                    userPhotoUrl: user.photoUrl,
                                    roomCode: widget.session.roomCode,
                                  ),
                                );
                              },
                              child: Container(
                                height: 42.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.indigo500, AppColors.indigo600],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.indigo500.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.share2,
                                      size: 14.r,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Share Card',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom: Cancel Room CTA
                ScaleButton(
                  onTap: _isCanceling ? null : _handleCancelRoom,
                  child: Container(
                    height: 44.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.rose500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: _isCanceling
                        ? const VowlMicroLoader(
                            color: AppColors.rose500,
                            size: 16,
                          )
                        : Text(
                            'Dissolve Room & Refund (30🪙)',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rose500,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

