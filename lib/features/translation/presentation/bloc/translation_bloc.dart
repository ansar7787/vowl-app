import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const TranslationTextChanged(this.text);
  @override
  List<Object?> get props => [text];
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

  const TranslationState({
    this.status = TranslationStatus.initial,
    this.sourceText = '',
    this.translatedText = '',
    this.currentTargetLanguage,
    this.downloadedLanguages = const [],
    this.isModelDownloading = false,
    this.errorMessage,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? sourceText,
    String? translatedText,
    String? currentTargetLanguage,
    List<String>? downloadedLanguages,
    bool? isModelDownloading,
    String? errorMessage,
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
  }

  Future<void> _onInitRequested(
    TranslationInitRequested event,
    Emitter<TranslationState> emit,
  ) async {
    emit(state.copyWith(status: TranslationStatus.loading));
    try {
      final currentLang = await _service.getConfiguredLanguageName();
      final downloaded = await _service.getDownloadedLanguageNames();

      emit(
        state.copyWith(
          status: TranslationStatus.loaded,
          currentTargetLanguage: currentLang,
          downloadedLanguages: downloaded,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TranslationStatus.error,
          errorMessage: 'Failed to load translation settings.',
        ),
      );
    }
  }

  Future<void> _onTextChanged(
    TranslationTextChanged event,
    Emitter<TranslationState> emit,
  ) async {
    final text = event.text.trim();
    emit(state.copyWith(sourceText: text, errorMessage: null));

    if (text.isEmpty) {
      emit(state.copyWith(translatedText: ''));
      return;
    }

    if (state.currentTargetLanguage == null) {
      emit(
        state.copyWith(errorMessage: 'Please select a target language first.'),
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

      emit(
        state.copyWith(
          translatedText: result,
          isModelDownloading: false,
          downloadedLanguages: newDownloaded,
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
            errorMessage: 'Failed to download language model.',
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
      emit(state.copyWith(errorMessage: 'Failed to delete language model.'));
    }
  }
}
