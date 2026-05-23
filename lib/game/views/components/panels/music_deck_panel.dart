import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../managers/audio_manager.dart';

class MusicDeckPanel extends StatefulWidget {
  const MusicDeckPanel({super.key});

  @override
  State<MusicDeckPanel> createState() => _MusicDeckPanelState();
}

class _MusicDeckPanelState extends State<MusicDeckPanel>
    with SingleTickerProviderStateMixin {
  double _musicVolume = 0.6;
  late final AnimationController _eqController;
  final List<double> _barHeights = List.filled(8, 3.0);
  final math.Random _rand = math.Random();

  // Playback position and duration state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _isDragging = false;
  double _dragValue = 0.0;

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
    _musicVolume = AudioManager.instance.musicVolume;
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_updateEqBars);
    _eqController.repeat();

    // Fetch initial playback duration & position if track is already loaded
    AudioManager.instance.getCurrentPosition().then((p) {
      if (mounted && p != null) {
        setState(() {
          _position = p;
        });
      }
    });
    AudioManager.instance.getDuration().then((d) {
      if (mounted && d != null) {
        setState(() {
          _duration = d;
        });
      }
    });

    // Subscribe to BGM position/duration streams
    _positionSubscription = AudioManager.instance.onPositionChanged.listen((p) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = p;
        });
      }
    });

    _durationSubscription = AudioManager.instance.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });
  }

  void _updateEqBars() {
    if (!mounted) return;
    final isPlaying = AudioManager.instance.isPlayingBGM;
    setState(() {
      for (int i = 0; i < 8; i++) {
        if (isPlaying) {
          final target = 3.0 + _rand.nextDouble() * 22.0;
          _barHeights[i] = (_barHeights[i] * 0.5 + target * 0.5).clamp(3.0, 25.0);
        } else {
          _barHeights[i] = (_barHeights[i] * 0.85 + 3.0 * 0.15).clamp(3.0, 25.0);
        }
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _eqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsset = AudioManager.instance.currentBgmAsset;
    final isPlaying = AudioManager.instance.isPlayingBGM;
    final isShuffle = AudioManager.instance.isShuffle;
    final isRepeat = AudioManager.instance.isRepeat;

    int activeTrackIndex =
        _tracks.indexWhere((track) => track['path'] == currentAsset);
    if (activeTrackIndex == -1) activeTrackIndex = 0;

    final activeTrack = _tracks[activeTrackIndex];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LCD Display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: HTColors.surfaceVariant,
              border:
                  Border.all(color: HTColors.border.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeTrack['title']!.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: HTColors.primary,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        activeTrack['artist']!.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 7.0,
                          color: HTColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                // Equalizer bars
                SizedBox(
                  width: 76.0,
                  height: 28.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(8, (i) {
                      return Container(
                        width: 5.0,
                        height: _barHeights[i],
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? HTColors.success.withValues(alpha: 0.8)
                              : HTColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // Progress Bar with Time stamps
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                      color: HTColors.primary,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 8.0,
                      color: HTColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: HTColors.primary,
                  inactiveTrackColor: HTColors.surfaceVariant,
                  thumbColor: HTColors.primary,
                  overlayColor: HTColors.primary.withValues(alpha: 0.2),
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                ),
                child: SizedBox(
                  height: 14.0,
                  child: Slider(
                    value: (_isDragging ? _dragValue : _position.inMilliseconds.toDouble())
                        .clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (val) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      await AudioManager.instance.seekBGM(Duration(milliseconds: val.toInt()));
                      setState(() {
                        _isDragging = false;
                        _position = Duration(milliseconds: val.toInt());
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Player Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallIconButton(
                icon: Icons.shuffle,
                isActive: isShuffle,
                onTap: () {
                  AudioManager.instance.playSFX('audio/sounds/click.wav');
                  AudioManager.instance.toggleShuffle();
                  setState(() {});
                },
              ),
              const SizedBox(width: 6.0),
              _SmallIconButton(
                icon: Icons.skip_previous,
                onTap: () async {
                  AudioManager.instance.playSFX('audio/sounds/click.wav');
                  await AudioManager.instance.playPrevTrack();
                  setState(() {});
                },
              ),
              const SizedBox(width: 6.0),
              _SmallIconButton(
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
              const SizedBox(width: 6.0),
              _SmallIconButton(
                icon: Icons.skip_next,
                onTap: () async {
                  AudioManager.instance.playSFX('audio/sounds/click.wav');
                  await AudioManager.instance.playNextTrack();
                  setState(() {});
                },
              ),
              const SizedBox(width: 6.0),
              _SmallIconButton(
                icon: Icons.repeat,
                isActive: isRepeat,
                onTap: () {
                  AudioManager.instance.playSFX('audio/sounds/click.wav');
                  AudioManager.instance.toggleRepeat();
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 12.0),
          const Divider(color: HTColors.border, height: 1.0),
          const SizedBox(height: 8.0),

          // Volume Slider
          Row(
            children: [
              const Icon(Icons.music_note, size: 12.0,
                  color: HTColors.textSecondary),
              const SizedBox(width: 6.0),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: HTColors.secondary,
                    inactiveTrackColor: HTColors.surfaceVariant,
                    thumbColor: HTColors.secondary,
                    overlayColor:
                        HTColors.secondary.withValues(alpha: 0.2),
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5.0),
                  ),
                  child: Slider(
                    value: _musicVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => _musicVolume = val);
                      AudioManager.instance
                          .updateSettings(musicVolume: val);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 28.0,
                child: Text(
                  '${(_musicVolume * 100).round()}%',
                  style:
                      HTTypography.metricValue.copyWith(fontSize: 9.0),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),
          const Divider(color: HTColors.border, height: 1.0),
          const SizedBox(height: 6.0),

          // Playlist
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final isCurrent = track['path'] == currentAsset;

                return GestureDetector(
                  onTap: () async {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    await AudioManager.instance
                        .playBGM(track['path']!, userSelected: true);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? HTColors.primary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCurrent
                            ? HTColors.primary
                            : HTColors.border.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent && isPlaying
                              ? Icons.volume_up
                              : Icons.music_note,
                          size: 12.0,
                          color: isCurrent
                              ? HTColors.primary
                              : HTColors.textSecondary,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            track['title']!.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 9.0,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? HTColors.primary
                                  : HTColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          isCurrent ? 'ACTIVE' : 'PLAY',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 7.0,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? HTColors.primary
                                : HTColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;
  final bool isActive;

  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    this.isLarge = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 36.0 : 28.0;
    final iconSize = isLarge ? 18.0 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive
              ? HTColors.primary.withValues(alpha: 0.15)
              : HTColors.surface,
          border: Border.all(
              color: isActive ? HTColors.primary : HTColors.border),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: isActive ? HTColors.primary : HTColors.textSecondary,
        ),
      ),
    );
  }
}
