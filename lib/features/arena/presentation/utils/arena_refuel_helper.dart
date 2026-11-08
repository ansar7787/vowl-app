import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/presentation/widgets/arena_refuel_dialog.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Reusable utility for handling Arena coin refuels across the app.
///
/// Encapsulates VIP immediate grant vs ad-rewarded coin refills,
/// with consistent messaging, analytics, and AuthBloc synchronization.
class ArenaRefuelHelper {
  ArenaRefuelHelper._();

  /// Displays the refuel dialog and wires the ad/VIP claim flow.
  static void showRefuelDialog({
    required BuildContext context,
    required UserEntity user,
    VoidCallback? onRefuelSuccess,
  }) {
    final liveUser = context.read<AuthBloc>().state.user ?? user;
    ArenaRefuelDialog.show(
      context: context,
      currentCoins: liveUser.coins,
      requiredCoins: 30,
      isPremium: liveUser.isPremium,
      onWatchAd: () => refuelCoins(
        context: context,
        user: liveUser,
        onSuccess: onRefuelSuccess,
      ),
    );
  }

  /// Executes coin addition (+30) via VIP bypass or rewarded video ad.
  static Future<void> refuelCoins({
    required BuildContext context,
    required UserEntity user,
    VoidCallback? onSuccess,
  }) async {
    if (user.isPremium) {
      try {
        if (di.sl.isRegistered<UpdateUserCoins>()) {
          await di.sl<UpdateUserCoins>()(
            const UpdateUserCoinsParams(
              amountChange: 30,
              title: 'VIP Arena Refuel',
            ),
          );
        }
        if (context.mounted) {
          context.read<AuthBloc>().add(AuthRefreshUser());
          CustomSnackBar.show(
            context: context,
            message: '👑 +30 VIP Coins added! Ready to enter duel.',
            type: CustomSnackBarType.success,
          );
          onSuccess?.call();
        }
      } catch (e) {
        debugPrint('[ArenaRefuelHelper] VIP refuel error: $e');
      }
      return;
    }

    if (!di.sl.isRegistered<AdService>()) return;
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
                title: 'Arena Refuel',
              ),
            );
          }
          if (context.mounted) {
            context.read<AuthBloc>().add(AuthRefreshUser());
            CustomSnackBar.show(
              context: context,
              message: '+30 Coins added! Ready to enter duel.',
              type: CustomSnackBarType.success,
            );
            onSuccess?.call();
          }
        } catch (e) {
          debugPrint('[ArenaRefuelHelper] Refuel reward error: $e');
        }
      },
    );
  }
}
