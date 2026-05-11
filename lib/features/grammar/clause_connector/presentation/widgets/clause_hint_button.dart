import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class ClauseHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const ClauseHintButton({
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
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: canUseHint
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              border: Border.all(
                color: canUseHint ? primaryColor : Colors.grey,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  used ? Icons.link_off_rounded : Icons.link_rounded,
                  color: canUseHint ? primaryColor : Colors.grey,
                  size: 22.r,
                ),
                if (!used && hintCount > 0) ...[
                  SizedBox(width: 8.w),
                  Text(
                    hintCount.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
