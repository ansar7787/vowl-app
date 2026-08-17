import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

class TranslationBottomSheet extends StatelessWidget {
  final String textToTranslate;
  final bool isDark;

  const TranslationBottomSheet({
    super.key,
    required this.textToTranslate,
    required this.isDark,
  });

  static Future<void> show({
    required BuildContext context,
    required String text,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Auto-remove any trailing punctuation to get clean translations for words
    final cleanText = text.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
    if (cleanText.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (context) => di.sl<TranslationBloc>()
          ..add(TranslationInitRequested())
          ..add(TranslationTextChanged(cleanText)),
        child: TranslationBottomSheet(
          textToTranslate: cleanText,
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Source Text
          Text(
            textToTranslate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Target Language Indicator
          BlocBuilder<TranslationBloc, TranslationState>(
            builder: (context, state) {
              if (state.currentTargetLanguage == null && !state.isModelDownloading) {
                return Text(
                  'Please select a language in the Translate tab first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: const Color(0xFFEF4444),
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Icon(Icons.arrow_forward_rounded, size: 16.r, color: const Color(0xFF10B981)),
                      ),
                      Text(
                        state.currentTargetLanguage ?? '...',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Translation Result
                  GlassTile(
                    padding: EdgeInsets.all(20.r),
                    borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildResultContent(state, isDark),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(TranslationState state, bool isDark) {
    if (state.status == TranslationStatus.loading || state.isModelDownloading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: const CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }
    
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      return Text(
        state.errorMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          color: const Color(0xFFEF4444),
        ),
      );
    }
    
    return Text(
      state.translatedText.isEmpty ? '...' : state.translatedText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: state.translatedText.isEmpty 
            ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
            : (isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
    );
  }
}
