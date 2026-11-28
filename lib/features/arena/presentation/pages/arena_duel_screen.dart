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
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/arena/presentation/utils/arena_refuel_helper.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_rematch_overlay.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_result_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_round_strip.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_score_hud.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_waiting_view.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_mcq_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_rapid_judge_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_round_announce_card.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_sentence_build_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_speed_spell_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_spot_error_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_type_duel_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_word_snap_mechanic.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

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
      child: _ArenaDuelView(initialSession: initialSession),
    );
  }
}

class _ArenaDuelView extends StatefulWidget {
  final ArenaDuelSession initialSession;
  const _ArenaDuelView({required this.initialSession});

  @override
  State<_ArenaDuelView> createState() => _ArenaDuelViewState();
}

class _ArenaDuelViewState extends State<_ArenaDuelView>
    with WidgetsBindingObserver {
  StreamSubscription<AppNetworkStatus>? _networkSubscription;
  StreamSubscription<Map<String, dynamic>>? _rematchSubscription;
  Timer? _countdownTimer;
  Timer? _backgroundForfeitTimer;
  Timer? _announceTimer;
  bool _isOffline = false;
  bool _hasTriggeredMatchFound = false;
  bool _hasTriggeredFirstBlood = false;

  // Brief non-blocking round announce overlay tracker
  int _lastAnnouncedRound = -1;
  bool _showRoundAnnounce = false;

  // Live PvP rematch handshake state
  bool _waitingForRematchAccept = false;
  bool _isProcessingRematchNav = false;
  bool _isResultDialogOpen = false;
  String? _incomingRematchRequester;

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

    if (!widget.initialSession.isGhostRival &&
        di.sl.isRegistered<ArenaRepository>()) {
      _attachRematchListener(widget.initialSession.roomCode);
    }
  }

  void _attachRematchListener(String roomCode) {
    _rematchSubscription?.cancel();
    _rematchSubscription = di.sl<ArenaRepository>()
        .listenToRematchRequest(roomCode: roomCode)
        .listen((data) {
          if (!mounted || _isProcessingRematchNav) return;
          final authUser = context.read<AuthBloc>().state.user;
          if (authUser == null) return;

          final status = data['status'] as String?;
          final requesterId = data['requesterId'] as String?;
          final requesterName =
              data['requesterName'] as String? ?? 'Challenger';
          final newRoomCode = data['newRoomCode'] as String?;

          if (status == 'pending' &&
              requesterId != null &&
              requesterId != authUser.id) {
            setState(() {
              _incomingRematchRequester = requesterName;
            });
          } else if (status == 'accepted' &&
              newRoomCode != null &&
              newRoomCode.isNotEmpty) {
            setState(() {
              _incomingRematchRequester = null;
            });
            if (_waitingForRematchAccept) {
              _enterAcceptedRematch(newRoomCode, authUser);
            }
          } else if (status == 'declined') {
            final wasWaiting = _waitingForRematchAccept;
            setState(() {
              _incomingRematchRequester = null;
              _waitingForRematchAccept = false;
            });
            if (wasWaiting) {
              CustomSnackBar.show(
                context: context,
                message: context.tr(
                  'arena.rematch_declined',
                  fallback: 'Rival declined the rematch.',
                ),
                type: CustomSnackBarType.info,
              );
              final cubitState = context.read<ArenaDuelCubit>().state;
              if (cubitState.isCompleted && !_isResultDialogOpen) {
                _showResultDialog(context, cubitState);
              }
            }
          }
        });
  }

  Future<void> _enterAcceptedRematch(
    String newRoomCode,
    UserEntity user,
  ) async {
    if (_isProcessingRematchNav) return;
    _isProcessingRematchNav = true;
    try {
      final session = await di.sl<ArenaRepository>().enterAcceptedRematch(
        newRoomCode: newRoomCode,
        currentUser: user,
      );
      if (mounted) {
        context.read<AuthBloc>().add(const AuthReloadUser());
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacement(ArenaDuelScreen.route(session: session));
      }
    } catch (e) {
      _isProcessingRematchNav = false;
      if (mounted) {
        setState(() => _waitingForRematchAccept = false);
        CustomSnackBar.show(
          context: context,
          message: 'Could not join rematch room.',
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  Future<void> _acceptIncomingRematch(UserEntity user) async {
    if (_isProcessingRematchNav) return;
    if (user.coins < 30) {
      setState(() => _incomingRematchRequester = null);
      if (di.sl.isRegistered<ArenaRepository>()) {
        await di.sl<ArenaRepository>().declineRematch(
          roomCode: widget.initialSession.roomCode,
        );
      }
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Not enough coins (30🪙 required) for rematch.',
          type: CustomSnackBarType.warning,
        );
      }
      return;
    }

    _isProcessingRematchNav = true;
    setState(() => _incomingRematchRequester = null);

    try {
      final newSession = await di.sl<ArenaRepository>().acceptRematch(
        originalRoomCode: widget.initialSession.roomCode,
        currentUser: user,
      );
      if (mounted) {
        context.read<AuthBloc>().add(const AuthReloadUser());
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacement(ArenaDuelScreen.route(session: newSession));
      }
    } catch (e) {
      _isProcessingRematchNav = false;
      if (di.sl.isRegistered<ArenaRepository>()) {
        await di.sl<ArenaRepository>().declineRematch(
          roomCode: widget.initialSession.roomCode,
        );
      }
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Could not start rematch.',
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  void _cancelRematchWait(BuildContext context) {
    setState(() => _waitingForRematchAccept = false);
    if (di.sl.isRegistered<ArenaRepository>()) {
      di.sl<ArenaRepository>().declineRematch(
        roomCode: widget.initialSession.roomCode,
      );
    }
    final cubitState = context.read<ArenaDuelCubit>().state;
    if (cubitState.isCompleted && !_isResultDialogOpen) {
      _showResultDialog(context, cubitState);
    }
  }

  void _declineIncomingRematch() {
    setState(() => _incomingRematchRequester = null);
    if (di.sl.isRegistered<ArenaRepository>()) {
      di.sl<ArenaRepository>().declineRematch(
        roomCode: widget.initialSession.roomCode,
      );
    }
  }

  void _triggerRoundAnnounce(int roundIdx) {
    if (_lastAnnouncedRound == roundIdx) return;
    _lastAnnouncedRound = roundIdx;
    _announceTimer?.cancel();
    if (VowlMotion.lowAnimationModeOverride.value) return;

    setState(() => _showRoundAnnounce = true);
    _announceTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _showRoundAnnounce = false);
      }
    });
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
    _announceTimer?.cancel();
    _networkSubscription?.cancel();
    _rematchSubscription?.cancel();
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

    final authUser = context.watch<AuthBloc>().state.user;

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
        body: Stack(
          children: [
            Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
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
                if (_waitingForRematchAccept)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    color: AppColors.indigo500,
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.swords,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            context.tr(
                              'arena.waiting_rematch',
                              fallback: 'Waiting for rival to accept rematch...',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () => _cancelRematchWait(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            context.tr('arena.cancel', fallback: 'Cancel'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                        (prev.currentChallenge == null) !=
                            (curr.currentChallenge == null) ||
                        prev.currentChallenge?.mechanic !=
                            curr.currentChallenge?.mechanic ||
                        prev.session?.roomCode != curr.session?.roomCode ||
                        prev.session?.guestId != curr.session?.guestId ||
                        prev.isCompleted != curr.isCompleted,
                    listener: (context, state) {
                      if (!state.isWaitingForGuest &&
                          !state.isCompleted &&
                          state.currentChallenge != null) {
                        if (!_hasTriggeredMatchFound) {
                          _hasTriggeredMatchFound = true;
                          if (di.sl.isRegistered<SoundService>()) {
                            di.sl<SoundService>().playArenaMatchFound();
                            _countdownTimer?.cancel();
                            _countdownTimer = Timer(
                              const Duration(milliseconds: 380),
                              () {
                                if (mounted &&
                                    di.sl.isRegistered<SoundService>()) {
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
                        _triggerRoundAnnounce(state.currentQuestionIndex);
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

                      if (state.isCompleted && !_isResultDialogOpen) {
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

                        _showResultDialog(context, state);
                      }
                    },
                    builder: (context, state) {
                      final user = authUser;
                      if (user == null) return const SizedBox.shrink();

                      if (state.isWaitingForGuest) {
                        return ArenaMatchingLoader(
                          roomCode: state.session?.roomCode,
                          showShareCode: true,
                        );
                      }

                      final rivalName =
                          state.session?.opponentName(user.id) ?? 'Challenger';
                      final rivalPhoto = state.session?.opponentPhotoUrl(
                        user.id,
                      );

                      if (state.isWaitingForOpponentFinish &&
                          !state.isCompleted) {
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

                      final challenge = state.currentChallenge;
                      if (challenge == null) {
                        return const ArenaMatchingLoader(
                          customMessage: 'Loading next pentathlon round...',
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
                            // Live Score HUD
                            RepaintBoundary(
                              child: BlocBuilder<ArenaDuelCubit, ArenaDuelState>(
                                buildWhen: (prev, curr) =>
                                    prev.timeRemaining != curr.timeRemaining ||
                                    prev.myScore != curr.myScore ||
                                    prev.rivalScore != curr.rivalScore ||
                                    prev.currentQuestionIndex !=
                                        curr.currentQuestionIndex ||
                                    prev.isAnswered != curr.isAnswered ||
                                    prev.comboStreak != curr.comboStreak ||
                                    prev.currentChallenge?.mechanic !=
                                        curr.currentChallenge?.mechanic,
                                builder: (context, hudState) {
                                  final activeChal = hudState.currentChallenge;
                                  final mechanic =
                                      activeChal?.mechanic ??
                                      ArenaMechanicType.mcq;
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
                                        hudState.session?.challenges.length ??
                                        7,
                                    timeRemaining: hudState.timeRemaining,
                                    maxRoundSeconds: mechanic.timerSeconds,
                                    mechanic: mechanic,
                                    myDuelWins: user.duelWins,
                                    rivalDuelWins:
                                        hudState.session?.opponentDuelWins(
                                          user.id,
                                        ) ??
                                        0,
                                    isAnswered: hudState.isAnswered,
                                    isDark: isDark,
                                    isAiRival:
                                        hudState.session?.isGhostRival ?? false,
                                    aiTierLabel: () {
                                      final session = hudState.session;
                                      if (session == null ||
                                          !session.isGhostRival) {
                                        return null;
                                      }
                                      final gid =
                                          session.guestId?.toLowerCase() ?? '';
                                      if (gid.contains('hard')) return 'HARD';
                                      if (gid.contains('medium') ||
                                          gid.contains('med')) {
                                        return 'MED';
                                      }
                                      if (gid.contains('easy')) return 'EASY';
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

                            // Active Round Strip + Mechanic Dispatch
                            Expanded(
                              child: BlocBuilder<ArenaDuelCubit, ArenaDuelState>(
                                buildWhen: (prev, curr) =>
                                    prev.currentQuestionIndex !=
                                        curr.currentQuestionIndex ||
                                    prev.isAnswered != curr.isAnswered ||
                                    prev.selectedOption !=
                                        curr.selectedOption ||
                                    prev.currentChallenge !=
                                        curr.currentChallenge ||
                                    prev.rivalCharactersTyped !=
                                        curr.rivalCharactersTyped ||
                                    prev.rapidCurrentItemIndex !=
                                        curr.rapidCurrentItemIndex ||
                                    prev.rapidMyCorrectItems !=
                                        curr.rapidMyCorrectItems,
                                builder: (context, roundState) {
                                  final activeChal =
                                      roundState.currentChallenge;
                                  if (activeChal == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final totalRounds =
                                      roundState.session?.challenges.length ??
                                      7;

                                  return Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ArenaRoundStrip(
                                            challenge: activeChal,
                                            currentRound:
                                                roundState.currentQuestionIndex +
                                                1,
                                            totalRounds: totalRounds,
                                            isDark: isDark,
                                          ),
                                          SizedBox(height: 10.h),
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: VowlMotion.fast,
                                              switchInCurve: Curves.easeOut,
                                              switchOutCurve: Curves.easeIn,
                                              child: KeyedSubtree(
                                                key: ValueKey<int>(
                                                  roundState
                                                      .currentQuestionIndex,
                                                ),
                                                child: _buildRoundWidget(
                                                  challenge: activeChal,
                                                  state: roundState,
                                                  user: user,
                                                  isDark: isDark,
                                                  isMidnight: isMidnight,
                                                  borderColor: borderColor,
                                                  textPrimary: textPrimary,
                                                  textSecondary: textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_showRoundAnnounce &&
                                          !roundState.isAnswered)
                                        Positioned.fill(
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: () => setState(
                                              () => _showRoundAnnounce = false,
                                            ),
                                            child: IgnorePointer(
                                              child: ArenaRoundAnnounceCard(
                                                roundNumber:
                                                    roundState
                                                        .currentQuestionIndex +
                                                    1,
                                                totalRounds: totalRounds,
                                                mechanic: activeChal.mechanic,
                                                isDark: isDark,
                                                isMidnight: isMidnight,
                                              ),
                                            ),
                                          ),
                                        ),
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

            // Incoming PvP Rematch Request Overlay
            if (_incomingRematchRequester != null && authUser != null)
              Positioned.fill(
                child: ArenaRematchOverlay(
                  requesterName: _incomingRematchRequester!,
                  onAccept: () => _acceptIncomingRematch(authUser),
                  onDecline: _declineIncomingRematch,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundWidget({
    required ArenaChallenge challenge,
    required ArenaDuelState state,
    required UserEntity user,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final cubit = context.read<ArenaDuelCubit>();

    switch (challenge.mechanic) {
      case ArenaMechanicType.wordSnap:
        return ArenaWordSnapMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onSubmitWord: (spelled) => cubit.submitWordSnap(spelled, user),
        );

      case ArenaMechanicType.typeDuel:
        return ArenaTypeDuelMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTextChanged: (text) => cubit.onTypeDuelTextChanged(text, user),
          onSubmitWord: (typed) => cubit.submitTypeDuel(typed, user),
        );

      case ArenaMechanicType.rapidJudge:
        return ArenaRapidJudgeMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onJudgeItem: (idx, judgedCorrect) =>
              cubit.submitRapidJudgment(idx, judgedCorrect, user),
        );

      case ArenaMechanicType.sentenceBuild:
        return ArenaSentenceBuildMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onSubmitSentence: (words) => cubit.submitSentenceBuild(words, user),
        );

      case ArenaMechanicType.spotError:
        return ArenaSpotErrorMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTapToken: (idx) => cubit.submitSpotError(idx, user),
        );

      case ArenaMechanicType.speedSpell:
        return ArenaSpeedSpellMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onDraftChanged: (draft) => cubit.onSpeedSpellDraftChanged(draft),
          onSubmitLetters: (filled) => cubit.submitSpeedSpell(filled, user),
        );

      case ArenaMechanicType.mcq:
      case ArenaMechanicType.voiceDuel:
        return ArenaMcqMechanic(
          challenge: challenge,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onSelectOption: (idx) => cubit.selectOption(idx, user),
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

  void _showResultDialog(BuildContext context, ArenaDuelState state) {
    if (_isResultDialogOpen || !mounted) return;
    _isResultDialogOpen = true;

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    final session = state.session;
    final rivalName = session?.opponentName(currentUserId) ?? 'Challenger';
    final rivalPhoto = session?.opponentPhotoUrl(currentUserId);
    final myName =
        session?.myName(currentUserId) ??
        (authState.user?.safeDisplayName ?? 'You');
    final myPhoto =
        session?.myPhotoUrl(currentUserId) ?? authState.user?.photoUrl;
    final totalRounds = session?.challenges.length ?? 7;

    showDialog<void>(
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
        roomCode: session?.roomCode ?? '',
        isAiRival: session?.isGhostRival ?? false,
        totalRounds: totalRounds,
        myDuelWins: authState.user?.duelWins ?? 0,
        rivalDuelWins: session?.opponentDuelWins(currentUserId) ?? 0,
        roundResults: state.roundResults,
        onRematch: () {
          if (authState.status == AuthStatus.authenticated &&
              authState.user != null) {
            _triggerRematch(context, authState.user!, session, dialogCtx);
          }
        },
        onClose: () {
          _isResultDialogOpen = false;
          Navigator.of(dialogCtx).pop();
          context.read<AuthBloc>().add(const AuthReloadUser());
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          } else {
            GoRouter.of(context).go(AppRouter.gamesRoute);
          }
        },
      ),
    ).whenComplete(() {
      _isResultDialogOpen = false;
    });
  }

  Future<void> _triggerRematch(
    BuildContext context,
    UserEntity user,
    ArenaDuelSession? completedSession,
    BuildContext dialogCtx,
  ) async {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user ?? user;

    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!context.mounted) return;

    if (currentUser.coins < 30) {
      ArenaRefuelHelper.showRefuelDialog(
        context: context,
        user: currentUser,
        onRefuelSuccess: () {
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthReloadUser());
            _triggerRematch(context, currentUser, completedSession, dialogCtx);
          }
        },
      );
      return;
    }

    if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
      Navigator.of(dialogCtx).pop();
      _isResultDialogOpen = false;
    }

    // Ghost AI rematch: instant launch with same AI tier & new challenges
    if (completedSession != null && completedSession.isGhostRival) {
      try {
        final repo = di.sl<ArenaRepository>();
        final oppId = completedSession.guestId ?? 'computer_medium';
        final oppName = completedSession.opponentName(currentUser.id);
        final oppPhoto = completedSession.opponentPhotoUrl(currentUser.id);
        final oppWins = completedSession.opponentDuelWins(currentUser.id);
        final newSession = await repo.rematchGhostAi(
          currentUser: currentUser,
          previousGuestId: oppId,
          previousGuestName: oppName,
          previousGuestPhotoUrl: oppPhoto,
          previousAccuracy: completedSession.ghostAccuracy,
          previousOpponentDuelWins: oppWins,
        );
        if (context.mounted) {
          context.read<AuthBloc>().add(const AuthReloadUser());
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacement(ArenaDuelScreen.route(session: newSession));
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Could not start AI rematch.',
            type: CustomSnackBarType.error,
          );
          _showResultDialog(context, context.read<ArenaDuelCubit>().state);
        }
      }
      return;
    }

    // Live PvP rematch handshake
    if (completedSession != null && !completedSession.isGhostRival) {
      setState(() => _waitingForRematchAccept = true);
      try {
        await di.sl<ArenaRepository>().sendRematchRequest(
          roomCode: completedSession.roomCode,
          requesterId: currentUser.id,
          requesterName: currentUser.safeDisplayName,
        );
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            message:
                '⚔️ ${context.tr('arena.rematch_sent', fallback: 'Rematch request sent to rival!')}',
            type: CustomSnackBarType.info,
          );
        }
      } catch (e) {
        if (context.mounted) {
          setState(() => _waitingForRematchAccept = false);
          CustomSnackBar.show(
            context: context,
            message: 'Failed to send rematch request.',
            type: CustomSnackBarType.error,
          );
          _showResultDialog(context, context.read<ArenaDuelCubit>().state);
        }
      }
    }
  }
}
