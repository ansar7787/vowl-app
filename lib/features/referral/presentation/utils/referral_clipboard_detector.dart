import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_claim_dialog.dart';

class ReferralClipboardDetector {
  ReferralClipboardDetector._();

  static final RegExp _kCodePattern = RegExp(r'^VOWL-[A-Za-z0-9]{4,12}$');
  static String? _lastDetectedCode;

  /// Checks the system clipboard for a Vowl referral code.
  /// If found, and the user hasn't claimed a referral yet, prompts a dialog.
  static Future<void> checkAndPrompt({
    required BuildContext context,
    required UserEntity user,
    required Function(String code) onClaim,
  }) async {
    if (user.hasClaimedReferral) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim().toUpperCase();

      if (text == null || text.isEmpty) return;
      if (text == _lastDetectedCode) return;
      if (user.referralCode != null && user.referralCode!.toUpperCase() == text) return;

      if (_kCodePattern.hasMatch(text)) {
        _lastDetectedCode = text;

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (dialogContext) => ReferralClaimDialog(
            initialCode: text,
            onClaim: (code) {
              Navigator.of(dialogContext).pop();
              onClaim(code);
            },
          ),
        );
      }
    } catch (_) {
      // Ignore clipboard read errors gracefully
    }
  }
}
