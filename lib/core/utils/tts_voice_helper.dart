import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Available human-like voice presets for speech synthesis across the application.
enum TtsVoicePreset {
  friendlyTeacher(
    'friendly_teacher',
    'Friendly Teacher',
    'Warm, cheerful & encouraging (recommended for Kids & Phonics)',
    Icons.school_rounded,
    isPremium: false,
  ),
  clearGuide(
    'clear_guide',
    'Clear Guide',
    'Natural, crisp American pronunciation for clear learning',
    Icons.record_voice_over_rounded,
    isPremium: false,
  ),
  britishAccent(
    'british_accent',
    'British Accent',
    'Refined UK English for IELTS & international study',
    Icons.travel_explore_rounded,
    isPremium: true,
  ),
  australianAccent(
    'australian_accent',
    'Australian Accent',
    'Natural Aussie English pronunciation for global mastery',
    Icons.terrain_rounded,
    isPremium: true,
  ),
  indianEnglish(
    'indian_english',
    'Indian English',
    'Clear South Asian English pronunciation & intonation',
    Icons.translate_rounded,
    isPremium: true,
  ),
  systemDefault(
    'system_default',
    'Device Default',
    'Use device system accessibility voice engine',
    Icons.settings_voice_rounded,
    isPremium: false,
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPremium;

  const TtsVoicePreset(
    this.id,
    this.title,
    this.subtitle,
    this.icon, {
    this.isPremium = false,
  });

  static TtsVoicePreset fromId(String? id) {
    return TtsVoicePreset.values.firstWhere(
      (e) => e.id == id,
      orElse: () => TtsVoicePreset.clearGuide,
    );
  }
}

/// Centralized utility managing high-fidelity voice resolution, engine calibration,
/// and user preference persistence across both Kids Zone and general learning modules.
class TtsVoiceHelper {
  TtsVoiceHelper._();

  static const String prefsKeyVoicePreset = 'tts_voice_preset';

  /// Retrieves the saved voice preset or defaults to [TtsVoicePreset.clearGuide].
  static Future<TtsVoicePreset> getSavedPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(prefsKeyVoicePreset);
      final preset = TtsVoicePreset.fromId(id);

      // If the saved preset is premium, verify active entitlement
      if (preset.isPremium) {
        try {
          if (di.sl.isRegistered<AuthBloc>()) {
            final authState = di.sl<AuthBloc>().state;
            if (authState.status == AuthStatus.authenticated &&
                !(authState.user?.isPremium ?? false)) {
              return TtsVoicePreset.clearGuide;
            }
            if (authState.status == AuthStatus.unauthenticated) {
              return TtsVoicePreset.clearGuide;
            }
          }
        } catch (_) {}
      }

      return preset;
    } catch (e) {
      return TtsVoicePreset.clearGuide;
    }
  }

  /// Persists the selected voice preset to local storage.
  static Future<void> savePreset(TtsVoicePreset preset) async {
    try {
      // Guard against saving premium presets for non-premium accounts
      if (preset.isPremium) {
        try {
          if (di.sl.isRegistered<AuthBloc>()) {
            final authState = di.sl<AuthBloc>().state;
            if (authState.status == AuthStatus.authenticated &&
                !(authState.user?.isPremium ?? false)) {
              return;
            }
            if (authState.status == AuthStatus.unauthenticated) {
              return;
            }
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKeyVoicePreset, preset.id);
    } catch (e) {
      di.sl<AppLogger>().warning(
        'TtsVoiceHelper: Failed to persist voice preset: $e',
        tag: 'TTS',
      );
    }
  }

  static List<dynamic>? _cachedVoices;

  /// Invalidates the in-memory voices cache (e.g., when the app resumes after user installs a new TTS engine).
  static void invalidateVoiceCache() {
    _cachedVoices = null;
  }

  /// Warm up and cache available voices in memory to remove preview tap delay.
  static Future<void> warmUpVoices(FlutterTts tts, {bool force = false}) async {
    if (!force && _cachedVoices != null) return;
    try {
      final dynamic raw = await tts.getVoices;
      if (raw is List && raw.isNotEmpty) {
        _cachedVoices = raw;
      }
    } catch (_) {}
  }

  /// Configures a [FlutterTts] instance with optimal high-fidelity on-device voices,
  /// natural human speaking rates, and pleasant pitches.
  static Future<void> applyPresetToTts(
    FlutterTts tts, {
    required TtsVoicePreset preset,
    bool isKids = false,
    String? explicitLocale,
  }) async {
    try {
      // 1. Set Language Locale
      final targetLocale =
          explicitLocale ??
          switch (preset) {
            TtsVoicePreset.britishAccent => 'en-GB',
            TtsVoicePreset.australianAccent => 'en-AU',
            TtsVoicePreset.indianEnglish => 'en-IN',
            _ => 'en-US',
          };
      await tts.setLanguage(targetLocale);

      // 2. Cadence and Pitch Calibration
      // Kids mode: 0.42 speech rate (patient and clear) with 1.03 pitch (warm teacher, no chipmunk distortion)
      // Adult mode: 0.44 speech rate with 1.0 pitch (natural human cadence)
      if (isKids) {
        await tts.setSpeechRate(0.42);
        await tts.setPitch(1.03);
      } else {
        await tts.setSpeechRate(0.44);
        await tts.setPitch(1.0);
      }

      await tts.setVolume(1.0);
      await tts.awaitSpeakCompletion(true);

      // 3. Voice Search & Resolution
      if (preset != TtsVoicePreset.systemDefault) {
        if (_cachedVoices == null) {
          try {
            final dynamic raw = await tts.getVoices;
            if (raw is List) {
              _cachedVoices = raw;
            }
          } catch (_) {}
        }
        final dynamic rawVoices = _cachedVoices;
        if (rawVoices is List && rawVoices.isNotEmpty) {
          final selectedVoice = _resolveVoice(rawVoices, preset, targetLocale);
          if (selectedVoice != null) {
            await tts.setVoice(selectedVoice);
          }
        }
      } else {
        try {
          await tts.clearVoice();
        } catch (_) {
          try {
            final dynamic defaultVoice = await tts.getDefaultVoice;
            if (defaultVoice is Map) {
              final Map<String, String> mapped = {};
              defaultVoice.forEach(
                (k, v) => mapped[k.toString()] = v.toString(),
              );
              await tts.setVoice(mapped);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      di.sl<AppLogger>().warning(
        'TtsVoiceHelper: Failed to calibrate TTS voice preset, using defaults: $e',
        tag: 'TTS',
      );
    }
  }

  /// Maps available device voices to the selected human-like preset.
  static Map<String, String>? _resolveVoice(
    List<dynamic> voices,
    TtsVoicePreset preset,
    String targetLocale,
  ) {
    final List<Map<String, String>> voiceList = [];
    for (final v in voices) {
      if (v is Map) {
        final name = (v['name'] ?? '').toString();
        final locale = (v['locale'] ?? '').toString();
        if (name.isNotEmpty) {
          voiceList.add({'name': name, 'locale': locale});
        }
      }
    }

    if (voiceList.isEmpty) return null;

    final langPrefix = targetLocale.toLowerCase().replaceAll('_', '-');

    // Filter to target language voices first
    final matchingLocaleVoices = voiceList.where((v) {
      final loc = v['locale']?.toLowerCase().replaceAll('_', '-') ?? '';
      return loc.startsWith(langPrefix) ||
          loc.startsWith(langPrefix.split('-').first);
    }).toList();

    final candidatePool = matchingLocaleVoices.isNotEmpty
        ? matchingLocaleVoices
        : voiceList;

    switch (preset) {
      case TtsVoicePreset.friendlyTeacher:
        // Priority 1: Google US warm female neural voices (sfg, tpf, iol)
        // Priority 2: Apple Samantha, Karen, Ava, Siri
        // Priority 3: Any natural female voice
        return candidatePool.firstWhere(
          (v) {
            final name = v['name']!.toLowerCase();
            return name.contains('sfg') || name.contains('tpf');
          },
          orElse: () => candidatePool.firstWhere((v) {
            final name = v['name']!.toLowerCase();
            return name.contains('samantha') ||
                name.contains('karen') ||
                name.contains('ava') ||
                name.contains('female');
          }, orElse: () => candidatePool.first),
        );

      case TtsVoicePreset.clearGuide:
        // Priority 1: Google US male neural voices (iol, iom)
        // Priority 2: Apple Daniel, Oliver, Aaron
        return candidatePool.firstWhere(
          (v) {
            final name = v['name']!.toLowerCase();
            return name.contains('iol') || name.contains('iom');
          },
          orElse: () => candidatePool.firstWhere((v) {
            final name = v['name']!.toLowerCase();
            return name.contains('daniel') ||
                name.contains('oliver') ||
                name.contains('aaron') ||
                name.contains('male');
          }, orElse: () => candidatePool.first),
        );

      case TtsVoicePreset.britishAccent:
        // Priority 1: Google UK voices (rjs, fis) or Apple British voices (oliver, kate, arthur)
        return candidatePool.firstWhere(
          (v) {
            final name = v['name']!.toLowerCase();
            final loc = v['locale']!.toLowerCase();
            return loc.contains('gb') &&
                (name.contains('rjs') ||
                    name.contains('fis') ||
                    name.contains('oliver') ||
                    name.contains('kate') ||
                    name.contains('arthur'));
          },
          orElse: () => candidatePool.firstWhere(
            (v) => (v['locale']?.toLowerCase().contains('gb') ?? false),
            orElse: () => candidatePool.first,
          ),
        );

      case TtsVoicePreset.australianAccent:
        // Priority 1: Google AU voices or Apple Karen/Lee/Russell
        return candidatePool.firstWhere(
          (v) {
            final name = v['name']!.toLowerCase();
            final loc = v['locale']!.toLowerCase();
            return loc.contains('au') ||
                name.contains('karen') ||
                name.contains('lee') ||
                name.contains('russell');
          },
          orElse: () => candidatePool.firstWhere(
            (v) => (v['locale']?.toLowerCase().contains('au') ?? false),
            orElse: () => candidatePool.first,
          ),
        );

      case TtsVoicePreset.indianEnglish:
        // Priority 1: Google IN voices or Apple Rishi/Isha/Sangeeta
        return candidatePool.firstWhere(
          (v) {
            final name = v['name']!.toLowerCase();
            final loc = v['locale']!.toLowerCase();
            return loc.contains('in') ||
                name.contains('rishi') ||
                name.contains('isha') ||
                name.contains('sangeeta');
          },
          orElse: () => candidatePool.firstWhere(
            (v) => (v['locale']?.toLowerCase().contains('in') ?? false),
            orElse: () => candidatePool.first,
          ),
        );

      case TtsVoicePreset.systemDefault:
        return null;
    }
  }

  static final Map<TtsVoicePreset, int> _sampleSentenceIndex = {};

  static const Map<TtsVoicePreset, List<String>> _sampleSentenceCatalog = {
    TtsVoicePreset.friendlyTeacher: [
      "Hello! Let's learn and have fun together today!",
      "Great job! Keep practicing and you will do wonderfully!",
      "Listen carefully, and repeat after me: The sun is shining bright!",
    ],
    TtsVoicePreset.clearGuide: [
      "Hello! Welcome to Vowl. Let's practice clear English pronunciation.",
      "Focus on enunciating each syllable clearly and steadily.",
      "Your pronunciation is improving with every single lesson.",
    ],
    TtsVoicePreset.britishAccent: [
      "Hello! Splendid! Welcome to Vowl. Ready for today's pronunciation lesson?",
      "Notice the crisp distinction between vowel sounds like bath and trap.",
      "Practice makes perfect. Shall we have another go at today's quest?",
    ],
    TtsVoicePreset.australianAccent: [
      "Hello! G'day! Welcome to Vowl. Ready to practice natural English pronunciation?",
      "Listen closely to the relaxed vowel sounds and upbeat intonation.",
      "Awesome work mate! You're making fantastic progress on your journey.",
    ],
    TtsVoicePreset.indianEnglish: [
      "Hello! Namaste! Welcome to Vowl. Let's master English together.",
      "Focus on standard rhythm and clear syllable stress for global communication.",
      "Wonderful effort! Consistent daily practice will build your confidence.",
    ],
    TtsVoicePreset.systemDefault: [
      "Hello! This is your device's default speech voice.",
      "This voice uses your operating system's standard text-to-speech engine.",
      "You can adjust system speech preferences in your device settings.",
    ],
  };

  /// Sample sentence for the settings audio preview, rotating through varied natural sentences.
  static String getSampleSentence(TtsVoicePreset preset) {
    final list =
        _sampleSentenceCatalog[preset] ??
        _sampleSentenceCatalog[TtsVoicePreset.clearGuide]!;
    final index = _sampleSentenceIndex[preset] ?? 0;
    final sentence = list[index % list.length];
    _sampleSentenceIndex[preset] = index + 1;
    return sentence;
  }
}
