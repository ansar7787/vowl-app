import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_rank_badge.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';

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
  final bool isAiRival;
  final bool showConfetti;
  final int totalRounds;
  final int myDuelWins;
  final int rivalDuelWins;
  final List<ArenaRoundResult> roundResults;
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
    this.isAiRival = false,
    this.showConfetti = true,
    this.totalRounds = 5,
    this.myDuelWins = 0,
    this.rivalDuelWins = 0,
    this.roundResults = const [],
    required this.onRematch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark
        ? AppColors.midnightSurface
        : (tokens?.surface ?? Colors.white);
    final borderColor = isDark
        ? AppColors.slate800
        : (tokens?.border ?? AppColors.slate200);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? AppColors.slate900);
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? AppColors.slate500);
    final cardBg = isDark ? AppColors.ultraDeep : AppColors.slate50;

    final statusColor = isSpeedTieBreak
        ? AppColors.amber500
        : (isDraw
              ? AppColors.indigo500
              : (isWinner ? AppColors.emerald500 : AppColors.rose500));

    final statusTitle = isSpeedTieBreak
        ? (isWinner ? '⚡ SPEED VICTORY!' : '⚡ TIME TIEBREAKER')
        : (isDraw ? 'DRAW!' : (isWinner ? 'VICTORY!' : 'DEFEAT'));

    final statusSubtitle = isSpeedTieBreak
        ? (isWinner
              ? 'Tied on points! You were ${speedDiffSeconds.toStringAsFixed(1)}s faster!'
              : 'Tied on points! Rival was ${speedDiffSeconds.toStringAsFixed(1)}s faster.')
        : (isDraw
              ? 'Exact tie! Your $payoutCoins coins were refunded.'
              : (isWinner
                    ? 'Great match! +$payoutCoins coins won.'
                    : 'Good match! +$payoutCoins coins returned.'));

    final effectiveRounds = totalRounds > 0
        ? totalRounds
        : (roundResults.isNotEmpty ? roundResults.length : 5);
    final netCoins = payoutCoins - 30;

    final dialog = Dialog(
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
                        : (isDraw
                              ? LucideIcons.scale
                              : (isWinner
                                    ? LucideIcons.trophy
                                    : LucideIcons.swords)),
                    size: 28.sp,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Text(
                statusTitle,
                textAlign: TextAlign.center,
                softWrap: true,
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
                softWrap: true,
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
                                    ? AppColors.emerald500.withValues(
                                        alpha: 0.15,
                                      )
                                    : (isDark
                                          ? AppColors.slate800
                                          : AppColors.slate200),
                                backgroundImage:
                                    myPhotoUrl != null && myPhotoUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(myPhotoUrl!)
                                    : null,
                                child: myPhotoUrl == null || myPhotoUrl!.isEmpty
                                    ? Text(
                                        myName.isNotEmpty
                                            ? myName[0].toUpperCase()
                                            : 'Y',
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
                                Icon(
                                  LucideIcons.trophy,
                                  size: 12.sp,
                                  color: AppColors.amber500,
                                ),
                                SizedBox(width: 3.w),
                              ],
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    myName.isNotEmpty ? myName : 'You',
                                    softWrap: true,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
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
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: isWinner
                                    ? AppColors.emerald500
                                    : textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$myCorrectCount/$effectiveRounds • ${(myTotalTimeMs / 1000).toStringAsFixed(1)}s',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ArenaRankBadge.fromWins(
                            duelWins: myDuelWins,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // VS Divider
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'VS',
                        softWrap: true,
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
                              if (isAiRival &&
                                  (rivalPhotoUrl == null ||
                                      rivalPhotoUrl!.isEmpty))
                                Container(
                                  width: 20.r,
                                  height: 20.r,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.cyan400,
                                        AppColors.blue500,
                                      ],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/vowly_head.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                CircleAvatar(
                                  radius: 10.r,
                                  backgroundColor: (!isWinner && !isDraw)
                                      ? AppColors.emerald500.withValues(
                                          alpha: 0.15,
                                        )
                                      : (isDark
                                            ? AppColors.slate800
                                            : AppColors.slate200),
                                  backgroundImage:
                                      rivalPhotoUrl != null &&
                                          rivalPhotoUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(rivalPhotoUrl!)
                                      : null,
                                  child:
                                      rivalPhotoUrl == null ||
                                          rivalPhotoUrl!.isEmpty
                                      ? Text(
                                          rivalName.isNotEmpty
                                              ? rivalName[0].toUpperCase()
                                              : 'R',
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                              SizedBox(width: 4.w),
                              if (!isWinner && !isDraw) ...[
                                Icon(
                                  LucideIcons.trophy,
                                  size: 12.sp,
                                  color: AppColors.amber500,
                                ),
                                SizedBox(width: 3.w),
                              ],
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    rivalName.isNotEmpty ? rivalName : 'Rival',
                                    softWrap: true,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
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
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: (!isWinner && !isDraw)
                                    ? AppColors.emerald500
                                    : textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$rivalCorrectCount/$effectiveRounds • ${(rivalTotalTimeMs / 1000).toStringAsFixed(1)}s',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ArenaRankBadge.fromWins(
                            duelWins: rivalDuelWins,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // 3. Match Rewards Ledger ("What You Get / What You Lose")
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.midnightSurface
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: borderColor.withValues(alpha: 0.8)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.coins,
                          size: 14.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'MATCH REWARDS',
                              softWrap: true,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: (isDraw
                                    ? AppColors.indigo500
                                    : (isWinner
                                          ? AppColors.emerald500
                                          : AppColors.rose500))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            netCoins > 0
                                ? '+$netCoins COINS'
                                : (netCoins == 0
                                      ? '0 COINS'
                                      : '$netCoins COINS'),
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: isDraw
                                  ? AppColors.indigo500
                                  : (isWinner
                                        ? AppColors.emerald500
                                        : AppColors.rose500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Divider(
                      height: 1.h,
                      color: borderColor.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Entry Fee',
                            maxLines: 2,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '30 🪙',
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isWinner ? 'Coins Won' : 'Coins Returned',
                            maxLines: 2,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '+$payoutCoins 🪙',
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: isWinner
                                ? AppColors.emerald500
                                : AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                    if (isWinner) ...[
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Win Bonus',
                              maxLines: 2,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '+5 XP ⚡',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.indigo500,
                            ),
                          ),
                        ],
                      ),
                      if (myCorrectCount >= effectiveRounds) ...[
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Perfect $effectiveRounds/$effectiveRounds Bonus',
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '+10 🪙 🎯',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Match XP',
                              maxLines: 2,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '+0 XP',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    value:
                        '${((myCorrectCount / effectiveRounds) * 100).round()}%',
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
                    value:
                        '${(myTotalTimeMs / (effectiveRounds * 1000)).toStringAsFixed(1)}s',
                    borderColor: borderColor,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),

              if (roundResults.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _RoundBreakdownPanel(
                  roundResults: roundResults,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],

              SizedBox(height: 18.h),

              // 5. Share Card Action (Winners & Contenders)
              ScaleButton(
                onTap: () {
                  final code = roomCode.isNotEmpty ? roomCode : 'VOWL';
                  final effectiveRival = rivalName.isNotEmpty
                      ? rivalName
                      : 'Challenger';
                  final shareData = isWinner
                      ? ShareCardData.fromArenaVictory(
                          userName: myName,
                          userPhotoUrl: myPhotoUrl,
                          myScore: myScore,
                          rivalScore: rivalScore,
                          rivalName: effectiveRival,
                          roomCode: code,
                          payoutCoins: payoutCoins,
                          isAiRival: isAiRival,
                        )
                      : (isDraw
                            ? ShareCardData.fromArenaDraw(
                                userName: myName,
                                userPhotoUrl: myPhotoUrl,
                                myScore: myScore,
                                rivalScore: rivalScore,
                                rivalName: effectiveRival,
                                roomCode: code,
                                payoutCoins: payoutCoins,
                                isAiRival: isAiRival,
                              )
                            : ShareCardData.fromArenaDefeat(
                                userName: myName,
                                userPhotoUrl: myPhotoUrl,
                                myScore: myScore,
                                rivalScore: rivalScore,
                                rivalName: effectiveRival,
                                roomCode: code,
                                payoutCoins: payoutCoins,
                                isAiRival: isAiRival,
                              ));
                  ShareCardPreviewModal.show(context: context, data: shareData);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500,
                      width: 1.2.w,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.share2,
                        size: 15.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isWinner
                                ? 'Share Victory Card'
                                : (isDraw
                                      ? 'Share Draw Card'
                                      : 'Share Battle Card'),
                            softWrap: true,
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

              // Rematch Button
              ScaleButton(
                onTap: onRematch,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.indigo600],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.35),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.r),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.swords,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Rematch (30🪙)',
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
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

              // Back to Arena Hub Button
              ScaleButton(
                onTap: onClose,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    'Back to Arena',
                    softWrap: true,
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

    final content = (!isWinner || !showConfetti)
        ? dialog
        : Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              dialog,
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(child: GameConfetti(shouldPop: true)),
                ),
              ),
            ],
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onClose();
      },
      child: content,
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
                softWrap: true,
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
                softWrap: true,
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

class _RoundBreakdownPanel extends StatefulWidget {
  final List<ArenaRoundResult> roundResults;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _RoundBreakdownPanel({
    required this.roundResults,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_RoundBreakdownPanel> createState() => _RoundBreakdownPanelState();
}

class _RoundBreakdownPanelState extends State<_RoundBreakdownPanel> {
  int? _selectedRoundIndex;

  @override
  Widget build(BuildContext context) {
    final selected =
        (_selectedRoundIndex != null &&
            _selectedRoundIndex! >= 0 &&
            _selectedRoundIndex! < widget.roundResults.length)
        ? widget.roundResults[_selectedRoundIndex!]
        : null;
    final hasDetails =
        selected != null &&
        ((selected.prompt?.isNotEmpty ?? false) ||
            (selected.correctAnswer?.isNotEmpty ?? false) ||
            (selected.explanation?.isNotEmpty ?? false));

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    'arena.round_breakdown',
                    fallback: 'ROUND BREAKDOWN',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: widget.textSecondary,
                  ),
                ),
              ),
              if (widget.roundResults.any(
                (r) =>
                    (r.correctAnswer?.isNotEmpty ?? false) ||
                    (r.explanation?.isNotEmpty ?? false),
              ))
                Text(
                  context.tr(
                    'arena.tap_round_review',
                    fallback: 'Tap any round to review',
                  ),
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.textSecondary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: List.generate(widget.roundResults.length, (idx) {
              final r = widget.roundResults[idx];
              final col = r.isCorrect
                  ? AppColors.emerald500
                  : AppColors.rose500;
              final isSelected = _selectedRoundIndex == idx;
              final label = r.rapidCorrectItems != null
                  ? '${r.mechanic.icon} ${r.mechanic.displayName} (${r.rapidCorrectItems}/${r.rapidTotalItems ?? 6})'
                  : '${r.mechanic.icon} ${r.mechanic.displayName} ${r.isCorrect ? "✓" : "✗"}';
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRoundIndex = isSelected ? null : idx;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: isSelected ? 0.24 : 0.12),
                    borderRadius: BorderRadius.circular(7.r),
                    border: Border.all(
                      color: col.withValues(alpha: isSelected ? 0.90 : 0.35),
                      width: isSelected ? 1.3 : 0.8,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: col,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (hasDetails) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: widget.borderColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selected.prompt?.isNotEmpty ?? false)
                    Text(
                      selected.prompt!,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                  if (selected.correctAnswer?.isNotEmpty ?? false) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Answer: ${selected.correctAnswer!}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ],
                  if (selected.explanation?.isNotEmpty ?? false) ...[
                    SizedBox(height: 2.h),
                    Text(
                      selected.explanation!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
