import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle free, on-device ML Kit translation.
///
/// This avoids expensive API calls and perfectly preserves user privacy.
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  static const String _kSourceLangKey = 'translation_source_lang';
  static const String _kTargetLangKey = 'translation_target_lang';
  static const String _kCachedDownloadedLangsKey =
      'cached_downloaded_languages';

  TranslationService._internal() {
    _loadCachedDownloadedLanguages();
  }

  Future<void> _loadCachedDownloadedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_kCachedDownloadedLangsKey);
      if (cached != null && cached.isNotEmpty) {
        if (downloadedLanguagesNotifier.value.isEmpty) {
          downloadedLanguagesNotifier.value = cached.toSet();
        }
      }
    } catch (_) {}
  }

  final _modelManager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _translator;
  TranslateLanguage? _currentSourceLanguage;
  TranslateLanguage? _currentTargetLanguage;

  /// Reactive notifier for all languages currently downloaded and ready offline.
  final ValueNotifier<Set<String>> downloadedLanguagesNotifier =
      ValueNotifier<Set<String>>({});

  /// Reactive notifier tracking active language downloads and their progress (0.0 to 1.0).
  final ValueNotifier<Map<String, double>> downloadingProgressNotifier =
      ValueNotifier<Map<String, double>>({});

  final Map<String, Future<bool>> _activeDownloads = {};

  /// Accurate country flag emojis for all 58 supported ML Kit languages.
  static const Map<String, String> languageFlags = {
    'Afrikaans': '🇿🇦',
    'Albanian': '🇦🇱',
    'Arabic': '🇸🇦',
    'Belarusian': '🇧🇾',
    'Bengali': '🇧🇩',
    'Bulgarian': '🇧🇬',
    'Catalan': '🇪🇸',
    'Chinese': '🇨🇳',
    'Croatian': '🇭🇷',
    'Czech': '🇨🇿',
    'Danish': '🇩🇰',
    'Dutch': '🇳🇱',
    'English': '🇬🇧',
    'Esperanto': '🌐',
    'Estonian': '🇪🇪',
    'Finnish': '🇫🇮',
    'French': '🇫🇷',
    'Galician': '🇪🇸',
    'Georgian': '🇬🇪',
    'German': '🇩🇪',
    'Greek': '🇬🇷',
    'Gujarati': '🇮🇳',
    'Hebrew': '🇮🇱',
    'Hindi': '🇮🇳',
    'Hungarian': '🇭🇺',
    'Icelandic': '🇮🇸',
    'Indonesian': '🇮🇩',
    'Irish': '🇮🇪',
    'Italian': '🇮🇹',
    'Japanese': '🇯🇵',
    'Kannada': '🇮🇳',
    'Korean': '🇰🇷',
    'Latvian': '🇱🇻',
    'Lithuanian': '🇱🇹',
    'Macedonian': '🇲🇰',
    'Malay': '🇲🇾',
    'Maltese': '🇲🇹',
    'Marathi': '🇮🇳',
    'Norwegian': '🇳🇴',
    'Persian': '🇮🇷',
    'Polish': '🇵🇱',
    'Portuguese': '🇵🇹',
    'Romanian': '🇷🇴',
    'Russian': '🇷🇺',
    'Slovak': '🇸🇰',
    'Slovenian': '🇸🇮',
    'Spanish': '🇪🇸',
    'Swahili': '🇰🇪',
    'Swedish': '🇸🇪',
    'Tagalog': '🇵🇭',
    'Tamil': '🇮🇳',
    'Telugu': '🇮🇳',
    'Thai': '🇹🇭',
    'Turkish': '🇹🇷',
    'Ukrainian': '🇺🇦',
    'Urdu': '🇵🇰',
    'Vietnamese': '🇻🇳',
    'Welsh': '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
  };

  /// Returns the country flag emoji for a given language name.
  static String getFlag(String languageName) =>
      languageFlags[languageName] ?? '🌐';

  /// The list of major supported native languages to show in the UI selector.
  static const Map<String, TranslateLanguage> supportedLanguages = {
    'Afrikaans': TranslateLanguage.afrikaans,
    'Albanian': TranslateLanguage.albanian,
    'Arabic': TranslateLanguage.arabic,
    'Belarusian': TranslateLanguage.belarusian,
    'Bengali': TranslateLanguage.bengali,
    'Bulgarian': TranslateLanguage.bulgarian,
    'Catalan': TranslateLanguage.catalan,
    'Chinese': TranslateLanguage.chinese,
    'Croatian': TranslateLanguage.croatian,
    'Czech': TranslateLanguage.czech,
    'Danish': TranslateLanguage.danish,
    'Dutch': TranslateLanguage.dutch,
    'English': TranslateLanguage.english,
    'Esperanto': TranslateLanguage.esperanto,
    'Estonian': TranslateLanguage.estonian,
    'Finnish': TranslateLanguage.finnish,
    'French': TranslateLanguage.french,
    'Galician': TranslateLanguage.galician,
    'Georgian': TranslateLanguage.georgian,
    'German': TranslateLanguage.german,
    'Greek': TranslateLanguage.greek,
    'Gujarati': TranslateLanguage.gujarati,
    'Hebrew': TranslateLanguage.hebrew,
    'Hindi': TranslateLanguage.hindi,
    'Hungarian': TranslateLanguage.hungarian,
    'Icelandic': TranslateLanguage.icelandic,
    'Indonesian': TranslateLanguage.indonesian,
    'Irish': TranslateLanguage.irish,
    'Italian': TranslateLanguage.italian,
    'Japanese': TranslateLanguage.japanese,
    'Kannada': TranslateLanguage.kannada,
    'Korean': TranslateLanguage.korean,
    'Latvian': TranslateLanguage.latvian,
    'Lithuanian': TranslateLanguage.lithuanian,
    'Macedonian': TranslateLanguage.macedonian,
    'Malay': TranslateLanguage.malay,
    'Maltese': TranslateLanguage.maltese,
    'Marathi': TranslateLanguage.marathi,
    'Norwegian': TranslateLanguage.norwegian,
    'Persian': TranslateLanguage.persian,
    'Polish': TranslateLanguage.polish,
    'Portuguese': TranslateLanguage.portuguese,
    'Romanian': TranslateLanguage.romanian,
    'Russian': TranslateLanguage.russian,
    'Slovak': TranslateLanguage.slovak,
    'Slovenian': TranslateLanguage.slovenian,
    'Spanish': TranslateLanguage.spanish,
    'Swahili': TranslateLanguage.swahili,
    'Swedish': TranslateLanguage.swedish,
    'Tagalog': TranslateLanguage.tagalog,
    'Tamil': TranslateLanguage.tamil,
    'Telugu': TranslateLanguage.telugu,
    'Thai': TranslateLanguage.thai,
    'Turkish': TranslateLanguage.turkish,
    'Ukrainian': TranslateLanguage.ukrainian,
    'Urdu': TranslateLanguage.urdu,
    'Vietnamese': TranslateLanguage.vietnamese,
    'Welsh': TranslateLanguage.welsh,
  };

  /// Native script and phonetic search aliases for all supported languages.
  static const Map<String, List<String>> languageAliases = {
    'Arabic': ['العربية', 'arabiya'],
    'Belarusian': ['беларуская'],
    'Bengali': ['বাংলা', 'bangla'],
    'Bulgarian': ['български'],
    'Catalan': ['català'],
    'Chinese': ['中文', '汉语', '漢語', 'mandarin', 'zhongwen'],
    'Croatian': ['hrvatski'],
    'Czech': ['čeština', 'cestina'],
    'Danish': ['dansk'],
    'Dutch': ['nederlands'],
    'Esperanto': ['esperanto'],
    'Estonian': ['eesti'],
    'Finnish': ['suomi'],
    'French': ['français', 'francais'],
    'Galician': ['galego'],
    'Georgian': ['ქართული'],
    'German': ['deutsch'],
    'Greek': ['ελληνικά', 'greek'],
    'Gujarati': ['ગુજરાતી', 'gujarati'],
    'Hebrew': ['עברית', 'ivrit'],
    'Hindi': ['हिन्दी', 'हिंदी', 'hindi'],
    'Hungarian': ['magyar'],
    'Icelandic': ['íslenska'],
    'Indonesian': ['bahasa indonesia'],
    'Irish': ['gaeilge'],
    'Italian': ['italiano'],
    'Japanese': ['日本語', 'にほんご', 'nihongo'],
    'Kannada': ['ಕನ್ನಡ', 'kannada'],
    'Korean': ['한국어', '조선말', 'hangul', 'hangugeo'],
    'Latvian': ['latviešu'],
    'Lithuanian': ['lietuvių'],
    'Macedonian': ['македонски'],
    'Malay': ['bahasa melayu'],
    'Maltese': ['malti'],
    'Marathi': ['मराठी', 'marathi'],
    'Norwegian': ['norsk'],
    'Persian': ['فارسی', 'farsi'],
    'Polish': ['polski'],
    'Portuguese': ['português', 'portugues'],
    'Romanian': ['română', 'romana'],
    'Russian': ['русский', 'russkiy'],
    'Slovak': ['slovenčina'],
    'Slovenian': ['slovenščina'],
    'Spanish': ['español', 'espanol', 'castellano'],
    'Swahili': ['kiswahili'],
    'Swedish': ['svenska'],
    'Tagalog': ['filipino', 'pilipino'],
    'Tamil': ['தமிழ்', 'tamil'],
    'Telugu': ['తెలుగు', 'telugu'],
    'Thai': ['ไทย', 'thai'],
    'Turkish': ['türkçe', 'turkce'],
    'Ukrainian': ['українська'],
    'Urdu': ['اردو', 'urdu'],
    'Vietnamese': ['tiếng việt', 'tieng viet'],
    'Welsh': ['cymraeg'],
  };

  TranslateLanguage? _resolveLanguage(String? bcpCode) {
    if (bcpCode == null) return null;
    try {
      return TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == bcpCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureModelDownloadedInternal(String bcpCode) async {
    final isDownloaded = await _modelManager.isModelDownloaded(bcpCode);
    if (!isDownloaded) {
      await _modelManager.downloadModel(bcpCode);
    }
  }

  /// Returns the BCP-47 language code of the user's configured target language (e.g. 'es', 'fr', 'de').
  Future<String?> getTargetLanguageBcpCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTargetLangKey);
  }

  /// Returns true if the user has previously selected and downloaded a target language.
  Future<bool> isLanguageConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kTargetLangKey);
  }

  /// Returns true if the ML kit model for the target language is fully downloaded.
  Future<bool> isTargetModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) return false;
    final targetDownloaded = await _modelManager.isModelDownloaded(bcpCode);
    final englishDownloaded = await _modelManager.isModelDownloaded(
      TranslateLanguage.english.bcpCode,
    );
    return targetDownloaded && englishDownloaded;
  }

  /// Sets the user's preferred target language. This triggers model download.
  Future<void> setTargetLanguage(TranslateLanguage target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTargetLangKey, target.bcpCode);

    if (_currentTargetLanguage != target) {
      await _translator?.close();
      _translator = null;
    }

    _currentTargetLanguage = target;

    await Future.wait(
      {
        TranslateLanguage.english.bcpCode,
        target.bcpCode,
      }.map(_ensureModelDownloadedInternal),
    );
    await refreshDownloadedLanguages();
  }

  /// Sets the user's source language.
  Future<void> setSourceLanguage(TranslateLanguage source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourceLangKey, source.bcpCode);

    if (_currentSourceLanguage != source) {
      await _translator?.close();
      _translator = null;
    }

    _currentSourceLanguage = source;

    await Future.wait(
      {
        TranslateLanguage.english.bcpCode,
        source.bcpCode,
      }.map(_ensureModelDownloadedInternal),
    );
    await refreshDownloadedLanguages();
  }

  /// Sets both source and target languages simultaneously.
  Future<void> setLanguages({
    required TranslateLanguage source,
    required TranslateLanguage target,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourceLangKey, source.bcpCode);
    await prefs.setString(_kTargetLangKey, target.bcpCode);

    if (_currentSourceLanguage != source || _currentTargetLanguage != target) {
      await _translator?.close();
      _translator = null;
    }

    _currentSourceLanguage = source;
    _currentTargetLanguage = target;

    await Future.wait(
      {
        TranslateLanguage.english.bcpCode,
        source.bcpCode,
        target.bcpCode,
      }.map(_ensureModelDownloadedInternal),
    );
    await refreshDownloadedLanguages();
  }

  /// Refreshes the cached downloaded languages and notifies all reactive listeners.
  Future<List<String>> refreshDownloadedLanguages() async {
    final downloaded = await getDownloadedLanguageNames();
    downloadedLanguagesNotifier.value = downloaded.toSet();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCachedDownloadedLangsKey, downloaded);
    } catch (_) {}
    return downloaded;
  }

  /// Downloads the specified language pack and updates reactive listeners across the app.
  /// Deduplicates concurrent download requests for the same language.
  Future<bool> downloadLanguage(String languageName) async {
    final target = supportedLanguages[languageName];
    if (target == null) return false;

    // Check if already downloaded
    final isAlreadyDownloaded = await _modelManager.isModelDownloaded(
      target.bcpCode,
    );
    if (isAlreadyDownloaded) {
      final current = Set<String>.from(downloadedLanguagesNotifier.value)
        ..add(languageName);
      downloadedLanguagesNotifier.value = current;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_kCachedDownloadedLangsKey, current.toList());
      } catch (_) {}
      return true;
    }

    // Deduplicate in-flight downloads
    if (_activeDownloads.containsKey(languageName)) {
      return _activeDownloads[languageName]!;
    }

    final completer = Completer<bool>();
    _activeDownloads[languageName] = completer.future;

    // Start simulated progress for smooth real-time visual feedback
    double progress = 0.08;
    final progressMap = Map<String, double>.from(
      downloadingProgressNotifier.value,
    );
    progressMap[languageName] = progress;
    downloadingProgressNotifier.value = progressMap;

    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (progress < 0.60) {
        progress += 0.04;
      } else if (progress < 0.85) {
        progress += 0.02;
      } else if (progress < 0.95) {
        progress += 0.005;
      }
      final currentMap = Map<String, double>.from(
        downloadingProgressNotifier.value,
      );
      if (currentMap.containsKey(languageName)) {
        currentMap[languageName] = progress;
        downloadingProgressNotifier.value = currentMap;
      }
    });

    try {
      await Future.wait(
        {
          TranslateLanguage.english.bcpCode,
          target.bcpCode,
        }.map(_ensureModelDownloadedInternal),
      );

      progressTimer.cancel();

      // Complete to 100%
      final finalMap = Map<String, double>.from(
        downloadingProgressNotifier.value,
      );
      finalMap[languageName] = 1.0;
      downloadingProgressNotifier.value = finalMap;

      // Update downloaded set across the entire app
      final newDownloaded = Set<String>.from(downloadedLanguagesNotifier.value)
        ..add(languageName);
      downloadedLanguagesNotifier.value = newDownloaded;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _kCachedDownloadedLangsKey,
          newDownloaded.toList(),
        );
      } catch (_) {}

      // Brief pause so user sees completion feedback
      await Future.delayed(const Duration(milliseconds: 300));
      final cleanMap = Map<String, double>.from(
        downloadingProgressNotifier.value,
      );
      cleanMap.remove(languageName);
      downloadingProgressNotifier.value = cleanMap;

      _activeDownloads.remove(languageName);
      completer.complete(true);
      return true;
    } catch (e) {
      progressTimer.cancel();
      final errMap = Map<String, double>.from(
        downloadingProgressNotifier.value,
      );
      errMap.remove(languageName);
      downloadingProgressNotifier.value = errMap;
      _activeDownloads.remove(languageName);
      completer.complete(false);
      rethrow;
    }
  }

  /// Translates the given text between source and target languages.
  ///
  /// Automatically downloads models if not yet ready on device.
  Future<String> translate(
    String text, {
    TranslateLanguage? sourceLanguage,
    TranslateLanguage? targetLanguage,
  }) async {
    if (text.isEmpty) return text;

    final prefs = await SharedPreferences.getInstance();
    final source =
        sourceLanguage ??
        _resolveLanguage(prefs.getString(_kSourceLangKey)) ??
        TranslateLanguage.english;

    final target =
        targetLanguage ??
        _resolveLanguage(prefs.getString(_kTargetLangKey)) ??
        TranslateLanguage.spanish;

    if (source == target) return text;

    // Initialize or recreate translator if needed
    if (_translator == null ||
        _currentSourceLanguage != source ||
        _currentTargetLanguage != target) {
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      _currentSourceLanguage = source;
      _currentTargetLanguage = target;
    }

    // Ensure models are fully downloaded before translating
    await Future.wait(
      {
        source.bcpCode,
        target.bcpCode,
        TranslateLanguage.english.bcpCode,
      }.map(_ensureModelDownloadedInternal),
    );

    try {
      var result = await _translator!.translateText(text);
      if (result == text && source != target) {
        await Future.delayed(const Duration(milliseconds: 600));
        result = await _translator!.translateText(text);
      }
      return result;
    } catch (e) {
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      _currentSourceLanguage = source;
      _currentTargetLanguage = target;

      try {
        var result2 = await _translator!.translateText(text);
        if (result2 == text && source != target) {
          await Future.delayed(const Duration(milliseconds: 600));
          result2 = await _translator!.translateText(text);
        }
        return result2;
      } catch (e2) {
        await _modelManager.deleteModel(target.bcpCode);
        throw Exception(
          'Model error encountered. Corrupted model reset. Please try again to reload.',
        );
      }
    }
  }

  /// Explicitly starts the model download for the configured language and waits for completion.
  Future<void> ensureModelDownloaded() async {
    final targetName = await getConfiguredLanguageName();
    if (targetName != null) {
      await downloadLanguage(targetName);
    }
  }

  /// Returns the display name of the currently configured source language.
  Future<String> getConfiguredSourceLanguageName() async {
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kSourceLangKey);
    if (bcpCode == null) return 'English';

    for (final entry in supportedLanguages.entries) {
      if (entry.value.bcpCode == bcpCode) return entry.key;
    }
    return 'English';
  }

  /// Returns the display name of the currently configured target language,
  /// or null if no language has been selected.
  Future<String?> getConfiguredLanguageName() async {
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) return null;

    for (final entry in supportedLanguages.entries) {
      if (entry.value.bcpCode == bcpCode) return entry.key;
    }
    return null;
  }

  /// Returns a list of language names that are currently downloaded on the device.
  ///
  /// Executed in parallel with Future.wait for maximum speed.
  Future<List<String>> getDownloadedLanguageNames() async {
    final results = await Future.wait(
      supportedLanguages.entries.map((entry) async {
        final isDownloaded = await _modelManager.isModelDownloaded(
          entry.value.bcpCode,
        );
        return isDownloaded ? entry.key : null;
      }),
    );
    return results.whereType<String>().toList();
  }

  /// Deletes the ML model for a specific language to free up storage space.
  Future<void> deleteLanguageModel(String languageName) async {
    final target = supportedLanguages[languageName];
    if (target != null) {
      final current = Set<String>.from(downloadedLanguagesNotifier.value)
        ..remove(languageName);
      downloadedLanguagesNotifier.value = current;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_kCachedDownloadedLangsKey, current.toList());
      } catch (_) {}

      await _modelManager.deleteModel(target.bcpCode);
      if (_currentTargetLanguage == target ||
          _currentSourceLanguage == target) {
        await _translator?.close();
        _translator = null;
      }
      await refreshDownloadedLanguages();
    }
  }

  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
  }
}
