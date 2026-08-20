import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_jigsaw_wrapper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';

class WordSnapScreen extends StatefulWidget {
  final int level;

  const WordSnapScreen({
    super.key,
    this.level = 1,
  });

  @override
  State<WordSnapScreen> createState() => _WordSnapScreenState();
}

class _WordSnapScreenState extends State<WordSnapScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Map<String, dynamic>? _currentPuzzle;
  bool _isAnswered = false;
  bool _pendingSnap = false;

  @override
  void initState() {
    super.initState();
    _loadDailyPuzzle();
  }

  Future<void> _loadDailyPuzzle() async {
    final puzzle = await DailyChallengeService.getTodayWordSnap();
    if (mounted) {
      setState(() {
        _currentPuzzle = puzzle;
      });
    }
  }

  void _onSubmit(bool nailedIt) {
    if (_isAnswered) return;

    if (nailedIt) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _isAnswered = true;
        _pendingSnap = false;
      });

      final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

      if (!isPremium) {
        final adService = di.sl<AdService>();
        bool adWatched = false;

        adService.showRewardedAd(
          context: context,
          isPremium: false,
          childSafe: false,
          onUserEarnedReward: (_) {
            adWatched = true;
          },
          onDismissed: () {
            if (adWatched) {
              _grantRewards();
            } else {
              if (mounted) context.pop();
            }
          },
        );
      } else {
        _grantRewards();
      }
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _isAnswered = true;
        _pendingSnap = false;
      });
      GameDialogHelper.showGameOver(context);
    }
  }

  void _grantRewards() {
    // Credit coins directly to the user's ledger
    di.sl<UpdateUserCoins>().call(
      const UpdateUserCoinsParams(
        amountChange: 10,
        title: 'Word Snap Challenge',
        isEarned: true,
      ),
    );

    GameDialogHelper.showCompletion(
      context,
      xp: 50,
      coins: 10,
      title: context.tr('vocabulary.word_snap_master', fallback: 'WORD SNAP MASTER!'),
      enableDoubleUp: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF59E0B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: _currentPuzzle == null
            ? GameShimmerLoading(primaryColor: primaryColor)
            : Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(24.r),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              _buildHeaderCard(primaryColor, isDark),
                              SizedBox(height: 40.h),
                              _buildQuestContent(primaryColor, isDark),
                              SizedBox(height: (_isAnswered || _pendingSnap) ? 160.h : 60.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isAnswered && !_pendingSnap)
                    Positioned(
                      bottom: 40.h,
                      left: 24.w,
                      right: 24.w,
                      child: ElevatedButton(
                        onPressed: () {
                          _hapticService.selection();
                          setState(() => _pendingSnap = true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          context.tr('games.start_assembling', fallback: 'Start Assembling'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_pendingSnap && !_isAnswered)
                    DynamicJigsawWrapper(
                      expectedText: _currentPuzzle!['word']!,
                      primaryColor: primaryColor,
                      onConfirmed: () => _onSubmit(true),
                      onSkipped: () => _onSubmit(false),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    final instruction = _currentPuzzle!['instruction'] as String? ?? 'Assemble the pieces into meaning.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.close_rounded, color: primaryColor),
              ),
              Icon(Icons.extension_rounded, color: primaryColor, size: 36.sp),
              SizedBox(width: 48.w), // Balance for centering
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            instruction.isEmpty ? 'Assemble the pieces into meaning.' : instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestContent(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            (_currentPuzzle!['word'] as String).toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 2,
            ),
          ),
          if (_currentPuzzle!['question'] != null && (_currentPuzzle!['question'] as String).isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              _currentPuzzle!['question'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
