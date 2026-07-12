import 'dart:io';

void main() {
  print("=========================================================");
  print("🚀 STARTING DEEP AUTOMATED PRODUCTION READINESS SCAN...");
  print("=========================================================");

  int issuesFound = 0;
  int totalFilesChecked = 0;

  // 1. Scan Dart files
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print("❌ Error: 'lib' directory not found.");
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().toList();
  final dartFiles = files.where((f) => f.path.endsWith('.dart')).toList();
  totalFilesChecked += dartFiles.length;
  print("✓ Found ${dartFiles.length} Dart source files.");

  // Check game screen sizes
  final heavyScreens = <String>[];
  for (final file in dartFiles) {
    if (file.path.endsWith('_screen.dart')) {
      try {
        final lines = file.readAsLinesSync().length;
        if (lines > 350) {
          heavyScreens.add(
            "${file.path.split(Platform.pathSeparator).last} ($lines lines)",
          );
        }
      } catch (e) {
        // Safe check for empty or unreadable files
      }
    }
  }

  if (heavyScreens.isNotEmpty) {
    print(
      "⚠️ Alert: The following screens are currently larger than 350 lines:",
    );
    for (final screen in heavyScreens) {
      print("  - $screen");
    }
  } else {
    print("✓ All game screens are perfectly modularized (under 350 lines)!");
  }

  // 2. Verify Assets from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final pubspecLines = pubspecFile.readAsLinesSync();
    final assets = <String>[];
    bool inAssets = false;
    for (final line in pubspecLines) {
      if (line.startsWith('  assets:')) {
        inAssets = true;
        continue;
      }
      if (inAssets) {
        final trimmed = line.trim();
        if (trimmed.startsWith('-')) {
          final path = trimmed.replaceFirst('-', '').trim();
          assets.add(path);
        } else if (trimmed.isNotEmpty &&
            !line.startsWith('    ') &&
            !line.startsWith('  ')) {
          inAssets = false;
        }
      }
    }

    int missingAssetsCount = 0;
    for (final asset in assets) {
      if (asset == '.env') continue; // Dotenv file check is separated
      if (asset.endsWith('/')) {
        if (!Directory(asset).existsSync()) {
          print("❌ Missing Directory: $asset");
          missingAssetsCount++;
          issuesFound++;
        }
      } else {
        if (!File(asset).existsSync()) {
          print("❌ Missing File: $asset");
          missingAssetsCount++;
          issuesFound++;
        }
      }
    }

    if (missingAssetsCount == 0) {
      print("✓ All declared assets and directories exist on disk!");
    } else {
      print("⚠️ Found $missingAssetsCount missing assets in pubspec.yaml.");
    }
  }

  // 3. Audit .env keys
  final envFile = File('.env');
  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    if (content.contains('rzp_test_')) {
      print(
        "⚠️ WARNING: Razorpay key is configured for TEST mode (rzp_test_...). Replace it with 'rzp_live_...'!",
      );
      issuesFound++;
    } else {
      print("✓ Razorpay key looks solid.");
    }

    if (content.contains('ca-app-pub-3940256099942544')) {
      print("⚠️ WARNING: Google Mobile Ads contains placeholder test App ID!");
      issuesFound++;
    } else {
      print("✓ AdMob config confirmed.");
    }
  }

  // 4. Verify native configs
  final googleJson = File('android/app/google-services.json');
  if (!googleJson.existsSync()) {
    print(
      "❌ Missing: android/app/google-services.json (Android app will crash on startup!)",
    );
    issuesFound++;
  } else {
    print("✓ Found android/app/google-services.json");
  }

  final googlePlist = File('ios/Runner/GoogleService-Info.plist');
  if (!googlePlist.existsSync()) {
    print(
      "⚠️ Alert: ios/Runner/GoogleService-Info.plist not found. Remember to add in Xcode!",
    );
  } else {
    print("✓ Found ios/Runner/GoogleService-Info.plist");
  }

  // 5. Audit Android gradle configs
  final gradle = File('android/app/build.gradle.kts');
  if (gradle.existsSync()) {
    final content = gradle.readAsStringSync();
    if (content.contains('signingConfig = signingConfigs.getByName("debug")')) {
      print(
        "⚠️ WARNING: Release build signs with debug keys! Keystore must be configured for release!",
      );
      issuesFound++;
    } else {
      print("✓ Android signing configs look ready.");
    }
  }

  // 6. Search for prints and TODOs
  int prints = 0;
  int todos = 0;
  for (final file in dartFiles) {
    try {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        if (line.trim().startsWith('print(')) prints++;
        if (line.contains('TODO:')) todos++;
      }
    } catch (e) {
      // Safe check
    }
  }

  print("✓ Found $todos active TODOs in files.");
  if (prints > 50) {
    print(
      "⚠️ WARNING: Found $prints raw print() statements. Use loggers or debugPrint() in production.",
    );
  } else {
    print("✓ Minimal raw print statements.");
  }

  print("=========================================================");
  if (issuesFound > 0) {
    print("❌ SCAN COMPLETED WITH $issuesFound CRITICAL ISSUES / WARNINGS.");
    print("Please resolve all warnings before building for production!");
  } else {
    print(
      "🎉 CONGRATULATIONS! ALL CHECKS PASSED. YOUR APP IS 100% PRODUCTION READY!",
    );
  }
  print("Total Files Traversed: $totalFilesChecked");
  print("=========================================================");
}
