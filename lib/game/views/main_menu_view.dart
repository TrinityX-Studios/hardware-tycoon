/// Hardware Tycoon — Main Menu View
///
/// A minimalist, industrial-themed entry point for the application.
/// Provides options to start a new simulation, restore a session, or exit.
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import '../../versioning/versioning_aware.dart';
import '../managers/audio_manager.dart';

class MainMenuView extends StatelessWidget {
  final AppStateMachine appState;

  const MainMenuView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HTColors.background,
      body: Stack(
        children: [
          // Background graphic elements (e.g., subtle blueprint lines)
          _buildBackgroundLines(),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Huge retro-tech title
                Text(
                  'Hardware Tycoon',
                  style: HTTypography.statLarge.copyWith(
                    fontSize: 64.0,
                    letterSpacing: 8.0,
                    shadows: [
                      const BoxShadow(
                        color: HTColors.primaryGlow,
                        blurRadius: 20.0,
                        spreadRadius: 5.0,
                      ),
                    ],
                  ),
                ),
                Text(
                  '1 9 6 0',
                  style: HTTypography.metricValue.copyWith(
                    color: HTColors.textSecondary,
                    fontSize: 24.0,
                    letterSpacing: 24.0,
                  ),
                ),

                const SizedBox(height: 80.0),

                // Menu Options
                _MenuButton(
                  label: 'BEGIN INITIALIZATION',
                  icon: Icons.power_settings_new,
                  onTap: () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    appState.goToSetup();
                  },
                  isPrimary: true,
                ),
                const SizedBox(height: 16.0),

                _MenuButton(
                  label: 'RESTORE SESSION',
                  icon: Icons.restore,
                  onTap: () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    appState.goToSessionSlots();
                  },
                ),
                const SizedBox(height: 16.0),

                _MenuButton(
                  label: 'TERMINAL SETTINGS',
                  icon: Icons.settings,
                  onTap: () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    appState.goToSettings();
                  },
                ),
                const SizedBox(height: 16.0),

                _MenuButton(
                  label: 'ABOUT SYSTEM',
                  icon: Icons.info_outline,
                  onTap: () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    appState.goToAbout();
                  },
                ),
                const SizedBox(height: 16.0),

                _MenuButton(
                  label: 'EXIT CORE',
                  icon: Icons.exit_to_app,
                  onTap: () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else {
                      exit(0);
                    }
                  },
                ),
              ],
            ),
          ),

          // Version tag
          Positioned(
            bottom: 16.0,
            right: 24.0,
            child: VersionWatermark(
              color: HTColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLines() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: CustomPaint(painter: _GridBackgroundPainter()),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.isPrimary
        ? HTColors.primary
        : HTColors.textSecondary;
    final hoverColor = widget.isPrimary
        ? HTColors.primary
        : HTColors.textPrimary;
    final borderColor = widget.isPrimary ? HTColors.primary : HTColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 300.0,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isPrimary
                      ? HTColors.primary.withValues(alpha: 0.1)
                      : HTColors.surfaceVariant)
                : HTColors.surface,
            border: Border.all(
              color: _isHovered ? hoverColor : borderColor,
              width: 1.0,
            ),
            boxShadow: _isHovered && widget.isPrimary
                ? [
                    BoxShadow(
                      color: HTColors.primaryGlow,
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? hoverColor : defaultColor,
                size: 18.0,
              ),
              const SizedBox(width: 12.0),
              Text(
                widget.label,
                style: HTTypography.panelHeader.copyWith(
                  color: _isHovered ? hoverColor : defaultColor,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HTColors.primary
      ..strokeWidth = 1.0;

    // Draw a sparse grid
    for (double x = 0; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
