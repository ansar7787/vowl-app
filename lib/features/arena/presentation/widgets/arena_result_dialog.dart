import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class ArenaResultDialog extends StatelessWidget {
  final bool isWinner;
  final bool isDraw;
  final bool isSpeedTieBreak;
  final double speedDiffSeconds;
  final int myScore;
  final int rivalScore;
  final int myCorrectCount;
  final int rivalCorrectCount;
  final int myTotalTimeMs;
  final int rivalTotalTimeMs;
  final String rivalName;
  final String? rivalPhotoUrl;
  final String myName;
  final String? myPhotoUrl;
  final int payoutCoins;
  final String roomCode;
  final VoidCallback onRematch;
  final VoidCallback onClose;

  const ArenaResultDialog({
    super.key,
    required this.isWinner,
    this.isDraw = false,
    this.isSpeedTieBreak = false,
    this.speedDiffSeconds = 0.0,
    required this.myScore,
    required this.rivalScore,
    this.myCorrectCount = 0,
    this.rivalCorrectCount = 0,
    this.myTotalTimeMs = 0,
    this.rivalTotalTimeMs = 0,
    required this.rivalName,
    this.rivalPhotoUrl,
    this.myName = 'You',
    this.myPhotoUrl,
    required this.payoutCoins,
    this.roomCode = '',
    required this.onRematch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white);
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));
    final cardBg = isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC);

    final statusColor = isSpeedTieBreak
        ? const Color(0xFFF59E0B)
        : (isWinner ? AppColors.emerald500 : AppColors.rose500);

    final statusTitle = isSpeedTieBreak
        ? (isWinner ? '⚡ SPEED VICTORY!' : '⚡ SPLIT-SECOND LOSS')
        : (isWinner ? 'VICTORY!' : 'DEFEAT');

    final statusSubtitle = isSpeedTieBreak
        ? (isWinner
            ? 'Tied on score! You answered ${speedDiffSeconds.toStringAsFixed(1)}s faster!'
            : 'Tied on score! Rival answered ${speedDiffSeconds.toStringAsFixed(1)}s faster.')
        : (isWinner
            ? 'Decisive triumph! +$payoutCoins coins awarded.'
            : 'Tough match! +$payoutCoins coins consolation returned.');

    final netCoins = isWinner ? 20 : -20;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: borderColor, width: 1.2.w),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Status Badge
              Center(
                child: Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                      width: 1.5.w,
                    ),
                  ),
                  child: Icon(
                    isSpeedTieBreak
                        ? LucideIcons.zap
                        : (isWinner ? LucideIcons.trophy : LucideIcons.swords),
                    size: 28.sp,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Text(
                statusTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                statusSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),

              SizedBox(height: 16.h),

              // 2. Head-to-Head Telemetry Card
              Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    // You Column
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10.r,
                                backgroundColor: isWinner
                                    ? AppColors.emerald500.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.slate800 : const Color(0xFFE2E8F0)),
                                backgroundImage: myPhotoUrl != null && myPhotoUrl!.isNotEmpty
                                    ? NetworkImage(myPhotoUrl!)
                                    : null,
                                child: myPhotoUrl == null || myPhotoUrl!.isEmpty
                                    ? Text(
                                        myName.isNotEmpty ? myName[0].toUpperCase() : 'Y',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 4.w),
                              if (isWinner) ...[
                                Icon(LucideIcons.crown, size: 12.sp, color: const Color(0xFFF59E0B)),
                                SizedBox(width: 2.w),
                              ],
                              Flexible(
                                child: Text(
                                  myName.isNotEmpty ? myName : 'You',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$myScore',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: isWinner ? AppColors.emerald500 : textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$myCorrectCount/5 • ${(myTotalTimeMs / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VS Divider
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: textSecondary,
                        ),
                      ),
                    ),

                    // Rival Column
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10.r,
                                backgroundColor: !isWinner
                                    ? AppColors.emerald500.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.slate800 : const Color(0xFFE2E8F0)),
                                backgroundImage: rivalPhotoUrl != null && rivalPhotoUrl!.isNotEmpty
                                    ? NetworkImage(rivalPhotoUrl!)
                                    : null,
                                child: rivalPhotoUrl == null || rivalPhotoUrl!.isEmpty
                                    ? Text(
                                        rivalName.isNotEmpty ? rivalName[0].toUpperCase() : 'R',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 4.w),
                              if (!isWinner) ...[
                                Icon(LucideIcons.crown, size: 12.sp, color: const Color(0xFFF59E0B)),
                                SizedBox(width: 2.w),
                              ],
                              Flexible(
                                child: Text(
                                  rivalName.isNotEmpty ? rivalName : 'Rival',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$rivalScore',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: !isWinner ? AppColors.emerald500 : textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$rivalCorrectCount/5 • ${(rivalTotalTimeMs / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // 3. Economic Settlement Ledger ("What You Get / What You Lose")
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B101D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: borderColor.withValues(alpha: 0.8)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.coins, size: 14.sp, color: const Color(0xFFF59E0B)),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'COIN SETTLEMENT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? AppColors.emerald500.withValues(alpha: 0.15)
                                : AppColors.rose500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isWinner ? '+$netCoins COINS NET' : '$netCoins COINS NET',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: isWinner ? AppColors.emerald500 : AppColors.rose500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Divider(height: 1.h, color: borderColor.withValues(alpha: 0.5)),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Stake Paid',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.sp, color: textSecondary),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('30 🪙', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isWinner ? 'Prize Claimed' : 'Consolation Return',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.sp, color: textSecondary),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '+$payoutCoins 🪙',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: isWinner ? AppColors.emerald500 : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // 4. Performance Metric 3-Item Strip
              Row(
                children: [
                  _MetricPill(
                    icon: LucideIcons.target,
                    label: 'Accuracy',
                    value: '${((myCorrectCount / 5) * 100).toInt()}%',
                    borderColor: borderColor,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  _MetricPill(
                    icon: LucideIcons.timer,
                    label: 'Total Time',
                    value: '${(myTotalTimeMs / 1000).toStringAsFixed(1)}s',
                    borderColor: borderColor,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  _MetricPill(
                    icon: LucideIcons.zap,
                    label: 'Speed/Q',
                    value: '${(myTotalTimeMs / 5000).toStringAsFixed(1)}s',
                    borderColor: borderColor,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              // 5. Actions
              if (isWinner) ...[
                ScaleButton(
                  onTap: () {
                    final code = roomCode.isNotEmpty ? roomCode : 'VOWL';
                    final message =
                        '⚔️ I just won a 1v1 English Duel on Vowl with $myScore points against $rivalName!\n'
                        'Can you beat my vocabulary reflexes? Duel me now:\n'
                        'https://vowl.app/duel/$code';
                    SharePlus.instance.share(
                      ShareParams(
                        text: message,
                        subject: '1v1 English Duel Victory!',
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.indigo500, width: 1.2.w),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.share2, size: 15.sp, color: AppColors.indigo500),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Share Victory (Brag!)',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              // Rematch Button
              ScaleButton(
                onTap: onRematch,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.r),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.flame, size: 18.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '🔥 Rematch (Double or Nothing!)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 6.h),

              // Back to Games Hub Button
              ScaleButton(
                onTap: onClose,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    'Back to Arena Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color borderColor;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.borderColor,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: textSecondary),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
