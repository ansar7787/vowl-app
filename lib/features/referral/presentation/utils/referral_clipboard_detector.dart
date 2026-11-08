import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_claim_dialog.dart';

class ReferralClipboardDetector {
  ReferralClipboardDetector._();

  static final RegExp _kCodePattern = RegExp(
    r'VOWL-[A-Za-z0-9]{4,12}',
    caseSensitive: false,
  );
  static String? _lastDetectedCode;

  /// Checks the system clipboard for a Vowl referral code or invite message.
  /// If found, and the user hasn't claimed a referral yet, prompts a claim dialog.
  static Future<void> checkAndPrompt({
    required BuildContext context,
    required UserEntity user,
    required Function(String code) onClaim,
  }) async {
    if (user.hasClaimedReferral) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();

      if (text == null || text.isEmpty) return;

      final match = _kCodePattern.firstMatch(text);
      if (match != null) {
        final code = match.group(0)!.toUpperCase();
        if (code == _lastDetectedCode) return;
        if (user.referralCode != null &&
            user.referralCode!.toUpperCase() == code)
          return;

        _lastDetectedCode = code;

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (dialogContext) => ReferralClaimDialog(
            initialCode: code,
            onClaim: (submittedCode) {
              Navigator.of(dialogContext).pop();
              onClaim(submittedCode);
            },
          ),
        );
      }
    } catch (_) {
      // Ignore clipboard read errors gracefully
    }
  }
}
