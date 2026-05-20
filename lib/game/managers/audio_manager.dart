/// Hardware Tycoon — Audio Manager Registry
///
/// Unified singleton layer orchestrating looped background music (BGM)
/// and mechanical interface clicks/alerts (SFX) with smooth volume gating.
library;

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  // Singleton instance
  static final AudioManager instance = AudioManager._internal();

  factory AudioManager() => instance;

  AudioManager._internal() {
    // Set up BGM player release mode
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // Audio players
  final AudioPlayer _bgmPlayer = AudioPlayer();
  String? _currentBgmAsset;

  // Audio parameters
  double _masterVolume = 0.8;
  double _musicVolume = 0.6;
  bool _interfaceClicksEnabled = true;

  // Getters
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  bool get interfaceClicksEnabled => _interfaceClicksEnabled;

  double get effectiveMusicVolume => _masterVolume * _musicVolume;

  /// Play a background music track (loops continuously).
  /// Path must be relative to the assets directory, e.g. "audio/music/Voltaic.mp3"
  Future<void> playBGM(String assetPath) async {
    if (_currentBgmAsset == assetPath) return;
    _currentBgmAsset = assetPath;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource(assetPath));
      await _updateBgmVolume();
    } catch (e) {
      debugPrint('HT AudioManager BGM Error: $e');
    }
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
