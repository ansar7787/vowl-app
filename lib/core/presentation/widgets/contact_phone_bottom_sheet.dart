import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Formatter that strips non-digits and isolates a clean 10-digit Indian phone number.
class IndiaPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Bottom sheet dialog prompting the user for a phone number for UPI/payment processing.
class ContactPhoneBottomSheet extends StatefulWidget {
  const ContactPhoneBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const ContactPhoneBottomSheet(),
    );
  }

  @override
  State<ContactPhoneBottomSheet> createState() =>
      _ContactPhoneBottomSheetState();
}

class _ContactPhoneBottomSheetState extends State<ContactPhoneBottomSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isValid = _controller.text.trim().length == 10;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final safeBottom =
        (systemBottomPadding > 0 ? systemBottomPadding : 24.h) +
        bottomInset +
        12.h;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: 20.h,
        bottom: safeBottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? (context.isMidnight
                  ? AppColors.midnightSurface
                  : const Color(0xFF0F172A))
            : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.slate200,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.slate300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.indigo500,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'premium.contact_prompt_title',
                            fallback: 'UPI & Payment Mobile Number',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.tr(
                            'premium.contact_prompt_subtitle',
                            fallback:
                                'Razorpay requires your phone number for UPI routing and receipts.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofocus: true,
                cursorColor: AppColors.indigo500,
                cursorWidth: 2.2,
                cursorRadius: Radius.circular(2.r),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  IndiaPhoneInputFormatter(),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (isValid) {
                    Navigator.of(context).pop(_controller.text.trim());
                  }
                },
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.slate100,
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    color: isValid
                        ? AppColors.indigo500
                        : (isDark ? Colors.white38 : AppColors.slate400),
                    size: 20.sp,
                  ),
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: 0.5,
                  ),
                  hintText: 'Enter 10-digit number',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white30 : AppColors.slate400,
                    letterSpacing: 0.2,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 18.sp,
                            color: isDark ? Colors.white38 : AppColors.slate400,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: isValid
                          ? AppColors.indigo500
                          : (isDark ? Colors.white12 : AppColors.slate200),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: AppColors.indigo500,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              ScaleButton(
                onTap: isValid
                    ? () {
                        Navigator.of(context).pop(_controller.text.trim());
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: isValid
                        ? const LinearGradient(
                            colors: [AppColors.indigo500, AppColors.violet500],
                          )
                        : null,
                    color: isValid
                        ? null
                        : (isDark ? Colors.white12 : AppColors.slate200),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: isValid
                        ? [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr(
                      'premium.continue_to_payment',
                      fallback: 'Proceed to Payment Options',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isValid
                          ? Colors.white
                          : (isDark ? Colors.white38 : AppColors.slate400),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop('');
                  },
                  child: Text(
                    context.tr(
                      'common.skip',
                      fallback: 'Skip and enter inside payment gateway',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : AppColors.slate500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
