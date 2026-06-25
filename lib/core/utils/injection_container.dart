import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:vowl/core/utils/di/di_core.dart';
import 'package:vowl/core/utils/di/di_auth.dart';
import 'package:vowl/core/utils/di/di_features.dart';

export 'package:vowl/core/utils/di/di_core.dart';
export 'package:vowl/core/utils/di/di_auth.dart';
export 'package:vowl/core/utils/di/di_features.dart';

final sl = GetIt.instance;

/// Central Dependency Injection container coordinator for Vowl.
///
/// Orchestrates the division of registers across core services,
/// auth features, and quest-specific learning features, keeping
/// main package boundaries clean, cohesive, and SRP-compliant.
Future<void> init() async {
  try {
    await initExternalAndCore(sl);
    initAuthFeature(sl);
    initFeatures(sl);
  } catch (e, stackTrace) {
    // A DI bootstrap failure is fatal to the app either way, but logging
    // which stage failed (and the full stack trace) before rethrowing
    // gives crash reporting something actionable instead of just an
    // opaque "app failed to start" with no context.
    if (kDebugMode) {
      debugPrint('DI bootstrap failed during init(): $e\n$stackTrace');
    }
    rethrow;
  }
}
