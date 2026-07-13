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
    'Spanish': TranslateLanguage.spanish,
    'Hindi': TranslateLanguage.hindi,
    'French': TranslateLanguage.french,
    'German': TranslateLanguage.german,
    'Portuguese': TranslateLanguage.portuguese,
    'Arabic': TranslateLanguage.arabic,
    'Russian': TranslateLanguage.russian,
    'Chinese': TranslateLanguage.chinese,
    'Japanese': TranslateLanguage.japanese,
    'Korean': TranslateLanguage.korean,
    'Telugu': TranslateLanguage.telugu,
    'Tamil': TranslateLanguage.tamil,
    'Marathi': TranslateLanguage.marathi,
    'Bengali': TranslateLanguage.bengali,
    'Gujarati': TranslateLanguage.gujarati,
    'Kannada': TranslateLanguage.kannada,
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
    return await _modelManager.isModelDownloaded(bcpCode);
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

    // Trigger download in background
    await _modelManager.downloadModel(target.bcpCode);
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

    // Ensure model is fully downloaded before translating
    final isDownloaded = await _modelManager.isModelDownloaded(target.bcpCode);
    if (!isDownloaded) {
      await _modelManager.downloadModel(target.bcpCode);
    }

    return await _translator!.translateText(englishText);
  }

  /// Explicitly starts the model download for the configured language and waits for completion.
  Future<void> ensureModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final bcpCode = prefs.getString(_kTargetLangKey);
    if (bcpCode == null) return;
    final isDownloaded = await _modelManager.isModelDownloaded(bcpCode);
    if (!isDownloaded) {
      await _modelManager.downloadModel(bcpCode);
    }
  }

  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
  }
}
