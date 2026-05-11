import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class ArticleHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const ArticleHintButton({
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: canUseHint
                  ? primaryColor.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: canUseHint ? primaryColor : Colors.grey,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  used ? Icons.edit_off_rounded : Icons.edit_note_rounded,
                  color: canUseHint ? primaryColor : Colors.grey,
                  size: 20.r,
                ),
                if (!used && hintCount > 0) ...[
                  SizedBox(width: 6.w),
                  Text(
                    "HINT ($hintCount)",
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.5,
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
