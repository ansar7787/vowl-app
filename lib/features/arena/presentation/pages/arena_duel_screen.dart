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
                listener: (context, state) {
                  if (!state.isWaitingForGuest &&
                      !state.isCompleted &&
                      state.currentQuestion != null &&
                      !_hasTriggeredMatchFound) {
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
                    final isHost = authState.user?.id == state.session?.hostId;
                    final rivalName = isHost
                        ? (state.session?.guestName ?? 'Challenger')
                        : (state.session?.hostName ?? 'Host');
                    final rivalPhoto = isHost
                        ? state.session?.guestPhotoUrl
                        : state.session?.hostPhotoUrl;
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

                  final rivalName = state.session?.guestId == user.id
                      ? (state.session?.hostName ?? 'Host')
                      : (state.session?.guestName ?? 'Challenger');
                  final rivalPhoto = state.session?.guestId == user.id
                      ? state.session?.hostPhotoUrl
                      : state.session?.guestPhotoUrl;

                  // SUSPENSE STATE: Completed 5 rounds, waiting for rival to finish
                  if (state.isWaitingForOpponentFinish && !state.isCompleted) {
                    return _buildWaitingForOpponentView(
                      context: context,
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

                  final isWordClash = q.discipline == 'word_clash' ||
                      q.question.toLowerCase().contains('synonym') ||
                      q.question.toLowerCase().contains('antonym') ||
                      q.question.toLowerCase().contains('opposite');
                  final isShortOptions = q.options.every(
                    (opt) => opt.trim().length <= 14 && !opt.trim().contains(' '),
                  );
                  final shouldUseGrid = isWordClash && isShortOptions;

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

                        SizedBox(height: 14.h),

                        // Discipline-Specific Hero Card
                        _buildDisciplineHero(
                          context: context,
                          q: q,
                          state: state,
                          isDark: isDark,
                          isMidnight: isMidnight,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        SizedBox(height: 14.h),

                        // Interactive Options Section (2x2 Grid for Speed Clash vs Sleek Precision List)
                        Expanded(
                          child: shouldUseGrid
                              ? GridView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: q.options.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10.h,
                                    crossAxisSpacing: 10.w,
                                    childAspectRatio: 2.2,
                                  ),
                                  itemBuilder: (context, idx) {
                                    final option = q.options[idx];
                                    return _buildGridOptionButton(
                                      context: context,
                                      index: idx,
                                      text: option,
                                      state: state,
                                      correctIndex: q.correctIndex,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      textPrimary: textPrimary,
                                      onTap: () => _handleAnswerTap(idx, q, state, user),
                                    );
                                  },
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
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
                                      onTap: () => _handleAnswerTap(idx, q, state, user),
                                    );
                                  },
                                ),
                        ),

                        // Live Academic Explanation Card when answered
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

  void _handleAnswerTap(int idx, ArenaQuestion q, ArenaDuelState state, UserEntity user) {
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
    final disc = q.discipline;
    final lower = q.question.toLowerCase();

    if (disc == 'word_clash' ||
        lower.contains('synonym') ||
        lower.contains('antonym') ||
        lower.contains('opposite')) {
      return _buildWordClashHero(
        q: q,
        state: state,
        isDark: isDark,
        isMidnight: isMidnight,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    if (disc == 'phrase_duel' ||
        lower.contains('idiom') ||
        lower.contains('collocation') ||
        lower.contains('natural pair') ||
        lower.contains('particle') ||
        lower.contains('phrasal')) {
      return _buildPhraseDuelHero(
        q: q,
        state: state,
        isDark: isDark,
        isMidnight: isMidnight,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    if (disc == 'sentence_strike' ||
        lower.contains('academic') ||
        lower.contains('precision')) {
      return _buildSentenceStrikeHero(
        q: q,
        state: state,
        isDark: isDark,
        isMidnight: isMidnight,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    return _buildContextBlitzHero(
      q: q,
      state: state,
      isDark: isDark,
      isMidnight: isMidnight,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
  }

  /// 1. WORD CLASH ⚡: Instant Speed Target Card
  Widget _buildWordClashHero({
    required ArenaQuestion q,
    required ArenaDuelState state,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final lower = q.question.toLowerCase();
    final isAntonym = lower.contains('opposite') || lower.contains('antonym');
    final accentColor = isAntonym ? AppColors.amber500 : AppColors.indigo500;

    final quoteMatch = RegExp(r'"([^"]+)"').firstMatch(q.question);
    final targetWord = quoteMatch?.group(1);

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 11.sp, color: accentColor),
                    SizedBox(width: 5.w),
                    Text(
                      isAntonym ? 'WORD CLASH • ANTONYM' : 'WORD CLASH • SYNONYM',
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ],
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

          if (targetWord != null) ...[
            Text(
              isAntonym ? 'SELECT THE DIRECT OPPOSITE OF:' : 'SELECT THE CLOSEST SYNONYM TO:',
              softWrap: true,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                targetWord.toUpperCase(),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: accentColor,
                ),
              ),
            ),
          ] else ...[
            Text(
              q.question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. PHRASE DUEL 🎯: Collocation & Idiom Puzzle
  Widget _buildPhraseDuelHero({
    required ArenaQuestion q,
    required ArenaDuelState state,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final lower = q.question.toLowerCase();
    final isIdiom = lower.contains('idiom') || lower.contains('mean');
    final isPhrasal = lower.contains('phrasal') || lower.contains('particle');
    final accentColor = isIdiom
        ? const Color(0xFF06B6D4) // Cyan
        : (isPhrasal ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)); // Purple or Emerald

    final tagText = isIdiom
        ? 'PHRASE DUEL • IDIOM'
        : (isPhrasal ? 'PHRASE DUEL • PHRASAL VERB' : 'PHRASE DUEL • COLLOCATION');

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.target, size: 11.sp, color: accentColor),
                    SizedBox(width: 5.w),
                    Text(
                      tagText,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ],
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
            isIdiom
                ? 'DECIPHER THE FIGURATIVE EXPRESSION:'
                : 'FIT THE NATURAL COLLOCATING PHRASE:',
            softWrap: true,
            style: TextStyle(
              fontSize: 10.5.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. SENTENCE STRIKE 💥: Academic Register & Precision
  Widget _buildSentenceStrikeHero({
    required ArenaQuestion q,
    required ArenaDuelState state,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    const accentColor = Color(0xFFEC4899); // Pink
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.flame, size: 11.sp, color: accentColor),
                    SizedBox(width: 5.w),
                    Text(
                      'SENTENCE STRIKE • ACADEMIC',
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ],
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
            'SELECT THE PRECISE GRAMMATICAL & REGISTER FIT:',
            softWrap: true,
            style: TextStyle(
              fontSize: 10.5.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. CONTEXT BLITZ 🧠: Deductive Reasoning Dossier
  Widget _buildContextBlitzHero({
    required ArenaQuestion q,
    required ArenaDuelState state,
    required bool isDark,
    required bool isMidnight,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    const accentColor = Color(0xFF0EA5E9); // Sky Blue
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.brainCircuit, size: 11.sp, color: accentColor),
                    SizedBox(width: 5.w),
                    Text(
                      'CONTEXT BLITZ • INFERENCE',
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ],
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

          Row(
            children: [
              Icon(LucideIcons.search, size: 12.sp, color: accentColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'ANALYZE CONTEXT CLUES & INFER THE MISSING MEANING:',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.left,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPTIONS BUILDERS
  // ==========================================

  Widget _buildGridOptionButton({
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
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: btnBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  text,
                  softWrap: true,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: btnBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontFamily: 'Outfit',
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
                  softWrap: true,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Outfit',
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

  // ==========================================
  // SUSPENSE WAITING VIEW (Round 5 Complete)
  // ==========================================

  Widget _buildWaitingForOpponentView({
    required BuildContext context,
    required ArenaDuelState state,
    required UserEntity user,
    required String rivalName,
    required String? rivalPhoto,
    required bool isDark,
    required bool isMidnight,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.swords, size: 13.sp, color: AppColors.indigo500),
                  SizedBox(width: 6.w),
                  Text(
                    'PENTATHLON MATCH COMPLETE',
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.indigo500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'WAITING FOR RIVAL TO FINISH',
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'All 5 rounds submitted. Rival is concluding their match.',
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),

          SizedBox(height: 24.h),

          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isMidnight
                  ? AppColors.midnightSurface
                  : (isDark ? AppColors.slate800 : Colors.white),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // User Locked Side
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.indigo500, width: 2),
                              image: user.photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: AppColors.indigo500.withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: user.photoUrl == null
                                ? Text(
                                    user.safeDisplayName.isNotEmpty
                                        ? user.safeDisplayName[0].toUpperCase()
                                        : 'Y',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.indigo500,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            user.safeDisplayName,
                            softWrap: true,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.emerald500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'LOCKED: ${state.myScore} PTS',
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VS Divider
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.slate700 : AppColors.slate200),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Rival Side
                    Expanded(
                      child: Column(
                        children: [
                          if ((state.session?.isGhostRival == true) &&
                              (rivalPhoto == null || rivalPhoto.isEmpty))
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.bot,
                                  color: Colors.white,
                                  size: 26.r,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.rose500, width: 2),
                                image: rivalPhoto != null && rivalPhoto.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(rivalPhoto),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: AppColors.rose500.withValues(alpha: 0.15),
                              ),
                              alignment: Alignment.center,
                              child: rivalPhoto == null || rivalPhoto.isEmpty
                                  ? Text(
                                      rivalName.isNotEmpty
                                          ? rivalName[0].toUpperCase()
                                          : 'R',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.rose500,
                                      ),
                                    )
                                  : null,
                            ),
                          SizedBox(height: 8.h),
                          Text(
                            rivalName,
                            softWrap: true,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'RIVAL: ${state.rivalScore} PTS',
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amber500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // Modern Linear Indicator (Never 2019 Spinner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.indigo500),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Awaiting final round submission from rival...',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Zero-Tie Resolution Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.zap, size: 16.sp, color: AppColors.amber500),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero-Tie Speed Precision Active',
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'If total points match, the duel is decided by millisecond response speed. Every fraction of a second counts.',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.sp,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _triggerRematch(BuildContext context, dynamic user) {
    if (user is! UserEntity) return;

    if (user.coins < 30) {
      CustomSnackBar.show(
        context: context,
        message: 'You need at least 30 coins to enter a rematch!',
        type: CustomSnackBarType.warning,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      ArenaMatchmakingScreen.route(user: user),
    );
  }
}
