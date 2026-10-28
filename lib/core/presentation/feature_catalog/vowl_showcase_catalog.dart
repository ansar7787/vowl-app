import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Single bullet highlight for a showcase slide.
class ShowcaseHighlight {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  const ShowcaseHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });
}

/// Slide configuration for onboarding and feature discovery tours.
class ShowcaseSlide {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final String heroTag;
  final List<Color> gradientColors;
  final Color accentColor;
  final List<ShowcaseHighlight> highlights;

  const ShowcaseSlide({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.heroTag,
    required this.gradientColors,
    required this.accentColor,
    required this.highlights,
  });
}

/// Central catalog of showcase slides shared between the Full-Screen Onboarding Page
/// and the in-app Feature Directory bottom sheet tour.
abstract final class VowlShowcaseCatalog {
  VowlShowcaseCatalog._();

  static const List<ShowcaseSlide> slides = [
    // ── Slide 1: Speech & Games ─────────────────────────────────────────────
    ShowcaseSlide(
      title: '100+ Games Across 9 Pillars',
      subtitle:
          'Practice speaking, master daily grammar, and build real-world conversation confidence.',
      heroIcon: LucideIcons.gamepad2,
      heroTag: '9 LEARNING PILLARS',
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      accentColor: AppColors.indigo500,
      highlights: [
        ShowcaseHighlight(
          icon: LucideIcons.mic,
          title: 'Live Speech Practice',
          subtitle:
              'Instant pronunciation guidance to help you speak clearly and naturally',
          tint: Color(0xFF6366F1),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.sparkles,
          title: '19 Grammar Practice Games',
          subtitle: 'Master verb tenses, sentence puzzles, and vocabulary',
          tint: Color(0xFF8B5CF6),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.messageSquare,
          title: 'Everyday Conversations',
          subtitle:
              'Interactive dialogues for travel, dining, and daily situations',
          tint: Color(0xFFA855F7),
        ),
      ],
    ),

    // ── Slide 2: AI Vision & Camera ─────────────────────────────────────────
    ShowcaseSlide(
      title: 'AI Vision & 50+ Languages',
      subtitle:
          'Point your camera at real-world objects or book pages, and translate offline anytime.',
      heroIcon: LucideIcons.camera,
      heroTag: 'CAMERA & OFFLINE TOOLS',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      accentColor: AppColors.blue500,
      highlights: [
        ShowcaseHighlight(
          icon: LucideIcons.camera,
          title: 'Photo Vocabulary',
          subtitle:
              'Scan everyday objects to learn their English names instantly',
          tint: Color(0xFF0EA5E9),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.scan,
          title: 'Scan & Learn',
          subtitle:
              'Turn book pages and printed text into interactive study lists',
          tint: Color(0xFF2563EB),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.languages,
          title: '50+ Languages Offline',
          subtitle:
              'Translate words and full sentences without needing internet',
          tint: Color(0xFF06B6D4),
        ),
      ],
    ),

    // ── Slide 3: Buddy & Rewards ───────────────────────────────────────────
    ShowcaseSlide(
      title: 'Buddy Boutique & Kids World',
      subtitle:
          'Dress up your companion mascot, care for your pet, and collect milestone stickers as you learn.',
      heroIcon: LucideIcons.sparkles,
      heroTag: 'MASCOT & REWARDS',
      gradientColors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
      accentColor: AppColors.rose500,
      highlights: [
        ShowcaseHighlight(
          icon: LucideIcons.shirt,
          title: 'Buddy Boutique',
          subtitle:
              'Unlock cute outfits, hats, glasses, and accessories for your buddy',
          tint: Color(0xFFF43F5E),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.penTool,
          title: '100-Sticker Album',
          subtitle: 'Learn letter handwriting and collect milestone stickers',
          tint: Color(0xFFF59E0B),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.baby,
          title: 'Safe Kids Zone',
          subtitle:
              'Gentle phonics games, pet care, and fun beginner activities',
          tint: Color(0xFFFB923C),
        ),
      ],
    ),

    // ── Slide 4: Progress & Accents ─────────────────────────────────────────
    ShowcaseSlide(
      title: 'Reports, Accents & Error Journal',
      subtitle:
          'Track your weekly progress, review past mistakes at your own pace, and tune your ear to global accents.',
      heroIcon: LucideIcons.barChart2,
      heroTag: 'PROGRESS & ACCENTS',
      gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
      accentColor: AppColors.emerald500,
      highlights: [
        ShowcaseHighlight(
          icon: LucideIcons.barChart2,
          title: 'Weekly Learning Reports',
          subtitle:
              'Clear charts showing your daily accuracy, streak, and study time',
          tint: Color(0xFF10B981),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.refreshCw,
          title: 'Review Mistake Journal',
          subtitle:
              'Replay and practice words and questions you missed earlier',
          tint: Color(0xFF14B8A6),
        ),
        ShowcaseHighlight(
          icon: LucideIcons.globe,
          title: '6 World Accents',
          subtitle:
              'Practice listening to American, British, Australian, and Indian voices',
          tint: Color(0xFF059669),
        ),
      ],
    ),
  ];
}

