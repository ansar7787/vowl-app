import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/translation_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class TranslationEvent extends Equatable {
  const TranslationEvent();
  @override
  List<Object?> get props => [];
}

class TranslationInitRequested extends TranslationEvent {}

class TranslationTextChanged extends TranslationEvent {
  final String text;
  final bool isPremium;
  const TranslationTextChanged(this.text, {this.isPremium = false});
  @override
  List<Object?> get props => [text, isPremium];
}

class TranslationLanguageChanged extends TranslationEvent {
  final String targetLanguageName;
  const TranslationLanguageChanged(this.targetLanguageName);
  @override
  List<Object?> get props => [targetLanguageName];
}

class TranslationModelDeleted extends TranslationEvent {
  final String targetLanguageName;
  const TranslationModelDeleted(this.targetLanguageName);
  @override
  List<Object?> get props => [targetLanguageName];
}

class TranslationAdWatched extends TranslationEvent {}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

enum TranslationStatus { initial, loading, loaded, error }

class TranslationState extends Equatable {
  final TranslationStatus status;
  final String sourceText;
  final String translatedText;
  final String? currentTargetLanguage;
  final List<String> downloadedLanguages;
  final bool isModelDownloading;
  final String? errorMessage;
  final int freeTranslationsRemaining;
  final bool isLimitReached;

  const TranslationState({
    this.status = TranslationStatus.initial,
    this.sourceText = '',
    this.translatedText = '',
    this.currentTargetLanguage,
    this.downloadedLanguages = const [],
    this.isModelDownloading = false,
    this.errorMessage,
    this.freeTranslationsRemaining = 3,
    this.isLimitReached = false,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? sourceText,
    String? translatedText,
    String? currentTargetLanguage,
    List<String>? downloadedLanguages,
    bool? isModelDownloading,
    String? errorMessage,
    int? freeTranslationsRemaining,
    bool? isLimitReached,
  }) {
    return TranslationState(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      currentTargetLanguage:
          currentTargetLanguage ?? this.currentTargetLanguage,
      downloadedLanguages: downloadedLanguages ?? this.downloadedLanguages,
      isModelDownloading: isModelDownloading ?? this.isModelDownloading,
      errorMessage: errorMessage,
      freeTranslationsRemaining: freeTranslationsRemaining ?? this.freeTranslationsRemaining,
      isLimitReached: isLimitReached ?? this.isLimitReached,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sourceText,
    translatedText,
    currentTargetLanguage,
    downloadedLanguages,
    isModelDownloading,
    errorMessage,
    freeTranslationsRemaining,
    isLimitReached,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════════

class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationService _service;

  TranslationBloc({required TranslationService service})
    : _service = service,
      super(const TranslationState()) {
    on<TranslationInitRequested>(_onInitRequested);
    on<TranslationTextChanged>(_onTextChanged);
    on<TranslationLanguageChanged>(_onLanguageChanged);
    on<TranslationModelDeleted>(_onModelDeleted);
    on<TranslationAdWatched>(_onAdWatched);
  }

  Future<void> _onInitRequested(
    TranslationInitRequested event,
    Emitter<TranslationState> emit,
  ) async {
    emit(state.copyWith(status: TranslationStatus.loading));
    try {
      final currentLang = await _service.getConfiguredLanguageName();
      final downloaded = await _service.getDownloadedLanguageNames();

      final prefs = await SharedPreferences.getInstance();
      final int freeRemaining = prefs.getInt('translation_free_remaining') ?? 3;

      emit(
        state.copyWith(
          status: TranslationStatus.loaded,
          currentTargetLanguage: currentLang,
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
    final bool isFreshTranslation = state.translatedText.isEmpty && text.isNotEmpty;

    emit(state.copyWith(sourceText: text, errorMessage: null));

    if (text.isEmpty) {
      emit(state.copyWith(translatedText: '', isLimitReached: false));
      return;
    }

    if (!event.isPremium && state.freeTranslationsRemaining <= 0 && isFreshTranslation) {
      emit(state.copyWith(isLimitReached: true));
      return;
    }

    if (state.currentTargetLanguage == null) {
      emit(
        state.copyWith(errorMessage: 'translation.error_select_target'),
      );
      return;
    }

    try {
      final isDownloaded = state.downloadedLanguages.contains(
        state.currentTargetLanguage,
      );
      if (!isDownloaded) {
        emit(state.copyWith(isModelDownloading: true));
      }

      final result = await _service.translate(text);
      final newDownloaded = await _service.getDownloadedLanguageNames();

      final int newRemaining = event.isPremium 
          ? 3 
          : (isFreshTranslation ? state.freeTranslationsRemaining - 1 : state.freeTranslationsRemaining);

      final int finalRemaining = newRemaining > 0 ? newRemaining : 0;

      if (isFreshTranslation && !event.isPremium) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('translation_free_remaining', finalRemaining);
      }

      emit(
        state.copyWith(
          translatedText: result,
          isModelDownloading: false,
          downloadedLanguages: newDownloaded,
          freeTranslationsRemaining: finalRemaining,
          isLimitReached: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isModelDownloading: false,
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
          add(TranslationTextChanged(state.sourceText));
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

  Future<void> _onModelDeleted(
    TranslationModelDeleted event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      await _service.deleteLanguageModel(event.targetLanguageName);
      final newDownloaded = await _service.getDownloadedLanguageNames();

      String? currentLang = state.currentTargetLanguage;
      if (currentLang == event.targetLanguageName) {
        currentLang = null;
        emit(state.copyWith(translatedText: ''));
      }

      emit(
        state.copyWith(
          downloadedLanguages: newDownloaded,
          currentTargetLanguage: currentLang,
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
      add(TranslationTextChanged(state.sourceText));
    }
  }
}
