import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';
import 'package:vowl/features/translation/presentation/widgets/language_manager_sheet.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/presentation/widgets/premium_lock_card.dart';

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
  final ValueNotifier<bool> _isFocused = ValueNotifier(false);
  Timer? _debounce;

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
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
      context.read<TranslationBloc>().add(
        TranslationTextChanged(text, isPremium: isPremium),
      );
    });
  }

  void _showLanguagePicker(BuildContext context, bool isDark) {
    _haptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final blocState = context.read<TranslationBloc>().state;
        return _LanguagePickerSheet(
          isDark: isDark,
          currentLanguage: blocState.currentTargetLanguage,
          downloadedLanguages: blocState.downloadedLanguages,
          onSelected: (lang) {
            context.read<TranslationBloc>().add(TranslationLanguageChanged(lang));
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  void _showLanguageManager(BuildContext context, bool isDark) {
    _haptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<TranslationBloc>(),
        child: LanguageManagerSheet(isDark: isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = context.watch<AuthBloc>().state.user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    radius: Radius.circular(8.r),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 16.h),
                          _buildLanguageSelector(context, isDark, isPremium)
                              .animate()
                              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                          SizedBox(height: 16.h),
                          _buildInputArea(context, isDark, isPremium)
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                          SizedBox(height: 16.h),
                          BlocBuilder<TranslationBloc, TranslationState>(
                            builder: (context, state) {
                              if (!isPremium && state.isLimitReached) {
                                return PremiumLockCard(
                                  onPremiumTap: () => context.push('/premium'),
                                  onTap: () {
                                    di.sl<AdService>().showRewardedAd(
                                      context: context,
                                      isPremium: false,
                                      onUserEarnedReward: (_) {
                                        context.read<TranslationBloc>().add(
                                          TranslationAdWatched(),
                                        );
                                      },
                                      onDismissed: () {},
                                    );
                                  },
                                );
                              }
                              return _buildOutputArea(context, isDark);
                            },
                          )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 24.h),
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
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AutoSizeText(
              context.tr('translation.title', fallback: 'Translate'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
            ),
          ),
          IconButton(
            onPressed: () => _showLanguageManager(context, isDark),
            icon: Icon(
              Icons.settings_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    bool isDark,
    bool isPremium,
  ) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        final lang =
            state.currentTargetLanguage ??
            context.tr(
              'translation.select_target_language',
              fallback: 'Select Language',
            );
        return GestureDetector(
          onTap: () => _showLanguagePicker(context, isDark),
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    color: const Color(0xFF6366F1),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'translation.english_arrow',
                          fallback: 'English →',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      AutoSizeText(
                        lang,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ],
            ),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          borderColor: focused
              ? const Color(0xFF6366F1).withValues(alpha: 0.5)
              : null,
          borderWidth: focused ? 2.0 : null,
          child: child!,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr(
                        'translation.english_caps',
                        fallback: 'ENGLISH',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6366F1),
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (!isPremium) ...[
                      SizedBox(width: 12.w),
                      BlocBuilder<TranslationBloc, TranslationState>(
                        builder: (context, state) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 12.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${state.freeTranslationsRemaining} LEFT',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (_inputController.text.isEmpty)
                      GestureDetector(
                        onTap: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null && (data.text?.isNotEmpty ?? false)) {
                            _inputController.text = data.text!;
                            _inputController.selection = TextSelection.collapsed(
                              offset: data.text!.length,
                            );
                            _onInputChanged(data.text!);
                            _haptics.light();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.paste_rounded,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                size: 14.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                context.tr('common.paste', fallback: 'Paste'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms),
                    if (_inputController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _inputController.clear();
                          context.read<TranslationBloc>().add(
                            TranslationTextChanged('', isPremium: isPremium),
                          );
                          _haptics.light();
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            size: 16.r,
                          ),
                        ),
                      ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _inputController,
              focusNode: _focusNode,
              onChanged: _onInputChanged,
              maxLines: null, // Allows infinite expansion
              minLines: 3,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: context.tr(
                  'translation.type_to_translate',
                  fallback: 'Type something to translate...',
                ),
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 8.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputArea(BuildContext context, bool isDark) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        return GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          borderWidth: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state.currentTargetLanguage?.toUpperCase() ??
                        context.tr(
                          'translation.translation_caps',
                          fallback: 'TRANSLATION',
                        ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      if (state.isTranslating)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Text(
                            context.tr('translation.translating', fallback: 'Translating...'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1.seconds),
                        ),
                      if (state.isModelDownloading)
                        SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      if (state.translatedText.isNotEmpty && !state.isTranslating)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: state.translatedText));
                            _haptics.success();
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('common.copied', fallback: 'Copied to clipboard'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr('common.copy', fallback: 'Copy'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 200.ms),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                Text(
                  context.tr(
                    state.errorMessage!,
                    fallback: state.errorMessage!,
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: const Color(0xFFEF4444),
                  ),
                )
              else if (state.isModelDownloading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'translation.downloading_pack',
                        fallback:
                            'Downloading offline language pack (~30MB)...',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    LinearProgressIndicator(
                      backgroundColor: isDark
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: SelectableText(
                    state.translatedText.isEmpty
                        ? context.tr(
                            'translation.translation_placeholder',
                            fallback: 'Translation will appear here.',
                          )
                        : state.translatedText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: state.translatedText.isEmpty
                          ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
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

class _LanguagePickerSheet extends StatefulWidget {
  final bool isDark;
  final Function(String) onSelected;
  final String? currentLanguage;
  final List<String> downloadedLanguages;

  const _LanguagePickerSheet({
    required this.isDark,
    required this.onSelected,
    this.currentLanguage,
    this.downloadedLanguages = const [],
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLanguages = [];
  List<String> _allLanguages = [];

  @override
  void initState() {
    super.initState();
    _allLanguages = TranslationService.supportedLanguages.keys.toList()..sort();
    _filteredLanguages = List.from(_allLanguages);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = List.from(_allLanguages);
      } else {
        _filteredLanguages = _allLanguages
            .where((lang) => lang.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            context.tr(
              'translation.select_target_language',
              fallback: 'Select Target Language',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 16.h),
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('common.search', fallback: 'Search'),
                        hintStyle: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        size: 18.r,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: _filteredLanguages.isEmpty
                ? Center(
                    child: Text(
                      context.tr('language_picker.no_results', fallback: 'No results found'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = _filteredLanguages[index];
                      final isActive = lang == widget.currentLanguage;
                      final isDownloaded = widget.downloadedLanguages.contains(lang);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onSelected(lang),
                            borderRadius: BorderRadius.circular(16.r),
                            splashColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                            highlightColor: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                                border: isActive
                                    ? Border.all(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lang,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16.sp,
                                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                        color: isActive
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                      ),
                                    ),
                                  ),
                                  if (isDownloaded)
                                    Container(
                                      margin: EdgeInsets.only(right: 8.w),
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        context.tr('common.ready', fallback: 'READY'),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  if (isActive)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: const Color(0xFF6366F1),
                                      size: 20.r,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
