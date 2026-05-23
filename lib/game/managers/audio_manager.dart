/// Hardware Tycoon — Audio Manager Registry
///
/// Unified singleton layer orchestrating looped background music (BGM)
/// and mechanical interface clicks/alerts (SFX) with smooth volume gating.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  // Singleton instance
  static final AudioManager instance = AudioManager._internal();

  factory AudioManager() => instance;

  AudioManager._internal() {
    _bgmPlayer.setReleaseMode(ReleaseMode.stop);
    _bgmPlayer.onPlayerComplete.listen((event) {
      playNextTrack(auto: true);
    });
  }

  // Audio players
  final AudioPlayer _bgmPlayer = AudioPlayer();
  String? _currentBgmAsset;

  // Audio parameters
  double _masterVolume = 0.8;
  double _musicVolume = 0.6;
  bool _interfaceClicksEnabled = true;

  // Playlist & state controls
  final List<String> _playlist = [
    'audio/music/Laser_Groove.mp3',
    'audio/music/Voltaic.mp3',
    'audio/music/Bleeping_Demo.mp3',
  ];

  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isUserOverridden = false;

  // Getters
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  bool get interfaceClicksEnabled => _interfaceClicksEnabled;
  double get effectiveMusicVolume => _masterVolume * _musicVolume;

  String? get currentBgmAsset => _currentBgmAsset;
  bool get isPlayingBGM => _bgmPlayer.state == PlayerState.playing;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isUserOverridden => _isUserOverridden;
  List<String> get playlist => _playlist;

  // Position, duration streams and seek controls
  Stream<Duration> get onPositionChanged => _bgmPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _bgmPlayer.onDurationChanged;
  Future<void> seekBGM(Duration position) async {
    try {
      await _bgmPlayer.seek(position);
    } catch (e) {
      debugPrint('HT AudioManager seekBGM Error: $e');
    }
  }
  Future<Duration?> getCurrentPosition() => _bgmPlayer.getCurrentPosition();
  Future<Duration?> getDuration() => _bgmPlayer.getDuration();

  Future<void> pauseBGM() async {
    try {
      await _bgmPlayer.pause();
    } catch (e) {
      debugPrint('HT AudioManager pauseBGM Error: $e');
    }
  }

  Future<void> resumeBGM() async {
    try {
      if (_currentBgmAsset != null) {
        await _bgmPlayer.resume();
      } else {
        await playBGM('audio/music/Laser_Groove.mp3');
      }
    } catch (e) {
      debugPrint('HT AudioManager resumeBGM Error: $e');
    }
  }

  /// Play a background music track.
  /// Path must be relative to the assets directory, e.g. "audio/music/Voltaic.mp3"
  Future<void> playBGM(String assetPath, {bool userSelected = false}) async {
    if (userSelected) {
      _isUserOverridden = true;
    } else if (_isUserOverridden) {
      // If user has overridden the playlist manually, do not transition automatically
      return;
    }

    if (_currentBgmAsset == assetPath && isPlayingBGM) return;
    _currentBgmAsset = assetPath;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource(assetPath));
      await _updateBgmVolume();
    } catch (e) {
      debugPrint('HT AudioManager BGM Error: $e');
    }
  }

  Future<void> playNextTrack({bool auto = false}) async {
    if (_isRepeat && auto) {
      if (_currentBgmAsset != null) {
        try {
          await _bgmPlayer.stop();
          await _bgmPlayer.play(AssetSource(_currentBgmAsset!));
          await _updateBgmVolume();
        } catch (e) {
          debugPrint('HT AudioManager Replay Error: $e');
        }
      }
      return;
    }

    int nextIndex = 0;
    if (_isShuffle) {
      nextIndex = math.Random().nextInt(_playlist.length);
    } else {
      int curr = _playlist.indexOf(_currentBgmAsset ?? '');
      nextIndex = (curr + 1) % _playlist.length;
    }

    await playBGM(_playlist[nextIndex], userSelected: !auto);
  }

  Future<void> playPrevTrack() async {
    int prevIndex = 0;
    if (_isShuffle) {
      prevIndex = math.Random().nextInt(_playlist.length);
    } else {
      int curr = _playlist.indexOf(_currentBgmAsset ?? '');
      prevIndex = (curr - 1 + _playlist.length) % _playlist.length;
    }

    await playBGM(_playlist[prevIndex], userSelected: true);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
  }

  /// Stop currently playing background music.
  Future<void> stopBGM() async {
    _currentBgmAsset = null;
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('HT AudioManager stopBGM Error: $e');
    }
  }

  /// Play a crisp mechanical sound effect.
  /// Path must be relative to the assets directory, e.g. "audio/sounds/click.wav"
  Future<void> playSFX(String assetPath) async {
    if (!_interfaceClicksEnabled) return;
    try {
      final sfxPlayer = AudioPlayer();
      await sfxPlayer.setVolume(_masterVolume);
      await sfxPlayer.play(AssetSource(assetPath));
      // Clean up player resources automatically on completion
      sfxPlayer.onPlayerComplete.listen((event) {
        sfxPlayer.dispose();
      });
    } catch (e) {
      debugPrint('HT AudioManager SFX Error: $e');
    }
  }

  /// Update configurations instantly.
  Future<void> updateSettings({
    double? masterVolume,
    double? musicVolume,
    bool? interfaceClicks,
  }) async {
    if (masterVolume != null) _masterVolume = masterVolume;
    if (musicVolume != null) _musicVolume = musicVolume;
    if (interfaceClicks != null) _interfaceClicksEnabled = interfaceClicks;
    await _updateBgmVolume();
  }

  /// Sync volume updates to BGM player.
  Future<void> _updateBgmVolume() async {
    try {
      await _bgmPlayer.setVolume(effectiveMusicVolume);
    } catch (e) {
      debugPrint('HT AudioManager BGM Volume Update Error: $e');
    }
  }
}
