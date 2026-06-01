import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

/// Helper utility coordinating hint consumption check flows in Vowl.
///
/// Encapsulates double-tap race guarding, decoupled context lookups,
/// and optional overrides for clean unit/widget testing.
class HintHelper {
  HintHelper._(); // Non-instantiable utility pattern

  static bool _isProcessing = false;

  /// Safely initiates hint usage. Checks user counts and dispatches consumption.
  ///
  /// Employs a 500ms debouncing window to block rapid tap exploits.
  static void useHint({
    required BuildContext context,
    required VoidCallback onHintAction,
    AuthBloc? authBloc,
    EconomyBloc? economyBloc,
  }) {
    if (_isProcessing) return;

    final activeAuth = authBloc ?? context.read<AuthBloc>();
    final user = activeAuth.state.user;

    if (user == null || user.hintCount <= 0) {
      showLowHintsDialog(context);
      return;
    }

    _isProcessing = true;

    final activeEconomy = economyBloc ?? context.read<EconomyBloc>();
    activeEconomy.add(const EconomyConsumeHintRequested());

    onHintAction();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isProcessing = false;
    });
  }

  /// Displays the low hints dialogue, guiding users to the Treasury shop.
  static void showLowHintsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => ModernGameDialog(
        title: 'Light is Dim...',
        description:
            'You are out of hints! Visit the Treasury to get a Hint Pack.',
        buttonText: 'GET HINTS',
        isSuccess: false,
        onButtonPressed: () {
          Navigator.pop(c);
          if (context.mounted) {
            context.push(AppRouter.questCoinsRoute);
          }
        },
        secondaryButtonText: 'CANCEL',
        onSecondaryPressed: () => Navigator.pop(c),
      ),
    );
  }
}
