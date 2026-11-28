import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_rank_badge.dart';

/// Card tile displaying one completed match record in [ArenaMatchHistoryScreen],
/// including opponent rank badge, score, outcome, and tappable per-round review.
class ArenaMatchHistoryTile extends StatefulWidget {
  final ArenaMatchRecord record;
  final bool isDark;
  final bool isMidnight;

  const ArenaMatchHistoryTile({
    super.key,
    required this.record,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  State<ArenaMatchHistoryTile> createState() => _ArenaMatchHistoryTileState();
}

class _ArenaMatchHistoryTileState extends State<ArenaMatchHistoryTile> {
  int? _selectedRoundIndex;

  String _formatRelativeTime(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.isNegative || diff.inSeconds < 60) {
      return context.tr('arena.just_now', fallback: 'Just now');
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isDark = widget.isDark;
    final isMidnight = widget.isMidnight;

    final Color statusColor = record.isWin
        ? AppColors.emerald500
        : (record.isDraw ? AppColors.amber500 : AppColors.rose500);
    final String statusLabel = record.isWin
        ? context.tr('arena.victory', fallback: 'VICTORY')
        : (record.isDraw
              ? context.tr('arena.draw', fallback: 'DRAW')
              : context.tr('arena.defeat', fallback: 'DEFEAT'));
    final IconData statusIcon = record.isWin
        ? LucideIcons.trophy
        : (record.isDraw ? LucideIcons.scale : LucideIcons.shieldAlert);

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    final selectedRound =
        (_selectedRoundIndex != null &&
            _selectedRoundIndex! >= 0 &&
            _selectedRoundIndex! < record.rounds.length)
        ? record.rounds[_selectedRoundIndex!]
        : null;
    final hasReviewDetails =
        selectedRound != null &&
        ((selectedRound.prompt?.isNotEmpty ?? false) ||
            (selectedRound.correctAnswer?.isNotEmpty ?? false) ||
            (selectedRound.explanation?.isNotEmpty ?? false));

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Opponent Avatar
              if (record.isGhostRival &&
                  (record.opponentPhotoUrl == null ||
                      record.opponentPhotoUrl!.isEmpty))
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.cyan400, AppColors.blue500],
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
                UserAvatar(photoUrl: record.opponentPhotoUrl, size: 38.r),
              SizedBox(width: 10.w),

              // Opponent Name, Rank Badge & Mode Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.opponentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        ArenaRankBadge(
                          rank: record.opponentRank,
                          compact: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: (record.isGhostRival
                                    ? AppColors.cyan400
                                    : AppColors.emerald500)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            record.isGhostRival
                                ? context.tr(
                                    'arena.ai_rival',
                                    fallback: 'AI RIVAL',
                                  )
                                : context.tr(
                                    'arena.live_pvp',
                                    fallback: 'LIVE PVP',
                                  ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w900,
                              color: record.isGhostRival
                                  ? AppColors.cyan400
                                  : AppColors.emerald500,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _formatRelativeTime(context, record.timestamp),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score & Result Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11.sp, color: statusColor),
                        SizedBox(width: 4.w),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${record.myScore} vs ${record.rivalScore}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (record.rounds.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: List.generate(record.rounds.length, (idx) {
                final r = record.rounds[idx];
                final chipColor = r.isCorrect
                    ? AppColors.emerald500
                    : AppColors.rose500;
                final isSelected = _selectedRoundIndex == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRoundIndex = isSelected ? null : idx;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: isSelected ? 0.22 : 0.10),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: chipColor.withValues(alpha: isSelected ? 0.90 : 0.30),
                        width: isSelected ? 1.3 : 0.8,
                      ),
                    ),
                    child: Text(
                      r.rapidCorrectItems != null
                          ? '${r.mechanic.icon} ${r.rapidCorrectItems}/${r.rapidTotalItems ?? 6}'
                          : '${r.mechanic.icon} ${r.isCorrect ? "✓" : "✗"}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: chipColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (hasReviewDetails) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedRound.mechanic.icon} ${selectedRound.mechanic.displayName}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w900,
                        color: selectedRound.isCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500,
                      ),
                    ),
                    if (selectedRound.prompt?.isNotEmpty ?? false) ...[
                      SizedBox(height: 3.h),
                      Text(
                        selectedRound.prompt!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                    if (selectedRound.correctAnswer?.isNotEmpty ?? false) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Answer: ${selectedRound.correctAnswer!}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald500,
                        ),
                      ),
                    ],
                    if (selectedRound.explanation?.isNotEmpty ?? false) ...[
                      SizedBox(height: 2.h),
                      Text(
                        selectedRound.explanation!,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
