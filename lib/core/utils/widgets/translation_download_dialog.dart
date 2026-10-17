import 'package:flutter/material.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/widgets/translation_download_sheet.dart';

/// DRY forwarder ensuring all translation downloads use the unified TranslationDownloadSheet.
class TranslationDownloadDialog {
  TranslationDownloadDialog._();

  static Future<void> show(BuildContext context) async {
    return TranslationDownloadSheet.show(
      context,
      di.sl<TranslationService>().ensureModelDownloaded(),
    );
  }
}
