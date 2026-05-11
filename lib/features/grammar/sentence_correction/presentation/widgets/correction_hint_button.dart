import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CorrectionHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const CorrectionHintButton({
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
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: canUseHint
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: canUseHint ? Colors.amber : Colors.grey,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                      used ? Icons.manage_search_rounded : Icons.search_rounded,
                      color: canUseHint ? Colors.amber : Colors.grey,
                      size: 28.r,
                    )
                    .animate(onPlay: (c) => used ? c.stop() : c.repeat())
                    .scale(
                      duration: 1.5.seconds,
                      begin: const Offset(0.9, 0.9),
                    ),
                if (!used && hintCount > 0)
                  Positioned(
                    bottom: 4.r,
                    right: 4.r,
                    child: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        hintCount.toString(),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
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
