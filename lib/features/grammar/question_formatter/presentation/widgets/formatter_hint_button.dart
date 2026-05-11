import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FormatterHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const FormatterHintButton({
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

        return ScaleButton(
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
                          style: GoogleFonts.outfit(
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
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: canUseHint
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(27.r),
              border: Border.all(
                color: canUseHint ? primaryColor : Colors.grey,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                      used
                          ? Icons.psychology_alt_rounded
                          : Icons.psychology_rounded,
                      color: canUseHint ? primaryColor : Colors.grey,
                      size: 28.r,
                    )
                    .animate(onPlay: (c) => used ? c.stop() : c.repeat())
                    .shimmer(duration: 3.seconds),
                if (!used && hintCount > 0)
                  Positioned(
                    top: 2.r,
                    right: 2.r,
                    child: Container(
                      width: 20.r,
                      height: 20.r,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          hintCount.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
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
