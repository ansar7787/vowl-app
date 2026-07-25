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

  static const String _kTargetLangKey = 'translation_target_lang';

  final _modelManager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _translator;
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
    final englishDownloaded = await _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
    return targetDownloaded && englishDownloaded;
  }

  /// Sets the user's preferred target language. This triggers the 30MB model download.
  Future<void> setTargetLanguage(TranslateLanguage target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTargetLangKey, target.bcpCode);

    // If they changed the language, dispose the old translator
    if (_currentTargetLanguage != target) {
      await _translator?.close();
      _translator = null;
    }

    _currentTargetLanguage = target;

    // Ensure English base model is downloaded
    final isEnDownloaded = await _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
    if (!isEnDownloaded) {
      await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
    }

    // Trigger download for target language
    final isTargetDownloaded = await _modelManager.isModelDownloaded(target.bcpCode);
    if (!isTargetDownloaded) {
      await _modelManager.downloadModel(target.bcpCode);
    }
  }

  /// Translates the given English text to the user's saved target language.
  ///
  /// Automatically downloads the model if it hasn't finished yet.
  Future<String> translate(String englishText) async {
    if (englishText.isEmpty) return englishText;

    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) {
      throw Exception('Target language not set');
    }

    final target = TranslateLanguage.values.firstWhere(
      (lang) => lang.bcpCode == bcpCode,
      orElse: () => TranslateLanguage.spanish,
    );

    // Initialize translator if needed
    if (_translator == null || _currentTargetLanguage != target) {
      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: target,
      );
      _currentTargetLanguage = target;
    }

    // Ensure models are fully downloaded before translating
    final isEnDownloaded = await _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
    if (!isEnDownloaded) {
      await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
    }
    final isDownloaded = await _modelManager.isModelDownloaded(target.bcpCode);
    if (!isDownloaded) {
      await _modelManager.downloadModel(target.bcpCode);
    }

    try {
      return await _translator!.translateText(englishText);
    } catch (e) {
      // Native engine might have been killed by OS memory pressure.
      // Re-initialize and retry once.
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: target,
      );
      _currentTargetLanguage = target;
      return await _translator!.translateText(englishText);
    }
  }


  /// Explicitly starts the model download for the configured language and waits for completion.
  Future<void> ensureModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) return;
    final isEnDownloaded = await _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
    if (!isEnDownloaded) {
      await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
    }
    final isDownloaded = await _modelManager.isModelDownloaded(bcpCode);
    if (!isDownloaded) {
      await _modelManager.downloadModel(bcpCode);
    }
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

  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
  }
}
