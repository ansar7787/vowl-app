import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A simple parental gate dialog that requires solving a basic math problem
/// before allowing access to real-money purchase flows from Kids Zone.
///
/// This prevents children from accidentally initiating purchases without
/// adult involvement. Required for COPPA compliance and App Store policies.
///
/// ### Usage
/// ```dart
/// final passed = await ParentalGateDialog.show(context);
/// if (passed) {
///   // Proceed with purchase flow
/// }
/// ```
class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  /// Shows the parental gate and returns `true` if the adult correctly
  /// answers the math challenge, `false` otherwise.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ParentalGateDialog(),
    );
    return result ?? false;
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late final int _a;
  late final int _b;
  late final int _answer;
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // Generate a multiplication problem that a young child wouldn't know
    // but an adult can easily solve (e.g. 7 × 8 = 56).
    _a = rng.nextInt(6) + 5; // 5–10
    _b = rng.nextInt(6) + 5; // 5–10
    _answer = _a * _b;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = 'Incorrect answer. Please try again.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'Parental Verification',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This area contains real purchases. '
            'Please ask a parent or guardian to solve this:',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'What is $_a × $_b?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: 'Enter answer',
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            onSubmitted: (_) => _onSubmit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _onSubmit, child: const Text('Verify')),
      ],
    );
  }
}
