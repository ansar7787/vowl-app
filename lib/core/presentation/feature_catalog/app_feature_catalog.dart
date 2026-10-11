import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';

/// Categories grouping the entire Vowl application ecosystem.
enum FeatureCategory {
  games('100+ Games', LucideIcons.gamepad2, AppColors.indigo500),
  aiTools('AI & Vision', LucideIcons.sparkles, AppColors.blue500),
  analytics('Reports & Errors', LucideIcons.barChart2, AppColors.emerald500),
  gaming('Boutique & Rank', LucideIcons.trophy, AppColors.amber500),
  kids('Kids World', LucideIcons.baby, AppColors.rose500),
  voice('Accents & Speech', LucideIcons.mic, AppColors.violet500);

  final String label;
  final IconData icon;
  final Color color;

  const FeatureCategory(this.label, this.icon, this.color);
}

/// Metadata model describing a single discoverable feature in Vowl.
class AppFeatureItem {
  final String id;
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color accentColor;
  final FeatureCategory category;
  final String route;
  final bool isHighlight;

  const AppFeatureItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.category,
    required this.route,
    this.badge,
    this.isHighlight = false,
  });
}

/// Central registry indexing every feature, tool, and game across the entire app.
class AppFeatureCatalog {
  AppFeatureCatalog._();

  static const List<AppFeatureItem> allFeatures = [
    // ── 1. 100+ Games across 9 Adult Pillars ────────────────────────────────
    AppFeatureItem(
      id: 'games_hub',
      title: '100+ Games Hub',
      subtitle: 'Complete curriculum across 9 skill pillars with level maps',
      badge: '100+ Games',
      icon: LucideIcons.layers,
      accentColor: AppColors.indigo500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'speaking_pillar',
      title: 'Speaking & Speech Recognition',
      subtitle: '10 speaking games with live microphone scoring & karaoke',
      badge: 'Mic AI',
      icon: LucideIcons.mic,
      accentColor: AppColors.indigo500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'listening_pillar',
      title: 'Listening Comprehension',
      subtitle: '10 auditory games: fast speech decoder & ambient recognition',
      badge: 'Ear Training',
      icon: LucideIcons.headphones,
      accentColor: AppColors.blue500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'reading_pillar',
      title: 'Reading Mastery',
      subtitle: '12 reading challenges: speed check, cloze tests & inference',
      badge: 'Speed Reading',
      icon: LucideIcons.bookOpen,
      accentColor: AppColors.emerald500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'writing_pillar',
      title: 'Writing & Daily Journal',
      subtitle: '11 creative games: fix sentence, story summary & email drafting',
      badge: 'Composition',
      icon: LucideIcons.penTool,
      accentColor: AppColors.amber500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'grammar_pillar',
      title: 'Grammar Precision',
      subtitle: '19 grammar quests: tenses, sentence correction & conditionals',
      badge: '19 Quests',
      icon: LucideIcons.checkSquare,
      accentColor: AppColors.violet500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'vocabulary_pillar',
      title: 'Vocabulary & 3D Flashcards',
      subtitle: '12 vocab quests: affixes, idioms, collocations & word building',
      badge: 'Flashcards',
      icon: LucideIcons.bookmark,
      accentColor: AppColors.rose500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'accent_pillar',
      title: 'Accent & Intonation Training',
      subtitle: '12 phonology drills: minimal pairs, syllable stress & shadowing',
      badge: 'Phonics',
      icon: LucideIcons.volume2,
      accentColor: AppColors.indigo500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),
    AppFeatureItem(
      id: 'roleplay_pillar',
      title: 'Real-Life Roleplay',
      subtitle: '10 conversational simulations: job interview, travel & dining',
      badge: 'Conversations',
      icon: LucideIcons.users,
      accentColor: AppColors.teal500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'quest_library',
      title: 'Quest Library',
      subtitle: 'Explore the complete syllabus catalog and themed quests',
      badge: 'Full Catalog',
      icon: LucideIcons.compass,
      accentColor: AppColors.blue500,
      category: FeatureCategory.games,
      route: AppRouter.libraryRoute,
    ),
    AppFeatureItem(
      id: 'elite_mastery',
      title: 'Elite Mastery (Advanced Quests)',
      subtitle: 'Accent shadowing, idiom match, speed spelling & story builder',
      badge: 'Elite Tier',
      icon: LucideIcons.crown,
      accentColor: AppColors.amber500,
      category: FeatureCategory.games,
      route: AppRouter.gamesRoute,
    ),

    // ── 2. AI Vision & Global Tools ─────────────────────────────────────────
    AppFeatureItem(
      id: 'photo_vocab',
      title: 'Photo Vocab',
      subtitle: 'Point your camera at any object to identify and learn words in real time',
      badge: 'Camera AI',
      icon: LucideIcons.camera,
      accentColor: AppColors.blue500,
      category: FeatureCategory.aiTools,
      route: AppRouter.photoVocabularyRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'scan_and_learn',
      title: 'Scan & Learn',
      subtitle: 'OCR scanner to extract and learn English from book pages & documents',
      badge: 'OCR Scanner',
      icon: LucideIcons.scanLine,
      accentColor: AppColors.teal500,
      category: FeatureCategory.aiTools,
      route: AppRouter.scanAndLearnRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'offline_translate',
      title: '50+ Languages Offline Translator',
      subtitle: 'On-device neural translation without needing an internet connection',
      badge: '50+ Offline',
      icon: LucideIcons.languages,
      accentColor: AppColors.emerald500,
      category: FeatureCategory.aiTools,
      route: AppRouter.translateRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'daily_words',
      title: 'Daily Words',
      subtitle: 'Curated vocabulary of the day with audio pronunciation & examples',
      badge: 'Curated Daily',
      icon: LucideIcons.calendar,
      accentColor: AppColors.amber500,
      category: FeatureCategory.aiTools,
      route: AppRouter.dailyWordsRoute,
    ),
    AppFeatureItem(
      id: 'word_snap',
      title: 'Word Snap',
      subtitle: 'High-speed memory match challenge pairing words and definitions',
      badge: 'Brain Game',
      icon: LucideIcons.zap,
      accentColor: AppColors.rose500,
      category: FeatureCategory.aiTools,
      route: AppRouter.wordSnapRoute,
    ),
    AppFeatureItem(
      id: 'word_mixer',
      title: 'Word Mixer',
      subtitle: 'Anagram puzzle assembling scrambled letters against the clock',
      badge: 'Speed Puzzle',
      icon: LucideIcons.shuffle,
      accentColor: AppColors.violet500,
      category: FeatureCategory.aiTools,
      route: AppRouter.wordMixerRoute,
    ),

    // ── 3. Growth, Reports & Error Journal ──────────────────────────────────
    AppFeatureItem(
      id: 'learning_report',
      title: 'Learning Report & Analytics',
      subtitle: 'Comprehensive progress dashboard tracking accuracy & study time',
      badge: 'Analytics',
      icon: LucideIcons.barChart2,
      accentColor: AppColors.emerald500,
      category: FeatureCategory.analytics,
      route: AppRouter.progressDashboardRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'review_mistakes',
      title: 'Review & Master (Error Journal)',
      subtitle: 'Spaced repetition replay hub for questions missed in previous lessons',
      badge: 'Error Journal',
      icon: LucideIcons.rotateCcw,
      accentColor: AppColors.amber500,
      category: FeatureCategory.analytics,
      route: AppRouter.reviewMistakesRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'streak_hub',
      title: 'Daily Streak & Motivation',
      subtitle: 'Daily streak tracker, weekly motivation audio & streak freeze',
      badge: 'Streak Shield',
      icon: LucideIcons.flame,
      accentColor: AppColors.rose500,
      category: FeatureCategory.analytics,
      route: AppRouter.streakRoute,
    ),

    // ── 4. Mascot, Boutique & Leaderboards ──────────────────────────────────
    AppFeatureItem(
      id: 'buddy_boutique',
      title: 'Buddy Boutique & Mascot Hub',
      subtitle: 'Customize your mascot companion with outfits, hats, glasses & skins',
      badge: 'Outfits & Pet',
      icon: LucideIcons.sparkles,
      accentColor: AppColors.amber500,
      category: FeatureCategory.gaming,
      route: AppRouter.vowlMascotRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'leaderboard',
      title: 'Global & League Leaderboard',
      subtitle: 'Weekly competitive tiers with global player rankings and rewards',
      badge: 'Leagues',
      icon: LucideIcons.trophy,
      accentColor: AppColors.amber600,
      category: FeatureCategory.gaming,
      route: AppRouter.leaderboardRoute,
    ),
    AppFeatureItem(
      id: 'hall_of_fame',
      title: 'Hall of Fame & Badges',
      subtitle: 'Showcase of earned achievement badges, medals, and mastery milestones',
      badge: 'Trophy Room',
      icon: LucideIcons.award,
      accentColor: AppColors.violet500,
      category: FeatureCategory.gaming,
      route: AppRouter.profileRoute,
    ),

    // ── 5. Kids Zone & Kids Room ────────────────────────────────────────────
    AppFeatureItem(
      id: 'kids_zone',
      title: 'Kids Zone (25 Games)',
      subtitle: 'Playful curriculum with 18 topics: animals, phonics, numbers & routine',
      badge: '25 Games',
      icon: LucideIcons.baby,
      accentColor: AppColors.rose500,
      category: FeatureCategory.kids,
      route: AppRouter.kidsZoneRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'kids_handwriting',
      title: 'Finger Handwriting & Tracing',
      subtitle: 'Interactive letter, shape, and number tracing with stroke guidance',
      badge: 'Tracing',
      icon: LucideIcons.penTool,
      accentColor: AppColors.teal500,
      category: FeatureCategory.kids,
      route: AppRouter.kidsHandwritingRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'kids_room',
      title: 'Kids Room & Pet Care',
      subtitle: 'Mascot bedroom with furniture decor, food feeding, and room themes',
      badge: 'Interactive Room',
      icon: LucideIcons.home,
      accentColor: AppColors.violet500,
      category: FeatureCategory.kids,
      route: AppRouter.kidsRoomRoute,
      isHighlight: true,
    ),
    AppFeatureItem(
      id: 'kids_stickers',
      title: '100-Sticker Collector Book',
      subtitle: '100 collectible stickers unlocked by mastering Kids Zone games',
      badge: '100 Stickers',
      icon: LucideIcons.smile,
      accentColor: AppColors.amber500,
      category: FeatureCategory.kids,
      route: AppRouter.kidsStickerBookRoute,
    ),
    AppFeatureItem(
      id: 'kids_boutique',
      title: 'Kids Boutique',
      subtitle: 'Fun child-friendly accessories, capes, and hats for the pet',
      badge: 'Costumes',
      icon: LucideIcons.shoppingBag,
      accentColor: AppColors.rose500,
      category: FeatureCategory.kids,
      route: AppRouter.kidsBuddyBoutiqueRoute,
    ),

    // ── 6. Accents & Speech Settings ────────────────────────────────────────
    AppFeatureItem(
      id: 'voice_accents',
      title: '6 World Accent Presets',
      subtitle: 'British (IELTS), American, Australian, & Indian neural on-device voices',
      badge: '6 Accents',
      icon: LucideIcons.globe,
      accentColor: AppColors.violet500,
      category: FeatureCategory.voice,
      route: AppRouter.settingsRoute,
      isHighlight: true,
    ),
  ];
}

