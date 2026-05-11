import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class HintHelper {
  static void useHint({
    required BuildContext context,
    required VoidCallback onHintAction,
  }) {
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state.user;

    if (user == null || user.hintCount <= 0) {
      showLowHintsDialog(context);
      return;
    }

    di.sl<EconomyBloc>().add(const EconomyConsumeHintRequested());
    onHintAction();
  }

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
          context.push(AppRouter.questCoinsRoute);
        },
        secondaryButtonText: 'CANCEL',
        onSecondaryPressed: () => Navigator.pop(c),
      ),
    );
  }
}
