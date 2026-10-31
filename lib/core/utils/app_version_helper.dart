/// Utility class for parsing and comparing semantic versions (e.g., "1.0.0", "1.0.1+4").
class AppVersionHelper {
  AppVersionHelper._();

  /// Compares two version strings [v1] and [v2].
  ///
  /// Returns:
  /// - A positive integer if [v1] > [v2]
  /// - A negative integer if [v1] < [v2]
  /// - 0 if [v1] == [v2]
  ///
  /// Ignores leading 'v' or 'V' prefixes and build metadata following '+'.
  static int compare(String v1, String v2) {
    final clean1 = _cleanVersion(v1);
    final clean2 = _cleanVersion(v2);

    final parts1 = clean1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final parts2 = clean2.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }

    return 0;
  }

  /// Returns true if [remoteVersion] is strictly newer than [currentVersion].
  static bool isUpdateAvailable(String currentVersion, String remoteVersion) {
    if (remoteVersion.trim().isEmpty) return false;
    return compare(remoteVersion, currentVersion) > 0;
  }

  /// Returns true if [currentVersion] is strictly below the required [minVersion].
  static bool isBelowMinVersion(String currentVersion, String minVersion) {
    if (minVersion.trim().isEmpty) return false;
    return compare(minVersion, currentVersion) > 0;
  }

  /// Strips leading 'v', build metadata ('+3'), and leading/trailing whitespace.
  static String cleanDisplayVersion(String version) {
    return _cleanVersion(version);
  }

  static String _cleanVersion(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1).trim();
    }
    // Remove build metadata e.g. "+3"
    if (s.contains('+')) {
      s = s.split('+').first.trim();
    }
    return s.isEmpty ? '0.0.0' : s;
  }
}

