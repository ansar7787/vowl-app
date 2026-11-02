import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final inviteCopy = widget.data.referralCode != null
        ? 'Join me on Vowl using code ${widget.data.referralCode} to claim 100 Bonus Coins & Free VIP!'
        : 'Leveling up my English skills on Vowl!';

    await SocialShareRasterizer.captureAndShare(
      boundaryKey: _boundaryKey,
      shareText: '🏆 ${widget.data.title} on Vowl!\n$inviteCopy\nhttps://vowl.app',
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
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(LucideIcons.share2, size: 18.sp),
                label: Text(
                  _isSharing ? 'Generating Image...' : 'Share Card to Stories / WhatsApp',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
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

