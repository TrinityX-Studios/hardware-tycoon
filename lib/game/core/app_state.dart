/// Hardware Tycoon — App State Machine
///
/// Root-level state manager for transitioning between the main menu,
/// setup screen, and active gameplay.
library;

import 'package:flutter/foundation.dart';
import 'game_state.dart';
import '../managers/audio_manager.dart';

enum AppScreen {
  mainMenu,
  newGameSetup,
  gameplay,
  sessionSlots,
  settings,
  about,
}

class AppStateMachine extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.mainMenu;
  AppScreen get currentScreen => _currentScreen;

  GameStateNotifier? _activeGameState;
  GameStateNotifier? get activeGameState => _activeGameState;

  void goToMainMenu() {
    // Pause game state if active before transitioning
    _activeGameState?.pause();
    _currentScreen = AppScreen.mainMenu;
    notifyListeners();
    // Play menu theme
    AudioManager.instance.playBGM('audio/music/Laser_Groove.mp3');
  }

  void goToSetup() {
    _currentScreen = AppScreen.newGameSetup;
    notifyListeners();
  }

  void goToSessionSlots() {
    _currentScreen = AppScreen.sessionSlots;
    notifyListeners();
  }

  AppScreen _settingsReturnScreen = AppScreen.mainMenu;
  AppScreen get settingsReturnScreen => _settingsReturnScreen;

  void goToSettings({AppScreen returnTo = AppScreen.mainMenu}) {
    _settingsReturnScreen = returnTo;
    _currentScreen = AppScreen.settings;
    notifyListeners();
  }

  void exitSettings() {
    _currentScreen = _settingsReturnScreen;
    if (_settingsReturnScreen == AppScreen.gameplay) {
      _activeGameState?.startSimulation();
    }
    notifyListeners();
  }

  void goToAbout() {
    _currentScreen = AppScreen.about;
    notifyListeners();
  }

  void startGame(FinancialConfig config) {
    // Dispose previous state if any
    _activeGameState?.dispose();
    
    // Initialize new game state
    _activeGameState = GameStateNotifier(config: config);
    
    // Transition to gameplay
    _currentScreen = AppScreen.gameplay;
    notifyListeners();
    
    // Play gameplay theme
    AudioManager.instance.playBGM('audio/music/Voltaic.mp3');
    
    // Start simulation ticks
    _activeGameState?.startSimulation();
  }
  
  void loadGame(GameStateNotifier restoredState) {
    _activeGameState?.dispose();
    _activeGameState = restoredState;
    _currentScreen = AppScreen.gameplay;
    notifyListeners();
    
    // Play gameplay theme
    AudioManager.instance.playBGM('audio/music/Voltaic.mp3');
    
    _activeGameState?.startSimulation();
  }

  @override
  void dispose() {
    _activeGameState?.dispose();
    super.dispose();
  }
}
