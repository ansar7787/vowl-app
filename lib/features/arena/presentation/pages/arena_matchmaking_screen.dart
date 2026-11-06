import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

enum _MatchStage { searching, faceOff, countdown }

/// Production 1v1 Arena Matchmaking Screen featuring holographic radar scan,
/// Face-Off (VS) card clash, and 3..2..1 countdown transition.
class ArenaMatchmakingScreen extends StatefulWidget {
  final UserEntity user;

  const ArenaMatchmakingScreen({super.key, required this.user});

  static Route<void> route({required UserEntity user}) {
    return MaterialPageRoute(
      builder: (_) => ArenaMatchmakingScreen(user: user),
    );
  }

  @override
  State<ArenaMatchmakingScreen> createState() => _ArenaMatchmakingScreenState();
}

class _ArenaMatchmakingScreenState extends State<ArenaMatchmakingScreen>
    with TickerProviderStateMixin {
  _MatchStage _stage = _MatchStage.searching;
  ArenaDuelSession? _session;
  bool _isCanceled = false;
  bool _hasRefunded = false;

  // Radar animation
  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;

  // VS Slam animation
  late final AnimationController _vsController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scaleVsAnimation;

  // Search Timer & ticker
  Timer? _searchTickerTimer;
  int _secondsElapsed = 0;
  int _messageIndex = 0;
  int _countdownNumber = 3;
  Timer? _countdownTimer;

  static const List<String> _statusMessages = [
    'Scanning active players in regional lobby...',
    'Matching skill ratings & discipline...',
    'Expanding search across global arena...',
    'Checking queue for live challenger...',
    'Finalizing player match...',
  ];

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeInOut,
    );

    _vsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnimation = CurvedAnimation(
      parent: _vsController,
      curve: Curves.easeOutBack,
    );

    _scaleVsAnimation = CurvedAnimation(
      parent: _vsController,
      curve: Curves.elasticOut,
    );

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
    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.quickMatch(
        currentUser: widget.user,
        leaderboardUsers: const [],
      );

      if (_isCanceled || !mounted) {
        // User canceled while matchmaking was resolving -> refund immediately
        await _refundIfCanceled();
        return;
      }

      _onRivalFound(session);
    } catch (e) {
      debugPrint('[ArenaMatchmakingScreen] Matchmaking error: $e');
      if (mounted && !_isCanceled) {
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

    _vsController.forward().then((_) {
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
    Navigator.of(context).pushReplacement(
      ArenaDuelScreen.route(session: _session!),
    );
  }

  Future<void> _handleCancel() async {
    if (_stage != _MatchStage.searching) return;
    _isCanceled = true;
    _searchTickerTimer?.cancel();
    await _refundIfCanceled();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _searchTickerTimer?.cancel();
    _countdownTimer?.cancel();
    _radarController.dispose();
    _vsController.dispose();
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
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC));
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.indigo500.withValues(alpha: 0.16);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    return PopScope(
      canPop: _stage == _MatchStage.searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _isCanceled = true;
          _searchTickerTimer?.cancel();
          _refundIfCanceled();
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
                        icon: Icon(LucideIcons.x, size: 22.sp, color: textPrimary),
                        onPressed: _handleCancel,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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
                                Icon(LucideIcons.coins, size: 13.r, color: AppColors.amber500),
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
                  _buildSearchingHUD(isDark, cardBg, borderColor, textPrimary, textSecondary)
                else
                  _buildFaceOffHUD(isDark, cardBg, borderColor, textPrimary, textSecondary),

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
                          color: isDark ? AppColors.slate700 : AppColors.slate300,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Radar Rings (Isolated with RepaintBoundary)
        RepaintBoundary(
          child: SizedBox(
            width: 140.r,
            height: 140.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarAnimation,
                  builder: (context, _) {
                    final scale = 0.8 + (_radarAnimation.value * 0.45);
                    final opacity = (1.0 - _radarAnimation.value).clamp(0.0, 1.0);
                    return Container(
                      width: 130.r * scale,
                      height: 130.r * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: opacity * 0.5),
                          width: 2.0,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardBg,
                    border: Border.all(color: AppColors.indigo500, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Center(
                    child: UserAvatar(photoUrl: widget.user.photoUrl, size: 68.r),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

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
    final rivalName = _session?.guestName ?? 'Challenger';
    final rivalPhoto = _session?.guestPhotoUrl;

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

        SizedBox(height: 24.h),

        // Face-Off Cards Slam (Isolated with RepaintBoundary)
        RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Card: You
              SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.2, 0),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Container(
                width: 120.w,
                constraints: BoxConstraints(minHeight: 130.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    UserAvatar(photoUrl: widget.user.photoUrl, size: 52.r),
                    SizedBox(height: 8.h),
                    Text(
                      widget.user.safeDisplayName,
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
                    const Spacer(),
                    Text(
                      'You',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: AppColors.indigo500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Center VS Badge
            ScaleTransition(
              scale: _scaleVsAnimation,
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.indigo600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Right Card: Rival
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.2, 0),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Container(
                width: 120.w,
                constraints: BoxConstraints(minHeight: 130.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    if (_session?.isGhostRival == true && (rivalPhoto == null || rivalPhoto.isEmpty))
                      Container(
                        width: 52.r,
                        height: 52.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.bot,
                            color: Colors.white,
                            size: 26.r,
                          ),
                        ),
                      )
                    else
                      UserAvatar(photoUrl: rivalPhoto, size: 52.r),
                    SizedBox(height: 8.h),
                    Text(
                      rivalName,
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
                    const Spacer(),
                    Text(
                      _session?.isGhostRival == true ? 'AI Opponent' : 'Live Player',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: _session?.isGhostRival == true
                            ? const Color(0xFF06B6D4)
                            : AppColors.emerald500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

        SizedBox(height: 18.h),

        // 5-Round Disciplines Strip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.indigo500.withValues(alpha: 0.25),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '5-ROUND DUEL: WORD CLASH • PHRASE DUEL • SENTENCE STRIKE • CONTEXT BLITZ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.indigo400 : AppColors.indigo600,
              ),
            ),
          ),
        ),

        SizedBox(height: 32.h),

        // Countdown Overlay
        if (_stage == _MatchStage.countdown)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '$_countdownNumber',
              key: ValueKey(_countdownNumber),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.indigo600,
              ),
            ),
          ),
      ],
    );
  }
}

