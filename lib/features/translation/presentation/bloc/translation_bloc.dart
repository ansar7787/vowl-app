import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/translation_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Base event class for the [TranslationBloc].
abstract class TranslationEvent extends Equatable {
  const TranslationEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched to initialize language models and restore cached state.
class TranslationInitRequested extends TranslationEvent {}

/// Dispatched when the user alters the input source text for translation.
class TranslationTextChanged extends TranslationEvent {
  /// The updated source text string.
  final String text;

  /// Whether the active user holds premium entitlement.
  final bool isPremium;

  /// Whether the translation should execute immediately without debounce.
  final bool immediate;

  /// Creates a [TranslationTextChanged] event.
  const TranslationTextChanged(
    this.text, {
    this.isPremium = false,
    this.immediate = false,
  });

  @override
  List<Object?> get props => [text, isPremium, immediate];
}

/// Dispatched when the target destination language is changed.
class TranslationLanguageChanged extends TranslationEvent {
  /// The localized or display name of the selected target language.
  final String targetLanguageName;

  /// Whether the active user holds premium entitlement.
  final bool isPremium;

  /// Creates a [TranslationLanguageChanged] event.
  const TranslationLanguageChanged(
    this.targetLanguageName, {
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [targetLanguageName, isPremium];
}

/// Dispatched when the source origin language is changed.
class TranslationSourceLanguageChanged extends TranslationEvent {
  /// The localized or display name of the selected source language.
  final String sourceLanguageName;

  /// Whether the active user holds premium entitlement.
  final bool isPremium;

  /// Creates a [TranslationSourceLanguageChanged] event.
  const TranslationSourceLanguageChanged(
    this.sourceLanguageName, {
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [sourceLanguageName, isPremium];
}

/// Dispatched to swap the current source and target languages.
class TranslationSwapLanguages extends TranslationEvent {
  /// Whether the active user holds premium entitlement.
  final bool isPremium;

  /// Creates a [TranslationSwapLanguages] event.
  const TranslationSwapLanguages({this.isPremium = false});

  @override
  List<Object?> get props => [isPremium];
}

/// Dispatched to purge an offline on-device translation model from local storage.
class TranslationModelDeleted extends TranslationEvent {
  /// The display name of the target language model to delete.
  final String targetLanguageName;

  /// Creates a [TranslationModelDeleted] event.
  const TranslationModelDeleted(this.targetLanguageName);

  @override
  List<Object?> get props => [targetLanguageName];
}

/// Dispatched when a rewarded video advertisement completes to unlock translations.
class TranslationAdWatched extends TranslationEvent {}

/// Dispatched to retry a previously failed translation attempt.
class TranslationRetryRequested extends TranslationEvent {
  /// Whether the active user holds premium entitlement.
  final bool isPremium;

  /// Creates a [TranslationRetryRequested] event.
  const TranslationRetryRequested({this.isPremium = false});

  @override
  List<Object?> get props => [isPremium];
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// High-level lifecycle status of the translation state machine.
enum TranslationStatus { initial, loading, loaded, error }

/// Immutable state snapshot for translation requests, language pairings,
/// and offline language model availability.
class TranslationState extends Equatable {
  final TranslationStatus status;
  final String sourceText;
  final String translatedText;
  final String currentSourceLanguage;
  final String? currentTargetLanguage;
  final List<String> downloadedLanguages;
  final bool isModelDownloading;
  final String? errorMessage;
  final int freeTranslationsRemaining;
  final bool isLimitReached;
  final bool isTranslating;

  const TranslationState({
    this.status = TranslationStatus.initial,
    this.sourceText = '',
    this.translatedText = '',
    this.currentSourceLanguage = 'English',
    this.currentTargetLanguage,
    this.downloadedLanguages = const [],
    this.isModelDownloading = false,
    this.errorMessage,
    this.freeTranslationsRemaining = 3,
    this.isLimitReached = false,
    this.isTranslating = false,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? sourceText,
    String? translatedText,
    String? currentSourceLanguage,
    String? currentTargetLanguage,
    List<String>? downloadedLanguages,
    bool? isModelDownloading,
    String? errorMessage,
    int? freeTranslationsRemaining,
    bool? isLimitReached,
    bool? isTranslating,
  }) {
    return TranslationState(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      currentSourceLanguage:
          currentSourceLanguage ?? this.currentSourceLanguage,
      currentTargetLanguage:
          currentTargetLanguage ?? this.currentTargetLanguage,
      downloadedLanguages: downloadedLanguages ?? this.downloadedLanguages,
      isModelDownloading: isModelDownloading ?? this.isModelDownloading,
      errorMessage: errorMessage,
      freeTranslationsRemaining:
          freeTranslationsRemaining ?? this.freeTranslationsRemaining,
      isLimitReached: isLimitReached ?? this.isLimitReached,
      isTranslating: isTranslating ?? this.isTranslating,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sourceText,
    translatedText,
    currentSourceLanguage,
    currentTargetLanguage,
    downloadedLanguages,
    isModelDownloading,
    errorMessage,
    freeTranslationsRemaining,
    isLimitReached,
    isTranslating,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════════

/// BLoC component managing real-time on-device text translation, free quota tracking,
/// language pack downloads, and bidirectional source/target language swapping.
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationService _service;
  DateTime? _lastTokenDeductionTime;
  int _requestId = 0;

  TranslationBloc({required TranslationService service})
    : _service = service,
      super(const TranslationState()) {
    on<TranslationInitRequested>(_onInitRequested);
    on<TranslationTextChanged>(_onTextChanged);
    on<TranslationLanguageChanged>(_onLanguageChanged);
    on<TranslationSourceLanguageChanged>(_onSourceLanguageChanged);
    on<TranslationSwapLanguages>(_onSwapLanguages);
    on<TranslationModelDeleted>(_onModelDeleted);
    on<TranslationAdWatched>(_onAdWatched);
    on<TranslationRetryRequested>(_onRetryRequested);
  }

  Future<void> _onInitRequested(
    TranslationInitRequested event,
    Emitter<TranslationState> emit,
  ) async {
    emit(state.copyWith(status: TranslationStatus.loading));
    try {
      final sourceLang = await _service.getConfiguredSourceLanguageName();
      final currentTargetLang = await _service.getConfiguredLanguageName();
      final downloaded = await _service.getDownloadedLanguageNames();

      final prefs = await SharedPreferences.getInstance();

      final lastResetStr = prefs.getString('translation_last_reset_date');
      final now = DateTime.now();
      bool shouldReset = false;

      if (lastResetStr != null) {
        final lastReset = DateTime.tryParse(lastResetStr);
        if (lastReset == null ||
            lastReset.year != now.year ||
            lastReset.month != now.month ||
            lastReset.day != now.day) {
          shouldReset = true;
        }
      } else {
        shouldReset = true;
      }

      int freeRemaining = prefs.getInt('translation_free_remaining') ?? 3;

      if (shouldReset) {
        freeRemaining = 3;
        await prefs.setInt('translation_free_remaining', 3);
        await prefs.setString(
          'translation_last_reset_date',
          now.toIso8601String(),
        );
      }

      emit(
        state.copyWith(
          status: TranslationStatus.loaded,
          currentSourceLanguage: sourceLang,
          currentTargetLanguage: currentTargetLang ?? 'Spanish',
          downloadedLanguages: downloaded,
          freeTranslationsRemaining: freeRemaining,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TranslationStatus.error,
          errorMessage: 'translation.error_load_settings',
        ),
      );
    }
  }

  Future<void> _onTextChanged(
    TranslationTextChanged event,
    Emitter<TranslationState> emit,
  ) async {
    final text = event.text.trim();
    _requestId++;
    final currentId = _requestId;

    if (text.isEmpty) {
      emit(
        state.copyWith(
          sourceText: '',
          translatedText: '',
          isLimitReached: false,
          isTranslating: false,
          errorMessage: null,
        ),
      );
      _lastTokenDeductionTime = null;
      return;
    }

    // Require at least 2 characters to trigger translation to avoid burning tokens on initial keystrokes
    if (text.length < 2) {
      emit(state.copyWith(sourceText: text, isTranslating: false, errorMessage: null));
      return;
    }

    final now = DateTime.now();
    bool isFreshTranslation = false;

    if (_lastTokenDeductionTime == null ||
        now.difference(_lastTokenDeductionTime!) >
            const Duration(seconds: 25)) {
      isFreshTranslation = true;
    }

    if (!event.isPremium &&
        state.freeTranslationsRemaining <= 0 &&
        isFreshTranslation) {
      emit(state.copyWith(sourceText: text, isLimitReached: true, isTranslating: false));
      return;
    }

    if (state.currentTargetLanguage == null) {
      emit(state.copyWith(sourceText: text, errorMessage: 'translation.error_select_target', isTranslating: false));
      return;
    }

    if (state.currentSourceLanguage == state.currentTargetLanguage) {
      emit(state.copyWith(sourceText: text, translatedText: text, isTranslating: false));
      return;
    }

    try {
      final isDownloaded = state.downloadedLanguages.contains(
        state.currentTargetLanguage,
      );

      emit(
        state.copyWith(
          sourceText: text,
          isTranslating: true,
          isModelDownloading: !isDownloaded,
          errorMessage: null,
        ),
      );

      final sourceLang =
          TranslationService.supportedLanguages[state.currentSourceLanguage];
      final targetLang =
          TranslationService.supportedLanguages[state.currentTargetLanguage];

      final result = await _service.translate(
        text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      // Discard stale responses if a newer request was dispatched
      if (currentId != _requestId) {
        return;
      }

      final newDownloaded = await _service.getDownloadedLanguageNames();

      final int newRemaining = event.isPremium
          ? 3
          : (isFreshTranslation
                ? state.freeTranslationsRemaining - 1
                : state.freeTranslationsRemaining);

      final int finalRemaining = newRemaining > 0 ? newRemaining : 0;

      if (isFreshTranslation && !event.isPremium) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('translation_free_remaining', finalRemaining);
        _lastTokenDeductionTime = now;
      }

      emit(
        state.copyWith(
          translatedText: result,
          isModelDownloading: false,
          downloadedLanguages: newDownloaded,
          freeTranslationsRemaining: finalRemaining,
          isLimitReached: false,
          isTranslating: false,
        ),
      );
    } catch (e) {
      if (currentId != _requestId) return;

      emit(
        state.copyWith(
          isModelDownloading: false,
          isTranslating: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLanguageChanged(
    TranslationLanguageChanged event,
    Emitter<TranslationState> emit,
  ) async {
    final lang = event.targetLanguageName;
    if (lang == state.currentTargetLanguage) return;

    emit(state.copyWith(currentTargetLanguage: lang, errorMessage: null));

    final target = TranslationService.supportedLanguages[lang];
    if (target != null) {
      emit(state.copyWith(isModelDownloading: true));
      try {
        await _service.setTargetLanguage(target);
        final newDownloaded = await _service.getDownloadedLanguageNames();
        emit(
          state.copyWith(
            isModelDownloading: false,
            downloadedLanguages: newDownloaded,
          ),
        );

        if (state.sourceText.isNotEmpty) {
          add(
            TranslationTextChanged(
              state.sourceText,
              isPremium: event.isPremium,
              immediate: true,
            ),
          );
        }
      } catch (e) {
        emit(
          state.copyWith(
            isModelDownloading: false,
            errorMessage: 'translation.error_download_model',
          ),
        );
      }
    }
  }

  Future<void> _onSourceLanguageChanged(
    TranslationSourceLanguageChanged event,
    Emitter<TranslationState> emit,
  ) async {
    final lang = event.sourceLanguageName;
    if (lang == state.currentSourceLanguage) return;

    emit(state.copyWith(currentSourceLanguage: lang, errorMessage: null));

    final source = TranslationService.supportedLanguages[lang];
    if (source != null) {
      emit(state.copyWith(isModelDownloading: true));
      try {
        await _service.setSourceLanguage(source);
        final newDownloaded = await _service.getDownloadedLanguageNames();
        emit(
          state.copyWith(
            isModelDownloading: false,
            downloadedLanguages: newDownloaded,
          ),
        );

        if (state.sourceText.isNotEmpty) {
          add(
            TranslationTextChanged(
              state.sourceText,
              isPremium: event.isPremium,
              immediate: true,
            ),
          );
        }
      } catch (e) {
        emit(
          state.copyWith(
            isModelDownloading: false,
            errorMessage: 'translation.error_download_model',
          ),
        );
      }
    }
  }

  Future<void> _onSwapLanguages(
    TranslationSwapLanguages event,
    Emitter<TranslationState> emit,
  ) async {
    final oldSource = state.currentSourceLanguage;
    final oldTarget = state.currentTargetLanguage;
    if (oldTarget == null) return;

    final newSource = oldTarget;
    final newTarget = oldSource;
    final newSourceText = state.translatedText;
    final newTranslatedText = state.sourceText;

    emit(
      state.copyWith(
        currentSourceLanguage: newSource,
        currentTargetLanguage: newTarget,
        sourceText: newSourceText,
        translatedText: newTranslatedText,
        errorMessage: null,
      ),
    );

    final sourceObj = TranslationService.supportedLanguages[newSource];
    final targetObj = TranslationService.supportedLanguages[newTarget];
    if (sourceObj != null && targetObj != null) {
      await _service.setLanguages(source: sourceObj, target: targetObj);
      if (newSourceText.isNotEmpty) {
        add(
          TranslationTextChanged(
            newSourceText,
            isPremium: event.isPremium,
            immediate: true,
          ),
        );
      }
    }
  }

  Future<void> _onModelDeleted(
    TranslationModelDeleted event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      await _service.deleteLanguageModel(event.targetLanguageName);
      final newDownloaded = await _service.getDownloadedLanguageNames();

      String? currentTarget = state.currentTargetLanguage;
      if (currentTarget == event.targetLanguageName) {
        currentTarget = null;
        emit(state.copyWith(translatedText: ''));
      }

      emit(
        state.copyWith(
          downloadedLanguages: newDownloaded,
          currentTargetLanguage: currentTarget,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'translation.error_delete_model'));
    }
  }

  Future<void> _onAdWatched(
    TranslationAdWatched event,
    Emitter<TranslationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('translation_free_remaining', 3);

    emit(
      state.copyWith(
        freeTranslationsRemaining: 3,
        isLimitReached: false,
        errorMessage: null,
      ),
    );
    if (state.sourceText.isNotEmpty) {
      add(TranslationTextChanged(state.sourceText, immediate: true));
    }
  }

  Future<void> _onRetryRequested(
    TranslationRetryRequested event,
    Emitter<TranslationState> emit,
  ) async {
    if (state.sourceText.isNotEmpty) {
      add(
        TranslationTextChanged(
          state.sourceText,
          isPremium: event.isPremium,
          immediate: true,
        ),
      );
    } else {
      add(TranslationInitRequested());
    }
  }
}
