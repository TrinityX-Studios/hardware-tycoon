import 'package:flutter/material.dart';
import 'versioning.dart';

/// A mixin that grants class structures easy access to the build version diagnostics.
mixin VersioningAware {
  String get appVersionDisplay => AppVersion.displayVersion;
  bool get isReleaseBuild => AppVersion.isRelease;
  bool get isDebugBuild => AppVersion.isDebug;
  Map<String, String> get buildDiagnostics => AppVersion.diagnostics;
}

/// A compact, terminal-themed watermark widget that aligns with the game's dark industrial theme.
class VersionWatermark extends StatelessWidget with VersioningAware {
  final Color? color;
  final double fontSize;

  const VersionWatermark({
    super.key,
    this.color,
    this.fontSize = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? const Color(0xFF64748B); // Slate-500 (textMuted)

    return Text(
      'v$appVersionDisplay // CORE OK',
      style: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: fontSize,
        color: displayColor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
