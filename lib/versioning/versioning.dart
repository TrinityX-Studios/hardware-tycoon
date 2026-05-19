import 'package:flutter/foundation.dart';

/// Manages dynamic compile-time version retrieval via --dart-define parameters.
class AppVersion {
  static const String buildType = String.fromEnvironment(
    'BUILD_TYPE',
    defaultValue: 'debug',
  );

  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'unknown',
  );

  static const String gitTag = String.fromEnvironment(
    'GIT_TAG',
    defaultValue: 'v1.0.0-alpha.1',
  );

  static const String buildTime = String.fromEnvironment(
    'BUILD_TIME',
    defaultValue: 'unknown',
  );

  /// Returns true if this is a production release build.
  static bool get isRelease => buildType == 'release';

  /// Returns true if this is a debug build.
  static bool get isDebug => buildType == 'debug';

  /// The dynamic version string based on build rules:
  /// - debug builds: bound to the commit hash (e.g. `v1.0.0-alpha.1+debug.3a5f8c`)
  /// - release builds: bound strictly to the tag (e.g. `v1.0.0-alpha.1`)
  static String get displayVersion {
    if (isRelease) {
      return gitTag;
    } else {
      // For debug builds, bind dynamically to the commit hash/ID.
      final shortCommit = gitCommit.length > 7 ? gitCommit.substring(0, 7) : gitCommit;
      return '$gitTag+debug.$shortCommit';
    }
  }

  /// Full diagnostic details about the build.
  static Map<String, String> get diagnostics => {
        'BUILD_TYPE': buildType,
        'COMMIT': gitCommit,
        'TAG': gitTag,
        'BUILD_TIME': buildTime,
        'RAW_PLATFORM': defaultTargetPlatform.name,
      };
}
