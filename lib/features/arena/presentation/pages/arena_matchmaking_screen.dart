import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/arena/presentation/widgets/duel_illustration.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

enum _MatchStage { searching, faceOff, countdown }

/// Production 1v1 Arena Matchmaking Screen featuring holographic radar scan,
/// Face-Off (VS) card clash, and 3..2..1 countdown transition.
class ArenaMatchmakingScreen extends StatefulWidget {
  final UserEntity user;

  const ArenaMatchmakingScreen({super.key, required this.user});

  static Route<void> route({required UserEntity user}) {
    return MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ArenaMatchmakingScreen(user: user),
    );
  }

  @override
  State<ArenaMatchmakingScreen> createState() => _ArenaMatchmakingScreenState();
}

class _ArenaMatchmakingScreenState extends State<ArenaMatchmakingScreen> {
  _MatchStage _stage = _MatchStage.searching;
  ArenaDuelSession? _session;
  bool _isCanceled = false;
  bool _hasRefunded = false;

  // Search Timer & ticker
  Timer? _searchTickerTimer;
  int _secondsElapsed = 0;
  int _messageIndex = 0;
  int _countdownNumber = 3;
  Timer? _countdownTimer;

  static const List<String> _duelLayers = [
    'assets/illustrations/duel_base.svg',
    'assets/illustrations/duel_cardA.svg',
    'assets/illustrations/duel_cardB.svg',
    'assets/illustrations/duel_trophy.svg',
    'assets/illustrations/duel_vs.svg',
    'assets/illustrations/duel_bubbleA.svg',
    'assets/illustrations/duel_bubbleB.svg',
    'assets/illustrations/duel_timer.svg',
  ];

  void _preWarmDuel() {
    for (final path in _duelLayers) {
      try {
        final loader = SvgAssetLoader(path);
        vg.loadPicture(loader, null, onError: (e, stack) {});
      } catch (_) {}
    }
  }

  static const List<String> _statusMessages = [
    'Finding an opponent...',
    'Matching skill levels...',
    'Checking for live players...',
    'Preparing duel...',
  ];

  @override
  void initState() {
    super.initState();
    _preWarmDuel();

    _startSearchTimer();
    _executeMatchmaking();
  }

  void _startSearchTimer() {
    _searchTickerTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        _messageIndex = (_messageIndex + 1) % _statusMessages.length;
      });
    });
  }

  Future<void> _executeMatchmaking() async {
    if (!await ArenaNetworkHelper.ensureOnline(context)) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.quickMatch(currentUser: widget.user);

      if (_isCanceled || !mounted) {
        // User canceled while matchmaking was resolving -> refund immediately
        await _refundIfCanceled();
        return;
      }

      _onRivalFound(session);
    } catch (e) {
      debugPrint('[ArenaMatchmakingScreen] Matchmaking error: $e');
      if (_isCanceled) {
        return;
      }
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Matchmaking failed. Please check your connection and try again!',
          type: CustomSnackBarType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refundIfCanceled() async {
    if (_hasRefunded) return;
    _hasRefunded = true;
    try {
      final repo = di.sl<ArenaRepository>();
      await repo.refundStake(userId: widget.user.id);
    } catch (e) {
      debugPrint('[ArenaMatchmakingScreen] Refund error: $e');
    }
    if (mounted) {
      context.read<AuthBloc>().add(const AuthReloadUser());
    }
  }

  void _onRivalFound(ArenaDuelSession session) {
    _searchTickerTimer?.cancel();

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

    setState(() {
      _session = session;
      _stage = _MatchStage.faceOff;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _startCountdown();
    });
  }

  void _startCountdown() {
    setState(() {
      _stage = _MatchStage.countdown;
      _countdownNumber = 3;
    });

    if (di.sl.isRegistered<SoundService>()) {
      try {
        di.sl<SoundService>().playArenaCountdown();
      } catch (_) {}
    }

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdownNumber > 1) {
        setState(() => _countdownNumber--);
      } else {
        t.cancel();
        _launchDuel();
      }
    });
  }

  void _launchDuel() {
    if (_session == null || !mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement(ArenaDuelScreen.route(session: _session!));
  }

  Future<void> _handleCancel() async {
    if (_stage != _MatchStage.searching) return;
    _isCanceled = true;
    _searchTickerTimer?.cancel();

    // 1. Instantly purge background queue ticket & abort background search
    try {
      final repo = di.sl<ArenaRepository>();
      await repo.cancelMatchmaking(userId: widget.user.id);
    } catch (e) {
      debugPrint('[ArenaMatchmakingScreen] cancelMatchmaking error: $e');
    }

    // 2. Guarantee 100% stake refund to user's balance
    await _refundIfCanceled();

    // 3. Close the screen immediately
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      } else {
        try {
          GoRouter.of(context).go(AppRouter.gamesRoute);
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _isCanceled = true;
    _searchTickerTimer?.cancel();
    _countdownTimer?.cancel();
    if (_stage == _MatchStage.searching && !_hasRefunded) {
      try {
        final repo = di.sl<ArenaRepository>();
        repo.cancelMatchmaking(userId: widget.user.id);
        repo.refundStake(userId: widget.user.id);
      } catch (_) {}
    }
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.midnightSurface : AppColors.slate50);
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightSurface : Colors.white);
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.indigo500.withValues(alpha: 0.16);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_stage == _MatchStage.searching) {
          _handleCancel();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: [
                // Header Row
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_stage == _MatchStage.searching)
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 22.sp,
                          color: textPrimary,
                        ),
                        onPressed: _handleCancel,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
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
                                Icon(
                                  LucideIcons.coins,
                                  size: 13.r,
                                  color: AppColors.amber500,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'Entry 30🪙 • Winner Takes 50🪙 + 5 XP',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amber500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const Spacer(),

                // Center Content: Switching between Radar Searching vs Face-Off VS
                if (_stage == _MatchStage.searching)
                  _buildSearchingHUD(
                    isDark,
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  )
                else
                  _buildFaceOffHUD(
                    isDark,
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),

                const Spacer(),

                // Bottom Cancel CTA during searching
                if (_stage == _MatchStage.searching) ...[
                  ScaleButton(
                    onTap: _handleCancel,
                    child: Container(
                      height: 44.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.slate700
                              : AppColors.slate300,
                        ),
                      ),
                      child: Text(
                        'Cancel Matchmaking',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ] else ...[
                  SizedBox(height: 60.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingHUD(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final meAvatar =
        widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
        ? CachedNetworkImageProvider(widget.user.photoUrl!)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1 vs 1 Duel Illustration (Searching state with pulsing ? and opponent ripples)
        RepaintBoundary(
          child: SizedBox(
            height: 220.h,
            child: AspectRatio(
              aspectRatio: 360 / 320,
              child: DuelIllustration(meAvatar: meAvatar, searching: true),
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Search Timer
        Text(
          _formattedTime,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isDark ? Colors.white : AppColors.indigo600,
          ),
        ),

        SizedBox(height: 8.h),

        // Rotating Status Ticker
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _statusMessages[_messageIndex],
            key: ValueKey(_messageIndex),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceOffHUD(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final rivalName = _session?.opponentName(widget.user.id) ?? 'Challenger';
    final rivalPhoto = _session?.opponentPhotoUrl(widget.user.id);
    final myName = _session?.myName(widget.user.id) ?? widget.user.safeDisplayName;
    final myPhoto = _session?.myPhotoUrl(widget.user.id) ?? widget.user.photoUrl;
    final isAiRival = _session?.isGhostRival ?? false;

    final meAvatar = myPhoto != null && myPhoto.isNotEmpty
        ? CachedNetworkImageProvider(myPhoto)
        : null;
    final opponentAvatar = rivalPhoto != null && rivalPhoto.isNotEmpty
        ? CachedNetworkImageProvider(rivalPhoto)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.indigo500.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'ARENA PENTATHLON • 5 ROUNDS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.indigo500,
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // 1 vs 1 Duel Illustration (Face-off settled mode with both avatars and VS badge)
        RepaintBoundary(
          child: SizedBox(
            height: 220.h,
            child: AspectRatio(
              aspectRatio: 360 / 320,
              child: DuelIllustration(
                meAvatar: meAvatar,
                opponentAvatar: opponentAvatar,
                isOpponentAi: isAiRival,
                searching: false,
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Player Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  myName,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 48.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  rivalName,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        // 5-Round Disciplines Strip with Icon Preview (⚡🎯💥🧠👑)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.indigo500.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _disciplineChip(
                      icon: LucideIcons.zap,
                      label: 'R1 Clash',
                      color: AppColors.indigo500,
                      isDark: isDark,
                    ),
                    SizedBox(width: 4.w),
                    _disciplineChip(
                      icon: LucideIcons.target,
                      label: 'R2 Phrase',
                      color: AppColors.emerald500,
                      isDark: isDark,
                    ),
                    SizedBox(width: 4.w),
                    _disciplineChip(
                      icon: LucideIcons.flame,
                      label: 'R3 Strike',
                      color: AppColors.rose500,
                      isDark: isDark,
                    ),
                    SizedBox(width: 4.w),
                    _disciplineChip(
                      icon: LucideIcons.brainCircuit,
                      label: 'R4 Blitz',
                      color: AppColors.blue500,
                      isDark: isDark,
                    ),
                    SizedBox(width: 4.w),
                    _disciplineChip(
                      icon: LucideIcons.crown,
                      label: 'R5 Climax',
                      color: AppColors.amber500,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '5 PROGRESSIVE ROUNDS • EASY → MEDIUM → HARD',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Countdown Overlay
        if (_stage == _MatchStage.countdown)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              'Starting in $_countdownNumber...',
              key: ValueKey(_countdownNumber),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.indigo600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _disciplineChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 3.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
