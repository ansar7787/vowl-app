import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/premium_lock_card.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final HapticService _haptics = di.sl<HapticService>();
  final TtsService _tts = di.sl<TtsService>();
  final SpeechService _speech = di.sl<SpeechService>();

  final ValueNotifier<bool> _isFocused = ValueNotifier(false);
  final ValueNotifier<bool> _isSourceSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> _isTargetSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> _isListening = ValueNotifier(false);

  double _swapTurns = 0.0;
  Timer? _debounce;
  static const int _maxCharacterLimit = 600;

  @override
  void initState() {
    super.initState();
    context.read<TranslationBloc>().add(TranslationInitRequested());

    _focusNode.addListener(() {
      _isFocused.value = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tts.stop();
    _speech.stop();
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isFocused.dispose();
    _isSourceSpeaking.dispose();
    _isTargetSpeaking.dispose();
    _isListening.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
      context.read<TranslationBloc>().add(
        TranslationTextChanged(text, isPremium: isPremium),
      );
    });
  }

  void _triggerImmediateTranslation() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    context.read<TranslationBloc>().add(
      TranslationTextChanged(
        _inputController.text,
        isPremium: isPremium,
        immediate: true,
      ),
    );
    _haptics.light();
  }

  void _showLanguagePicker(
    BuildContext context,
    bool isDark, {
    required bool isSource,
  }) {
    final blocState = context.read<TranslationBloc>().state;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    LanguageSelectionBottomSheet.show(
      context,
      isSource: isSource,
      currentLanguage: isSource
          ? blocState.currentSourceLanguage
          : blocState.currentTargetLanguage,
      downloadedLanguages: blocState.downloadedLanguages,
      onSelected: (lang) {
        if (isSource) {
          if (lang == blocState.currentTargetLanguage) {
            _onSwapTapped(isPremium);
          } else {
            context.read<TranslationBloc>().add(
              TranslationSourceLanguageChanged(lang, isPremium: isPremium),
            );
          }
        } else {
          if (lang == blocState.currentSourceLanguage) {
            _onSwapTapped(isPremium);
          } else {
            context.read<TranslationBloc>().add(
              TranslationLanguageChanged(lang, isPremium: isPremium),
            );
          }
        }
      },
    );
  }

  void _showLanguageManager(BuildContext context, bool isDark) {
    _haptics.selection();
    _showLanguagePicker(context, isDark, isSource: false);
  }

  Future<void> _speakText({
    required String text,
    required String languageName,
    required bool isSource,
  }) async {
    final notifier = isSource ? _isSourceSpeaking : _isTargetSpeaking;
    if (notifier.value) {
      await _tts.stop();
      notifier.value = false;
      return;
    }

    if (text.trim().isEmpty) return;

    _haptics.light();
    notifier.value = true;

    try {
      final targetObj = TranslationService.supportedLanguages[languageName];
      final bcp = targetObj?.bcpCode ?? 'en-US';
      await _tts.speak(text, locale: bcp);
    } catch (_) {
      // Ignored gracefully
    } finally {
      if (mounted) {
        notifier.value = false;
      }
    }
  }

  Future<void> _toggleVoiceDictation(String sourceLanguage) async {
    if (_isListening.value) {
      await _speech.stop();
      _isListening.value = false;
      _haptics.light();
      return;
    }

    _haptics.selection();
    try {
      final hasPerm = await _speech.initializeStt();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'translation.mic_permission_required',
                  fallback:
                      'Microphone permission is required for voice input.',
                ),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      _isListening.value = true;
      final langObj = TranslationService.supportedLanguages[sourceLanguage];
      final localeId = langObj?.bcpCode ?? 'en-US';

      await _speech.listen(
        localeId: localeId,
        onResult: (words, isFinal) {
          if (words.isNotEmpty && mounted) {
            final phrase = words.join(' ');
            _inputController.text = phrase;
            _inputController.selection = TextSelection.collapsed(
              offset: phrase.length,
            );
            _onInputChanged(phrase);
          }
        },
        onDone: () {
          if (mounted) _isListening.value = false;
        },
      );
    } catch (_) {
      if (mounted) _isListening.value = false;
    }
  }

  void _onSwapTapped(bool isPremium) {
    _haptics.selection();
    _focusNode.unfocus();
    setState(() {
      _swapTurns += 0.5;
    });
    final bloc = context.read<TranslationBloc>();
    final currentTranslated = bloc.state.translatedText;
    _inputController.text = currentTranslated;
    _inputController.selection = TextSelection.collapsed(
      offset: currentTranslated.length,
    );
    bloc.add(TranslationSwapLanguages(isPremium: isPremium));
  }

  bool _hasUserActivity(TranslationState state) {
    return _inputController.text.trim().isNotEmpty ||
        state.sourceText.trim().isNotEmpty ||
        state.translatedText.trim().isNotEmpty ||
        _isListening.value ||
        _isSourceSpeaking.value ||
        _isTargetSpeaking.value;
  }

  void _popSafely(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      } catch (_) {}
    }
  }

  void _handleExit(BuildContext context, TranslationState state) {
    FocusScope.of(context).unfocus();
    if (!_hasUserActivity(state)) {
      _haptics.light();
      _popSafely(context);
      return;
    }

    _haptics.light();
    GameDialogHelper.showExitConfirmation(
      context,
      title: context.tr(
        'translation.quit_title',
        fallback: 'QUIT TRANSLATION?',
      ),
      description: context.tr(
        'translation.quit_desc',
        fallback:
            'Your current translation will be lost. Are you sure you want to leave?',
      ),
      onQuit: () {
        _tts.stop();
        _speech.stop();
        _popSafely(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = context.watch<AuthBloc>().state.user?.isPremium ?? false;

    return BlocConsumer<TranslationBloc, TranslationState>(
      listener: (context, state) {
        // Sync input controller when swap happens or external reset occurs
        if (state.sourceText != _inputController.text && !_focusNode.hasFocus) {
          _inputController.text = state.sourceText;
          _inputController.selection = TextSelection.collapsed(
            offset: state.sourceText.length,
          );
        }
      },
      builder: (context, state) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            _inputController,
            _isListening,
            _isSourceSpeaking,
            _isTargetSpeaking,
          ]),
          builder: (context, _) {
            final hasActivity = _hasUserActivity(state);

            return PopScope(
              canPop: !hasActivity,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _handleExit(context, state);
              },
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: Scaffold(
                  backgroundColor: isDark ? AppColors.slate900 : Colors.white,
                  body: Stack(
                    children: [
                      const MeshGradientBackground(showLetters: false),
                      SafeArea(
                        child: Column(
                          children: [
                            _buildHeader(context, isDark, isPremium, state),
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: false,
                                radius: Radius.circular(8.r),
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(height: 12.h),
                                      _buildLanguageSelectorBar(
                                            context,
                                            isDark,
                                            isPremium,
                                          )
                                          .animate()
                                          .fadeIn(
                                            duration: 350.ms,
                                            curve: Curves.easeOut,
                                          )
                                          .slideY(
                                            begin: 0.08,
                                            end: 0,
                                            curve: Curves.easeOut,
                                          ),
                                      SizedBox(height: 16.h),
                                      _buildInputArea(
                                            context,
                                            isDark,
                                            isPremium,
                                          )
                                          .animate(delay: 80.ms)
                                          .fadeIn(
                                            duration: 350.ms,
                                            curve: Curves.easeOut,
                                          )
                                          .slideY(
                                            begin: 0.08,
                                            end: 0,
                                            curve: Curves.easeOut,
                                          ),
                                      SizedBox(height: 16.h),
                                      BlocBuilder<
                                            TranslationBloc,
                                            TranslationState
                                          >(
                                            builder: (context, state) {
                                              if (!isPremium &&
                                                  state.isLimitReached) {
                                                return PremiumLockCard(
                                                  onPremiumTap: () =>
                                                      context.push('/premium'),
                                                  onTap: () {
                                                    di.sl<AdService>().showRewardedAd(
                                                      context: context,
                                                      isPremium: false,
                                                      onUserEarnedReward: (_) {
                                                        context
                                                            .read<
                                                              TranslationBloc
                                                            >()
                                                            .add(
                                                              TranslationAdWatched(),
                                                            );
                                                      },
                                                      onDismissed: () {},
                                                    );
                                                  },
                                                );
                                              }
                                              return _buildOutputArea(
                                                context,
                                                isDark,
                                                isPremium,
                                              );
                                            },
                                          )
                                          .animate(delay: 150.ms)
                                          .fadeIn(
                                            duration: 350.ms,
                                            curve: Curves.easeOut,
                                          )
                                          .slideY(
                                            begin: 0.08,
                                            end: 0,
                                            curve: Curves.easeOut,
                                          ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(
                                              context,
                                            ).padding.bottom +
                                            32.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    bool isPremium,
    TranslationState state,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.tr('common.back', fallback: 'Back'),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleExit(context, state),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate100,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 18.r,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  context.tr('translation.title', fallback: 'Translate'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                ),
                Text(
                  context.tr(
                    'translation.offline_ready_badge',
                    fallback: '50+ languages • Works offline',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<TranslationBloc, TranslationState>(
            builder: (context, state) {
              if (isPremium) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.amber500,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.amber500,
                      size: 14.r,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '${state.freeTranslationsRemaining} free',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
          Semantics(
            button: true,
            label: context.tr(
              'translation.downloaded_packs',
              fallback: 'Downloaded Language Packs',
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLanguageManager(context, isDark),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate100,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20.r,
                    color: isDark ? Colors.white70 : AppColors.slate600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorBar(
    BuildContext context,
    bool isDark,
    bool isPremium,
  ) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        final source = state.currentSourceLanguage;
        final target =
            state.currentTargetLanguage ??
            context.tr(
              'translation.select_target_language',
              fallback: 'Select Target Language',
            );

        final isTargetReady = state.downloadedLanguages.contains(target);
        final isSourceReady =
            state.downloadedLanguages.contains(source) || source == 'English';

        return GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              // Source Pill
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showLanguagePicker(context, isDark, isSource: true),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.tr('translation.from', fallback: 'FROM'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.indigo500,
                                letterSpacing: 0.6,
                              ),
                            ),
                            if (isSourceReady) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 11.r,
                                color: AppColors.emerald500,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                source,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 16.r,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Swap Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: AnimatedRotation(
                  turns: _swapTurns,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onSwapTapped(isPremium),
                      borderRadius: BorderRadius.circular(24.r),
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 20.r,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Target Pill
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showLanguagePicker(context, isDark, isSource: false),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.tr('translation.to', fallback: 'TO'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald500,
                                letterSpacing: 0.6,
                              ),
                            ),
                            if (isTargetReady) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 11.r,
                                color: AppColors.emerald500,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                target,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 16.r,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, bool isDark, bool isPremium) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isFocused,
        builder: (context, focused, child) => GlassTile(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
          borderColor: focused
              ? AppColors.indigo500.withValues(alpha: 0.5)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate200.withValues(alpha: 0.8)),
          borderWidth: 1.2,
          child: child!,
        ),
        child: BlocBuilder<TranslationBloc, TranslationState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top control row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            state.currentSourceLanguage.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _inputController,
                      builder: (context, value, _) {
                        final isEmpty = value.text.isEmpty;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isEmpty) ...[
                              Text(
                                '${value.text.length}/$_maxCharacterLimit',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: value.text.length > _maxCharacterLimit
                                      ? AppColors.red500
                                      : (isDark
                                            ? Colors.white38
                                            : AppColors.slate400),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              ValueListenableBuilder<bool>(
                                valueListenable: _isSourceSpeaking,
                                builder: (context, speaking, _) {
                                  return IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 32.r,
                                      minHeight: 32.r,
                                    ),
                                    tooltip: 'Listen to input',
                                    onPressed: () => _speakText(
                                      text: value.text,
                                      languageName: state.currentSourceLanguage,
                                      isSource: true,
                                    ),
                                    icon: Icon(
                                      speaking
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_down_rounded,
                                      color: speaking
                                          ? AppColors.indigo500
                                          : (isDark
                                                ? Colors.white60
                                                : AppColors.slate500),
                                      size: 18.r,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 4.w),
                              InkWell(
                                onTap: () {
                                  _inputController.clear();
                                  context.read<TranslationBloc>().add(
                                    TranslationTextChanged(
                                      '',
                                      isPremium: isPremium,
                                    ),
                                  );
                                  _haptics.light();
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.slate100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.slate500,
                                    size: 14.r,
                                  ),
                                ),
                              ),
                            ],
                            if (isEmpty) ...[
                              ValueListenableBuilder<bool>(
                                valueListenable: _isListening,
                                builder: (context, listening, _) {
                                  return InkWell(
                                    onTap: () => _toggleVoiceDictation(
                                      state.currentSourceLanguage,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      margin: EdgeInsets.only(right: 8.w),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: listening
                                            ? AppColors.red500.withValues(
                                                alpha: 0.15,
                                              )
                                            : (isDark
                                                  ? Colors.white10
                                                  : AppColors.slate100),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: listening
                                            ? Border.all(
                                                color: AppColors.red500,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            listening
                                                ? Icons.mic_rounded
                                                : Icons.mic_none_rounded,
                                            color: listening
                                                ? AppColors.red500
                                                : (isDark
                                                      ? Colors.white70
                                                      : AppColors.slate600),
                                            size: 14.r,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            listening
                                                ? 'Listening...'
                                                : 'Voice',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: listening
                                                  ? AppColors.red500
                                                  : (isDark
                                                        ? Colors.white70
                                                        : AppColors.slate600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              InkWell(
                                onTap: () async {
                                  final data = await Clipboard.getData(
                                    'text/plain',
                                  );
                                  if (data != null &&
                                      (data.text?.isNotEmpty ?? false)) {
                                    _inputController.text = data.text!;
                                    _inputController.selection =
                                        TextSelection.collapsed(
                                          offset: data.text!.length,
                                        );
                                    _onInputChanged(data.text!);
                                    _haptics.light();
                                  }
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : AppColors.slate100,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.paste_rounded,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.slate600,
                                        size: 14.r,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr(
                                          'common.paste',
                                          fallback: 'Paste',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  onChanged: _onInputChanged,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _triggerImmediateTranslation(),
                  maxLines: null,
                  minLines: 3,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr(
                      'translation.type_to_translate',
                      fallback: 'Type something to translate...',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : AppColors.slate400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 4.w,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _inputController,
                  builder: (context, value, _) {
                    if (value.text.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: TextButton.icon(
                          onPressed: _triggerImmediateTranslation,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            backgroundColor: AppColors.indigo500.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14.r,
                            color: AppColors.indigo500,
                          ),
                          label: Text(
                            context.tr(
                              'common.translate',
                              fallback: 'Translate',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOutputArea(BuildContext context, bool isDark, bool isPremium) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        final targetLang = state.currentTargetLanguage ?? 'Spanish';

        return GlassTile(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.slate200.withValues(alpha: 0.8),
          borderWidth: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      targetLang.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isTranslating)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child:
                              Text(
                                    context.tr(
                                      'translation.translating',
                                      fallback: 'Translating...',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.emerald500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(duration: 900.ms),
                        ),
                      if (state.translatedText.isNotEmpty &&
                          !state.isTranslating) ...[
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTargetSpeaking,
                          builder: (context, speaking, _) {
                            return IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 32.r,
                                minHeight: 32.r,
                              ),
                              tooltip: 'Listen to translation',
                              onPressed: () => _speakText(
                                text: state.translatedText,
                                languageName: targetLang,
                                isSource: false,
                              ),
                              icon: Icon(
                                speaking
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_down_rounded,
                                color: speaking
                                    ? AppColors.emerald500
                                    : (isDark
                                          ? Colors.white60
                                          : AppColors.slate500),
                                size: 18.r,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: state.translatedText),
                            );
                            _haptics.success();
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr(
                                      'common.copied',
                                      fallback: 'Copied to clipboard',
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.emerald500,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr('common.copy', fallback: 'Copy'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.emerald500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Content Body
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.red500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.red500.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 16.r,
                            color: AppColors.red500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              context.tr(
                                state.errorMessage!,
                                fallback: state.errorMessage!,
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                color: AppColors.red500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      TextButton.icon(
                        onPressed: () {
                          _haptics.light();
                          context.read<TranslationBloc>().add(
                            TranslationRetryRequested(isPremium: isPremium),
                          );
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 14.r,
                          color: AppColors.red500,
                        ),
                        label: Text(
                          context.tr('common.retry', fallback: 'Retry'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.isModelDownloading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'translation.downloading_pack',
                        fallback: 'Downloading offline language pack...',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark ? Colors.white70 : AppColors.slate600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        backgroundColor: isDark
                            ? Colors.white10
                            : AppColors.slate200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.emerald500,
                        ),
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: SelectableText(
                    state.translatedText.isEmpty
                        ? context.tr(
                            'translation.translation_placeholder',
                            fallback: 'Translation will appear here.',
                          )
                        : state.translatedText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: state.translatedText.isEmpty
                          ? (isDark ? Colors.white38 : AppColors.slate400)
                          : (Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
