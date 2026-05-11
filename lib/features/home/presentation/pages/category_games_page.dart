import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class CategoryGamesPage extends StatefulWidget {
  const CategoryGamesPage({super.key, required this.categoryId});
  final String categoryId;

  @override
  State<CategoryGamesPage> createState() => _CategoryGamesPageState();
}

class _CategoryGamesPageState extends State<CategoryGamesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final games = _getGamesForCategory(widget.categoryId);
      CurriculumService.prewarmCache(games.map((g) => g.name).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: isDark,
      isMidnight: context.watch<ThemeCubit>().state.isMidnight,
    );
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white38 : const Color(0xFF4F46E5),
          ),
        ),
      );
    }

    final games = _getGamesForCategory(widget.categoryId);
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      body: Stack(
        children: [
          // 1. Immersive Mesh Background
          const MeshGradientBackground(showLetters: false),
          
          // 2. Dynamic Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spacer for the floating App Bar
              SliverToBoxAdapter(child: SizedBox(height: 130.h)),

              // 3. Mastery Dashboard Header
              SliverToBoxAdapter(
                child: _buildMasteryDashboard(theme, user, games, isDark),
              ),

              // 4. Game Grid/List
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 100.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 24.h),
                      child: _buildSpatialGameCard(
                        context,
                        user,
                        games[index],
                        isDark,
                        index,
                      ),
                    );
                  }, childCount: games.length),
                ),
              ),
            ],
          ),

          // 5. Floating Glass Island AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingGlassAppBar(context, theme, isDark, contentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassAppBar(BuildContext context, dynamic theme, bool isDark, Color contentColor) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 110.h,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 20.w, right: 20.w),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleButton(
                onTap: () => context.pop(),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: contentColor, size: 20.r),
                ),
              ),
              // Centered Glass Capsule
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(theme.icon, color: theme.primaryColor, size: 16.r),
                    SizedBox(width: 8.w),
                    Text(
                      widget.categoryId.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: contentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // User Progress/Stats Pill
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 20.r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasteryDashboard(dynamic theme, UserEntity user, List<GameSubtype> games, bool isDark) {
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);
    
    // Calculate Progress (200 levels per game)
    int clearedLevels = 0;
    for (var g in games) {
      clearedLevels += (user.unlockedLevels[g.name] ?? 1) - 1;
    }
    final totalLevels = games.length * 200;
    final progress = totalLevels > 0 ? (clearedLevels / totalLevels) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "OVERALL MASTERY",
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${(progress * 100).toStringAsFixed(progress < 0.01 && progress > 0 ? 2 : 1)}% COMPLETED",
                          style: GoogleFonts.outfit(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: contentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w), // Space buffer to prevent touching
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$clearedLevels/$totalLevels LVLS",
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Massive Liquid Progress
            _buildLiquidProgressBar(theme.primaryColor, clearedLevels + 1, total: totalLevels),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(child: _buildStatMini(Icons.bolt_rounded, "POWER", "${clearedLevels * 10} XP", theme.primaryColor, isDark)),
                Expanded(child: Center(child: _buildStatMini(Icons.sports_esports_rounded, "GAMES", "${games.length}", theme.primaryColor, isDark))),
                Expanded(child: Align(alignment: Alignment.centerRight, child: _buildStatMini(Icons.stars_rounded, "RANK", _getRank(progress), theme.primaryColor, isDark))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRank(double progress) {
    if (progress <= 0.0) return "BEGINNER";
    if (progress < 0.15) return "NOVICE";
    if (progress < 0.35) return "SCHOLAR";
    if (progress < 0.55) return "EXPERT";
    if (progress < 0.80) return "VIRTUOSO";
    if (progress < 0.99) return "GRANDMASTER";
    return "LEGENDARY";
  }

  Widget _buildStatMini(IconData icon, String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12.r),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpatialGameCard(BuildContext context, UserEntity user, GameSubtype subtype, bool isDark, int index) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final currentLevel = user.unlockedLevels[subtype.name] ?? 1;
    final isNew = !user.categoryStats.containsKey(subtype.name) && currentLevel == 1;
    final displayColor = isDark ? theme.primaryColor : HSLColor.fromColor(theme.primaryColor).withLightness(0.4).toColor();
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ScaleButton(
      onTap: () => context.push('${AppRouter.levelsRoute}?category=${widget.categoryId}&gameType=${subtype.name}'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Body
          GlassTile(
            borderRadius: BorderRadius.circular(32.r),
            padding: EdgeInsets.all(24.r),
            glassOpacity: 0.15, // Match shelf opacity
            showShadow: false, // Remove unwanted glow
            usePremiumStyle: true,
            child: Row(
              children: [
                // Spatial Icon Placeholder (The real icon floats above)
                SizedBox(width: 60.r),
                SizedBox(width: 20.w),
                // Game Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.title.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: contentColor,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Liquid Progress Bar
                      _buildLiquidProgressBar(displayColor, currentLevel),
                      SizedBox(height: 8.h),
                      Text(
                        "MISSION PROGRESS: ${((currentLevel - 1) / 200 * 100).toInt()}%",
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: displayColor.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Completion Badge
                _buildSpatialBadge(displayColor, currentLevel, isNew),
              ],
            ),
          ),
          
          // Floating Spatial Icon
          Positioned(
            left: 20.w,
            top: -15.h,
            child: Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [displayColor, displayColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: displayColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                GameHelper.getIconForSubtype(subtype),
                color: Colors.white,
                size: 32.r,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: 0, end: -5, duration: 2.seconds, curve: Curves.easeInOutQuad),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildLiquidProgressBar(Color color, int currentLevel, {int total = 200}) {
    final progress = ((currentLevel - 1) % total) / total.toDouble();
    return Container(
      height: 8.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.05, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
      ),
    );
  }

  Widget _buildSpatialBadge(Color color, int currentLevel, bool isNew) {
    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
        ),
        child: Text(
          "NEW",
          style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds);
    }

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "$currentLevel",
        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  List<GameSubtype> _getGamesForCategory(String category) {
    final List<GameSubtype> allGames = GameSubtype.values
        .where((s) => s.category.name == category && !s.isLegacy)
        .toList();

    final Map<String, List<GameSubtype>> journeyOrder = {
      'vocabulary': [
        GameSubtype.flashcards,
        GameSubtype.topicVocab,
        GameSubtype.wordFormation,
        GameSubtype.prefixSuffix,
        GameSubtype.synonymSearch,
        GameSubtype.antonymSearch,
        GameSubtype.contextClues,
        GameSubtype.collocations,
        GameSubtype.phrasalVerbs,
        GameSubtype.idioms,
        GameSubtype.academicWord,
        GameSubtype.contextualUsage,
      ],
      'grammar': [
        GameSubtype.partsOfSpeech,
        GameSubtype.grammarQuest,
        GameSubtype.wordReorder,
        GameSubtype.sentenceCorrection,
        GameSubtype.tenseMastery,
        GameSubtype.subjectVerbAgreement,
        GameSubtype.articleInsertion,
        GameSubtype.questionFormatter,
        GameSubtype.clauseConnector,
        GameSubtype.voiceSwap,
        GameSubtype.punctuationMastery,
        GameSubtype.modifierPlacement,
        GameSubtype.modalsSelection,
        GameSubtype.prepositionChoice,
        GameSubtype.pronounResolution,
        GameSubtype.relativeClauses,
        GameSubtype.conditionals,
        GameSubtype.conjunctions,
        GameSubtype.directIndirectSpeech,
      ],
      'listening': [
        GameSubtype.audioFillBlanks,
        GameSubtype.audioMultipleChoice,
        GameSubtype.audioSentenceOrder,
        GameSubtype.audioTrueFalse,
        GameSubtype.soundImageMatch,
        GameSubtype.detailSpotlight,
        GameSubtype.emotionRecognition,
        GameSubtype.fastSpeechDecoder,
        GameSubtype.listeningInference,
        GameSubtype.ambientId,
      ],
      'reading': [
        GameSubtype.readAndAnswer,
        GameSubtype.findWordMeaning,
        GameSubtype.trueFalseReading,
        GameSubtype.sentenceOrderReading,
        GameSubtype.guessTitle,
        GameSubtype.readAndMatch,
        GameSubtype.skimmingScanning,
        GameSubtype.paragraphSummary,
        GameSubtype.readingSpeedCheck,
        GameSubtype.readingInference,
        GameSubtype.readingConclusion,
        GameSubtype.clozeTest,
      ],
      'writing': [
        GameSubtype.sentenceBuilder,
        GameSubtype.completeSentence,
        GameSubtype.fixTheSentence,
        GameSubtype.describeSituationWriting,
        GameSubtype.summarizeStoryWriting,
        GameSubtype.shortAnswerWriting,
        GameSubtype.opinionWriting,
        GameSubtype.dailyJournal,
        GameSubtype.writingEmail,
        GameSubtype.correctionWriting,
        GameSubtype.essayDrafting,
      ],
      'speaking': [
        GameSubtype.repeatSentence,
        GameSubtype.speakMissingWord,
        GameSubtype.yesNoSpeaking,
        GameSubtype.pronunciationFocus,
        GameSubtype.speakSynonym,
        GameSubtype.speakOpposite,
        GameSubtype.dailyExpression,
        GameSubtype.situationSpeaking,
        GameSubtype.sceneDescriptionSpeaking,
        GameSubtype.dialogueRoleplay,
      ],
      'accent': [
        GameSubtype.minimalPairs,
        GameSubtype.vowelDistinction,
        GameSubtype.consonantClarity,
        GameSubtype.syllableStress,
        GameSubtype.wordLinking,
        GameSubtype.connectedSpeech,
        GameSubtype.intonationMimic,
        GameSubtype.pitchModulation,
        GameSubtype.pitchPatternMatch,
        GameSubtype.speedVariance,
        GameSubtype.shadowingChallenge,
        GameSubtype.dialectDrill,
      ],
      'roleplay': [
        GameSubtype.situationalResponse,
        GameSubtype.branchingDialogue,
        GameSubtype.socialSpark,
        GameSubtype.travelDesk,
        GameSubtype.gourmetOrder,
        GameSubtype.jobInterview,
        GameSubtype.medicalConsult,
        GameSubtype.conflictResolver,
        GameSubtype.elevatorPitch,
        GameSubtype.emergencyHub,
      ],
      'elitemastery': [
        GameSubtype.storyBuilder,
        GameSubtype.idiomMatch,
        GameSubtype.speedSpelling,
        GameSubtype.accentShadowing,
      ],
    };

    final order = journeyOrder[category];
    if (order != null) {
      allGames.sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    return allGames;
  }
}
