/// Hardware Tycoon — About & Credits Terminal View
///
/// A premium monospaced dark-terminal display outlining the game summary,
/// project licensing, and credits for music and sound effect composers.
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import '../../versioning/versioning.dart';

class AboutAndCreditsView extends StatelessWidget {
  final AppStateMachine appState;

  const AboutAndCreditsView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HTColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: HTColors.primary,
                    onPressed: () => appState.goToMainMenu(),
                  ),
                  const SizedBox(width: 16.0),
                  Text('ABOUT SYSTEM', style: HTTypography.statMedium),
                  const Spacer(),
                  Text(
                    AppVersion.displayVersion,
                    style: HTTypography.metricLabel.copyWith(color: HTColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              const Divider(color: HTColors.border, height: 1.0),

              const SizedBox(height: 24.0),

              // Scrollable content body
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game header block
                          _buildTerminalBlock(
                            header: 'SYSTEM IDENTIFICATION',
                            icon: Icons.memory,
                            children: [
                              _buildCrtLine('PROJECT', 'Hardware Tycoon 1960'),
                              _buildCrtLine('TYPE', 'Real-Time Industrial Strategy Simulation'),
                              _buildCrtLine('ENGINE', 'Flutter / Dart'),
                              _buildCrtLine('VERSION', AppVersion.displayVersion),
                              const SizedBox(height: 12.0),
                              const Text(
                                'Build and manage a semiconductor empire from the '
                                'dawn of the transistor era. Design chip architectures, '
                                'navigate the historical technology tree, manage foundry '
                                'operations, and compete in the evolving hardware market.',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 11.0,
                                  color: HTColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24.0),

                          // License block
                          _buildTerminalBlock(
                            header: 'LICENSE & COMPLIANCE',
                            icon: Icons.gavel,
                            accentColor: HTColors.warning,
                            children: [
                              const Text(
                                'This software is provided as-is for educational and '
                                'entertainment purposes. All third-party assets are '
                                'used under their respective licenses as credited below.',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 10.0,
                                  color: HTColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: HTColors.warning.withValues(alpha: 0.05),
                                  border: Border.all(color: HTColors.warning.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                child: const Text(
                                  '[ ! ] All music tracks are licensed under Creative Commons. '
                                  'Redistribution must comply with the original license terms.',
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 9.0,
                                    color: HTColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24.0),

                          // Music Credits
                          _buildTerminalBlock(
                            header: 'MUSIC CREDITS',
                            icon: Icons.music_note,
                            accentColor: HTColors.secondary,
                            children: [
                              _buildCreditEntry(
                                title: 'Kevin MacLeod',
                                subtitle: 'Incompetech',
                                tracks: [
                                  _TrackInfo('Bleeping Demo', 'https://youtu.be/F83jrB_2irM'),
                                  _TrackInfo('Laser Groove', 'https://youtu.be/GImBmTwBV1s'),
                                  _TrackInfo('Voltaic', 'https://youtu.be/2M7_r3P1naU'),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24.0),

                          // Sound Effects Credits
                          _buildTerminalBlock(
                            header: 'SOUND EFFECTS CREDITS',
                            icon: Icons.surround_sound,
                            accentColor: HTColors.success,
                            children: [
                              _buildCreditEntry(
                                title: 'Synthesized Audio',
                                subtitle: 'Procedurally Generated',
                                tracks: [
                                  _TrackInfo('click.wav', 'Mechanical button click'),
                                  _TrackInfo('error.wav', 'Dual-tone warning buzzer'),
                                  _TrackInfo('success.wav', 'Arpeggiated confirmation chime'),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24.0),

                          // Development credits
                          _buildTerminalBlock(
                            header: 'DEVELOPMENT',
                            icon: Icons.code,
                            accentColor: HTColors.info,
                            children: [
                              _buildCrtLine('FRAMEWORK', 'Flutter SDK'),
                              _buildCrtLine('TYPOGRAPHY', 'IBM Plex Mono'),
                              _buildCrtLine('AUDIO ENGINE', 'audioplayers'),
                              _buildCrtLine('DESIGN LANGUAGE', 'CRT Industrial Terminal'),
                            ],
                          ),

                          const SizedBox(height: 48.0),

                          // Footer
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 10.0,
                                    color: HTColors.border,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'HARDWARE TYCOON 1960',
                                  style: HTTypography.panelHeader.copyWith(
                                    color: HTColors.primary,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'END OF SYSTEM MANIFEST',
                                  style: HTTypography.metricLabel.copyWith(
                                    color: HTColors.textMuted,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 24.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildTerminalBlock({
    required String header,
    required IconData icon,
    Color accentColor = HTColors.primary,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HTColors.surface,
        border: Border.all(color: HTColors.border),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14.0, color: accentColor),
                const SizedBox(width: 10.0),
                Text(
                  header,
                  style: HTTypography.panelHeader.copyWith(
                    color: accentColor,
                    letterSpacing: 1.5,
                    fontSize: 12.0,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrtLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.0,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                color: HTColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10.0,
              color: HTColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10.0,
                color: HTColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditEntry({
    required String title,
    required String subtitle,
    required List<_TrackInfo> tracks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '▸ ',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11.0,
                color: HTColors.primary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: HTColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              '($subtitle)',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 9.0,
                color: HTColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        ...tracks.map((track) => Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 4.0),
          child: Row(
            children: [
              Container(
                width: 4.0,
                height: 4.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HTColors.textMuted,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                track.name,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                  color: HTColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  track.detail,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9.0,
                    color: HTColors.textMuted.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _TrackInfo {
  final String name;
  final String detail;

  const _TrackInfo(this.name, this.detail);
}
