import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';

import 'package:vowl/features/profile/presentation/widgets/adventure_total_xp_card.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_daily_xp_chart.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_mastery_grid.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_store_section.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_recent_activities.dart';

class AdventureXPScreen extends StatelessWidget {
  const AdventureXPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<ProgressionBloc, ProgressionState>(
      listener: (context, state) {
        if (state.message != null) {
          final rawMessage = state.message!;
          final lowerMsg = rawMessage.toLowerCase();
          final isError =
              state.lastPurchaseSuccess == false ||
              lowerMsg.contains('not enough') ||
              lowerMsg.contains('failed') ||
              lowerMsg.contains('insufficient') ||
              lowerMsg.contains('lacking');

          String displayMessage;
          if (isError) {
            displayMessage = context.tr(
              'adventure.insufficient_coins',
              fallback: 'Not enough coins!',
            );
          } else if (rawMessage.startsWith('Exception: ') ||
              rawMessage.startsWith('ServerFailure: ')) {
            di.sl<AppLogger>().error(
              'Unhandled ProgressionBloc message shown as generic error',
              error: rawMessage,
            );
            displayMessage = context.tr(
              'adventure.generic_error',
              fallback: 'Something went wrong.',
            );
          } else {
            displayMessage = rawMessage;
          }

          di.sl<HapticService>().light();

          CustomSnackBar.show(
            context: context,
            message: displayMessage,
            type: isError
                ? CustomSnackBarType.error
                : CustomSnackBarType.success,
          );

          context.read<ProgressionBloc>().add(
            const ProgressionClearMessageRequested(),
          );
        }
      },
      child: Builder(
        builder: (context) {
          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
          final bgColor = isMidnight
              ? Colors.black
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
          return Scaffold(
            backgroundColor: bgColor,
            body: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state.user;
                if (user == null) return const SizedBox.shrink();

                return Stack(
                  children: [
                    const MeshGradientBackground(),
                    SafeArea(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ── App Bar ──────────────────────────────────
                          SliverAppBar(
                            pinned: true,
                            floating: true,
                            snap: true,
                            automaticallyImplyLeading: false,
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            toolbarHeight: 64.h,
                            titleSpacing: 16.r,
                            centerTitle: false,
                            title: GlassTile(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.r,
                                vertical: 6.r,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Semantics(
                                    label: context.tr(
                                      'adventure.back_label',
                                      fallback: 'Go back',
                                    ),
                                    child: SizedBox(
                                      width: 32.r,
                                      height: 32.r,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 18.r,
                                        onPressed: () => context.pop(),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.r),
                                  Text(
                                    context.tr(
                                      'adventure.screen_title',
                                      fallback: 'Adventure XP',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Body Content ────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(24.r, 24.r, 24.r, 0),
                              child: AdventureTotalXpCard(user: user),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.r),
                              child: AdventureDailyXpChart(
                                history: user.dailyXpHistory,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.r),
                              child: AdventureMasteryGrid(user: user),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.r),
                              child: AdventureStoreSection(user: user),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.r),
                              child: AdventureRecentActivities(user: user),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24.r,
                                24.r,
                                24.r,
                                48.r,
                              ),
                              child: const AdRewardCard(
                                margin: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
