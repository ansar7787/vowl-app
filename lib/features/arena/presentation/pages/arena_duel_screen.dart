import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_result_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_score_hud.dart';

class ArenaDuelScreen extends StatelessWidget {
  final ArenaDuelSession initialSession;

  const ArenaDuelScreen({super.key, required this.initialSession});

  static Route<void> route({required ArenaDuelSession session}) {
    return MaterialPageRoute(
      builder: (_) => ArenaDuelScreen(initialSession: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ArenaDuelCubit(
          repository: di.sl<ArenaRepository>(),
        );
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated && authState.user != null) {
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

class _ArenaDuelViewState extends State<_ArenaDuelView> {
  StreamSubscription<AppNetworkStatus>? _networkSubscription;
  Timer? _countdownTimer;
  bool _isOffline = false;
  bool _hasTriggeredMatchFound = false;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _countdownTimer?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final backgroundColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : Colors.white);
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));
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
              Icon(LucideIcons.swords, size: 18.sp, color: const Color(0xFFF59E0B)),
              SizedBox(width: 8.w),
              Text(
                '1v1 Arena Duel',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: textPrimary),
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
                  color: const Color(0xFFF59E0B),
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
                    Icon(LucideIcons.wifiOff, size: 14.sp, color: Colors.black87),
                    SizedBox(width: 8.w),
                    Text(
                      'Reconnecting to Arena... Checking network connection',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocConsumer<ArenaDuelCubit, ArenaDuelState>(
                listener: (context, state) {
                  if (!state.isWaitingForGuest && !state.isCompleted && state.currentQuestion != null && !_hasTriggeredMatchFound) {
                    _hasTriggeredMatchFound = true;
                    if (di.sl.isRegistered<SoundService>()) {
                      di.sl<SoundService>().playArenaMatchFound();
                      _countdownTimer?.cancel();
                      _countdownTimer = Timer(const Duration(milliseconds: 380), () {
                        if (mounted && di.sl.isRegistered<SoundService>()) {
                          try {
                            di.sl<SoundService>().playArenaCountdown();
                          } catch (_) {}
                        }
                      });
                    }
                    if (di.sl.isRegistered<HapticService>()) {
                      di.sl<HapticService>().heavy();
                    }
                  }

                  if (state.timeRemaining == 3 && !state.isCompleted && !state.isWaitingForGuest) {
                    if (di.sl.isRegistered<HapticService>()) {
                      di.sl<HapticService>().warning();
                    }
                  }

                  if (state.isCompleted) {
                    if (di.sl.isRegistered<SoundService>()) {
                      if (state.isWinner) {
                        di.sl<SoundService>().playArenaVictory();
                      } else if (state.isDraw) {
                        di.sl<SoundService>().playLevelComplete();
                      } else {
                        di.sl<SoundService>().playArenaDefeat();
                      }
                    }

                    final authState = context.read<AuthBloc>().state;
                    final rivalName = state.session?.guestName ?? 'Rival';
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
                        rivalPhotoUrl: state.session?.guestPhotoUrl ?? state.session?.hostPhotoUrl,
                        myName: authState.user?.safeDisplayName ?? 'You',
                        myPhotoUrl: authState.user?.photoUrl,
                        payoutCoins: state.payoutCoins,
                        roomCode: state.session?.roomCode ?? '',
                        isAiRival: state.session?.isGhostRival ?? false,
                        onRematch: () {
                          Navigator.of(dialogCtx).pop();
                          if (authState.status == AuthStatus.authenticated && authState.user != null) {
                            _triggerRematch(context, authState.user!);
                          }
                        },
                        onClose: () {
                          Navigator.of(dialogCtx).pop();
                          context.read<AuthBloc>().add(const AuthReloadUser());
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final authState = context.watch<AuthBloc>().state;
                  final user = authState.status == AuthStatus.authenticated ? authState.user : null;
                  if (user == null) return const SizedBox.shrink();

                  if (state.isWaitingForGuest) {
                    return ArenaMatchingLoader(
                      roomCode: state.session?.roomCode,
                      showShareCode: true,
                    );
                  }

                  final q = state.currentQuestion;
                  if (q == null) {
                    return const ArenaMatchingLoader(
                      customMessage: 'Loading next vocabulary duel...',
                    );
                  }

          final rivalName = state.session?.guestId == user.id
              ? (state.session?.hostName ?? 'Host')
              : (state.session?.guestName ?? 'Challenger');
          final rivalPhoto = state.session?.guestId == user.id
              ? state.session?.hostPhotoUrl
              : state.session?.guestPhotoUrl;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: 12.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Score HUD
                ArenaScoreHud(
                  myName: user.safeDisplayName,
                  myPhotoUrl: user.photoUrl,
                  myScore: state.myScore,
                  rivalName: rivalName,
                  rivalPhotoUrl: rivalPhoto,
                  rivalScore: state.rivalScore,
                  currentQuestionIndex: state.currentQuestionIndex,
                  totalQuestions: state.session?.questions.length ?? 5,
                  timeRemaining: state.timeRemaining,
                  isDark: isDark,
                  isAiRival: state.session?.isGhostRival ?? false,
                ),

                SizedBox(height: 16.h),

                // Question Box
                Builder(
                  builder: (_) {
                    final disciplineLabel = _getDisciplineLabel(q);
                    final disciplineColor = _getDisciplineColor(q);
                    final isMidnight = isDark &&
                        Theme.of(context).scaffoldBackgroundColor == Colors.black;
                    return Container(
                      padding: EdgeInsets.all(AppSpacing.card),
                      decoration: BoxDecoration(
                        color: isMidnight
                            ? AppColors.midnightSurface
                            : (isDark ? AppColors.slate800 : Colors.white),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: disciplineColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    disciplineLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: disciplineColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'ROUND ${state.currentQuestionIndex + 1} OF ${state.session?.questions.length ?? 5}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            q.question,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 14.h),

                // Options List
                Expanded(
                  child: ListView.separated(
                    itemCount: q.options.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, idx) {
                      final option = q.options[idx];
                      return _buildOptionButton(
                        context: context,
                        index: idx,
                        text: option,
                        state: state,
                        correctIndex: q.correctIndex,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        onTap: () {
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
                        },
                      );
                    },
                  ),
                ),

                // Live Explanation Card when answered
                if (state.isAnswered && q.explanation.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.lightbulb, size: 15.sp, color: const Color(0xFFF59E0B)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            q.explanation,
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
                ],
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

  String _getDisciplineLabel(ArenaQuestion q) {
    final disc = q.discipline;
    final lower = q.question.toLowerCase();

    if (disc == 'word_clash' ||
        lower.contains('synonym') ||
        lower.contains('antonym') ||
        lower.contains('opposite')) {
      if (lower.contains('opposite') || lower.contains('antonym')) {
        return 'WORD CLASH • ANTONYM';
      }
      return 'WORD CLASH • SYNONYM';
    }

    if (disc == 'phrase_duel' ||
        lower.contains('idiom') ||
        lower.contains('collocation') ||
        lower.contains('natural pair') ||
        lower.contains('particle') ||
        lower.contains('phrasal')) {
      if (lower.contains('idiom')) return 'PHRASE DUEL • IDIOM';
      if (lower.contains('particle') || lower.contains('phrasal')) {
        return 'PHRASE DUEL • PHRASAL VERB';
      }
      return 'PHRASE DUEL • COLLOCATION';
    }

    if (disc == 'sentence_strike' ||
        lower.contains('academic') ||
        lower.contains('precision')) {
      return 'SENTENCE STRIKE • ACADEMIC';
    }

    return 'CONTEXT BLITZ • INFERENCE';
  }

  Color _getDisciplineColor(ArenaQuestion q) {
    final label = _getDisciplineLabel(q);
    if (label.contains('SYNONYM')) return AppColors.indigo500;
    if (label.contains('ANTONYM')) return const Color(0xFFF59E0B);
    if (label.contains('IDIOM')) return const Color(0xFF06B6D4);
    if (label.contains('COLLOCATION')) return const Color(0xFF10B981);
    if (label.contains('PHRASAL')) return const Color(0xFF8B5CF6);
    if (label.contains('SENTENCE STRIKE')) return const Color(0xFFEC4899);
    return const Color(0xFF0EA5E9);
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required int index,
    required String text,
    required ArenaDuelState state,
    required int correctIndex,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    Color btnBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    Color btnBorder = borderColor;
    Color txtColor = textPrimary;

    if (state.isAnswered) {
      if (index == correctIndex) {
        btnBg = AppColors.emerald500.withValues(alpha: 0.2);
        btnBorder = AppColors.emerald500;
        txtColor = isDark ? Colors.white : const Color(0xFF065F46);
      } else if (state.selectedOption == index) {
        btnBg = AppColors.rose500.withValues(alpha: 0.2);
        btnBorder = AppColors.rose500;
        txtColor = isDark ? Colors.white : AppColors.rose500;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: state.isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: btnBorder, width: 1.5.w),
          ),
          child: Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: txtColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    final cubit = context.read<ArenaDuelCubit>();
    if (cubit.state.isCompleted) {
      context.read<AuthBloc>().add(const AuthReloadUser());
      Navigator.of(context).pop();
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
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _triggerRematch(BuildContext context, dynamic user) async {
    if (user.coins < 30) {
      CustomSnackBar.show(
        context: context,
        message: 'You need at least 30 coins for a rematch stake!',
        type: CustomSnackBarType.warning,
      );
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final newSession = await repo.quickMatch(
        currentUser: user,
        leaderboardUsers: const [],
      );
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          ArenaDuelScreen.route(session: newSession),
        );
      }
    } catch (e) {
      debugPrint('[ArenaDuelScreen] Rematch error: $e');
    }
  }
}
