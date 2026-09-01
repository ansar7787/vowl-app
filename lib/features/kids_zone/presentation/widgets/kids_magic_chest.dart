import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
  Timer? _timer;
  final ValueNotifier<String> _timeRemaining = ValueNotifier("00:00:00");
  final ValueNotifier<bool> _isClaiming = ValueNotifier(false);
  final ValueNotifier<DateTime?> _lastClaimedLocally = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Update immediately so the countdown shows on first render
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCountdown());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeRemaining.dispose();
    _isClaiming.dispose();
    _lastClaimedLocally.dispose();
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
      final lastClaim =
          (_lastClaimedLocally.value != null &&
              (serverLastClaim == null ||
                  _lastClaimedLocally.value!.isAfter(serverLastClaim)))
          ? _lastClaimedLocally.value
          : serverLastClaim;

      if (lastClaim != null) {
        final now = DateTime.now();
        final nextClaim = lastClaim.add(const Duration(hours: 24));
        if (now.isBefore(nextClaim)) {
          final diff = nextClaim.difference(now);
          _timeRemaining.value =
              "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
        } else {
          _timeRemaining.value = "00:00:00";
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

        return ListenableBuilder(
          listenable: Listenable.merge([_timeRemaining, _isClaiming, _lastClaimedLocally]),
          builder: (context, _) {
            final serverLastClaim = user.lastKidsDailyRewardDate;
            final lastClaim =
                (_lastClaimedLocally.value != null &&
                    (serverLastClaim == null ||
                        _lastClaimedLocally.value!.isAfter(serverLastClaim)))
                ? _lastClaimedLocally.value
                : serverLastClaim;

            final now = DateTime.now();
            final canClaim =
                !_isClaiming.value &&
                (lastClaim == null ||
                    now.isAfter(lastClaim.add(const Duration(hours: 24))));

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ScaleButton(
          onTap: canClaim
              ? () async {
                  final claimTime = DateTime.now();
                  _isClaiming.value = true;
                  _lastClaimedLocally.value = claimTime;

                  widget.onClaimed(); // Trigger confetti/animations in parent

                  // Fixed daily reward — no gambling mechanics for children
                  const amount = 15;

                  if (context.mounted) {
                    context.read<EconomyBloc>().add(
                      const EconomyClaimKidsDailyRewardRequested(amount),
                    );
                    widget.showNotification(
                      context,
                      "🎁 Hooray! You earned $amount coins! 🪙",
                    );
                    di.sl<SoundService>().playCorrect();
                  }

                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) _isClaiming.value = false;
                }
              : null,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canClaim
                    ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                    : [
                        (isDark ? Colors.grey.shade900 : Colors.indigo.shade50)
                            .withValues(alpha: isDark ? 0.4 : 0.8),
                        (isDark ? Colors.black : Colors.indigo.shade100)
                            .withValues(alpha: isDark ? 0.3 : 0.4),
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
                    : (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
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
                      canClaim
                          ? Icons.card_giftcard_rounded
                          : Icons.lock_clock_rounded,
                      color: canClaim
                          ? Colors.white
                          : (isDark ? Colors.white24 : Colors.black26),
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
                        canClaim
                            ? context.tr('kids_zone.magic_chest', fallback: 'Magic Chest')
                            : context.tr('kids_zone.chest_claimed', fallback: 'Chest Claimed'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: canClaim
                              ? Colors.white
                              : (isDark
                                    ? Colors.white38
                                    : Colors.indigo.shade900.withValues(
                                        alpha: 0.6,
                                      )),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        canClaim
                            ? context.tr('kids_zone.open_for_daily_coins', fallback: 'Open for 15 daily Kids Coins!')
                            : context.tr('kids_zone.next_claim_in', fallback: 'Come back in ${_timeRemaining.value}', args: [_timeRemaining.value]),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: canClaim
                              ? Colors.white70
                              : (isDark
                                    ? Colors.white24
                                    : Colors.indigo.shade800.withValues(
                                        alpha: 0.5,
                                      )),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canClaim)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "CLAIM",
                      style: TextStyle(
                        fontFamily: 'Outfit',
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
      },
    );
  }
}
