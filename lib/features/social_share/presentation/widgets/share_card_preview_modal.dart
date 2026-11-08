import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/milestone_share_card_widget.dart';
import 'package:vowl/features/social_share/services/social_share_rasterizer.dart';

class ShareCardPreviewModal extends StatefulWidget {
  final ShareCardData data;

  const ShareCardPreviewModal({super.key, required this.data});

  static Future<void> show({
    required BuildContext context,
    required ShareCardData data,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => ShareCardPreviewModal(data: data),
    );
  }

  @override
  State<ShareCardPreviewModal> createState() => _ShareCardPreviewModalState();
}

class _ShareCardPreviewModalState extends State<ShareCardPreviewModal> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);

    final String shareText;
    if (widget.data.type == ShareCardType.arenaVictory) {
      final code = widget.data.roomCode ?? 'VOWL';
      shareText =
          '⚔️ I just won a 1v1 English Duel on Vowl with ${widget.data.myScore ?? 0} points!\n'
          'Can you beat my score? Enter room code: $code in the app, or tap:\n'
          'https://vowl-acbc5.web.app/duel/$code';
    } else if (widget.data.type == ShareCardType.arenaInvite) {
      final code = widget.data.roomCode ?? 'VOWL';
      shareText =
          '⚔️ You\'ve been challenged to a 1v1 English Duel on Vowl!\n'
          'Room Code: $code\n'
          'Winner takes 50 Coins + 5 XP!\n\n'
          'Tap to join the duel:\n'
          'https://vowl-acbc5.web.app/duel/$code';
    } else if (widget.data.type == ShareCardType.referral) {
      final code = widget.data.referralCode ?? '';
      shareText =
          '🚀 Join me on Vowl to level up your English skills!\n'
          'Use my invite code $code to unlock 100 Bonus Coins + Free VIP access immediately:\n'
          'https://vowl-acbc5.web.app/invite/$code';
    } else {
      final inviteCopy = widget.data.referralCode != null
          ? 'Join me on Vowl using code ${widget.data.referralCode} to claim 100 Bonus Coins & Free VIP!'
          : 'Leveling up my English skills on Vowl!';
      shareText =
          '🏆 ${widget.data.title} on Vowl!\n$inviteCopy\nhttps://vowl-acbc5.web.app';
    }

    await SocialShareRasterizer.captureAndShare(
      boundaryKey: _boundaryKey,
      shareText: shareText,
      subject: widget.data.title,
    );
    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button at top right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(LucideIcons.x, color: Colors.white, size: 24.sp),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(height: 8.h),

            // The card wrapped in RepaintBoundary for capture
            RepaintBoundary(
              key: _boundaryKey,
              child: MilestoneShareCardWidget(data: widget.data),
            ),

            SizedBox(height: 20.h),

            // Action Button
            SizedBox(
              width: 340.w,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _handleShare,
                icon: _isSharing
                    ? const VowlMicroLoader(size: 16, color: Colors.white)
                    : Icon(LucideIcons.share2, size: 18.sp),
                label: Text(
                  _isSharing
                      ? 'Generating Image...'
                      : 'Share Card to Stories / WhatsApp',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
