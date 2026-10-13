import 'dart:async';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle free, on-device ML Kit translation.
///
/// This avoids expensive API calls and perfectly preserves user privacy.
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const String _kSourceLangKey = 'translation_source_lang';
  static const String _kTargetLangKey = 'translation_target_lang';

  final _modelManager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _translator;
  TranslateLanguage? _currentSourceLanguage;
  TranslateLanguage? _currentTargetLanguage;

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

  /// Sets the user's preferred target language. This triggers the 30MB model download.
  Future<void> setTargetLanguage(TranslateLanguage target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTargetLangKey, target.bcpCode);

    if (_currentTargetLanguage != target) {
      await _translator?.close();
      _translator = null;
    }

    _currentTargetLanguage = target;

    await Future.wait([
      _ensureModelDownloadedInternal(TranslateLanguage.english.bcpCode),
      _ensureModelDownloadedInternal(target.bcpCode),
    ]);
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

    await Future.wait([
      _ensureModelDownloadedInternal(TranslateLanguage.english.bcpCode),
      _ensureModelDownloadedInternal(source.bcpCode),
    ]);
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

    await Future.wait([
      _ensureModelDownloadedInternal(TranslateLanguage.english.bcpCode),
      _ensureModelDownloadedInternal(source.bcpCode),
      _ensureModelDownloadedInternal(target.bcpCode),
    ]);
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
    final source = sourceLanguage ??
        _resolveLanguage(prefs.getString(_kSourceLangKey)) ??
        TranslateLanguage.english;

    final target = targetLanguage ??
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
    await Future.wait([
      _ensureModelDownloadedInternal(source.bcpCode),
      _ensureModelDownloadedInternal(target.bcpCode),
      if (source != TranslateLanguage.english &&
          target != TranslateLanguage.english)
        _ensureModelDownloadedInternal(TranslateLanguage.english.bcpCode),
    ]);

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
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) return;
    await Future.wait([
      _ensureModelDownloadedInternal(TranslateLanguage.english.bcpCode),
      _ensureModelDownloadedInternal(bcpCode),
    ]);
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
      await _modelManager.deleteModel(target.bcpCode);
      if (_currentTargetLanguage == target ||
          _currentSourceLanguage == target) {
        await _translator?.close();
        _translator = null;
      }
    }
  }

  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
  }
}
