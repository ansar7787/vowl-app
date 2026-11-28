import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_match_history_tile.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Displays the player's last 50 completed 1v1 Arena duels with
/// opponent rank badges, scores, and per-round mechanic breakdowns.
class ArenaMatchHistoryScreen extends StatefulWidget {
  final UserEntity user;

  const ArenaMatchHistoryScreen({super.key, required this.user});

  static Route<void> route({required UserEntity user}) {
    return MaterialPageRoute<void>(
      builder: (_) => ArenaMatchHistoryScreen(user: user),
    );
  }

  @override
  State<ArenaMatchHistoryScreen> createState() =>
      _ArenaMatchHistoryScreenState();
}

class _ArenaMatchHistoryScreenState extends State<ArenaMatchHistoryScreen> {
  late Future<List<ArenaMatchRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<ArenaMatchRecord>> _loadHistory() {
    if (!di.sl.isRegistered<ArenaRepository>()) {
      return Future.value(const []);
    }
    return di.sl<ArenaRepository>().getMatchHistory(
      userId: widget.user.id,
      limit: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = AppTheme.isMidnight(context);
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.ultraDeep : AppColors.slate50);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isMidnight
            ? Colors.black
            : (isDark ? AppColors.slate900 : Colors.white),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('arena.match_history', fallback: 'Match History'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ArenaMatchRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: VowlMicroLoader(color: AppColors.indigo500, size: 28),
            );
          }

          final records = snapshot.data ?? const [];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.swords,
                      size: 36.r,
                      color: AppColors.indigo500,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      context.tr(
                        'arena.match_history_empty',
                        fallback: 'No Match History Yet',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Complete a 7-round Hybrid Pentathlon duel to see detailed round-by-round replays here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _historyFuture = _loadHistory();
              });
              await _historyFuture;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.all(16.r),
              itemCount: records.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                return ArenaMatchHistoryTile(
                  record: records[index],
                  isDark: isDark,
                  isMidnight: isMidnight,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
