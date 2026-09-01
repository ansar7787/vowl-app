import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_anagram_wrapper.dart';
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

class WordMixerScreen extends StatefulWidget {
  const WordMixerScreen({super.key});

  @override
  State<WordMixerScreen> createState() => _WordMixerScreenState();
}

class _WordMixerScreenState extends State<WordMixerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Map<String, dynamic>?> _currentPuzzle = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadDailyPuzzle();
  }

  @override
  void dispose() {
    _currentPuzzle.dispose();
    _isAnswered.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPuzzle() async {
    final puzzle = await DailyChallengeService.getTodayWordMixer();
    if (mounted) {
      _currentPuzzle.value = puzzle;
    }
  }

  void _onSuccess() {
    _hapticService.success();
    _soundService.playCorrect();
    _isAnswered.value = true;

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
            // User didn't finish ad, they get nothing but the game is over.
            if (mounted) context.pop();
          }
        },
      );
    } else {
      _grantRewards();
    }
  }

  void _grantRewards() {
    // Credit coins directly to the user's ledger
    di.sl<UpdateUserCoins>().call(
      const UpdateUserCoinsParams(
        amountChange: 10,
        title: 'Word Mixer Challenge',
        isEarned: true,
      ),
    );

    GameDialogHelper.showCompletion(
      context,
      xp: 50,
      coins: 10,
      title: context.tr(
        'home.word_mixer_master',
        fallback: 'WORD MIXER MASTER!',
      ),
      enableDoubleUp: true,
    );
  }

  void _onFail() {
    _hapticService.error();
    _soundService.playWrong();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFA855F7);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([_currentPuzzle, _isAnswered]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          body: SafeArea(
            child: _currentPuzzle.value == null
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
                              SizedBox(height: 20.h),
                              _buildHeaderCard(primaryColor, isDark),
                              SizedBox(height: 40.h),
                              _buildHintCard(primaryColor, isDark),
                              SizedBox(height: 180.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isAnswered.value)
                    DynamicAnagramWrapper(
                      expectedText: _currentPuzzle.value!['word']!,
                      primaryColor: primaryColor,
                      onConfirmed: _onSuccess,
                      onFailed: _onFail,
                      bonusCoins: 20,
                      title: context.tr('home.spell_it', fallback: 'SPELL IT!'),
                      subtitle: context.tr(
                        'home.spell_it_subtitle',
                        fallback:
                            'Tap the letters in the correct order to form the word.',
                      ),
                    ),
                ],
              ),
          ),
        );
      }
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
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
              Icon(
                Icons.sort_by_alpha_rounded,
                color: primaryColor,
                size: 36.sp,
              ),
              SizedBox(width: 48.w), // Balance for centering
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            context.tr('home.word_mixer', fallback: 'Word Mixer'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
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
            context.tr('home.hint', fallback: 'HINT'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _currentPuzzle.value!['hint'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
