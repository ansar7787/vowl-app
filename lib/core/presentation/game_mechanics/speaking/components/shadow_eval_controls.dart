import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_eval_button.dart';

class ShadowEvalControls extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onNeedsWork;
  final VoidCallback onNailedIt;

  const ShadowEvalControls({
    super.key,
    required this.isSubmitting,
    required this.onNeedsWork,
    required this.onNailedIt,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: GameEvalButton(
            title: context.tr('eval.needs_work', fallback: 'Needs Work'),
            icon: Icons.close_rounded,
            color: tokens.gameIncorrect,
            onTap: isSubmitting ? () {} : onNeedsWork,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: GameEvalButton(
            title: context.tr('eval.nailed_it', fallback: 'Nailed It'),
            icon: Icons.check_rounded,
            color: tokens.gameCorrect,
            onTap: isSubmitting ? () {} : onNailedIt,
          ),
        ),
      ],
    );
  }
}
