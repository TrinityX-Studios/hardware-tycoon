/// Hardware Tycoon — Terminal Settings View
///
/// Interface for configuring application display and audio parameters.
library;

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
                    onPressed: () => widget.appState.goToMainMenu(),
                  ),
                  const SizedBox(width: 16.0),
                  Text('TERMINAL SETTINGS', style: HTTypography.statMedium),
                ],
              ),
              const SizedBox(height: 12.0),
              const Divider(color: HTColors.border, height: 1.0),
              
              const SizedBox(height: 32.0),
              
              // Settings Controls
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
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
                          
                          const SizedBox(height: 36.0),
                          
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
                          
                          const SizedBox(height: 48.0),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => widget.appState.goToMainMenu(),
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
                                  widget.appState.goToMainMenu();
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
