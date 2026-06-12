import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Feature-specific hint button for the Parts-of-Speech screen.
///
/// ⚠️  ARCHITECTURE NOTE — dual economy path:
/// This widget directly dispatches [EconomyConsumeHintRequested] to deduct a
/// hint from the user's balance. If the calling screen ALSO dispatches
/// [GrammarHintUsed] (which calls the [UseHint] use-case), the hint will be
/// deducted twice.
///
/// Resolution: either use this widget OR [QuestHintButton] from
/// `core/presentation/widgets/` (which goes through [GrammarBloc]), not both.
/// The current [PartsOfSpeechScreen] uses [GrammarGameHeader] → [QuestHintButton],
/// so this widget is currently inactive for that screen.
class SpeechHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const SpeechHintButton({
    super.key,
    required this.used,
    required this.primaryColor,
    this.hintText,
    required this.onTap,
    required this.soundService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final hintCount = authState.user?.hintCount ?? 0;
        final canUseHint = !used && hintCount > 0;

        return Semantics(
          label: used
              ? 'Hint already used'
              : (canUseHint
                    ? 'Use hint ($hintCount remaining)'
                    : 'No hints remaining'),
          button: true,
          child: ScaleButton(
            onTap: canUseHint
                ? () {
                    context.read<EconomyBloc>().add(
                      const EconomyConsumeHintRequested(),
                    );
                    soundService.playHint();
                    onTap();
                    if (hintText != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            hintText!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
            child: Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                gradient: canUseHint
                    ? LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canUseHint ? null : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  if (canUseHint)
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                        used
                            ? Icons.gps_not_fixed_rounded
                            : Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: 24.r,
                      )
                      .animate(onPlay: (c) => used ? c.stop() : c.repeat())
                      .rotate(duration: 3.seconds),
                  if (!used && hintCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$hintCount',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
