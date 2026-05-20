/// Hardware Tycoon — App State Machine
///
/// Root-level state manager for transitioning between the main menu,
/// setup screen, and active gameplay.
library;

import 'package:flutter/foundation.dart';
import 'game_state.dart';

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
  }

  void goToSetup() {
    _currentScreen = AppScreen.newGameSetup;
    notifyListeners();
  }

  void goToSessionSlots() {
    _currentScreen = AppScreen.sessionSlots;
    notifyListeners();
  }

  void goToSettings() {
    _currentScreen = AppScreen.settings;
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
    
    // Start simulation ticks
    _activeGameState?.startSimulation();
  }
  
  void loadGame(GameStateNotifier restoredState) {
    _activeGameState?.dispose();
    _activeGameState = restoredState;
    _currentScreen = AppScreen.gameplay;
    notifyListeners();
    _activeGameState?.startSimulation();
  }

  @override
  void dispose() {
    _activeGameState?.dispose();
    super.dispose();
  }
}
