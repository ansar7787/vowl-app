import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
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

class _ArenaDuelView extends StatelessWidget {
  const _ArenaDuelView();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white),
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
      body: BlocConsumer<ArenaDuelCubit, ArenaDuelState>(
        listener: (context, state) {
          if (state.isCompleted) {
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
                onRematch: () {
                  Navigator.of(dialogCtx).pop();
                  if (authState.status == AuthStatus.authenticated && authState.user != null) {
                    _triggerRematch(context, authState.user!);
                  }
                },
                onClose: () {
                  Navigator.of(dialogCtx).pop();
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
            return _buildWaitingLobby(context, state, isDark, borderColor, textPrimary, textSecondary);
          }

          final q = state.currentQuestion;
          if (q == null) return const Center(child: CircularProgressIndicator());

          final rivalName = state.session?.guestId == user.id
              ? (state.session?.hostName ?? 'Host')
              : (state.session?.guestName ?? 'Challenger');
          final rivalPhoto = state.session?.guestId == user.id
              ? state.session?.hostPhotoUrl
              : state.session?.guestPhotoUrl;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                ),

                SizedBox(height: 16.h),

                // Question Box
                Builder(
                  builder: (_) {
                    final disciplineLabel = _getDisciplineLabel(q);
                    final disciplineColor = _getDisciplineColor(q);
                    return Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.midnightSurface : Colors.white,
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
                          if (di.sl.isRegistered<HapticService>()) {
                            di.sl<HapticService>().light();
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

  Widget _buildWaitingLobby(
    BuildContext context,
    ArenaDuelState state,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final code = state.session?.roomCode ?? 'VOWL-DUEL';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.swords, size: 28.sp, color: AppColors.indigo500),
            ),
            SizedBox(height: 16.h),
            Text(
              'Waiting for Opponent',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            SizedBox(height: 6.h),
            Text(
              'Share this room code with a friend to begin the 30-coin duel:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: textSecondary),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.indigo500,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Forfeit Duel?'),
        content: const Text('Leaving mid-match will forfeit your 30-coin stake.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Stay & Fight'),
          ),
          ElevatedButton(
            onPressed: () {
              final cubit = context.read<ArenaDuelCubit>();
              final session = cubit.state.session;
              final authState = context.read<AuthBloc>().state;
              if (session != null && authState.user != null) {
                di.sl<ArenaRepository>().forfeitMatch(
                  roomCode: session.roomCode,
                  userId: authState.user!.id,
                );
              }
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose500),
            child: const Text('Forfeit'),
          ),
        ],
      ),
    );
  }

  void _triggerRematch(BuildContext context, dynamic user) async {
    if (user.coins < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 30 coins for a rematch stake!'),
          backgroundColor: AppColors.rose500,
        ),
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
