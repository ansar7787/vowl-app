import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class KidsMagicChest extends StatefulWidget {
  final VoidCallback onClaimed;
  final Function(BuildContext, String, {bool isError}) showNotification;

  const KidsMagicChest({
    super.key,
    required this.onClaimed,
    required this.showNotification,
  });

  @override
  State<KidsMagicChest> createState() => _KidsMagicChestState();
}

class _KidsMagicChestState extends State<KidsMagicChest> {
  final math.Random _random = math.Random();
  Timer? _timer;
  String _timeRemaining = "00:00:00";
  bool _isClaiming = false;
  DateTime? _lastClaimedLocally;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final state = context.read<AuthBloc>().state;
    final user = state.user;
    if (user != null) {
      final serverLastClaim = user.lastKidsDailyRewardDate;
      final lastClaim = (_lastClaimedLocally != null &&
              (serverLastClaim == null ||
                  _lastClaimedLocally!.isAfter(serverLastClaim)))
          ? _lastClaimedLocally
          : serverLastClaim;

      if (lastClaim != null) {
        final now = DateTime.now();
        final nextClaim = lastClaim.add(const Duration(hours: 24));
        if (now.isBefore(nextClaim)) {
          final diff = nextClaim.difference(now);
          setState(() {
            _timeRemaining =
                "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
          });
        } else {
          setState(() {
            _timeRemaining = "00:00:00";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();

        final serverLastClaim = user.lastKidsDailyRewardDate;
        final lastClaim = (_lastClaimedLocally != null &&
                (serverLastClaim == null ||
                    _lastClaimedLocally!.isAfter(serverLastClaim)))
            ? _lastClaimedLocally
            : serverLastClaim;

        final now = DateTime.now();
        final canClaim =
            !_isClaiming &&
            (lastClaim == null ||
                now.isAfter(lastClaim.add(const Duration(hours: 24))));

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ScaleButton(
          onTap: canClaim
              ? () async {
                  final claimTime = DateTime.now();
                  setState(() {
                    _isClaiming = true;
                    _lastClaimedLocally = claimTime;
                  });
                  
                  widget.onClaimed(); // Trigger confetti/animations in parent
                  
                  // 1 to 30 coin shuffle
                  final amount = 1 + _random.nextInt(30);

                  if (context.mounted) {
                    context.read<EconomyBloc>().add(EconomyClaimKidsDailyRewardRequested(amount));
                    widget.showNotification(
                      context,
                      "🎁 HOORAY! YOU FOUND $amount 🚗!",
                    );
                    di.sl<SoundService>().playCorrect();
                  }

                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _isClaiming = false);
                }
              : null,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canClaim
                    ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                    : [
                        (isDark ? Colors.grey.shade900 : Colors.indigo.shade50).withValues(alpha: isDark ? 0.4 : 0.8),
                        (isDark ? Colors.black : Colors.indigo.shade100).withValues(alpha: isDark ? 0.3 : 0.4),
                      ],
              ),
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: canClaim
                  ? [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
              border: Border.all(
                color: canClaim
                    ? Colors.white.withValues(alpha: 0.5)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (canClaim)
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Icon(
                      canClaim ? Icons.card_giftcard_rounded : Icons.lock_clock_rounded,
                      color: canClaim ? Colors.white : (isDark ? Colors.white24 : Colors.black26),
                      size: 32.sp,
                    ),
                  ],
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canClaim ? "MAGIC CHEST" : "CHEST CLAIMED",
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: canClaim ? Colors.white : (isDark ? Colors.white38 : Colors.indigo.shade900.withValues(alpha: 0.6)),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        canClaim
                            ? "Open for daily Kids Coins!"
                            : "Next claim in $_timeRemaining",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: canClaim ? Colors.white70 : (isDark ? Colors.white24 : Colors.indigo.shade800.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canClaim)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "CLAIM",
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
        );
      },
    );
  }
}
