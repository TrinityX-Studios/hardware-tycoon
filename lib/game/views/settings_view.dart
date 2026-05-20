/// Hardware Tycoon — Terminal Settings View
///
/// Interface for configuring application display, audio parameters,
/// and interactive background music selection.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import '../managers/audio_manager.dart';

class SettingsView extends StatefulWidget {
  final AppStateMachine appState;

  const SettingsView({super.key, required this.appState});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isFullscreen = true;
  double _uiScale = 1.0;
  double _masterVolume = 0.8;
  double _musicVolume = 0.6;
  bool _interfaceClicks = true;

  int _activeTabIndex = 0;

  static const List<Map<String, String>> _tracks = [
    {
      'title': 'Laser Groove',
      'path': 'audio/music/Laser_Groove.mp3',
      'artist': 'Kevin MacLeod (Incompetech)',
    },
    {
      'title': 'Voltaic',
      'path': 'audio/music/Voltaic.mp3',
      'artist': 'Kevin MacLeod (Incompetech)',
    },
    {
      'title': 'Bleeping Demo',
      'path': 'audio/music/Bleeping_Demo.mp3',
      'artist': 'Kevin MacLeod (Incompetech)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initFullscreen();
    // Sync with AudioManager singleton state
    _masterVolume = AudioManager.instance.masterVolume;
    _musicVolume = AudioManager.instance.musicVolume;
    _interfaceClicks = AudioManager.instance.interfaceClicksEnabled;
  }

  Future<void> _initFullscreen() async {
    try {
      final isFS = await windowManager.isFullScreen();
      setState(() {
        _isFullscreen = isFS;
      });
    } catch (_) {}
  }

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
                    onPressed: () => widget.appState.exitSettings(),
                  ),
                  const SizedBox(width: 16.0),
                  Text('TERMINAL SETTINGS', style: HTTypography.statMedium),
                ],
              ),
              const SizedBox(height: 12.0),
              const Divider(color: HTColors.border, height: 1.0),
              
              const SizedBox(height: 24.0),

              // Tab Selection Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, '01 // DISPLAY', Icons.desktop_windows),
                    const SizedBox(width: 12.0),
                    _buildTabButton(1, '02 // AUDIO & INTERFACE', Icons.volume_up),
                    const SizedBox(width: 12.0),
                    _buildTabButton(2, '03 // MUSIC DECK', Icons.music_note),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),
              
              // Settings Controls
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (_activeTabIndex == 0) _buildDisplayTab(),
                          if (_activeTabIndex == 1) _buildAudioTab(),
                          if (_activeTabIndex == 2) _buildMusicTab(),

                          const SizedBox(height: 48.0),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => widget.appState.exitSettings(),
                                style: TextButton.styleFrom(
                                  foregroundColor: HTColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                ),
                                child: const Text('DISCARD'),
                              ),
                              const SizedBox(width: 16.0),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                      await windowManager.setFullScreen(_isFullscreen);
                                  } catch (_) {}
                                  widget.appState.exitSettings();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HTColors.primary,
                                  foregroundColor: HTColors.textOnPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                                ),
                                child: const Text('APPLY CONFIGURATION'),
                              ),
                            ],
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

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playSFX('audio/sounds/click.wav');
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? HTColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? HTColors.primary : HTColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.0,
              color: isSelected ? HTColors.primary : HTColors.textSecondary,
            ),
            const SizedBox(width: 10.0),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? HTColors.primary : HTColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('DISPLAY MODE'),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'WINDOWED',
                isSelected: !_isFullscreen,
                onTap: () => setState(() => _isFullscreen = false),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _ToggleButton(
                label: 'FULLSCREEN',
                isSelected: _isFullscreen,
                onTap: () => setState(() => _isFullscreen = true),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 36.0),
        
        _buildSectionHeader('UI DENSITY / TEXT SCALE'),
        const SizedBox(height: 16.0),
        _buildSliderRow(
          icon: Icons.text_fields,
          value: _uiScale,
          min: 0.8,
          max: 1.2,
          divisions: 4,
          label: '${(_uiScale * 100).round()}%',
          onChanged: (val) => setState(() => _uiScale = val),
        ),
      ],
    );
  }

  Widget _buildAudioTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('MASTER VOLUME LEVEL'),
        const SizedBox(height: 16.0),
        _buildSliderRow(
          icon: _masterVolume == 0 ? Icons.volume_off : Icons.volume_up,
          value: _masterVolume,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          label: '${(_masterVolume * 100).round()}%',
          accentColor: HTColors.primary,
          onChanged: (val) {
            setState(() => _masterVolume = val);
            AudioManager.instance.updateSettings(masterVolume: val);
          },
        ),
        
        const SizedBox(height: 36.0),
        
        _buildSectionHeader('INTERFACE CLICK SOUNDS'),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Icon(
              _interfaceClicks ? Icons.touch_app : Icons.do_not_touch,
              size: 16.0,
              color: HTColors.textSecondary,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                _interfaceClicks
                    ? 'MECHANICAL CLICK FEEDBACK: ENABLED'
                    : 'MECHANICAL CLICK FEEDBACK: DISABLED',
                style: HTTypography.listTitle.copyWith(
                  color: _interfaceClicks ? HTColors.success : HTColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            GestureDetector(
              onTap: () {
                setState(() => _interfaceClicks = !_interfaceClicks);
                AudioManager.instance.updateSettings(interfaceClicks: _interfaceClicks);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48.0,
                height: 26.0,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: _interfaceClicks
                      ? HTColors.success.withValues(alpha: 0.2)
                      : HTColors.surfaceVariant,
                  border: Border.all(
                    color: _interfaceClicks ? HTColors.success : HTColors.border,
                  ),
                  borderRadius: BorderRadius.circular(13.0),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _interfaceClicks
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20.0,
                    height: 20.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _interfaceClicks ? HTColors.success : HTColors.textMuted,
                      boxShadow: _interfaceClicks
                          ? [
                              BoxShadow(
                                color: HTColors.success.withValues(alpha: 0.4),
                                blurRadius: 6.0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMusicTab() {
    final currentAsset = AudioManager.instance.currentBgmAsset;
    final isPlaying = AudioManager.instance.isPlayingBGM;

    int activeTrackIndex = _tracks.indexWhere((track) => track['path'] == currentAsset);
    if (activeTrackIndex == -1) activeTrackIndex = 0;

    final activeTrack = _tracks[activeTrackIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('MUSIC VOLUME LAYER'),
        const SizedBox(height: 16.0),
        _buildSliderRow(
          icon: Icons.music_note,
          value: _musicVolume,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          label: '${(_musicVolume * 100).round()}%',
          accentColor: HTColors.secondary,
          onChanged: (val) {
            setState(() => _musicVolume = val);
            AudioManager.instance.updateSettings(musicVolume: val);
          },
        ),
        
        const SizedBox(height: 36.0),

        _buildSectionHeader('CORE MUSIC DECK'),
        const SizedBox(height: 16.0),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: HTColors.surface,
            border: Border.all(color: HTColors.border),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display LCD Pane
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: HTColors.surfaceVariant,
                  border: Border.all(color: HTColors.border.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRACK: ${activeTrack['title']!.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: HTColors.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'COMPOSER: ${activeTrack['artist']!.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 8.0,
                              color: HTColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Live Equalizer Visualizer
                    SizedBox(
                      width: 160.0,
                      height: 40.0,
                      child: _EqualizerBars(isPlaying: isPlaying),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // Player Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PlayerButton(
                    icon: Icons.skip_previous,
                    onTap: () async {
                      AudioManager.instance.playSFX('audio/sounds/click.wav');
                      await AudioManager.instance.playPrevTrack();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16.0),
                  _PlayerButton(
                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                    isLarge: true,
                    onTap: () async {
                      AudioManager.instance.playSFX('audio/sounds/click.wav');
                      if (isPlaying) {
                        await AudioManager.instance.pauseBGM();
                      } else {
                        await AudioManager.instance.resumeBGM();
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16.0),
                  _PlayerButton(
                    icon: Icons.skip_next,
                    onTap: () async {
                      AudioManager.instance.playSFX('audio/sounds/click.wav');
                      await AudioManager.instance.playNextTrack();
                      setState(() {});
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20.0),
              const Divider(color: HTColors.border, height: 1.0),
              const SizedBox(height: 16.0),

              const Text(
                'AVAILABLE TRACKS SYSTEM INDEX:',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  color: HTColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Column(
                children: List.generate(_tracks.length, (index) {
                  final track = _tracks[index];
                  final isCurrent = track['path'] == currentAsset;

                  return GestureDetector(
                    onTap: () async {
                      AudioManager.instance.playSFX('audio/sounds/click.wav');
                      await AudioManager.instance.playBGM(track['path']!, userSelected: true);
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: isCurrent ? HTColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                        border: Border.all(
                          color: isCurrent ? HTColors.primary : HTColors.border.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent && isPlaying ? Icons.volume_up : Icons.music_note,
                            size: 14.0,
                            color: isCurrent ? HTColors.primary : HTColors.textSecondary,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track['title']!.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 10.0,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent ? HTColors.primary : HTColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  track['artist']!.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 8.0,
                                    color: HTColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isCurrent ? '[ ACTIVE ]' : '[ SELECT ]',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? HTColors.primary : HTColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: HTTypography.panelHeader),
        const SizedBox(width: 16.0),
        Expanded(child: Container(height: 1.0, color: HTColors.border)),
      ],
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    Color accentColor = HTColors.primary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: HTColors.textSecondary),
        const SizedBox(width: 16.0),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: HTColors.surfaceVariant,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        SizedBox(
          width: 48.0,
          child: Text(
            label,
            style: HTTypography.metricValue,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? HTColors.primary.withValues(alpha: 0.15) : HTColors.surface,
          border: Border.all(
            color: isSelected ? HTColors.primary : HTColors.border,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Center(
          child: Text(
            label,
            style: HTTypography.listTitle.copyWith(
              color: isSelected ? HTColors.primary : HTColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;

  const _PlayerButton({
    required this.icon,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 54.0 : 42.0;
    final iconSize = isLarge ? 28.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: HTColors.surface,
          border: Border.all(color: HTColors.border),
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: HTColors.primary,
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  const _EqualizerBars({required this.isPlaying});

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<double> _heights = List.filled(15, 6.0);
  final List<double> _targetHeights = List.filled(15, 6.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        if (!widget.isPlaying) {
          setState(() {
            for (int i = 0; i < 15; i++) {
              _heights[i] = _heights[i] * 0.8 + 4.0 * 0.2; // decay to flat baseline
            }
          });
          return;
        }
        setState(() {
          for (int i = 0; i < 15; i++) {
            _heights[i] = _heights[i] * 0.6 + _targetHeights[i] * 0.4;
          }
        });
      });
    
    _controller.repeat();
    _generateTargets();
  }

  void _generateTargets() {
    if (!mounted) return;
    if (widget.isPlaying) {
      setState(() {
        final rand = math.Random();
        for (int i = 0; i < 15; i++) {
          _targetHeights[i] = 4.0 + rand.nextDouble() * 32.0;
        }
      });
    }
    Future.delayed(const Duration(milliseconds: 150), _generateTargets);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(15, (index) {
        return Container(
          width: 6.0,
          height: _heights[index],
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? HTColors.success.withValues(alpha: 0.8)
                : HTColors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1.0),
            boxShadow: widget.isPlaying
                ? [
                    BoxShadow(
                      color: HTColors.success.withValues(alpha: 0.4),
                      blurRadius: 4.0,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
