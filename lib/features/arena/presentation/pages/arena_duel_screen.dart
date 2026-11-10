import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/arena/presentation/pages/arena_matchmaking_screen.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_result_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_score_hud.dart';
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/arena/presentation/utils/arena_refuel_helper.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_context_blitz_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_discipline_strip.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_option_tile.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_phrase_duel_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_sentence_strike_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_waiting_view.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_word_clash_hero.dart';

class ArenaDuelScreen extends StatelessWidget {
  final ArenaDuelSession initialSession;

  const ArenaDuelScreen({super.key, required this.initialSession});

  static Route<void> route({required ArenaDuelSession session}) {
    return MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ArenaDuelScreen(initialSession: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ArenaDuelCubit(repository: di.sl<ArenaRepository>());
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          cubit.startSession(initialSession, authState.user!);
        }
        return cubit;
      },
      child: const _ArenaDuelView(),
    );
  }
}

class _ArenaDuelView extends StatefulWidget {
  const _ArenaDuelView();

  @override
  State<_ArenaDuelView> createState() => _ArenaDuelViewState();
}

class _ArenaDuelViewState extends State<_ArenaDuelView>
    with WidgetsBindingObserver {
  StreamSubscription<AppNetworkStatus>? _networkSubscription;
  Timer? _countdownTimer;
  Timer? _backgroundForfeitTimer;
  bool _isOffline = false;
  bool _hasTriggeredMatchFound = false;
  bool _hasTriggeredFirstBlood = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (di.sl.isRegistered<NetworkInfo>()) {
      final networkInfo = di.sl<NetworkInfo>();
      _isOffline = networkInfo.isCurrentlyOffline;
      _networkSubscription = networkInfo.onStatusChange.listen((status) {
        if (mounted) {
          setState(() {
            _isOffline = status == AppNetworkStatus.offline;
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final cubit = context.read<ArenaDuelCubit>();
      if (!cubit.state.isCompleted && !cubit.state.isWaitingForGuest) {
        _backgroundForfeitTimer?.cancel();
        _backgroundForfeitTimer = Timer(const Duration(seconds: 30), () {
          if (mounted) {
            _forfeitDueToInactivity();
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _backgroundForfeitTimer?.cancel();
      _backgroundForfeitTimer = null;
    }
  }

  void _forfeitDueToInactivity() async {
    final cubit = context.read<ArenaDuelCubit>();
    final session = cubit.state.session;
    final authState = context.read<AuthBloc>().state;
    if (session != null && authState.user != null) {
      await di.sl<ArenaRepository>().forfeitMatch(
        roomCode: session.roomCode,
        userId: authState.user!.id,
      );
    }
    if (mounted) {
      context.read<AuthBloc>().add(const AuthReloadUser());
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      } else {
        GoRouter.of(context).go(AppRouter.gamesRoute);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundForfeitTimer?.cancel();
    _countdownTimer?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final backgroundColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : Colors.white);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? AppColors.slate900);
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? AppColors.slate500);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: isMidnight
              ? Colors.black
              : (isDark ? AppColors.slate900 : Colors.white),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.x, size: 20.sp, color: textPrimary),
            onPressed: () => _confirmExit(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.swords, size: 18.sp, color: AppColors.indigo500),
              SizedBox(width: 8.w),
              Text(
                '1v1 Arena Duel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.amber500,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.wifiOff,
                      size: 14.sp,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Reconnecting to Arena... Checking network connection',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocConsumer<ArenaDuelCubit, ArenaDuelState>(
                buildWhen: (prev, curr) =>
                    prev.isWaitingForGuest != curr.isWaitingForGuest ||
                    prev.isWaitingForOpponentFinish !=
                        curr.isWaitingForOpponentFinish ||
                    (prev.currentQuestion == null) !=
                        (curr.currentQuestion == null) ||
                    prev.session?.roomCode != curr.session?.roomCode ||
                    prev.session?.guestId != curr.session?.guestId ||
                    prev.isCompleted != curr.isCompleted,
                listener: (context, state) {
                  if (!state.isWaitingForGuest &&
                      !state.isCompleted &&
                      state.currentQuestion != null &&
                      !_hasTriggeredMatchFound) {
                    _hasTriggeredMatchFound = true;
                    if (di.sl.isRegistered<SoundService>()) {
                      di.sl<SoundService>().playArenaMatchFound();
                      _countdownTimer?.cancel();
                      _countdownTimer = Timer(
                        const Duration(milliseconds: 380),
                        () {
                          if (mounted && di.sl.isRegistered<SoundService>()) {
                            try {
                              di.sl<SoundService>().playArenaCountdown();
                            } catch (_) {}
                          }
                        },
                      );
                    }
                    if (di.sl.isRegistered<HapticService>()) {
                      di.sl<HapticService>().heavy();
                    }
                  }

                  if (state.hasFirstBlood && !_hasTriggeredFirstBlood) {
                    _hasTriggeredFirstBlood = true;
                    if (di.sl.isRegistered<HapticService>()) {
                      di.sl<HapticService>().success();
                    }
                    CustomSnackBar.show(
                      context: context,
                      message: '⚡ FIRST BLOOD! Early round advantage.',
                      type: CustomSnackBarType.success,
                    );
                  }

                  if (state.timeRemaining == 3 &&
                      !state.isCompleted &&
                      !state.isWaitingForGuest) {
                    if (di.sl.isRegistered<HapticService>()) {
                      di.sl<HapticService>().warning();
                    }
                  }

                  if (state.isCompleted) {
                    context.read<AuthBloc>().add(const AuthReloadUser());
                    if (di.sl.isRegistered<SoundService>()) {
                      if (state.isWinner) {
                        di.sl<SoundService>().playArenaVictory();
                      } else if (state.isDraw) {
                        di.sl<SoundService>().playLevelComplete();
                      } else {
                        di.sl<SoundService>().playArenaDefeat();
                      }
                    }
                    if (di.sl.isRegistered<HapticService>()) {
                      if (state.isWinner) {
                        di.sl<HapticService>().success();
                      } else {
                        di.sl<HapticService>().selection();
                      }
                    }

                    final authState = context.read<AuthBloc>().state;
                    final currentUserId = authState.user?.id ?? '';
                    final session = state.session;
                    final rivalName = session?.opponentName(currentUserId) ?? 'Challenger';
                    final rivalPhoto = session?.opponentPhotoUrl(currentUserId);
                    final myName = session?.myName(currentUserId) ??
                        (authState.user?.safeDisplayName ?? 'You');
                    final myPhoto = session?.myPhotoUrl(currentUserId) ??
                        authState.user?.photoUrl;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => ArenaResultDialog(
                        isWinner: state.isWinner,
                        isDraw: state.isDraw,
                        isSpeedTieBreak: state.isSpeedTieBreak,
                        speedDiffSeconds: state.speedDiffSeconds,
                        myScore: state.myScore,
                        rivalScore: state.rivalScore,
                        myCorrectCount: state.myCorrectCount,
                        rivalCorrectCount: state.rivalCorrectCount,
                        myTotalTimeMs: state.myTotalTimeMs,
                        rivalTotalTimeMs: state.rivalTotalTimeMs,
                        rivalName: rivalName,
                        rivalPhotoUrl: rivalPhoto,
                        myName: myName,
                        myPhotoUrl: myPhoto,
                        payoutCoins: state.payoutCoins,
                        roomCode: state.session?.roomCode ?? '',
                        isAiRival: state.session?.isGhostRival ?? false,
                        onRematch: () {
                          Navigator.of(dialogCtx).pop();
                          if (authState.status == AuthStatus.authenticated &&
                              authState.user != null) {
                            _triggerRematch(context, authState.user!);
                          }
                        },
                        onClose: () {
                          Navigator.of(dialogCtx).pop();
                          context.read<AuthBloc>().add(const AuthReloadUser());
                          final nav = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          if (nav.canPop()) {
                            nav.pop();
                          } else {
                            GoRouter.of(context).go(AppRouter.gamesRoute);
                          }
                        },
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final authState = context.watch<AuthBloc>().state;
                  final user = authState.status == AuthStatus.authenticated
                      ? authState.user
                      : null;
                  if (user == null) return const SizedBox.shrink();

                  if (state.isWaitingForGuest) {
                    return ArenaMatchingLoader(
                      roomCode: state.session?.roomCode,
                      showShareCode: true,
                    );
                  }

                  final rivalName = state.session?.opponentName(user.id) ?? 'Challenger';
                  final rivalPhoto = state.session?.opponentPhotoUrl(user.id);

                  // SUSPENSE STATE: Completed 5 rounds, waiting for rival to finish
                  if (state.isWaitingForOpponentFinish && !state.isCompleted) {
                    return ArenaWaitingView(
                      state: state,
                      user: user,
                      rivalName: rivalName,
                      rivalPhoto: rivalPhoto,
                      isDark: isDark,
                      isMidnight: isMidnight,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    );
                  }

                  final q = state.currentQuestion;
                  if (q == null) {
                    return const ArenaMatchingLoader(
                      customMessage: 'Loading next vocabulary duel...',
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.compact,
                      vertical: 12.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live Score HUD: Isolated rebuilds for countdown & real-time points
                        RepaintBoundary(
                          child: BlocBuilder<ArenaDuelCubit, ArenaDuelState>(
                            buildWhen: (prev, curr) =>
                                prev.timeRemaining != curr.timeRemaining ||
                                prev.myScore != curr.myScore ||
                                prev.rivalScore != curr.rivalScore ||
                                prev.currentQuestionIndex !=
                                    curr.currentQuestionIndex ||
                                prev.isAnswered != curr.isAnswered ||
                                prev.comboStreak != curr.comboStreak,
                            builder: (context, hudState) {
                              return ArenaScoreHud(
                                myName: user.safeDisplayName,
                                myPhotoUrl: user.photoUrl,
                                myScore: hudState.myScore,
                                rivalName: rivalName,
                                rivalPhotoUrl: rivalPhoto,
                                rivalScore: hudState.rivalScore,
                                currentQuestionIndex:
                                    hudState.currentQuestionIndex,
                                totalQuestions:
                                    hudState.session?.questions.length ?? 5,
                                timeRemaining: hudState.timeRemaining,
                                isAnswered: hudState.isAnswered,
                                isDark: isDark,
                                isAiRival:
                                    hudState.session?.isGhostRival ?? false,
                                aiTierLabel: () {
                                  final session = hudState.session;
                                  if (session == null || !session.isGhostRival) {
                                    return null;
                                  }
                                  final gid =
                                      session.guestId?.toLowerCase() ?? '';
                                  if (gid.contains('hard')) {
                                    return 'HARD';
                                  }
                                  if (gid.contains('medium') ||
                                      gid.contains('med')) {
                                    return 'MED';
                                  }
                                  if (gid.contains('easy')) {
                                    return 'EASY';
                                  }
                                  if (session.ghostAccuracy >= 0.86) {
                                    return 'HARD';
                                  }
                                  if (session.ghostAccuracy >= 0.74) {
                                    return 'MED';
                                  }
                                  return 'EASY';
                                }(),
                                comboStreak: hudState.comboStreak,
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // Discipline Hero Card, Options, and Explanation:
                        // Isolated to only rebuild on question transition or answer tap (0 timer ticks)
                        Expanded(
                          child: BlocBuilder<ArenaDuelCubit, ArenaDuelState>(
                            buildWhen: (prev, curr) =>
                                prev.currentQuestionIndex !=
                                    curr.currentQuestionIndex ||
                                prev.isAnswered != curr.isAnswered ||
                                prev.selectedOption != curr.selectedOption ||
                                prev.currentQuestion != curr.currentQuestion,
                            builder: (context, qState) {
                              final activeQ = qState.currentQuestion;
                              if (activeQ == null) {
                                return const SizedBox.shrink();
                              }

                              final isWordClash =
                                  activeQ.discipline == 'word_clash';
                              final isShortOptions = activeQ.options.every(
                                (opt) =>
                                    opt.trim().length <= 14 &&
                                    !opt.trim().contains(' '),
                              );
                              final shouldUseGrid =
                                  isWordClash && isShortOptions;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Animated Discipline Strip above Hero Card
                                  ArenaDisciplineStrip(
                                    question: activeQ,
                                    currentRound:
                                        qState.currentQuestionIndex + 1,
                                    totalRounds:
                                        qState.session?.questions.length ?? 5,
                                    isDark: isDark,
                                  ),

                                  SizedBox(height: 10.h),

                                  // Discipline-Specific Hero Card with slide transition
                                  RepaintBoundary(
                                    child: AnimatedSwitcher(
                                      duration: VowlMotion.fast,
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.08, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey<int>(
                                          qState.currentQuestionIndex,
                                        ),
                                        child: _buildDisciplineHero(
                                          context: context,
                                          q: activeQ,
                                          state: qState,
                                          isDark: isDark,
                                          isMidnight: isMidnight,
                                          borderColor: borderColor,
                                          textPrimary: textPrimary,
                                          textSecondary: textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 14.h),

                                  // Interactive Options Section (2x2 Grid for Speed Clash vs Sleek Precision List)
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: shouldUseGrid
                                          ? GridView.builder(
                                              padding: EdgeInsets.zero,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: activeQ.options.length,
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    mainAxisSpacing: 10.h,
                                                    crossAxisSpacing: 10.w,
                                                    childAspectRatio: 2.2,
                                                  ),
                                              itemBuilder: (context, idx) {
                                                final option =
                                                    activeQ.options[idx];
                                                return ArenaGridOptionTile(
                                                  index: idx,
                                                  text: option,
                                                  isAnswered: qState.isAnswered,
                                                  selectedOption:
                                                      qState.selectedOption,
                                                  correctIndex:
                                                      activeQ.correctIndex,
                                                  isDark: isDark,
                                                  borderColor: borderColor,
                                                  textPrimary: textPrimary,
                                                  onTap: () => _handleAnswerTap(
                                                    idx,
                                                    activeQ,
                                                    qState,
                                                    user,
                                                  ),
                                                );
                                              },
                                            )
                                          : ListView.separated(
                                              padding: EdgeInsets.zero,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: activeQ.options.length,
                                              separatorBuilder: (_, _) =>
                                                  SizedBox(height: 10.h),
                                              itemBuilder: (context, idx) {
                                                final option =
                                                    activeQ.options[idx];
                                                return ArenaListOptionTile(
                                                  index: idx,
                                                  text: option,
                                                  isAnswered: qState.isAnswered,
                                                  selectedOption:
                                                      qState.selectedOption,
                                                  correctIndex:
                                                      activeQ.correctIndex,
                                                  isDark: isDark,
                                                  borderColor: borderColor,
                                                  textPrimary: textPrimary,
                                                  onTap: () => _handleAnswerTap(
                                                    idx,
                                                    activeQ,
                                                    qState,
                                                    user,
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),

                                  // Live Academic Explanation Card when answered
                                  if (qState.isAnswered &&
                                      activeQ.explanation.isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    RepaintBoundary(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.slate900
                                              : AppColors.slate100,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              LucideIcons.lightbulb,
                                              size: 15.sp,
                                              color: AppColors.amber500,
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                activeQ.explanation,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.35,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswerTap(
    int idx,
    ArenaQuestion q,
    ArenaDuelState state,
    UserEntity user,
  ) {
    if (state.isAnswered) return;
    final isCorrect = idx == q.correctIndex;
    if (isCorrect) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect(
          comboStep: state.currentQuestionIndex + 1,
        );
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
    }
    context.read<ArenaDuelCubit>().selectOption(idx, user);
  }

  // ==========================================
  // DISCIPLINE HERO BUILDERS
  // ==========================================

  Widget _buildDisciplineHero({
    required BuildContext context,
    required ArenaQuestion q,
    required ArenaDuelState state,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    switch (q.discipline) {
      case 'word_clash':
        return ArenaWordClashHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'phrase_duel':
        return ArenaPhraseDuelHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'sentence_strike':
        return ArenaSentenceStrikeHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'context_blitz':
      default:
        return ArenaContextBlitzHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
    }
  }

  void _confirmExit(BuildContext context) {
    final cubit = context.read<ArenaDuelCubit>();
    if (cubit.state.isCompleted) {
      context.read<AuthBloc>().add(const AuthReloadUser());
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      } else {
        GoRouter.of(context).go(AppRouter.gamesRoute);
      }
      return;
    }

    final isWaiting = cubit.state.isWaitingForGuest;

    ArenaQuitMatchDialog.show(
      context: context,
      isWaitingLobby: isWaiting,
      onForfeit: () async {
        final session = cubit.state.session;
        final authState = context.read<AuthBloc>().state;
        if (session != null && authState.user != null) {
          await di.sl<ArenaRepository>().forfeitMatch(
            roomCode: session.roomCode,
            userId: authState.user!.id,
          );
        }
        if (context.mounted) {
          context.read<AuthBloc>().add(const AuthReloadUser());
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          } else {
            GoRouter.of(context).go(AppRouter.gamesRoute);
          }
        }
      },
    );
  }

  Future<void> _triggerRematch(BuildContext context, dynamic user) async {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user ?? (user is UserEntity ? user : null);
    if (currentUser == null) return;

    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!context.mounted) return;

    if (currentUser.coins < 30) {
      ArenaRefuelHelper.showRefuelDialog(
        context: context,
        user: currentUser,
        onRefuelSuccess: () {
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthReloadUser());
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushReplacement(ArenaMatchmakingScreen.route(user: currentUser));
          }
        },
      );
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement(ArenaMatchmakingScreen.route(user: currentUser));
  }
}
